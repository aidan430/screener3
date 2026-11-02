"""Go-live tests: the dashboard lock, self-hosted test pages, the .env reader and writer."""
from __future__ import annotations

import base64
import os
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from tests.base import FactoryTestCase

from factory import config  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent


def basic(user: str, password: str) -> dict:
    return {"Authorization": "Basic " + base64.b64encode(f"{user}:{password}".encode()).decode()}


class LockTest(FactoryTestCase):
    def client(self):
        from fastapi.testclient import TestClient
        from factory.api.server import app
        return TestClient(app)

    def test_without_a_password_the_local_dashboard_is_open(self):
        with mock.patch.dict(os.environ, {"DASHBOARD_PASSWORD": ""}):
            self.assertEqual(self.client().get("/api/state").status_code, 200)

    def test_with_a_password_only_the_public_paths_are_open(self):
        t = self.to_smoke()[0][0]
        c = self.client()
        with mock.patch.dict(os.environ, {"DASHBOARD_PASSWORD": "s3cret", "DASHBOARD_USER": "owner"}):
            self.assertEqual(c.get("/api/state").status_code, 401)
            self.assertEqual(c.get("/").status_code, 401)
            self.assertEqual(c.get("/api/state", headers=basic("owner", "nope")).status_code, 401)
            self.assertEqual(c.get("/api/state", headers=basic("someone", "s3cret")).status_code, 401)
            self.assertEqual(c.get("/api/state", headers=basic("owner", "s3cret")).status_code, 200)
            self.assertEqual(c.post(f"/api/approve/{t.id}").status_code, 401)  # the money buttons are locked
            self.assertEqual(c.post(f"/api/event/{t.slug}?kind=visit").status_code, 200)  # page beacons are not
            self.assertNotEqual(c.get(f"/pages/{t.slug}/").status_code, 401)
            hook = c.post("/api/paystack/webhook", content=b"{}")  # reaches the app, which checks the signature
            self.assertEqual((hook.status_code, "bad signature" in hook.text), (401, True))

    def test_refuses_to_listen_beyond_this_machine_without_a_password(self):
        from factory.api import server
        with mock.patch.dict(os.environ, {"HOST": "0.0.0.0", "DASHBOARD_PASSWORD": ""}), \
                mock.patch("uvicorn.run") as run:
            with self.assertRaises(SystemExit):
                server.main()
            run.assert_not_called()

    def test_pages_are_served_by_the_factory_on_its_own_domain(self):
        with mock.patch.dict(os.environ, {"FACTORY_DOMAIN": "mytrials.co.za", "VERCEL_TOKEN": ""}):
            t = self.to_smoke()[0][0]
        self.assertEqual((t.deploy_target, t.url), ("self", f"https://mytrials.co.za/pages/{t.slug}/"))
        self.assertNotIn("only on localhost", t.manual_steps)
        page = Path(t.page_path).read_text()
        self.assertNotIn("plausible.io", page)  # self-hosted pages count visits with their own beacon
        self.assertIn('"api": ""', page)


class EnvTest(unittest.TestCase):
    def test_reader_skips_comments_and_writer_keeps_hashes(self):
        env = Path(tempfile.mkdtemp()) / ".env"
        env.write_text("VF_A=value  # comment\nVF_B=sk-ant-abc#def\nVF_C=   # only a comment\nVF_D=old\n")
        for key, value in (("VF_D", "new"), ("VF_E", "#starts-with-hash"), ("VF_F", "has # inside")):
            subprocess.run(["python3", str(ROOT / "scripts" / "env_set.py"), str(env), key], input=value,
                           text=True, check=True)
        keys = ("VF_A", "VF_B", "VF_C", "VF_D", "VF_E", "VF_F")
        with mock.patch.dict(os.environ, {}):
            for k in keys:
                os.environ.pop(k, None)
            config.load_dotenv(env)
            got = [os.environ.get(k) for k in keys]
        self.assertEqual(got, ["value", "sk-ant-abc#def", None, "new", "#starts-with-hash", "has # inside"])
        self.assertEqual(env.read_text().count("VF_D="), 1)

    def test_installer_scripts_are_valid_bash(self):
        for name in ("install.sh", "set-key.sh"):
            subprocess.run(["bash", "-n", str(ROOT / "scripts" / name)], check=True)


if __name__ == "__main__":
    unittest.main()

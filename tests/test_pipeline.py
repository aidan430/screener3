"""End-to-end pipeline tests: fake sources + fake Claude, temp DB. Run: make test"""
from __future__ import annotations

import io
import json
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest import mock

from tests.fakes import FAKE_POSTS, FakeClaude, temp_env

import logging  # noqa: E402

logging.disable(logging.CRITICAL)
TMP = temp_env()  # must run before factory.models creates the engine

from factory import config, costs, models  # noqa: E402
from factory.models import Card, Cost, GateResult, SmokeTest, TrackEvent, session  # noqa: E402
from sqlmodel import select  # noqa: E402


def quiet(fn, *a, **kw):
    buf = io.StringIO()
    with redirect_stdout(buf):
        out = fn(*a, **kw)
    return out, buf.getvalue()


class PipelineTest(unittest.TestCase):
    def setUp(self):
        import os
        import tempfile
        d = tempfile.mkdtemp(dir=TMP)
        os.environ["FACTORY_DB"] = str(Path(d) / "t.db")
        models.reset_engine()
        self.fake = FakeClaude()
        costs.set_client(self.fake)
        self.patches = [
            mock.patch.object(config, "PAGES_DIR", Path(d) / "pages"),
            mock.patch.object(config, "VENTURES_DIR", Path(d) / "ventures"),
            mock.patch("factory.scouts.sources.reddit.fetch", return_value=[FAKE_POSTS[0]]),
            mock.patch("factory.scouts.sources.hn.fetch", return_value=[FAKE_POSTS[1]]),
            mock.patch.dict(os.environ, {"META_ADS_ENABLED": "false", "VERCEL_TOKEN": "", "FACTORY_DOMAIN": ""}),
        ]
        for p in self.patches:
            p.start()

    def tearDown(self):
        for p in self.patches:
            p.stop()
        costs.set_client(None)

    def scout(self, niches=1):
        from factory.scouts import runner
        with mock.patch.object(runner, "active_niches", lambda: _first(niches)):
            return quiet(runner.run)

    def test_scout_keeps_only_verbatim_cards(self):
        _, out = self.scout()
        with session() as s:
            cards = list(s.exec(select(Card)))
        self.assertEqual([c.title for c in cards], ["Lease renewal reminders"])
        c = cards[0]
        self.assertEqual(c.pay_amount, 450)
        self.assertTrue(c.url.startswith("https://www.reddit.com/"))
        self.assertIn("Lease renewal reminders", out)
        self.assertIn("[cost] scout", out)

    def test_costs_logged_in_rand(self):
        self.scout()
        with session() as s:
            rows = list(s.exec(select(Cost)))
        self.assertTrue(rows and all(r.model == "claude-haiku-4-5" and r.zar > 0 for r in rows))
        self.assertAlmostEqual(rows[0].zar, rows[0].usd * 18.5, places=6)

    def test_gates_and_evidence_check(self):
        from factory.gates import run as gates
        self.scout()
        res, out = quiet(gates.run)
        self.assertEqual(res["proof"]["passed"], 1)
        self.assertEqual(res["craft"]["passed"], 1)
        with session() as s:
            proof = s.exec(select(GateResult).where(GateResult.gate == "proof")).one()
        self.assertEqual(proof.evidence, ["I pay someone R450 a month"])  # invented one discarded
        self.assertIn("non-verbatim evidence", proof.reasoning)
        self.assertIn("[PASS] proof", out)
        self.assertTrue(all(c.model == "claude-sonnet-4-6" for c in self.fake.calls if c.schema == "Verdict"))

    def test_stage_cap_stops_gates(self):
        from factory.gates import run as gates
        self.scout()
        with mock.patch.object(costs, "stage_cap", lambda: 0.0001):
            res, out = quiet(gates.run)
        self.assertIn("STOPPED", out)
        self.assertEqual(res["proof"]["passed"] + res["proof"]["killed"], 0)

    def test_niche_cap_skips(self):
        with mock.patch.dict(config.settings()["caps"], {"scout_zar_per_niche": 0.0001}):
            _, out = self.scout()
        self.assertIn("over R0.0001 scout cap", out)
        with session() as s:
            self.assertEqual(len(list(s.exec(select(Card)))), 0)

    def test_smoke_reaches_awaiting_funding_and_prints_steps(self):
        from factory.gates import run as gates
        from factory.smoke import run as smoke
        self.scout()
        quiet(gates.run)
        made, out = quiet(smoke.run)
        self.assertEqual(len(made), 1)
        t = made[0]
        self.assertEqual(t.status, "awaiting_funding")
        self.assertTrue(Path(t.page_path).exists())
        self.assertIn("Manual steps (META_ADS_ENABLED=false)", out)
        self.assertEqual(json.loads(t.ads_json)["budget_zar"], 200)
        html = Path(t.page_path).read_text()
        self.assertIn("We are onboarding founders this week, leave your email.", html)
        self.assertIn("buy_click", html)

    def test_state_contract_and_api(self):
        from fastapi.testclient import TestClient
        from factory.api.server import app
        from factory.gates import run as gates
        from factory.smoke import run as smoke
        self.scout()
        quiet(gates.run)
        quiet(smoke.run)
        c = TestClient(app)
        st = c.get("/api/state").json()
        for k in ("gold", "elixir_month", "scouts_active", "buildings", "treasury", "net_30d",
                  "concentration_pct", "side_quests"):
            self.assertIn(k, st)
        kinds = {b["kind"] for b in st["buildings"]}
        self.assertTrue({"hq", "camp", "gate", "archive", "test"} <= kinds)
        for b in st["buildings"]:
            self.assertEqual(len(b["kv"]), 3)
            self.assertTrue(0 <= b["pile"] <= 3 and 0 <= b["rate"] <= 1)
        gate1 = next(b for b in st["buildings"] if b["id"] == "gate1")
        self.assertIn("Lease renewal reminders", gate1["desc"])
        self.assertGreater(st["elixir_month"], 0)
        test = next(b for b in st["buildings"] if b["kind"] == "test")
        endpoint = test["actions"][0]["endpoint"]
        self.assertTrue(endpoint.startswith("/api/approve/"))
        slug = None
        with session() as s:
            slug = s.exec(select(SmokeTest)).one().slug
        self.assertEqual(c.post(f"/api/event/{slug}?kind=visit").status_code, 200)
        self.assertEqual(c.get(f"/pages/{slug}/").status_code, 200)
        r = c.post(endpoint).json()
        self.assertIn("launch it by hand", r["message"])
        self.assertEqual(c.post(endpoint).status_code, 409)  # cannot approve twice
        self.assertIn("Venture Base", c.get("/").text)

    def test_winner_gets_spec(self):
        from datetime import timedelta
        from factory.gates import run as gates
        from factory.models import utcnow
        from factory.smoke import run as smoke
        self.scout()
        quiet(gates.run)
        t = quiet(smoke.run)[0][0]
        quiet(smoke.approve, t.id)
        with session() as s:
            st = s.get(SmokeTest, t.id)
            st.approved_at = utcnow() - timedelta(hours=10)
            s.add(st)
            for i in range(160):
                s.add(TrackEvent(slug=t.slug, kind="visit"))
            for i in range(10):
                s.add(TrackEvent(slug=t.slug, kind="buy_click"))
            s.commit()
        _, out = quiet(smoke.run)
        self.assertIn("settled: Lease Nudge won", out)
        self.assertTrue((config.VENTURES_DIR / t.slug / "CLAUDE.md").exists())

    def test_no_opus(self):
        with self.assertRaises(ValueError):
            costs.price("claude-opus-4-6")


def _first(n):
    from factory.seed import active_niches
    return active_niches()[:n]


if __name__ == "__main__":
    unittest.main()

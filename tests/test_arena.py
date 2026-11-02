"""State v2 + API tests: the arena must show only what the database says. FAKE DATA only."""
from __future__ import annotations

import unittest

from tests.base import FactoryTestCase

from factory.models import SmokeTest, session  # noqa: E402
from sqlmodel import select  # noqa: E402


class ArenaStateTest(FactoryTestCase):
    def client(self):
        from fastapi.testclient import TestClient
        from factory.api.server import app
        return TestClient(app)

    def test_contract_keys(self):
        self.to_smoke()
        st = self.client().get("/api/state").json()
        for k in ("gold", "elixir_month", "scouts_active", "buildings", "treasury", "net_30d",
                  "concentration_pct", "side_quests", "agents_total", "departments", "arena", "niches", "dossiers"):
            self.assertIn(k, st)
        self.assertEqual([t["n"] for t in st["arena"]["towers"]], [1, 2, 3, 4, 5, 6])
        self.assertEqual([t["side"] for t in st["arena"]["towers"]], ["free"] * 3 + ["money"] * 3)
        self.assertEqual({ln["position"] for ln in st["arena"]["lanes"]}, {"top", "mid", "bot"})
        for b in st["buildings"]:
            self.assertEqual(len(b["kv"]), 3, b["id"])
        ids = {b["id"] for b in st["buildings"]}
        self.assertTrue({"base", "market", "research", "dive", "warden", "archive", "t1", "t6"} <= ids)

    def test_unit_waits_at_tower_4_with_a_fund_button(self):
        self.to_smoke()
        st = self.client().get("/api/state").json()
        alive = [u for u in st["arena"]["units"] if u["state"] != "dead"]
        self.assertEqual(len(alive), 1)
        u = alive[0]
        self.assertEqual((u["tower"], u["state"], u["lane"]), (4, "blocked", "digital"))
        self.assertTrue(u["actions"][0]["endpoint"].startswith("/api/approve/"))
        self.assertEqual(u["dossier"]["capital"], 2600)  # R700 test in ZA
        t4 = next(t for t in st["arena"]["towers"] if t["n"] == 4)
        self.assertEqual(t4["waiting"], 1)
        self.assertEqual(st["dossiers"][0]["capital"], 2600)
        self.assertEqual(st["niches"][0]["stage"], "waiting for your R700")

    def test_runs_are_real_agent_runs_only(self):
        st = self.client().get("/api/state").json()
        self.assertEqual(st["arena"]["runs"], [])  # nothing ran, so nothing moves
        self.to_smoke()
        st = self.client().get("/api/state").json()
        roles = {r["role"] for r in st["arena"]["runs"]}
        self.assertTrue({"reddit scout", "Distiller", "Proof gatekeeper", "Craft gatekeeper", "Demand analyst",
                         "Capital estimator", "Smoke-test builder"} <= roles)
        dive = next(d for d in st["departments"] if d["id"] == "dive")
        self.assertEqual((dive["agents"], dive["working"]), (5, 0))
        warden = next(d for d in st["departments"] if d["id"] == "warden")
        self.assertEqual((warden["built"], warden["agents"]), (True, 4))  # built in Phase 3
        treasury = next(d for d in st["departments"] if d["id"] == "treasury")
        self.assertFalse(treasury["built"])  # Phase 6: shown as a construction site

    def test_approve_moves_the_unit_to_tower_5(self):
        self.to_smoke()
        c = self.client()
        with session() as s:
            t = s.exec(select(SmokeTest)).one()
        self.assertIn("launch it by hand", c.post(f"/api/approve/{t.id}").json()["message"])
        self.assertEqual(c.post(f"/api/approve/{t.id}").status_code, 409)  # cannot approve twice
        u = c.get("/api/state").json()["arena"]["units"][0]
        self.assertEqual((u["tower"], u["state"]), (5, "testing"))

    def test_dashboard_files_are_served(self):
        c = self.client()
        self.assertIn("Venture Base", c.get("/").text)
        self.assertIn("Arena", c.get("/arena.js").text)
        self.assertEqual(c.get("/app.js").status_code, 200)
        self.assertEqual(c.get("/secrets.js").status_code, 404)

    def test_killed_cards_show_at_their_tower_tonight(self):
        self.fake.price = 30.0  # the Deep Dive kills it at tower 3
        self.scout()
        self.gates()
        self.dive()
        st = self.client().get("/api/state").json()
        dead = [u for u in st["arena"]["units"] if u["state"] == "dead"]
        self.assertEqual([(u["tower"], u["status"]) for u in dead], [(3, "killed_dive")])
        archive = next(b for b in st["buildings"] if b["id"] == "archive")
        self.assertEqual(archive["kv"][0][0], "1")


if __name__ == "__main__":
    unittest.main()

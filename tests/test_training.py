"""Training Academy tests: fake Claude, temp DB. FAKE DATA only."""
from __future__ import annotations

import json
import unittest
from unittest import mock

from tests.base import FactoryTestCase

from factory import config  # noqa: E402
from factory.models import AgentRun, Card, Venture, session  # noqa: E402
from factory.training.tables import Squad, SquadAgent  # noqa: E402
from sqlmodel import select  # noqa: E402


def card():
    with session() as s:
        return s.exec(select(Card)).one()


def crew():
    with session() as s:
        sq = s.exec(select(Squad).order_by(Squad.id.desc())).first()
        return sq, {a.role: a for a in s.exec(select(SquadAgent).where(SquadAgent.squad_id == sq.id))}


class TrainingTest(FactoryTestCase):
    def client(self):
        from fastapi.testclient import TestClient
        from factory.api.server import app
        return TestClient(app)

    def test_winner_is_certified_and_waits_for_launch_money(self):
        t = self.to_won()
        res, out = self.train()
        self.assertEqual(res["certified"], 1, out)
        self.assertEqual(card().status, "certified")
        sq, agents = crew()
        self.assertEqual(set(agents), {"store", "content", "ads", "support", "books"})
        self.assertTrue(all(a.status == "passed" and a.score == 1.0 for a in agents.values()))
        folder = config.VENTURES_DIR / t.slug
        self.assertTrue((folder / "CLAUDE.md").exists())
        for role in agents:
            self.assertIn("## Never break these", (folder / "squad" / f"{role}.md").read_text())
        self.assertIn("Support agent", (folder / "squad" / "exams.md").read_text())
        cat = json.loads((folder / "squad" / "catalogue.json").read_text())
        self.assertEqual((cat["items"][0]["price"], cat["items"][0]["currency"]), (169.0, "ZAR"))  # the page's price
        self.assertIn("corrected", cat["notes"])
        st = self.client().get("/api/state").json()
        unit = next(u for u in st["arena"]["units"] if u["state"] != "dead")
        self.assertEqual((unit["tower"], unit["state"]), (6, "blocked"))
        self.assertEqual(unit["actions"][0]["label"], "FUND LAUNCH R1,900")  # R2,600 minus the R700 test
        self.assertEqual(len(unit["squad"]["agents"]), 5)
        depts = {d["id"]: d for d in st["departments"]}
        self.assertEqual((depts["train"]["agents"], depts["ops"]["agents"]), (6, 6))  # 1 builder + 5 standing by

    def test_exams_use_each_agents_own_model_and_drills_test_the_rules(self):
        self.to_won()
        self.train()
        models = [c.model for c in self.fake.calls if c.schema == "Replies"]
        self.assertEqual(len(models), 5)
        self.assertEqual(sorted(set(models)), ["claude-haiku-4-5", "claude-sonnet-4-6"])
        _, agents = crew()
        drills = agents["support"].j("scenarios")
        self.assertGreaterEqual(sum(d["tests_guardrail"] for d in drills), 2)
        with session() as s:
            roles = {r.role for r in s.exec(select(AgentRun).where(AgentRun.dept == "train"))}
        self.assertTrue({"Playbook writer", "Catalogue builder", "Prompt engineer", "Simulator", "Examiner",
                         "Certifier", "Exam · Support agent"} <= roles)

    def test_failed_agent_is_rewritten_keeps_its_guardrails_and_retakes(self):
        self.fake.exam_mode = "fail_once"
        self.to_won()
        self.train()
        self.assertEqual(card().status, "certified")
        sq, agents = crew()
        support = agents["support"]
        self.assertEqual((support.version, support.status, sq.attempts), (2, "passed", 2))
        self.assertEqual(support.j("revisions")[0]["changes"], "Added a refund rule.")
        for rule in config.squad()["guardrails"]:
            self.assertIn(rule, support.prompt)  # the rewrite dropped them; the code put them back

    def test_squad_not_certified_after_two_failures_needs_you(self):
        from factory.warden import health, report
        self.fake.exam_mode = "fail_always"
        self.to_won()
        res, _ = self.train()
        self.assertEqual(res["failed"], 1)
        self.assertEqual(card().status, "training_failed")
        sq, _ = crew()
        self.assertIn("Support agent failed", sq.notes)
        unit = next(u for u in self.client().get("/api/state").json()["arena"]["units"] if u["state"] != "dead")
        self.assertEqual(unit["actions"][0]["endpoint"], f"/api/train/{card().id}/retry")
        res = health.check()
        self.assertIn("training_failed", [i.kind for i in res["needs_you"]])
        with mock.patch("factory.warden.report.mailer.send", return_value=False):
            rep = report.save("weekly")
        self.assertIn("Retry training for", rep.body_md)
        self.assertEqual(self.client().post(f"/api/train/{card().id}/retry").status_code, 200)
        self.assertEqual(card().status, "won")  # back in the queue for tonight

    def test_fund_launch_gives_a_shopping_list_and_a_mine(self):
        self.to_won()
        self.train()
        c = self.client()
        msg = c.post(f"/api/launch/{card().id}").json()["message"]
        self.assertIn("Nothing is bought automatically. Your shopping list (R1,900)", msg)
        self.assertIn("- Domain: R250", msg)
        self.assertEqual(card().status, "building")
        with session() as s:
            self.assertEqual(s.exec(select(Venture)).one().status, "building")
        self.assertEqual(len(c.get("/api/state").json()["arena"]["mines"]), 1)
        self.assertEqual(c.post(f"/api/launch/{card().id}").status_code, 409)  # cannot launch twice

    def test_training_budget_cap(self):
        self.to_won()
        with mock.patch.dict(config.settings()["caps"], {"training_zar_per_squad": 0.0001}):
            res, out = self.train()
        self.assertIn("training budget used up", out)
        self.assertEqual(card().status, "training_failed")
        with session() as s:
            self.assertEqual(s.exec(select(AgentRun).where(AgentRun.role == "Playbook writer")).one().status, "blocked")


if __name__ == "__main__":
    unittest.main()

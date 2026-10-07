"""End-to-end pipeline tests: fake sources + fake Claude, temp DB. Run: make test"""
from __future__ import annotations

import json
import unittest
from pathlib import Path
from unittest import mock

from tests.base import FactoryTestCase, quiet

from factory import config, costs  # noqa: E402
from factory.models import Card, Cost, GateResult, SmokeTest, TrackEvent, session  # noqa: E402
from sqlmodel import select  # noqa: E402


class PipelineTest(FactoryTestCase):
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
        made, out = self.to_smoke()
        self.assertEqual(len(made), 1)
        t = made[0]
        self.assertEqual(t.status, "awaiting_funding")
        self.assertTrue(Path(t.page_path).exists())
        self.assertIn("Manual steps (META_ADS_ENABLED=false)", out)
        self.assertIn("If this test wins, the full start-up needs about R2,100", out)
        self.assertEqual(json.loads(t.ads_json)["budget_zar"], 200)
        html = Path(t.page_path).read_text()
        self.assertIn("We are onboarding founders this week, leave your email.", html)
        self.assertIn("buy_click", html)
        page_call = next(c for c in self.fake.calls if c.schema == "PageDraft")
        self.assertIn("$9 / month", page_call.prompt)  # the Deep Dive's price reaches the page writer

    def test_smoke_skips_cards_that_did_not_pass_the_deep_dive(self):
        self.scout()
        self.gates()
        made, out = self.smoke()
        self.assertEqual(made, [])
        self.assertIn("0 card(s) passed the Deep Dive", out)

    def test_winner_waits_for_training(self):
        from datetime import timedelta
        from factory.models import utcnow
        from factory.smoke import run as smoke
        t = self.to_smoke()[0][0]
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
        _, out = self.smoke()
        self.assertIn("settled: Lease Nudge won", out)
        with session() as s:
            self.assertEqual(s.exec(select(Card)).one().status, "won")  # now waits at tower 6 for Training
        self.assertFalse((config.VENTURES_DIR / t.slug / "CLAUDE.md").exists())  # Training writes the brief

    def test_no_opus(self):
        with self.assertRaises(ValueError):
            costs.price("claude-opus-4-6")



if __name__ == "__main__":
    unittest.main()

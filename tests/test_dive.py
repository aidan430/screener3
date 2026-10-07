"""Deep Dive tests: fake marketplaces + fake Claude, temp DB. FAKE DATA only."""
from __future__ import annotations

import unittest
from unittest import mock

from tests.base import FactoryTestCase

from factory.models import AgentRun, Card, Dossier, GateResult, session  # noqa: E402
from sqlmodel import select  # noqa: E402


class DeepDiveTest(FactoryTestCase):
    def run_dive(self):
        self.scout()
        self.gates()
        return self.dive()

    def dossier(self) -> Dossier:
        with session() as s:
            return s.exec(select(Dossier)).one()

    def test_pass_writes_a_dossier_with_rand_numbers(self):
        res, out = self.run_dive()
        self.assertEqual(res["passed"], 1, out)
        d = self.dossier()
        self.assertEqual((d.business_model, d.lane, d.verdict), ("micro_saas", "digital", "pass"))
        self.assertAlmostEqual(d.price_zar, 9 * 18.5)
        # micro-SaaS: 5% fees, 30% ad cost, 5% unit cost (assumption) -> 60% margin
        self.assertAlmostEqual(d.margin, 0.60, places=3)
        self.assertIn("assumption", d.unit_cost_basis)
        # Domain 250 + hosting 350 + smoke test 200 + first ad test 1300
        self.assertEqual(d.capital_zar, 2100)
        self.assertEqual(d.break_even_sales, 22)
        self.assertEqual(d.price_basis, "E1")
        evidence = d.j("evidence")
        self.assertEqual(evidence[0]["id"], "E0")
        self.assertTrue(evidence[1]["url"].startswith("https://apps.apple.com/"))
        with session() as s:
            card = s.exec(select(Card)).one()
            gate = s.exec(select(GateResult).where(GateResult.gate == "economics")).one()
        self.assertEqual(card.status, "dive_passed")
        self.assertEqual(gate.evidence, ["I pay someone R450 a month"])  # invented snippet dropped
        self.assertIn("start-up R2,100", out)

    def test_price_far_above_the_anchor_kills(self):
        self.fake.price = 30.0  # E1 is 9.99 USD
        res, out = self.run_dive()
        self.assertEqual(res["killed"], 1)
        d = self.dossier()
        self.assertEqual(d.verdict, "kill")
        self.assertTrue(any("more than 25% above E1" in r for r in d.j("kill_reasons")))
        with session() as s:
            self.assertEqual(s.exec(select(Card)).one().status, "killed_dive")

    def test_hard_risk_kills(self):
        self.fake.hard_kill = True
        res, _ = self.run_dive()
        self.assertEqual(res["killed"], 1)
        self.assertTrue(any(r.startswith("hard risk") for r in self.dossier().j("kill_reasons")))

    def test_capital_cap_kills(self):
        from factory import config
        with mock.patch.dict(config.settings()["caps"], {"niche_capital_zar": 1000}):
            self.run_dive()
        self.assertTrue(any("above your R1,000 cap" in r for r in self.dossier().j("kill_reasons")))

    def test_every_analyst_is_a_logged_agent_run(self):
        self.run_dive()
        with session() as s:
            runs = list(s.exec(select(AgentRun).where(AgentRun.dept == "dive")))
        self.assertEqual([r.role for r in runs], ["Demand analyst", "Competitor analyst", "Economics analyst",
                                                  "Risk analyst", "Capital estimator"])
        self.assertTrue(all(r.status == "ok" and r.tower == 3 and r.finished_at for r in runs))
        econ = next(r for r in runs if r.role == "Economics analyst")
        self.assertGreater(econ.cost_zar, 0)
        self.assertIn("micro_saas", econ.summary)

    def test_no_marketplace_data_is_recorded_not_invented(self):
        from factory.market.base import ProbeError

        def down(*a, **kw):
            raise ProbeError("App Store us HTTP 403")
        with mock.patch("factory.market.appstore.search", side_effect=down):
            self.run_dive()
        d = self.dossier()
        self.assertEqual(len(d.j("evidence")), 1)  # only the buyer's own post
        self.assertIn("probe problems", d.reasoning)
        self.assertEqual(d.verdict, "kill")  # E1 no longer exists, so the price is not anchored
        with session() as s:
            demand = s.exec(select(AgentRun).where(AgentRun.role == "Demand analyst")).one()
        self.assertEqual(demand.status, "failed")

    def test_stage_cap_stops_the_deep_dive(self):
        from factory import costs
        self.scout()
        self.gates()
        with mock.patch.object(costs, "stage_cap", lambda: 0.0001):
            res, out = self.dive()
        self.assertIn("STOPPED", out)
        with session() as s:
            self.assertEqual(s.exec(select(Card)).one().status, "craft_passed")  # waits for tomorrow


if __name__ == "__main__":
    unittest.main()

"""Commerce (South Africa, local stock) tests: fake Claude, temp DB. FAKE DATA only."""
from __future__ import annotations

import json
import unittest
from unittest import mock

from tests.base import FactoryTestCase

from factory import config  # noqa: E402
from factory.commerce import landed  # noqa: E402
from factory.models import AgentRun, Card, Dossier, Niche, SmokeTest, session  # noqa: E402
from factory.smoke import budget  # noqa: E402
from sqlmodel import select  # noqa: E402


def one(table):
    with session() as s:
        return s.exec(select(table).order_by(table.id.desc())).first()


class LandedCostTest(unittest.TestCase):
    def test_numbers_for_a_light_product(self):
        u = landed.unit_economics(599, 89.85, "assumption", weight_kg=0.3, cap=5000)
        # supplier 89.85 + freight 36 + duty 17.97 + import VAT 17.52 + clearing 600/26 + receiving and storage 5
        self.assertEqual(u["batch_units"], 26)
        self.assertAlmostEqual(u["landed_zar"], 189.42, places=1)
        self.assertAlmostEqual(u["contribution_zar"], 253.66, places=1)  # minus R108 per order and 8% of price
        self.assertAlmostEqual(u["break_even_conversion"], 4 / 253.66, places=3)
        self.assertLessEqual(u["batch_zar"], 5000)
        self.assertEqual(landed.gate_flags(u), [])

    def test_cheap_product_and_heavy_product_are_killed(self):
        cheap = landed.unit_economics(299, 55.5, "assumption", weight_kg=0.3)
        self.assertIn("must buy just to break even", landed.gate_flags(cheap)[0])
        heavy = landed.unit_economics(899, 160, "assumption", weight_kg=0.9, cap=5000)
        self.assertIn("buys only 13 units", landed.gate_flags(heavy)[0])

    def test_the_first_batch_fits_both_caps(self):
        from factory.dive import capital
        room = capital.stock_room("local_stock", 160)
        self.assertEqual(room, 10670)  # R15,000 start-up cap minus store, domain, photos, samples, test, ad test
        u = landed.unit_economics(899, 160, "assumption", weight_kg=0.9, cap=min(10000, room))
        self.assertEqual((u["batch_units"], landed.gate_flags(u)), (27, []))
        with mock.patch.dict(config.settings()["caps"], {"niche_capital_zar": 10000}):
            room = capital.stock_room("local_stock", 160)
        u = landed.unit_economics(899, 160, "assumption", weight_kg=0.9, cap=min(10000, room))
        self.assertIn("start-up cap leaves R5,670 for stock", landed.gate_flags(u)[0])

    def test_shop_price_and_test_budget(self):
        self.assertEqual((landed.retail_price(462), landed.retail_price(599)), (449, 599))
        self.assertEqual(budget.for_market("ZA"), 700)   # 150 visitors x R4 x 1.15, rounded up to R50
        self.assertEqual(budget.for_market("US"), 1000)  # capped: R1,000 buys only about 75 US visitors


class CommerceTest(FactoryTestCase):
    def client(self):
        from fastapi.testclient import TestClient
        from factory.api.server import app
        return TestClient(app)

    def test_commerce_niches_come_first_and_scout_reddit_only(self):
        self.scout(kind="commerce")
        with session() as s:
            active = list(s.exec(select(Niche).where(Niche.active == True)))  # noqa: E712
            roles = {r.role for r in s.exec(select(AgentRun).where(AgentRun.dept == "research"))}
        self.assertEqual(sum(n.kind == "commerce" for n in active), 4)
        self.assertEqual(sum(n.kind != "commerce" for n in active), 2)
        self.assertNotIn("hn scout", roles)
        card = one(Card)
        self.assertEqual((card.business_model, card.lane), ("local_stock", "commerce"))
        prompt = next(c for c in self.fake.calls if c.schema == "Distilled").prompt
        self.assertIn("Where can I buy", prompt)

    def test_a_good_product_passes_the_dive_and_its_test_is_priced_for_south_africa(self):
        self.to_smoke("commerce")
        d = one(Dossier)
        self.assertEqual((d.business_model, d.verdict), ("local_stock", "pass"), d.kill_reasons_json)
        self.assertEqual(d.currency, "ZAR")  # "R" in the post, normalised
        u = d.j("unit")
        self.assertEqual((u["batch_units"], d.break_even_sales), (40, 31))  # sunk R4,120 / R136.74 a sale
        self.assertLessEqual(d.capital_zar, 15000)  # the batch was sized to fit the start-up cap
        labels = [x[0] for x in d.j("capital_lines")]
        self.assertIn("First stock batch, 40 units", labels)
        t = one(SmokeTest)
        ads = json.loads(t.ads_json)
        self.assertEqual((t.price_label, ads["budget_zar"], ads["audience"]["countries"]), ("R599", 700, ["ZA"]))
        self.assertIn("first stock batch of 40 units", t.manual_steps)
        self.assertIn("We are taking first orders this week", open(t.page_path).read())
        gate_prompt = next(c for c in self.fake.calls if c.schema == "Verdict").prompt
        self.assertIn("Business model (scout's guess): local_stock (Local-stock store)", gate_prompt)

    def test_a_thin_product_is_killed_at_tower_3(self):
        self.fake.commerce_price = 449.0
        self.scout(kind="commerce")
        self.gates()
        _, out = self.dive()
        self.assertIn("of visitors must buy just to break even", out)
        self.assertEqual(one(Card).status, "killed_dive")

    def test_a_click_win_that_cannot_pay_for_its_ads_is_lost(self):
        self.fake.commerce_price = 549.0  # R226 left per order
        self.to_won("commerce", visits=160, clicks=8)  # 5% click Buy: about R230 of ads per real sale
        t = one(SmokeTest)
        self.assertEqual(t.status, "lost")
        self.assertIn("won on clicks", t.result)
        self.assertEqual(one(Card).status, "archived")

    def test_winner_gets_a_stock_squad_and_fund_stock_drafts_the_first_order(self):
        self.to_won("commerce")
        res, out = self.train()
        self.assertEqual(res["certified"], 1, out)
        from factory.training.tables import SquadAgent
        with session() as s:
            roles = {a.role for a in s.exec(select(SquadAgent))}
        self.assertEqual(roles, {"store", "ads", "support", "stock", "books"})
        c = self.client()
        unit = next(u for u in c.get("/api/state").json()["arena"]["units"] if u["state"] != "dead")
        self.assertTrue(unit["actions"][0]["label"].startswith("FUND STOCK R"))
        msg = c.post(f"/api/launch/{one(Card).id}").json()["message"]
        self.assertIn("Stock approved", msg)
        self.assertIn("First stock batch, 40 units", msg)
        order = config.VENTURES_DIR / one(SmokeTest).slug / "stock" / "first-order.md"
        self.assertIn("Nothing has been ordered or paid", order.read_text())
        spec_call = next(c for c in self.fake.calls if c.schema == "Spec")
        self.assertIn("left per order before ads", spec_call.prompt)  # the store brief gets the unit economics

    def test_rubric_carries_the_south_african_rules(self):
        from factory.gates.common import rubric
        craft, version = rubric("craft")
        self.assertIn("ICASA", craft)
        self.assertIn("fulfilment warehouse", craft)
        self.assertEqual(version, "2026-10-07.2")


if __name__ == "__main__":
    unittest.main()

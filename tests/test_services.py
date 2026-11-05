"""BPO (AI-run services for South African businesses) tests: fake Claude, temp DB. FAKE DATA only."""
from __future__ import annotations

import unittest
from pathlib import Path
from unittest import mock

from tests.base import FactoryTestCase, quiet

from factory import config  # noqa: E402
from factory.dive import economics  # noqa: E402
from factory.market import web  # noqa: E402
from factory.models import Card, Dossier, SmokeTest, session  # noqa: E402
from factory.services import unit  # noqa: E402
from sqlmodel import select  # noqa: E402


def one(table):
    with session() as s:
        return s.exec(select(table).order_by(table.id.desc())).first()


class ServiceUnitTest(unittest.TestCase):
    def test_one_client_month_for_a_support_desk(self):
        s = unit.unit_economics("ai_support", 2999)
        got = {label.split(",")[0]: v for label, v, _ in s["lines"]}
        self.assertEqual(s["volume"], 300)  # services.yaml default, labelled as an assumption
        self.assertIn("assumption", s["volume_basis"])
        self.assertAlmostEqual(got["AI agent"], 300 * (8000 * 1 + 600 * 5) / 1e6 * 18.5, places=2)  # R61.05
        self.assertAlmostEqual(got["WhatsApp replies"], 300 * 0.6 * 0.25, places=2)
        self.assertAlmostEqual(got["Supervisor takes 10% of conversations"], 300 * 0.1 * 5 / 60 * 120, places=2)
        self.assertAlmostEqual(got["Winning the client"], 1500 / 12, places=2)
        self.assertAlmostEqual(s["cost_zar"], sum(v for _, v, _ in s["lines"]), places=2)
        self.assertGreater(s["margin"], 0.5)
        self.assertAlmostEqual(s["delivery_zar"], s["cost_zar"] - s["fees_zar"] - s["cac_month_zar"], places=2)

    def test_volume_and_voice_change_the_cost(self):
        busy = unit.unit_economics("ai_support", 1499, volume=600, channel="whatsapp", volume_basis="evidence E2")
        self.assertEqual((busy["volume_basis"], busy["channel"]), ("evidence E2", "whatsapp"))
        self.assertLess(busy["margin"], 0.5)  # a cheap plan for a busy client does not pay
        voice = unit.unit_economics("ai_followup", 4999, channel="voice")
        self.assertTrue(any(label.startswith("Voice calls") for label, _, _ in voice["lines"]))
        self.assertEqual(unit.unit_economics("ai_followup", 4999, channel="fax")["channel"], "mixed")


class PayCheckTest(unittest.TestCase):
    def test_pay_period_is_read_from_the_page_words(self):
        cases = {"R9 500 per month": (9500, "per month"), "R8 000 - R10 000 per month": (8000, "per month"),
                 "R12 000 p/m plus commission": (12000, "per month"), "R95 per hour": (95, "per hour"),
                 "R150 000 per annum": (150000, "per year"), "R4 500 p.m.": (4500, "per month"),
                 "Takealot R449 in stock": (449, ""), "R9 500 basic plus annual bonus": (9500, ""),
                 "R8 000, apply by 5pm": (8000, "")}
        for text, want in cases.items():
            self.assertEqual((web.price_in(text), web.period_in(text)), want, text)

    def _econ(self, **kw):
        base = {"business_model": "ai_support", "price_point": 2999, "currency": "R", "price_unit": "per month",
                "price_basis_id": "E1", "demand_score": 7, "competition_score": 7, "score": 8,
                "reasoning": "r", "evidence": []}
        return economics.Econ(**{**base, **kw})

    def test_a_monthly_price_needs_a_comparable_anchor(self):
        hourly = {"E1": {"id": "E1", "price": 95, "currency": "ZAR", "period": "per hour"}}
        flags = economics.compute(self._econ(), hourly)["flags"]
        self.assertTrue(any("per month but E1 is per hour" in f for f in flags), flags)
        yearly = {"E1": {"id": "E1", "price": 114000, "currency": "ZAR", "period": "per year"}}
        self.assertEqual(economics.compute(self._econ(), yearly)["flags"], [])  # R9,500 a month: R2,999 undercuts
        above = economics.compute(self._econ(price_point=14999), yearly)["flags"]
        self.assertTrue(any("more than 25% above" in f for f in above), above)

    def test_a_service_is_sold_monthly_and_voice_answering_is_not_offered_yet(self):
        items = {"E1": {"id": "E1", "price": 36000, "currency": "ZAR", "period": "per year"}}
        n = economics.compute(self._econ(price_point=36000, price_unit="per year"), items)
        self.assertEqual((n["price_zar"], n["flags"]), (3000, []))  # a yearly price becomes its monthly share
        self.assertTrue(economics.compute(self._econ(price_unit="one-off"),
                                          {"E1": {"id": "E1", "price": 9500, "currency": "ZAR"}})["flags"])
        voice = economics.compute(self._econ(channel="voice"), {"E1": {"id": "E1", "price": 9500, "currency": "R"}})
        self.assertEqual(voice["service"]["channel"], "mixed")


class ServicesTest(FactoryTestCase):
    def test_a_job_advert_becomes_a_support_desk_card(self):
        _, out = self.scout(kind="services")
        card = one(Card)
        self.assertEqual((card.business_model, card.lane), ("ai_support", "services"), out)
        self.assertIn("R9 500 per month", card.pay_evidence)
        scout = next(c for c in self.fake.calls if c.schema == "web_search")
        self.assertIn("Category: online stores support", scout.prompt)

    def test_the_dive_prices_one_client_month_and_passes(self):
        self.scout(kind="services")
        self.gates()
        _, out = self.dive()
        d = one(Dossier)
        self.assertEqual((d.business_model, d.verdict), ("ai_support", "pass"), d.kill_reasons_json)
        sv = d.j("service")
        self.assertEqual((sv["price_zar"], d.price_unit, d.margin), (2999, "per month", sv["margin"]))
        self.assertGreaterEqual(d.margin, 0.5)
        self.assertEqual(d.j("unit"), {})
        labels = [x[0] for x in d.j("capital_lines")]
        self.assertIn("Free pilot month for the first client", labels)
        self.assertLessEqual(d.break_even_sales, 12)  # client-months
        self.assertIn("client-months", out)
        pay = [e for e in d.j("evidence") if e["source"] == "web" and e["id"] != "E0"]  # E0: the scout's page
        self.assertEqual(sorted((e["price"], e["period"]) for e in pay),
                         [(95, "per hour"), (4500, "per month"), (8000, "per month")])
        self.assertEqual(d.j("evidence")[0]["period"], "per month")  # E0: the job advert's salary
        material = next(c for c in self.fake.calls if c.schema == "Econ").prompt
        self.assertIn("price 4500 ZAR per month", material)

    def test_a_cited_volume_counts_only_if_the_page_says_it(self):
        self.fake.service_price = 1499  # a cheap plan for a busy client: 500 conversations, cited from E2
        self.fake.service_extra = {"volume_per_month": 500, "volume_basis_id": "E2"}
        self.scout(kind="services")
        self.gates()
        self.dive()
        d = one(Dossier)
        self.assertEqual((d.j("service")["volume"], d.j("service")["volume_basis"]), (500, "evidence E2"))
        self.assertEqual(d.verdict, "kill")
        self.assertTrue(any("margin" in r for r in d.j("kill_reasons")), d.kill_reasons_json)
        material = next(c for c in self.fake.calls if c.schema == "Econ").prompt
        self.assertIn('quote "Outsourced WhatsApp support from R4 500 per month', material)

    def test_a_volume_the_evidence_does_not_show_is_an_assumption(self):
        self.fake.service_extra = {"volume_per_month": 900, "volume_basis_id": "E0"}
        self.scout(kind="services")
        self.gates()
        self.dive()
        d = one(Dossier)
        self.assertEqual(d.j("service")["volume"], 300)  # services.yaml default
        self.assertIn("assumption", d.j("service")["volume_basis"])
        self.assertIn("the analyst's 900 a month is not in E0", d.unit_cost_basis)

    def test_test_page_speaks_to_business_owners_in_rand_a_month(self):
        made, out = self.to_smoke("services")
        t = made[0]
        self.assertEqual(t.price_label, "R2,999 / month")
        page = Path(t.page_path).read_text()
        self.assertIn("first businesses this month", page)
        self.assertIn("you@yourbusiness.co.za", page)
        draft = next(c for c in self.fake.calls if c.schema == "PageDraft").prompt
        self.assertIn("never that people do", draft)
        self.assertIn("client-months", t.manual_steps)
        self.assertIn("business owners", t.manual_steps)

    def test_a_click_win_is_judged_on_what_a_client_leaves(self):
        from factory.smoke import track
        t = self.to_won("services", visits=160, clicks=9)
        with session() as s:
            st = s.get(SmokeTest, t.id)
            self.assertEqual(st.status, "won", st.result)
            self.assertEqual(track.customer_cost(s, st, True), "")

    def test_training_builds_a_bpo_squad_and_launch_writes_the_first_client_checklist(self):
        from factory.build import launch
        from factory.training.tables import Squad, SquadAgent
        self.to_won("services")
        self.train()
        with session() as s:
            sq = s.exec(select(Squad)).first()
            crew = list(s.exec(select(SquadAgent).where(SquadAgent.squad_id == sq.id)))
        self.assertEqual(sq.status, "certified", sq.notes)
        self.assertEqual(sorted(a.role for a in crew), ["ads", "books", "desk", "qa", "reporter"])
        desk = next(a for a in crew if a.role == "desk")
        for rule in config.squad()["guardrails"]:
            self.assertIn(rule, desk.prompt)
        self.assertIn("operator (POPIA section 21)", desk.prompt)
        brief = next(c for c in self.fake.calls if c.schema == "Spec")
        self.assertIn("Per client per month", brief.prompt)
        card = one(Card)
        res, _ = quiet(launch.launch, card.id)
        self.assertTrue(res["ok"], res)
        self.assertIn("first-client.md", res["message"])
        self.assertNotIn("Smoke test", res["message"])
        checklist = (config.VENTURES_DIR / sq.slug / "client" / "first-client.md").read_text()
        for must in ("Nothing has been signed", "sections 20 and 21", "section 69", "Information Regulator", "R2,999"):
            self.assertIn(must, checklist)

    def test_followup_squad_has_the_followup_agent(self):
        roles = config.squad_roles("services", "ai_followup")
        self.assertEqual(list(roles), ["ads", "followup", "qa", "reporter", "books"])
        self.assertEqual(list(config.squad_roles("commerce", "local_stock")), ["store", "ads", "support", "stock", "books"])
        with mock.patch.dict(config.squad(), {"models": {}}):
            self.assertEqual(list(config.squad_roles("services")), config.squad()["default_roles"])


if __name__ == "__main__":
    unittest.main()

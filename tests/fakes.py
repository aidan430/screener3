"""Test doubles. FAKE DATA: never written to data/factory.db.

FakeClaude stands in for anthropic.Anthropic and answers by output schema.
FAKE_POSTS are invented forum posts used only to exercise the pipeline.
"""
from __future__ import annotations

import os
import tempfile
from types import SimpleNamespace

from factory.scouts.sources.base import RawSignal

FAKE_POSTS = [
    RawSignal(source="reddit", external_id="reddit:t1", url="https://www.reddit.com/r/test/comments/t1/",
              title="Is there a tool for lease renewals?",
              text="I pay someone R450 a month just to send lease renewal reminders to my six tenants. "
                   "Is there a tool that does this automatically for South African leases?",
              score=14, replies=9, matched=["is there a tool", "I pay someone to"]),
    RawSignal(source="hn", external_id="hn:t2", url="https://news.ycombinator.com/item?id=2",
              title="Ask HN: deposit interest calculation",
              text="Tracking rental deposit interest by hand in a spreadsheet takes me hours every quarter.",
              score=4, replies=3, matched=["takes me hours", "rental deposit"]),
]


def fake_draft(signal_ids: list[int]):
    from factory.scouts.distill import CardDraft, Distilled
    a, b = signal_ids[0], signal_ids[-1]  # one post is fine: the second draft then fails the verbatim check
    return Distilled(cards=[
        CardDraft(signal_id=a, title="Lease renewal reminders", problem="Small SA landlords pay people to chase renewals.",
                  quote="I pay someone R450 a month just to send lease renewal reminders to my six tenants.",
                  pay_evidence="I pay someone R450 a month", pay_amount=450, pay_currency="R",
                  business_model="micro_saas"),
        CardDraft(signal_id=b, title="Invented card", problem="This quote does not exist in the post.",
                  quote="Landlords everywhere are begging for an app and would pay R999.",
                  pay_evidence="", pay_amount=None),
    ])


class FakeMessages:
    def __init__(self, owner):
        self.owner = owner

    def parse(self, *, model, max_tokens, system, messages, output_format):
        self.owner.calls.append(SimpleNamespace(model=model, schema=output_format.__name__, prompt=messages[0]["content"]))
        name = output_format.__name__
        prompt = messages[0]["content"]
        if name == "Distilled":
            import re
            ids = [int(x) for x in re.findall(r'<post id="(\d+)"', prompt)]
            out = fake_draft(ids)
        elif name == "Verdict":
            out = self.owner.verdict(system, prompt)
        elif name == "PageDraft":
            from factory.smoke.page import AdVariant, PageDraft, Targeting
            out = PageDraft(product_name="Lease Nudge", headline="Lease renewals that send themselves",
                            subhead="Reminders for SA landlords.", benefits=["a", "b", "c"],
                            price_label="R99 / month", cta="Buy now",
                            ads=[AdVariant(primary_text=f"v{i}", headline=f"h{i}") for i in range(3)],
                            targeting=Targeting(countries=["ZA"], interests=["Property"]))
        elif name == "Plan":
            from factory.dive.demand import Plan
            out = Plan(terms=["lease renewal reminders", "rent reminder"], business_model="micro_saas")
        elif name == "Econ":
            out = self.owner.econ()
        elif name == "Risks":
            from factory.dive.risk import RiskItem, Risks
            out = Risks(risks=[RiskItem(risk="Tenant data must follow POPIA.", severity="medium",
                                        hard_kill=self.owner.hard_kill)], summary="One data-protection risk.")
        elif name == "Spec":
            from factory.build.spec import Spec
            out = Spec(claude_md="# Lease Nudge\n\nFAKE SPEC FOR TESTS")
        else:
            raise AssertionError(name)
        usage = SimpleNamespace(input_tokens=len(system + prompt) // 4, output_tokens=300,
                                cache_read_input_tokens=0, cache_creation_input_tokens=0)
        return SimpleNamespace(parsed_output=out, usage=usage, stop_reason="end_turn")


class FakeClaude:
    def __init__(self):
        self.calls = []
        self.messages = FakeMessages(self)
        self.price = 9.0          # anchored to E1 (9.99 USD) unless a test changes it
        self.hard_kill = False

    def econ(self):
        from factory.dive.economics import Econ
        return Econ(business_model="micro_saas", price_point=self.price, currency="USD", price_unit="per month",
                    price_basis_id="E1", demand_score=7, competition_score=6, score=8,
                    reasoning="Landlords pay R450 a month for a person; apps charge $9.99.",
                    evidence=["I pay someone R450 a month", "an invented snippet"])

    def verdict(self, system, prompt):
        from factory.gates.common import Verdict
        if "Gate of Proof" in system:
            if "Lease renewal" in prompt:
                return Verdict(score=7, verdict="pass", reasoning="Rule 3: pays a person R450/month.",
                               evidence=["I pay someone R450 a month", "a quote the model made up"])
            return Verdict(score=2, verdict="kill", reasoning="No money.", evidence=[])
        return Verdict(score=8, verdict="pass", reasoning="Cron + SMS, 3 days.", evidence=["no sales calls"])


def fake_probe(term, market="us", limit=10, http=None):
    """FAKE App Store search result used instead of the network."""
    from factory.market.base import Listing, Probe
    return Probe(source="appstore", market=market, term=term, total=12, listings=[
        Listing(source="appstore", market=market, title="RentReminder Pro", price=9.99, currency="USD",
                url=f"https://apps.apple.com/{market}/app/rentreminder/id1", metric=1200,
                metric_label="ratings", rating=3.1, ext_id="1")])


def temp_env():
    d = tempfile.mkdtemp(prefix="vf-test-")
    os.environ["FACTORY_DB"] = os.path.join(d, "test.db")
    return d

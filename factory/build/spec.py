"""Training's Playbook writer, part 1: the venture brief.

Sonnet writes ventures/{slug}/CLAUDE.md for a smoke-test winner (data model,
stack, pricing, Paystack, first 5 SEO pages). A local-stock product gets a
store brief instead (store, product page, warehouse, returns, stock), and a
service for businesses a service brief (offer, tools, onboarding, consent and
privacy, winning clients). Called by factory/training/run.py.
The human starts the Claude Code session that builds it, after funding the launch.
"""
from __future__ import annotations

import json

from pydantic import BaseModel
from sqlmodel import select

from factory import config, costs
from factory.commerce import landed
from factory.models import Card, Dossier, GateResult, Niche, SmokeTest, session
from factory.services import unit as service_unit

SYSTEM = """You write the operational brief (a CLAUDE.md) that a Claude Code session
will follow to build a small paid web product in under 7 days, solo, with no
humans in the loop. Be concrete and short. Use only facts given to you; where
you choose a default, say so. Sections, in order:
# <Product name>
## What this is (problem, buyer, evidence url, smoke-test result)
## Stack (default: Python 3.11 + FastAPI + SQLite + HTMX, deployed on Vercel or Fly; justify any change)
## Data model (tables and fields)
## Pricing (one plan, the price that won the smoke test)
## Payments (Paystack by default: checkout link, webhook to /api/paystack, plan codes)
## Pages and flows (landing, signup, core tool, billing)
## First 5 SEO pages (title + target query + one-line outline each)
## Build order (day by day, max 7 days)
## Done means (acceptance checks)
## Never (money, posting publicly, personal data rules)"""


STORE_SYSTEM = """You write the operational brief (a CLAUDE.md) that a Claude Code session
will follow to set up a small online store in South Africa selling one physical
product from stock held by a fulfilment warehouse, run by AI agents with the
owner approving all money. Be concrete and short. Use only facts given to you;
where you choose a default, say so. Sections, in order:
# <Store name>
## What this is (product, buyer, evidence url, smoke-test result)
## Store (default: Shopify with one product page and policy pages; justify any change)
## Product page (title, price in rand, three benefits, photos needed, FAQs)
## Payments (Paystack by default: cards and instant EFT)
## Fulfilment (the warehouse's Shopify app or API: orders flow in, tracking flows back to the buyer)
## Delivery and returns (delivery is free and built into the price; returns follow South African
   consumer law: the 7-day cooling-off for online purchases and returns of defective goods; confirm the current rules)
## Unit economics (landed cost, cost per order, break-even conversion, from the facts given)
## Launch campaign (Meta ads in South Africa, inside the budget the owner approved)
## Stock (first batch, reorder point in days of cover, the owner approves every reorder)
## Done means (acceptance checks)
## Never (money, posting publicly, personal data rules)"""


SERVICE_SYSTEM = """You write the operational brief (a CLAUDE.md) that a Claude Code session
will follow to set up a small AI-run service business in South Africa: AI agents
answer customers or follow up leads for client businesses, a person supervises,
and the owner approves all money and signs every client contract. Be concrete and
short. Use only facts given to you; where you choose a default, say so. Sections, in order:
# <Business name>
## What this is (the service, the client businesses, evidence url, smoke-test result)
## Offer (one plan per client per month at the price that won the smoke test: what is included,
   monthly volume, hours covered, the hand-over to the client's own people)
## Channels and tools (default: a shared helpdesk for email and chat, the WhatsApp Business
   Platform through an approved provider, a booking calendar; justify any change)
## Client onboarding (service agreement and POPIA operator agreement signed first; then the
   client's FAQs, policies and hand-over contacts; test conversations; go-live)
## How the agents work (which agent does what, when a person takes over, QA sampling, the monthly report)
## Privacy and consent (we process each client's customer data as its operator, POPIA section 21;
   contact only people who asked or are customers, with an opt-out in every message, POPIA
   section 69 and the CPA; contact hours; recording notices; confirm the current rules)
## Payments (Paystack by default: a monthly card or debit-order subscription per client)
## Unit economics (cost and margin per client per month, from the facts given)
## Winning clients (Meta ads to business owners in South Africa inside the approved budget;
   reply only to businesses that asked; no cold calls or cold messages)
## Done means (acceptance checks)
## Never (money, posting publicly, contacting people who did not ask, mixing clients' data)"""


class Spec(BaseModel):
    claude_md: str


def write_brief(t: SmokeTest, cap_zar: float | None = None) -> str:
    """Write ventures/{slug}/CLAUDE.md for a smoke-test winner. Returns its path."""
    with session() as s:
        card = s.get(Card, t.card_id)
        niche = s.get(Niche, card.niche_id)
        gates = list(s.exec(select(GateResult).where(GateResult.card_id == card.id)))
        dossier = s.exec(select(Dossier).where(Dossier.card_id == card.id).order_by(Dossier.id.desc())).first()
    unit = dossier.j("unit") if dossier else {}
    service = dossier.j("service") if dossier else {}
    rate = (t.buy_clicks / t.visitors) if t.visitors else 0
    prompt = (f"Product name: {t.name}\nHeadline: {t.headline}\nPrice: {t.price_label}\n"
              f"Niche: {niche.slug} ({niche.region})\nProblem: {card.problem}\n"
              f"Buyer quote: \"{card.quote}\" ({card.url})\nPay evidence: {card.pay_evidence or 'none'}\n"
              f"Smoke test: {t.visitors} visitors, {t.buy_clicks} buy-clicks ({rate:.1%})\n"
              f"Gate notes: " + " | ".join(f"{g.gate} {g.score}/10: {g.reasoning}" for g in gates) +
              f"\nAd set used: {json.dumps(json.loads(t.ads_json).get('variants', []))}"
              + ("\nUnit economics (Deep Dive, rand):\n" + "\n".join(landed.lines(unit)) if unit else "")
              + ("\nPer client per month (Deep Dive, rand):\n" + "\n".join(service_unit.lines(service))
                 if service else ""))
    out = costs.call(stage_name="train", model=config.settings()["models"]["judge"],
                     system=STORE_SYSTEM if unit else SERVICE_SYSTEM if service else SYSTEM,
                     prompt=prompt, output=Spec, max_tokens=6000, card_id=card.id, cap_zar=cap_zar,
                     note="venture brief")
    d = config.VENTURES_DIR / t.slug
    d.mkdir(parents=True, exist_ok=True)
    (d / "CLAUDE.md").write_text(out.claude_md)
    return str(d / "CLAUDE.md")

"""Training's Playbook writer, part 1: the venture brief.

Sonnet writes ventures/{slug}/CLAUDE.md for a smoke-test winner (data model,
stack, pricing, Paystack, first 5 SEO pages). Called by factory/training/run.py.
The human starts the Claude Code session that builds it, after funding the launch.
"""
from __future__ import annotations

import json

from pydantic import BaseModel
from sqlmodel import select

from factory import config, costs
from factory.models import Card, GateResult, Niche, SmokeTest, session

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


class Spec(BaseModel):
    claude_md: str


def write_brief(t: SmokeTest, cap_zar: float | None = None) -> str:
    """Write ventures/{slug}/CLAUDE.md for a smoke-test winner. Returns its path."""
    with session() as s:
        card = s.get(Card, t.card_id)
        niche = s.get(Niche, card.niche_id)
        gates = list(s.exec(select(GateResult).where(GateResult.card_id == card.id)))
    rate = (t.buy_clicks / t.visitors) if t.visitors else 0
    prompt = (f"Product name: {t.name}\nHeadline: {t.headline}\nPrice: {t.price_label}\n"
              f"Niche: {niche.slug} ({niche.region})\nProblem: {card.problem}\n"
              f"Buyer quote: \"{card.quote}\" ({card.url})\nPay evidence: {card.pay_evidence or 'none'}\n"
              f"Smoke test: {t.visitors} visitors, {t.buy_clicks} buy-clicks ({rate:.1%})\n"
              f"Gate notes: " + " | ".join(f"{g.gate} {g.score}/10: {g.reasoning}" for g in gates) +
              f"\nAd set used: {json.dumps(json.loads(t.ads_json).get('variants', []))}")
    out = costs.call(stage_name="train", model=config.settings()["models"]["judge"], system=SYSTEM,
                     prompt=prompt, output=Spec, max_tokens=6000, card_id=card.id, cap_zar=cap_zar,
                     note="venture brief")
    d = config.VENTURES_DIR / t.slug
    d.mkdir(parents=True, exist_ok=True)
    (d / "CLAUDE.md").write_text(out.claude_md)
    return str(d / "CLAUDE.md")

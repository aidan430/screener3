"""Sonnet writes a full CLAUDE.md for each smoke-test winner.

Output: ventures/{slug}/CLAUDE.md (data model, stack, pricing, Paystack, first
5 SEO pages). The human starts that Claude Code session.
Usage: python -m factory.build.spec
"""
from __future__ import annotations

import json

from pydantic import BaseModel
from sqlmodel import select

from factory import agents, config, costs
from factory.models import Build, Card, GateResult, Niche, SmokeTest, session

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


def write(t: SmokeTest) -> Build:
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
    out = costs.call(stage_name="spec", model=config.settings()["models"]["judge"], system=SYSTEM,
                     prompt=prompt, output=Spec, max_tokens=6000, card_id=card.id)
    d = config.VENTURES_DIR / t.slug
    d.mkdir(parents=True, exist_ok=True)
    (d / "CLAUDE.md").write_text(out.claude_md)
    b = Build(smoke_id=t.id, slug=t.slug, spec_path=str(d / "CLAUDE.md"))
    with session() as s:
        s.add(b)
        c = s.get(Card, card.id)
        c.status = "building"
        s.add(c)
        s.commit()
    return b


def run() -> list[Build]:
    with session() as s:
        done = {b.smoke_id for b in s.exec(select(Build))}
        winners = [t for t in s.exec(select(SmokeTest).where(SmokeTest.status == "won")) if t.id not in done]
    builds = []
    with costs.stage("spec"):
        for t in winners:
            with session() as s:
                card = s.get(Card, t.card_id)
            with agents.run("train", "Playbook writer", subject=t.name, card=card, tower=6) as job:
                b = write(t)
                job.summary = f"wrote the venture brief for {t.name}"
            from factory.build import launch
            launch.scaffold(b)
            builds.append(b)
            print(f"  spec written: {b.spec_path}")
    if not winners:
        print("  no smoke-test winners waiting for a spec")
    return builds


if __name__ == "__main__":
    config.setup_logging()
    run()

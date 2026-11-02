"""Deep Dive: the Risk analyst (Sonnet). Any hard_kill risk kills at the Economics gate."""
from __future__ import annotations

from typing import Literal

from pydantic import BaseModel

from factory import config, costs

SYSTEM = """You are the Risk analyst in a venture studio's Deep Dive department.
List the legal, platform, payment, intellectual-property and reputational risks
of selling this product as a {model} to buyers in {markets}, run by one founder
and AI agents.

Set hard_kill only for risks that make the business unworkable for that founder:
medical or health claims, regulated products (weapons, drugs, supplements,
financial or legal advice), trademark or copyright infringement built into the
product, a marketplace or ad platform that bans the category, or collecting
health, children's, biometric or credit data. Everything else is low, medium
or high without hard_kill.

At most 5 risks, each one short sentence. summary: one sentence."""


class RiskItem(BaseModel):
    risk: str
    severity: Literal["low", "medium", "high"]
    hard_kill: bool = False


class Risks(BaseModel):
    risks: list[RiskItem]
    summary: str


def assess(card, niche, model: str, comps: list[dict], cap_zar: float) -> Risks:
    label = config.business_models()["models"][model]["label"]
    markets = "South Africa and global English-speaking markets" if niche.region == "ZA" else "global markets"
    names = ", ".join(c["name"][:60] for c in comps[:5]) or "none found"
    prompt = (f"Card: {card.title}\nProblem: {card.problem}\nBuyer quote: \"{card.quote}\"\n"
              f"Business model: {label}\nExisting competitors: {names}")
    return costs.call(stage_name="dive", model=config.settings()["models"]["judge"],
                      system=SYSTEM.format(model=label, markets=markets), prompt=prompt, output=Risks,
                      max_tokens=600, card_id=card.id, cap_zar=cap_zar, note="risk analyst")

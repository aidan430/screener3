"""Training: the Playbook writer (policies), the Catalogue builder, and the Prompt
engineer's first draft of every squad agent's instructions.

Everything is grounded in the card, its Dossier and its smoke test. Where the
writer has to choose (a refund window, a tone), it says so in the text.
"""
from __future__ import annotations

from pydantic import BaseModel, Field

from factory import config, costs

SOPS_SYSTEM = """You are the Playbook writer in a venture studio's Training Academy. A niche
has just won its smoke test. Write the operating policies its squad of AI agents
will follow. Use only the facts given. Where you must choose a policy (refund
window, reply time), choose something fair and common for this business model
and write "(our default)" after it. No invented reviews, numbers or features.
role_rules: 3 to 5 short, concrete rules for each role: {roles}."""

CATALOGUE_SYSTEM = """You are the Catalogue builder in a venture studio's Training Academy. List
what this niche will sell, based only on the facts given. The main item's price
must be exactly the Deep Dive price given. Describe only what the smoke-test page
promised; put anything you had to assume in `notes`. Keep it to 1-3 items."""


class FAQ(BaseModel):
    question: str
    answer: str


class RoleRules(BaseModel):
    role: str = Field(description="one of the role keys")
    rules: list[str]


class Sops(BaseModel):
    brand_voice: str
    offer_summary: str
    refund_policy: str
    delivery_policy: str
    escalation: str
    faqs: list[FAQ]
    role_rules: list[RoleRules]


class Item(BaseModel):
    name: str
    description: str
    price: float
    currency: str
    unit: str = Field(description='"one-off", "per month" or "per year"')
    includes: list[str]


class Catalogue(BaseModel):
    items: list[Item]
    notes: str = ""


def facts(card, niche, dossier, smoke) -> str:
    label = config.business_models()["models"].get(dossier.business_model if dossier else card.business_model,
                                                   {}).get("label", "unknown model")
    lines = [f"Niche: {niche.slug} (region {niche.region})", f"Business model: {label}",
             f"Problem: {card.problem}", f"Buyer quote: \"{card.quote}\" ({card.url})",
             f"Product name: {smoke.name}", f"Smoke-test headline: {smoke.headline}",
             f"Smoke-test result: {smoke.buy_clicks} buy-clicks from {smoke.visitors} visitors",
             f"Price: {dossier.price_point:g} {dossier.currency} {dossier.price_unit}" if dossier and dossier.price_point
             else f"Price on the smoke-test page: {smoke.price_label}"]
    if dossier:
        lines.append(f"Deep Dive reasoning: {dossier.reasoning[:600]}")
        lines += [f"Risk: {r['risk']} ({r['severity']})" for r in dossier.j("risks")[:4]]
    return "\n".join(lines)


def write_sops(card, material: str, cap_zar: float) -> Sops:
    roles = ", ".join(config.squad()["roles"])
    sops = costs.call(stage_name="train", model=config.settings()["models"]["judge"],
                      system=SOPS_SYSTEM.format(roles=roles), prompt=material, output=Sops,
                      max_tokens=3000, card_id=card.id, cap_zar=cap_zar, note="playbook writer")
    known = set(config.squad()["roles"])
    sops.role_rules = [r for r in sops.role_rules if r.role in known]
    return sops


def build_catalogue(card, material: str, dossier, cap_zar: float) -> Catalogue:
    cat = costs.call(stage_name="train", model=config.settings()["models"]["judge"], system=CATALOGUE_SYSTEM,
                     prompt=material, output=Catalogue, max_tokens=1500, card_id=card.id, cap_zar=cap_zar,
                     note="catalogue builder")
    if dossier and dossier.price_point and cat.items:
        main = cat.items[0]
        if abs(main.price - dossier.price_point) > 0.01 or main.currency.upper() != dossier.currency.upper():
            cat.notes = (cat.notes + " " if cat.notes else "") + (
                f"Main price corrected from {main.price:g} {main.currency} to the Deep Dive price.")
            main.price, main.currency = dossier.price_point, dossier.currency
    return cat


def compose(role_key: str, product: str, material: str, sops: Sops, cat: Catalogue) -> str:
    """The Prompt engineer's first draft: a fixed template filled from the playbook and catalogue."""
    role = config.squad()["roles"][role_key]
    rules = next((r.rules for r in sops.role_rules if r.role == role_key), [])
    items = "\n".join(f"- {i.name}: {i.price:g} {i.currency} {i.unit}. {i.description} Includes: {', '.join(i.includes)}."
                      for i in cat.items)
    faqs = "\n".join(f"- Q: {f.question}\n  A: {f.answer}" for f in sops.faqs)
    guard = "\n".join(f"- {g}" for g in config.squad()["guardrails"])
    return (f"You are the {role['name']} for {product}.\nYour job: {role['job']}\n\n"
            f"## Facts about this business\n{material}\n\n## What we sell\n{items}\n"
            + (f"Catalogue notes: {cat.notes}\n" if cat.notes else "")
            + f"\n## Brand voice\n{sops.brand_voice}\n\n## Policies\nOffer: {sops.offer_summary}\n"
            f"Refunds: {sops.refund_policy}\nDelivery: {sops.delivery_policy}\nEscalation: {sops.escalation}\n\n"
            f"## Your rules\n" + "\n".join(f"- {r}" for r in rules) + f"\n\n## FAQs\n{faqs}\n\n"
            f"## Never break these\n{guard}\n")

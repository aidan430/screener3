"""Deep Dive: the Economics analyst.

Sonnet picks the business model and a price point anchored to a cited evidence
item. Code then does the arithmetic in rand: fees, assumed ad cost per sale,
unit cost (from cited evidence, otherwise a labelled assumption) and margin.
A local-stock product is priced in rand and costed by factory/commerce/landed.py.
"""
from __future__ import annotations

import json

from pydantic import BaseModel, Field

from factory import config, costs
from factory.commerce import landed

SYSTEM = """You are the Economics analyst in a venture studio's Deep Dive department.
Decide how this niche would make money and whether the numbers can work for one
founder whose business is run by AI agents.

Rules:
- Use only the evidence given. Anchor the price to one evidence item: set
  price_basis_id to its id (E0 is the buyer's own post). Your price_point may
  match or undercut that item and may be at most 25% above it, in its currency.
- unit_cost: fill it only if an evidence item shows a cost per unit (a supplier
  or wholesale price) and cite it in unit_cost_basis_id. Otherwise leave it
  null; the system then applies a labelled assumption.
- business_model must be one of: {models}.
- local_stock is a physical product sold in South Africa from a small batch of
  stock held by a fulfilment warehouse. For it, also estimate weight_kg (packed,
  per unit) and duty_category (one of: {duties}). Its unit_cost is a supplier or
  wholesale price per unit, never a retail price.
- demand_score 0-10: how much paying demand the evidence shows (ratings,
  favourites, listing counts, people asking to pay).
- competition_score 0-10: 10 = existing options are weak, overpriced or
  complained about; 0 = crowded with strong, cheap options.
- score 0-10 overall for a solo founder with agents; 7+ means worth a smoke test.
- evidence: up to 4 short snippets copied verbatim from the material.
- reasoning: 3-5 plain sentences."""


class Econ(BaseModel):
    business_model: str
    price_point: float = Field(gt=0)
    currency: str = Field(description="ISO code of the cited item's price, e.g. USD, GBP, ZAR")
    price_unit: str = Field(description='"one-off", "per month" or "per year"')
    price_basis_id: str
    unit_cost: float | None = None
    unit_cost_currency: str = ""
    unit_cost_basis_id: str = ""
    weight_kg: float | None = Field(default=None, description="local_stock only: packed kg per unit")
    duty_category: str = Field(default="default", description="local_stock only: customs duty category")
    demand_score: int = Field(ge=0, le=10)
    competition_score: int = Field(ge=0, le=10)
    score: int = Field(ge=0, le=10)
    reasoning: str
    evidence: list[str]


def _material(card, niche, model: str, items: dict, stats: dict, comps: list[dict]) -> str:
    lines = [f"Niche: {niche.slug} (region {niche.region})", f"Card: {card.title}",
             f"Problem: {card.problem}", f"Planner's business model: {model}", "", "Evidence items:"]
    for k, it in items.items():
        bits = [k, it["source"], it.get("market") or "", it["title"][:120]]
        if it.get("price"):
            bits.append(f"price {it['price']:g} {it.get('currency', '')}")
        if it.get("metric"):
            bits.append(f"{int(it['metric'])} {it.get('metric_label', '')}")
        if it.get("quote"):
            bits.append(f'quote "{it["quote"][:300]}"')
        lines.append(" | ".join(b for b in bits if b))
    lines += ["", "Marketplace totals: " + json.dumps(
        {s: {k: v for k, v in d.items() if k in ("reported_total", "price", "price_currency", "metric_total")}
         for s, d in stats.items()}, default=str)]
    lines += ["", "Competitors:"] + [
        f"- {c['name'][:80]} ({c['source']}, {c.get('price')} {c.get('currency', '')}, rating {c.get('rating')})"
        + "".join(f'\n    complaint: "{q}"' for q in c.get("complaints", [])) for c in comps]
    return "\n".join(lines)


def analyse(card, niche, model: str, items: dict, stats: dict, comps: list[dict], cap_zar: float) -> tuple[Econ, str]:
    models = config.enabled_models()
    material = _material(card, niche, model, items, stats, comps)
    e = costs.call(stage_name="dive", model=config.settings()["models"]["judge"],
                   system=SYSTEM.format(models=", ".join(models), duties=", ".join(config.commerce()["duty"])),
                   prompt=material, output=Econ,
                   max_tokens=1200, card_id=card.id, cap_zar=cap_zar, note="economics analyst")
    if e.business_model not in models:
        e.business_model = model if model in models else models[0]
    return e, material


SYMBOLS = {"R": "ZAR", "$": "USD", "US$": "USD", "£": "GBP", "€": "EUR", "A$": "AUD", "C$": "CAD"}


def code(currency: str | None) -> str:
    """ISO code for a currency as written in a post ("R" -> "ZAR")."""
    c = (currency or "").strip()
    return SYMBOLS.get(c, c.upper())


def compute(e: Econ, items: dict) -> dict:
    """Rand arithmetic. Returns numbers plus `flags`: reasons the Economics gate must kill."""
    m = config.business_models()["models"][e.business_model]
    e.currency, e.unit_cost_currency = code(e.currency), code(e.unit_cost_currency)
    flags: list[str] = []
    basis = items.get(e.price_basis_id)
    if basis is None:
        flags.append(f"price not anchored to evidence (unknown id {e.price_basis_id})")
    elif not basis.get("price"):
        flags.append(f"{e.price_basis_id} shows no price to anchor to")
    else:
        if code(basis.get("currency")) not in ("", e.currency):
            flags.append(f"price currency {e.currency} differs from {e.price_basis_id} ({basis.get('currency')})")
        elif e.price_point > float(basis["price"]) * 1.25:
            flags.append(f"price {e.price_point:g} is more than 25% above {e.price_basis_id} ({basis['price']:g})")
    price_zar = config.to_zar(e.price_point, e.currency)
    out = {"price_zar": price_zar, "fees_zar": None, "cac_zar": None, "unit_cost_zar": None,
           "unit_cost_basis": "", "unit_profit_zar": None, "margin": None, "flags": flags, "unit": None}
    if price_zar is None:
        flags.append(f"no exchange rate for {e.currency} in settings.fx_zar")
        return out
    if m.get("landed"):
        return _local_stock(e, items, out, m)
    uc = None
    if e.unit_cost is not None and e.unit_cost_basis_id in items:
        uc = config.to_zar(e.unit_cost, e.unit_cost_currency or e.currency)
        basis_txt = f"evidence {e.unit_cost_basis_id}"
    if uc is None:
        uc = price_zar * float(m["unit_cost_pct"])
        basis_txt = f"assumption: {float(m['unit_cost_pct']):.0%} of price (business_models.yaml)"
    fees, cac = price_zar * float(m["fee_pct"]), price_zar * float(m["cac_pct"])
    profit = price_zar - fees - cac - uc
    out.update(fees_zar=round(fees, 2), cac_zar=round(cac, 2), unit_cost_zar=round(uc, 2),
               unit_cost_basis=basis_txt, unit_profit_zar=round(profit, 2),
               margin=round(profit / price_zar, 4), price_zar=round(price_zar, 2))
    return out


def _local_stock(e: Econ, items: dict, out: dict, m: dict) -> dict:
    """A South African warehouse product: a shop price in rand and its landed unit economics."""
    price, sup = landed.retail_price(out["price_zar"]), None
    if e.unit_cost is not None and e.unit_cost_basis_id in items:
        sup = config.to_zar(e.unit_cost, e.unit_cost_currency or e.currency)
        basis = f"evidence {e.unit_cost_basis_id}"
    if sup is None:
        pct = float(m["unit_cost_pct"])
        sup, basis = price * pct, f"assumption: {pct:.0%} of price (business_models.yaml)"
    u = landed.unit_economics(price, sup, basis, e.weight_kg, e.duty_category)
    out["flags"] += landed.gate_flags(u)
    profit = u["profit_good_zar"]  # if it converts like the top fifth of stores
    out.update(price_zar=price, fees_zar=u["per_order_zar"], cac_zar=u["cac_good_zar"], unit_cost_zar=u["landed_zar"],
               unit_cost_basis=f"landed in SA; supplier price {basis}", unit_profit_zar=profit,
               margin=round(profit / price, 4), unit=u)
    return out

"""Deep Dive: the Economics analyst.

Sonnet picks the business model and a price point anchored to a cited evidence
item. Code then does the arithmetic in rand: fees, assumed ad cost per sale,
unit cost (from cited evidence, otherwise a labelled assumption) and margin.
A local-stock product is priced in rand and costed by factory/commerce/landed.py;
a service for businesses is priced per client per month by factory/services/unit.py.
"""
from __future__ import annotations

import json

from pydantic import BaseModel, Field

from factory import config, costs
from factory.commerce import landed
from factory.dive import capital
from factory.scouts.distill import amount_in
from factory.services import unit

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
- ai_support and ai_followup are services sold to South African businesses: AI
  agents answer a business's customers (ai_support) or follow up leads who asked to
  be contacted (ai_followup), and a person supervises. Price them in ZAR per month
  per client, anchored to what a business pays for this work today: a salary in a
  job advert or an outsourced provider's price, ideally an item marked per month.
  Set volume_per_month (conversations or leads a month for one client) only if an
  evidence item shows a volume, and cite it in volume_basis_id; otherwise leave it
  null and the system applies a labelled assumption. channel: email, whatsapp or
  mixed; voice only for ai_followup.
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
    volume_per_month: int | None = Field(default=None, description="services only: conversations or leads a month")
    volume_basis_id: str = ""
    channel: str = Field(default="", description="services only: email, whatsapp, voice or mixed")
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
            bits.append(f"price {it['price']:g} {it.get('currency', '')} {it.get('period') or ''}".strip())
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
        anchor, period = float(basis["price"]), basis.get("period") or ""
        if period and period != e.price_unit:  # compare like with like: a year is 12 months
            if {period, e.price_unit} == {"per month", "per year"}:
                anchor = anchor / 12 if period == "per year" else anchor * 12
            else:
                flags.append(f"price is {e.price_unit} but {e.price_basis_id} is {period}")
        if code(basis.get("currency")) not in ("", e.currency):
            flags.append(f"price currency {e.currency} differs from {e.price_basis_id} ({basis.get('currency')})")
        elif e.price_point > anchor * 1.25:
            flags.append(f"price {e.price_point:g} is more than 25% above {e.price_basis_id} "
                         f"({basis['price']:g}{' ' + period if period else ''})")
    price_zar = config.to_zar(e.price_point, e.currency)
    out = {"price_zar": price_zar, "fees_zar": None, "cac_zar": None, "unit_cost_zar": None,
           "unit_cost_basis": "", "unit_profit_zar": None, "margin": None, "flags": flags, "unit": None}
    if price_zar is None:
        flags.append(f"no exchange rate for {e.currency} in settings.fx_zar")
        return out
    if m.get("landed"):
        return _local_stock(e, items, out, m)
    if m.get("service"):
        return _service(e, items, out)
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
    room = capital.stock_room(e.business_model, sup)  # the batch must fit both caps
    cap = min(float(config.settings()["caps"]["stock_batch_zar"]), room)
    u = landed.unit_economics(price, sup, basis, e.weight_kg, e.duty_category, cap=cap)
    out["flags"] += landed.gate_flags(u)
    profit = u["profit_good_zar"]  # if it converts like the top fifth of stores
    out.update(price_zar=price, fees_zar=u["per_order_zar"], cac_zar=u["cac_good_zar"], unit_cost_zar=u["landed_zar"],
               unit_cost_basis=f"landed in SA; supplier price {basis}", unit_profit_zar=profit,
               margin=round(profit / price, 4), unit=u)
    return out


def _service(e: Econ, items: dict, out: dict) -> dict:
    """A service for South African businesses: its price and cost per client per month."""
    if e.price_unit == "per year":  # sold monthly: a yearly figure becomes its monthly share
        e.price_point, e.price_unit, out["price_zar"] = round(e.price_point / 12, 2), "per month", out["price_zar"] / 12
    elif e.price_unit != "per month":
        out["flags"].append(f"a service is sold per month, not {e.price_unit}")
    vol, basis, note = None, "", ""
    if e.volume_per_month:  # evidence only if the cited item's own words hold that number
        it = items.get(e.volume_basis_id) or {}
        if amount_in(e.volume_per_month, f"{it.get('title', '')} {it.get('quote') or ''}"):
            vol, basis = int(e.volume_per_month), f"evidence {e.volume_basis_id}"
        else:
            note = f"; the analyst's {e.volume_per_month} a month is not in {e.volume_basis_id or 'any item'}"
    channel = (e.channel or "").strip().lower()
    if channel == "voice" and e.business_model != "ai_followup":
        channel = "mixed"  # answering calls by voice is not offered yet
    s = unit.unit_economics(e.business_model, out["price_zar"], vol, channel, basis)
    out.update(price_zar=s["price_zar"], fees_zar=s["fees_zar"], cac_zar=s["cac_month_zar"],
               unit_cost_zar=s["delivery_zar"], unit_profit_zar=s["margin_zar"], margin=s["margin"], service=s,
               unit_cost_basis=f"one client's month: {s['volume']} {s['what']} ({s['volume_basis']}{note}); "
                               f"AI, channels, supervisor and tools are assumptions (config/services.yaml)")
    return out

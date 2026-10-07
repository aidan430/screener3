"""Deep Dive: the Capital estimator and the Economics gate (both plain code).

Start-up capital = the model's fixed lines from business_models.yaml + samples
at unit cost + the smoke-test budget + the first ad test after a win. A local-
stock product adds its samples by express courier and its first stock batch.
Break-even sales = the capital you do not get back (everything but the stock
batch, which comes back as it sells) / unit profit.
"""
from __future__ import annotations

import math

from factory import config
from factory.smoke import budget

SRC = "assumption: business_models.yaml"
STOCK = "First stock batch"


def estimate(model: str, unit_cost_zar: float | None, unit: dict | None = None) -> tuple[list[list], float]:
    m = config.business_models()["models"][model]
    lines = [[label, float(amount), SRC] for label, amount in m["capital"]]
    n = int(m.get("samples") or 0)
    if unit:  # local stock: samples by express courier, then the first batch for the warehouse
        if n:
            ship = float(config.commerce()["inbound"]["sample_shipping_zar"])
            lines.append([f"Product samples x{n}, express courier", round(n * unit["supplier_zar"] + ship, 2),
                          "samples x supplier price + courier (assumption)"])
        lines.append([f"{STOCK}, {unit['batch_units']} units", unit["batch_zar"], "units x landed cost"])
    elif n and unit_cost_zar:
        lines.append([f"Product samples x{n}", round(n * unit_cost_zar, 2), "samples x unit cost"])
    lines.append(["Smoke test ads, 48 h", float(budget.for_market()), "settings.yaml (smoke)"])
    if m.get("ad_test"):
        lines.append(["First ad test after a win", float(m["ad_test"]), SRC])
    return lines, round(sum(x[1] for x in lines), 2)


def sunk(lines: list[list]) -> float:
    """Capital that selling does not return: everything except the stock batch."""
    return round(sum(x[1] for x in lines if not x[0].startswith(STOCK)), 2)


def break_even(capital_zar: float, unit_profit_zar: float | None) -> int | None:
    if not unit_profit_zar or unit_profit_zar <= 0:
        return None
    return math.ceil(capital_zar / unit_profit_zar)


def gate(model: str, score: int, numbers: dict, capital_zar: float, be: int | None, risks) -> tuple[str, list[str]]:
    th, caps = config.settings()["thresholds"], config.settings()["caps"]
    m = config.business_models()["models"][model]
    reasons = list(numbers.get("flags", []))
    if score < int(th["dive_min_score"]):
        reasons.append(f"score {score}/10 is below {th['dive_min_score']}")
    margin = numbers.get("margin")
    # a local-stock product is judged on break-even conversion and its stock batch (numbers["flags"])
    if not m.get("landed") and (margin is None or margin < float(m["min_margin"])):
        shown = "unknown" if margin is None else f"{margin:.0%}"
        reasons.append(f"margin {shown} is below the {float(m['min_margin']):.0%} minimum for {m['label']}")
    if capital_zar > float(caps["niche_capital_zar"]):
        reasons.append(f"start-up capital R{capital_zar:,.0f} is above your R{float(caps['niche_capital_zar']):,.0f} cap")
    if be is None or be > int(th["max_break_even_sales"]):
        reasons.append("never breaks even" if be is None
                       else f"needs {be} sales to break even (max {th['max_break_even_sales']})")
    for r in risks:
        if r.hard_kill:
            reasons.append(f"hard risk: {r.risk}")
    return ("kill" if reasons else "pass"), reasons

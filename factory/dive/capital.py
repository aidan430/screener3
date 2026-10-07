"""Deep Dive: the Capital estimator and the Economics gate (both plain code).

Start-up capital = the model's fixed lines from business_models.yaml + samples
at unit cost + the smoke-test budget + the first ad test after a win.
Break-even sales = capital / unit profit.
"""
from __future__ import annotations

import math

from factory import config

SRC = "assumption: business_models.yaml"


def estimate(model: str, unit_cost_zar: float | None) -> tuple[list[list], float]:
    m = config.business_models()["models"][model]
    lines = [[label, float(amount), SRC] for label, amount in m["capital"]]
    n = int(m.get("samples") or 0)
    if n and unit_cost_zar:
        lines.append([f"Product samples x{n}", round(n * unit_cost_zar, 2), "samples x unit cost"])
    lines.append(["Smoke test ads, 48 h", float(config.settings()["smoke"]["budget_zar"]), "settings.yaml"])
    if m.get("ad_test"):
        lines.append(["First ad test after a win", float(m["ad_test"]), SRC])
    return lines, round(sum(x[1] for x in lines), 2)


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
    if margin is None or margin < float(m["min_margin"]):
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

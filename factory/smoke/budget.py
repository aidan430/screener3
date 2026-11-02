"""Smoke-test ad budget: enough clicks to reach the visitor minimum in the test market.

budget = visitors needed x cost per click x headroom, rounded up to R50 and
capped at smoke.max_budget_zar. In South Africa (about R4 a click) that is R700.
A test keeps the budget it was prepared with, even if settings change later.
"""
from __future__ import annotations

import json
import math

from factory import config


def cpc(market: str | None = None) -> float:
    sm = config.settings()["smoke"]
    table = sm["cpc_zar"]
    return float(table.get((market or sm["market"]).upper(), table[sm["market"]]))


def for_market(market: str | None = None) -> int:
    sm = config.settings()["smoke"]
    need = int(config.settings()["thresholds"]["win_min_visitors"])
    raw = need * cpc(market) * float(sm["headroom"])
    return int(min(float(sm["max_budget_zar"]), math.ceil(raw / 50) * 50))


def of(test) -> int:
    """The budget a prepared smoke test asks for (stored in its ad set)."""
    try:
        stored = json.loads(test.ads_json or "{}").get("budget_zar")
    except (TypeError, ValueError):
        stored = None
    return int(stored) if stored else for_market()

"""Draft the ad set JSON (3 variants, audience, budget for the test market, 48 h) and the manual steps.

Never calls the Meta API unless the test is APPROVED *and* META_ADS_ENABLED=true.
"""
from __future__ import annotations

import json
import logging

from factory import config
from factory.smoke import budget
from factory.smoke.page import PageDraft

log = logging.getLogger("factory.smoke.ads")


def ad_set(d: PageDraft, url: str, slug: str) -> dict:
    sm = config.settings()["smoke"]
    return {
        "name": f"smoke-{slug}",
        "objective": "OUTCOME_TRAFFIC",
        "budget_zar": budget.for_market(),
        "duration_hours": sm["duration_hours"],
        "destination_url": url,
        "audience": {**d.targeting.model_dump(), "countries": [sm["market"]]},  # the budget is priced for it
        "placements": "advantage_plus",
        "variants": [v.model_dump() for v in d.ads[: sm["variants"]]],
        "success_metric": {
            "event": "buy_click",
            "win_rate": config.settings()["thresholds"]["win_buy_click_rate"],
            "min_visitors": config.settings()["thresholds"]["win_min_visitors"],
        },
    }


def manual_steps(ads: dict) -> str:
    v = ads["variants"]
    a = ads["audience"]
    lines = [
        f"Smoke test '{ads['name']}' is ready and waiting on you. Nothing has been spent.",
        "Manual steps (META_ADS_ENABLED=false):",
        "1. Open Meta Ads Manager -> Create -> Objective: Traffic.",
        f"2. Campaign name: {ads['name']}. Budget: lifetime R{ads['budget_zar']}, "
        f"schedule {ads['duration_hours']} hours from now.",
        f"3. Audience: countries {', '.join(a['countries'])}, age {a['age_min']}-{a['age_max']}, "
        f"interests: {', '.join(a['interests'][:6])}. Placements: Advantage+.",
        f"4. Destination URL: {ads['destination_url']}",
        f"5. Create {len(v)} ads, one per variant:",
    ]
    for i, var in enumerate(v, 1):
        lines.append(f"   {i}) headline \"{var['headline']}\" | text \"{var['primary_text']}\"")
    lines += [
        "6. Publish. The factory reads visitors and buy_click events for 48 h.",
        f"   Win = buy_click/visitors >= {ads['success_metric']['win_rate']:.0%} "
        f"with >= {ads['success_metric']['min_visitors']} visitors.",
    ]
    return "\n".join(lines)


def launch_if_enabled(ads: dict) -> str:
    """Called only after /api/approve. Returns a status line for the dashboard."""
    if not config.env_flag("META_ADS_ENABLED"):
        steps = manual_steps(ads)
        log.warning("META_ADS_ENABLED=false; manual steps:\n%s", steps)
        return "manual"
    token, account = config.env("META_ACCESS_TOKEN"), config.env("META_AD_ACCOUNT_ID")
    if not (token and account):
        log.error("META_ADS_ENABLED=true but META_ACCESS_TOKEN / META_AD_ACCOUNT_ID missing")
        return "manual"
    # TODO(meta): create campaign -> ad set -> creatives -> ads via the Marketing API
    # (graph.facebook.com/v21.0/act_{account}/campaigns ...). Left unimplemented on
    # purpose until the Meta developer app exists; falls back to manual steps.
    log.warning("Meta Marketing API launch not implemented yet; use manual steps. %s", json.dumps(ads)[:200])
    return "manual"

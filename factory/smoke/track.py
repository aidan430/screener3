"""Read visitors and buy_click events, then settle tests that have enough data.

Source of numbers: Plausible Stats API when PLAUSIBLE_API_KEY is set and the
page is on the factory domain; otherwise our own TrackEvent beacons.
"""
from __future__ import annotations

import logging

import httpx
from sqlmodel import func, select

from factory import config
from factory.models import Card, SmokeTest, TrackEvent, session, utcnow

log = logging.getLogger("factory.smoke.track")


def local_counts(slug: str) -> tuple[int, int]:
    with session() as s:
        def n(kind):
            return s.exec(select(func.count()).select_from(TrackEvent)
                          .where(TrackEvent.slug == slug, TrackEvent.kind == kind)).one()
        return n("visit"), n("buy_click")


def plausible_counts(slug: str) -> tuple[int, int] | None:
    key, domain = config.env("PLAUSIBLE_API_KEY"), config.env("FACTORY_DOMAIN")
    if not (key and domain):
        return None
    site = f"{slug}.{domain}"
    try:
        with httpx.Client(timeout=20, headers={"Authorization": f"Bearer {key}"}) as c:
            agg = c.get("https://plausible.io/api/v1/stats/aggregate",
                        params={"site_id": site, "period": "7d", "metrics": "visitors"}).json()
            ev = c.get("https://plausible.io/api/v1/stats/breakdown",
                       params={"site_id": site, "period": "7d", "property": "event:name",
                               "metrics": "visitors"}).json()
        visitors = int(agg["results"]["visitors"]["value"])
        clicks = sum(int(r["visitors"]) for r in ev.get("results", []) if r.get("name") == "buy_click")
        return visitors, clicks
    except Exception as e:
        log.warning("plausible read failed for %s: %s", site, e)
        return None


def refresh() -> list[SmokeTest]:
    th = config.settings()["thresholds"]
    settled = []
    with session() as s:
        for t in s.exec(select(SmokeTest).where(SmokeTest.status.in_(["awaiting_funding", "approved"]))):
            counts = (plausible_counts(t.slug) if t.deploy_target == "vercel" else None) or local_counts(t.slug)
            t.visitors, t.buy_clicks = counts
            if t.status == "approved" and t.approved_at:
                hours = (utcnow() - t.approved_at).total_seconds() / 3600
                if t.visitors >= th["win_min_visitors"]:
                    rate = t.buy_clicks / t.visitors
                    if rate >= th["win_buy_click_rate"]:
                        t.status = "won"
                    elif hours >= config.settings()["smoke"]["duration_hours"]:
                        t.status = "lost"
                elif hours >= config.settings()["smoke"]["duration_hours"] * 2:
                    t.status = "lost"       # never reached the visitor minimum
                if t.status in ("won", "lost"):
                    card = s.get(Card, t.card_id)
                    card.status = "won" if t.status == "won" else "archived"
                    s.add(card)
                    settled.append(t)
            s.add(t)
        s.commit()
    return settled

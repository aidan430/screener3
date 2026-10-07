"""Read visitors and buy_click events, then settle tests that have enough data.

Source of numbers: Plausible Stats API when PLAUSIBLE_API_KEY is set and the
page is on the factory domain; otherwise our own TrackEvent beacons.

A test that clears the buy-click bar must also pay for its ads: if each real
sale would cost more in ads than the order leaves, it settles as lost and says
why. Every test records the reason it settled in `result`.
"""
from __future__ import annotations

import logging

import httpx
from sqlmodel import func, select

from factory import config
from factory.models import Card, Dossier, SmokeTest, TrackEvent, session, utcnow
from factory.smoke import budget

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


def customer_cost(s, t: SmokeTest, full: bool) -> str:
    """Why a click-win would still lose money on ads, or "" if each sale pays for its ads."""
    d = s.exec(select(Dossier).where(Dossier.card_id == t.card_id).order_by(Dossier.id.desc())).first()
    if not d or not t.visitors or not t.buy_clicks:
        return ""
    sm = config.settings()["smoke"]
    per_visitor = budget.cpc() * float(sm["headroom"])  # planned; the real spend is known only at the end
    if full:
        per_visitor = max(per_visitor, budget.of(t) / t.visitors)
    cpa = per_visitor / (t.buy_clicks / t.visitors * float(sm["click_to_purchase"]))
    unit = d.j("unit")
    if unit:
        left = unit["contribution_zar"]
    elif d.price_zar is not None:
        months = float(sm["ltv_months"]) if d.price_unit == "per month" else 1.0
        left = (d.price_zar - (d.fees_zar or 0) - (d.unit_cost_zar or 0)) * months
    else:
        return ""
    if cpa <= left:
        return ""
    return (f"won on clicks, but at about R{per_visitor:,.2f} a visitor each sale would cost about R{cpa:,.0f} "
            f"in ads against R{left:,.0f} left per order")


def refresh() -> list[SmokeTest]:
    th = config.settings()["thresholds"]
    settled = []
    with session() as s:
        for t in s.exec(select(SmokeTest).where(SmokeTest.status.in_(["awaiting_funding", "approved"]))):
            counts = (plausible_counts(t.slug) if t.deploy_target == "vercel" else None) or local_counts(t.slug)
            t.visitors, t.buy_clicks = counts
            if t.status == "approved" and t.approved_at:
                hours = (utcnow() - t.approved_at).total_seconds() / 3600
                full = hours >= config.settings()["smoke"]["duration_hours"]
                if t.visitors >= th["win_min_visitors"]:
                    rate = t.buy_clicks / t.visitors
                    if rate >= th["win_buy_click_rate"]:
                        reason = customer_cost(s, t, full)
                        t.status, t.result = ("lost", reason) if reason else (
                            "won", f"{rate:.1%} of {t.visitors} visitors clicked Buy")
                    elif full:
                        t.status = "lost"
                        t.result = f"only {rate:.1%} of {t.visitors} visitors clicked Buy (need {th['win_buy_click_rate']:.0%})"
                elif hours >= config.settings()["smoke"]["duration_hours"] * 2:
                    t.status = "lost"       # never reached the visitor minimum
                    t.result = f"only {t.visitors} visitors in {hours:.0f} hours (need {th['win_min_visitors']})"
                if t.status in ("won", "lost"):
                    card = s.get(Card, t.card_id)
                    card.status = "won" if t.status == "won" else "archived"
                    s.add(card)
                    settled.append(t)
            s.add(t)
        s.commit()
    return settled

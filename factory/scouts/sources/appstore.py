"""App Store scout: the latest 1-2 star reviews of the niche's named competitor apps.

A complaint about a paid competitor is Proof-gate evidence (rule 2). Uses the
public iTunes Search API and review RSS, so no key is needed. ZA niches look
in the South African store first, then the configured global markets.
"""
from __future__ import annotations

import logging

from factory import config
from factory.market import appstore
from factory.market.base import ProbeError, client
from factory.scouts.sources.base import RawSignal, SourceError, matches

log = logging.getLogger("factory.scouts.appstore")
NAME = "appstore"


def countries(niche) -> list[str]:
    base = list(config.settings()["markets"]["appstore_countries"])
    first = ["za"] if niche.region == "ZA" else []
    return first + [c for c in base if c not in first]


def fetch(niche) -> list[RawSignal]:
    if not niche.competitors:
        return []
    limit = int(config.settings()["markets"]["reviews_per_app"])
    terms = niche.keywords + niche.competitors + config.phrases_for(niche)
    found: dict[str, RawSignal] = {}
    errors: list[str] = []
    with client() as http:
        for comp in niche.competitors:
            app = None
            for country in countries(niche)[:2]:
                try:
                    app = appstore.find_app(comp, country, http=http)
                except ProbeError as e:
                    errors.append(str(e))
                    continue
                if app:
                    break
            if not app:
                continue
            try:
                revs = appstore.reviews(app, max_stars=2, limit=limit, http=http)
            except ProbeError as e:
                errors.append(str(e))
                continue
            price = "free" if not app.price else f"{app.price:g} {app.currency}"
            for r in revs:
                title = f"{app.title} ({price}, {int(app.metric or 0)} ratings) {r.rating}-star review: {r.title}"
                sig = RawSignal(source=NAME, external_id=f"appstore:{app.ext_id}:{r.review_id}",
                                url=app.url, title=title, text=r.text,
                                matched=matches(f"{title} {r.text}", terms) or [comp])
                found[sig.external_id] = sig
    if not found and errors:
        raise SourceError("; ".join(errors[:3]))
    return list(found.values())

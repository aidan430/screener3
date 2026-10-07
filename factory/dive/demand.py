"""Deep Dive: the Demand analyst and the Competitor analyst.

Demand analyst: Haiku turns a card into up to 3 marketplace search terms and a
business-model guess, then probes the marketplaces that model calls for (App
Store, Etsy, eBay) across the configured global markets.
Competitor analyst: ranks what came back and adds the niche's named competitor
apps with their verbatim 1-2 star reviews.
Every number here comes straight from a marketplace response, with its url.
"""
from __future__ import annotations

import logging
from collections import defaultdict

from pydantic import BaseModel, Field

from factory import config, costs
from factory.market import appstore, ebay, etsy
from factory.market.base import NeedsKey, Probe, ProbeError, client, price_stats

log = logging.getLogger("factory.dive.demand")

PLAN_SYSTEM = """You plan marketplace research for a product idea. Return up to {n}
short search terms (1-4 words each) that a buyer would type into the App Store,
Etsy or eBay to find an existing paid solution to the card's problem, and the
business model that fits a solo founder best: one of {models}.
Use only the card given. No brand names unless the card names one."""


class Plan(BaseModel):
    terms: list[str] = Field(description="1-3 marketplace search terms")
    business_model: str = Field(description="one of the allowed business models")


def plan(card, niche, cap_zar: float) -> Plan:
    n = int(config.settings()["dive"]["search_terms"])
    models = config.enabled_models()
    prompt = (f"Niche: {niche.slug} (region {niche.region}). Keywords: {', '.join(niche.keywords)}.\n"
              f"Card: {card.title}\nProblem: {card.problem}\nBuyer quote: \"{card.quote}\"\n"
              f"Scout's model guess: {card.business_model or 'none'}")
    out = costs.call(stage_name="dive", model=config.settings()["models"]["scout"],
                     system=PLAN_SYSTEM.format(n=n, models=", ".join(models)), prompt=prompt,
                     output=Plan, max_tokens=300, card_id=card.id, cap_zar=cap_zar, note="query planner")
    terms = [t.strip() for t in out.terms if t and t.strip()][:n] or [card.title]
    fallback = card.business_model if card.business_model in models else (
        "local_stock" if getattr(niche, "kind", "") == "commerce" else "digital_product")
    model = out.business_model if out.business_model in models else fallback
    return Plan(terms=terms, business_model=model)


def _markets(source: str) -> list[str]:
    mk = config.settings()["markets"]
    return {"appstore": mk["appstore_countries"], "ebay": mk["ebay_marketplaces"]}.get(source, ["etsy"])


def probe(terms: list[str], model: str) -> tuple[list[Probe], list[str]]:
    """Run every probe the model calls for. Returns probes and plain-English notes on failures."""
    sources = config.business_models()["models"][model]["probes"]
    limit = int(config.settings()["markets"]["listings_per_probe"])
    probes, notes = [], []
    with client() as http:
        for src in sources:
            try:
                for term in terms:
                    for market in _markets(src):
                        try:
                            if src == "appstore":
                                probes.append(appstore.search(term, market, limit, http=http))
                            elif src == "etsy":
                                probes.append(etsy.search(term, limit, http=http))
                            elif src == "ebay":
                                probes.append(ebay.search(term, market, limit, http=http))
                        except NeedsKey:
                            raise
                        except ProbeError as e:
                            notes.append(str(e))
                            log.warning("probe failed: %s", e)
            except NeedsKey as e:
                notes.append(str(e))
    return probes, notes


def demand_stats(probes: list[Probe]) -> dict:
    out = {}
    for src in sorted({p.source for p in probes}):
        ps = [p for p in probes if p.source == src]
        listings = [x for p in ps for x in p.listings]
        by_cur: dict[str, list[float]] = defaultdict(list)
        for x in listings:
            if x.price:
                by_cur[x.currency].append(x.price)
        cur = max(by_cur, key=lambda c: len(by_cur[c])) if by_cur else ""
        top = max(listings, key=lambda x: x.metric or 0, default=None)
        out[src] = {
            "queries": len(ps),
            "markets": sorted({p.market for p in ps}),
            "reported_total": sum(p.total or 0 for p in ps),
            "listings_seen": len(listings),
            "price_currency": cur,
            "price": price_stats(by_cur.get(cur, [])),
            "metric_label": top.metric_label if top else "",
            "metric_total": sum(x.metric or 0 for x in listings),
            "top": top.as_dict() if top and top.metric else None,
        }
    return out


def evidence_items(card, probes: list[Probe]) -> dict[str, dict]:
    """E0 is the card's own source; E1.. are the strongest marketplace listings."""
    items = {"E0": {"id": "E0", "source": card.source, "market": "", "title": card.title,
                    "price": card.pay_amount, "currency": card.pay_currency, "url": card.url,
                    "metric": None, "metric_label": "", "quote": card.quote}}
    seen, listings = set(), []
    for x in (x for p in probes for x in p.listings):
        if x.url not in seen:
            seen.add(x.url)
            listings.append(x)
    listings.sort(key=lambda x: (x.metric or 0, x.price is not None), reverse=True)
    for i, x in enumerate(listings[: int(config.settings()["dive"]["evidence_items"])], 1):
        items[f"E{i}"] = {"id": f"E{i}", **x.as_dict()}
    return items


def competitors(items: dict[str, dict], niche) -> tuple[list[dict], list[str]]:
    """Top listings by ratings/favourites plus the niche's named competitor apps and complaints."""
    ranked = [it for k, it in items.items() if k != "E0"][:6]
    comps = [{"name": it["title"], "source": it["source"], "market": it["market"], "price": it["price"],
              "currency": it["currency"], "rating": it.get("rating"), "metric": it.get("metric"),
              "metric_label": it.get("metric_label", ""), "url": it["url"], "complaints": []} for it in ranked]
    notes = []
    country = "za" if niche.region == "ZA" else config.settings()["markets"]["appstore_countries"][0]
    with client() as http:
        for name in niche.competitors[:3]:
            try:
                app = appstore.find_app(name, country, http=http)
                if not app:
                    notes.append(f"{name}: no App Store app found")
                    continue
                revs = appstore.reviews(app, max_stars=2, limit=3, http=http)
            except ProbeError as e:
                notes.append(f"{name}: {e}")
                continue
            comps.append({"name": app.title, "source": "appstore", "market": app.market, "price": app.price,
                          "currency": app.currency, "rating": app.rating, "metric": app.metric,
                          "metric_label": "ratings", "url": app.url, "named": True,
                          "complaints": [f"{r.rating}-star: {r.text[:240]}" for r in revs]})
    return comps, notes

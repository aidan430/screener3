"""Etsy Open API v3: active listings for a search term (needs ETSY_API_KEY).

Gives prices people list at, favourites as a demand signal, and the total
number of matching listings as a measure of competition.
"""
from __future__ import annotations

from factory import config
from factory.market.base import Listing, NeedsKey, Probe, ProbeError, client

API = "https://openapi.etsy.com/v3/application/listings/active"


def _price(p: dict | None) -> tuple[float | None, str]:
    if not p or not p.get("divisor"):
        return None, ""
    return p["amount"] / p["divisor"], p.get("currency_code", "")


def search(term: str, limit: int = 10, http=None) -> Probe:
    key = config.env("ETSY_API_KEY")
    if not key:
        raise NeedsKey("Etsy needs ETSY_API_KEY (create an app at etsy.com/developers)")
    own = http is None
    http = http or client()
    try:
        resp = http.get(API, params={"keywords": term, "limit": limit, "sort_on": "score"},
                        headers={"x-api-key": key})
        if resp.status_code != 200:
            raise ProbeError(f"Etsy HTTP {resp.status_code}")
        data = resp.json()
    except ProbeError:
        raise
    except Exception as e:
        raise ProbeError(f"Etsy: {e}") from e
    finally:
        if own:
            http.close()
    listings = []
    for r in data.get("results", []):
        if not r.get("url"):
            continue
        price, cur = _price(r.get("price"))
        listings.append(Listing(source="etsy", market="etsy", title=r.get("title", ""), url=r["url"],
                                price=price, currency=cur, metric=float(r.get("num_favorers") or 0),
                                metric_label="favourites", ext_id=str(r.get("listing_id", ""))))
    return Probe(source="etsy", market="etsy", term=term, total=data.get("count"), listings=listings)

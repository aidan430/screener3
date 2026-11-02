"""Apple App Store via the public iTunes Search API and customer-review RSS (no key).

search(): apps for a term in one country, with price and rating counts.
reviews(): the latest 1-2 star reviews of one app, verbatim.
"""
from __future__ import annotations

from dataclasses import dataclass

from factory.market.base import Listing, Probe, ProbeError, client

SEARCH = "https://itunes.apple.com/search"
REVIEWS = "https://itunes.apple.com/{country}/rss/customerreviews/page=1/id={app_id}/sortby=mostrecent/json"


@dataclass
class Review:
    app: str
    app_id: str
    url: str
    rating: int
    title: str
    text: str
    review_id: str


def _listing(r: dict, country: str) -> Listing | None:
    if not r.get("trackViewUrl") or not r.get("trackName"):
        return None
    return Listing(source="appstore", market=country, title=r["trackName"], url=r["trackViewUrl"],
                   price=float(r["price"]) if r.get("price") is not None else None,
                   currency=r.get("currency", ""), metric=float(r.get("userRatingCount") or 0),
                   metric_label="ratings", rating=r.get("averageUserRating"),
                   seller=r.get("sellerName", ""), ext_id=str(r.get("trackId", "")))


def search(term: str, country: str = "us", limit: int = 10, http=None) -> Probe:
    own = http is None
    http = http or client()
    try:
        resp = http.get(SEARCH, params={"term": term, "country": country, "entity": "software",
                                        "limit": limit})
        if resp.status_code != 200:
            raise ProbeError(f"App Store {country} HTTP {resp.status_code}")
        data = resp.json()
    except ProbeError:
        raise
    except Exception as e:
        raise ProbeError(f"App Store {country}: {e}") from e
    finally:
        if own:
            http.close()
    listings = [x for x in (_listing(r, country) for r in data.get("results", [])) if x]
    return Probe(source="appstore", market=country, term=term, total=data.get("resultCount"),
                 listings=listings)


def find_app(name: str, country: str = "us", http=None) -> Listing | None:
    """The app whose name contains `name` (for competitors named in niches.yaml)."""
    probe = search(name, country, limit=5, http=http)
    for app in probe.listings:
        if name.lower() in app.title.lower():
            return app
    return None


def reviews(app: Listing, max_stars: int = 2, limit: int = 20, http=None) -> list[Review]:
    own = http is None
    http = http or client()
    try:
        resp = http.get(REVIEWS.format(country=app.market, app_id=app.ext_id))
        if resp.status_code != 200:
            raise ProbeError(f"App Store reviews {app.market}/{app.ext_id} HTTP {resp.status_code}")
        entries = resp.json().get("feed", {}).get("entry", [])
    except ProbeError:
        raise
    except Exception as e:
        raise ProbeError(f"App Store reviews: {e}") from e
    finally:
        if own:
            http.close()
    if isinstance(entries, dict):
        entries = [entries]
    out = []
    for e in entries:
        try:
            stars = int(e["im:rating"]["label"])
        except (KeyError, TypeError, ValueError):
            continue  # the app's own entry or a malformed row
        content = e.get("content", {})
        text = content.get("label", "") if isinstance(content, dict) else ""
        if stars <= max_stars and text:
            out.append(Review(app=app.title, app_id=app.ext_id, url=app.url, rating=stars,
                              title=e.get("title", {}).get("label", ""), text=text,
                              review_id=str(e.get("id", {}).get("label", ""))))
        if len(out) >= limit:
            break
    return out

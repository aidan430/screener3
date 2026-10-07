"""Shared types for official marketplace probes (App Store, Etsy, eBay)."""
from __future__ import annotations

import statistics
from dataclasses import asdict, dataclass, field

import httpx

USER_AGENT = "venture-factory/0.1 (market research)"


class ProbeError(RuntimeError):
    """The marketplace could not be read. No data => no number. Never invent."""


class NeedsKey(ProbeError):
    """The probe needs an API key the player has not added yet."""


@dataclass
class Listing:
    source: str                 # appstore | etsy | ebay
    market: str                 # us / EBAY_GB / etsy
    title: str
    url: str
    price: float | None = None
    currency: str = ""
    metric: float | None = None  # ratings count (appstore), favourites (etsy)
    metric_label: str = ""
    rating: float | None = None
    seller: str = ""
    ext_id: str = ""

    def as_dict(self) -> dict:
        return asdict(self)


@dataclass
class Probe:
    source: str
    market: str
    term: str
    total: int | None = None     # matching listings the marketplace reports
    listings: list[Listing] = field(default_factory=list)
    error: str = ""


def client() -> httpx.Client:
    return httpx.Client(timeout=20.0, headers={"User-Agent": USER_AGENT}, follow_redirects=True)


def price_stats(prices: list[float]) -> dict | None:
    prices = sorted(p for p in prices if p is not None and p > 0)
    if not prices:
        return None
    q = statistics.quantiles(prices, n=4) if len(prices) >= 4 else [prices[0], statistics.median(prices), prices[-1]]
    return {"n": len(prices), "min": prices[0], "p25": q[0], "median": statistics.median(prices),
            "p75": q[-1], "max": prices[-1]}

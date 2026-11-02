"""Web price check for the Deep Dive: what South African shops charge for a product today,
or, for a service, what businesses pay people to do the work (salaries in job adverts,
outsourced providers' prices).

Claude searches; a citation becomes a listing only when the words the API copied
from the page contain a rand price. Code reads the price, and the pay period when
the words give one, from those words; the model's own words are never used. One
call per card, not per term or market.
"""
from __future__ import annotations

import re

import anthropic

from factory import config, costs, websearch
from factory.market.base import Listing, Probe, ProbeError

NAME = "web"

SYSTEM = """You check what South African shops charge for a product today. Use web search
to find current listings (Takealot, Makro, Game, Loot, Amazon.co.za and specialist
shops). Write one short line per listing and cite the listing's own words that show
the product and its price in rand. Never cite a page for something it does not say."""

SERVICES = """You check what South African businesses pay today to have customer messages
answered or leads followed up. Use web search to find current job adverts with a salary
(Pnet, CareerJunction, Indeed, LinkedIn) for customer service, call centre, WhatsApp
or sales support agents, and outsourced customer service or virtual assistant offers
with a price. Write one short line per page and cite the page's own words that show
the job or service and its pay or price in rand, with the period (per month, per hour).
Never cite a page for something it does not say."""

PRICE = re.compile(r"(?<![A-Za-z])R\s?(\d{1,3}(?:[ ,]\d{3})+(?:\.\d{2})?|\d+(?:\.\d{2})?)(?!\d)")
PERIODS = [("per hour", r"per\s+hour|\bp/?h\b|/\s?h(?:ou)?r\b|\bhourly|\ban\s+hour"),
           ("per day", r"per\s+day|\bp/?d\b|/\s?day\b|\ba\s+day\b"),
           ("per month", r"per\s+month|\bp/?m\b|\bp\.m\.|/\s?month|/\s?mo\b|\bmonthly|\ba\s+month"),
           ("per year", r"per\s+(?:year|annum)|\bp\.?a\.?(?=[\s,;)]|$)|/\s?year|\bannually|\ba\s+year")]


def price_in(text: str) -> float | None:
    """The first rand price in a piece of page text: 'R 1 299.00' -> 1299.0."""
    m = PRICE.search(text or "")
    if not m:
        return None
    value = float(m.group(1).replace(" ", "").replace(",", ""))
    return value if value > 0 else None


def period_in(text: str) -> str:
    """The pay period written just after the first rand price ('R9 500 - R11 000 per month')."""
    m = PRICE.search(text or "")
    if not m:
        return ""
    after = text[m.end():m.end() + 32].lower()
    hits = [(re.search(rx, after), name) for name, rx in PERIODS]
    hits = [(h.start(), name) for h, name in hits if h]
    return min(hits)[1] if hits else ""


def search(terms: list[str], card_id: int | None = None, cap_zar: float | None = None,
           services: bool = False) -> Probe:
    what = (f"Work: {' / '.join(terms)}. Find up to 8 current job adverts or service offers in South "
            "Africa with pay or prices.") if services else \
        f"Product: {' / '.join(terms)}. Find up to 8 current listings in South Africa with prices."
    try:
        found = websearch.run(
            stage_name="dive", system=SERVICES if services else SYSTEM, country="ZA", card_id=card_id,
            cap_zar=cap_zar, prompt=what, max_uses=int(config.settings()["web"]["price_searches"]),
            note="web pay check" if services else "web price check")
    except costs.CapExceeded as e:
        raise ProbeError(f"web price check skipped: {e}") from e
    except (anthropic.APIStatusError, anthropic.APIConnectionError) as e:
        raise ProbeError(f"web price check failed: {e}") from e
    if not found.cites and found.errors:
        raise ProbeError(f"web price check failed: {websearch.error_text(found.errors)}")
    listings, seen = [], set()
    for c in found.cites:
        price = price_in(c.text)
        if price is None or (c.url, price) in seen:
            continue
        seen.add((c.url, price))
        listings.append(Listing(source=NAME, market="ZA", title=(c.title or c.text)[:120], url=c.url,
                                price=price, currency="ZAR", period=period_in(c.text), quote=c.text))
    return Probe(source=NAME, market="ZA", term=" / ".join(terms), listings=listings)

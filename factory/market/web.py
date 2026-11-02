"""Web price check for the Deep Dive: what South African shops charge for a product today.

Claude searches; a citation becomes a listing only when the words the API copied
from the page contain a rand price. Code reads the price from those words; the
model's own words are never used. One call per card, not per term or market.
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

PRICE = re.compile(r"(?<![A-Za-z])R\s?(\d{1,3}(?:[ ,]\d{3})+(?:\.\d{2})?|\d+(?:\.\d{2})?)(?!\d)")


def price_in(text: str) -> float | None:
    """The first rand price in a piece of page text: 'R 1 299.00' -> 1299.0."""
    m = PRICE.search(text or "")
    if not m:
        return None
    value = float(m.group(1).replace(" ", "").replace(",", ""))
    return value if value > 0 else None


def search(terms: list[str], card_id: int | None = None, cap_zar: float | None = None) -> Probe:
    try:
        found = websearch.run(
            stage_name="dive", system=SYSTEM, country="ZA", card_id=card_id, cap_zar=cap_zar,
            prompt=f"Product: {' / '.join(terms)}. Find up to 8 current listings in South Africa with prices.",
            max_uses=int(config.settings()["web"]["price_searches"]), note="web price check")
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
                                price=price, currency="ZAR"))
    return Probe(source=NAME, market="ZA", term=" / ".join(terms), listings=listings)

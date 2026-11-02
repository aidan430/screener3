"""Web scout: Claude searches the web for people who want something they cannot easily get.

Reddit closed new API access on 31 October 2026 and ends public access by March
2027, so commerce niches listen here (search engines still index Reddit threads,
forums and review sites). Each cited page becomes one signal; its text is only
what the API copied from the page, never the model's own words.
Only niches that list `web` in niches.yaml use it, because searches cost more.
"""
from __future__ import annotations

import hashlib

import anthropic

from factory import config, costs, websearch
from factory.scouts.sources.base import RawSignal, SourceError, SourceSkipped, matches

NAME = "web"

COMMERCE = """You find demand for a small South African online store that sells physical
products from local stock. Use web search to find recent posts where real people say
they want to buy a product but cannot easily get it in South Africa: it is out of
stock, overpriced, slow or costly to import, or the local options are poor. Forums,
community Q&A and review sites are best (MyBroadband, Reddit threads, Hellopeter,
Quora); skip shop pages, adverts and news articles.
Write one short line per post naming the product and the problem, and cite the
post's own words that show the want and any price. Never cite a page for something
it does not say. Skip food, medicine, supplements, cosmetics with health claims,
weapons, wireless or mains-electrical gadgets, brand-name originals and copies of
them, and anything heavier than 5 kg."""

SERVICES = """You find South African businesses that pay people to answer customer messages
or follow up leads, work an AI-run service could do for less. Use web search to find
recent job adverts with a salary (Pnet, CareerJunction, Indeed, LinkedIn), posts where
owners say they cannot keep up with WhatsApps, emails, missed calls or leads, and
adverts for outsourced customer service with prices.
Write one short line per page naming the business type and the work, and cite the
page's own words that show the work and any salary or price. Never cite a page for
something it does not say. Skip work that needs a licence or professional advice
(financial, legal, medical), health or children's records, debt collection, cold
marketing calls or messages to people who never asked, and work done on site."""

SOFTWARE = """You find problems people pay to solve. Use web search to find recent forum
posts and reviews where people complain about a task they pay for, or ask for a tool
to do it. Write one short line per post and cite the post's own words that show the
problem and any price. Never cite a page for something it does not say."""


def prompt_for(niche) -> str:
    words = niche.slug.replace("sa-", "").replace("-", " ")
    phrases = config.phrases_for(niche)[:4]
    where = "in South Africa" if niche.region == "ZA" else "anywhere"
    ideas = "; ".join(f'"{p} {k}"' for p, k in zip(phrases, niche.keywords)) or ", ".join(niche.keywords)
    return (f"Category: {words} ({', '.join(niche.keywords)}), buyers {where}.\n"
            f"Search ideas: {ideas}.\nFind up to 8 different posts from the last two years.")


def fetch(niche) -> list[RawSignal]:
    try:
        found = websearch.run(
            stage_name="scout", system={"commerce": COMMERCE, "services": SERVICES}.get(niche.kind, SOFTWARE),
            prompt=prompt_for(niche), max_uses=int(config.settings()["web"]["scout_searches"]),
            country="ZA" if niche.region == "ZA" else "", niche_slug=niche.slug, note=f"web scout {niche.slug}",
            cap_zar=float(config.settings()["caps"]["web_zar_per_niche"]))
    except costs.NoApiKey as e:
        raise SourceSkipped(f"skipped: {e}") from e
    except costs.CapExceeded as e:
        raise SourceSkipped(f"skipped: over the web search cap ({e})") from e
    except anthropic.RateLimitError as e:
        raise SourceError("web search: HTTP 429 (rate limited)") from e
    except anthropic.BadRequestError as e:
        raise SourceError(f"web search refused: {e.message} (is web search on in the Claude Console?)") from e
    except anthropic.APIStatusError as e:
        raise SourceError(f"web search: HTTP {e.status_code}") from e
    except anthropic.APIConnectionError as e:
        raise SourceError("web search: connection timed out") from e
    if not found.cites and found.errors:
        raise SourceError(f"web search failed: {websearch.error_text(found.errors)}")
    terms = niche.keywords + config.phrases_for(niche)
    by_url: dict[str, list[websearch.Cite]] = {}
    for c in found.cites:
        by_url.setdefault(c.url, []).append(c)
    out = []
    for url, cites in by_url.items():
        text = "\n".join(dict.fromkeys(c.text for c in cites))  # separate excerpts: a quote cannot span two
        out.append(RawSignal(source=NAME, external_id="web:" + hashlib.sha1(url.encode()).hexdigest()[:16],
                             url=url, title=cites[0].title, text=text,
                             posted_at=websearch.page_date(cites[0].page_age),
                             matched=matches(f"{cites[0].title} {text}", terms) or ["found by web search"]))
    return out

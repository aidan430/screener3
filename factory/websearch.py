"""Anthropic's server-side web search, shared by the web scout and the Deep Dive price check.

Claude runs the searches. The only evidence kept is citations: the page's url and
title and up to 150 characters the API copied from the page. Words the model
wrote itself are never kept as evidence. Costs go through costs.search.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timezone

from factory import config, costs

TOOL = "web_search_20250305"  # the basic tool: runs on Haiku 4.5 (dynamic filtering needs a 4.6+ model)


@dataclass
class Cite:
    url: str
    title: str
    text: str            # verbatim from the page, at most 150 characters
    page_age: str = ""


@dataclass
class Found:
    cites: list[Cite] = field(default_factory=list)
    queries: list[str] = field(default_factory=list)
    errors: list[str] = field(default_factory=list)
    searches: int = 0
    paused: bool = False


def tool(max_uses: int, country: str = "") -> dict:
    t = {"type": TOOL, "name": "web_search", "max_uses": int(max_uses)}
    if country:
        t["user_location"] = {"type": "approximate", "country": country}
        if country == "ZA":
            t["user_location"]["timezone"] = "Africa/Johannesburg"
    return t


def run(*, stage_name: str, system: str, prompt: str, max_uses: int, country: str = "", max_tokens: int = 2000,
        niche_slug: str = "", card_id: int | None = None, cap_zar: float | None = None, note: str = "") -> Found:
    msg = costs.search(stage_name=stage_name, model=config.settings()["models"]["scout"], system=system,
                       prompt=prompt, tools=[tool(max_uses, country)], max_tokens=max_tokens,
                       niche_slug=niche_slug, card_id=card_id, cap_zar=cap_zar, note=note)
    return parse(msg)


def parse(msg) -> Found:
    found, ages, seen = Found(), {}, set()
    for block in msg.content:
        kind = getattr(block, "type", "")
        if kind == "server_tool_use":
            query = (getattr(block, "input", None) or {}).get("query")
            if query:
                found.queries.append(str(query))
        elif kind == "web_search_tool_result":
            content = getattr(block, "content", None)
            if isinstance(content, list):
                for r in content:
                    ages[getattr(r, "url", "")] = getattr(r, "page_age", None) or ""
            else:  # one error object instead of a list of results
                found.errors.append(str(getattr(content, "error_code", "unavailable")))
        elif kind == "text":
            for c in getattr(block, "citations", None) or []:
                text = (getattr(c, "cited_text", "") or "").strip()
                if getattr(c, "type", "") != "web_search_result_location" or not text:
                    continue
                if (c.url, text) not in seen:
                    seen.add((c.url, text))
                    found.cites.append(Cite(url=c.url, title=getattr(c, "title", "") or "", text=text))
    for cite in found.cites:
        cite.page_age = ages.get(cite.url, "")
    found.searches = costs.searches(msg.usage)
    found.paused = getattr(msg, "stop_reason", "") == "pause_turn"
    return found


def page_date(page_age: str) -> datetime | None:
    """'April 30, 2025' style dates from search results; anything else is unknown."""
    for fmt in ("%B %d, %Y", "%b %d, %Y", "%Y-%m-%d", "%d %B %Y"):
        try:
            return datetime.strptime(page_age.strip(), fmt).replace(tzinfo=timezone.utc)
        except (ValueError, AttributeError):
            continue
    return None


ERRORS = {"too_many_requests": "HTTP 429 (search rate limit)", "unavailable": "server error (search unavailable)"}


def error_text(codes: list[str]) -> str:
    """Words the Warden's Fixer recognises: rate limits and server errors are temporary."""
    return ", ".join(ERRORS.get(c, c) for c in dict.fromkeys(codes))

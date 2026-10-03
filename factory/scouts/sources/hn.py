"""Hacker News scout via the Algolia search API (no key needed).

For each keyword: one Ask HN search and one comment search. For each named
competitor: one "<competitor> alternative" search. Pain phrases rank the hits.
"""
from __future__ import annotations

import logging
import time
from datetime import datetime, timezone

from factory import config
from factory.scouts.sources.base import RawSignal, SourceError, clean, http_client, matches

log = logging.getLogger("factory.scouts.hn")
NAME = "hn"
API = "https://hn.algolia.com/api/v1/search"


def queries(niche) -> list[tuple[str, str]]:
    """(query, tags) pairs."""
    out = []
    for kw in niche.keywords:
        out.append((kw, "ask_hn"))
        out.append((kw, "comment"))
    for comp in niche.competitors:
        out.append((f"{comp} alternative", "(story,comment)"))
    return out


def _to_signal(hit: dict, terms: list[str]) -> RawSignal | None:
    oid = hit.get("objectID")
    title = clean(hit.get("title") or hit.get("story_title"))
    body = clean(hit.get("story_text") or hit.get("comment_text"))
    if not oid or not (title or body):
        return None
    ts = hit.get("created_at_i")
    return RawSignal(
        source=NAME,
        external_id=f"hn:{oid}",
        url=f"https://news.ycombinator.com/item?id={oid}",
        title=title,
        text=body or title,
        score=float(hit.get("points") or 0),
        replies=int(hit.get("num_comments") or 0),
        posted_at=datetime.fromtimestamp(ts, timezone.utc) if ts else None,
        matched=matches(f"{title} {body}", terms),
    )


def fetch(niche) -> list[RawSignal]:
    cfg = config.settings()["hn"]
    since = int(time.time()) - int(cfg["lookback_days"]) * 86400
    terms = niche.keywords + niche.competitors + config.pain_phrases()
    seen: dict[str, RawSignal] = {}
    errors: list[str] = []
    with http_client() as client:
        for q, tags in queries(niche):
            try:
                r = client.get(API, params={"query": q, "tags": tags, "hitsPerPage": cfg["hits_per_query"],
                                            "numericFilters": f"created_at_i>{since}"})
                if r.status_code != 200:
                    raise SourceError(f"HTTP {r.status_code}")
                hits = r.json().get("hits", [])
            except Exception as e:
                errors.append(f"{q!r}: {e}")
                log.warning("hn query %r failed: %s", q, e)
                continue
            for h in hits:
                sig = _to_signal(h, terms)
                if sig and sig.external_id not in seen:
                    seen[sig.external_id] = sig
    if not seen and errors:
        raise SourceError("; ".join(errors[:3]))
    return list(seen.values())

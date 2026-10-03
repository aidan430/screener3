"""Reddit scout: per subreddit, search the niche keywords and the pain phrases.

Uses praw when REDDIT_CLIENT_ID/SECRET are set (the CLAUDE.md stack). Without
credentials it falls back to Reddit's public read-only JSON search, which is
rate limited harder but needs no account (see NOTES.md).
"""
from __future__ import annotations

import logging
import time
from datetime import datetime, timezone

from factory import config
from factory.scouts.sources.base import RawSignal, SourceError, clean, http_client, matches

log = logging.getLogger("factory.scouts.reddit")
NAME = "reddit"


def _or_query(terms: list[str]) -> str:
    return " OR ".join(f'"{t}"' for t in terms)


def queries(niche) -> list[tuple[str, str]]:
    """(subreddit, query) pairs: one keyword query and one pain-phrase query per sub."""
    out = []
    for sub in niche.subreddits:
        if niche.keywords:
            out.append((sub, _or_query(niche.keywords)))
        out.append((sub, _or_query(config.pain_phrases()[:8])))
    return out


def _to_signal(d: dict, terms: list[str]) -> RawSignal | None:
    title = clean(d.get("title"))
    body = clean(d.get("selftext"))
    text = f"{title}\n\n{body}".strip()
    if not d.get("permalink") or not text:
        return None
    created = d.get("created_utc")
    return RawSignal(
        source=NAME,
        external_id=f"reddit:{d.get('id') or d.get('name')}",
        url="https://www.reddit.com" + d["permalink"],
        title=title,
        text=body or title,
        score=float(d.get("score") or 0),
        replies=int(d.get("num_comments") or 0),
        posted_at=datetime.fromtimestamp(created, timezone.utc) if created else None,
        matched=matches(text, terms),
    )


def _fetch_public(sub: str, q: str, cfg: dict, client) -> list[dict]:
    r = client.get(f"https://www.reddit.com/r/{sub}/search.json", params={
        "q": q, "restrict_sr": 1, "sort": "relevance", "t": cfg["lookback"],
        "limit": cfg["per_query_limit"], "raw_json": 1,
    })
    if r.status_code != 200:
        raise SourceError(f"reddit r/{sub} HTTP {r.status_code}")
    return [c["data"] for c in r.json().get("data", {}).get("children", [])]


def _fetch_praw(sub: str, q: str, cfg: dict, reddit) -> list[dict]:
    out = []
    for p in reddit.subreddit(sub).search(q, sort="relevance", time_filter=cfg["lookback"],
                                          limit=cfg["per_query_limit"]):
        out.append({"id": p.id, "title": p.title, "selftext": p.selftext, "permalink": p.permalink,
                    "score": p.score, "num_comments": p.num_comments, "created_utc": p.created_utc})
    return out


def _praw_client():
    cid, secret = config.env("REDDIT_CLIENT_ID"), config.env("REDDIT_CLIENT_SECRET")
    if not (cid and secret):
        return None
    import praw
    return praw.Reddit(client_id=cid, client_secret=secret, check_for_async=False,
                       user_agent=config.env("REDDIT_USER_AGENT", "venture-factory/0.1"))


def fetch(niche) -> list[RawSignal]:
    cfg = config.settings()["reddit"]
    terms = niche.keywords + config.pain_phrases()
    reddit = _praw_client()
    seen: dict[str, RawSignal] = {}
    errors: list[str] = []
    with http_client() as client:
        for i, (sub, q) in enumerate(queries(niche)):
            if i and not reddit:
                time.sleep(cfg["request_pause_s"])
            try:
                rows = _fetch_praw(sub, q, cfg, reddit) if reddit else _fetch_public(sub, q, cfg, client)
            except Exception as e:  # network, 403, 429, praw errors
                errors.append(f"r/{sub}: {e}")
                log.warning("reddit r/%s failed: %s", sub, e)
                continue
            for d in rows:
                sig = _to_signal(d, terms)
                if sig and sig.external_id not in seen:
                    seen[sig.external_id] = sig
    if not seen and errors:
        raise SourceError("; ".join(errors[:3]))
    return list(seen.values())

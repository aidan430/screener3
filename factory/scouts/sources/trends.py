"""Google Trends rising queries.

TODO(first-run): stubbed. Tonight only reddit + hn are live (KICKOFF constraint).
Implementation plan: pytrends (needs approval: not in the stack list yet). Return RawSignal rows with the verbatim text and
the page url; if the page cannot be read, raise SourceError. Never invent.
Enable in config/settings.yaml -> sources.trends once implemented.
"""
from __future__ import annotations

from factory.scouts.sources.base import NotImplementedSource, RawSignal

NAME = "trends"


def fetch(niche) -> list[RawSignal]:
    raise NotImplementedSource("trends adapter is a TODO stub (reddit + hn only on first run)")

"""Fiverr gig search pages, starting-price extraction.

TODO(first-run): stubbed. Tonight only reddit + hn are live (KICKOFF constraint).
Implementation plan: playwright or httpx. Return RawSignal rows with the verbatim text and
the page url; if the page cannot be read, raise SourceError. Never invent.
Enable in config/settings.yaml -> sources.fiverr once implemented.
"""
from __future__ import annotations

from factory.scouts.sources.base import NotImplementedSource, RawSignal

NAME = "fiverr"


def fetch(niche) -> list[RawSignal]:
    raise NotImplementedSource("fiverr adapter is a TODO stub (reddit + hn only on first run)")

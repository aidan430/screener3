"""HelloPeter public complaint pages (SA).

TODO(first-run): stubbed. Tonight only reddit + hn are live (KICKOFF constraint).
Implementation plan: httpx + HTML parsing. Return RawSignal rows with the verbatim text and
the page url; if the page cannot be read, raise SourceError. Never invent.
Enable in config/settings.yaml -> sources.hellopeter once implemented.
"""
from __future__ import annotations

from factory.scouts.sources.base import NotImplementedSource, RawSignal

NAME = "hellopeter"


def fetch(niche) -> list[RawSignal]:
    raise NotImplementedSource("hellopeter adapter is a TODO stub (reddit + hn only on first run)")

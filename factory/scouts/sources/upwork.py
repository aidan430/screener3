"""Upwork public job search pages (playwright), price extraction from budgets.

TODO(first-run): stubbed. Tonight only reddit + hn are live (KICKOFF constraint).
Implementation plan: playwright. Return RawSignal rows with the verbatim text and
the page url; if the page cannot be read, raise SourceError. Never invent.
Enable in config/settings.yaml -> sources.upwork once implemented.
"""
from __future__ import annotations

from factory.scouts.sources.base import NotImplementedSource, RawSignal

NAME = "upwork"


def fetch(niche) -> list[RawSignal]:
    raise NotImplementedSource("upwork adapter is a TODO stub (reddit + hn only on first run)")

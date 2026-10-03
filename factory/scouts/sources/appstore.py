"""1-2 star reviews for the competitor apps named in niches.yaml.

TODO(first-run): stubbed. Tonight only reddit + hn are live (KICKOFF constraint).
Implementation plan: App Store RSS (feedparser) + Play Store (playwright). Return RawSignal rows with the verbatim text and
the page url; if the page cannot be read, raise SourceError. Never invent.
Enable in config/settings.yaml -> sources.appstore once implemented.
"""
from __future__ import annotations

from factory.scouts.sources.base import NotImplementedSource, RawSignal

NAME = "appstore"


def fetch(niche) -> list[RawSignal]:
    raise NotImplementedSource("appstore adapter is a TODO stub (reddit + hn only on first run)")

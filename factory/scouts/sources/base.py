"""Shared types for source adapters."""
from __future__ import annotations

import html
import re
from dataclasses import dataclass, field
from datetime import datetime

import httpx

USER_AGENT = "venture-factory/0.1 (nightly research scout)"


class SourceError(RuntimeError):
    """The source could not be read. No signals => no cards. Never invent."""


class NotImplementedSource(SourceError):
    pass


@dataclass
class RawSignal:
    source: str
    external_id: str
    url: str
    title: str
    text: str
    score: float = 0.0
    replies: int = 0
    posted_at: datetime | None = None
    matched: list[str] = field(default_factory=list)


_TAG = re.compile(r"<[^>]+>")
_WS = re.compile(r"\s+")


def clean(text: str | None) -> str:
    """Strip HTML and collapse whitespace; keep wording verbatim otherwise."""
    if not text:
        return ""
    text = text.replace("<p>", "\n\n")
    text = html.unescape(_TAG.sub("", text))
    return _WS.sub(" ", text).strip()


def http_client() -> httpx.Client:
    return httpx.Client(timeout=20.0, headers={"User-Agent": USER_AGENT}, follow_redirects=True)


def matches(text: str, terms: list[str]) -> list[str]:
    low = text.lower()
    return [t for t in terms if t.lower() in low]

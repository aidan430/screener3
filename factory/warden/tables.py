"""Warden tables. Imported at the end of factory/models.py so create_all sees them."""
from __future__ import annotations

from datetime import datetime
from typing import Optional

from sqlmodel import Field, SQLModel

from factory.models import tonight, utcnow


class Incident(SQLModel, table=True):
    """Something the Warden noticed, what it did, and whether you are needed."""
    id: Optional[int] = Field(default=None, primary_key=True)
    key: str = Field(index=True)               # dedupe: one open incident per key
    kind: str = Field(index=True)              # stale_run | source_down | daily_cap | missing_key | ...
    subject: str = ""
    detail: str = ""                           # what happened, in plain words
    action: str = ""                           # what the Warden did about it
    outcome: str = "watching"                  # fixed | needs_you | watching
    night: str = Field(default_factory=tonight, index=True)
    created_at: datetime = Field(default_factory=utcnow, index=True)
    last_seen: datetime = Field(default_factory=utcnow)
    resolved_at: Optional[datetime] = None
    emailed: bool = False


class SourceHold(SQLModel, table=True):
    """A source the Fixer paused because it kept failing. Scouts skip it until `until`."""
    id: Optional[int] = Field(default=None, primary_key=True)
    source: str = Field(index=True)
    until: datetime
    reason: str = ""
    created_at: datetime = Field(default_factory=utcnow)
    released_at: Optional[datetime] = None


class WardenReport(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    kind: str = "weekly"                       # weekly | monthly
    title: str = ""
    period_start: datetime
    period_end: datetime
    created_at: datetime = Field(default_factory=utcnow, index=True)
    body_md: str = ""
    body_html: str = ""
    summary_json: str = "{}"
    emailed: bool = False

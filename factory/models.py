"""SQLModel tables. One SQLite file at data/factory.db (override with FACTORY_DB)."""
from __future__ import annotations

import json
from datetime import datetime, timezone
from typing import Optional

from sqlmodel import Field, Session, SQLModel, create_engine

from factory import config


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


def tonight() -> str:
    """The 'night' a run belongs to, as a SAST calendar date."""
    from zoneinfo import ZoneInfo
    return datetime.now(ZoneInfo("Africa/Johannesburg")).date().isoformat()


class Niche(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    slug: str = Field(index=True, unique=True)
    region: str = "GLOBAL"
    keywords_json: str = "[]"
    subreddits_json: str = "[]"
    competitors_json: str = "[]"
    position: int = 0
    active: bool = True

    @property
    def keywords(self) -> list[str]:
        return json.loads(self.keywords_json)

    @property
    def subreddits(self) -> list[str]:
        return json.loads(self.subreddits_json)

    @property
    def competitors(self) -> list[str]:
        return json.loads(self.competitors_json)


class Signal(SQLModel, table=True):
    """Raw evidence pulled by a source adapter. Kept for retention_days."""
    id: Optional[int] = Field(default=None, primary_key=True)
    niche_id: int = Field(foreign_key="niche.id", index=True)
    source: str
    external_id: str = Field(index=True)      # "<source>:<native id>", unique per niche
    url: str
    title: str = ""
    text: str = ""
    score: float = 0.0                         # upvotes / points
    replies: int = 0
    rank: float = 0.0                          # our relevance ranking
    posted_at: Optional[datetime] = None
    fetched_at: datetime = Field(default_factory=utcnow)


class Card(SQLModel, table=True):
    """An idea with verbatim evidence. No url, no card."""
    id: Optional[int] = Field(default=None, primary_key=True)
    niche_id: int = Field(foreign_key="niche.id", index=True)
    signal_id: Optional[int] = Field(default=None, foreign_key="signal.id")
    night: str = Field(default_factory=tonight, index=True)
    title: str
    problem: str
    quote: str
    url: str
    pay_evidence: str = ""
    pay_amount: Optional[float] = None
    pay_currency: str = ""
    source: str
    # scouted -> proof_passed -> craft_passed -> awaiting_funding -> testing -> won/lost
    # killed_proof / killed_craft / archived are terminal (never deleted)
    status: str = Field(default="scouted", index=True)
    created_at: datetime = Field(default_factory=utcnow)


class GateResult(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    card_id: int = Field(foreign_key="card.id", index=True)
    gate: str                                  # proof | craft
    score: int
    verdict: str                               # pass | kill
    reasoning: str
    evidence_json: str = "[]"
    rubric_version: str = ""
    model: str = ""
    created_at: datetime = Field(default_factory=utcnow)

    @property
    def evidence(self) -> list[str]:
        return json.loads(self.evidence_json)


class SmokeTest(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    card_id: int = Field(foreign_key="card.id", index=True)
    slug: str = Field(index=True, unique=True)
    name: str = ""
    headline: str = ""
    price_label: str = ""
    page_path: str = ""
    url: str = ""
    deploy_target: str = "local"               # local | vercel
    ads_json: str = "{}"
    manual_steps: str = ""
    # awaiting_funding -> approved -> won/lost
    status: str = Field(default="awaiting_funding", index=True)
    visitors: int = 0
    buy_clicks: int = 0
    approved_at: Optional[datetime] = None
    created_at: datetime = Field(default_factory=utcnow)


class TrackEvent(SQLModel, table=True):
    """Local buy_click / visit beacons when pages are served by our own API."""
    id: Optional[int] = Field(default=None, primary_key=True)
    slug: str = Field(index=True)
    kind: str                                  # visit | buy_click | email
    detail: str = ""
    created_at: datetime = Field(default_factory=utcnow)


class Build(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    smoke_id: int = Field(foreign_key="smoketest.id")
    slug: str
    spec_path: str = ""
    status: str = "spec_written"               # spec_written | launched
    created_at: datetime = Field(default_factory=utcnow)


class Venture(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    build_id: Optional[int] = Field(default=None, foreign_key="build.id")
    slug: str = Field(index=True, unique=True)
    name: str
    status: str = "building"                   # building | live | paused
    price_label: str = ""
    revenue_collected: float = 0.0             # rand, moved to gold
    revenue_uncollected: float = 0.0           # rand, awaiting /api/collect
    started_at: datetime = Field(default_factory=utcnow)
    live_at: Optional[datetime] = None


class Cost(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    ts: datetime = Field(default_factory=utcnow, index=True)
    night: str = Field(default_factory=tonight, index=True)
    stage: str = Field(index=True)              # scout | proof | craft | smoke | spec
    model: str
    input_tokens: int = 0
    output_tokens: int = 0
    usd: float = 0.0
    zar: float = 0.0
    niche_slug: str = ""
    card_id: Optional[int] = None
    note: str = ""


class RunLog(SQLModel, table=True):
    """One row per stage run, so the dashboard can show 'last night' honestly."""
    id: Optional[int] = Field(default=None, primary_key=True)
    night: str = Field(default_factory=tonight, index=True)
    stage: str
    started_at: datetime = Field(default_factory=utcnow)
    finished_at: Optional[datetime] = None
    ok: bool = True
    summary: str = ""


_engine = None


def engine():
    global _engine
    if _engine is None:
        config.DATA_DIR.mkdir(exist_ok=True)
        _engine = create_engine(config.db_url(), connect_args={"check_same_thread": False})
        SQLModel.metadata.create_all(_engine)
    return _engine


def reset_engine() -> None:
    """Used by tests that point FACTORY_DB at a temp file."""
    global _engine
    _engine = None


def session() -> Session:
    return Session(engine(), expire_on_commit=False)

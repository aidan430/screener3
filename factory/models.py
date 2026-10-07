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
    business_model: str = ""                   # key in config/business_models.yaml
    lane: str = ""                             # digital | commerce | content
    # scouted -> proof_passed -> craft_passed -> dive_passed -> awaiting_funding
    #   -> testing -> won -> building ; killed_* / archived are terminal (never deleted)
    status: str = Field(default="scouted", index=True)
    created_at: datetime = Field(default_factory=utcnow)


class GateResult(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    card_id: int = Field(foreign_key="card.id", index=True)
    gate: str                                  # proof | craft | economics
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


class Dossier(SQLModel, table=True):
    """Deep Dive output for one card. Every number is evidence (with url) or assumption."""
    id: Optional[int] = Field(default=None, primary_key=True)
    card_id: int = Field(foreign_key="card.id", index=True)
    night: str = Field(default_factory=tonight, index=True)
    business_model: str = ""
    lane: str = ""
    search_terms_json: str = "[]"
    evidence_json: str = "[]"                  # [{id, source, market, title, price, currency, url, metric}]
    demand_json: str = "{}"                    # per-source counts and price spread
    competitors_json: str = "[]"
    price_point: Optional[float] = None
    currency: str = ""
    price_unit: str = ""                       # one-off | per month | per year
    price_basis: str = ""                      # evidence id the price is anchored to
    price_zar: Optional[float] = None
    unit_cost_zar: Optional[float] = None
    unit_cost_basis: str = ""                  # "evidence E4" or "assumption: 35% of price"
    fees_zar: Optional[float] = None
    cac_zar: Optional[float] = None
    unit_profit_zar: Optional[float] = None
    margin: Optional[float] = None
    capital_zar: Optional[float] = None
    capital_lines_json: str = "[]"             # [[label, rand, basis]]
    break_even_sales: Optional[int] = None
    risks_json: str = "[]"                     # [{risk, severity, hard_kill}]
    demand_score: int = 0
    competition_score: int = 0
    score: int = 0
    verdict: str = ""                          # pass | kill
    reasoning: str = ""
    kill_reasons_json: str = "[]"
    created_at: datetime = Field(default_factory=utcnow)

    def j(self, field: str):
        return json.loads(getattr(self, field + "_json"))


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


class AgentRun(SQLModel, table=True):
    """One unit of work by one agent. The dashboard only ever draws these."""
    id: Optional[int] = Field(default=None, primary_key=True)
    night: str = Field(default_factory=tonight, index=True)
    dept: str = Field(index=True)              # research | dive | train | ops | treasury | warden
    role: str
    subject: str = ""                          # niche slug or card title
    card_id: Optional[int] = None
    lane: str = ""
    tower: Optional[int] = None                # 1-6 when working at a tower
    started_at: datetime = Field(default_factory=utcnow, index=True)
    finished_at: Optional[datetime] = None
    status: str = "running"                    # running | ok | failed | skipped | blocked
    summary: str = ""
    cost_zar: float = 0.0


_engine = None


def _migrate(eng) -> None:
    """Add columns that newer code expects to tables an older run created."""
    from sqlalchemy import inspect, text
    insp = inspect(eng)
    with eng.begin() as conn:
        for table in SQLModel.metadata.sorted_tables:
            if not insp.has_table(table.name):
                continue
            have = {c["name"] for c in insp.get_columns(table.name)}
            for col in table.columns:
                if col.name in have:
                    continue
                arg = col.default.arg if col.default is not None else None
                default = None if callable(arg) else arg
                ddl = f'ALTER TABLE "{table.name}" ADD COLUMN "{col.name}" {col.type.compile(eng.dialect)}'
                if default is not None:
                    ddl += " DEFAULT " + (f"'{default}'" if isinstance(default, str) else str(default))
                conn.execute(text(ddl))


def engine():
    global _engine
    if _engine is None:
        config.DATA_DIR.mkdir(exist_ok=True)
        _engine = create_engine(config.db_url(), connect_args={"check_same_thread": False})
        _migrate(_engine)
        SQLModel.metadata.create_all(_engine)
    return _engine


def reset_engine() -> None:
    """Used by tests that point FACTORY_DB at a temp file."""
    global _engine
    _engine = None


def session() -> Session:
    return Session(engine(), expire_on_commit=False)


from factory.training import tables as _training_tables  # noqa: E402,F401  (registers Training tables)
from factory.warden import tables as _warden_tables  # noqa: E402,F401  (registers Warden tables)

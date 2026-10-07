"""Agent activity: every agent's unit of work becomes an AgentRun row.

    with agents.run("dive", "Risk analyst", subject=card.title, card=card, tower=3) as job:
        ...
        job.summary = "2 risks, none fatal"

The dashboard draws agents only from these rows, so nothing on the map is made up.
Rosters below count the agents that exist in code today, per department.
"""
from __future__ import annotations

import logging
from contextlib import contextmanager
from datetime import timedelta

from sqlmodel import select

from factory import config, costs
from factory.models import AgentRun, Niche, session, utcnow

log = logging.getLogger("factory.agents")
STALE = timedelta(hours=2)   # a "running" row older than this died with its process

DEPARTMENTS = [
    # id, name, phase that builds it out
    ("research", "Research", 1),
    ("dive", "Deep Dive", 2),
    ("train", "Training", 4),
    ("ops", "Operations", 5),
    ("treasury", "Treasury", 6),
    ("warden", "Warden", 3),
]
BUILT_PHASE = 3   # departments whose phase is <= this are fully built
DIVE_ROLES = ["Demand analyst", "Competitor analyst", "Economics analyst", "Risk analyst", "Capital estimator"]


class Job:
    def __init__(self, row: AgentRun):
        self.row = row
        self.summary = ""
        self.status = "ok"


@contextmanager
def run(dept: str, role: str, subject: str = "", card=None, tower: int | None = None, lane: str = ""):
    row = AgentRun(dept=dept, role=role, subject=(subject or "")[:200],
                   card_id=getattr(card, "id", None), tower=tower,
                   lane=lane or getattr(card, "lane", "") or "")
    with session() as s:
        s.add(row)
        s.commit()
        s.refresh(row)
    job, spent0 = Job(row), costs.process_spent()
    try:
        yield job
    except (costs.StageOverBudget, costs.CapExceeded, costs.NoApiKey) as e:
        job.status, job.summary = "blocked", job.summary or str(e)
        raise
    except Exception as e:
        job.status, job.summary = "failed", job.summary or f"{type(e).__name__}: {e}"
        raise
    finally:
        with session() as s:
            r = s.get(AgentRun, row.id)
            r.status, r.summary = job.status, (job.summary or "")[:300]
            r.finished_at = utcnow()
            r.cost_zar = round(costs.process_spent() - spent0, 4)
            s.add(r)
            s.commit()


def roster() -> dict[str, list[str]]:
    """Agent roles that exist in code right now, per department."""
    enabled = [k for k, v in config.settings()["sources"].items() if v]
    with session() as s:
        niches = list(s.exec(select(Niche.slug).where(Niche.active == True)))  # noqa: E712
    scouts = [f"{src} scout · {slug}" for slug in niches for src in enabled]
    return {
        "research": scouts + ["Distiller", "Proof gatekeeper", "Craft gatekeeper"],
        "dive": list(DIVE_ROLES),
        "train": ["Playbook writer"],
        "ops": ["Smoke-test builder"],          # per-niche squads arrive in Phase 5
        "treasury": [],                        # Phase 6
        "warden": ["Health check", "Cost guard", "Fixer", "Reporter"],
    }


def effective_status(r: AgentRun) -> str:
    if r.status == "running" and r.started_at and utcnow() - _aware(r.started_at) > STALE:
        return "failed"
    return r.status


def _aware(dt):
    from datetime import timezone
    return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)


def recent(hours: float = 36, limit: int = 400) -> list[AgentRun]:
    since = utcnow() - timedelta(hours=hours)
    with session() as s:
        return list(s.exec(select(AgentRun).where(AgentRun.started_at >= since)
                           .order_by(AgentRun.started_at.desc()).limit(limit)))


def departments() -> list[dict]:
    ros = roster()
    runs = recent(hours=2)
    out = []
    for dept, name, phase in DEPARTMENTS:
        working = sum(1 for r in runs if r.dept == dept and effective_status(r) == "running")
        out.append({"id": dept, "name": name, "agents": len(ros[dept]), "working": working,
                    "built": bool(ros[dept]), "complete": phase <= BUILT_PHASE, "phase": phase})
    return out


def latest_by_role(dept: str) -> list[dict]:
    """For a department panel: each role and what it did last."""
    rows = [r for r in recent(hours=24 * 7) if r.dept == dept]
    seen, out = set(), []
    for r in rows:  # newest first
        key = r.role.split(" · ")[0]
        if key in seen:
            continue
        seen.add(key)
        out.append({"role": r.role, "subject": r.subject, "status": effective_status(r),
                    "summary": r.summary, "when": _aware(r.started_at).isoformat()})
    return out

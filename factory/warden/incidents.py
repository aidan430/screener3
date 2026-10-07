"""Open, refresh and resolve Warden incidents. One open incident per key.

Outcomes: fixed (the Warden handled it), needs_you (only a human can),
watching (noted; the Warden keeps an eye on it).
"""
from __future__ import annotations

from datetime import timedelta

from sqlmodel import select

from factory.models import session, utcnow
from factory.warden.tables import Incident

LABEL = {
    "stale_run": "Job that never finished", "source_down": "Source not answering",
    "source_flaky": "Source failing in some niches", "missing_key": "Missing key",
    "stuck_funding": "Waiting for your R200", "stuck_cards": "Cards waiting too long",
    "silent_test": "Funded test with no visitors", "daily_cap": "Daily spend cap",
    "spend_spike": "Unusual spend", "missed_night": "Missed night run", "retry": "Retried a source",
    "training_failed": "Squad not certified", "stuck_launch": "Waiting for you to fund a launch",
}


def record(kind: str, subject: str, detail: str, action: str, outcome: str, key: str | None = None) -> Incident:
    key = key or f"{kind}:{subject}"
    with session() as s:
        inc = s.exec(select(Incident).where(Incident.key == key, Incident.resolved_at.is_(None))).first()
        if inc is None:
            inc = Incident(key=key, kind=kind, subject=subject)
        inc.detail, inc.action, inc.outcome, inc.last_seen = detail, action, outcome, utcnow()
        if outcome == "fixed":
            inc.resolved_at = utcnow()  # a fix closes the incident; it stays in the log
        s.add(inc)
        s.commit()
        s.refresh(inc)
    return inc


def resolve_cleared(kinds: set[str], still_open: set[str]) -> int:
    """Close open incidents of these kinds whose condition no longer holds."""
    n = 0
    with session() as s:
        for inc in s.exec(select(Incident).where(Incident.resolved_at.is_(None), Incident.kind.in_(kinds))):
            if inc.key not in still_open:
                inc.resolved_at = utcnow()
                s.add(inc)
                n += 1
        s.commit()
    return n


def dismiss(incident_id: int) -> bool:
    """A human says they handled it. The next check reopens it if the problem is still there."""
    with session() as s:
        inc = s.get(Incident, incident_id)
        if not inc or inc.resolved_at:
            return False
        inc.resolved_at = utcnow()
        s.add(inc)
        s.commit()
    return True


def open_items() -> list[Incident]:
    with session() as s:
        return list(s.exec(select(Incident).where(Incident.resolved_at.is_(None))
                           .order_by(Incident.created_at.desc())))


def since(days: float) -> list[Incident]:
    with session() as s:
        return list(s.exec(select(Incident).where(Incident.created_at >= utcnow() - timedelta(days=days))
                           .order_by(Incident.created_at.desc())))


def as_dict(inc: Incident) -> dict:
    return {"id": inc.id, "kind": inc.kind, "label": LABEL.get(inc.kind, inc.kind), "subject": inc.subject,
            "detail": inc.detail, "action": inc.action, "outcome": inc.outcome,
            "open": inc.resolved_at is None, "created": inc.created_at.isoformat() if inc.created_at else None}

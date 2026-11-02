"""Sources the Fixer has paused. Scouts skip a held source until the hold expires."""
from __future__ import annotations

from datetime import timedelta

from sqlmodel import select

from factory import config
from factory.models import session, utcnow
from factory.warden.tables import SourceHold


def _aware(dt):
    from datetime import timezone
    return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)


def local(dt) -> str:
    """A time as the player reads it: South African time."""
    from zoneinfo import ZoneInfo
    return _aware(dt).astimezone(ZoneInfo("Africa/Johannesburg")).strftime("%a %H:%M SAST")


def active() -> dict[str, SourceHold]:
    now = utcnow()
    with session() as s:
        rows = s.exec(select(SourceHold).where(SourceHold.released_at.is_(None)))
        return {h.source: h for h in rows if _aware(h.until) > now}


def hold(source: str, reason: str) -> SourceHold:
    hours = float(config.settings()["warden"]["hold_hours"])
    current = active().get(source)
    if current:
        return current
    h = SourceHold(source=source, until=utcnow() + timedelta(hours=hours), reason=reason[:300])
    with session() as s:
        s.add(h)
        s.commit()
        s.refresh(h)
    return h


def release_all() -> int:
    n = 0
    with session() as s:
        for h in s.exec(select(SourceHold).where(SourceHold.released_at.is_(None))):
            h.released_at = utcnow()
            s.add(h)
            n += 1
        s.commit()
    return n

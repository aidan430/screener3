"""Health check: what the Warden looks at every 15 minutes (and after every night).

Each check records incidents (see incidents.py); conditions that cleared are
resolved automatically. The check itself is an AgentRun, so it shows on the map.
"""
from __future__ import annotations

import re
from collections import defaultdict
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

from sqlmodel import func, select

from factory import agents, config, costs
from factory.models import AgentRun, Card, Cost, RunLog, SmokeTest, session, tonight, utcnow
from factory.warden import fixer, holds, incidents
from factory.warden.tables import Incident

CHECKED = {"source_down", "source_flaky", "missing_key", "stuck_funding", "stuck_cards", "silent_test",
           "daily_cap", "spend_spike"}
SAST = ZoneInfo("Africa/Johannesburg")


def cfg() -> dict:
    return config.settings()["warden"]


def now_sast() -> datetime:
    return datetime.now(SAST)


def _short(text: str, n: int = 140) -> str:
    text = re.sub(r"^FAILED:\s*", "", text or "unknown error")
    text = "; ".join(dict.fromkeys(text.split("; ")))  # the same error from several queries, once
    return text if len(text) <= n else text[: n - 1] + "…"


def missing_keys() -> list[Incident]:
    if config.env("ANTHROPIC_API_KEY") or config.env("ANTHROPIC_AUTH_TOKEN"):
        return []
    return [incidents.record("missing_key", "ANTHROPIC_API_KEY",
                             "No agent can think: ANTHROPIC_API_KEY is not set, so no cards, gates or Deep Dives run.",
                             "Nothing the Warden can fix. Scouts still collect posts, so nothing is lost.", "needs_you")]


def source_health() -> tuple[list[Incident], set[str]]:
    n, out, keep = int(cfg()["hold_after_runs"]), [], set()
    enabled = [k for k, v in config.settings()["sources"].items() if v]
    with session() as s:
        logs = list(s.exec(select(RunLog).where(RunLog.stage == "scout").order_by(RunLog.id.desc()).limit(n)))
        rows = defaultdict(list)  # source -> [(ran, failed, last error)] newest first
        for rl in logs:
            jobs = list(s.exec(select(AgentRun).where(AgentRun.dept == "research", AgentRun.started_at >= rl.started_at,
                                                      AgentRun.started_at <= (rl.finished_at or utcnow()))))
            for src in enabled:
                ran = [j for j in jobs if j.role == f"{src} scout" and j.status in ("ok", "failed")]
                bad = [j for j in ran if j.status == "failed"]
                rows[src].append((len(ran), len(bad), bad[0].summary if bad else ""))
    held = holds.active()
    for src in enabled:
        if src in held:
            keep.add(f"source_down:{src}")
            continue
        hist = rows.get(src, [])
        if not hist or hist[0][0] == 0:
            continue
        if len(hist) >= n and all(r[0] and r[1] == r[0] for r in hist):
            err = _short(hist[0][2])
            h = holds.hold(src, reason=err)
            blocked = re.search(r"\b40[13]\b", err) is not None
            detail = f"{src} failed in every niche on the last {n} runs ({err})."
            if blocked:
                detail += " A 401 or 403 usually means the network blocks it or it needs credentials."
            out.append(incidents.record("source_down", src, detail,
                                        f"Paused {src} until {holds.local(h.until)} so nights are not "
                                        "wasted on it. Scouts try it again after that.",
                                        "needs_you" if blocked else "fixed"))
        elif hist[0][1]:
            temporary = fixer.TRANSIENT.search(hist[0][2] or "") is not None
            out.append(incidents.record("source_flaky", src, f"{src} failed in {hist[0][1]} of {hist[0][0]} niches "
                                        f"on the last run ({_short(hist[0][2])}).",
                                        "Retried once, as the error looked temporary." if temporary else
                                        "Not a temporary error, so no retry; it is tried again next night.",
                                        "watching"))
    return out, keep


def stuck() -> list[Incident]:
    out, days = [], int(cfg()["stuck_funding_days"])
    with session() as s:
        tests = list(s.exec(select(SmokeTest).where(SmokeTest.status == "awaiting_funding")))
        old = dict(s.exec(select(Card.status, func.count()).where(
            Card.status.in_(["scouted", "proof_passed", "craft_passed"]),
            Card.created_at < utcnow() - timedelta(days=2)).group_by(Card.status)).all())
    for t in tests:
        age = (utcnow() - agents._aware(t.created_at)).days
        if age >= days:
            out.append(incidents.record("stuck_funding", t.name, f"“{t.name}” has waited {age} days at tower 4 for your R200.",
                                        "Kept it waiting and put it in your Monday report. Nothing is spent without your click.",
                                        "needs_you", key=f"stuck_funding:{t.id}"))
    if old:
        where = ", ".join(f"{n} at tower {['scouted', 'proof_passed', 'craft_passed'].index(k) + 1}" for k, n in old.items())
        out.append(incidents.record("stuck_cards", "towers 1-3", f"{sum(old.values())} cards have waited more than 2 days ({where}).",
                                    "They are retried every night. If it keeps happening, check the API key and the stage caps.",
                                    "watching", key="stuck_cards"))
    return out


def silent_tests() -> list[Incident]:
    hours = float(cfg()["silent_test_hours"])
    with session() as s:
        tests = list(s.exec(select(SmokeTest).where(SmokeTest.status == "approved", SmokeTest.visitors == 0)))
    out = []
    for t in tests:
        if t.approved_at and utcnow() - agents._aware(t.approved_at) >= timedelta(hours=hours):
            out.append(incidents.record("silent_test", t.name, f"“{t.name}” has had no visitors {hours:.0f}+ hours after you funded it.",
                                        "Spent nothing. Check that the ads are live in Meta Ads Manager and that the page opens.",
                                        "needs_you", key=f"silent_test:{t.id}"))
    return out


def spend() -> list[Incident]:
    out, cap, today = [], costs.daily_cap(), costs.spent_today()
    day = now_sast().date().isoformat()
    if cap and today >= 0.8 * cap:
        with session() as s:
            hit = s.exec(select(func.count()).select_from(AgentRun).where(
                AgentRun.status == "blocked", AgentRun.started_at >= costs.day_start_utc(),
                AgentRun.summary.contains("daily agent-spend cap"))).one()
        out.append(incidents.record("daily_cap", day, f"R{today:.2f} of the R{cap:.0f} daily agent-spend cap used today.",
                                    "Stopped all agent calls for the rest of the day; work resumes after midnight SAST."
                                    if hit else "Watching. The cap stops every agent call when it is reached.",
                                    "watching", key=f"daily_cap:{day}"))
    with session() as s:
        nights = list(s.exec(select(Cost.night, func.sum(Cost.zar)).group_by(Cost.night).order_by(Cost.night.desc()).limit(8)))
    if len(nights) >= 4 and nights[0][0] == tonight():
        prev = [z for _, z in nights[1:]]
        avg = sum(prev) / len(prev)
        if avg > 0 and nights[0][1] > float(cfg()["spend_spike_ratio"]) * avg and nights[0][1] > 5:
            out.append(incidents.record("spend_spike", nights[0][0], f"Tonight's agent spend R{nights[0][1]:.2f} is "
                                        f"{nights[0][1] / avg:.1f}x the recent average (R{avg:.2f}).",
                                        "Watching. Every stage still stops at its R20 cap and the day at the daily cap.",
                                        "watching", key=f"spend_spike:{nights[0][0]}"))
    return out


def missed_night(catch_up: bool) -> Incident | None:
    hh, mm = (int(x) for x in str(cfg()["missed_night_after"]).split(":"))
    now = now_sast()
    if (now.hour, now.minute) < (hh, mm):
        return None
    night, key = tonight(), f"missed_night:{tonight()}"
    with session() as s:
        ran_tonight = s.exec(select(RunLog).where(RunLog.stage == "scout", RunLog.night == night)).first()
        ever_ran = s.exec(select(RunLog).where(RunLog.stage == "scout")).first()
        done = s.exec(select(Incident).where(Incident.key == key, Incident.outcome == "fixed")).first()
    if ran_tonight or not ever_ran or done:
        return None
    if catch_up:
        return fixer.catch_up_night()
    return incidents.record("missed_night", night, f"No scouting run has happened for {night} yet.",
                            "The scheduler catches up once on its next check.", "watching", key=key)


def check(catch_up: bool = False) -> dict:
    """One full health check. `catch_up` lets it run a missed night (scheduler only)."""
    with agents.run("warden", "Health check", subject="all departments") as job:
        fixed = fixer.close_stale_runs()
        found, keep = source_health()
        for fn in (missing_keys, stuck, silent_tests, spend):
            found += fn()
        missed = missed_night(catch_up)
        fixed += [i for i in found + ([missed] if missed else []) if i.outcome == "fixed"]
        keep |= {i.key for i in found if i.outcome != "fixed"}
        incidents.resolve_cleared(CHECKED, keep)
        open_items = incidents.open_items()
        needs = [i for i in open_items if i.outcome == "needs_you"]
        job.summary = f"{len(open_items)} open, {len(needs)} need you, {len(fixed)} fixed just now"
    from factory.warden import mailer
    mailer.alert(needs)
    return {"open": open_items, "needs_you": needs, "fixed": fixed, "summary": job.summary}

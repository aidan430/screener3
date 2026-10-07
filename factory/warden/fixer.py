"""The Fixer: what the Warden may repair on its own.

Allowed: close jobs that died, retry a source that hit a rate limit or server
error (once per niche per night), pause a source that keeps failing, and catch
up a night that never ran. Never: spend money, approve anything, publish,
delete data, or change settings.yaml (which holds its own limits).
"""
from __future__ import annotations

import logging
import re
import time
from datetime import timedelta

from sqlmodel import select

from factory import agents, config
from factory.models import AgentRun, Niche, session, tonight, utcnow
from factory.warden import holds, incidents

log = logging.getLogger("factory.warden.fixer")
TRANSIENT = re.compile(r"HTTP (429|5\d\d)|timed? ?out|temporar|server error|connection reset", re.I)


def cfg() -> dict:
    return config.settings()["warden"]


def close_stale_runs() -> list:
    cutoff = utcnow() - timedelta(hours=float(cfg()["stale_run_hours"]))
    with session() as s:
        rows = list(s.exec(select(AgentRun).where(AgentRun.status == "running", AgentRun.started_at < cutoff)))
        for r in rows:
            r.status, r.finished_at = "failed", utcnow()
            r.summary = ((r.summary + " ") if r.summary else "") + "No finish recorded: its process stopped."
            s.add(r)
        s.commit()
    return [incidents.record("stale_run", f"{r.role} · {r.subject}",
                             f"{r.role} ({r.subject}) started at {agents._aware(r.started_at):%a %H:%M} UTC and never finished.",
                             "Marked the job as failed so the map stops showing it as working. Tomorrow's run redoes the work.",
                             "fixed", key=f"stale_run:{r.id}") for r in rows]


def retry_failed_sources(delay: float | None = None) -> list:
    """Retry tonight's scout jobs that failed for a temporary reason, once each."""
    night = tonight()
    with session() as s:
        failed = [r for r in s.exec(select(AgentRun).where(AgentRun.night == night, AgentRun.dept == "research",
                                                           AgentRun.status == "failed"))
                  if r.role.endswith(" scout") and TRANSIENT.search(r.summary or "")]
        done = {r.subject for r in s.exec(select(AgentRun).where(AgentRun.night == night, AgentRun.dept == "warden",
                                                                 AgentRun.role == "Fixer"))}
        niches = {n.slug: n for n in s.exec(select(Niche))}
    todo = list(dict.fromkeys((r.role, r.subject) for r in failed if f"retry {r.role} · {r.subject}" not in done))
    held = holds.active()
    todo = [(role, slug) for role, slug in todo if role[: -len(" scout")] not in held and slug in niches]
    if not todo:
        return []
    wait = float(cfg()["retry_delay_s"]) if delay is None else delay
    if wait:
        print(f"  Warden: waiting {wait:.0f} s before retrying {len(todo)} source job(s) that hit a temporary error")
        time.sleep(wait)
    from factory.scouts import runner
    out = []
    for role, slug in todo:
        src, niche = role[: -len(" scout")], niches[slug]
        with agents.run("warden", "Fixer", subject=f"retry {role} · {slug}") as job:
            new = runner.fetch_source(niche, src, job)
            ok = job.status == "ok"
            job.summary, job.status = f"retried {role} for {slug}: {job.summary}", "ok" if ok else "failed"
        cards = runner.distill_job(niche) if new else []
        out.append(incidents.record(
            "retry", f"{src} · {slug}", f"{src} failed for {slug} with a temporary error.",
            f"Retried once: {job.summary}" + (f" {len(cards)} new card(s)." if cards else ""),
            "fixed" if ok else "watching", key=f"retry:{src}:{slug}:{night}"))
        print(f"  Warden retried {src} for {slug}: {'ok' if ok else 'still failing'}")
    return out


def catch_up_night():
    """Run tonight's pipeline once when the scheduled run never happened (computer asleep, crash)."""
    from factory import night
    when = tonight()
    with agents.run("warden", "Fixer", subject="catch up the missed night") as job:
        night.run()
        job.summary = f"ran the {when} night that the scheduler missed"
    return incidents.record("missed_night", when, f"No scouting run had happened for {when} by "
                            f"{cfg()['missed_night_after']} SAST.", "Ran the night pipeline once to catch up.",
                            "fixed", key=f"missed_night:{when}")

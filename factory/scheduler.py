"""APScheduler (SAST): scouts 01:00; Warden retries, gates, Deep Dive and smoke prep 02:00;
Warden health check every 15 minutes; Monday report 07:00; monthly review on the 1st.

The dashboard state is built on every /api/state request; a snapshot is also
written to data/state.json after each job.
Usage: python -m factory.scheduler   (run alongside `make serve`)
"""
from __future__ import annotations

import logging

from apscheduler.schedulers.blocking import BlockingScheduler
from apscheduler.triggers.cron import CronTrigger

from factory import config
from factory.api import state

log = logging.getLogger("factory.scheduler")
TZ = "Africa/Johannesburg"


def scout_job() -> None:
    from factory.scouts import runner
    runner.run()
    state.snapshot()


def gates_job() -> None:
    from factory.dive import run as dive
    from factory.gates import run as gates
    from factory.smoke import run as smoke
    from factory.warden import fixer
    fixer.retry_failed_sources(delay=0)  # an hour after scouting: rate limits have usually cleared
    res = gates.run()
    if not any("cap" in r["note"] for r in res.values()) and "cap" not in dive.run()["note"]:
        smoke.run()
    state.snapshot()


def warden_job() -> None:
    from factory.warden import health
    health.check(catch_up=True)
    state.snapshot()


def report_job(kind: str) -> None:
    from factory.warden import report
    report.save(kind)


def main() -> None:
    config.setup_logging()
    sched, w = config.settings()["schedule"], config.settings()["warden"]
    s = BlockingScheduler(timezone=TZ)
    for name, fn in (("scout", scout_job), ("gates", gates_job)):
        hh, mm = sched[name].split(":")
        s.add_job(fn, CronTrigger(hour=int(hh), minute=int(mm), timezone=TZ), id=name,
                  misfire_grace_time=3600, coalesce=True, max_instances=1)
    s.add_job(warden_job, "interval", minutes=int(w["check_every_min"]), id="warden", coalesce=True, max_instances=1)
    hh, mm = str(w["report_time"]).split(":")
    s.add_job(report_job, CronTrigger(day_of_week=w["report_day"], hour=int(hh), minute=int(mm), timezone=TZ),
              args=["weekly"], id="weekly_report", misfire_grace_time=6 * 3600, coalesce=True)
    s.add_job(report_job, CronTrigger(day=1, hour=int(hh), minute=int(mm) + 30 if int(mm) < 30 else int(mm),
                                      timezone=TZ), args=["monthly"], id="monthly_review",
              misfire_grace_time=6 * 3600, coalesce=True)
    s.add_job(state.snapshot, "interval", minutes=5, id="state")
    for job in s.get_jobs():
        print(f"scheduled {job.id}: {job.trigger}")
    s.start()


if __name__ == "__main__":
    main()

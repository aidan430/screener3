"""APScheduler: scouts 01:00 SAST; gates, Deep Dive and smoke prep 02:00. The dashboard
state is built on every /api/state request, so it is always current; a
snapshot is also written to data/state.json after each job.

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
    res = gates.run()
    if not any("cap" in r["note"] for r in res.values()) and "cap" not in dive.run()["note"]:
        smoke.run()
    state.snapshot()


def main() -> None:
    config.setup_logging()
    sched = config.settings()["schedule"]
    s = BlockingScheduler(timezone=TZ)
    for name, fn in (("scout", scout_job), ("gates", gates_job)):
        hh, mm = sched[name].split(":")
        s.add_job(fn, CronTrigger(hour=int(hh), minute=int(mm), timezone=TZ), id=name,
                  misfire_grace_time=3600, coalesce=True, max_instances=1)
    s.add_job(state.snapshot, "interval", minutes=5, id="state")
    for job in s.get_jobs():
        print(f"scheduled {job.id}: {job.trigger}")
    s.start()


if __name__ == "__main__":
    main()

"""Warden command line.

    python -m factory.warden.run check     # health check now, print what it found
    python -m factory.warden.run report    # write the weekly report now and print it
    python -m factory.warden.run monthly   # write the monthly review now
    python -m factory.warden.run release   # release every paused source
"""
from __future__ import annotations

import sys

from factory import config, costs
from factory.warden import health, holds, report

MARK = {"fixed": "FIXED", "needs_you": "NEEDS YOU", "watching": "WATCHING"}


def print_check(res: dict) -> None:
    print(f"\n== Warden health check: {res['summary']}")
    cap = costs.daily_cap()
    print(f"  agent spend today: R{costs.spent_today():.2f}" + (f" of the R{cap:.0f} daily cap" if cap else ""))
    for i in res["fixed"]:
        print(f"  [{MARK['fixed']:<9}] {i.detail}\n              -> {i.action}")
    for i in res["open"]:
        print(f"  [{MARK[i.outcome]:<9}] {i.detail}\n              -> {i.action}")
    held = holds.active()
    for src, h in held.items():
        print(f"  paused source: {src} until {holds.local(h.until)} ({h.reason})")
    if not (res["fixed"] or res["open"] or held):
        print("  all clear")


def main(argv: list[str]) -> None:
    config.setup_logging()
    cmd = argv[0] if argv else "check"
    if cmd == "check":
        print_check(health.check(catch_up=False))
    elif cmd in ("report", "monthly"):
        rep = report.save("weekly" if cmd == "report" else "monthly")
        print(rep.body_md)
        print(f"(saved as report #{rep.id}; {'emailed' if rep.emailed else 'not emailed: SMTP not configured'})")
    elif cmd == "release":
        print(f"released {holds.release_all()} paused source(s)")
    else:
        raise SystemExit(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:])

"""One full night: scout -> gates -> Deep Dive -> smoke prep -> Training -> Warden check -> state.

Stops early if a stage hits the R20 cap. Usage: python -m factory.night
"""
from __future__ import annotations

import json

from sqlmodel import select

from factory import config, costs
from factory.api import state
from factory.dive import run as dive
from factory.gates import run as gates
from factory.models import RunLog, session, tonight
from factory.scouts import runner
from factory.smoke import run as smoke
from factory.training import run as training
from factory.warden import fixer, health
from factory.warden import run as warden_cli


def stopped_on_cap(stage: str) -> str | None:
    with session() as s:
        row = s.exec(select(RunLog).where(RunLog.stage == stage).order_by(RunLog.id.desc())).first()
    return row.summary if row is not None and not row.ok and "cap" in (row.summary or "") else None


def pipeline() -> str:
    """Scout -> gates -> Deep Dive -> smoke prep. Returns why it halted, or ""."""
    runner.run()
    fixer.retry_failed_sources()
    if (msg := stopped_on_cap("scout")):
        return f"after scout: {msg}"
    res = gates.run()
    if any("cap" in r["note"] for r in res.values()):
        return "after gates: a spending cap was reached"
    if "cap" in dive.run()["note"]:
        return "after Deep Dive: a spending cap was reached"
    smoke.run()
    if "cap" in training.run()["note"]:
        return "after Training: a spending cap was reached"
    return ""


def run() -> dict:
    print(f"=== Venture Factory night {tonight()} ===")
    halted = pipeline()
    if halted:
        print(f"\nNIGHT HALTED {halted}")
    warden_cli.print_check(health.check())  # the Warden always looks, halted or not
    st = state.snapshot()
    print("\n=== State refresh (data/state.json, served at /api/state) ===")
    print(json.dumps({k: st[k] for k in ("gold", "elixir_month", "agents_total", "net_30d", "night")}))
    for b in st["buildings"]:
        print(f"  {b['kind']:<8} {b['name']:<24} " + " | ".join(f"{v} {k}" for v, k in b["kv"]))
    print("  side quests:")
    for q in st["side_quests"]:
        print(f"   - {q}")
    costs.print_nightly_total()
    return st


if __name__ == "__main__":
    config.setup_logging()
    run()

"""One full night: scout -> gates -> Deep Dive -> smoke (prepare only) -> state refresh.

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


def stopped_on_cap(stage: str) -> str | None:
    with session() as s:
        row = s.exec(select(RunLog).where(RunLog.stage == stage).order_by(RunLog.id.desc())).first()
    return row.summary if row is not None and not row.ok and "cap" in (row.summary or "") else None


def run() -> dict:
    print(f"=== Venture Factory night {tonight()} ===")
    runner.run()
    if (msg := stopped_on_cap("scout")):
        print(f"\nNIGHT HALTED after scout: {msg}")
        return state.snapshot()
    res = gates.run()
    if any("cap" in r["note"] for r in res.values()):
        print("\nNIGHT HALTED after gates: stage cap reached")
        return state.snapshot()
    res = dive.run()
    if "cap" in res["note"]:
        print("\nNIGHT HALTED after Deep Dive: stage cap reached")
        return state.snapshot()
    smoke.run()
    st = state.snapshot()
    print("\n=== State refresh (data/state.json, served at /api/state) ===")
    print(json.dumps({k: st[k] for k in ("gold", "elixir_month", "scouts_active", "net_30d", "night")}))
    for b in st["buildings"]:
        print(f"  {b['kind']:<8} {b['name']:<20} " + " | ".join(f"{v} {k}" for v, k in b["kv"]))
    print("  side quests:")
    for q in st["side_quests"]:
        print(f"   - {q}")
    costs.print_nightly_total()
    return st


if __name__ == "__main__":
    config.setup_logging()
    run()

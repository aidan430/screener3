"""Run both gates over every card waiting at them and print verdicts.

Usage: python -m factory.gates.run
"""
from __future__ import annotations

import logging
import textwrap

from factory import agents, config, costs
from factory.gates import craft, proof
from factory.models import Card, GateResult, RunLog, session, utcnow

log = logging.getLogger("factory.gates")


def show(card: Card, r: GateResult) -> None:
    mark = "PASS" if r.verdict == "pass" else "KILL"
    print(f"  [{mark}] {r.gate:<5} {r.score:>2}/10  #{card.id} {card.title}")
    for line in textwrap.wrap(r.reasoning, 92):
        print(f"           {line}")
    for e in r.evidence[:3]:
        print(f"           - \"{e[:140]}\"")


def run_gate(gate) -> tuple[int, int, str]:
    cards = gate.pending()
    print(f"\n== Gate of {gate.NAME.title()}: {len(cards)} card(s) waiting")
    passed = killed = 0
    note = ""
    with costs.stage(gate.NAME) as st:
        for card in cards:
            try:
                with agents.run("research", f"{gate.NAME.title()} gatekeeper", subject=card.title,
                                card=card, tower=gate.TOWER) as job:
                    r = gate.run_card(card)
                    job.summary = f"{r.verdict.upper()} {r.score}/10: {r.reasoning[:160]}"
            except costs.StageOverBudget as e:
                note = f"STOPPED: {e}"
                print(f"  {note}")
                break
            except costs.NoApiKey as e:
                note = f"STOPPED: {e}"
                print(f"  {note}")
                break
            except Exception as e:  # one bad response should not kill the night
                log.exception("gate %s failed on card %s", gate.NAME, card.id)
                print(f"  [ERR ] #{card.id} {card.title}: {e} (card stays at the gate)")
                continue
            show(card, r)
            passed += r.verdict == "pass"
            killed += r.verdict == "kill"
        print(f"  -> {passed} passed, {killed} killed, elixir R{st['spent_zar']:.2f}")
    return passed, killed, note


def run() -> dict:
    out = {}
    for gate in (proof, craft):
        row = RunLog(stage=gate.NAME)
        p, k, note = run_gate(gate)
        out[gate.NAME] = {"passed": p, "killed": k, "note": note}
        row.ok, row.summary, row.finished_at = not note, note or f"{p} passed, {k} killed", utcnow()
        with session() as s:
            s.add(row)
            s.commit()
        if note.startswith("STOPPED") and "cap" in note:
            break
    costs.print_nightly_total()
    return out


if __name__ == "__main__":
    config.setup_logging()
    run()

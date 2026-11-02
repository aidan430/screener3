"""Gate of Proof: is there evidence someone pays today? Score < 6 is killed.

Killed cards are archived (status killed_proof), never deleted.
"""
from __future__ import annotations

from factory import config
from factory.gates.common import cards_with_status, judge, save
from factory.models import Card, GateResult

NAME = "proof"
TOWER = 1


def run_card(card: Card) -> GateResult:
    result = judge(NAME, card, int(config.settings()["thresholds"]["proof_min_score"]), check_evidence=True)
    save(result, card, "proof_passed", "killed_proof")
    return result


def pending() -> list[Card]:
    return cards_with_status("scouted")

"""Gate of Craft: solo-buildable in under 7 days with no humans in the loop?

Runs only on cards that passed the Gate of Proof. Same output shape.
"""
from __future__ import annotations

from factory import config
from factory.gates.common import cards_with_status, judge, save
from factory.models import Card, GateResult

NAME = "craft"


def run_card(card: Card) -> GateResult:
    result = judge(NAME, card, int(config.settings()["thresholds"]["craft_min_score"]), check_evidence=False)
    save(result, card, "craft_passed", "killed_craft")
    return result


def pending() -> list[Card]:
    return cards_with_status("proof_passed")

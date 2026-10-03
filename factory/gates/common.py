"""Shared gate machinery: rubric loading, judge output shape, persistence."""
from __future__ import annotations

import json
import re
from pathlib import Path

from pydantic import BaseModel, Field
from sqlmodel import select

from factory import config, costs
from factory.models import Card, GateResult, Niche, Signal, session

RUBRIC = Path(__file__).with_name("rubric.md")


class Verdict(BaseModel):
    score: int = Field(ge=0, le=10)
    verdict: str = Field(description='"pass" or "kill"')
    reasoning: str
    evidence: list[str]


def rubric(section: str) -> tuple[str, str]:
    text = RUBRIC.read_text()
    version = re.search(r"version:\s*([\w.\-]+)", text).group(1)
    m = re.search(rf"^## {section}\n(.*?)(?=^## |\Z)", text, re.S | re.M)
    return m.group(1).strip(), version


def material(card: Card) -> tuple[str, str]:
    """The card plus its source post: everything the judge may use."""
    with session() as s:
        niche = s.get(Niche, card.niche_id)
        sig = s.get(Signal, card.signal_id) if card.signal_id else None
    post = ""
    if sig:
        post = (f"\n<source_post url=\"{sig.url}\" source=\"{sig.source}\" score=\"{sig.score:g}\" "
                f"replies=\"{sig.replies}\">\nTITLE: {sig.title}\nTEXT: {sig.text[:4000]}\n</source_post>")
    pay = f"{card.pay_currency}{card.pay_amount:g}" if card.pay_amount is not None else "none extracted"
    block = (f"<card id=\"{card.id}\">\nNiche: {niche.slug} (region {niche.region})\n"
             f"Known competitors in this niche: {', '.join(niche.competitors) or 'none'}\n"
             f"Title: {card.title}\nProblem: {card.problem}\nQuote: \"{card.quote}\"\n"
             f"Pay evidence: {card.pay_evidence or 'none'}\nPay amount: {pay}\nURL: {card.url}\n</card>{post}")
    corpus = f"{card.title}\n{card.problem}\n{card.quote}\n{card.pay_evidence}\n{niche.slug}\n" \
             f"{' '.join(niche.competitors)}\n{sig.title if sig else ''}\n{sig.text if sig else ''}"
    return block, corpus


def judge(gate: str, card: Card, min_score: int, check_evidence: bool) -> GateResult:
    from factory.scouts.distill import verbatim
    text, version = rubric(gate)
    block, corpus = material(card)
    system = (text + "\n\nReturn JSON with fields score (0-10 integer), verdict "
              '("pass" or "kill"), reasoning, evidence (list of strings).')
    model = config.settings()["models"]["judge"]
    v: Verdict = costs.call(stage_name=gate, model=model, system=system, max_tokens=900,
                            prompt=f"Judge this card.\n\n{block}", output=Verdict, card_id=card.id)
    evidence = v.evidence
    reasoning = v.reasoning.strip()
    if check_evidence:
        kept = [e for e in evidence if verbatim(e, corpus)]
        if len(kept) < len(evidence):
            reasoning += f" [system: {len(evidence) - len(kept)} non-verbatim evidence item(s) discarded]"
        evidence = kept
    passed = v.score >= min_score and v.verdict.lower().startswith("pass")
    if passed and check_evidence and not evidence:
        passed = False
        reasoning += " [system: pass overruled, no verbatim evidence survived]"
    return GateResult(card_id=card.id, gate=gate, score=v.score, verdict="pass" if passed else "kill",
                      reasoning=reasoning, evidence_json=json.dumps(evidence), rubric_version=version,
                      model=model)


def save(result: GateResult, card: Card, pass_status: str, kill_status: str) -> None:
    with session() as s:
        s.add(result)
        c = s.get(Card, card.id)
        c.status = pass_status if result.verdict == "pass" else kill_status
        s.add(c)
        s.commit()
    card.status = c.status


def cards_with_status(status: str) -> list[Card]:
    with session() as s:
        return list(s.exec(select(Card).where(Card.status == status).order_by(Card.id)))

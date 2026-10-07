"""Deep Dive department: run the five analysts on every card waiting at tower 3,
write a Dossier and apply the Economics gate.

Usage: python -m factory.dive.run
"""
from __future__ import annotations

import json
import logging
import textwrap

from factory import agents, config, costs
from factory.commerce import landed
from factory.dive import capital, demand, economics, risk
from factory.gates.common import cards_with_status
from factory.models import Card, Dossier, GateResult, Niche, RunLog, session, utcnow
from factory.scouts.distill import verbatim

log = logging.getLogger("factory.dive")
TOWER = 3


def _left(cap: float, spent0: float) -> float:
    return max(0.0, cap - (costs.process_spent() - spent0))


def dive_card(card: Card) -> Dossier:
    with session() as s:
        niche = s.get(Niche, card.niche_id)
    cap, spent0 = float(config.settings()["caps"]["dive_zar_per_card"]), costs.process_spent()
    ctx = {"subject": card.title, "card": card, "tower": TOWER}
    with agents.run("dive", "Demand analyst", **ctx) as job:
        plan = demand.plan(card, niche, _left(cap, spent0))
        probes, notes = demand.probe(plan.terms, plan.business_model)
        stats, items = demand.demand_stats(probes), demand.evidence_items(card, probes)
        job.summary = (f"searched {', '.join(plan.terms)} as {plan.business_model}: {len(items) - 1} listings"
                       + (f"; {len(notes)} probe problems" if notes else ""))
        if len(items) == 1 and notes:
            job.status = "failed"  # no marketplace data at all; the analysts see only the post
    with agents.run("dive", "Competitor analyst", **ctx) as job:
        comps, cnotes = demand.competitors(items, niche)
        named = [c for c in comps if c.get("named")]
        job.summary = f"{len(comps)} competitors; {sum(len(c['complaints']) for c in named)} complaints from named apps"
    with agents.run("dive", "Economics analyst", **ctx) as job:
        econ, material = economics.analyse(card, niche, plan.business_model, items, stats, comps,
                                           _left(cap, spent0))
        numbers = economics.compute(econ, items)
        m, u = numbers["margin"], numbers.get("unit")
        job.summary = (f"{econ.business_model}: {econ.price_point:g} {econ.currency} {econ.price_unit}, "
                       f"margin {'unknown' if m is None else f'{m:.0%}'}, score {econ.score}/10")
        if u:
            be_cr = u["break_even_conversion"]
            job.summary = (f"local stock at R{u['price_zar']:,.0f}: R{u['landed_zar']:,.0f} landed, "
                           f"R{u['contribution_zar']:,.0f} left per order, break-even "
                           f"{'never' if be_cr is None else f'{be_cr:.1%} of visitors'}, score {econ.score}/10")
    with agents.run("dive", "Risk analyst", **ctx) as job:
        risks = risk.assess(card, niche, econ.business_model, comps, _left(cap, spent0))
        hard = [r for r in risks.risks if r.hard_kill]
        job.summary = risks.summary + (f" Hard kill: {hard[0].risk}" if hard else "")
    with agents.run("dive", "Capital estimator", **ctx) as job:
        lines, total = capital.estimate(econ.business_model, numbers["unit_cost_zar"], numbers.get("unit"))
        be = capital.break_even(capital.sunk(lines), numbers["unit_profit_zar"])
        verdict, reasons = capital.gate(econ.business_model, econ.score, numbers, total, be, risks.risks)
        job.summary = f"R{total:,.0f} to start, break-even {be or 'never'} sales: {verdict.upper()}"
    kept = [e for e in econ.evidence if verbatim(e, material)]
    reasoning = econ.reasoning.strip()
    if len(kept) < len(econ.evidence):
        reasoning += f" [system: {len(econ.evidence) - len(kept)} non-verbatim evidence item(s) discarded]"
    if notes + cnotes:
        reasoning += " [probe problems: " + "; ".join((notes + cnotes)[:3]) + "]"
    d = Dossier(card_id=card.id, business_model=econ.business_model, lane=config.lane_of(econ.business_model),
                search_terms_json=json.dumps(plan.terms), evidence_json=json.dumps(list(items.values()), default=str),
                demand_json=json.dumps(stats, default=str), competitors_json=json.dumps(comps, default=str),
                price_point=econ.price_point, currency=econ.currency.upper(), price_unit=econ.price_unit,
                price_basis=econ.price_basis_id, capital_zar=total, capital_lines_json=json.dumps(lines),
                break_even_sales=be, risks_json=json.dumps([r.model_dump() for r in risks.risks]),
                unit_json=json.dumps(numbers.get("unit") or {}),
                demand_score=econ.demand_score, competition_score=econ.competition_score, score=econ.score,
                verdict=verdict, reasoning=reasoning, kill_reasons_json=json.dumps(reasons),
                **{k: numbers[k] for k in ("price_zar", "unit_cost_zar", "unit_cost_basis", "fees_zar",
                                           "cac_zar", "unit_profit_zar", "margin")})
    return save(card, d, kept)


def save(card: Card, d: Dossier, kept: list[str]) -> Dossier:
    reasons = d.j("kill_reasons")
    gr = GateResult(card_id=card.id, gate="economics", score=d.score, verdict=d.verdict,
                    reasoning=d.reasoning + (" Kill reasons: " + "; ".join(reasons) if reasons else ""),
                    evidence_json=json.dumps(kept), rubric_version="dive-2026-10-07",
                    model=config.settings()["models"]["judge"])
    with session() as s:
        s.add(d)
        s.add(gr)
        c = s.get(Card, card.id)
        c.business_model, c.lane = d.business_model, d.lane
        c.status = "dive_passed" if d.verdict == "pass" else "killed_dive"
        s.add(c)
        s.commit()
        s.refresh(d)
    card.status, card.lane, card.business_model = c.status, d.lane, d.business_model
    return d


def show(card: Card, d: Dossier) -> None:
    label = config.business_models()["models"][d.business_model]["label"]
    mark = "PASS" if d.verdict == "pass" else "KILL"
    margin = "unknown" if d.margin is None else f"{d.margin:.0%}"
    print(f"  [{mark}] econ  {d.score:>2}/10  #{card.id} {card.title}  ({label}, {d.lane} lane)")
    if d.price_zar is not None:
        print(f"           price {d.price_point:g} {d.currency} {d.price_unit} (R{d.price_zar:,.0f}, anchored to "
              f"{d.price_basis}); unit profit R{d.unit_profit_zar or 0:,.0f}; margin {margin}")
        print(f"           unit cost: {d.unit_cost_basis}")
        if d.j("unit"):
            for line in landed.lines(d.j("unit"))[1:]:
                print(f"         {line}")
    print(f"           start-up R{d.capital_zar:,.0f}: "
          + "; ".join(f"{x[0]} R{x[1]:,.0f}" for x in d.j("capital_lines")))
    print(f"           break-even {d.break_even_sales or 'never'} sales; demand {d.demand_score}/10, "
          f"competition {d.competition_score}/10")
    for line in textwrap.wrap(d.reasoning, 92)[:5]:
        print(f"           {line}")
    for r in d.j("risks")[:3]:
        print(f"           risk ({r['severity']}{', HARD KILL' if r['hard_kill'] else ''}): {r['risk']}")
    for r in d.j("kill_reasons"):
        print(f"           x {r}")


def run() -> dict:
    cards = cards_with_status("craft_passed")
    print(f"\n== Deep Dive: {len(cards)} card(s) waiting at tower 3")
    row, passed, killed, note = RunLog(stage="dive"), 0, 0, ""
    with costs.stage("dive") as st:
        for card in cards:
            try:
                d = dive_card(card)
            except (costs.StageOverBudget, costs.NoApiKey) as e:
                note = f"STOPPED: {e}"
                print(f"  {note}")
                break
            except costs.CapExceeded as e:
                print(f"  [SKIP] #{card.id} {card.title}: {e} (stays at tower 3)")
                continue
            except Exception as e:
                log.exception("deep dive failed on card %s", card.id)
                print(f"  [ERR ] #{card.id} {card.title}: {e} (stays at tower 3)")
                continue
            show(card, d)
            passed += d.verdict == "pass"
            killed += d.verdict == "kill"
        print(f"  -> {passed} passed, {killed} killed, elixir R{st['spent_zar']:.2f}")
    row.ok, row.summary, row.finished_at = not note, note or f"{passed} passed, {killed} killed", utcnow()
    with session() as s:
        s.add(row)
        s.commit()
    return {"passed": passed, "killed": killed, "note": note}


if __name__ == "__main__":
    config.setup_logging()
    run()
    costs.print_nightly_total()

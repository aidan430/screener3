"""Training Academy: prepare, examine and certify the squad for every smoke-test winner.

Playbook writer -> Catalogue builder -> Prompt engineer -> for each agent:
Simulator, exam, Examiner -> one retake after a revision -> Certifier.
Usage: python -m factory.training.run
"""
from __future__ import annotations

import json
import logging
from pathlib import Path

from sqlmodel import select

from factory import agents, config, costs
from factory.build import spec
from factory.gates.common import cards_with_status
from factory.models import Build, Card, Dossier, Niche, RunLog, SmokeTest, session, utcnow
from factory.training import exam, writer
from factory.training.tables import Squad, SquadAgent

log = logging.getLogger("factory.training")
TOWER = 6


def _save(*rows) -> None:
    with session() as s:
        for r in rows:
            s.add(r)
        s.commit()
        for r in rows:
            s.refresh(r)


def _left(cap: float, spent0: float) -> float:
    return max(0.0, cap - (costs.process_spent() - spent0))


def train_card(card: Card) -> Squad:
    with session() as s:
        niche = s.get(Niche, card.niche_id)
        smoke = s.exec(select(SmokeTest).where(SmokeTest.card_id == card.id)).first()
        dossier = s.exec(select(Dossier).where(Dossier.card_id == card.id).order_by(Dossier.id.desc())).first()
    cap, spent0 = float(config.settings()["caps"]["training_zar_per_squad"]), costs.process_spent()
    ctx = {"subject": card.title, "card": card, "tower": TOWER}
    material = writer.facts(card, niche, dossier, smoke)
    with agents.run("train", "Playbook writer", **ctx) as job:
        brief = spec.write_brief(smoke, _left(cap, spent0))
        sops = writer.write_sops(card, material, _left(cap, spent0))
        job.summary = f"venture brief and policies for {smoke.name}; refunds: {sops.refund_policy[:80]}"
    with agents.run("train", "Catalogue builder", **ctx) as job:
        cat = writer.build_catalogue(card, material, dossier, _left(cap, spent0))
        job.summary = f"{len(cat.items)} item(s): " + "; ".join(f"{i.name} {i.price:g} {i.currency}" for i in cat.items)
    squad = Squad(card_id=card.id, slug=smoke.slug, folder=str(Path(brief).parent),
                  sops_json=sops.model_dump_json(), catalogue_json=cat.model_dump_json())
    _save(squad)
    with agents.run("train", "Prompt engineer", **ctx) as job:
        crew = [SquadAgent(squad_id=squad.id, role=k, name=r["name"], model=r["model"],
                           prompt=writer.compose(k, smoke.name, material, sops, cat))
                for k, r in config.squad()["roles"].items()]
        _save(*crew)
        job.summary = f"first instructions for {len(crew)} agents: " + ", ".join(a.name for a in crew)
    examine(card, squad, crew, material, cap, spent0)
    return certify(card, squad, crew, smoke, brief)


def examine(card: Card, squad: Squad, crew: list[SquadAgent], material: str, cap: float, spent0: float) -> None:
    attempts = int(config.squad()["training"]["max_attempts"])
    for attempt in range(1, attempts + 1):
        squad.attempts = attempt
        for a in [a for a in crew if a.status != "passed"]:
            if not a.j("scenarios"):
                with agents.run("train", "Simulator", subject=f"{a.name} · {card.title}", card=card, tower=TOWER) as job:
                    drills = exam.simulate(a, material, card.id, _left(cap, spent0))
                    a.scenarios_json = json.dumps([d.model_dump() for d in drills])
                    job.summary = f"{len(drills)} drills for the {a.name}, {sum(d.tests_guardrail for d in drills)} test the rules"
            drills = [exam.Scenario(**d) for d in a.j("scenarios")]
            with agents.run("train", f"Exam · {a.name}", subject=card.title, card=card, tower=TOWER) as job:
                replies = exam.sit(a, drills, card.id, _left(cap, spent0))
                job.summary = f"attempt {attempt}: answered {len(replies)} of {len(drills)} drills on {a.model}"
            with agents.run("train", "Examiner", subject=f"{a.name} · {card.title}", card=card, tower=TOWER) as job:
                rows = exam.grade(a, drills, replies, card.id, _left(cap, spent0))
                a.score, a.breaches, ok = exam.result(rows)
                a.exam_json, a.status, a.updated_at = json.dumps(rows), "passed" if ok else "failed", utcnow()
                job.summary = f"{a.name}: {a.score:.0%}, {a.breaches} rule(s) broken: {'PASS' if ok else 'FAIL'}"
            _save(a)
        failed = [a for a in crew if a.status != "passed"]
        if not failed or attempt == attempts:
            return
        for a in failed:
            with agents.run("train", "Prompt engineer", subject=f"revise {a.name} · {card.title}", card=card,
                            tower=TOWER) as job:
                rev = exam.revise(a, a.j("exam"), card.id, _left(cap, spent0))
                a.revisions_json = json.dumps(a.j("revisions") + [{"version": a.version + 1, "changes": rev.changes}])
                a.prompt, a.version, a.status = rev.prompt, a.version + 1, "drafted"
                job.summary = f"{a.name} v{a.version}: {rev.changes[:160]}"
            _save(a)


def certify(card: Card, squad: Squad, crew: list[SquadAgent], smoke: SmokeTest, brief: str) -> Squad:
    with agents.run("train", "Certifier", subject=card.title, card=card, tower=TOWER) as job:
        ok = all(a.status == "passed" for a in crew)
        squad.score = min(a.score for a in crew)
        squad.status, squad.certified_at = ("certified", utcnow()) if ok else ("failed", None)
        weakest = min(crew, key=lambda a: (a.status == "passed", a.score))
        squad.notes = "" if ok else f"{weakest.name} failed: {weakest.score:.0%}, {weakest.breaches} rule(s) broken."
        write_files(squad, crew)
        _save(squad)
        with session() as s:
            c = s.get(Card, card.id)
            c.status = "certified" if ok else "training_failed"
            s.add(c)
            if ok and not s.exec(select(Build).where(Build.smoke_id == smoke.id)).first():
                s.add(Build(smoke_id=smoke.id, slug=smoke.slug, spec_path=brief))
            s.commit()
        card.status = c.status
        job.summary = (f"certified: every agent passed (lowest {squad.score:.0%}); waiting for you to fund the launch"
                       if ok else f"not certified after {squad.attempts} attempt(s): {squad.notes}")
    return squad


def write_files(squad: Squad, crew: list[SquadAgent]) -> None:
    d = Path(squad.folder) / "squad"
    d.mkdir(parents=True, exist_ok=True)
    for a in crew:
        (d / f"{a.role}.md").write_text(a.prompt)
    (d / "catalogue.json").write_text(json.dumps(squad.j("catalogue"), indent=2))
    (d / "policies.json").write_text(json.dumps(squad.j("sops"), indent=2))
    lines = [f"# Exams for {squad.slug}", "", f"Status: {squad.status}. Pass mark "
             f"{float(config.squad()['training']['pass_mark']):.0%}, no rule broken.", ""]
    for a in crew:
        lines += [f"## {a.name} ({a.model}): {a.score:.0%}, {a.status}, instructions v{a.version}", ""]
        lines += [f"- Drill {r['n']}{' (rule test)' if r['guardrail'] else ''}: {r['situation']} -> {r['score']}/10"
                  f"{', BROKE A RULE' if r['breached'] else ''}. {r['feedback']}" for r in a.j("exam")]
        lines.append("")
    (d / "exams.md").write_text("\n".join(lines))


def _fail(card: Card, reason: str) -> None:
    with session() as s:
        c = s.get(Card, card.id)
        c.status = "training_failed"
        s.add(c)
        for sq in s.exec(select(Squad).where(Squad.card_id == card.id, Squad.status == "training")):
            sq.status, sq.notes = "failed", reason[:300]
            s.add(sq)
        s.commit()


def show(card: Card, squad: Squad) -> None:
    with session() as s:
        crew = list(s.exec(select(SquadAgent).where(SquadAgent.squad_id == squad.id)))
    mark = "CERTIFIED" if squad.status == "certified" else "NOT CERTIFIED"
    print(f"  [{mark}] #{card.id} {card.title}: {squad.attempts} attempt(s), lowest score {squad.score:.0%}")
    for a in crew:
        print(f"           {a.name:<14} {a.model:<18} {a.score:>4.0%}  {a.breaches} broken  v{a.version}  {a.status}")
    print(f"           files: {squad.folder}/squad/")


def run() -> dict:
    cards = cards_with_status("won")
    print(f"\n== Training Academy: {len(cards)} smoke-test winner(s) waiting at tower 6")
    row, done, failed, note = RunLog(stage="train"), 0, 0, ""
    with costs.stage("train") as st:
        for card in cards:
            try:
                sq = train_card(card)
            except (costs.StageOverBudget, costs.NoApiKey) as e:
                note = f"STOPPED: {e}"
                print(f"  {note}")
                break
            except costs.CapExceeded as e:
                _fail(card, f"ran out of its training budget: {e}")
                print(f"  [STOP] #{card.id} {card.title}: training budget used up; waits for you to retry")
                failed += 1
                continue
            except Exception as e:
                log.exception("training failed for card %s", card.id)
                _fail(card, f"error: {e}")
                print(f"  [ERR ] #{card.id} {card.title}: {e}")
                failed += 1
                continue
            show(card, sq)
            done += sq.status == "certified"
            failed += sq.status != "certified"
        print(f"  -> {done} certified, {failed} not certified, elixir R{st['spent_zar']:.2f}")
    row.ok, row.summary, row.finished_at = not note, note or f"{done} certified, {failed} not certified", utcnow()
    _save(row)
    return {"certified": done, "failed": failed, "note": note}


if __name__ == "__main__":
    config.setup_logging()
    run()
    costs.print_nightly_total()

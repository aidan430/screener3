"""Fund launch: the human's second money approval for a certified niche (tower 6).

Nothing is bought automatically. Launching creates the Venture row (a mine at
the Market, status building), prepares the venture folder for the Claude Code
session that builds it, and returns the shopping list from the Dossier.
"""
from __future__ import annotations

import subprocess
from pathlib import Path

from sqlmodel import select

from factory.models import Build, Card, Dossier, SmokeTest, Venture, session, utcnow
from factory.training.tables import Squad

GITIGNORE = ".env\n.venv/\n__pycache__/\ndata/\n"


def shopping_list(card_id: int) -> tuple[list[list], float]:
    with session() as s:
        d = s.exec(select(Dossier).where(Dossier.card_id == card_id).order_by(Dossier.id.desc())).first()
    lines = [x for x in (d.j("capital_lines") if d else []) if not x[0].startswith("Smoke test")]
    return lines, round(sum(x[1] for x in lines), 2)


def launch(card_id: int) -> dict:
    with session() as s:
        card = s.get(Card, card_id)
        if not card or card.status != "certified":
            return {"ok": False, "message": "Only a niche whose squad is certified can be launched."}
        squad = s.exec(select(Squad).where(Squad.card_id == card_id, Squad.status == "certified")
                       .order_by(Squad.id.desc())).first()
        t = s.exec(select(SmokeTest).where(SmokeTest.card_id == card_id)).first()
        b = s.exec(select(Build).where(Build.smoke_id == t.id)).first()
        d = Path(squad.folder)
        d.mkdir(parents=True, exist_ok=True)
        (d / ".gitignore").write_text(GITIGNORE)
        (d / "README.md").write_text(f"# {t.name}\n\nBuilt from CLAUDE.md by a Claude Code session. "
                                     "The certified squad's instructions are in squad/.\n")
        if not (d / ".git").exists():
            subprocess.run(["git", "init", "-q", str(d)], check=False)
        v = s.exec(select(Venture).where(Venture.slug == t.slug)).first() or Venture(
            slug=t.slug, name=t.name, price_label=t.price_label, build_id=b.id if b else None)
        squad.status, squad.launched_at = "launched", utcnow()
        card.status = "building"
        if b:
            b.status = "launched"
            s.add(b)
        s.add(v)
        s.add(squad)
        s.add(card)
        s.commit()
    lines, total = shopping_list(card_id)
    items = "\n".join(f"- {x[0]}: R{x[1]:,.0f}" for x in lines) or "- (no capital lines in the Dossier)"
    return {"ok": True, "message": (
        f"Launch approved for {t.name}. Nothing is bought automatically. Your shopping list (R{total:,.0f}):\n"
        f"{items}\nThen start the build: cd {d} && claude \"Read CLAUDE.md and build it.\"\n"
        "The certified squad's instructions are in squad/; Operations runs them from Phase 5.")}

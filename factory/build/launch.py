"""Scaffold a sibling venture folder from its spec and hand off to a human-started
Claude Code session. Creates the Venture row (status: building).
"""
from __future__ import annotations

import subprocess

from sqlmodel import select

from factory.models import Build, SmokeTest, Venture, session

GITIGNORE = ".env\n.venv/\n__pycache__/\ndata/\n"


def scaffold(b: Build) -> Venture:
    from pathlib import Path
    d = Path(b.spec_path).parent
    (d / ".gitignore").write_text(GITIGNORE)
    (d / "README.md").write_text(f"# {b.slug}\n\nBuilt from CLAUDE.md by a Claude Code session.\n")
    if not (d / ".git").exists():
        subprocess.run(["git", "init", "-q", str(d)], check=False)
    with session() as s:
        t = s.get(SmokeTest, b.smoke_id)
        v = s.exec(select(Venture).where(Venture.slug == b.slug)).first() or Venture(
            slug=b.slug, name=t.name, price_label=t.price_label, build_id=b.id)
        s.add(v)
        bb = s.get(Build, b.id)
        bb.status = "launched"
        s.add(bb)
        s.commit()
    print(f"  Venture '{v.name}' scaffolded at {d}\n"
          f"  Hand-off (you start it): cd {d} && claude \"Read CLAUDE.md and build it.\"")
    return v

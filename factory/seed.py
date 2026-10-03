"""Load config/niches.yaml into Niche rows. Only the first `niche_limit` are active."""
from __future__ import annotations

import json

from sqlmodel import select

from factory import config
from factory.models import Niche, session


def seed(limit: int | None = None) -> list[Niche]:
    limit = limit if limit is not None else int(config.settings()["niche_limit"])
    rows = config.niches_config()
    out = []
    with session() as s:
        for i, n in enumerate(rows):
            niche = s.exec(select(Niche).where(Niche.slug == n["slug"])).first() or Niche(slug=n["slug"])
            niche.region = n.get("region", "GLOBAL")
            niche.keywords_json = json.dumps(n.get("keywords", []))
            niche.subreddits_json = json.dumps(n.get("subreddits", []))
            niche.competitors_json = json.dumps(n.get("competitors", []))
            niche.position = i
            niche.active = i < limit
            s.add(niche)
            out.append(niche)
        s.commit()
    return out


def active_niches() -> list[Niche]:
    with session() as s:
        return list(s.exec(select(Niche).where(Niche.active == True).order_by(Niche.position)))  # noqa: E712


if __name__ == "__main__":
    niches = seed()
    active = [n.slug for n in niches if n.active]
    print(f"Seeded {len(niches)} niches; {len(active)} active: {', '.join(active)}")

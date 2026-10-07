"""Load config/niches.yaml into Niche rows.

Active niches: `niche_limit` is either a number (the first N in the file) or
{commerce: N, other: M} (the first N commerce niches and the first M others).
"""
from __future__ import annotations

import json

from sqlmodel import select

from factory import config
from factory.models import Niche, session


def limits(limit: int | dict | None = None) -> dict:
    lim = limit if limit is not None else config.settings()["niche_limit"]
    return {k: int(v) for k, v in lim.items()} if isinstance(lim, dict) else {"all": int(lim)}


def seed(limit: int | dict | None = None) -> list[Niche]:
    lim, seen = limits(limit), {}
    rows = config.niches_config()
    out = []
    with session() as s:
        for i, n in enumerate(rows):
            kind = n.get("kind", "")
            bucket = "all" if "all" in lim else ("commerce" if kind == "commerce" else "other")
            niche = s.exec(select(Niche).where(Niche.slug == n["slug"])).first() or Niche(slug=n["slug"])
            niche.region = n.get("region", "GLOBAL")
            niche.keywords_json = json.dumps(n.get("keywords", []))
            niche.subreddits_json = json.dumps(n.get("subreddits", []))
            niche.competitors_json = json.dumps(n.get("competitors", []))
            niche.kind, niche.sources_json = kind, json.dumps(n.get("sources", []))
            niche.position = i
            niche.active = seen.get(bucket, 0) < lim.get(bucket, 0)
            seen[bucket] = seen.get(bucket, 0) + 1
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

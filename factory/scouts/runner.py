"""Run every active Niche through the enabled source adapters, then distill.

One Niche row = one scout. Usage: python -m factory.scouts.runner
"""
from __future__ import annotations

import logging
import math
import re
from datetime import timedelta

from sqlmodel import delete, select

from factory import agents, config, costs
from factory.models import Card, Niche, RunLog, Signal, session, tonight, utcnow
from factory.scouts import distill
from factory.scouts.sources import appstore, fiverr, hellopeter, hn, reddit, trends, upwork
from factory.scouts.sources.base import NotImplementedSource, RawSignal, SourceError
from factory.seed import active_niches, seed

log = logging.getLogger("factory.scouts")
ADAPTERS = {m.NAME: m for m in (reddit, hn, upwork, fiverr, appstore, hellopeter, trends)}
PRICE = re.compile(r"(\$|R|£|€)\s?\d|\d+\s?(/mo|per month|a month|/month|per year|/yr)|\bpay(ing)?\b", re.I)


def rank(sig: RawSignal, phrases: list[str] | None = None) -> float:
    text = f"{sig.title} {sig.text}"
    phrases = [p.lower() for p in (phrases if phrases is not None else config.pain_phrases())]
    pains = sum(1 for m in sig.matched if m.lower() in phrases)
    others = len(sig.matched) - pains
    money = 2.0 if PRICE.search(text) else 0.0
    return 3 * pains + others + money + math.log1p(max(sig.score, 0)) + 0.5 * math.log1p(sig.replies)


def purge_old_signals() -> int:
    cutoff = utcnow() - timedelta(days=int(config.settings()["retention_days"]))
    with session() as s:
        used = select(Card.signal_id).where(Card.signal_id.is_not(None))
        res = s.exec(delete(Signal).where(Signal.fetched_at < cutoff, Signal.id.not_in(used)))
        s.commit()
        return res.rowcount or 0


def store(niche: Niche, raws: list[RawSignal]) -> int:
    new, phrases = 0, config.phrases_for(niche)
    with session() as s:
        for r in raws:
            existing = s.exec(select(Signal).where(Signal.niche_id == niche.id,
                                                   Signal.external_id == r.external_id)).first()
            if existing:
                existing.score, existing.replies, existing.rank = r.score, r.replies, rank(r, phrases)
                existing.fetched_at = utcnow()
                s.add(existing)
                continue
            s.add(Signal(niche_id=niche.id, source=r.source, external_id=r.external_id, url=r.url,
                         title=r.title[:500], text=r.text[:6000], score=r.score, replies=r.replies,
                         rank=rank(r, phrases), posted_at=r.posted_at))
            new += 1
        s.commit()
    return new


def fetch_source(niche: Niche, name: str, job) -> int:
    """One source for one niche, inside an AgentRun. Returns new signals stored."""
    try:
        raws = ADAPTERS[name].fetch(niche)
        relevant = [r for r in raws if r.matched]
        n = store(niche, relevant)
        job.summary = f"{len(raws)} fetched, {len(relevant)} relevant, {n} new"
        return n
    except NotImplementedSource as e:
        job.status, job.summary = "skipped", f"TODO: {e}"
    except SourceError as e:
        job.status, job.summary = "failed", f"FAILED: {e}"
        log.warning("source %s failed for %s: %s", name, niche.slug, e)
    return 0


def distill_job(niche: Niche) -> list[Card]:
    with agents.run("research", "Distiller", subject=niche.slug) as job:
        cards = distill.distill_niche(niche)
        job.summary = f"{len(cards)} cards ({distill.last_note.get(niche.slug, '')})"
        if not cards and "skipped" in distill.last_note.get(niche.slug, ""):
            job.status = "skipped"
    return cards


def scout_niche(niche: Niche) -> dict:
    from factory.warden import holds
    enabled = [k for k, v in config.settings()["sources"].items() if v and (not niche.sources or k in niche.sources)]
    held = holds.active()
    report = {"niche": niche.slug, "sources": {}, "new_signals": 0, "cards": []}
    for name in enabled:
        with agents.run("research", f"{name} scout", subject=niche.slug) as job:
            if name in held:
                job.status = "skipped"
                job.summary = f"paused by the Warden until {holds.local(held[name].until)}: {held[name].reason}"
            else:
                report["new_signals"] += fetch_source(niche, name, job)
            report["sources"][name] = job.summary
    report["cards"] = distill_job(niche)
    return report


def print_card(c: Card) -> None:
    pay = f"{c.pay_currency}{c.pay_amount:g}" if c.pay_amount is not None else "-"
    print(f"    #{c.id:<4} {c.title}")
    print(f"          problem: {c.problem}")
    print(f"          quote:   \"{c.quote[:220]}{'...' if len(c.quote) > 220 else ''}\"")
    print(f"          pay:     {c.pay_evidence or '-'}  (amount: {pay})")
    print(f"          model:   {c.business_model or '-'} ({c.lane or 'no lane'})")
    print(f"          source:  {c.source}  {c.url}")


def run() -> list[dict]:
    log.info("scout run starting")
    seed()
    purged = purge_old_signals()
    niches = active_niches()
    print(f"Scouting {len(niches)} niches (sources: "
          f"{', '.join(k for k, v in config.settings()['sources'].items() if v)}); purged {purged} old signals")
    run_row = RunLog(stage="scout")
    reports = []
    with costs.stage("scout"):
        for niche in niches:
            print(f"\n== scout: {niche.slug} ({niche.region})")
            try:
                rep = scout_niche(niche)
            except costs.StageOverBudget as e:
                print(f"  STOPPED: {e}")
                run_row.ok, run_row.summary = False, str(e)
                break
            for src, msg in rep["sources"].items():
                print(f"  {src:<10} {msg}")
            if rep["cards"]:
                print(f"  cards ({len(rep['cards'])}):")
                for c in rep["cards"]:
                    print_card(c)
            else:
                print(f"  cards: none ({rep.get('note') or distill.last_note.get(niche.slug, 'no evidence')})")
            reports.append(rep)
    total_cards = sum(len(r["cards"]) for r in reports)
    failed = {}
    for r in reports:
        for src, msg in r["sources"].items():
            if msg.startswith("FAILED"):
                failed[src] = failed.get(src, 0) + 1
    fail_txt = "".join(f", {src} failed in {n}/{len(reports)} niches" for src, n in failed.items())
    run_row.summary = run_row.summary or f"{len(reports)} niches, {total_cards} cards{fail_txt}"
    run_row.finished_at = utcnow()
    with session() as s:
        s.add(run_row)
        s.commit()
    print(f"\nScout night {tonight()}: {total_cards} cards from {len(reports)} niches")
    costs.print_nightly_total()
    return reports


if __name__ == "__main__":
    config.setup_logging()
    run()

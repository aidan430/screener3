"""Prepare smoke tests for every card that passed both gates; settle running ones.

Each prepared test ends at status `awaiting_funding` and prints the manual
steps. Nothing is spent until /api/approve/{id} is hit from the dashboard.
Usage: python -m factory.smoke.run
"""
from __future__ import annotations

import json
import logging

from sqlmodel import select

from factory import agents, config, costs
from factory.gates.common import cards_with_status
from factory.models import Card, Dossier, RunLog, SmokeTest, session, utcnow
from factory.smoke import ads, deploy, page, track

log = logging.getLogger("factory.smoke")


def unique_slug(base: str) -> str:
    slug, i = base, 2
    with session() as s:
        while s.exec(select(SmokeTest).where(SmokeTest.slug == slug)).first():
            slug, i = f"{base}-{i}", i + 1
    return slug


SYMBOL = {"USD": "$", "GBP": "£", "EUR": "€", "ZAR": "R", "AUD": "A$", "CAD": "C$"}


def dossier_for(card_id: int) -> Dossier | None:
    with session() as s:
        return s.exec(select(Dossier).where(Dossier.card_id == card_id).order_by(Dossier.id.desc())).first()


def price_label(d: Dossier | None) -> str:
    if not d or not d.price_point:
        return ""
    unit = {"per month": " / month", "per year": " / year"}.get(d.price_unit, "")
    return f"{SYMBOL.get(d.currency, d.currency + ' ')}{d.price_point:g}{unit}"


def prepare(card: Card) -> SmokeTest:
    dossier = dossier_for(card.id)
    d = page.draft(card, price_label(dossier))
    slug = unique_slug(page.slugify(d.product_name))
    vercel = bool(config.env("VERCEL_TOKEN") and config.env("FACTORY_DOMAIN"))
    path = deploy.write_local(slug, page.render(d, slug, api_base=None if vercel else ""))
    target, url = deploy.deploy(slug)
    ad_json = ads.ad_set(d, url, slug)
    steps = ads.manual_steps(ad_json)
    if dossier and dossier.capital_zar:
        steps += (f"\nIf this test wins, the full start-up needs about R{dossier.capital_zar:,.0f} "
                  f"(break-even after {dossier.break_even_sales or '?'} sales). That is a separate approval.")
    if target == "local":
        steps += ("\nNOTE: page is only on localhost. Set FACTORY_DOMAIN + VERCEL_TOKEN and re-run "
                  "`make smoke` before funding, or ads will point nowhere.")
    t = SmokeTest(card_id=card.id, slug=slug, name=d.product_name, headline=d.headline,
                  price_label=d.price_label, page_path=path, url=url, deploy_target=target,
                  ads_json=json.dumps(ad_json), manual_steps=steps, status="awaiting_funding")
    with session() as s:
        s.add(t)
        c = s.get(Card, card.id)
        c.status = "awaiting_funding"
        s.add(c)
        s.commit()
    return t


def approve(smoke_id: int) -> dict:
    """The human clicked FUND TEST. Only now may ads launch."""
    with session() as s:
        t = s.get(SmokeTest, smoke_id)
        if not t:
            return {"ok": False, "message": f"No smoke test {smoke_id}"}
        if t.status != "awaiting_funding":
            return {"ok": False, "message": f"{t.name} is already {t.status}"}
        mode = ads.launch_if_enabled(json.loads(t.ads_json))
        t.status, t.approved_at = "approved", utcnow()
        card = s.get(Card, t.card_id)
        card.status = "testing"
        s.add(t)
        s.add(card)
        s.commit()
    if mode == "manual":
        print(t.manual_steps)
        return {"ok": True, "message": "Approved. Meta ads are off, so launch it by hand:\n" + t.manual_steps}
    return {"ok": True, "message": "Approved. Campaign created; results in 48h."}


def run() -> list[SmokeTest]:
    row = RunLog(stage="smoke")
    cards = cards_with_status("dive_passed")
    print(f"\n== Smoke: {len(cards)} card(s) passed the Deep Dive")
    made = []
    with costs.stage("smoke"):
        for card in cards:
            try:
                with agents.run("ops", "Smoke-test builder", subject=card.title, card=card, tower=4) as job:
                    t = prepare(card)
                    job.summary = f"{t.name} at {t.price_label}: page {t.deploy_target}, waiting for your R200"
            except (costs.StageOverBudget, costs.NoApiKey) as e:
                print(f"  STOPPED: {e}")
                row.ok, row.summary = False, str(e)
                break
            except Exception as e:
                log.exception("smoke prepare failed for card %s", card.id)
                print(f"  [ERR] #{card.id} {card.title}: {e}")
                continue
            made.append(t)
            print(f"  #{t.id} {t.name} ({t.price_label}) -> {t.status}  {t.url}")
            print("    " + t.manual_steps.replace("\n", "\n    "))
    settled = track.refresh()
    for t in settled:
        print(f"  settled: {t.name} {t.status} ({t.buy_clicks}/{t.visitors} buy-clicks)")
    row.summary = row.summary or f"{len(made)} prepared, {len(settled)} settled"
    row.finished_at = utcnow()
    with session() as s:
        s.add(row)
        s.commit()
    return made


if __name__ == "__main__":
    config.setup_logging()
    run()
    costs.print_nightly_total()

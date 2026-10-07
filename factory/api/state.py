"""Builds the JSON the dashboard consumes (contract in CLAUDE.md -> Dashboard contract).

Phase 1 keys stay; Phase 2 adds agents_total, departments, arena, niches, dossiers.
"""
from __future__ import annotations

import json
from datetime import timedelta

from sqlmodel import func, select

from factory import agents, config, costs
from factory.api import arena as arena_mod
from factory.api import panels
from factory.models import Card, Cost, Dossier, Niche, RunLog, SmokeTest, Venture, session, tonight, utcnow


def _night(s) -> str:
    row = s.exec(select(RunLog).where(RunLog.stage == "scout").order_by(RunLog.id.desc())).first()
    return row.night if row else tonight()


def side_quests(s) -> list[str]:
    q = []
    need = [("ANTHROPIC_API_KEY", "Add ANTHROPIC_API_KEY to .env (no agent can think without it)."),
            ("REDDIT_CLIENT_ID", "Create a Reddit script app and add REDDIT_CLIENT_ID/SECRET (10 min)."),
            ("ETSY_API_KEY", "Create an Etsy developer app and add ETSY_API_KEY (10 min)."),
            ("EBAY_CLIENT_ID", "Create an eBay developer app and add EBAY_CLIENT_ID/SECRET (10 min)."),
            ("FACTORY_DOMAIN", "Buy the factory domain and set FACTORY_DOMAIN (15 min)."),
            ("VERCEL_TOKEN", "Create the Vercel project + token, add VERCEL_TOKEN (10 min)."),
            ("PLAUSIBLE_API_KEY", "Open a Plausible account, add PLAUSIBLE_API_KEY (10 min)."),
            ("META_ACCESS_TOKEN", "Create the Meta developer app + ad account (20 min, needs your ID)."),
            ("PAYSTACK_SECRET_KEY", "Paystack KYC and webhook secret for the first venture (15 min).")]
    q += [text for key, text in need if not config.env(key)]
    for t in s.exec(select(SmokeTest).where(SmokeTest.status == "awaiting_funding")):
        q.append(f"Fund the {t.name} smoke test (R{config.settings()['smoke']['budget_zar']}).")
    return q


def treasury(s) -> tuple[list[dict], float, float]:
    rows = []
    for v in s.exec(select(Venture)):
        days = max(1, (utcnow() - agents._aware(v.live_at or v.started_at)).days)
        if v.status == "building":
            rows.append({"name": v.name, "sub": "under construction", "projected_30d": None,
                         "label": "unknown", "kind": "soon"})
        else:
            earned = v.revenue_collected + v.revenue_uncollected
            rows.append({"name": v.name, "sub": f"{v.status}, {days} days",
                         "projected_30d": round(earned / days * 30), "kind": "income"})
    for t in s.exec(select(SmokeTest).where(SmokeTest.status.in_(["awaiting_funding", "approved"]))):
        rows.append({"name": t.name, "sub": "smoke test, waiting on your R200" if t.status == "awaiting_funding"
                     else "smoke test running", "projected_30d": None, "label": "unknown", "kind": "soon"})
    week = costs.total_zar(since=utcnow() - timedelta(days=7))
    rows.append({"name": "Elixir (agent spend)", "sub": "every agent's API bill, last 7 days x 30/7",
                 "projected_30d": -round(week * 30 / 7, 2), "kind": "cost"})
    funded = s.exec(select(func.count()).select_from(SmokeTest).where(
        SmokeTest.approved_at >= utcnow() - timedelta(days=30))).one()
    rows.append({"name": "Ads and hosting", "sub": f"{funded} funded smoke tests, 30 days",
                 "projected_30d": -float(funded * config.settings()["smoke"]["budget_zar"]), "kind": "cost"})
    biggest = max([abs(r["projected_30d"] or 0) for r in rows] + [1])
    for r in rows:
        r["pct"] = (round(100 * abs(r["projected_30d"]) / biggest) if r["projected_30d"]
                    else (6 if r["kind"] == "soon" else 0))
    income = [r["projected_30d"] for r in rows if r["kind"] == "income"]
    net = sum(r["projected_30d"] or 0 for r in rows if r["kind"] in ("income", "cost"))
    conc = round(100 * max(income) / sum(income)) if income and sum(income) > 0 else 0
    return rows, round(net, 2), conc


def _latest_dossiers(s) -> dict[int, Dossier]:
    return {d.card_id: d for d in s.exec(select(Dossier).order_by(Dossier.id))}


def niches(s) -> list[dict]:
    """Every niche that reached a smoke test: what it earned and cost so far (rand)."""
    doss, bm, out = _latest_dossiers(s), config.business_models()["models"], []
    stage = {"awaiting_funding": "waiting for your R200", "approved": "smoke test running",
             "won": "won its smoke test", "lost": "lost its smoke test"}
    for t in s.exec(select(SmokeTest)):
        c = s.get(Card, t.card_id)
        v = s.exec(select(Venture).where(Venture.slug == t.slug)).first()
        revenue = (v.revenue_collected + v.revenue_uncollected) if v else 0.0
        agent = s.exec(select(func.coalesce(func.sum(Cost.zar), 0.0)).where(Cost.card_id == c.id)).one()
        spent = float(agent) + (float(config.settings()["smoke"]["budget_zar"]) if t.approved_at else 0.0)
        d = doss.get(c.id)
        out.append({"name": t.name, "card_id": c.id, "lane": c.lane or arena_mod.LANE_FALLBACK,
                    "model": bm.get(c.business_model, {}).get("label", "Unknown"),
                    "stage": v.status if v else stage.get(t.status, t.status), "revenue": round(revenue, 2),
                    "costs": round(spent, 2), "profit": round(revenue - spent, 2),
                    "capital": d.capital_zar if d else None})
    return out


def dossiers(s, limit: int = 8) -> list[dict]:
    bm, out = config.business_models()["models"], []
    rows = s.exec(select(Dossier, Card).join(Card, Card.id == Dossier.card_id)
                  .where(Dossier.verdict == "pass").order_by(Dossier.id.desc()).limit(limit))
    for d, c in rows:
        out.append({"card_id": c.id, "title": c.title, "status": c.status, "lane": d.lane,
                    "model": bm.get(d.business_model, {}).get("label", d.business_model),
                    "price": d.price_point, "currency": d.currency, "price_unit": d.price_unit,
                    "price_zar": d.price_zar, "capital": d.capital_zar, "lines": d.j("capital_lines"),
                    "break_even": d.break_even_sales, "margin": d.margin, "score": d.score,
                    "demand_score": d.demand_score, "competition_score": d.competition_score,
                    "unit_cost_basis": d.unit_cost_basis, "reasoning": d.reasoning[:400], "url": c.url})
    return out


def build_state() -> dict:
    month_start = utcnow().replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    elixir = costs.total_zar(since=month_start)
    depts = agents.departments()
    with session() as s:
        night = _night(s)
        arena = arena_mod.arena_json(s, night)
        quests = side_quests(s)
        rows, net, conc = treasury(s)
        gold = float(s.exec(select(func.coalesce(func.sum(Venture.revenue_collected), 0.0))).one())
        blds = (panels.bases(s, arena, quests, gold, elixir) + panels.camps(s, depts)
                + panels.tower_panels(arena) + [panels.archive(s, night)])
        research = next(b for b in blds if b["id"] == "research")
        research["desc"] += f" Live sources: {panels.sources_line()}. {panels.last_scout(s)}"
        niche_rows, doss = niches(s), dossiers(s)
        scouts = s.exec(select(func.count()).select_from(Niche).where(Niche.active == True)).one()  # noqa: E712
        cards = [{"id": c.id, "title": c.title, "status": c.status, "lane": c.lane, "url": c.url}
                 for c in s.exec(select(Card).where(Card.night == night).order_by(Card.id))]
    total = sum(d["agents"] for d in depts)
    working = sum(d["working"] for d in depts)
    foot = (f"Night {night}: {len(cards)} card{'' if len(cards) == 1 else 's'} scouted. "
            f"Agent spend this month {panels._r(elixir)}. "
            + (f"Top earner is {conc}% of your gold." if conc else "No gold mines yet; every figure here is real."))
    return {"gold": round(gold), "elixir_month": round(elixir, 2), "scouts_active": scouts,
            "agents_total": total, "agents_working": working, "departments": depts,
            "buildings": blds, "arena": arena, "treasury": rows, "net_30d": net, "concentration_pct": conc,
            "side_quests": quests, "niches": niche_rows, "dossiers": doss,
            "builders": f"{working} of {total} agents working", "night": night,
            "generated_at": utcnow().isoformat(), "foot": foot, "cards": cards}


def snapshot() -> dict:
    st = build_state()
    config.DATA_DIR.mkdir(exist_ok=True)
    (config.DATA_DIR / "state.json").write_text(json.dumps(st, indent=2, default=str))
    return st

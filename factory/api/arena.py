"""Arena JSON for the MOBA dashboard: lanes, towers, niche units, mines, agent runs.

Card statuses place units at towers; AgentRun rows are the only source of agent
movement. Nothing here is simulated.
"""
from __future__ import annotations

import re
from datetime import timedelta

from sqlmodel import func, select

from factory import agents, config
from factory.models import Build, Card, Dossier, GateResult, SmokeTest, Venture, utcnow

TOWERS = [  # n, id, name, side, owner, rule
    (1, "proof", "Gate of Proof", "free", "research", "Someone already pays for this: a priced job, a paid competitor with complaints, or a forum request to pay."),
    (2, "craft", "Gate of Craft", "free", "research", "One founder with agents can build it in 7 days: no sales calls, no own stock, no licence, no human support."),
    (3, "economics", "Economics gate", "free", "dive", "Deep Dive score 7+, margin above the model's minimum, start-up capital under your cap, break-even in 80 sales or fewer."),
    (4, "fund", "Fund test", "money", "you", "You approve the smoke-test budget (R200). Nothing is spent before your click."),
    (5, "smoke", "Smoke test", "money", "ops", "5%+ of 150+ visitors click Buy within 48 hours."),
    (6, "launch", "Certify & fund launch", "money", "train", "Training writes the venture brief; you approve the rest of the start-up capital."),
]
PLACE = {"scouted": (1, "waiting"), "proof_passed": (2, "waiting"), "craft_passed": (3, "waiting"),
         "dive_passed": (4, "waiting"), "awaiting_funding": (4, "blocked"), "testing": (5, "testing"),
         "won": (6, "blocked"), "killed_proof": (1, "dead"), "killed_craft": (2, "dead"),
         "killed_dive": (3, "dead"), "archived": (5, "dead")}
LANE_FALLBACK = "commerce"  # mid lane until a business model is known


def iso(dt) -> str | None:
    return agents._aware(dt).isoformat() if dt else None


def short(title: str) -> str:
    words = [w for w in re.split(r"[^A-Za-z0-9]+", title) if w]
    if not words:
        return "?"
    return (words[0][0] + (words[1][0] if len(words) > 1 else words[0][1:2])).upper()


def lanes() -> list[dict]:
    bm = config.business_models()
    return [{"id": ln["id"], "name": ln["name"], "position": ln["position"],
             "models": [bm["models"][m]["label"] for m in ln["models"]]} for ln in bm["lanes"]]


def units(s, night: str) -> list[dict]:
    smoke = {t.card_id: t for t in s.exec(select(SmokeTest))}
    doss = {d.card_id: d for d in s.exec(select(Dossier).order_by(Dossier.id))}
    budget = config.settings()["smoke"]["budget_zar"]
    out = []
    for c in s.exec(select(Card).where(Card.status.in_(list(PLACE))).order_by(Card.id)):
        tower, state = PLACE[c.status]
        if state == "dead" and c.night != night:
            continue
        u = {"card_id": c.id, "title": c.title, "short": short(c.title), "lane": c.lane or LANE_FALLBACK,
             "lane_guessed": not c.lane, "tower": tower, "state": state, "status": c.status,
             "model": c.business_model, "url": c.url, "actions": []}
        t = smoke.get(c.id)
        if t:
            u["smoke"] = {"name": t.name, "price": t.price_label, "url": t.url, "visitors": t.visitors,
                          "buy_clicks": t.buy_clicks}
            if c.status == "awaiting_funding":
                u["actions"] = [{"label": f"FUND TEST R{budget}", "endpoint": f"/api/approve/{t.id}", "style": "spend"}]
        d = doss.get(c.id)
        if d:
            u["dossier"] = {"capital": d.capital_zar, "break_even": d.break_even_sales, "margin": d.margin,
                            "score": d.score, "verdict": d.verdict}
        out.append(u)
    return out


def towers(s, unit_list: list[dict]) -> list[dict]:
    week = utcnow() - timedelta(days=7)
    gate = {(g, v): n for g, v, n in s.exec(
        select(GateResult.gate, GateResult.verdict, func.count()).where(GateResult.created_at >= week)
        .group_by(GateResult.gate, GateResult.verdict))}
    st = {k: n for k, n in s.exec(select(SmokeTest.status, func.count()).where(SmokeTest.created_at >= week)
                                    .group_by(SmokeTest.status))}
    approved = s.exec(select(func.count()).select_from(SmokeTest).where(SmokeTest.approved_at >= week)).one()
    built = s.exec(select(func.count()).select_from(Build).where(Build.created_at >= week)).one()
    stats = {1: (gate.get(("proof", "pass"), 0), gate.get(("proof", "kill"), 0)),
             2: (gate.get(("craft", "pass"), 0), gate.get(("craft", "kill"), 0)),
             3: (gate.get(("economics", "pass"), 0), gate.get(("economics", "kill"), 0)),
             4: (approved, 0), 5: (st.get("won", 0), st.get("lost", 0)), 6: (built, 0)}
    out = []
    for n, tid, name, side, owner, rule in TOWERS:
        waiting = sum(1 for u in unit_list if u["tower"] == n and u["state"] != "dead")
        out.append({"n": n, "id": tid, "name": name, "side": side, "owner": owner, "rule": rule,
                    "waiting": waiting, "passed_7d": stats[n][0], "killed_7d": stats[n][1]})
    return out


def mines(s) -> list[dict]:
    lane_by_slug = {}
    for t in s.exec(select(SmokeTest)):
        c = s.get(Card, t.card_id)
        lane_by_slug[t.slug] = (c.lane if c else "") or LANE_FALLBACK
    out = []
    for v in s.exec(select(Venture)):
        acts = ([{"label": f"COLLECT R{v.revenue_uncollected:,.0f}", "endpoint": f"/api/collect/{v.id}", "style": "gold"}]
                if v.revenue_uncollected > 0 else [])
        out.append({"venture_id": v.id, "name": v.name, "lane": lane_by_slug.get(v.slug, LANE_FALLBACK),
                    "status": v.status, "revenue": v.revenue_collected + v.revenue_uncollected,
                    "uncollected": v.revenue_uncollected, "price": v.price_label, "actions": acts})
    return out


def runs() -> list[dict]:
    return [{"id": r.id, "dept": r.dept, "role": r.role, "subject": r.subject, "lane": r.lane,
             "tower": r.tower, "card_id": r.card_id, "started": iso(r.started_at), "finished": iso(r.finished_at),
             "status": agents.effective_status(r), "summary": r.summary, "cost": r.cost_zar}
            for r in agents.recent(hours=36, limit=400)]


def arena_json(s, night: str) -> dict:
    unit_list = units(s, night)
    return {"lanes": lanes(), "towers": towers(s, unit_list), "units": unit_list, "mines": mines(s),
            "runs": runs()}

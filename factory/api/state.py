"""Builds the JSON the dashboard consumes (contract in CLAUDE.md -> Dashboard contract).

Extra keys beyond the contract (builders, night, generated_at, foot, cards)
are optional hints the dashboard uses if present.
"""
from __future__ import annotations

import json
from datetime import datetime, timedelta

from sqlmodel import func, select

from factory import config, costs
from factory.models import (Card, GateResult, Niche, RunLog, Signal, SmokeTest, Venture, session,
                            tonight, utcnow)

BUILDERS = 3


def _r(x: float) -> str:
    return f"R{x:,.0f}" if abs(x) >= 10 else f"R{x:,.2f}"


def _night_of_last_run(s) -> str:
    row = s.exec(select(RunLog).where(RunLog.stage == "scout").order_by(RunLog.id.desc())).first()
    return row.night if row else tonight()


def _gate_building(s, gate: str, night: str, gid: str, gx_name: str, desc: str) -> dict:
    results = list(s.exec(select(GateResult, Card).join(Card, Card.id == GateResult.card_id)
                          .where(GateResult.gate == gate, Card.night == night).order_by(GateResult.score.desc())))
    killed = [(g, c) for g, c in results if g.verdict == "kill"]
    passed = [(g, c) for g, c in results if g.verdict == "pass"]
    waiting_status = "scouted" if gate == "proof" else "proof_passed"
    waiting = list(s.exec(select(Card).where(Card.status == waiting_status)))
    elixir = costs.total_zar(night=night, stage_name=gate)
    lines = [desc]
    if passed:
        lines.append("Passed: " + "; ".join(f"{c.title} ({g.score}/10)" for g, c in passed[:4]) + ".")
    if killed:
        lines.append("Killed: " + "; ".join(f"{c.title} ({g.score}/10)" for g, c in killed[:4]) + ".")
    if waiting:
        lines.append("Waiting at the gate: " + "; ".join(c.title for c in waiting[:4]) + ".")
    total = len(results)
    rate = f"{round(100 * len(killed) / total)}%" if total else "-"
    return {"id": gid, "kind": "gate", "name": gx_name, "level": len(waiting),
            "lvl": f"Defence, {len(waiting)} waiting" if waiting else "Defence",
            "desc": " ".join(lines),
            "kv": [[str(len(killed)), "killed last night"], [str(len(passed)), "passed"],
                   [_r(elixir), "elixir a night"] if gate == "craft" else [rate, "kill rate"]],
            "actions": [], "pile": 0, "rate": 0}


def buildings(s, night: str) -> list[dict]:
    out = []
    niches = list(s.exec(select(Niche).where(Niche.active == True)))  # noqa: E712
    cards_night = list(s.exec(select(Card).where(Card.night == night)))
    signals = s.exec(select(func.count()).select_from(Signal)).one()
    scout_r = costs.total_zar(night=night, stage_name="scout")
    last_scout = s.exec(select(RunLog).where(RunLog.stage == "scout").order_by(RunLog.id.desc())).first()
    srcs = ", ".join(k for k, v in config.settings()["sources"].items() if v)
    camp_desc = (f"One scout per niche ({', '.join(n.slug for n in niches)}). Live sources: {srcs}. ")
    if last_scout:
        camp_desc += f"Last run {last_scout.night}: {last_scout.summary}."
    else:
        camp_desc += "No scouting run yet: run `make scout`."
    if cards_night:
        camp_desc += " Cards: " + "; ".join(c.title for c in cards_night[:5]) + (
            f" and {len(cards_night) - 5} more." if len(cards_night) > 5 else ".")
    out.append({"id": "camp", "kind": "camp", "name": "Scout Camp", "level": len(niches),
                "lvl": f"{len(niches)} scouts", "desc": camp_desc,
                "kv": [[str(len(cards_night)), "cards last night"], [_r(scout_r), "elixir a night"],
                       [str(signals), "signals, 30 days"]],
                "actions": [{"label": "TRAIN MORE SCOUTS", "endpoint": "#msg", "style": "grey",
                             "msg": f"Capped at {config.settings()['niche_limit']} niches for the first run. "
                                    "Raise niche_limit in config/settings.yaml when you are ready."}],
                "pile": 0, "rate": 0})
    out.append(_gate_building(s, "proof", night, "gate1", "Gate of Proof",
                              "Kills any idea with no evidence that someone already pays for it."))
    out.append(_gate_building(s, "craft", night, "gate2", "Gate of Craft",
                              "Kills anything that needs sales calls, stock, licences, or more than a week to build."))
    buried = list(s.exec(select(Card).where(Card.status.in_(["killed_proof", "killed_craft", "archived"]))
                         .order_by(Card.id.desc())))
    out.append({"id": "archive", "kind": "archive", "name": "The Archive", "level": len(buried),
                "lvl": "Graveyard",
                "desc": "Every slain idea with its evidence, never deleted." + (
                    " Latest: " + "; ".join(c.title for c in buried[:3]) + "." if buried else ""),
                "kv": [[str(len(buried)), "buried"], ["0", "revived"], ["R0", "cost"]],
                "actions": [], "pile": 0, "rate": 0})
    for t in s.exec(select(SmokeTest).where(SmokeTest.status.in_(["awaiting_funding", "approved"]))):
        sm = config.settings()["smoke"]
        if t.status == "awaiting_funding":
            kv = [[_r(sm["budget_zar"]), "test cost"], ["5%", "target"], [f"{sm['duration_hours']}h", "duration"]]
            acts = [{"label": f"FUND TEST {_r(sm['budget_zar'])}", "endpoint": f"/api/approve/{t.id}", "style": "spend"}]
            lvl = "Smoke test ready"
        else:
            rate = f"{100 * t.buy_clicks / t.visitors:.1f}%" if t.visitors else "-"
            kv = [[str(t.visitors), "visitors"], [str(t.buy_clicks), "buy-clicks"], [rate, "rate"]]
            acts, lvl = [], "Smoke test running"
        out.append({"id": f"test{t.id}", "kind": "test", "name": t.name, "level": 1, "lvl": lvl,
                    "desc": f"{t.headline} {t.price_label}. Page: {t.url}. "
                            "Nothing happens until you fund the test.",
                    "kv": kv, "actions": acts, "pile": 0, "rate": 0})
    for v in s.exec(select(Venture)):
        days = max(1, (utcnow() - (v.live_at or v.started_at)).days)
        if v.status == "building":
            out.append({"id": f"v{v.id}", "kind": "site", "name": v.name, "level": 0, "lvl": "Under construction",
                        "desc": f"Spec written; waiting on a Claude Code session you start. Price {v.price_label}.",
                        "kv": [[str(days) + "d", "since spec"], [v.price_label or "-", "price"], ["R0", "earned"]],
                        "actions": [], "pile": 0, "rate": 0})
        else:
            earned = v.revenue_collected + v.revenue_uncollected
            pile = 0 if v.revenue_uncollected <= 0 else min(3, 1 + int(v.revenue_uncollected // 1000))
            out.append({"id": f"v{v.id}", "kind": "mine", "name": v.name, "level": 1 + int(earned // 10000),
                        "lvl": f"Gold Mine, {v.status}",
                        "desc": f"Sells {v.price_label}. Live {days} days.",
                        "kv": [[_r(earned / days), "per day"], [_r(earned), "all time"],
                               [_r(v.revenue_uncollected), "uncollected"]],
                        "actions": [{"label": f"COLLECT {_r(v.revenue_uncollected)}",
                                     "endpoint": f"/api/collect/{v.id}", "style": "gold"}]
                        if v.revenue_uncollected > 0 else [],
                        "pile": pile, "rate": min(1.0, earned / days / 1000),
                        "float": "+" + (v.price_label.split(" ")[0] if v.price_label else "R")})
    return out


def side_quests(s) -> list[str]:
    q = []
    need = [("ANTHROPIC_API_KEY", "Add ANTHROPIC_API_KEY to .env (scouts and gates cannot think without it)."),
            ("REDDIT_CLIENT_ID", "Create a Reddit script app and add REDDIT_CLIENT_ID/SECRET (10 min)."),
            ("FACTORY_DOMAIN", "Buy the factory domain and set FACTORY_DOMAIN (15 min)."),
            ("VERCEL_TOKEN", "Create the Vercel project + token, add VERCEL_TOKEN (10 min)."),
            ("PLAUSIBLE_API_KEY", "Open a Plausible account, add PLAUSIBLE_API_KEY (10 min)."),
            ("META_ACCESS_TOKEN", "Create the Meta developer app + ad account (20 min, needs your ID)."),
            ("PAYSTACK_SECRET_KEY", "Paystack KYC and webhook secret for the first venture (15 min).")]
    for key, text in need:
        if not config.env(key):
            q.append(text)
    for t in s.exec(select(SmokeTest).where(SmokeTest.status == "awaiting_funding")):
        q.append(f"Fund the {t.name} smoke test (R{config.settings()['smoke']['budget_zar']}).")
    return q


def treasury(s) -> tuple[list[dict], float, float]:
    rows = []
    for v in s.exec(select(Venture)):
        days = max(1, (utcnow() - (v.live_at or v.started_at)).days)
        if v.status == "building":
            rows.append({"name": v.name, "sub": "under construction", "projected_30d": None,
                         "label": "unknown", "kind": "soon"})
        else:
            earned = v.revenue_collected + v.revenue_uncollected
            rows.append({"name": v.name, "sub": f"{v.status}, {days} days", "projected_30d": round(earned / days * 30),
                         "kind": "income"})
    for t in s.exec(select(SmokeTest).where(SmokeTest.status.in_(["awaiting_funding", "approved"]))):
        rows.append({"name": t.name, "sub": "smoke test, waiting on your R200" if t.status == "awaiting_funding"
                     else "smoke test running", "projected_30d": None, "label": "unknown", "kind": "soon"})
    week = costs.total_zar(since=utcnow() - timedelta(days=7))
    rows.append({"name": "Elixir (API spend)", "sub": "scouts and gatekeepers, last 7 days x 30/7",
                 "projected_30d": -round(week * 30 / 7, 2), "kind": "cost"})
    funded = s.exec(select(func.count()).select_from(SmokeTest).where(
        SmokeTest.approved_at >= utcnow() - timedelta(days=30))).one()
    rows.append({"name": "Ads and hosting", "sub": f"{funded} funded smoke tests, 30 days",
                 "projected_30d": -float(funded * config.settings()["smoke"]["budget_zar"]), "kind": "cost"})
    biggest = max([abs(r["projected_30d"] or 0) for r in rows] + [1])
    for r in rows:
        r["pct"] = round(100 * abs(r["projected_30d"] or 0) / biggest) if r["projected_30d"] else (6 if r["kind"] == "soon" else 0)
    income = [r["projected_30d"] for r in rows if r["kind"] == "income"]
    net = sum(r["projected_30d"] or 0 for r in rows if r["kind"] in ("income", "cost"))
    conc = round(100 * max(income) / sum(income)) if income and sum(income) > 0 else 0
    return rows, round(net, 2), conc


def build_state() -> dict:
    with session() as s:
        night = _night_of_last_run(s)
        month_start = utcnow().replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        blds = buildings(s, night)
        rows, net, conc = treasury(s)
        quests = side_quests(s)
        gold = float(s.exec(select(func.coalesce(func.sum(Venture.revenue_collected), 0.0))).one())
        busy = s.exec(select(func.count()).select_from(Venture).where(Venture.status == "building")).one() + \
            s.exec(select(func.count()).select_from(SmokeTest).where(SmokeTest.status == "approved")).one()
        cards = [{"id": c.id, "title": c.title, "status": c.status, "url": c.url, "source": c.source}
                 for c in s.exec(select(Card).where(Card.night == night).order_by(Card.id))]
    elixir = costs.total_zar(since=month_start)
    hq = {"id": "hq", "kind": "hq", "name": "Player HQ", "level": 1 + sum(b["kind"] == "mine" for b in blds),
          "lvl": f"Town Hall, Lv {1 + sum(b['kind'] == 'mine' for b in blds)}",
          "desc": "You. The only unit that can spend gold, pass KYC, or sign anything.",
          "kv": [[str(len(quests)), "side quests"], [str(BUILDERS), "builders"], [str(min(busy, BUILDERS)), "busy"]],
          "actions": [{"label": "VIEW SIDE QUESTS", "endpoint": "#side_quests", "style": "grey"}],
          "pile": 0, "rate": 0}
    foot = (f"Night {night}: {len(cards)} card{'' if len(cards) == 1 else 's'} scouted. Elixir this month {_r(elixir)}. "
            + (f"Top earner is {conc}% of your gold." if conc else "No gold mines yet; every figure here is real."))
    return {"gold": round(gold), "elixir_month": round(elixir, 2),
            "scouts_active": next((b["level"] for b in blds if b["kind"] == "camp"), 0),
            "buildings": [hq] + blds, "treasury": rows, "net_30d": net, "concentration_pct": conc,
            "side_quests": quests, "builders": f"{min(busy, BUILDERS)} of {BUILDERS} builders busy",
            "night": night, "generated_at": utcnow().isoformat(), "foot": foot, "cards": cards}


def snapshot() -> dict:
    st = build_state()
    config.DATA_DIR.mkdir(exist_ok=True)
    (config.DATA_DIR / "state.json").write_text(json.dumps(st, indent=2))
    return st

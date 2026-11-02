"""Panel content for everything you can tap on the arena: bases, camps, towers.

Each panel: {id, kind, name, level, lvl, desc, kv: [[value, label] x3], actions, roster}.
Rosters come from AgentRun rows (what each role did last), never from templates.
"""
from __future__ import annotations

from datetime import timedelta

from sqlmodel import func, select

from factory import agents, config, costs
from factory.models import AgentRun, Card, GateResult, RunLog, utcnow

CAMP_DESC = {
    "research": "One scout per niche per source. Each night they pull posts, reviews and listings, the "
                "Distiller writes evidence cards, and two gatekeepers judge them at towers 1 and 2.",
    "dive": "Five analysts study every card at tower 3: demand, competitors, price and margin, risks and "
            "start-up capital. Only niches that pass the Economics gate cross the river.",
    "train": "Prepares the squad for every smoke-test winner: the venture brief, policies and catalogue, then "
             "five agents' instructions. Each agent sits drills that include attempts to make it break a rule; "
             "it needs 90% and no rule broken. One retake after a rewrite, then the Certifier decides.",
    "ops": "Builds each smoke test: landing page, ad drafts and deploy. Per-niche squads arrive in Phase 5.",
    "treasury": "Will pull sales, refunds, ad bills and agent bills per niche. Under construction (Phase 6).",
    "warden": "Checks every agent every 15 minutes. It closes jobs that died, retries sources that hit a "
              "temporary error, pauses sources that keep failing, catches up a missed night and enforces the "
              "daily spend cap. Anything it may not do comes to you, and every Monday it writes your report.",
}
STATE_LABEL = {"running": "work", "ok": "idle", "skipped": "idle", "failed": "block", "blocked": "block"}


def _r(x: float) -> str:
    return f"R{x:,.0f}" if abs(x) >= 10 else f"R{x:,.2f}"


def _roster(dept: str) -> list[dict]:
    return [{"who": r["role"], "task": f"{r['subject']}: {r['summary']}".strip(": "),
             "state": STATE_LABEL.get(r["status"], "idle"), "status": r["status"], "when": r["when"]}
            for r in agents.latest_by_role(dept)[:8]]


def camps(s, departments: list[dict]) -> list[dict]:
    day = utcnow() - timedelta(days=1)
    jobs = {d: n for d, n in s.exec(select(AgentRun.dept, func.count()).where(AgentRun.started_at >= day)
                                    .group_by(AgentRun.dept))}
    spend = {d["id"]: 0.0 for d in departments}
    for d, z in s.exec(select(AgentRun.dept, func.sum(AgentRun.cost_zar)).where(AgentRun.started_at >= day)
                       .group_by(AgentRun.dept)):
        spend[d] = z or 0.0
    names = {"research": "Research Camp", "dive": "Deep Dive Observatory", "train": "Training Academy",
             "ops": "Operations Workshop", "treasury": "Treasury Vault", "warden": "Warden Tower"}
    out = []
    for d in departments:
        lvl = (f"{d['agents']} agent{'' if d['agents'] == 1 else 's'} · {d['working']} working" if d["built"]
               else f"Under construction · Phase {d['phase']}")
        out.append({"id": d["id"], "kind": "camp", "name": names[d["id"]], "level": d["agents"], "lvl": lvl,
                    "desc": CAMP_DESC[d["id"]], "built": d["built"],
                    "kv": [[str(d["agents"]), "agents"], [str(jobs.get(d["id"], 0)), "jobs, 24 h"],
                           [_r(spend.get(d["id"], 0.0)), "spend, 24 h"]],
                    "actions": [], "roster": _roster(d["id"])})
    return out


def warden_panel(panel: dict, w: dict) -> dict:
    """The Warden's camp shows its incidents instead of a role list."""
    cap = f" of R{w['daily_cap_zar']:,.0f}" if w["daily_cap_zar"] else ""
    panel["kv"] = [[str(w["checks_24h"]), "checks, 24 h"], [str(w["fixes_7d"]), "fixes, 7 days"],
                   [str(w["needs_you"]), "need you"]]
    panel["lvl"] = f"{_r(w['today_zar'])}{cap} spent today"
    state = {"needs_you": "block", "watching": "watch", "fixed": "fixed"}
    panel["roster"] = [{"who": i["label"] + (f": {i['subject']}" if i["subject"] else ""),
                        "task": f"{i['detail']} → {i['action']}",
                        "state": state[i["outcome"]] if i["open"] or i["outcome"] == "fixed" else "done"}
                       for i in w["incidents"][:8]]
    panel["actions"] = [{"label": "RUN CHECK NOW", "endpoint": "/api/warden/check", "style": "grey"},
                        {"label": "WRITE REPORT NOW", "endpoint": "/api/warden/report", "style": "grey"}]
    if w["holds"]:
        panel["actions"].append({"label": "RELEASE PAUSED SOURCES", "endpoint": "/api/warden/holds/release",
                                 "style": "grey"})
    if w["report"]:
        panel["link"] = {"label": "Open the latest report", "url": w["report"]["url"]}
    return panel


def tower_panels(arena: dict) -> list[dict]:
    out = []
    for t in arena["towers"]:
        here = [u for u in arena["units"] if u["tower"] == t["n"] and u["state"] != "dead"]
        side = "your side (free)" if t["side"] == "free" else "past the river (money at stake)"
        out.append({"id": f"t{t['n']}", "kind": "tower", "name": f"Tower {t['n']}: {t['name']}", "level": t["n"],
                    "lvl": side, "desc": t["rule"],
                    "kv": [[str(t["waiting"]), "waiting"], [str(t["passed_7d"]), "passed, 7 days"],
                           [str(t["killed_7d"]), "killed, 7 days"]],
                    "actions": [],
                    "roster": [{"who": u["title"], "task": f"{u['lane']} lane · {u['status'].replace('_', ' ')}",
                                "state": "block" if u["state"] == "blocked" else "work"} for u in here[:8]]})
    return out


def bases(s, arena: dict, quests: list[str], gold: float, elixir: float) -> list[dict]:
    live = [m for m in arena["mines"] if m["status"] == "live"]
    revenue = sum(m["revenue"] for m in arena["mines"])
    uncollected = sum(m["uncollected"] for m in arena["mines"])
    return [
        {"id": "base", "kind": "base", "name": "Your base", "level": 1, "lvl": "Player HQ",
         "desc": "You. The only one who can approve spending, pass ID checks or own accounts. "
                 "Gold from live niches comes home here.",
         "kv": [[str(len(quests)), "side quests"], [_r(gold), "gold collected"], [_r(elixir), "elixir, month"]],
         "actions": [{"label": "VIEW SIDE QUESTS", "endpoint": "#side_quests", "style": "grey"}], "roster": []},
        {"id": "market", "kind": "market", "name": "The Market", "level": len(live),
         "lvl": f"{len(live)} live niche{'' if len(live) == 1 else 's'}",
         "desc": "Live niches stand here as gold mines and send gold back down their lane. "
                 "A niche gets here only after passing all six towers.",
         "kv": [[str(len(arena["mines"])), "mines"], [_r(revenue), "revenue"], [_r(uncollected), "uncollected"]],
         "actions": [a for m in arena["mines"] for a in m["actions"]][:2],
         "roster": [{"who": m["name"], "task": f"{m['status']} · {_r(m['revenue'])} earned",
                     "state": "work" if m["status"] == "live" else "idle"} for m in arena["mines"][:8]]},
    ]


def archive(s, night: str) -> dict:
    buried = s.exec(select(func.count()).select_from(Card).where(
        Card.status.in_(["killed_proof", "killed_craft", "killed_dive", "archived"]))).one()
    week = s.exec(select(func.count()).select_from(GateResult).where(
        GateResult.verdict == "kill", GateResult.created_at >= utcnow() - timedelta(days=7))).one()
    rows = list(s.exec(select(GateResult, Card).join(Card, Card.id == GateResult.card_id)
                       .where(GateResult.verdict == "kill").order_by(GateResult.id.desc()).limit(6)))
    return {"id": "archive", "kind": "archive", "name": "The Archive", "level": buried, "lvl": "Graveyard",
            "desc": "Every killed niche with its evidence and the reason, never deleted.",
            "kv": [[str(buried), "buried"], [str(week), "killed, 7 days"], ["R0", "cost"]], "actions": [],
            "roster": [{"who": c.title, "task": f"{g.gate} {g.score}/10: {g.reasoning[:140]}", "state": "idle"}
                       for g, c in rows]}


def last_scout(s) -> str:
    row = s.exec(select(RunLog).where(RunLog.stage == "scout").order_by(RunLog.id.desc())).first()
    return f"Last scouting run {row.night}: {row.summary}." if row else "No scouting run yet: run `make night`."


def elixir_since(dt) -> float:
    return costs.total_zar(since=dt)


def sources_line() -> str:
    return ", ".join(k for k, v in config.settings()["sources"].items() if v)

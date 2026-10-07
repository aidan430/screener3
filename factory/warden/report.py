"""The Reporter: the Monday report and the monthly review.

Built from the database only, with no model call, so it costs nothing and
cannot invent anything. Saved as a WardenReport row and a file in
data/reports/, shown on the dashboard, and emailed when SMTP is configured.
"""
from __future__ import annotations

import html
import json
from collections import defaultdict
from datetime import timedelta

from sqlmodel import func, select

from factory import agents, config, costs
from factory.models import AgentRun, Card, Dossier, GateResult, SmokeTest, Venture, session, utcnow
from factory.smoke import budget
from factory.warden import holds, incidents, mailer
from factory.warden.tables import WardenReport


def _r(x: float) -> str:
    return f"R{x:,.2f}" if abs(x) < 100 else f"R{x:,.0f}"


def build(kind: str = "weekly", now=None) -> dict:
    from factory.api import state as state_mod
    now = now or utcnow()
    start = now - timedelta(days=7 if kind == "weekly" else 30)
    with session() as s:
        scouted = s.exec(select(func.count()).select_from(Card).where(Card.created_at >= start)).one()
        gates = {(g, v): n for g, v, n in s.exec(select(GateResult.gate, GateResult.verdict, func.count())
                                                  .where(GateResult.created_at >= start)
                                                  .group_by(GateResult.gate, GateResult.verdict))}
        tests = dict(s.exec(select(SmokeTest.status, func.count()).group_by(SmokeTest.status)).all())
        waiting = list(s.exec(select(SmokeTest).where(SmokeTest.status == "awaiting_funding")))
        doss = {d.card_id: d for d in s.exec(select(Dossier).order_by(Dossier.id))}
        tower6 = list(s.exec(select(Card).where(Card.status.in_(["certified", "training_failed"]))))
        runs = list(s.exec(select(AgentRun).where(AgentRun.started_at >= start)))
        niches = state_mod.niches(s)
        ventures = {v.slug: v for v in s.exec(select(Venture))}
        slugs = {t.name: t.slug for t in s.exec(select(SmokeTest))}
        quests = state_mod.side_quests(s)
    decisions = []
    for t in waiting:
        d = doss.get(t.card_id)
        extra = (f" If it wins, the launch needs about R{d.capital_zar:,.0f} (break-even after "
                 f"{d.break_even_sales or '?'} sales)." if d and d.capital_zar else "")
        decisions.append({"text": f"Fund the {t.name} smoke test? R{budget.of(t)} for 48 hours.{extra}",
                          "label": f"FUND TEST R{budget.of(t)}", "endpoint": f"/api/approve/{t.id}"})
    from factory.build.launch import fund_label, shopping_list
    for c in tower6:
        if c.status == "certified":
            _, rest = shopping_list(c.id)
            label = fund_label(doss.get(c.id))
            what = "its first stock and the rest of the start-up" if label == "FUND STOCK" else "the rest of the start-up"
            decisions.append({"text": f"Fund the launch of “{c.title}”? It won its smoke test and its squad passed every "
                                      f"exam. {what[0].upper() + what[1:]} is R{rest:,.0f}; nothing is bought automatically.",
                              "label": f"{label} R{rest:,.0f}", "endpoint": f"/api/launch/{c.id}"})
        else:
            decisions.append({"text": f"Retry training for “{c.title}”? Its squad was not certified.",
                              "label": "RETRY TRAINING", "endpoint": f"/api/train/{c.id}/retry"})
    verdicts = []
    for n in niches:
        v = ventures.get(slugs.get(n["name"], ""))
        if not v:
            continue
        days = (now - agents._aware(v.live_at or v.started_at)).days
        verdict = ("scale" if n["profit"] > 0 and n["revenue"] >= 3 * max(n["costs"], 1) else
                   "hold" if n["profit"] >= 0 or days < 30 else "kill")
        verdicts.append({**n, "days": days, "verdict": verdict})
        if verdict == "kill":
            decisions.append({"text": f"Kill “{n['name']}”? It has lost {_r(-n['profit'])} over {days} days.",
                              "label": None, "endpoint": None})
    open_items = incidents.open_items()
    for i in open_items:  # what the Warden could not fix (funding and launches are listed above)
        if i.outcome == "needs_you" and i.kind not in ("stuck_funding", "stuck_launch", "training_failed"):
            decisions.append({"text": f"{i.detail} {i.action}", "label": None, "endpoint": None})
    fixed = [i for i in incidents.since((now - start).days) if i.outcome == "fixed"]
    by_dept, failed = defaultdict(float), sum(1 for r in runs if agents.effective_status(r) in ("failed", "blocked"))
    for r in runs:
        by_dept[r.dept] += r.cost_zar
    enabled = [k for k, v in config.settings()["sources"].items() if v]
    held = holds.active()
    sources = []
    for src in enabled:
        mine = [r for r in runs if r.role == f"{src} scout"]
        sources.append({"source": src, "ok": sum(r.status == "ok" for r in mine),
                        "failed": sum(r.status == "failed" for r in mine),
                        "held_until": holds.local(held[src].until) if src in held else None})
    spend = costs.total_zar(since=start)
    killed = sum(n for (g, v), n in gates.items() if v == "kill")
    return {
        "kind": kind, "start": start.isoformat(), "end": now.isoformat(),
        "money": {"spend": round(spend, 2), "by_dept": {k: round(v, 2) for k, v in by_dept.items()},
                  "revenue_to_date": round(sum(n["revenue"] for n in niches), 2),
                  "profit_to_date": round(sum(n["profit"] for n in niches), 2),
                  "daily_cap": costs.daily_cap()},
        "pipeline": {"scouted": scouted, "gates": {f"{g}_{v}": n for (g, v), n in gates.items()},
                     "killed": killed, "tests": tests},
        "niches": verdicts if kind == "monthly" else niches, "decisions": decisions,
        "done": ([{"what": f"{h.source} kept failing.", "action": f"Paused it until {holds.local(h.until)}."}
                  for h in held.values() if agents._aware(h.created_at) >= start]
                 + [{"what": i.detail, "action": i.action} for i in fixed])[:12],
        "watching": [{"what": i.detail, "action": i.action} for i in open_items if i.outcome == "watching"],
        "sources": sources, "agents": {"runs": len(runs), "failed": failed}, "side_quests": quests,
    }


def title(r: dict) -> str:
    n = len(r["decisions"])
    when = utcnow().strftime("%B %Y") + " review" if r["kind"] == "monthly" else "Week " + utcnow().strftime("%V")
    return f"{when}: {n} decision{'' if n == 1 else 's'} for you, {_r(r['money']['spend'])} agent spend"


def render_md(r: dict) -> str:
    m, p = r["money"], r["pipeline"]
    out = [f"# {title(r)}", "", f"From the Warden. Period {r['start'][:10]} to {r['end'][:10]}.", "",
           "## Decisions for you"]
    out += [f"{i}. {d['text']}" for i, d in enumerate(r["decisions"], 1)] or ["Nothing needs you this week."]
    out += ["", "## Money",
            f"- Agent spend: {_r(m['spend'])} (" + ", ".join(f"{k} {_r(v)}" for k, v in sorted(m["by_dept"].items())) + ")",
            f"- Revenue to date: {_r(m['revenue_to_date'])}; profit to date: {_r(m['profit_to_date'])}. "
            "Weekly revenue arrives with the Treasury (Phase 6).", "", "## Niches"]
    out += [f"- {n['name']} ({n['model']}, {n['stage']}): revenue {_r(n['revenue'])}, costs {_r(n['costs'])}, "
            f"profit {_r(n['profit'])}" + (f", verdict: {n['verdict']}" if "verdict" in n else "") for n in r["niches"]] \
        or ["- No niche has reached a smoke test yet."]
    out += ["", "## Pipeline", f"- {p['scouted']} cards scouted, {p['killed']} killed at the gates.",
            "- Gates: " + (", ".join(f"{k.replace('_', ' ')} {v}" for k, v in sorted(p["gates"].items())) or "no verdicts"),
            "- Smoke tests: " + (", ".join(f"{k.replace('_', ' ')} {v}" for k, v in sorted(p["tests"].items())) or "none"),
            "", "## Done without you"]
    out += [f"- {d['what']} {d['action']}" for d in r["done"]] or ["- Nothing needed fixing."]
    out += ["", "## Watching"] + ([f"- {w['what']}" for w in r["watching"]] or ["- Nothing."])
    out += ["", "## Sources"] + [f"- {x['source']}: {x['ok']} ok, {x['failed']} failed"
                                 + (f", paused until {x['held_until']}" if x["held_until"] else "")
                                 for x in r["sources"]]
    out += ["", f"Agents ran {r['agents']['runs']} jobs; {r['agents']['failed']} failed or were blocked."]
    return "\n".join(out) + "\n"


def render_html(r: dict, md: str) -> str:
    e = html.escape
    body = []
    for line in md.splitlines():
        if line.startswith("# "):
            body.append(f"<h1>{e(line[2:])}</h1>")
        elif line.startswith("## "):
            body.append(f"<h2>{e(line[3:])}</h2>")
        elif line.strip():
            body.append(f"<p>{e(line)}</p>")
    buttons = "".join(f'<p class="act">{e(d["text"])}<br><b>On the dashboard: {e(d["label"])}</b></p>'
                      for d in r["decisions"] if d.get("label"))
    return ("<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"utf-8\"><meta name=\"viewport\" "
            "content=\"width=device-width, initial-scale=1\"><title>Warden report</title><style>"
            "body{margin:0;padding:24px 16px;background:#102A38;color:#F4EBDA;font:16px/1.5 system-ui,sans-serif}"
            "main{max-width:720px;margin:0 auto;background:#F7E6C3;color:#3B2A14;border:4px solid #6B4423;"
            "border-radius:12px;padding:20px 24px}h1{font-size:24px;margin:0 0 6px}h2{font-size:18px;"
            "margin:22px 0 6px;border-bottom:2px dashed #C9A86A}p{margin:4px 0}.act{background:#fff8e8;"
            "border:2px solid #D9B98A;border-radius:8px;padding:8px}</style></head><body><main>"
            + "".join(body) + (f"<h2>Buttons waiting for you</h2>{buttons}" if buttons else "") + "</main></body></html>")


def save(kind: str = "weekly") -> WardenReport:
    with agents.run("warden", "Reporter", subject=f"{kind} report") as job:
        now = utcnow()
        r = build(kind, now)
        md = render_md(r)
        rep = WardenReport(kind=kind, title=title(r), period_start=now - timedelta(days=7 if kind == "weekly" else 30),
                           period_end=now, body_md=md, body_html=render_html(r, md),
                           summary_json=json.dumps(r, default=str))
        with session() as s:
            s.add(rep)
            s.commit()
            s.refresh(rep)
        folder = config.DATA_DIR / "reports"
        folder.mkdir(parents=True, exist_ok=True)
        (folder / f"{utcnow():%Y-%m-%d}-{kind}-{rep.id}.md").write_text(md)
        if mailer.send(rep.title, md, rep.body_html):
            with session() as s:
                row = s.get(WardenReport, rep.id)
                row.emailed = True
                s.add(row)
                s.commit()
            rep.emailed = True
        job.summary = f"{rep.title}" + (" (emailed)" if rep.emailed else "")
    return rep

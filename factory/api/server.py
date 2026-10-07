"""FastAPI: /api/state, /api/approve/{id}, /api/collect/{id}, Paystack webhook,
local page beacons, and the static dashboard. Port 8000.

Usage: python -m factory.api.server   (binds 127.0.0.1 unless HOST is set)
"""
from __future__ import annotations

import hashlib
import hmac
import json
import logging

from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import FileResponse, HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from sqlmodel import select

from factory import config
from factory.api.state import build_state
from factory.models import SmokeTest, TrackEvent, Venture, session

log = logging.getLogger("factory.api")
app = FastAPI(title="Venture Factory", docs_url="/api/docs")
KINDS = {"visit", "buy_click", "email"}


@app.get("/api/state")
def state() -> JSONResponse:
    return JSONResponse(build_state(), headers={"Cache-Control": "no-store"})


@app.post("/api/approve/{smoke_id}")
def approve(smoke_id: int) -> dict:
    """The only path that can lead to money being spent. Human click required."""
    from factory.smoke.run import approve as do_approve
    res = do_approve(smoke_id)
    if not res["ok"]:
        raise HTTPException(409, res["message"])
    return res


@app.post("/api/collect/{venture_id}")
def collect(venture_id: int, amount: float | None = None) -> dict:
    """No amount: move uncollected revenue to gold. With amount: record manual revenue (rand)."""
    with session() as s:
        v = s.get(Venture, venture_id)
        if not v:
            raise HTTPException(404, "No such venture")
        if amount is not None:
            if amount <= 0:
                raise HTTPException(400, "amount must be positive")
            v.revenue_collected += amount
            msg = f"Recorded R{amount:,.0f} for {v.name}."
        else:
            got = v.revenue_uncollected
            v.revenue_collected += got
            v.revenue_uncollected = 0
            msg = f"Collected R{got:,.0f} from {v.name}."
        s.add(v)
        s.commit()
    return {"ok": True, "message": msg}


@app.post("/api/paystack/webhook")
async def paystack(request: Request) -> dict:
    secret = config.env("PAYSTACK_SECRET_KEY")
    body = await request.body()
    sig = request.headers.get("x-paystack-signature", "")
    if not secret or not hmac.compare_digest(hmac.new(secret.encode(), body, hashlib.sha512).hexdigest(), sig):
        raise HTTPException(401, "bad signature")
    evt = json.loads(body)
    if evt.get("event") != "charge.success":
        return {"ok": True, "ignored": evt.get("event")}
    data = evt.get("data", {})
    slug = (data.get("metadata") or {}).get("venture")
    amount = float(data.get("amount", 0)) / 100  # kobo/cents -> rand
    with session() as s:
        v = s.exec(select(Venture).where(Venture.slug == slug)).first()
        if not v:
            log.warning("paystack charge for unknown venture %r", slug)
            return {"ok": True, "ignored": "unknown venture"}
        v.revenue_uncollected += amount
        if v.status == "building":
            v.status = "live"
        s.add(v)
        s.commit()
    return {"ok": True}


@app.api_route("/api/event/{slug}", methods=["GET", "POST"])
def event(slug: str, kind: str, detail: str = "") -> dict:
    if kind not in KINDS:
        raise HTTPException(400, "unknown kind")
    with session() as s:
        if not s.exec(select(SmokeTest).where(SmokeTest.slug == slug)).first():
            raise HTTPException(404, "unknown page")
        s.add(TrackEvent(slug=slug, kind=kind, detail=detail[:200]))
        s.commit()
    return {"ok": True}


@app.get("/api/reports")
def reports() -> list[dict]:
    from factory.warden.tables import WardenReport
    with session() as s:
        rows = s.exec(select(WardenReport).order_by(WardenReport.id.desc()).limit(20))
        return [{"id": r.id, "kind": r.kind, "title": r.title, "created": r.created_at.isoformat(),
                 "url": f"/reports/{r.id}", "emailed": r.emailed} for r in rows]


@app.get("/reports/{report_id}", response_class=HTMLResponse)
def report_page(report_id: int) -> HTMLResponse:
    from factory.warden.tables import WardenReport
    with session() as s:
        r = s.get(WardenReport, report_id)
    if not r:
        raise HTTPException(404, "No such report")
    return HTMLResponse(r.body_html)


@app.post("/api/warden/check")
def warden_check() -> dict:
    from factory.warden import health
    res = health.check(catch_up=False)
    lines = [f"{'Needs you' if i.outcome == 'needs_you' else 'Watching'}: {i.detail}" for i in res["open"]][:5]
    return {"ok": True, "message": "Health check done: " + res["summary"] + "." + ("\n" + "\n".join(lines) if lines else "")}


@app.post("/api/warden/report")
def warden_report() -> dict:
    from factory.warden import report
    rep = report.save("weekly")
    return {"ok": True, "url": f"/reports/{rep.id}",
            "message": f"Report written: {rep.title}." + (" Emailed to you." if rep.emailed else "")}


@app.post("/api/incidents/{incident_id}/resolve")
def resolve_incident(incident_id: int) -> dict:
    from factory.warden import incidents
    if not incidents.dismiss(incident_id):
        raise HTTPException(404, "No open incident with that id")
    return {"ok": True, "message": "Marked as handled. If the problem is still there, the Warden reopens it at its next check."}


@app.post("/api/warden/holds/release")
def release_holds() -> dict:
    from factory.warden import holds
    n = holds.release_all()
    return {"ok": True, "message": f"Released {n} paused source{'' if n == 1 else 's'}. Scouts try them tonight."}


@app.get("/")
def dashboard() -> FileResponse:
    return FileResponse(config.DASHBOARD_DIR / "index.html")


@app.get("/{name}.js")
def dashboard_js(name: str) -> FileResponse:
    if name not in ("arena", "app"):
        raise HTTPException(404, "not found")
    return FileResponse(config.DASHBOARD_DIR / f"{name}.js", media_type="text/javascript")


config.PAGES_DIR.mkdir(parents=True, exist_ok=True)
app.mount("/pages", StaticFiles(directory=config.PAGES_DIR, html=True), name="pages")


def main() -> None:
    import uvicorn
    config.setup_logging()
    uvicorn.run(app, host=config.env("HOST", "127.0.0.1"), port=int(config.env("PORT", "8000")))


if __name__ == "__main__":
    main()

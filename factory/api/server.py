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
from fastapi.responses import FileResponse, JSONResponse
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


@app.get("/")
def dashboard() -> FileResponse:
    return FileResponse(config.DASHBOARD_DIR / "index.html")


config.PAGES_DIR.mkdir(parents=True, exist_ok=True)
app.mount("/pages", StaticFiles(directory=config.PAGES_DIR, html=True), name="pages")


def main() -> None:
    import uvicorn
    config.setup_logging()
    uvicorn.run(app, host=config.env("HOST", "127.0.0.1"), port=int(config.env("PORT", "8000")))


if __name__ == "__main__":
    main()

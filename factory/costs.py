"""Every Anthropic call goes through here: pre-call budget check, call, Cost row.

Budgets:
- per-stage cap (settings.caps.stage_zar, R20): a call whose worst-case cost would
  push the stage over the cap raises StageOverBudget *before* it is sent.
- callers can pass their own `cap_zar` (e.g. the R0.60 per-niche scout cap).
"""
from __future__ import annotations

import logging
from contextlib import contextmanager
from typing import Any, Type, TypeVar

from pydantic import BaseModel
from sqlmodel import func, select

from factory import config
from factory.models import Cost, session, tonight

log = logging.getLogger("factory.costs")
T = TypeVar("T", bound=BaseModel)

_client = None
_stage: dict[str, Any] = {"name": None, "spent_zar": 0.0}
_process = {"zar": 0.0}  # everything this process has spent; agents.run() diffs it per AgentRun


class StageOverBudget(RuntimeError):
    pass


class CapExceeded(RuntimeError):
    """A caller-supplied cap (e.g. per-niche) would be exceeded."""


class NoApiKey(RuntimeError):
    pass


def set_client(client) -> None:
    """Inject a client (tests use a fake)."""
    global _client
    _client = client


def client():
    global _client
    if _client is None:
        if not (config.env("ANTHROPIC_API_KEY") or config.env("ANTHROPIC_AUTH_TOKEN")):
            raise NoApiKey("ANTHROPIC_API_KEY is not set (add it to .env)")
        import anthropic
        _client = anthropic.Anthropic(max_retries=3)
    return _client


def price(model: str) -> tuple[float, float]:
    if "opus" in model:
        raise ValueError("Opus is not allowed in the factory")
    table = config.settings()["pricing"]
    if model not in table:
        raise ValueError(f"No price configured for {model}")
    i, o = table[model]
    return float(i), float(o)


def usd_for(model: str, input_tokens: int, output_tokens: int) -> float:
    i, o = price(model)
    return (input_tokens * i + output_tokens * o) / 1_000_000


def estimate_zar(model: str, prompt_chars: int, max_tokens: int) -> float:
    """Worst case: ~3.5 chars per input token, every output token used."""
    return config.zar(usd_for(model, int(prompt_chars / 3.5) + 50, max_tokens))


@contextmanager
def stage(name: str):
    """Track spend for one pipeline stage against the R20 cap."""
    prev = dict(_stage)
    _stage.update(name=name, spent_zar=0.0)
    try:
        yield _stage
    finally:
        spent = _stage["spent_zar"]
        log.info("stage %s spent R%.2f", name, spent)
        _stage.update(prev)


def process_spent() -> float:
    return _process["zar"]


def stage_cap() -> float:
    return float(config.settings()["caps"]["stage_zar"])


def call(
    *,
    stage_name: str,
    model: str,
    system: str,
    prompt: str,
    output: Type[T],
    max_tokens: int,
    niche_slug: str = "",
    card_id: int | None = None,
    cap_zar: float | None = None,
    note: str = "",
) -> T:
    """Structured-output call. Returns a validated pydantic object."""
    est = estimate_zar(model, len(system) + len(prompt), max_tokens)
    if cap_zar is not None and est > cap_zar:
        raise CapExceeded(f"{stage_name}/{niche_slug}: est R{est:.2f} > cap R{cap_zar:.2f}")
    if _stage["name"] and _stage["spent_zar"] + est > stage_cap():
        raise StageOverBudget(
            f"stage '{_stage['name']}' has spent R{_stage['spent_zar']:.2f}; next call "
            f"(est R{est:.2f}) would pass the R{stage_cap():.0f} cap. Stopping."
        )
    resp = client().messages.parse(
        model=model,
        max_tokens=max_tokens,
        system=system,
        messages=[{"role": "user", "content": prompt}],
        output_format=output,
    )
    u = resp.usage
    in_tok = (u.input_tokens or 0) + (getattr(u, "cache_read_input_tokens", 0) or 0) \
        + (getattr(u, "cache_creation_input_tokens", 0) or 0)
    out_tok = u.output_tokens or 0
    usd = usd_for(model, in_tok, out_tok)
    rand = config.zar(usd)
    record(stage_name, model, in_tok, out_tok, usd, rand, niche_slug, card_id, note)
    _process["zar"] += rand
    if _stage["name"]:
        _stage["spent_zar"] += rand
    print(f"    [cost] {stage_name:<6} {model:<18} in={in_tok:>6} out={out_tok:>5} "
          f"R{rand:.3f}{'  ' + niche_slug if niche_slug else ''}")
    if resp.stop_reason == "refusal" or resp.parsed_output is None:
        raise RuntimeError(f"{model} returned no parsable output (stop_reason={resp.stop_reason})")
    return resp.parsed_output


def record(stage_name, model, in_tok, out_tok, usd, rand, niche_slug="", card_id=None, note=""):
    with session() as s:
        s.add(Cost(stage=stage_name, model=model, input_tokens=in_tok, output_tokens=out_tok,
                   usd=usd, zar=rand, niche_slug=niche_slug, card_id=card_id, note=note))
        s.commit()
    log.info("cost %s %s in=%d out=%d R%.4f %s", stage_name, model, in_tok, out_tok, rand, niche_slug)


def total_zar(night: str | None = None, stage_name: str | None = None, since=None) -> float:
    with session() as s:
        q = select(func.coalesce(func.sum(Cost.zar), 0.0))
        if night:
            q = q.where(Cost.night == night)
        if stage_name:
            q = q.where(Cost.stage == stage_name)
        if since is not None:
            q = q.where(Cost.ts >= since)
        return float(s.exec(q).one())


def niche_zar(slug: str, night: str | None = None) -> float:
    with session() as s:
        q = select(func.coalesce(func.sum(Cost.zar), 0.0)).where(
            Cost.niche_slug == slug, Cost.stage == "scout", Cost.night == (night or tonight()))
        return float(s.exec(q).one())


def print_nightly_total(night: str | None = None) -> float:
    night = night or tonight()
    with session() as s:
        rows = s.exec(select(Cost.stage, func.count(), func.sum(Cost.zar))
                      .where(Cost.night == night).group_by(Cost.stage)).all()
    total = sum(r[2] or 0 for r in rows)
    print(f"\n  Elixir for night {night}: R{total:.2f}")
    for st, n, z in rows:
        print(f"    {st:<8} {n:>3} calls  R{z or 0:.2f}")
    return total

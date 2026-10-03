"""Haiku: a niche's raw signals -> at most 5 Card rows per night.

Every card must point at one stored Signal. The quote and pay evidence are
checked to be verbatim substrings of that signal; anything that is not is
dropped (quote) or blanked (pay evidence). No url, no card.
"""
from __future__ import annotations

import logging
import re

from pydantic import BaseModel, Field
from sqlmodel import func, select

from factory import config, costs
from factory.models import Card, Niche, Signal, session, tonight

log = logging.getLogger("factory.distill")
last_note: dict[str, str] = {}

SYSTEM = """You are a scout for a venture studio. You read raw posts from forums and
extract problems that people already pay (or clearly would pay) to solve with
software that one developer could build.

Hard rules:
- Use ONLY the posts given. Never invent facts, prices, people or urls.
- `quote` must be copied character-for-character from the post's text (one to
  three sentences, 20-300 characters). Do not paraphrase, fix typos or join
  separate passages.
- `pay_evidence` must also be copied verbatim from the same post and show money:
  a price, a paid tool being used or complained about, paying a person to do the
  task, or an explicit willingness to pay. If the post has none, use "".
- `pay_amount` is the number in pay_evidence (e.g. 199 for "R199/month"), else null.
  `pay_currency` is its symbol or code as written ("R", "$", "USD"...), else "".
- Skip posts that are jokes, news, self-promotion, or problems needing physical
  work, licences or sales teams. Fewer good cards beat many weak ones.
- Return at most {max_cards} cards, each from a different post where possible."""


class CardDraft(BaseModel):
    signal_id: int = Field(description="id of the post this card comes from")
    title: str = Field(description="short product-style name of the problem, max 8 words")
    problem: str = Field(description="one sentence: who has what painful problem")
    quote: str
    pay_evidence: str
    pay_amount: float | None = None
    pay_currency: str = ""


class Distilled(BaseModel):
    cards: list[CardDraft]


_WS = re.compile(r"\s+")
_QUOTES = str.maketrans({"‘": "'", "’": "'", "“": '"', "”": '"', "–": "-", "—": "-"})


def norm(s: str) -> str:
    return _WS.sub(" ", (s or "").translate(_QUOTES)).strip().lower()


def verbatim(snippet: str, source: str) -> bool:
    return bool(snippet) and norm(snippet) in norm(source)


def amount_in(amount: float | None, text: str) -> bool:
    if amount is None:
        return False
    digits = re.sub(r"[^\d.]", " ", text.replace(",", ""))
    nums = {float(x) for x in digits.split() if re.fullmatch(r"\d+(\.\d+)?", x)}
    return float(amount) in nums


def candidates(niche: Niche, limit: int) -> list[Signal]:
    with session() as s:
        used = select(Card.signal_id).where(Card.signal_id.is_not(None))
        q = (select(Signal).where(Signal.niche_id == niche.id, Signal.id.not_in(used))
             .order_by(Signal.rank.desc()).limit(limit))
        return list(s.exec(q))


def build_prompt(niche: Niche, signals: list[Signal], chars: int, max_cards: int) -> str:
    parts = [f"Niche: {niche.slug} (region {niche.region}). Keywords: {', '.join(niche.keywords)}. "
             f"Known paid competitors: {', '.join(niche.competitors) or 'none listed'}.",
             f"Extract up to {max_cards} cards from these {len(signals)} posts:\n"]
    for sig in signals:
        body = sig.text[:chars]
        parts.append(f"<post id=\"{sig.id}\" source=\"{sig.source}\" score=\"{sig.score:g}\" "
                     f"replies=\"{sig.replies}\">\nTITLE: {sig.title}\nTEXT: {body}\n</post>")
    return "\n".join(parts)


def cards_tonight(niche: Niche) -> int:
    with session() as s:
        return s.exec(select(func.count()).select_from(Card)
                      .where(Card.niche_id == niche.id, Card.night == tonight())).one()


def distill_niche(niche: Niche) -> list[Card]:
    caps = config.settings()["caps"]
    max_cards = int(caps["cards_per_niche"]) - cards_tonight(niche)
    if max_cards <= 0:
        last_note[niche.slug] = "already has 5 cards tonight"
        return []
    signals = candidates(niche, int(caps["signals_to_distill"]))
    if not signals:
        last_note[niche.slug] = "no new signals (sources returned nothing usable)"
        return []
    cap = float(caps["scout_zar_per_niche"]) - costs.niche_zar(niche.slug)
    model = config.settings()["models"]["scout"]
    system = SYSTEM.format(max_cards=max_cards)
    chars = int(caps["signal_chars"])
    # Trim the batch until the worst-case estimate fits the per-niche cap.
    while signals:
        prompt = build_prompt(niche, signals, chars, max_cards)
        if costs.estimate_zar(model, len(system) + len(prompt), 2000) <= cap:
            break
        signals = signals[:-3]
    if not signals:
        last_note[niche.slug] = f"skipped: over R{caps['scout_zar_per_niche']} scout cap"
        log.warning("distill %s skipped: over cap", niche.slug)
        return []
    try:
        out = costs.call(stage_name="scout", model=model, system=system, prompt=prompt,
                         output=Distilled, max_tokens=2000, niche_slug=niche.slug, cap_zar=cap)
    except (costs.CapExceeded, costs.NoApiKey) as e:
        last_note[niche.slug] = f"skipped: {e}"
        log.warning("distill %s skipped: %s", niche.slug, e)
        return []
    return save_cards(niche, signals, out.cards[:max_cards])


def save_cards(niche: Niche, signals: list[Signal], drafts: list[CardDraft]) -> list[Card]:
    by_id = {s.id: s for s in signals}
    saved, dropped = [], []
    with session() as s:
        for d in drafts:
            sig = by_id.get(d.signal_id)
            if not sig or not sig.url:
                dropped.append(f"{d.title!r}: unknown post id {d.signal_id}")
                continue
            source_text = f"{sig.title}\n{sig.text}"
            if not verbatim(d.quote, source_text) or len(d.quote.strip()) < 20:
                dropped.append(f"{d.title!r}: quote not verbatim")
                continue
            pay_ev = d.pay_evidence if verbatim(d.pay_evidence, source_text) else ""
            amount = d.pay_amount if pay_ev and amount_in(d.pay_amount, pay_ev) else None
            card = Card(niche_id=niche.id, signal_id=sig.id, title=d.title.strip()[:120],
                        problem=d.problem.strip(), quote=d.quote.strip(), url=sig.url,
                        pay_evidence=pay_ev, pay_amount=amount,
                        pay_currency=d.pay_currency if amount is not None else "", source=sig.source)
            s.add(card)
            saved.append(card)
            by_id.pop(d.signal_id)  # one card per signal
        s.commit()
    for msg in dropped:
        log.warning("distill %s dropped %s", niche.slug, msg)
    last_note[niche.slug] = f"{len(drafts)} drafted, {len(dropped)} dropped by verbatim check"
    return saved

"""Sonnet writes the landing-page copy and ad drafts; we render a single-file page.

The page has a headline, three benefits, one price and one Buy button. The Buy
button records a `buy_click` event, then shows the founders-onboarding email
form. Tracking: Plausible custom event when PLAUSIBLE is configured, plus a
beacon to our own API (works when the page is served by `make serve`).
"""
from __future__ import annotations

import html
import json
import re

from pydantic import BaseModel, Field

from factory import config, costs
from factory.models import Card, Niche, session

SYSTEM = """You write landing pages for smoke tests: a fake-door page that measures
whether strangers click Buy. Write plain, specific, honest copy for the exact
problem in the card, in the buyer's own words where possible. No hype words, no
fake testimonials, no invented statistics, no claims of existing customers.
Price must be a single plan the evidence supports (use the pay evidence as an
anchor if present; otherwise a modest monthly price). For region ZA price in
rand (e.g. "R149 / month"); otherwise in USD.
Also draft 3 Meta ad variants (primary text <= 125 chars, headline <= 40 chars)
and a targeting suggestion (countries, age range, interests)."""


class AdVariant(BaseModel):
    primary_text: str
    headline: str
    description: str = ""


class Targeting(BaseModel):
    countries: list[str]
    age_min: int = 25
    age_max: int = 60
    interests: list[str]


class PageDraft(BaseModel):
    product_name: str = Field(description="2-3 word product name")
    headline: str
    subhead: str
    benefits: list[str] = Field(description="exactly three benefits")
    price_label: str = Field(description='e.g. "R149 / month" or "$19 / month"')
    cta: str = Field(description="buy button text, e.g. 'Buy now'")
    ads: list[AdVariant]
    targeting: Targeting


def slugify(s: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")[:40] or "venture"


def draft(card: Card, price_label: str = "") -> PageDraft:
    with session() as s:
        niche = s.get(Niche, card.niche_id)
    prompt = (f"Niche: {niche.slug} (region {niche.region})\nCard title: {card.title}\n"
              f"Problem: {card.problem}\nBuyer quote: \"{card.quote}\"\n"
              f"Pay evidence: {card.pay_evidence or 'none'}\nSource: {card.url}"
              + (f"\nPrice to use, exactly as written (set by the Deep Dive): {price_label}" if price_label else ""))
    return costs.call(stage_name="smoke", model=config.settings()["models"]["judge"], system=SYSTEM,
                      prompt=prompt, output=PageDraft, max_tokens=1500, card_id=card.id)


def render(d: PageDraft, slug: str, api_base: str | None = "") -> str:
    e = html.escape
    plausible = ""
    if config.env("FACTORY_DOMAIN"):
        dom = f"{slug}.{config.env('FACTORY_DOMAIN')}"
        plausible = (f'<script defer data-domain="{e(dom)}" src="https://plausible.io/js/script.tagged-events.js">'
                     "</script>\n<script>window.plausible=window.plausible||function(){(window.plausible.q="
                     "window.plausible.q||[]).push(arguments)}</script>")
    benefits = "".join(f"<li>{e(b)}</li>" for b in d.benefits[:3])
    cfg = json.dumps({"slug": slug, "api": api_base})
    return f"""<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{e(d.product_name)}</title>
{plausible}
<style>
body{{margin:0;font-family:system-ui,-apple-system,Segoe UI,sans-serif;background:#f7f7f4;color:#1c1c1a;line-height:1.5}}
main{{max-width:640px;margin:0 auto;padding:56px 20px}}
h1{{font-size:clamp(28px,6vw,42px);line-height:1.15;margin:0 0 12px}}
.sub{{font-size:19px;color:#4a4a45;margin:0 0 28px}}
ul{{padding-left:20px;margin:0 0 32px}} li{{margin:8px 0;font-size:17px}}
.price{{font-size:28px;font-weight:700;margin:0 0 14px}}
button{{font:inherit;font-size:18px;font-weight:700;background:#1f6f4a;color:#fff;border:0;border-radius:10px;padding:14px 28px;cursor:pointer}}
form{{display:none;margin-top:20px;gap:8px;flex-wrap:wrap}}
input{{font:inherit;padding:12px;border:1px solid #bbb;border-radius:8px;min-width:240px}}
.ok{{display:none;color:#1f6f4a;font-weight:600;margin-top:16px}}
footer{{margin-top:48px;font-size:13px;color:#7a7a72}}
</style></head><body><main>
<p style="font-weight:700;color:#1f6f4a">{e(d.product_name)}</p>
<h1>{e(d.headline)}</h1>
<p class="sub">{e(d.subhead)}</p>
<ul>{benefits}</ul>
<p class="price">{e(d.price_label)}</p>
<button id="buy">{e(d.cta)}</button>
<form id="f"><p style="width:100%;margin:0">We are onboarding founders this week, leave your email.</p>
<input type="email" id="em" required placeholder="you@example.com"><button type="submit">Notify me</button></form>
<p class="ok" id="ok">Thanks. We will be in touch this week.</p>
<footer>An early product test. No payment is taken on this page.</footer>
</main><script>
var C={cfg};
function beacon(kind,detail){{try{{if(window.plausible&&kind!=='visit')plausible(kind);
if(C.api!==null)navigator.sendBeacon((C.api||'')+'/api/event/'+C.slug+'?kind='+kind+(detail?'&detail='+encodeURIComponent(detail):''));}}catch(e){{}}}}
beacon('visit');
document.getElementById('buy').onclick=function(){{beacon('buy_click');this.style.display='none';document.getElementById('f').style.display='flex';}};
document.getElementById('f').onsubmit=function(ev){{ev.preventDefault();beacon('email',document.getElementById('em').value);this.style.display='none';document.getElementById('ok').style.display='block';}};
</script></body></html>
"""

# Venture Factory — operational brief

## What this is
An unattended system that runs nightly: 100+ scout agents mine evidence of
problems people already pay to solve, gatekeeper agents kill weak ideas,
survivors get a landing page and ad set prepared for a human-funded smoke
test, and winners get a build spec. A game-styled dashboard (dashboard/
index.html) shows the live state. The human (the "player") does only what
agents cannot: spend money, pass KYC, own accounts.

Money is never spent and nothing is posted publicly without a human click.

## Stack (do not deviate without asking)
- Python 3.11, `uv` for deps
- SQLite via `sqlmodel`, file at `data/factory.db`
- `anthropic` SDK. Scouts use `claude-haiku-4-5`. Gatekeepers, spec writer
  and page writer use `claude-sonnet-4-6`. Never Opus.
- `httpx` for HTTP, `praw` for Reddit, `feedparser` for RSS, `playwright`
  only where an API does not exist (app store reviews, Upwork search pages)
- FastAPI serving `/api/state` and the static dashboard, port 8000
- APScheduler: scouts 01:00 SAST, gates 02:00, dashboard refresh continuous
- `.env` for secrets, never committed

## Repo layout
```
factory/
  models.py          # Niche, Signal, Card, GateResult, SmokeTest, Build, Venture, Cost
  seed.py            # loads config/niches.yaml into Niche rows
  scouts/
    runner.py        # runs every active Niche through the source adapters
    sources/
      reddit.py      # subreddit + search for pain phrases
      hn.py          # Algolia HN API, "ask hn" + pain phrases
      upwork.py      # public job search pages (playwright), price extraction
      fiverr.py      # gig search pages, price extraction
      appstore.py    # 1-2 star reviews for competitor apps named in niche config
      hellopeter.py  # SA complaints site, public pages
      trends.py      # Google Trends rising queries via pytrends
    distill.py       # Haiku: raw signals -> Card rows with quote, url, pay_evidence
  gates/
    proof.py         # Sonnet judge: is there evidence someone pays today? score 0-10
    craft.py         # Sonnet judge: solo-buildable in <7 days, no humans in loop?
    rubric.md        # the exact rubrics, versioned
  smoke/
    page.py          # Sonnet writes a single-file landing page with price + buy button
    ads.py           # drafts 3 ad variants + targeting as JSON; never calls Meta API unless APPROVED
    deploy.py        # pushes page to Vercel via CLI under a subdomain of the factory domain
    track.py         # reads Plausible/umami events for buy-clicks
  build/
    spec.py          # Sonnet: writes a CLAUDE.md for the winning venture
    launch.py        # scaffolds a sibling repo from the spec, hands off to a Claude Code session
  api/
    server.py        # FastAPI: /api/state, /api/approve/{id}, /api/collect/{id}, static dashboard
    state.py         # builds the JSON the dashboard consumes
  scheduler.py
  costs.py           # logs every API call's tokens and rand cost to Cost table
config/
  niches.yaml
  pain_phrases.yaml  # "is there a tool", "I pay someone to", "I hate how", "any alternative to"
  settings.yaml      # kill thresholds, daily caps, fx rate
dashboard/
  index.html         # the game UI; read-only template provided, you make it live
data/
logs/
```

## Pipeline rules

### Scouts
- One Niche row = one scout. Each night, for each active niche, every source
  adapter runs with the niche's keywords and competitor names.
- Raw Signal rows are kept for 30 days with url, source, text, score fields.
- `distill.py` turns a niche's signals into at most 5 Card rows per night.
  A Card must have: title, problem, quote (verbatim), url, pay_evidence
  (text), pay_amount (numeric if found), source. No url, no card.
- Scout cost cap: R0.60 per niche per night. Over cap, skip and log.

### Gate of Proof (`gates/proof.py`)
Kill unless at least one of:
- a job post or gig with a price for this exact task,
- a paid competitor with pricing and evidence of complaints,
- a direct request to pay in a forum, with upvotes or replies.
Output: score 0-10, verdict, reasoning, evidence list. Score < 6 is killed.
Killed cards are archived, never deleted.

### Gate of Craft (`gates/craft.py`)
Kill if any of: needs sales calls, physical inventory, a licence, personal
data categories requiring registration, a marketplace with two sides to
seed, more than 7 build-days, or ongoing human support. Output same shape.

### Smoke test
- For each card passing both gates, generate a landing page: headline,
  three benefits, one price, one "Buy" button that records a `buy_click`
  event then shows "We are onboarding founders this week, leave your email".
- Draft ad set JSON (3 variants, audience, R200 budget, 48 h).
- Deploy page to `{slug}.{FACTORY_DOMAIN}`. Status = `awaiting_funding`.
- Nothing is spent until `/api/approve/{id}` is hit from the dashboard.
  After approval, if `META_ADS_ENABLED=true`, create the campaign via the
  Marketing API, else print the manual steps to logs and the dashboard.
- Win condition: buy_click / visitors >= 5% with >= 150 visitors.
  Losers archive with their numbers.

### Build
- Winners get `build/spec.py`: a full CLAUDE.md, data model, stack, pricing,
  payment provider (Paystack default), first 5 SEO pages. Written to
  `ventures/{slug}/CLAUDE.md`. The human starts that Claude Code session.
- Venture rows track status: building, live, paused. Revenue is entered via
  Paystack webhook or manually through `/api/collect`.

### Dashboard contract
`/api/state` returns:
```
{ gold, elixir_month, scouts_active,
  buildings: [ {id, kind: hq|mine|site|test|camp|gate|archive, name, level,
                desc, kv: [[v,label]x3], actions: [{label, endpoint, style}],
                pile: 0-3, rate: 0-1} ],
  treasury: [ {name, sub, projected_30d, kind: income|soon|cost, pct} ],
  net_30d, concentration_pct, side_quests: [str] }
```
Convert `dashboard/index.html` from its hard-coded `B` array and treasury
rows to render from this JSON, polling every 60 s. Keep the visuals exactly;
change only the data source. Buttons call the endpoints in `actions`.

## Working style
- Build in this order: models + seed -> reddit + hn scouts -> distill ->
  proof gate -> craft gate -> api/state + live dashboard -> remaining
  sources -> smoke -> build spec -> scheduler.
- After each stage, run it for real on 5 niches and show me actual cards.
- Every Claude call goes through `costs.py`. Print nightly rand total.
- Never invent evidence. If a source fails, the card does not exist.
- No external dependency beyond the stack list without asking.
- Keep files under 300 lines.

# Venture Factory — operational brief

## What this is
An agent factory that runs unattended and aims to build a side income. Six
departments of agents work in a cycle: Research finds niches people already
pay in, anywhere in the world; Deep Dive studies each one and prices what it
would cost to start; Training builds and certifies a squad of agents for the
niche; Operations runs it; the Treasury counts every rand per niche; the
Warden oversees all of it, fixes what it can and reports the rest.

Commerce comes first: physical products for South African buyers, sold from
small batches of stock held by a fulfilment warehouse (`config/commerce.yaml`).
Digital and content niches keep running at a lower volume.

The dashboard is a MOBA-style arena (see "The arena") so the player can see
in real time which agents are working, where every niche is in the cycle,
and which niches make or lose money.

The human (the "player") does only what agents cannot: approve spending,
pass ID checks, own accounts, and answer the Warden's weekly report. Target:
about 20 minutes a week. Money is never spent and nothing is posted publicly
without a human click.

## Departments
| Department | Agents (roles) | Input | Output | Passes on when |
|---|---|---|---|---|
| Research | one scout per niche per source, Distiller, Proof gatekeeper, Craft gatekeeper | niches.yaml categories, global sources | Cards with verbatim evidence | Proof gate and Craft gate pass |
| Deep Dive | Demand analyst, Competitor analyst, Economics analyst, Risk analyst, Capital estimator | Cards past Craft | Dossier: demand, competitors, price, margin, start-up capital, risks | Economics gate passes |
| Training | Playbook writer, Catalogue builder, Prompt engineer, Simulator, Examiner, Certifier | Smoke-test winners | Certified squad + venture CLAUDE.md | Every squad agent scores 90%+ with no rule broken |
| Operations | Smoke-test builder; per live niche a squad: Store, Content, Ads, Support, Bookkeeper (commerce: Stock instead of Content) | Dossiers, certified squads | Smoke tests; daily running of live niches | Monthly review keeps it |
| Treasury | Ledger, Auditor | Sales, refunds, ad and agent bills | Revenue, costs, profit per niche | Books match providers |
| Warden | Health check, Cost guard, Fixer, Reporter | Every AgentRun, Cost and GateResult | Automatic fixes, alerts, weekly + monthly reports | n/a (oversees) |

Departments not built yet show on the map as construction sites. Never show
an agent as working unless an AgentRun row says it is.

## The arena (dashboard map)
A square, top-down map like a MOBA:
- **Your base** bottom-left (HQ and Treasury). **The Market** top-right: live
  niches sit there as gold mines and send gold back down their lane.
- **Three lanes**, one per business-model family. Top = Digital (digital
  products, micro-SaaS). Mid = Commerce (local-stock stores; dropshipping and
  print-on-demand are switched off).
  Bot = Content (newsletters, affiliate sites). A card's lane comes from its
  business model.
- **Six towers per lane** = the six checks a niche must pass, in order:
  1 Proof, 2 Craft, 3 Economics (free, on your side, green), then
  4 Fund test, 5 Smoke test, 6 Certify & fund launch (money at stake, red).
- **The river** runs corner to corner between towers 3 and 4: nothing crosses
  it without your gold.
- **Jungle camps** = departments: Research and Deep Dive on your side,
  Training and Operations on the market side, the Warden at the centre where
  mid lane crosses the river, the Archive at the river mouth.
- **Units**: each card is a unit standing at the tower it is waiting at.
  Killed cards fall at that tower and go to the Archive. Agent units (in
  their department colour) walk from their camp to the tower or niche they
  are working on, driven only by real AgentRun rows. "Replay last night"
  plays back the night's AgentRuns at speed.

## The cycle (start to finish)
Card status -> tower:
1. `scouted` waits at tower 1. Proof gate -> `proof_passed` or `killed_proof`.
2. `proof_passed` at tower 2. Craft gate -> `craft_passed` or `killed_craft`.
3. `craft_passed` at tower 3. Deep Dive + Economics gate -> `dive_passed` or `killed_dive`.
4. `dive_passed` -> smoke prep -> `awaiting_funding` at tower 4 (blocked on you).
5. `testing` at tower 5 after you fund the test. Settles `won` or `lost` (archived).
6. `won` at tower 6: Training writes the brief and certifies the squad -> `certified`, or
   `training_failed` (you retry or leave it). You fund the launch -> `building`.
7. `building` / `live`: a mine at the Market. Operations runs it; Treasury counts it.
8. Monthly Warden review: scale, hold or kill. Killed niches go to the Archive.
Killed or lost cards are archived, never deleted.

## Money rules
- Two money gates per niche, both human clicks: Fund test (smoke budget:
  150 visitors at the test market's cost per click, R700 in South Africa, at
  most R1,000) and Fund launch (the rest of the start-up capital, only after a
  smoke-test win and a certified squad). Launching buys nothing: it returns
  the shopping list. For a local-stock product the button is FUND STOCK and
  includes the first stock batch, capped by `caps.stock_batch_zar` (R5,000).
- `caps.niche_capital_zar` is the most a niche may ask for to start; above it,
  the Economics gate kills.
- The R20 stage cap and R0.60 scout cap from Phase 1 stay. The Warden adds a
  daily agent-spend cap (`warden.daily_cap_zar`, R50) it cannot raise itself.
  Training is capped at R12 per squad (`caps.training_zar_per_squad`).

## Stack (do not deviate without asking)
- Python 3.11, `uv` for deps
- SQLite via `sqlmodel`, file at `data/factory.db`
- `anthropic` SDK. Scouts, the Demand analyst's query planner and the
  Simulator use `claude-haiku-4-5`. Gatekeepers, Deep Dive judges, page
  writer, Training's writers and the Examiner use `claude-sonnet-4-6`. Squad
  agents use the model set per role in `config/squad.yaml`. Never Opus.
- `httpx` for HTTP, `praw` for Reddit, `feedparser` for RSS, `playwright`
  only where an API does not exist
- Official APIs only for marketplaces: App Store (iTunes Search + reviews
  RSS, no key), Etsy Open API v3 (`ETSY_API_KEY`), eBay Browse API
  (`EBAY_CLIENT_ID` / `EBAY_CLIENT_SECRET`). No scraping that breaks a site's
  terms (this rules out Amazon and TikTok pages until official access exists).
- FastAPI serving `/api/state` and the static dashboard, port 8000
- APScheduler: scouts 01:00 SAST; Warden retries, gates, Deep Dive, smoke
  prep and Training 02:00; Warden check every 15 min; Monday report 07:00; dashboard live
- Email via the standard library's smtplib (optional, SMTP_* in .env)
- `.env` for secrets, never committed

## Repo layout
```
factory/
  models.py        # Niche, Signal, Card, GateResult, Dossier, SmokeTest, TrackEvent,
                   # Build, Venture, Cost, RunLog, AgentRun
  agents.py        # AgentRun logging + department rosters (who exists, who is working)
  seed.py, costs.py, config.py, night.py, scheduler.py
  market/          # official marketplace probes shared by scouts and Deep Dive
    appstore.py etsy.py ebay.py base.py
  scouts/          # Research: runner.py, distill.py, sources/{reddit,hn,appstore,...}.py
  gates/           # proof.py, craft.py, rubric.md, run.py
  dive/            # Deep Dive: demand.py, economics.py, risk.py, capital.py, run.py
  smoke/           # page.py, ads.py, budget.py, deploy.py, track.py, run.py
  commerce/        # landed.py: SA landed cost, cost per order, break-even, first batch (make landed)
  build/           # spec.py (venture brief), launch.py (fund launch: venture + shopping list)
  training/        # Training: tables.py (Squad, SquadAgent), writer.py, exam.py, run.py
  api/             # server.py, state.py, arena.py (map JSON), panels.py
  warden/          # health.py, fixer.py, holds.py, incidents.py, report.py, mailer.py, tables.py, run.py
config/
  niches.yaml, pain_phrases.yaml, settings.yaml
  business_models.yaml   # lanes, models, fee/cost assumptions, capital lines
  squad.yaml             # squad roles and models, guardrails, exam rules
  commerce.yaml          # SA tax, duty, freight, warehouse, courier, conversion benchmarks
dashboard/
  index.html       # layout, styles, polling
  app.js           # panels, alerts, feed, departments, niches, treasury
  arena.js         # the MOBA map renderer (also used by the blueprint preview)
```

## Pipeline rules

### Research (scouts)
- One Niche row = one scout per enabled source. Raw Signal rows kept 30 days.
- `distill.py` (Haiku) turns a niche's signals into at most 5 Cards a night,
  each with a guessed business model (and so a lane). Quote and pay evidence
  must be verbatim substrings of the stored signal. No url, no card.
- Scout cost cap: R0.60 per niche per night. Over cap, skip and log.
- Active niches (`niche_limit`): the first 4 commerce niches, then the first 2
  others. Commerce niches search buying phrases (`commerce.yaml`), use Reddit
  only and name no competitor apps.

### Gate of Proof (tower 1)
Kill unless at least one of: a job post or gig with a price for this exact
task; a paid competitor with pricing and evidence of complaints; a direct
request to pay in a forum, with upvotes or replies. For a local-stock
product, a shop selling it with a price plus complaints that South African
buyers cannot get it counts as the second. Score 0-10, < 6 killed.
Evidence must be verbatim; a pass with no evidence left becomes a kill.

### Gate of Craft (tower 2)
Kill if any of: sales calls, holding or shipping stock ourselves (a
fulfilment warehouse holding a local-stock product is allowed), a licence,
personal data categories requiring registration, a two-sided marketplace to
seed, more than 7 build-days, or ongoing human support. A local-stock product
is also killed if it needs ICASA or NRCS approval, is food, health or a
weapon, is branded or a copy, or is over 5 kg, fragile or sold in sizes.

### Deep Dive and Economics gate (tower 3)
- Demand analyst: Haiku plans up to 3 search terms; probes App Store, Etsy and
  eBay in the configured markets; records counts, prices, ratings with urls.
- Competitor analyst: top competitors with prices, ratings and 1-2 star
  review quotes, from the probes and the niche's named competitors.
- Economics analyst (Sonnet): picks the business model and a price point
  anchored to a cited evidence item; unit cost comes from cited evidence or
  is marked as an assumption from business_models.yaml.
- Risk analyst (Sonnet): legal, platform and IP risks; any `hard_kill` risk kills.
- Capital estimator (code): start-up lines from business_models.yaml plus
  samples and ad test; break-even sales = capital / unit profit.
- Economics gate (code): score >= 7, margin >= the model's minimum, capital
  <= `niche_capital_zar`, break-even <= `max_break_even_sales`, no hard kill.
- Local stock: the shop price is in rand (ending in 9) and `commerce/landed.py`
  costs it: supplier price (evidence, else 15% of price), freight, duty, import
  VAT, clearing, warehouse, pick and pack, courier, payment, store fee, returns.
  Its gate replaces the margin rule: at most 2.5% of visitors may need to buy
  to break even, and the stock cap must buy a first batch of 20+ units.
  Break-even sales count only money that does not come back (not the stock);
  profit per order is judged at the top-fifth conversion rate.
- Every number in a Dossier is tagged `evidence` (with url) or `assumption`.

### Smoke test (towers 4-5)
- For each `dive_passed` card: landing page at the Dossier's price, three
  benefits, one Buy button that records `buy_click` then shows "We are
  onboarding founders this week, leave your email" (local stock: "we will tell
  you the day it ships"). 3 ad variants, 48 h, budget from `smoke/budget.py`.
  Ads target `smoke.market` (ZA) and pages show the costed price in rand.
- Deploy to `{slug}.{FACTORY_DOMAIN}`. Status `awaiting_funding`. Nothing is
  spent until `/api/approve/{id}`. If `META_ADS_ENABLED=true` create the
  campaign, else print the manual steps to logs and the dashboard.
- Win: buy_click / visitors >= 5% with >= 150 visitors, and the ads must pay:
  a click-win whose cost per real sale (cost per visitor / (buy-click rate x
  0.4)) is above what an order leaves is lost. Losers archive; every test
  records why it settled (`result`).

### Training and launch (tower 6)
- Every `won` card goes to the Training Academy (02:00, after smoke prep).
- Playbook writer (Sonnet): the venture brief at `ventures/{slug}/CLAUDE.md`
  (data model, stack, pricing, Paystack, first 5 SEO pages) and the policies:
  brand voice, offer, refunds, delivery, escalation, FAQs, rules per role.
- Catalogue builder (Sonnet): what we sell, at the Dossier's price. Code
  corrects any other main price and notes it.
- Prompt engineer: writes each squad agent's instructions from a template
  (facts, catalogue, voice, policies, role rules). The guardrails in
  `config/squad.yaml` close every prompt word for word and survive rewrites.
- Squad: Store (Haiku), Content (Sonnet), Ads (Sonnet), Support (Haiku),
  Bookkeeper (Haiku). Commerce squads have a Stock agent (Haiku) instead of
  Content; a local-stock winner gets a store brief instead of a build brief.
- Simulator (Haiku): 5 drills per agent, at least 2 of them try to make it
  break a rule. Each agent answers on its own model. Examiner (Sonnet) scores
  every drill 0-10 and flags broken rules. A missing answer scores 0.
- Pass: average 90%+ and no rule broken. A failed agent is rewritten once and
  retakes (2 attempts). Certifier: all pass -> `certified`; otherwise
  `training_failed`, a needs-you item (retry from the map, or leave it).
- Files: `ventures/{slug}/squad/` holds each agent's instructions,
  catalogue.json, policies.json and exams.md.
- Fund launch (`/api/launch/{card_id}`, a human click, certified cards only):
  creates the Venture (`building`, a mine at the Market), prepares the folder
  (git init) and returns the shopping list: the Dossier's capital lines minus
  the smoke test (FUND STOCK also writes `stock/first-order.md`, a draft the
  owner places). Nothing is bought automatically. The human starts the
  build session; the squad stands by until Operations runs it (Phase 5).
- Venture rows: building, live, paused. Revenue via Paystack webhook or `/api/collect`.

### Warden (Phase 3)
- Health check every 15 minutes and after every night, itself an AgentRun.
  It records incidents with an outcome: `fixed` (the Warden handled it),
  `needs_you` (only a human can) or `watching`. Cleared conditions resolve
  themselves; a human can mark an incident handled from the dashboard.
  Tower 6 checks: a squad not certified, or a certified squad waiting more
  than 7 days for launch money, is needs-you.
- The Fixer may only: close jobs still "running" after 2 hours, retry a scout
  job that failed with a temporary error (429, 5xx, timeout) once per niche per
  night, pause a source that failed in every niche on the last 2 runs (24 h),
  and run a missed night once (only if the factory has run before).
- Cost guard: `warden.daily_cap_zar` in settings.yaml, enforced in `costs.call`
  for every Claude call (DailyCapReached stops all stages for the day). Only a
  human can raise it.
- Reporter: Monday 07:00 SAST weekly report and a monthly review on the 1st,
  built from the database with no model call: decisions for you, money,
  niches, pipeline, done without you, watching, sources. Saved to the
  WardenReport table and data/reports/, shown on the dashboard, emailed when
  SMTP is configured. Needs-you incidents are emailed once each.
- The Warden never spends, approves, publishes, deletes data, or writes
  settings.yaml.

### Agent activity
Every agent's unit of work is wrapped in `agents.run(dept, role, ...)`, which
writes an AgentRun row (start, finish, status, one-line summary, rand cost,
lane and tower when it works on a card). The dashboard draws only these.

## Dashboard contract
`/api/state` returns the Phase 1 keys (`gold, elixir_month, scouts_active,
buildings, treasury, net_30d, concentration_pct, side_quests`) plus:
```
agents_total, departments: [{id, name, agents, working, built}],
arena: { lanes: [{id, name, position: top|mid|bot}],
         towers: [{n: 1-6, id, name, side: free|money, waiting, passed_7d, killed_7d}],
         units: [{card_id, title, lane, tower: 1-6, state: waiting|blocked|testing|dead,
                  status, actions: [{label, endpoint, style}], dossier?, smoke?,
                  squad?: {status, score, notes, agents: [{name, model, score, breaches, status, version}]}}],
                  # dossier.stock and dossiers[].stock (local stock): {landed_zar, contribution_zar,
                  #   break_even_conversion, batch_units, batch_zar}
         mines: [{venture_id, name, lane, revenue_30d}],
         runs: [{id, dept, role, subject, lane, tower, started, finished, status, summary}] },
niches: [{name, lane, model, stage, revenue, costs, profit, capital}],   # to date, rand
dossiers: [{card_id, title, model, lane, capital, lines, break_even, margin, score, verdict}],
warden: {checks_24h, fixes_7d, needs_you, watching, today_zar, daily_cap_zar, holds, incidents, report},
alerts: [{id, kind, label, subject, detail, action, outcome}]   # open needs-you incidents
```
`buildings` carries the panel for each camp, base and tower (id, name, level,
desc, kv, actions). Buttons call the endpoints in `actions`. Poll every 60 s.

## Build phases
1. Research scouts (Reddit, HN), Proof + Craft gates, smoke prep, dashboard. Done.
2. Deep Dive + Economics gate + capital estimator, App Store/Etsy/eBay probes,
   AgentRun logging, MOBA arena dashboard. Done.
3. Warden v1: health checks, cost guard, retries, source pauses, catch-up,
   Monday report and monthly review, alerts, optional email. Done.
4. Training Academy: venture brief, policies, catalogue, squad instructions,
   drills, exams, certification, fund launch with a shopping list. Done.
5. Commerce, South Africa first: local-stock model, landed costs, SA product
   rules, market-priced tests and the customer-cost check, FUND STOCK. Done.
6. Operations squads (commerce first) and the store, warehouse and courier
   connections.
7. Treasury sync: Paystack, Shopify, the warehouse, Meta, agent bills per niche.
8. More business models.

## Working style
- After each stage, run it for real on the active niches and show real output.
- Every Claude call goes through `costs.py`. Print the nightly rand total.
  Stop and report if a stage would cost more than R20.
- Never invent evidence. If a source fails, the card or number does not exist.
- No external dependency beyond the stack list without asking.
- Keep files under 300 lines. Record every default in NOTES.md.

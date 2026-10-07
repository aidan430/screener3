# NOTES: first-run decisions and status

Each default below was chosen without asking, as the kickoff instructed. Change any of them in
`config/settings.yaml` or tell me and I will rework it.

## Phase 3: the Warden (2026-10-07)

| Step | Result |
|---|---|
| `make night` | Now ends with a Warden health check, even when a stage stopped early. Ran for real twice. Reddit and HN were refused (403) in every niche on the last 2 runs, so the Warden paused both for 24 hours and flagged them as needing you. The App Store failed in 4 of 5 niches (watching). The missing `ANTHROPIC_API_KEY` needs you. |
| `make warden` | Runs a health check now and prints what is fixed, what needs you and what is being watched. |
| `make report` | Writes the weekly report now. The real one: "Week 41: 3 decisions for you, R0.00 agent spend". Its "Done without you" lists the two paused sources. |
| `make schedule` | Adds the Warden check every 15 minutes, the Monday 07:00 report and the monthly review on the 1st at 07:30. Temporary source failures are retried at 02:00. |
| Dashboard | The Warden camp is built: a beacon on its island, and beams to every camp while a real check runs. A red banner lists what only you can do, each with "I handled it". The Warden panel has run-check, write-report and release-sources buttons and a link to the latest report. |
| `make test` | 38 offline tests pass (11 new for the Warden). |

### Phase 3 defaults (all in `config/settings.yaml -> warden`)
- **Daily agent-spend cap: R50 per SAST day**, about 3× a normal night for 5 niches. It is
  enforced in `costs.call` before every Claude call, so it covers every department. When
  it is reached, every stage stops with "daily agent-spend cap" and work resumes after
  midnight. The Warden reads this value and never writes it.
- **Health checks** run every 15 minutes and after every night. Each one is an
  `AgentRun`, so it shows on the map; the activity feed shows only the latest.
- **Stale jobs:** a job still "running" after 2 hours is closed as failed (its process died).
- **Retries:** a scout job that failed with 429, 5xx or a timeout is retried once per
  niche per night. Manual `make night` waits 60 s first; the scheduler retries at 02:00.
  A 403 is not temporary, so it is never retried.
- **Paused sources:** a source that failed in every niche on the last 2 scouting runs is
  paused for 24 hours and scouts skip it. If the error was 401 or 403, the incident is
  "needs you", because it usually means a network block or missing credentials. You can
  release pauses from the Warden panel or with `uv run python -m factory.warden.run release`.
- **Missed night:** if no scouting run has happened by 03:30 SAST, the next scheduled check
  runs the night once. This only happens if the factory has run before, so a fresh
  install doesn't start a night on its own.
- **Waiting on you:** a smoke test waiting more than 7 days for your R200 is "needs you".
  So is a funded test with 0 visitors after 24 hours.
- **Spend spike:** tonight's spend above 2× the average of the previous nights (with at
  least 3 nights of history and over R5) is "watching".
- **Reports** use no model call: they cost R0 and can only state what is in the database.
  - Revenue appears as a total to date; weekly revenue needs the Treasury (Phase 6).
  - Monthly verdicts: scale if profit > 0 and revenue is at least 3× costs; kill if it has
    lost money for 30+ days; otherwise hold.
- **Email** is optional, using Python's built-in `smtplib` (no new dependency). Reports and
  each needs-you incident are emailed once when `SMTP_HOST` and `REPORT_EMAIL_TO` are set.
  Otherwise reports are only on the dashboard (`/reports/{id}`) and in `data/reports/`.
- **Dismissing:** "I handled it" closes an incident; if the problem is still there, the
  next check opens it again.
- **The Warden never** spends, approves, publishes, deletes data, or writes
  `settings.yaml`. Losing ventures get a kill recommendation in the report, not an
  automatic pause, until Operations squads exist (Phase 5).

## Phase 2: Deep Dive and the arena (2026-10-07)

| Step | Result |
|---|---|
| CLAUDE.md | Rewritten for six departments, the arena (lanes, towers, river), the cycle from first signal to final verdict, two money approvals, dashboard contract v2 and the build phases. |
| `make dive` | Runs five Deep Dive analysts on each card at tower 3, writes a Dossier and applies the Economics gate. |
| `make night` | Now scout → gates → Deep Dive → smoke prep → state. Ran for real: Reddit, HN and the App Store all refused (HTTP 403 from this container's proxy), so 0 cards and R0.00. The 20 research jobs are logged as agent runs. |
| `make serve` | New MOBA arena dashboard, still read only from `/api/state`. |
| `make test` | 27 offline tests pass: pipeline 9, Deep Dive 7, marketplaces 5, arena 6. |

### Phase 2 defaults
- **Lanes:** top Digital (digital products, micro-SaaS), mid Commerce (dropshipping,
  print-on-demand), bottom Content (newsletters, affiliate sites). A card with no
  business-model guess stands on the mid lane, marked "guessed".
- **Towers:** 1 Proof, 2 Craft, 3 Economics are free checks on your side (green).
  4 Fund test, 5 Smoke test, 6 Certify and fund launch are past the river, where money is
  at stake (red).
- **Order:** the smoke test now comes before Training, so squads are only built for niches
  that won a test. The blueprint preview showed Training first. A niche needs two money
  approvals: the test budget, then the launch capital.
- **Craft gate:** now allows dropshipping and print-on-demand, because the supplier stores
  and ships. It still kills anything where we hold our own stock. Rubric version
  2026-10-07.1.
- **Sources:**
  - The App Store (no key needed) is now a Research source: the latest 1-2 star reviews of
    each niche's named competitor apps.
  - Deep Dive checks the App Store, Etsy and eBay, depending on the business model.
  - Markets: App Store us, gb, au, ca, de (za first for ZA niches); eBay US, GB, DE, AU.
- **Not built:**
  - Google Trends: keyword interest has no open official API. The unofficial endpoints
    pytrends uses are rate limited and not meant for automated use.
  - Amazon and TikTok: no open API, and scraping breaks their terms.
  - Upwork, Fiverr and HelloPeter stay TODO stubs.
- **Deep Dive cost:**
  - Haiku plans up to 3 search terms per card. The Sonnet Economics analyst gets up to
    1,200 output tokens and the Sonnet Risk analyst 600.
  - Cap: R1.50 per card (`caps.dive_zar_per_card`), plus the R20 stage cap.
  - Expected cost is about R0.80-1.00 per card.
- **Price anchoring:** the price must cite an evidence item, in the same currency, and be at
  most 25% above it. Otherwise the gate kills.
- **Unit cost and fees:**
  - Unit cost comes from cited evidence if any. There's no supplier source yet, so it
    usually falls back to the model's `unit_cost_pct` assumption.
  - Ad cost per sale = `cac_pct` of price. Fees = `fee_pct`. Both are assumptions.
- **Start-up capital:** the model's fixed lines + samples × unit cost + R200 smoke test +
  the first ad test after a win. All values are labelled assumptions in
  `config/business_models.yaml`; edit freely.
- **Economics gate:** passes only with score ≥ 7, margin ≥ the model's minimum, capital
  ≤ R10,000 (`caps.niche_capital_zar`) and break-even within 80 sales.
- **Payback days:** not shown. There's no sales-velocity data before a smoke test, so a
  Dossier shows break-even sales instead. The payback days in the blueprint preview were
  sample data.
- **FX (`fx_zar`):** USD 18.50, GBP 24.50, EUR 21.50, AUD 12.00, CAD 13.50. These are rough;
  edit them.
- **Agent runs:**
  - Every scout, the Distiller, both gatekeepers, the five analysts, the smoke-test builder
    and the playbook writer write an `AgentRun` row. The map draws only these.
  - A row still "running" after 2 hours counts as failed (its process died).
  - Each run's cost comes from the process's spend counter.
- **Agent counts are real:**
  - Research = active niches × enabled sources + Distiller + 2 gatekeepers (18 today).
  - Deep Dive 5, Training 1, Operations 1.
  - Treasury and Warden have 0 and appear as construction sites until Phases 6 and 3.
- **Arena behaviour:**
  - Idle agents stand by their camp, working agents stand at the tower they work on, and
    finished ones walk home over 9 seconds.
  - "Replay last night" plays the last 36 hours of agent runs in 40 seconds.
- **Niche money table:** revenue, costs (that niche's agent spend plus any funded test
  budget) and profit, to date. Figures per 30 days arrive with the Treasury in Phase 6.
- **Database upgrade:** on start, missing columns are added to an existing
  `data/factory.db` and new tables are created. Nothing is deleted.

## Phase 1 status (2026-10-03)

| Step | Command | Result |
|---|---|---|
| 1 | `make setup`, `make scout` | Built and ran for real on the 5 niches. **0 cards**: every Reddit and HN request was refused (HTTP 403) by the build container's egress proxy. No `ANTHROPIC_API_KEY` is set either. No evidence came in, so per the rules no card was created. |
| 2 | `make gates` | Built and ran: 0 cards waiting, R0.00. |
| 3 | `make serve` | Dashboard live at http://localhost:8000, rendering only from `/api/state`. Today it shows the real (empty) state: 5 scouts, R0 elixir, and the camp text "reddit failed in 5/5 niches, hn failed in 5/5 niches". |
| 4 | `make night` | Runs scout -> gates -> smoke prep -> state refresh end to end and halts on the R20 stage cap. |
| - | `make test` | 9 offline tests pass. They use invented posts and a fake Claude client in a temp DB, never `data/factory.db`. They exercise every stage: verbatim checks, caps, `awaiting_funding` plus manual steps, `/api/state`, approve, the winner spec. |

**To get real cards:** run `make setup && make night` on a machine with open internet and an
`ANTHROPIC_API_KEY` in `.env`. If you use this cloud environment, allow `www.reddit.com`,
`oauth.reddit.com` and `hn.algolia.com` in its network settings, and add `ANTHROPIC_API_KEY`
as an environment variable.

## What only you can do

1. **Anthropic API key**: put it in `.env` as `ANTHROPIC_API_KEY`. Nothing that thinks runs without it.
2. **Reddit API app**: at https://www.reddit.com/prefs/apps create a "script" app, then set
   `REDDIT_CLIENT_ID`, `REDDIT_CLIENT_SECRET` and `REDDIT_USER_AGENT` (`venture-factory/0.1 by u/<you>`).
   Without it the scout falls back to the public JSON search, which is more rate-limited.
3. **Etsy developer app**: at https://www.etsy.com/developers create an app and set
   `ETSY_API_KEY` to the value Etsy says to send in the `x-api-key` header. Without it Deep
   Dive skips Etsy and notes why.
4. **eBay developer app**: at https://developer.ebay.com create a production keyset and set
   `EBAY_CLIENT_ID` and `EBAY_CLIENT_SECRET`. Without it Deep Dive skips eBay.
5. **Factory domain**: buy it and set `FACTORY_DOMAIN`. Pages go to `{slug}.{FACTORY_DOMAIN}`.
   Add a wildcard `*` CNAME to `cname.vercel-dns.com`.
6. **Vercel project**: create a team or project and a token. Set `VERCEL_TOKEN` (and
   `VERCEL_SCOPE` for a team), add the domain to the project, and run `npm i -g vercel` on the
   factory host.
7. **Plausible account**: create it and an API key (`PLAUSIBLE_API_KEY`). Add the site(s) for
   your domain and a custom-event goal named `buy_click`.
8. **Meta developer app**: create the app and a Business ad account, pass the ID and phone
   checks, and get a system-user token with `ads_management`. Set `META_ACCESS_TOKEN` and
   `META_AD_ACCOUNT_ID`. Keep `META_ADS_ENABLED=false` until the Marketing API code is written
   (it is a TODO; approvals print manual steps).
9. **Paystack webhook**: complete Paystack KYC, set `PAYSTACK_SECRET_KEY`, and point the
   webhook at `https://<factory host>/api/paystack/webhook`. Charges must carry
   `metadata.venture = <venture slug>`.
10. **Email for the Warden (optional)**: set `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`,
    `SMTP_PASSWORD` and `REPORT_EMAIL_TO` (for Gmail, use an app password). Without them,
    reports stay on the dashboard.
11. **Fund each smoke test and each launch**: click FUND TEST on the dashboard. This is the only path to spend.

## Defaults I chose

### Layout and stack
- The factory lives at the repo root (`factory/`, `config/`, `dashboard/`, `Makefile`).
  The `files (1).zip` that was already in the repo is unrelated and left alone.
- Extra dependencies, needed to run the listed stack: `uvicorn` (to serve FastAPI) and
  `pyyaml` (for the YAML config). Tests use stdlib `unittest`, so there is no pytest.
  `playwright` and `pytrends` are not installed yet because their adapters are stubs. pytrends
  is not in the stack list, so it needs your OK.
- Model IDs are exactly as in CLAUDE.md: `claude-haiku-4-5` for scouts and
  `claude-sonnet-4-6` for the judge, page and spec writers. Opus raises an error in
  `costs.price`. FYI: `claude-sonnet-5-5` is newer *and* cheaper ($2/$10 vs $3/$15 per M
  tokens). The stack says not to deviate, so I have not switched; it is a one-line change in
  settings.yaml if you want it.
- Pricing (USD per M tokens): Haiku 4.5 $1 in / $5 out; Sonnet 4.6 $3 / $15.
- **FX: R18.50 per USD** (now part of the `fx_zar` table). Every Cost row stores both USD and rand.
- Times are stored as timezone-aware UTC. A "night" is the SAST calendar date.
- The API binds to 127.0.0.1 unless `HOST` is set.

### Costs and caps
- Every Claude call goes through `costs.call()`. Before sending, it estimates the worst case
  (prompt chars / 3.5 input tokens, plus all of `max_tokens` as output). Afterwards it logs a
  Cost row and prints a `[cost]` line.
- **R20 stage cap**: each of `scout`, `proof`, `craft`, `smoke` and `spec` is its own stage.
  If the next call's worst case would push the stage past R20, it raises before sending. The
  stage stops with `STOPPED: ...` and `make night` halts.
- **R0.60 scout cap per niche per night**: distill drops the lowest-ranked signals until the
  worst case fits. If it still cannot fit, the niche is skipped and logged.
- Expected spend with 5 niches is about R0.25 per niche for distill and about R0.28 per card
  per gate (2k tokens in, 600 out on Sonnet), so a full night is roughly R8-15.

### Scouts
- Reddit uses praw if credentials exist, otherwise `https://www.reddit.com/r/{sub}/search.json`.
  Per subreddit it runs two queries: the niche keywords OR'd together, and the first 8 pain
  phrases OR'd together. Restricted to the subreddit, past year, relevance sort, 25 results,
  with a 2 s pause between requests. It reads posts only (not comment threads) for now.
- HN uses the Algolia API with no key. Per keyword it runs one `ask_hn` search and one
  `comment` search. Per competitor it runs one `"<name> alternative"` search. Window is 365 days.
- A signal is kept only if its text contains a keyword, competitor or pain phrase.
  Rank = 3 × pain-phrase hits + other hits + 2 if money is mentioned + log(score) + 0.5 × log(replies).
- Signals are purged after 30 days, except ones a card points at (cards keep their evidence).
- `config/pain_phrases.yaml` has 12 phrases (the 4 from CLAUDE.md plus 8 similar ones).
- Upwork, Fiverr, appstore, HelloPeter and Trends are stubs that raise `NotImplementedSource`.
  Each has a TODO and an implementation plan, and is disabled in `settings.yaml -> sources`.

### Distill (no invented evidence)
- The top 25 unused signals per niche go to Haiku, each truncated to 700 chars.
- Haiku must cite a signal id. The code then checks that `quote` is a **verbatim substring**
  of that signal (whitespace and curly quotes normalised). Otherwise the card is dropped.
- `pay_evidence` must also be verbatim or it is blanked. `pay_amount` is kept only if that
  number appears in `pay_evidence`.
- The card's url always comes from the stored signal, never from the model. Each signal makes
  at most one card, and a signal is never reused on a later night.

### Gates
- Rubrics live in `factory/gates/rubric.md` (version `2026-10-03.1`), loaded at runtime.
  Every GateResult stores the rubric version.
- The judge sees only the card and its source post (up to 4,000 chars). For proof it may use
  outside knowledge only to recognise that a named product is paid.
- Proof: evidence snippets must be verbatim from that material. Invented snippets are
  discarded, and a "pass" with no surviving evidence becomes a kill.
- Craft runs only on proof survivors and uses the same 0-10 scale (kill below 6).
- Killed cards get status `killed_proof` or `killed_craft`; nothing is ever deleted.

### Smoke tests
- One Sonnet call per surviving card returns structured copy (name, headline, subhead,
  3 benefits, one price, CTA) plus 3 ad variants and targeting. The page itself is a fixed
  single-file template, so tracking and the Buy flow always work. Prices for ZA niches are
  in rand.
- Buy click: records `buy_click`, then shows "We are onboarding founders this week, leave
  your email". Emails are stored in `TrackEvent.detail`. That is personal data (POPIA), so
  only use it to contact those people about this product.
- Tracking: a Plausible custom event when `FACTORY_DOMAIN` is set, plus a beacon to
  `/api/event/{slug}` when the page is served locally.
- Deploy: Vercel CLI when `VERCEL_TOKEN` and `FACTORY_DOMAIN` are set. Otherwise the page is
  served at `http://localhost:8000/pages/{slug}/`, the status still becomes `awaiting_funding`,
  and the manual steps warn that ads cannot point at localhost.
- The ad set is 3 variants, R200 lifetime budget, 48 h, Traffic objective, Advantage+
  placements.
- `/api/approve/{id}` (POST, with a confirm dialog on the dashboard) is the only spend path.
  With `META_ADS_ENABLED=false` it prints the manual steps to the logs and the dashboard.
  The Marketing API call is a TODO even when the flag is true.
- Settling a test: **won** once there are ≥150 visitors and ≥5% buy-clicks. **Lost** if it
  is below 5% after 48 h with ≥150 visitors, or never reaches 150 visitors within 96 h.
  Losers archive with their numbers.
- **`make night` includes smoke prep** (scout -> gates -> smoke -> state refresh). Smoke prep
  spends no ad money, and including it is what lets survivors reach `awaiting_funding`
  overnight.

### Build
- Winners get `ventures/{slug}/CLAUDE.md` from Sonnet, plus a `git init`'d folder and a
  Venture row (status `building`). You start that Claude Code session; the exact command is
  printed. `ventures/` is gitignored.

### Dashboard (Phase 1)
- Replaced in Phase 2 by the arena (`dashboard/index.html`, `arena.js`, `app.js`). See
  "Phase 2 defaults" above.

### Scheduler
- `make schedule` runs APScheduler in Africa/Johannesburg: scouts at 01:00, then gates, Deep
  Dive and smoke prep at 02:00, and a state snapshot to `data/state.json` every 5 min. `/api/state` is built
  live on each request, so the dashboard is always current.

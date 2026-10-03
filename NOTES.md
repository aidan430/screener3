# NOTES: first-run decisions and status

Each default below was chosen without asking, as the kickoff instructed. Change any of them in
`config/settings.yaml` or tell me and I will rework it.

## Status of tonight's run (2026-10-03)

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
3. **Factory domain**: buy it and set `FACTORY_DOMAIN`. Pages go to `{slug}.{FACTORY_DOMAIN}`.
   Add a wildcard `*` CNAME to `cname.vercel-dns.com`.
4. **Vercel project**: create a team or project and a token. Set `VERCEL_TOKEN` (and
   `VERCEL_SCOPE` for a team), add the domain to the project, and run `npm i -g vercel` on the
   factory host.
5. **Plausible account**: create it and an API key (`PLAUSIBLE_API_KEY`). Add the site(s) for
   your domain and a custom-event goal named `buy_click`.
6. **Meta developer app**: create the app and a Business ad account, pass the ID and phone
   checks, and get a system-user token with `ads_management`. Set `META_ACCESS_TOKEN` and
   `META_AD_ACCOUNT_ID`. Keep `META_ADS_ENABLED=false` until the Marketing API code is written
   (it is a TODO; approvals print manual steps).
7. **Paystack webhook**: complete Paystack KYC, set `PAYSTACK_SECRET_KEY`, and point the
   webhook at `https://<factory host>/api/paystack/webhook`. Charges must carry
   `metadata.venture = <venture slug>`.
8. **Fund each smoke test**: click FUND TEST on the dashboard. This is the only path to spend.

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
- **FX: R18.50 per USD** (`fx_usd_zar`). Every Cost row stores both USD and rand.
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

### Dashboard (`dashboard/index.html`)
- The visuals and drawing code are unchanged. The hard-coded `B` array and treasury rows are
  gone; everything comes from `/api/state`, polled every 60 s.
- The JSON has no coordinates, so the page maps `kind` to the original look (hq castle, camp
  tents, gate towers, archive ruins, test "?", site scaffolding, gold mine) and places
  buildings on fixed plots. The HQ, camp, 2 gates and archive sit where they were in the
  mockup. Mines, then sites, then tests fill 4 large plots, then 5 small ones; anything beyond
  that shows as "+N more off-map".
- Optional extra JSON keys the page uses: `lvl` (the badge text), `builders`, `foot`, `float`
  (floating "+R" text on mines), `msg` (for local-only buttons), and `cards`, `night` and
  `generated_at` (for debugging).
- Endpoints starting with `#` are local: `#side_quests` lists the side quests and `#msg`
  shows a message. All other actions are POSTs. Spend-style buttons ask for confirmation.
- The gate panels list tonight's real cards by name with their scores, plus the cards still
  waiting at each gate.
- Side quests are derived from missing env vars, plus one per test awaiting funding.
- Elixir pill = this calendar month's spend (UTC). The treasury's elixir row projects the
  last 7 days × 30/7.
- Fonts still load from Google Fonts, as in the mockup.

### Scheduler
- `make schedule` runs APScheduler in Africa/Johannesburg: scouts at 01:00, gates plus smoke
  prep at 02:00, and a state snapshot to `data/state.json` every 5 min. `/api/state` is built
  live on each request, so the dashboard is always current.

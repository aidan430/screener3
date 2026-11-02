# Paste this as your first message in Claude Code

Read CLAUDE.md, config/niches.yaml and dashboard/index.html fully.

Build the factory stage by stage in the order in CLAUDE.md. Do not stop to ask
questions; make sensible defaults and record every one in NOTES.md.

Constraints for this first run:
- Use only the first 5 niches in niches.yaml until I say otherwise.
- Reddit and HN sources only for tonight; stub the others with a clear TODO.
- META_ADS_ENABLED=false. Smoke tests must reach "awaiting_funding" and print
  the manual steps.
- Log every Anthropic call's cost. Stop and tell me if a single stage costs
  more than R20.

Deliver, in this order, showing me real output after each:
1. `make setup` and `make scout` that runs the 5 scouts and prints the Card rows
2. `make gates` that runs both gates and prints verdicts with reasoning
3. `make serve` with the dashboard at localhost:8000 reading /api/state, so the
   base shows real cards at the gates and real elixir spend
4. `make night` that runs scout -> gates -> state refresh end to end
5. A list of what only I can do: Reddit API app, Vercel project, factory domain,
   Plausible account, Meta developer app, Paystack webhook

Do not stop until the dashboard shows real cards from tonight's scouting.

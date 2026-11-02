# Dashboard contract

Moved out of CLAUDE.md (which keeps a pointer) to keep it under 300 lines.

`/api/state` returns the Phase 1 keys (`gold, elixir_month, scouts_active,
buildings, treasury, net_30d, concentration_pct, side_quests`) plus:
```
agents_total, departments: [{id, name, agents, working, built}],
arena: { lanes: [{id, name, position: top|mid|bot}],
         towers: [{n: 1-6, id, name, side: free|money, waiting, passed_7d, killed_7d}],
         units: [{card_id, title, lane, tower: 1-6, state: waiting|blocked|testing|dead,
                  status, actions: [{label, endpoint, style}], dossier?, smoke?,
                  squad?: {status, score, notes, agents: [{name, model, score, breaches, status, version}]}}],
                  # dossier.stock, dossiers[].stock: {landed_zar, contribution_zar, break_even_conversion, batch_units, batch_zar}
                  # dossier.service, dossiers[].service: {price_zar, cost_zar, margin_zar, margin, volume, what, channel}
         mines: [{venture_id, name, lane, revenue_30d}],
         runs: [{id, dept, role, subject, lane, tower, started, finished, status, summary}] },
niches: [{name, lane, model, stage, revenue, costs, profit, capital}],   # to date, rand
dossiers: [{card_id, title, model, lane, capital, lines, break_even, margin, score, verdict}],
warden: {checks_24h, fixes_7d, needs_you, watching, today_zar, daily_cap_zar, holds, incidents, report},
alerts: [{id, kind, label, subject, detail, action, outcome}]   # open needs-you incidents
```
`buildings` carries the panel for each camp, base and tower (id, name, level,
desc, kv, actions). Buttons call the endpoints in `actions`. Poll every 60 s.


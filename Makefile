# Venture Factory. All targets run inside the uv-managed venv.
PY := uv run python
export PYTHONUNBUFFERED=1

.PHONY: setup seed scout gates dive smoke train serve night schedule warden report state costs test

setup:            ## install deps, create .env from template, create DB, seed niches
	uv sync
	@test -f .env || (cp .env.example .env && echo "created .env from .env.example; add ANTHROPIC_API_KEY")
	@mkdir -p data logs
	$(PY) -m factory.seed

seed:
	$(PY) -m factory.seed

scout:            ## run the active scouts (reddit + hn) and print the Card rows
	$(PY) -m factory.scouts.runner

gates:            ## Gate of Proof then Gate of Craft, with verdicts and reasoning
	$(PY) -m factory.gates.run

dive:             ## Deep Dive: demand, competitors, economics, risk, start-up capital -> Economics gate
	$(PY) -m factory.dive.run

smoke:            ## prepare smoke tests for Deep Dive survivors -> awaiting_funding (+ manual steps)
	$(PY) -m factory.smoke.run

train:            ## Training Academy: brief, policies, catalogue, squad exams, certification for winners
	$(PY) -m factory.training.run

serve:            ## dashboard + API at http://localhost:8000
	$(PY) -m factory.api.server

night:            ## scout -> gates -> Deep Dive -> smoke prep -> Training -> Warden -> state, end to end
	$(PY) -m factory.night

warden:           ## Warden health check now: what broke, what it fixed, what needs you
	$(PY) -m factory.warden.run check

report:           ## write the Warden's weekly report now (also runs Mondays 07:00 SAST)
	$(PY) -m factory.warden.run report

schedule:         ## scheduler (SAST): 01:00 scouts; 02:00 retries, gates, Deep Dive, smoke prep; Warden every 15 min; Monday report
	$(PY) -m factory.scheduler

state:            ## print /api/state JSON
	$(PY) -c "import json; from factory.api.state import snapshot; print(json.dumps(snapshot(), indent=2))"

costs:            ## tonight's elixir by stage
	$(PY) -c "from factory import costs; costs.print_nightly_total()"

test:             ## offline tests with fake sources and a fake Claude client
	$(PY) -m unittest discover -s tests -v

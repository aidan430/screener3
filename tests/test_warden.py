"""Warden tests: health checks, Fixer, cost guard, reports. FAKE DATA only."""
from __future__ import annotations

import os
import unittest
from datetime import datetime, timedelta
from unittest import mock

from tests.base import FactoryTestCase, quiet

from factory import config, costs  # noqa: E402
from factory.models import AgentRun, Card, RunLog, SmokeTest, session, utcnow  # noqa: E402
from factory.scouts.sources.base import SourceError  # noqa: E402
from factory.warden import fixer, health, holds, report  # noqa: E402
from factory.warden.tables import Incident, SourceHold, WardenReport  # noqa: E402
from sqlmodel import select  # noqa: E402


def incidents(kind=None):
    with session() as s:
        q = select(Incident)
        if kind:
            q = q.where(Incident.kind == kind)
        return list(s.exec(q))


class WardenTest(FactoryTestCase):
    def check(self, **kw):
        return quiet(health.check, **kw)[0]

    def test_daily_cap_stops_work_and_is_reported(self):
        self.scout()
        spent = costs.spent_today()
        self.assertGreater(spent, 0)
        with mock.patch.dict(config.settings()["warden"], {"daily_cap_zar": spent * 1.05}):
            _, out = self.gates()
            self.assertIn("daily agent-spend cap", out)
            self.check()
        with session() as s:
            self.assertEqual(s.exec(select(Card)).one().status, "scouted")  # waits for tomorrow
            blocked = s.exec(select(AgentRun).where(AgentRun.status == "blocked")).one()
        self.assertEqual(blocked.role, "Proof gatekeeper")
        inc = incidents("daily_cap")[0]
        self.assertIn("Stopped all agent calls", inc.action)

    def test_stale_run_is_closed(self):
        with session() as s:
            s.add(AgentRun(dept="research", role="reddit scout", subject="sa-landlords", status="running",
                           started_at=utcnow() - timedelta(hours=3)))
            s.commit()
        res = self.check()
        with session() as s:
            run = s.exec(select(AgentRun).where(AgentRun.role == "reddit scout")).one()
        self.assertEqual(run.status, "failed")
        self.assertEqual([i.kind for i in res["fixed"]], ["stale_run"])

    def test_dead_source_is_paused_after_two_runs_then_skipped(self):
        down = SourceError("r/southafrica: 403 Forbidden")
        with mock.patch("factory.scouts.sources.reddit.fetch", side_effect=down):
            self.scout()
            self.check()
            self.assertEqual(holds.active(), {})  # one bad run is not enough
            self.scout()
            res = self.check()
        self.assertIn("reddit", holds.active())
        inc = incidents("source_down")[0]
        self.assertEqual(inc.outcome, "needs_you")  # a 403 usually needs a human: network or credentials
        self.assertIn(inc, res["needs_you"])
        _, out = self.scout()
        self.assertIn("paused by the Warden", out)
        self.assertEqual(self.client().post("/api/warden/holds/release").status_code, 200)
        self.assertEqual(holds.active(), {})

    def test_temporary_failure_is_retried_once(self):
        calls = {"n": 0}

        def flaky(niche):
            calls["n"] += 1
            if calls["n"] == 1:
                raise SourceError("r/southafrica: HTTP 429")
            from tests.fakes import FAKE_POSTS
            return [FAKE_POSTS[0]]
        with mock.patch("factory.scouts.sources.reddit.fetch", side_effect=flaky):
            self.scout()
            fixed = quiet(fixer.retry_failed_sources, delay=0)[0]
            again = quiet(fixer.retry_failed_sources, delay=0)[0]
        self.assertEqual([i.outcome for i in fixed], ["fixed"])
        self.assertEqual(again, [])  # once per source per niche per night
        with session() as s:
            titles = [c.title for c in s.exec(select(Card))]
        self.assertEqual(titles, ["Lease renewal reminders"])  # the retry found the post and made the card

    def test_missing_key_needs_you_until_it_is_set(self):
        with mock.patch.dict(os.environ, {"ANTHROPIC_API_KEY": "", "ANTHROPIC_AUTH_TOKEN": ""}):
            self.check()
            st = self.client().get("/api/state").json()
        self.assertEqual([a["kind"] for a in st["alerts"]], ["missing_key"])
        with mock.patch.dict(os.environ, {"ANTHROPIC_API_KEY": "sk-test"}):
            self.check()
        self.assertIsNotNone(incidents("missing_key")[0].resolved_at)

    def test_unfunded_test_is_flagged_after_a_week_then_clears(self):
        self.to_smoke()
        with session() as s:
            t = s.exec(select(SmokeTest)).one()
            t.created_at = utcnow() - timedelta(days=8)
            s.add(t)
            s.commit()
        self.check()
        self.assertEqual(incidents("stuck_funding")[0].outcome, "needs_you")
        self.client().post(f"/api/approve/{t.id}")
        self.check()
        self.assertIsNotNone(incidents("stuck_funding")[0].resolved_at)

    def test_weekly_report_lists_decisions_and_escapes_html(self):
        self.to_smoke()
        rep = quiet(report.save, "weekly")[0]
        self.assertIn("1 decision for you", rep.title)
        self.assertIn("Fund the Lease Nudge smoke test? R200 for 48 hours. If it wins, the launch needs about "
                      "R2,100 (break-even after 22 sales).", rep.body_md)
        self.assertIn("## Done without you", rep.body_md)
        self.assertNotIn("<script", rep.body_html)
        self.assertTrue(any(p.suffix == ".md" for p in (config.DATA_DIR / "reports").iterdir()))
        c = self.client()
        self.assertEqual(c.get("/api/reports").json()[0]["id"], rep.id)
        self.assertIn("Lease Nudge", c.get(f"/reports/{rep.id}").text)
        self.assertEqual(c.get("/reports/999").status_code, 404)

    def test_report_is_emailed_when_smtp_is_configured(self):
        env = {"SMTP_HOST": "smtp.example.com", "SMTP_PORT": "587", "SMTP_USER": "u", "SMTP_PASSWORD": "p",
               "REPORT_EMAIL_TO": "player@example.com"}
        with mock.patch.dict(os.environ, env), mock.patch("smtplib.SMTP") as smtp:
            rep = quiet(report.save, "weekly")[0]
        self.assertTrue(rep.emailed)
        server = smtp.return_value
        server.starttls.assert_called_once()
        server.login.assert_called_once_with("u", "p")
        self.assertEqual(server.send_message.call_args[0][0]["To"], "player@example.com")

    def test_missed_night_is_caught_up_once(self):
        with session() as s:
            s.add(RunLog(stage="scout", night="2026-01-01", summary="an earlier night"))
            s.commit()
        late = datetime(2026, 10, 7, 9, 0, tzinfo=health.SAST)
        with mock.patch.object(health, "now_sast", return_value=late), \
                mock.patch("factory.night.run") as night_run:
            self.check(catch_up=True)
            self.check(catch_up=True)
        night_run.assert_called_once()
        self.assertEqual(incidents("missed_night")[0].outcome, "fixed")

    def test_api_check_resolve_and_state(self):
        with mock.patch.dict(os.environ, {"ANTHROPIC_API_KEY": "", "ANTHROPIC_AUTH_TOKEN": ""}):
            c = self.client()
            self.assertIn("Health check done", c.post("/api/warden/check").json()["message"])
            st = c.get("/api/state").json()
            warden = next(b for b in st["buildings"] if b["id"] == "warden")
            self.assertEqual(warden["actions"][0]["endpoint"], "/api/warden/check")
            self.assertEqual((warden["roster"][0]["who"], warden["roster"][0]["state"]),
                             ("Missing key: ANTHROPIC_API_KEY", "block"))
            inc = incidents("missing_key")[0]
            self.assertEqual(c.post(f"/api/incidents/{inc.id}/resolve").status_code, 200)
            self.assertEqual(c.post(f"/api/incidents/{inc.id}/resolve").status_code, 404)
            st = c.get("/api/state").json()
        self.assertEqual(st["warden"]["checks_24h"], 1)
        self.assertEqual(st["alerts"], [])  # handled: gone until the next check finds it again

    def test_warden_never_touches_settings(self):
        path = config.CONFIG_DIR / "settings.yaml"
        before = path.stat().st_mtime_ns
        self.to_smoke()
        self.check()
        quiet(report.save, "monthly")
        self.assertEqual(path.stat().st_mtime_ns, before)
        with session() as s:
            self.assertEqual(s.exec(select(WardenReport)).one().kind, "monthly")
            self.assertEqual(list(s.exec(select(SourceHold))), [])

    def client(self):
        from fastapi.testclient import TestClient
        from factory.api.server import app
        return TestClient(app)


if __name__ == "__main__":
    unittest.main()

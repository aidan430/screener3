"""Shared test setup: temp DB, fake Claude, fake sources and fake marketplaces.

FAKE DATA ONLY. Nothing here touches data/factory.db or the network.
"""
from __future__ import annotations

import io
import logging
import os
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest import mock

from tests.fakes import FAKE_POSTS, FakeClaude, fake_probe, temp_env

logging.disable(logging.CRITICAL)
TMP = temp_env()  # must run before factory.models creates the engine

from factory import config, costs, models  # noqa: E402


def quiet(fn, *a, **kw):
    buf = io.StringIO()
    with redirect_stdout(buf):
        out = fn(*a, **kw)
    return out, buf.getvalue()


def first_niches(n):
    from factory.seed import active_niches
    return active_niches()[:n]


def _no_key(*a, **kw):
    from factory.market.base import NeedsKey
    raise NeedsKey("fake: no key in tests")


class FactoryTestCase(unittest.TestCase):
    def setUp(self):
        d = tempfile.mkdtemp(dir=TMP)
        os.environ["FACTORY_DB"] = str(Path(d) / "t.db")
        models.reset_engine()
        self.fake = FakeClaude()
        costs.set_client(self.fake)
        self.patches = [
            mock.patch.object(config, "DATA_DIR", Path(d)),
            mock.patch.object(config, "PAGES_DIR", Path(d) / "pages"),
            mock.patch.object(config, "VENTURES_DIR", Path(d) / "ventures"),
            mock.patch("factory.scouts.sources.reddit.fetch", return_value=[FAKE_POSTS[0]]),
            mock.patch("factory.scouts.sources.hn.fetch", return_value=[FAKE_POSTS[1]]),
            mock.patch("factory.scouts.sources.appstore.fetch", return_value=[]),
            mock.patch("factory.market.appstore.search", side_effect=fake_probe),
            mock.patch("factory.market.appstore.find_app", return_value=None),
            mock.patch("factory.market.etsy.search", side_effect=_no_key),
            mock.patch("factory.market.ebay.search", side_effect=_no_key),
            mock.patch.dict(os.environ, {"META_ADS_ENABLED": "false", "VERCEL_TOKEN": "", "FACTORY_DOMAIN": "",
                                         "SMTP_HOST": "", "REPORT_EMAIL_TO": ""}),
        ]
        for p in self.patches:
            p.start()

    def tearDown(self):
        for p in self.patches:
            p.stop()
        costs.set_client(None)

    def scout(self, niches=1):
        from factory.scouts import runner
        with mock.patch.object(runner, "active_niches", lambda: first_niches(niches)):
            return quiet(runner.run)

    def gates(self):
        from factory.gates import run
        return quiet(run.run)

    def dive(self):
        from factory.dive import run
        return quiet(run.run)

    def smoke(self):
        from factory.smoke import run
        return quiet(run.run)

    def to_smoke(self):
        self.scout()
        self.gates()
        self.dive()
        return self.smoke()

    def to_won(self):
        """Through a funded smoke test that wins (FAKE visits and clicks)."""
        from datetime import timedelta
        from factory.models import SmokeTest, TrackEvent, session, utcnow
        from factory.smoke import run as smoke
        t = self.to_smoke()[0][0]
        quiet(smoke.approve, t.id)
        with session() as s:
            st = s.get(SmokeTest, t.id)
            st.approved_at = utcnow() - timedelta(hours=10)
            s.add(st)
            s.add_all([TrackEvent(slug=t.slug, kind="visit") for _ in range(160)]
                      + [TrackEvent(slug=t.slug, kind="buy_click") for _ in range(10)])
            s.commit()
        self.smoke()
        return t

    def train(self):
        from factory.training import run
        return quiet(run.run)

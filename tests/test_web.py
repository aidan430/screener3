"""Web research tests: the web scout, the Deep Dive price check and real SDK shapes. FAKE DATA only."""
from __future__ import annotations

import json
import os
from types import SimpleNamespace
from unittest import mock

import anthropic
import httpx2

from tests.base import FactoryTestCase

from factory import costs, websearch  # noqa: E402
from factory.market import web as price_check  # noqa: E402
from factory.models import AgentRun, Cost, Dossier, Signal, session  # noqa: E402
from sqlmodel import select  # noqa: E402

POST = "https://mybroadband.co.za/forum/threads/dog-bottle.1/"
API_REPLY = {  # shaped like the API's documented web search response
    "id": "msg_1", "type": "message", "role": "assistant", "model": "claude-haiku-4-5",
    "content": [
        {"type": "server_tool_use", "id": "srvtoolu_1", "name": "web_search",
         "input": {"query": "where can I buy collapsible dog water bottle South Africa"}},
        {"type": "web_search_tool_result", "tool_use_id": "srvtoolu_1", "content": [
            {"type": "web_search_result", "url": POST, "title": "Dog bottle?", "encrypted_content": "abc",
             "page_age": "October 2, 2026"}]},
        {"type": "text", "text": "A MyBroadband user cannot find one locally.", "citations": [
            {"type": "web_search_result_location", "url": POST, "title": "Dog bottle?", "encrypted_index": "Eo8",
             "cited_text": "Where can I buy a collapsible dog water bottle in SA? Takealot is out of stock"}]}],
    "stop_reason": "end_turn", "stop_sequence": None,
    "usage": {"input_tokens": 5200, "output_tokens": 310, "server_tool_use": {"web_search_requests": 2}},
}


class WebTest(FactoryTestCase):
    def test_real_sdk_request_and_response_shapes(self):
        sent = {}

        def handler(request):
            sent["body"] = json.loads(request.content)
            return httpx2.Response(200, json=API_REPLY)

        client = anthropic.Anthropic(api_key="test-key", max_retries=0, http_client=anthropic.DefaultHttpxClient(
            transport=httpx2.MockTransport(handler)))
        costs.set_client(client)
        found = websearch.run(stage_name="scout", system="s", prompt="p", max_uses=3, country="ZA",
                              niche_slug="sa-pets")
        self.assertEqual(sent["body"]["tools"], [{
            "type": "web_search_20250305", "name": "web_search", "max_uses": 3,
            "user_location": {"type": "approximate", "country": "ZA", "timezone": "Africa/Johannesburg"}}])
        self.assertEqual(sent["body"]["model"], "claude-haiku-4-5")
        self.assertEqual(found.queries, ["where can I buy collapsible dog water bottle South Africa"])
        self.assertEqual([(c.url, c.page_age) for c in found.cites], [(POST, "October 2, 2026")])
        self.assertTrue(found.cites[0].text.startswith("Where can I buy a collapsible dog water bottle in SA?"))
        with session() as s:
            cost = s.exec(select(Cost)).one()
        self.assertAlmostEqual(cost.usd, 5200 / 1e6 + 310 * 5 / 1e6 + 2 * 0.01)  # tokens + 2 searches
        self.assertIn("2 searches", cost.note)

    def test_scout_keeps_only_text_copied_from_pages(self):
        self.scout(kind="commerce")
        with session() as s:
            sig = s.exec(select(Signal).where(Signal.source == "web")).one()
        self.assertTrue(sig.url.startswith("https://www.reddit.com/r/southafrica/"))  # the cited page
        self.assertNotIn("Found these.", sig.text)  # the model's own words never become evidence
        self.assertIn("Where can I buy a collapsible dog water bottle", sig.text)
        self.assertEqual(sig.posted_at.year, 2026)

    def test_search_rate_limit_fails_the_scout_in_words_the_fixer_retries(self):
        from factory.warden.fixer import TRANSIENT
        ns = SimpleNamespace
        error = ns(content=[ns(type="web_search_tool_result", tool_use_id="srv1",
                               content=ns(type="web_search_tool_result_error", error_code="too_many_requests"))],
                   usage=ns(input_tokens=100, output_tokens=10, cache_read_input_tokens=0,
                            cache_creation_input_tokens=0, server_tool_use=ns(web_search_requests=0)),
                   stop_reason="end_turn")
        with mock.patch.object(self.fake, "web_search", return_value=error):
            self.scout(kind="commerce")
        with session() as s:
            run = s.exec(select(AgentRun).where(AgentRun.role == "web scout")).one()
        self.assertEqual(run.status, "failed")
        self.assertTrue(TRANSIENT.search(run.summary), run.summary)

    def test_no_key_skips_the_web_scout_without_stopping_the_night(self):
        costs.set_client(None)
        with mock.patch.dict(os.environ, {"ANTHROPIC_API_KEY": "", "ANTHROPIC_AUTH_TOKEN": ""}):
            _, out = self.scout(kind="commerce")
        with session() as s:
            run = s.exec(select(AgentRun).where(AgentRun.role == "web scout")).one()
        self.assertEqual(run.status, "skipped")
        self.assertIn("ANTHROPIC_API_KEY", run.summary)
        self.assertIn("Scout night", out)

    def test_deep_dive_reads_rand_prices_from_cited_shop_text(self):
        self.scout(kind="commerce")
        self.gates()
        self.dive()
        with session() as s:
            d = s.exec(select(Dossier)).one()
        web = [e for e in d.j("evidence") if e["source"] == "web" and e["id"] != "E0"]  # E0: the buyer's post
        self.assertEqual(sorted((e["price"], e["currency"]) for e in web), [(449.0, "ZAR"), (1299.0, "ZAR")])

    def test_price_parsing(self):
        self.assertEqual([price_check.price_in(t) for t in (
            "Dog bottle R449 in stock", "R 1 299.00 incl. VAT", "Now R12,500", "PR500 code", "no price")],
            [449.0, 1299.0, 12500.0, None, None])

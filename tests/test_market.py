"""Marketplace probe parsers against recorded-shape responses (no network). FAKE DATA only."""
from __future__ import annotations

import os
import unittest
from unittest import mock

import httpx

from factory.market import appstore, ebay, etsy
from factory.market.base import NeedsKey, ProbeError, price_stats


def client(routes: dict):
    def handler(request: httpx.Request):
        for frag, (status, body) in routes.items():
            if frag in str(request.url):
                return httpx.Response(status, json=body)
        return httpx.Response(404, json={})
    return httpx.Client(transport=httpx.MockTransport(handler))


APP = {"trackId": 111, "trackName": "PayProp", "trackViewUrl": "https://apps.apple.com/za/app/payprop/id111",
       "price": 0.0, "currency": "ZAR", "userRatingCount": 340, "averageUserRating": 2.4, "sellerName": "PayProp"}
REVIEWS = {"feed": {"entry": [
    {"im:rating": {"label": "1"}, "title": {"label": "Slow"}, "content": {"label": "Payments take 5 days."},
     "id": {"label": "r1"}},
    {"im:rating": {"label": "5"}, "title": {"label": "Great"}, "content": {"label": "Love it"}, "id": {"label": "r2"}},
    {"im:rating": {"label": "2"}, "title": {"label": "Fees"}, "content": {"label": "R250 a month is a lot."},
     "id": {"label": "r3"}}]}}


class MarketTest(unittest.TestCase):
    def test_appstore_search_and_reviews(self):
        http = client({"itunes.apple.com/search": (200, {"resultCount": 1, "results": [APP]}),
                       "customerreviews": (200, REVIEWS)})
        app = appstore.find_app("payprop", "za", http=http)
        self.assertEqual((app.title, app.metric, app.ext_id), ("PayProp", 340.0, "111"))
        revs = appstore.reviews(app, max_stars=2, http=http)
        self.assertEqual([r.rating for r in revs], [1, 2])  # the 5-star review is ignored
        self.assertEqual(revs[1].text, "R250 a month is a lot.")

    def test_appstore_single_entry_feed_and_errors(self):
        one = {"feed": {"entry": REVIEWS["feed"]["entry"][0]}}
        http = client({"customerreviews": (200, one)})
        app = appstore._listing(APP, "za")
        self.assertEqual(len(appstore.reviews(app, http=http)), 1)
        with self.assertRaises(ProbeError):
            appstore.search("x", "us", http=client({"itunes": (403, {})}))

    def test_etsy_needs_a_key_then_parses(self):
        with mock.patch.dict(os.environ, {"ETSY_API_KEY": ""}):
            with self.assertRaises(NeedsKey):
                etsy.search("lease template")
        body = {"count": 812, "results": [{"listing_id": 5, "title": "Lease pack", "url": "https://www.etsy.com/listing/5",
                                           "price": {"amount": 1299, "divisor": 100, "currency_code": "USD"},
                                           "num_favorers": 41}]}
        with mock.patch.dict(os.environ, {"ETSY_API_KEY": "k"}):
            p = etsy.search("lease template", http=client({"openapi.etsy.com": (200, body)}))
        self.assertEqual((p.total, p.listings[0].price, p.listings[0].metric), (812, 12.99, 41.0))

    def test_ebay_token_then_search(self):
        token = {"access_token": "t", "expires_in": 7200}
        body = {"total": 3400, "itemSummaries": [
            {"itemId": "v1|1", "title": "Pet bowl", "itemWebUrl": "https://www.ebay.co.uk/itm/1",
             "price": {"value": "14.99", "currency": "GBP"}, "seller": {"username": "shop1"}}]}
        ebay._token.update(value="", expires=0)
        with mock.patch.dict(os.environ, {"EBAY_CLIENT_ID": "id", "EBAY_CLIENT_SECRET": "s"}):
            p = ebay.search("pet bowl", "EBAY_GB", http=client({"oauth2/token": (200, token),
                                                                "item_summary": (200, body)}))
        self.assertEqual((p.total, p.listings[0].price, p.listings[0].currency), (3400, 14.99, "GBP"))

    def test_price_stats(self):
        st = price_stats([5, 10, 15, 20, 100])
        self.assertEqual((st["n"], st["min"], st["median"], st["max"]), (5, 5, 15, 100))
        self.assertIsNone(price_stats([]))


if __name__ == "__main__":
    unittest.main()

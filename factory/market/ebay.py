"""eBay Browse API: live listings for a term in one marketplace.

Needs EBAY_CLIENT_ID and EBAY_CLIENT_SECRET (a free eBay developer app). The
app token comes from the client-credentials grant and is cached until expiry.
"""
from __future__ import annotations

import base64
import time

from factory import config
from factory.market.base import Listing, NeedsKey, Probe, ProbeError, client

TOKEN_URL = "https://api.ebay.com/identity/v1/oauth2/token"
SEARCH = "https://api.ebay.com/buy/browse/v1/item_summary/search"
SCOPE = "https://api.ebay.com/oauth/api_scope"
_token: dict = {"value": "", "expires": 0.0}


def _app_token(http) -> str:
    if _token["value"] and time.time() < _token["expires"] - 60:
        return _token["value"]
    cid, secret = config.env("EBAY_CLIENT_ID"), config.env("EBAY_CLIENT_SECRET")
    if not (cid and secret):
        raise NeedsKey("eBay needs EBAY_CLIENT_ID and EBAY_CLIENT_SECRET (developer.ebay.com)")
    basic = base64.b64encode(f"{cid}:{secret}".encode()).decode()
    resp = http.post(TOKEN_URL, data={"grant_type": "client_credentials", "scope": SCOPE},
                     headers={"Authorization": f"Basic {basic}"})
    if resp.status_code != 200:
        raise ProbeError(f"eBay token HTTP {resp.status_code}")
    body = resp.json()
    _token.update(value=body["access_token"], expires=time.time() + int(body.get("expires_in", 7200)))
    return _token["value"]


def search(term: str, marketplace: str = "EBAY_US", limit: int = 10, http=None) -> Probe:
    own = http is None
    http = http or client()
    try:
        token = _app_token(http)
        resp = http.get(SEARCH, params={"q": term, "limit": limit},
                        headers={"Authorization": f"Bearer {token}", "X-EBAY-C-MARKETPLACE-ID": marketplace})
        if resp.status_code != 200:
            raise ProbeError(f"eBay {marketplace} HTTP {resp.status_code}")
        data = resp.json()
    except ProbeError:
        raise
    except Exception as e:
        raise ProbeError(f"eBay {marketplace}: {e}") from e
    finally:
        if own:
            http.close()
    listings = []
    for r in data.get("itemSummaries", []):
        if not r.get("itemWebUrl"):
            continue
        p = r.get("price") or {}
        try:
            price = float(p.get("value")) if p.get("value") is not None else None
        except ValueError:
            price = None
        listings.append(Listing(source="ebay", market=marketplace, title=r.get("title", ""),
                                url=r["itemWebUrl"], price=price, currency=p.get("currency", ""),
                                seller=(r.get("seller") or {}).get("username", ""),
                                ext_id=str(r.get("itemId", ""))))
    return Probe(source="ebay", market=marketplace, term=term, total=data.get("total"), listings=listings)

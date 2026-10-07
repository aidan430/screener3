"""Put a smoke page online.

With FACTORY_DOMAIN set and no VERCEL_TOKEN, the factory serves the page itself
at https://{FACTORY_DOMAIN}/pages/{slug}/ (Caddy in front, see scripts/install.sh).
With VERCEL_TOKEN as well, deploys data/pages/{slug}/ with the Vercel CLI and
aliases it to {slug}.{FACTORY_DOMAIN}. With neither, the page is only served
locally at /pages/{slug}/ (ads cannot point at localhost, so funding needs a domain).
"""
from __future__ import annotations

import logging
import shutil
import subprocess

from factory import config

log = logging.getLogger("factory.smoke.deploy")


def write_local(slug: str, html: str) -> str:
    d = config.PAGES_DIR / slug
    d.mkdir(parents=True, exist_ok=True)
    (d / "index.html").write_text(html)
    return str(d / "index.html")


def local_url(slug: str) -> str:
    return f"http://localhost:8000/pages/{slug}/"


def deploy(slug: str) -> tuple[str, str]:
    """Returns (target, url): self, vercel or local."""
    token, domain = config.env("VERCEL_TOKEN"), config.env("FACTORY_DOMAIN")
    if domain and not token:
        return "self", f"https://{domain}/pages/{slug}/"
    if not (token and domain):
        return "local", local_url(slug)
    if not shutil.which("vercel"):
        log.error("VERCEL_TOKEN set but the vercel CLI is not installed (npm i -g vercel)")
        return "local", local_url(slug)
    d = config.PAGES_DIR / slug
    scope = ["--scope", config.env("VERCEL_SCOPE")] if config.env("VERCEL_SCOPE") else []
    try:
        out = subprocess.run(["vercel", "deploy", str(d), "--prod", "--yes", "--token", token, *scope],
                             capture_output=True, text=True, timeout=300, check=True)
        deployment = out.stdout.strip().splitlines()[-1]
        host = f"{slug}.{domain}"
        subprocess.run(["vercel", "alias", "set", deployment, host, "--token", token, *scope],
                       capture_output=True, text=True, timeout=120, check=True)
        return "vercel", f"https://{host}/"
    except (subprocess.SubprocessError, IndexError) as e:
        log.error("vercel deploy failed for %s: %s", slug, e)
        return "local", local_url(slug)

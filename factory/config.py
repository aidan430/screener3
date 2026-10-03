"""Settings, paths and .env loading. No secrets live in this file."""
from __future__ import annotations

import logging
import os
from functools import lru_cache
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
CONFIG_DIR = ROOT / "config"
DATA_DIR = ROOT / "data"
LOG_DIR = ROOT / "logs"
DASHBOARD_DIR = ROOT / "dashboard"
PAGES_DIR = DATA_DIR / "pages"
VENTURES_DIR = ROOT / "ventures"


def load_dotenv(path: Path = ROOT / ".env") -> None:
    """Minimal .env reader (KEY=VALUE lines). Existing env vars win."""
    if not path.exists():
        return
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        value = value.strip().strip('"').strip("'")
        if value:
            os.environ.setdefault(key.strip(), value)


load_dotenv()


def env(key: str, default: str = "") -> str:
    return os.environ.get(key, default)


def env_flag(key: str) -> bool:
    return env(key, "false").lower() in ("1", "true", "yes", "on")


@lru_cache
def settings() -> dict:
    return yaml.safe_load((CONFIG_DIR / "settings.yaml").read_text())


@lru_cache
def pain_phrases() -> list[str]:
    return yaml.safe_load((CONFIG_DIR / "pain_phrases.yaml").read_text())


def niches_config() -> list[dict]:
    return yaml.safe_load((CONFIG_DIR / "niches.yaml").read_text())


def zar(usd: float) -> float:
    return usd * float(settings()["fx_usd_zar"])


def db_url() -> str:
    path = env("FACTORY_DB", str(DATA_DIR / "factory.db"))
    return f"sqlite:///{path}"


def setup_logging(name: str = "factory") -> logging.Logger:
    LOG_DIR.mkdir(exist_ok=True)
    root = logging.getLogger()
    if not root.handlers:
        fmt = logging.Formatter("%(asctime)s %(levelname)s %(name)s: %(message)s")
        fh = logging.FileHandler(LOG_DIR / "factory.log")
        fh.setFormatter(fmt)
        sh = logging.StreamHandler()
        sh.setFormatter(fmt)
        sh.setLevel(logging.ERROR)  # stage output is printed; details go to logs/factory.log
        root.addHandler(fh)
        root.addHandler(sh)
        root.setLevel(logging.INFO)
        for noisy in ("httpx", "httpcore", "anthropic", "urllib3", "prawcore"):
            logging.getLogger(noisy).setLevel(logging.WARNING)
    return logging.getLogger(name)

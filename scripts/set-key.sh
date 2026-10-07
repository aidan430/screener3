#!/usr/bin/env bash
# Add or change one setting in the factory's .env, then restart the factory.
#   bash /opt/factory/screener3/scripts/set-key.sh REDDIT_CLIENT_ID
# The value you paste stays hidden on screen and never appears in shell history.
set -euo pipefail

APP="$(cd "$(dirname "$0")/.." && pwd)"
KEY="${1:-}"
if [[ ! "$KEY" =~ ^[A-Z][A-Z0-9_]*$ ]]; then
  echo "Usage: bash $APP/scripts/set-key.sh NAME   (for example ANTHROPIC_API_KEY)"
  exit 1
fi
read -r -s -p "Paste the value for $KEY, then press Enter (it stays hidden): " VALUE </dev/tty
echo
if [ -z "$VALUE" ]; then
  echo "Nothing entered, so nothing changed."
  exit 1
fi
printf '%s' "$VALUE" | python3 "$APP/scripts/env_set.py" "$APP/.env" "$KEY"
chmod 600 "$APP/.env"
if id factory >/dev/null 2>&1; then chown factory:factory "$APP/.env"; fi
if systemctl restart factory-web factory-scheduler 2>/dev/null; then
  echo "Saved $KEY and restarted the factory."
else
  echo "Saved $KEY."
fi

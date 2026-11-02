#!/usr/bin/env bash
# Venture Factory installer for a fresh Ubuntu 24.04 server (a DigitalOcean droplet).
# Run it as root from the droplet's console:
#   curl -fsSL https://raw.githubusercontent.com/aidan430/screener3/main/scripts/install.sh | bash
# Running the same command again updates the factory and keeps your settings.
#
# It sets up: git, uv and the Python packages, the factory as two services that
# restart by themselves, a 1 GB swap file, Caddy (the https padlock) and a firewall
# that lets in only SSH and web traffic. The dashboard needs a password; only the
# test pages, their click counter and the signed Paystack webhook are public.
set -euo pipefail

REPO="${FACTORY_REPO:-https://github.com/aidan430/screener3.git}"
BRANCH="${FACTORY_BRANCH:-main}"
HOME_DIR=/opt/factory
APP="$HOME_DIR/screener3"

step() { printf '\n\033[1m[%s] %s\033[0m\n' "$1" "$2"; }
as_factory() { sudo -u factory -H bash -c "$1"; }
env_get() { grep -E "^$1=" "$APP/.env" 2>/dev/null | head -n 1 | cut -d= -f2- || true; }
env_put() { printf '%s' "$2" | python3 "$APP/scripts/env_set.py" "$APP/.env" "$1"; }

if [ "$(id -u)" != 0 ]; then echo "Run this as root (the DigitalOcean console logs you in as root)."; exit 1; fi
if [ ! -r /dev/tty ]; then echo "Run this in an interactive console: it asks you two questions."; exit 1; fi

step 1/9 "Installing the basics"
export DEBIAN_FRONTEND=noninteractive
apt-get update -q >/dev/null
apt-get install -y -q git curl sudo ufw python3 gnupg >/dev/null

step 2/9 "Adding a 1 GB swap file, so a small server never runs out of memory"
if ! swapon --show | grep -q .; then
  fallocate -l 1G /swapfile && chmod 600 /swapfile && mkswap /swapfile >/dev/null && swapon /swapfile
  grep -q '^/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

step 3/9 "Creating the 'factory' user and fetching the code ($BRANCH)"
id factory >/dev/null 2>&1 || useradd --system --create-home --home-dir "$HOME_DIR" --shell /bin/bash factory
if [ -d "$APP/.git" ]; then
  as_factory "cd '$APP' && git fetch -q origin '$BRANCH' && git checkout -q '$BRANCH' && git merge -q --ff-only 'origin/$BRANCH'"
else
  as_factory "git clone -q --branch '$BRANCH' '$REPO' '$APP'"
fi

step 4/9 "Installing uv and the Python packages (a minute or two)"
as_factory 'test -x ~/.local/bin/uv || curl -LsSf https://astral.sh/uv/install.sh | sh >/dev/null 2>&1'
UV="$HOME_DIR/.local/bin/uv"
[ -x "$UV" ] || UV="$HOME_DIR/.cargo/bin/uv"
as_factory "cd '$APP' && '$UV' sync --frozen -q"

step 5/9 "Your settings (kept on this server only, in $APP/.env)"
[ -f "$APP/.env" ] || as_factory "cp '$APP/.env.example' '$APP/.env'"
if [ -z "$(env_get ANTHROPIC_API_KEY)" ]; then
  read -r -s -p "Paste your Claude key (it starts with sk-ant-) and press Enter. It stays hidden: " KEY </dev/tty
  echo
  if [ -n "$KEY" ]; then env_put ANTHROPIC_API_KEY "$KEY"; fi
fi
DOMAIN="$(env_get FACTORY_DOMAIN)"
while [[ ! "$DOMAIN" =~ ^[a-z0-9-]+(\.[a-z0-9-]+)+$ ]]; do
  read -r -p "Your domain, without www or https (for example mytrials.co.za): " DOMAIN </dev/tty
  DOMAIN="$(printf '%s' "$DOMAIN" | tr 'A-Z' 'a-z' | sed -e 's#^https\{0,1\}://##' -e 's#^www\.##' -e 's#/.*$##')"
done
env_put FACTORY_DOMAIN "$DOMAIN"
NEW_PASSWORD=""
if [ -z "$(env_get DASHBOARD_PASSWORD)" ]; then
  NEW_PASSWORD="$(python3 -c 'import secrets; print(secrets.token_urlsafe(15))')"
  env_put DASHBOARD_PASSWORD "$NEW_PASSWORD"
fi
chown factory:factory "$APP/.env" && chmod 600 "$APP/.env"
as_factory "cd '$APP' && .venv/bin/python -m factory.seed" >/dev/null

step 6/9 "Starting the factory as two services that restart by themselves"
for svc in web scheduler; do
  if [ "$svc" = web ]; then module=factory.api.server; desc="dashboard and API"
  else module=factory.scheduler; desc="nightly scheduler and Warden"; fi
  cat > "/etc/systemd/system/factory-$svc.service" <<EOF
[Unit]
Description=Venture Factory $desc
After=network-online.target
Wants=network-online.target

[Service]
User=factory
WorkingDirectory=$APP
Environment=HOST=127.0.0.1
Environment=PORT=8000
Environment=PYTHONUNBUFFERED=1
ExecStart=$APP/.venv/bin/python -m $module
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
done
systemctl daemon-reload
systemctl enable -q factory-web factory-scheduler
systemctl restart factory-web factory-scheduler

step 7/9 "Installing Caddy, the https padlock"
if ! command -v caddy >/dev/null 2>&1; then
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
    | gpg --dearmor --yes -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' > /etc/apt/sources.list.d/caddy-stable.list
  chmod o+r /usr/share/keyrings/caddy-stable-archive-keyring.gpg /etc/apt/sources.list.d/caddy-stable.list
  apt-get update -q >/dev/null && apt-get install -y -q caddy >/dev/null
fi
cat > /etc/caddy/Caddyfile <<EOF
# Written by scripts/install.sh; running the installer again rewrites it.
# admin.$DOMAIN is the dashboard: the factory itself asks for the password.
admin.$DOMAIN {
	reverse_proxy 127.0.0.1:8000
}

# $DOMAIN shows strangers only the test pages, their click counter and the signed Paystack webhook.
$DOMAIN {
	@public path /pages/* /api/event/* /api/paystack/webhook
	handle @public {
		reverse_proxy 127.0.0.1:8000
	}
	handle {
		respond "Nothing here yet." 404
	}
}
EOF
systemctl enable -q caddy
systemctl reload caddy 2>/dev/null || systemctl restart caddy

step 8/9 "Closing every door except SSH and web"
ufw allow OpenSSH >/dev/null
ufw allow 80/tcp >/dev/null
ufw allow 443/tcp >/dev/null
ufw --force enable >/dev/null

step 9/9 "Checking"
CODE=000
for _ in $(seq 1 30); do  # the first start can take a few seconds
  CODE="$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8000/api/state || true)"
  [ "$CODE" = 401 ] && break
  sleep 1
done
if [ "$CODE" = 401 ]; then
  echo "The factory is running and its dashboard is locked."
else
  echo "The factory did not answer as expected (HTTP $CODE). Show me: journalctl -u factory-web -n 30"
fi
IP="$(hostname -I | awk '{print $1}')"
cat <<EOF

Done.

  Dashboard:   https://admin.$DOMAIN
  User name:   owner
  Password:    ${NEW_PASSWORD:-(unchanged)}
EOF
if [ -n "$NEW_PASSWORD" ]; then echo "               ^ save this in your password app now; it is shown only once"; fi
cat <<EOF
  Test pages:  https://$DOMAIN/pages/...

Your domain needs two A records pointing at this server ($IP):
  @      ->  $IP
  admin  ->  $IP
The padlock appears a minute or two after they work.

Add a key later:     bash $APP/scripts/set-key.sh REDDIT_CLIENT_ID
Update the factory:  run the same curl command again
Run a night now:     sudo -u factory -H bash -c 'cd $APP && .venv/bin/python -m factory.night'
EOF

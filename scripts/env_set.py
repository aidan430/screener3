"""Set KEY=VALUE in a .env file; the value is read from stdin so it never shows in `ps`.

Used by scripts/install.sh and scripts/set-key.sh. Standard library only.
Usage: printf '%s' "$VALUE" | python3 scripts/env_set.py /path/to/.env KEY
"""
import sys
from pathlib import Path

path, key = Path(sys.argv[1]), sys.argv[2]
value = sys.stdin.read().strip()
if value.startswith("#") or " #" in value or "\t#" in value:  # the reader would take it for a comment
    value = f"'{value}'" if '"' in value else f'"{value}"'
lines = path.read_text().splitlines() if path.exists() else []
out, done = [], False
for line in lines:
    if line.split("=", 1)[0].strip() == key:
        out.append(f"{key}={value}")
        done = True
    else:
        out.append(line)
if not done:
    out.append(f"{key}={value}")
path.write_text("\n".join(out) + "\n")

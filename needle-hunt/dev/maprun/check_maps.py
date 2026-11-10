"""Builds every map with the game's own code (dev/maprun/run_map.py) for a few seeds, with and
without a Golden Chest, and checks each gets Config.Chests.count chests and enough spawns. Slower
than dev/test_rules.py (it really builds the maps), so it runs on its own:

    PYTHONPATH=<where lupa is> python3 needle-hunt/dev/maprun/check_maps.py [seeds]
"""
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import run_map  # noqa: E402

config = (HERE.parent.parent / "src" / "shared" / "Config.luau").read_text()
count = int(re.search(r"count = (\d+), spread", config).group(1))
ids = re.findall(r'\{ id = "(\w+)", name', (HERE.parent.parent / "src" / "shared" / "Maps.luau").read_text())
seeds = int(sys.argv[1]) if len(sys.argv) > 1 else 3
problems = []
for m in ids:
    for seed in range(1, seeds + 1):
        for golden in (True, False):
            d = run_map.run(m, seed=seed, golden=golden)
            if len(d["chests"]) < count or len(d["spawns"]) < 4:
                problems.append(f"{m} seed {seed} golden {golden}: {len(d['chests'])} chests, {len(d['spawns'])} spawns")
    print(m, "ok" if not any(p.startswith(m + " ") for p in problems) else "PROBLEM", flush=True)
print("\n".join(problems) or f"all {len(ids)} maps: {count} chests and enough spawns on every seed")
sys.exit(1 if problems else 0)

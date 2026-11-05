"""Tests for the game's data, pile and pacing (standard library only): python3 dev/test_rules.py

The Luau code can't run here, so these check the data the game runs on and the pacing
simulation (dev/pacing.py), which mirrors Economy.luau's arithmetic.
"""
from __future__ import annotations

import json
import re
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "dev"))
import pacing  # noqa: E402

SHARED = ROOT / "src" / "shared"
CONFIG = (SHARED / "Config.luau").read_text()
FINDS = json.loads((SHARED / "Finds.json").read_text())


def layout() -> list[tuple[float, float, float]]:
    """Mirror of src/shared/Layout.luau: clump positions, bottom to top."""
    import math
    size, layers_n = pacing.number("ClumpSize"), int(pacing.number("PileLayers"))
    r0, r1, clumps = pacing.number("PileRadiusBottom"), pacing.number("PileRadiusTop"), int(pacing.number("Clumps"))
    layers, total = [], 0
    for i in range(layers_n):
        r = r0 - (r0 - r1) * i / (layers_n - 1)
        n = math.floor(r / size)
        layer = [(gx, i, gz, gx * gx + gz * gz) for gx in range(-n, n + 1) for gz in range(-n, n + 1) if (gx * size) ** 2 + (gz * size) ** 2 <= r * r]
        total += len(layer)
        layers.append(layer)
    excess = total - clumps
    for layer in layers:
        if excess <= 0:
            break
        layer.sort(key=lambda c: (-c[3], c[0], c[2]))
        cut = min(excess, len(layer) // 4)
        del layer[:cut]
        excess -= cut
    out = []
    for layer in layers:
        layer.sort(key=lambda c: (c[0], c[2]))
        out += [(c[0] * size, c[1] * size + size / 2, c[2] * size) for c in layer]
    return out


class Pile(unittest.TestCase):
    def test_exactly_the_configured_clumps_at_least_70_metres_high(self):
        clumps = layout()
        self.assertEqual(len(clumps), pacing.number("Clumps"))
        top = max(c[1] for c in clumps) + pacing.number("ClumpSize") / 2
        self.assertGreaterEqual(top * 0.28, 70, f"{top} studs is {top * 0.28:.1f} m")  # 1 stud = 0.28 m
        self.assertEqual(pacing.number("TotalStraws") % pacing.number("Clumps"), 0)

    def test_the_pile_fits_its_plot(self):
        clumps = layout()
        reach = max(max(abs(c[0]), abs(c[2])) for c in clumps) + pacing.number("ClumpSize") / 2
        self.assertLess(reach, pacing.number("PlotSize") / 2 - 15, "leave room to build around the pile")

    def test_four_plots_do_not_overlap_the_roads(self):
        size = pacing.number("PlotSize")
        centres = re.findall(r"\{ (-?\d+), (-?\d+) \}", re.search(r"^Config\.PlotCentres = (.*)$", CONFIG, re.M).group(1))
        self.assertEqual(len(centres), 4)
        for x, z in centres:
            self.assertGreaterEqual(min(abs(int(x)), abs(int(z))) - size / 2, 15, "plots must leave the roads clear")


class Items(unittest.TestCase):
    def test_tools_get_stronger_and_carry_more(self):
        tools = pacing.rows("Tools")
        self.assertEqual(len(tools), 10)
        self.assertEqual(tools[0]["price"], 0)
        for a, b in zip(tools, tools[1:]):
            for key in ("power", "capacity", "price"):
                self.assertGreater(b[key], a[key], key)
        self.assertEqual(pacing.number("DetectorLevel"), len(tools))

    def test_machines_need_power_that_generators_can_make(self):
        machines, generators = pacing.rows("Machines"), pacing.rows("Generators")
        draw = sum(m["draw"] * m["max"] for m in machines)
        made = sum(g["power"] * g["max"] for g in generators)
        self.assertGreaterEqual(made, draw, "every machine at once must be powerable")
        ids = [r["id"] for table in ("Pieces", "Machines", "Generators") for r in pacing.rows(table)]
        self.assertEqual(len(ids), len(set(ids)), "buildable item ids must be unique")

    def test_finds_tell_a_story(self):
        self.assertGreaterEqual(len(FINDS), 10)
        for f in FINDS:
            self.assertTrue(f["name"] and f["story"])


class Wheel(unittest.TestCase):
    def test_every_spin_wins_and_the_reveal_is_one_in_ten_thousand(self):
        prizes = pacing.rows("Wheel")
        total = sum(p["weight"] for p in prizes)
        reveal = [p for p in prizes if p.get("reveal") is not None or p["id"] == "needle"]
        self.assertEqual(len(reveal), 1)
        self.assertAlmostEqual(reveal[0]["weight"] / total, 1 / 10000)
        self.assertTrue(all(p["weight"] > 0 for p in prizes))


class Achievements(unittest.TestCase):
    def test_ten_achievements_with_known_numbers(self):
        block = re.search(r"^Config\.Achievements = \{(.*?)^\}", CONFIG, re.M | re.S).group(1)
        ids = re.findall(r'id = "(\w+)"', block)
        stats = set(re.findall(r'stat = "(\w+)"', block))
        self.assertEqual(len(ids), 10)
        self.assertEqual(len(set(ids)), 10)
        known = {"searches", "loads_filled", "straws_sold", "tool", "machines", "power", "best_height", "perks_maxed", "lucky_finds", "needles"}
        self.assertTrue(stats <= known, stats - known)

    def test_every_achievement_is_reachable(self):
        block = re.search(r"^Config\.Achievements = \{(.*?)^\}", CONFIG, re.M | re.S).group(1)
        goals = dict(zip(re.findall(r'stat = "(\w+)"', block), [float(g) for g in re.findall(r"goal = (\d+)", block)]))
        self.assertLessEqual(goals["tool"], len(pacing.rows("Tools")))
        self.assertLessEqual(goals["machines"], sum(m["max"] for m in pacing.rows("Machines")))
        self.assertLessEqual(goals["power"], sum(g["power"] * g["max"] for g in pacing.rows("Generators")))
        self.assertLessEqual(goals["best_height"], max(c[1] for c in layout()))


class Pacing(unittest.TestCase):
    def test_a_free_player_finds_the_needle_in_about_a_day(self):
        marks = pacing.simulate(False)
        half = next(h for h, s in marks if s >= 0.5)
        self.assertTrue(20 <= half <= 28, f"average needle at {half:.1f} h")

    def test_robux_is_much_faster(self):
        free = next(h for h, s in pacing.simulate(False) if s >= 0.5)
        robux = next(h for h, s in pacing.simulate(True) if s >= 0.5)
        self.assertTrue(0.15 <= robux / free <= 0.5, f"robux {robux:.1f} h vs free {free:.1f} h")

    def test_the_first_upgrade_comes_within_minutes(self):
        tools = pacing.rows("Tools")
        seconds = tools[1]["price"] / (tools[0]["power"] * pacing.CLICKS_PER_SECOND)
        self.assertLessEqual(seconds, 300)


if __name__ == "__main__":
    unittest.main(verbosity=1)

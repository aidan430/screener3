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
    """Clump positions, bottom to top (dev/pacing.py mirrors src/shared/Layout.luau)."""
    return [c[:3] for c in pacing.layout()["cells"]]


class Pile(unittest.TestCase):
    def test_exactly_the_configured_clumps_shaped_like_a_haystack(self):
        clumps = layout()
        self.assertEqual(len(clumps), pacing.number("Clumps"))
        top = max(c[1] for c in clumps) + pacing.number("ClumpSize") / 2
        width = 2 * max(abs(c[0]) for c in clumps) + pacing.number("ClumpSize")
        self.assertGreaterEqual(top * 0.28, 20, f"{top} studs is {top * 0.28:.1f} m")  # 1 stud = 0.28 m
        self.assertTrue(0.8 <= top / width <= 1.3, f"{top} tall and {width} wide: a haystack is about as tall as wide")
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

    def test_fitness_levels_cost_more_each_time(self):
        fitness = pacing.rows("Fitness")
        self.assertEqual({f["stat"] for f in fitness}, {"max", "regen", "walk"})
        self.assertEqual(len({f["id"] for f in fitness}), len(fitness))
        for f in fitness:
            prices = [f["price"] * f["growth"] ** n for n in range(int(f["levels"]))]
            self.assertGreater(f["price"], 0, f["name"])
            self.assertEqual(prices, sorted(set(prices)), f"{f['name']} prices must rise")
            self.assertGreater(f["per_level"], 0, f["name"])

    def test_stamina_refills_gently(self):
        st = pacing.table("Stamina")
        self.assertGreater(st["regenPerSecond"], 0)
        self.assertGreater(st["max"], 0)
        self.assertTrue(0 < st["recover"] <= st["max"], "you get your breath back before the bar is full")
        self.assertLessEqual(st["regenDelay"], 3, "a short rest, never a punishment")

    def test_the_metal_detector_is_an_early_buy(self):
        detector = pacing.table("MetalDetector")
        self.assertLess(detector["price"], pacing.rows("Tools")[2]["price"])
        self.assertTrue(0 < detector["range"] <= 40, "it only helps once you're close")
        self.assertGreaterEqual(detector["pollSeconds"], 0.2, "at most about 4-5 asks a second")

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
    def test_the_needle_hides_deep_in_the_upper_heap(self):
        lay = pacing.layout()
        self.assertGreaterEqual(len(lay["spots"]), 30, "enough hiding places that it isn't guessable")
        self.assertGreaterEqual(pacing.needle_share(), 0.85, "machines reach the needle only near the end")
        top = max(c[1] for c in lay["cells"])
        self.assertTrue(all(lay["cells"][i][1] >= top * 0.45 for i in lay["spots"]))
        self.assertEqual(sorted(lay["order"]), list(range(len(lay["cells"]))))

    def test_a_free_player_finds_the_needle_in_about_a_day_and_a_half(self):
        found = pacing.needle_hours(pacing.simulate(False))
        self.assertTrue(28 <= found <= 40, f"average needle at {found:.1f} h")

    def test_robux_is_much_faster(self):
        free = pacing.needle_hours(pacing.simulate(False))
        robux = pacing.needle_hours(pacing.simulate(True))
        self.assertTrue(0.15 <= robux / free <= 0.5, f"robux {robux:.1f} h vs free {free:.1f} h")

    def test_trucks_matter_but_never_strand_hay(self):
        p = pacing.Player(False)
        self.assertLess(pacing.number("TraderRate"), 20, "the trader alone can't keep up for long")
        rates = [t["rate"] for t in pacing.rows("Trucks")]
        self.assertEqual(rates, sorted(rates), "each truck hauls more than the last")
        self.assertEqual(len(rates), 4)
        self.assertGreater(p.haul([t["max"] for t in pacing.rows("Trucks")]), 300, "room for factories later")

    def test_the_first_upgrade_comes_within_minutes(self):
        tools = pacing.rows("Tools")
        seconds = tools[1]["price"] / (tools[0]["power"] * pacing.CLICKS_PER_SECOND)
        self.assertLessEqual(seconds, 300)


if __name__ == "__main__":
    unittest.main(verbosity=1)

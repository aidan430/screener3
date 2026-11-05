"""Tests for the game's data and pacing (standard library only): python3 dev/test_rules.py

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


class Items(unittest.TestCase):
    def test_tools_get_stronger_and_dearer(self):
        tools = pacing.rows("Tools")
        self.assertEqual(len(tools), 10)
        self.assertEqual(tools[0]["price"], 0)
        for a, b in zip(tools, tools[1:]):
            self.assertGreater(b["power"], a["power"])
            self.assertGreater(b["price"], a["price"])
        self.assertEqual(pacing.number("DetectorLevel"), len(tools))

    def test_bags_and_machines_scale_up(self):
        for table, key in (("Bags", "size"), ("Machines", "rate")):
            rows = pacing.rows(table)
            for a, b in zip(rows, rows[1:]):
                self.assertGreater(b[key], a[key], table)
                self.assertGreater(b["price"], a["price"], table)

    def test_perks_have_levels_and_prices(self):
        for perk in pacing.rows("Perks"):
            self.assertGreaterEqual(perk["levels"], 1)
            self.assertGreater(perk["price"], 0)
            self.assertGreater(perk["growth"], 1)

    def test_finds_tell_a_story(self):
        self.assertGreaterEqual(len(FINDS), 10)
        for f in FINDS:
            self.assertTrue(f["name"] and f["story"])
            self.assertLessEqual(f.get("bonus", 1), 3)


class Achievements(unittest.TestCase):
    def test_ten_achievements_with_distinct_ids(self):
        block = re.search(r"^Config\.Achievements = \{(.*?)^\}", CONFIG, re.M | re.S).group(1)
        ids = re.findall(r'id = "(\w+)"', block)
        stats = re.findall(r'stat = "(\w+)"', block)
        self.assertEqual(len(ids), 10)
        self.assertEqual(len(set(ids)), 10)
        known = {"searches", "bags_filled", "straws_sold", "tool", "machines", "perks_maxed",
                 "session_seconds", "searched", "lucky_finds", "needles"}
        self.assertTrue(set(stats) <= known, set(stats) - known)
        self.assertIn('id = "needle"', block)

    def test_every_achievement_is_reachable_by_a_free_player(self):
        block = re.search(r"^Config\.Achievements = \{(.*?)^\}", CONFIG, re.M | re.S).group(1)
        goals = dict(zip(re.findall(r'stat = "(\w+)"', block), [float(g) for g in re.findall(r"goal = (\d+)", block)]))
        self.assertLessEqual(goals["searched"], pacing.number("TotalStraws"))
        self.assertLessEqual(goals["tool"], len(pacing.rows("Tools")))
        self.assertLessEqual(goals["machines"], sum(m["max"] for m in pacing.rows("Machines")))


class Pacing(unittest.TestCase):
    def test_a_free_player_finds_the_needle_in_about_a_day(self):
        marks = pacing.simulate(False)
        earliest = next(h for h, s in marks if s >= pacing.number("NeedleEarliest"))
        full = marks[-1][0]
        self.assertTrue(14 <= earliest <= 20, f"needle zone starts at {earliest:.1f} h")
        self.assertTrue(20 <= full <= 28, f"full haystack takes {full:.1f} h")

    def test_robux_roughly_halves_the_time(self):
        free, robux = pacing.simulate(False)[-1][0], pacing.simulate(True)[-1][0]
        self.assertTrue(0.3 <= robux / free <= 0.6, f"robux {robux:.1f} h vs free {free:.1f} h")

    def test_the_first_upgrade_comes_within_minutes(self):
        tools, rate = pacing.rows("Tools"), pacing.number("CoinsPerStraw")
        seconds = tools[1]["price"] / (tools[0]["power"] * rate * pacing.CLICKS_PER_SECOND)
        self.assertLessEqual(seconds, 300)


if __name__ == "__main__":
    unittest.main(verbosity=1)

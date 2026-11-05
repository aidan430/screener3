"""Tests for the game's data and rules (standard library only): python3 dev/test_rules.py

The Luau code can't run here, so these check the data the game runs on, and mirror the
clue maker (src/shared/Clues.luau) to prove every case can be solved from its clues.
Keep `clues()` below in step with Clues.generate.
"""
from __future__ import annotations

import itertools
import json
import math
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SHARED = ROOT / "src" / "shared"
PILES = json.loads((SHARED / "Piles.json").read_text())
CASES = json.loads((SHARED / "Cases.json").read_text())
CONFIG = (SHARED / "Config.luau").read_text()
ATTRIBUTES = ["side", "water", "building", "animals"]


def config_number(name: str) -> float:
    m = re.search(rf"^Config\.{name} = ([\d.]+)", CONFIG, re.M)
    assert m, f"Config.{name} not found"
    return float(m.group(1))


def tools() -> list[dict]:
    rows = re.findall(r'\{ name = "([^"]+)", power = (\d+), price = (\d+), shaft = \{ [\d, ]+ \}, '
                      r'head = \{ [\d, ]+ \}, material = "(\w+)" \}', CONFIG)
    return [{"name": n, "power": int(p), "price": int(c), "material": m} for n, p, c, m in rows]


def clues(needle_id: str, order: list[str]) -> list[set]:
    """Mirror of Clues.generate with the attributes already shuffled into `order`."""
    needle = next(p for p in PILES if p["id"] == needle_id)
    candidates, out = list(PILES), []
    for attribute in order:
        keep = [p for p in candidates if p[attribute] == needle[attribute]]
        if len(candidates) > len(keep) >= 2:
            candidates = keep
            out.append({p["id"] for p in keep})
    out.append({needle_id})
    return out


class Piles(unittest.TestCase):
    def test_ten_distinct_haystacks(self):
        self.assertEqual(len(PILES), 10)
        for key in ("id", "name", "trace"):
            values = [p[key] for p in PILES]
            self.assertEqual(len(set(values)), len(values), key)
        for p in PILES:
            self.assertIn(p["side"], {"north", "south", "east", "west"})
            for flag in ("water", "building", "animals"):
                self.assertIsInstance(p[flag], bool)

    def test_haystacks_sit_on_the_right_side_and_apart(self):
        rng = config_number("SearchRange")
        for p in PILES:
            r = math.hypot(p["x"], p["z"])
            self.assertTrue(120 <= r <= 175, f"{p['id']} is {r:.0f} studs from the plaza")
            side = {"north": -p["z"], "south": p["z"], "east": p["x"], "west": -p["x"]}
            self.assertEqual(max(side, key=side.get), p["side"], p["id"])  # north is -Z
        for a, b in itertools.combinations(PILES, 2):
            d = math.hypot(a["x"] - b["x"], a["z"] - b["z"])
            self.assertGreater(d, 2 * rng, f"{a['id']} and {b['id']} search ranges overlap")

    def test_straws_split_evenly(self):
        self.assertEqual(config_number("TotalStraws") % len(PILES), 0)


class ClueLogic(unittest.TestCase):
    def test_every_case_is_solvable_from_its_clues(self):
        for needle in PILES:
            for order in itertools.permutations(ATTRIBUTES):
                found = clues(needle["id"], list(order))
                self.assertEqual(found[-1], {needle["id"]})
                for before, after in zip([{p["id"] for p in PILES}] + found, found):
                    self.assertIn(needle["id"], after)
                    self.assertLess(len(after), len(before), "a clue must rule something out")

    def test_most_cases_get_more_than_the_final_clue(self):
        counts = [len(clues(p["id"], list(o))) for p in PILES for o in itertools.permutations(ATTRIBUTES)]
        self.assertGreaterEqual(min(counts), 2)
        self.assertGreaterEqual(sum(counts) / len(counts), 2.5)


class Cases(unittest.TestCase):
    def test_cases_have_a_story_and_a_reveal(self):
        self.assertGreaterEqual(len(CASES), 5)
        for c in CASES:
            for key in ("title", "needle", "intro", "reveal"):
                self.assertTrue(c[key].strip(), key)
            self.assertIn("{pile}", c["reveal"])
            self.assertLessEqual(len(c["intro"]), 160, c["title"])  # fits the notice board
            self.assertNotIn("%", c["reveal"])  # the server fills {pile} with string.gsub


class Economy(unittest.TestCase):
    def test_tools_get_stronger_and_dearer(self):
        t = tools()
        self.assertEqual(len(t), 8)
        self.assertEqual(t[0]["price"], 0)
        for a, b in zip(t, t[1:]):
            self.assertGreater(b["power"], a["power"])
            self.assertGreater(b["price"], a["price"])
        self.assertEqual(config_number("DetectorLevel"), len(t))

    def test_each_tool_pays_for_the_next_in_minutes(self):
        """At 3 searches a second, the next tool should cost 5 seconds to 15 minutes of searching."""
        rate = config_number("CoinsPerStraw")
        t = tools()
        for a, b in zip(t, t[1:]):
            seconds = b["price"] / (a["power"] * rate * 3)
            self.assertTrue(5 <= seconds <= 900, f"{b['name']} takes {seconds:.0f}s")

    def test_needle_odds_are_fair(self):
        """handful / remaining each search finds the needle at a uniformly random straw."""
        remaining, handful, survive = 1000, 100, 1.0
        chances = []
        while remaining > 0:
            p = min(1, handful / remaining)
            chances.append(survive * p)
            survive *= 1 - p
            remaining -= handful
        self.assertAlmostEqual(sum(chances), 1.0)
        self.assertTrue(all(abs(c - 0.1) < 1e-9 for c in chances))


if __name__ == "__main__":
    unittest.main(verbosity=1)

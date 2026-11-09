"""Tests for the game's data, pile and pacing (standard library only): python3 dev/test_rules.py

The Luau code can't run here, so these check the data the game runs on and the pacing
simulation (dev/pacing.py), which mirrors Economy.luau's arithmetic.
"""
from __future__ import annotations

import json
import math
import re
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "dev"))
import pacing  # noqa: E402

SHARED = ROOT / "src" / "shared"
CONFIG = "\n".join((SHARED / f).read_text() for f in ("Config.luau", "ConfigFactory.luau", "ConfigGoals.luau", "ConfigPlayer.luau", "ConfigWorlds.luau", "ConfigPads.luau", "ConfigLobby.luau", "ConfigCosmetics.luau"))
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

    def test_old_four_plot_layout_note(self):
        """All four plots now share the middle of the farm (see Config.PlotCentres)."""
        centres = re.findall(r"\{ (-?\d+), (-?\d+) \}", re.search(r"^Config\.PlotCentres = (.*)$", CONFIG, re.M).group(1))
        self.assertEqual(len(centres), 4)
        self.assertEqual(len(set(centres)), 1, "every plot is the same place")

    def test_tools_get_stronger_and_carry_more(self):
        tools = pacing.rows("Tools")
        self.assertEqual(len(tools), 10)
        self.assertEqual(tools[0]["price"], 0)
        for a, b in zip(tools, tools[1:]):
            for key in ("power", "capacity", "price"):
                self.assertGreater(b[key], a[key], key)
        self.assertEqual(pacing.number("DetectorLevel"), len(tools))

    def test_every_tool_has_its_own_look(self):
        server = ROOT / "src" / "server"
        built = set(re.findall(r"^function Tool(?:Parts|Gadgets)\.(\w+)\(k\)", (server / "ToolParts.luau").read_text() + (server / "ToolGadgets.luau").read_text(), re.M))
        shapes = [t.get("shape") for t in pacing.rows("Tools") if "model" not in t]
        self.assertTrue(all(s in built for s in shapes), shapes)
        self.assertEqual(len(shapes), len(set(shapes)), "two tools share a shape")

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


class Heap(unittest.TestCase):
    def test_the_heap_has_its_own_material_and_the_place_file_matches(self):
        material = re.search(r'^Config\.HeapMaterial = "(\w+)"', CONFIG, re.M).group(1)
        self.assertIn(f'"{material}Name"', (ROOT / "dev" / "build.py").read_text())
        used = re.findall(r"Enum\.Material\.(\w+)", "".join(p.read_text() for p in (ROOT / "src").rglob("*.luau")))
        self.assertNotIn(material, used, "something else uses the heap's terrain material")

    def test_the_heaps_foot_slopes_out_but_stays_off_the_building_ground(self):
        foot = {k: float(v) for k, v in re.findall(r"(\w+) = ([\d.]+)", re.search(r"^Config\.HeapSkirt = \{([^}]*)\}", CONFIG, re.M).group(1))}
        self.assertGreaterEqual(foot["from"], pacing.number("PileRadiusBottom") - 2, "the foot starts at the heap's wall")
        self.assertLessEqual(foot["to"], pacing.number("BuildClear"), "the foot never buries a building")
        self.assertGreater(foot["to"] - foot["from"], 4, "a slope, not a step")


class StoryScript(unittest.TestCase):
    def test_every_beat_has_a_known_speaker_and_trigger(self):
        text = (SHARED / "Story.luau").read_text()
        cast = set(re.findall(r"^\t(\w+) = \{ name = ", text, re.M))
        speakers = set(re.findall(r'who = "(\w+)"', text))
        self.assertTrue(speakers <= cast, speakers - cast)
        ids = re.findall(r'\{ id = "(\w+)", title = ', text)
        self.assertEqual(len(ids), len(set(ids)), "beat ids are unique")
        kinds = set(re.findall(r'trigger = \{ kind = "(\w+)"', text))
        self.assertTrue(kinds <= {"start", "stat", "clumps", "tool", "truck", "placed", "machines", "needles", "world"}, kinds)
        worlds = {w["id"] for w in pacing.rows("Worlds")}
        self.assertTrue(set(re.findall(r'kind = "world", key = "(\w+)"', text)) <= worlds)
        clumps = [int(n) for n in re.findall(r'kind = "clumps", n = (\d+)', text)]
        self.assertEqual(clumps, sorted(clumps), "heap beats come in order")
        self.assertLessEqual(clumps[0], 2, "the first find comes within minutes")
        scenes = set(re.findall(r"^Cinematics\.(\w+) = ", (SHARED / "Cinematics.luau").read_text(), re.M))
        used = set(re.findall(r'cinematic = "(\w+)"', text))
        self.assertTrue(used and used <= scenes, used - scenes)


class Milestones(unittest.TestCase):
    def test_every_reward_is_a_real_cosmetic_and_the_24_hour_one_is_generous(self):
        text = (SHARED / "ConfigCosmetics.luau").read_text()
        cosmetics = set(re.findall(r'\{ id = "(\w+)", kind = "(?:title|hat|trail|aura)"', text))
        for ids in re.findall(r"cosmetics = \{ ([^}]*) \}", text):
            for c in re.findall(r'"(\w+)"', ids):
                self.assertIn(c, cosmetics)
        blocks = "".join(re.findall(r"^Config\.Achievements = \{(.*?)^\}", CONFIG, re.M | re.S))
        achievement_ids = re.findall(r'\{ id = "(\w+)"', blocks)
        self.assertEqual(len(achievement_ids), len(set(achievement_ids)), "achievement ids are unique")
        day = re.search(r'\{ id = "play24".*', text).group(0)
        self.assertIn("goal = 24", day)
        self.assertIn("spins = 5", day)
        self.assertIn("powerups = true", day)
        self.assertIn('stat = "hours"', day, "24 hours in total, never one sitting")
        self.assertIn("Config.Testing = { fastHours = 0, unlockAll = false }", text, "testing switches stay off in the shipped game")


class Settings(unittest.TestCase):
    def test_every_setting_a_script_uses_exists(self):
        """A Config.Name read anywhere in the scripts must be set in Config.luau or a companion."""
        defined = set(re.findall(r"^Config\.(\w+) = ", CONFIG, re.M))
        used = set()
        for path in (ROOT / "src").rglob("*.luau"):
            if path.name.startswith("Config"):
                continue
            used |= set(re.findall(r"\bConfig\.([A-Za-z]\w*)", path.read_text()))
        self.assertEqual(sorted(used - defined), [], "settings used but never set")


class Wheel(unittest.TestCase):
    def test_slices_are_sized_by_their_odds(self):
        """Mirrors Economy.wheelSlice: share of the face by weight, the smallest kept visible."""
        prizes, least = pacing.rows("Wheel"), pacing.number("WheelMinSlice")
        total = sum(p["weight"] for p in prizes)
        small = [p["weight"] for p in prizes if p["weight"] / total < least]
        spare = 1 - least * len(small)
        sizes = [least if p["weight"] / total < least else p["weight"] / (total - sum(small)) * spare for p in prizes]
        self.assertAlmostEqual(sum(sizes), 1)
        for p, size in zip(prizes, sizes):
            self.assertLess(abs(size - p["weight"] / total), 0.005, p["name"])

    def test_every_spin_wins_and_the_reveal_is_one_in_ten_thousand(self):
        prizes = pacing.rows("Wheel")
        total = sum(p["weight"] for p in prizes)
        reveal = [p for p in prizes if p.get("reveal") is not None or p["id"] == "needle"]
        self.assertEqual(len(reveal), 1)
        self.assertAlmostEqual(reveal[0]["weight"] / total, 1 / 10000)
        self.assertTrue(all(p["weight"] > 0 for p in prizes))


class Achievements(unittest.TestCase):
    def test_secret_achievements_with_known_numbers(self):
        block = re.search(r"^Config\.Achievements = \{(.*?)^\}", CONFIG, re.M | re.S).group(1)
        ids = re.findall(r'id = "(\w+)"', block)
        stats = set(re.findall(r'stat = "(\w+)"', block))
        self.assertEqual(len(ids), 11)
        self.assertEqual(len(set(ids)), 11)
        self.assertLessEqual(pacing.number("LoftAchievements"), len(ids), "the loft can be opened")
        known = {"searches", "loads_filled", "straws_sold", "tool", "machines", "power", "best_height", "perks_maxed", "lucky_finds", "needles", "secret_straw"}
        self.assertTrue(stats <= known, stats - known)

    def test_every_achievement_is_reachable(self):
        block = re.search(r"^Config\.Achievements = \{(.*?)^\}", CONFIG, re.M | re.S).group(1)
        goals = dict(zip(re.findall(r'stat = "(\w+)"', block), [float(g) for g in re.findall(r"goal = (\d+)", block)]))
        self.assertLessEqual(goals["tool"], len(pacing.rows("Tools")))
        self.assertLessEqual(goals["machines"], sum(m["max"] for m in pacing.rows("Machines")))
        self.assertLessEqual(goals["power"], sum(g["power"] * g["max"] for g in pacing.rows("Generators")))
        self.assertLessEqual(goals["best_height"], max(c[1] for c in layout()))


class Goals(unittest.TestCase):
    def test_goals_are_unique_rewarded_and_checkable(self):
        block = re.search(r"^Config\.Goals = \{(.*?)^\}", CONFIG, re.M | re.S).group(1)
        goals = [dict(re.findall(r'(\w+) = ("[^"]*"|[\d.]+)', g)) for g in re.findall(r"\{ (id = .*?) \}", block)]
        self.assertGreaterEqual(len(goals), 20)
        ids = [g["id"] for g in goals]
        self.assertEqual(len(ids), len(set(ids)), "goal ids must be unique")
        stats = set(re.findall(r'"(\w+)"', re.search(r"Profile\.STATS = \{(.*?)\}", (ROOT / "src/server/Profile.luau").read_text()).group(1)))
        items = {r["id"] for t in ("Pieces", "Machines", "Generators") for r in pacing.rows(t)}
        trucks = {r["id"] for r in pacing.rows("Trucks")}
        levels = {"tool": len(pacing.rows("Tools")), "bucket": len(pacing.rows("Buckets")), "silo": len(pacing.rows("Silos"))}
        for g in goals:
            kind, n = g["kind"].strip('"'), float(g["n"])
            self.assertGreater(float(g["reward"]), 0, g["id"])
            self.assertGreater(n, 0, g["id"])
            self.assertIn(kind, {"stat", "tool", "bucket", "silo", "clumps", "placed", "truck", "machines", "power"}, g["id"])
            key = g.get("key", '""').strip('"')
            if kind == "stat":
                self.assertIn(key, stats, g["id"])
            elif kind == "placed":
                self.assertIn(key, items, g["id"])
            elif kind == "truck":
                self.assertIn(key, trucks, g["id"])
            elif kind in levels:
                self.assertLessEqual(n, levels[kind], g["id"])
            elif kind == "clumps":
                self.assertLessEqual(n, float(pacing.number("Clumps")), g["id"])


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


class PortalWorlds(unittest.TestCase):
    FARM_REACH = 720  # the farm's ground is 1000 across, with hills to about 720 from the hub

    def worlds(self):
        rows = pacing.rows("Worlds")
        block = re.search(r"^Config\.Worlds = \{(.*?)^\}", CONFIG, re.M | re.S).group(1)
        centres = [(int(x), int(z)) for x, z in re.findall(r"x = (-?\d+), z = (-?\d+)", block)]
        self.assertEqual(len(rows), 4)
        self.assertEqual(len(centres), len(rows))
        return rows, centres

    def test_prices_and_multipliers_rise_world_by_world(self):
        rows, _ = self.worlds()
        for a, b in zip(rows, rows[1:]):
            for key in ("price", "multiplier", "straws"):
                self.assertGreater(b[key], a[key], f"{b['id']} {key}")
        self.assertGreater(rows[0]["multiplier"], 1, "a world pays more than the farm")
        self.assertEqual(len({r["id"] for r in rows}), len(rows))

    def test_worlds_are_far_apart_and_outside_the_farm(self):
        _, centres = self.worlds()
        size, inside = pacing.number("WorldSize"), pacing.number("WorldInside")
        self.assertGreaterEqual(inside, size / 2, "the whole world counts as inside it")
        for i, (x, z) in enumerate(centres):
            self.assertGreater(math.hypot(x, z) - inside, self.FARM_REACH, f"world {i + 1} overlaps the farm")
            for x2, z2 in centres[i + 1:]:
                self.assertGreater(math.hypot(x - x2, z - z2), 2 * inside + 200, "worlds overlap")


class Lobby(unittest.TestCase):
    def lobby(self):
        m = re.search(r"^Config\.Lobby = \{ x = (-?[\d.]+), floor = (-?[\d.]+), z = (-?[\d.]+) \}", CONFIG, re.M)
        self.assertIsNotNone(m, "Config.Lobby = { x = .., floor = .., z = .. }")
        return float(m.group(1)), float(m.group(3))

    def spots(self, table):
        block = re.search(rf"^Config\.{table} = \{{(.*?)^\}}", CONFIG, re.M | re.S).group(1)
        return [(key, float(x), float(z)) for key, x, z in re.findall(r'(?:id|key) = "(\w+)".*?at = \{ (-?[\d.]+), (-?[\d.]+) \}', block)]

    def test_the_lobby_is_far_from_the_farm_and_the_worlds(self):
        x, z = self.lobby()
        inside = pacing.number("LobbyInside")
        self.assertGreaterEqual(inside, pacing.number("LobbyRadius") + 40, "the whole island counts as the lobby")
        self.assertGreater(math.hypot(x, z) - inside, PortalWorlds.FARM_REACH, "the lobby overlaps the farm")
        block = re.search(r"^Config\.Worlds = \{(.*?)^\}", CONFIG, re.M | re.S).group(1)
        for wx, wz in re.findall(r"x = (-?\d+), z = (-?\d+)", block):
            gap = math.hypot(x - int(wx), z - int(wz)) - inside - pacing.number("WorldInside")
            self.assertGreater(gap, 200, "the lobby overlaps a world")

    def test_five_arches_one_for_the_farm_and_each_world(self):
        arches = self.spots("LobbyPortals")
        ids = [a[0] for a in arches]
        self.assertEqual(len(arches), 5)
        self.assertEqual(sorted(ids), sorted(["farm"] + [r["id"] for r in pacing.rows("Worlds")]))
        radius = pacing.number("LobbyRadius")
        for i, (_, x, z) in enumerate(arches):
            self.assertLess(math.hypot(x, z) + 8, radius, "arches stand on the island")
            self.assertGreater(math.hypot(x, z), 30, "arches stand round the plaza, not in the fountain")
            for _, x2, z2 in arches[i + 1:]:
                self.assertGreaterEqual(math.hypot(x - x2, z - z2), 16, "arches (13 wide) must not touch")

    def test_robux_pads_stand_in_the_lobby_clear_of_the_arches(self):
        pads = self.spots("RobuxPads")
        arches = self.spots("LobbyPortals")
        size, radius = pacing.number("RobuxPadSize"), pacing.number("LobbyRadius")
        arrival = re.search(r"^Config\.LobbyArrival = \{ (-?[\d.]+), (-?[\d.]+) \}", CONFIG, re.M)
        ax, az = float(arrival.group(1)), float(arrival.group(2))
        self.assertGreaterEqual(len(pads), 10)
        self.assertLess(math.hypot(ax, az) + 5, radius, "you arrive on the island")
        for i, (key, x, z) in enumerate(pads):
            self.assertLess(math.hypot(x, z) + size / 2, radius - 2, f"{key} is on the island")
            self.assertGreater(math.hypot(x - ax, z - az), size / 2 + 8, f"{key} is clear of where you arrive")
            for _, x2, z2 in arches:
                self.assertGreater(math.hypot(x - x2, z - z2), size / 2 + 6.5 + 2, f"{key} is clear of the arches")
            for _, x2, z2 in pads[i + 1:]:
                self.assertGreater(math.hypot(x - x2, z - z2), size + 1, "pads must not touch")

    def test_the_farms_arch_stands_off_the_build_area(self):
        m = re.search(r"^Config\.LobbyFarmPortal = \{ x = (-?[\d.]+), past = ([\d.]+), behind = ([\d.]+) \}", CONFIG, re.M)
        x, past, behind = (float(v) for v in m.groups())
        entrance = re.search(r"^Config\.FarmEntrance = \{ (-?[\d.]+), (-?[\d.]+), (-?[\d.]+) \}", CONFIG, re.M)
        z = max(pacing.number("PlotSize") / 2 + past, float(entrance.group(3)) + behind)
        self.assertGreater(z - 2, pacing.number("PlotSize") / 2, "outside the build area")
        self.assertGreater(math.hypot(x, z), pacing.number("BuildClear") + 10, "well clear of the haystack")


if __name__ == "__main__":
    unittest.main(verbosity=1)

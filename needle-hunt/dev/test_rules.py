"""Tests for A Needle in a Haystack's data and rules (standard library only):

    python3 needle-hunt/dev/test_rules.py

The Luau can't run here, so these read the shared data modules and mirror shared/Rules.luau's
arithmetic, and check the pieces fit: every map has a builder and spawns, every quest and
cosmetic is valid, rewards favour fast finds, and no reward is random or paid for with Robux.
"""
from __future__ import annotations

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SHARED = ROOT / "src" / "shared"
SERVER = ROOT / "src" / "server"
CONFIG = (SHARED / "Config.luau").read_text()
COSMETICS = (SHARED / "Cosmetics.luau").read_text()
QUESTS = (SHARED / "Quests.luau").read_text()
MAPS = (SHARED / "Maps.luau").read_text()
NEEDLES = (SHARED / "Needles.luau").read_text()


def rows(text: str, start: str) -> list[dict]:
    """The `{ key = value, ... }` rows of a list that begins at `start`."""
    block = text[text.index(start):]
    block = block[: block.index("\n}")]
    out = []
    for line in block.splitlines():
        line = line.strip()
        if not line.startswith("{ "):
            continue
        fields = dict(re.findall(r'(\w+) = ("[^"]*"|-?[\d.]+|true|false)', line))
        out.append({k: (v.strip('"') if v.startswith('"') else v == "true" if v in ("true", "false") else float(v)) for k, v in fields.items()})
    return out


def table(name: str) -> dict:
    line = re.search(rf"^Config\.{name} = \{{(.*)\}}", CONFIG, re.M).group(1)
    return {k: float(v) for k, v in re.findall(r"(\w+) = (-?[\d.]+)", line)}


def block_table(name: str) -> dict:
    block = CONFIG[CONFIG.index(f"Config.{name} = {{"):]
    block = block[: block.index("\n}")]
    return {k: float(v) for k, v in re.findall(r"(\w+) = (-?[\d.]+)", block)}


ROUND = block_table("Round")
REWARDS = block_table("Rewards")
LEVELS = table("Levels")
DIFFS = rows(CONFIG, "Config.Difficulty = {")
MODS = rows(CONFIG, "Config.Modifiers = {")
ITEMS = rows(COSMETICS, "Cosmetics.items = {")
POOL = rows(QUESTS, "Quests.pool = {")
MAP_ROWS = [r for r in rows(MAPS, "Maps.list = {") if "id" in r]
PLACE = [float(v) for v in re.search(r"place = \{ ([\d., ]+) \}", CONFIG).group(1).split(",")]


def xp_need(level: int) -> float:
    return LEVELS["xpBase"] + LEVELS["xpStep"] * (level - 1)


def find_reward(place, elapsed, duration, diff, golden=False, streak=0, double=False):
    """Mirror of Rules.findReward."""
    p = PLACE[min(place, len(PLACE)) - 1]
    speed = 0.5 + 0.5 * min(max(1 - elapsed / max(duration, 1), 0), 1)
    streak_mult = 1 + min(REWARDS["winStreakMax"], REWARDS["winStreakStep"] * max(0, streak))
    mult = p * speed * diff["coins"] * (REWARDS["golden"] if golden else 1)
    coins = int(REWARDS["findCoins"] * mult * streak_mult * (2 if double else 1) + 0.5)
    xp = int(REWARDS["findXp"] * mult + 0.5)
    if place <= 3:
        coins += REWARDS["top3Coins"] * (2 if double else 1)
        xp += REWARDS["top3Xp"]
    return coins, xp


class Rounds(unittest.TestCase):
    def test_timings_follow_the_brief(self):
        self.assertTrue(10 <= ROUND["lobbyCountdown"] <= 20)
        self.assertTrue(120 <= ROUND["duration"] <= 300)
        self.assertLess(ROUND["speedDuration"], ROUND["duration"])
        self.assertEqual(ROUND["results"], 10)
        self.assertEqual(ROUND["minPlayers"], 1, "a lone player still gets practice rounds")

    def test_difficulties_get_harder(self):
        easy, normal, hard = DIFFS
        self.assertGreater(easy["needle"], normal["needle"])
        self.assertGreater(normal["needle"], hard["needle"])
        self.assertGreater(hard["clutter"], normal["clutter"])
        self.assertGreater(hard["decoys"], 0)
        self.assertGreater(hard["coins"], easy["coins"], "harder rounds pay more")

    def test_modifiers_are_the_four_asked_for(self):
        self.assertEqual({m["id"] for m in MODS}, {"double", "speed", "lowlight", "camo"})
        self.assertIn("Config.GoldenChance", CONFIG)


class Rewards(unittest.TestCase):
    def test_faster_and_higher_places_pay_more(self):
        normal = DIFFS[1]
        fast, _ = find_reward(1, 10, 180, normal)
        slow, _ = find_reward(1, 170, 180, normal)
        second, _ = find_reward(2, 10, 180, normal)
        self.assertGreater(fast, slow)
        self.assertGreater(fast, second)

    def test_golden_and_double_coins(self):
        normal = DIFFS[1]
        base, _ = find_reward(1, 30, 180, normal)
        self.assertGreater(find_reward(1, 30, 180, normal, golden=True)[0], base * 2)
        self.assertEqual(find_reward(1, 30, 180, normal, double=True)[0], base * 2)

    def test_levels_take_longer_as_you_go(self):
        self.assertLess(xp_need(1), xp_need(10))
        first_win_xp = find_reward(1, 30, 180, DIFFS[1])[1]
        self.assertLess(xp_need(1) / first_win_xp, 3, "a couple of good rounds reach level 2")


class Content(unittest.TestCase):
    def test_every_map_has_a_builder_and_spawns(self):
        builders = (SERVER / "MapsA.luau").read_text() + (SERVER / "MapsB.luau").read_text()
        self.assertGreaterEqual(len(MAP_ROWS), 5)
        for m in MAP_ROWS:
            self.assertIn(f"function Maps{'A' if m['builder'] in ('field', 'barn', 'sunset') else 'B'}.{m['builder']}(ctx)", builders, m["id"])
        counts = re.findall(r"maze\.spawns\((\d+)\)", builders)
        self.assertEqual(len(counts), len(MAP_ROWS), "every map is a maze with its own spawns")
        for count in counts:
            self.assertGreaterEqual(int(count), 6, "at least six spawn points per map")
        maze = (SERVER / "MazeKit.luau").read_text()
        heights = [float(h) for h in re.findall(r"height = ([\d.]+), style", builders)]
        self.assertTrue(all(h >= 6 for h in heights), "maze walls block the view")
        self.assertIn("deadEnds", maze)

    def test_cosmetics(self):
        ids = [i["id"] for i in ITEMS]
        self.assertEqual(len(ids), len(set(ids)))
        self.assertTrue(all(i["kind"] in ("trail", "title", "effect") for i in ITEMS), "needles aren't sold: they're found")
        for i in ITEMS:
            if i["price"] == 0:
                self.assertIn("source", i, i["id"] + " says where it comes from")
        bundle = re.search(r'Config.StarterBundle = \{ coins = \d+, cosmetic = "(\w+)" \}', CONFIG).group(1)
        self.assertIn(bundle, ids)

    def test_quests(self):
        kinds = {"find", "win", "play", "fast", "hard", "golden", "collect", "rare"}
        ids = {i["id"] for i in ITEMS}
        self.assertTrue(all(q["kind"] in kinds for q in POOL))
        self.assertGreaterEqual(len({q["kind"] for q in POOL if q["kind"] != "golden"}), 3, "three different kinds a day")
        for q in POOL:
            self.assertGreater(q["coins"], 0)
            if "cosmetic" in q:
                self.assertIn(q["cosmetic"], ids)
            if q["kind"] == "fast":
                self.assertIn("under", q)
        handled = (SERVER / "QuestManager.luau").read_text() + (SERVER / "RewardManager.luau").read_text() + (SERVER / "CollectionManager.luau").read_text()
        for kind in kinds:
            self.assertIn(f'"{kind}"', handled, f"something records {kind} quests")

    def test_no_paid_random_rewards(self):
        shop = (SERVER / "ShopManager.luau").read_text()
        self.assertNotIn("NextNumber", shop)
        self.assertNotIn("math.random", shop)

    def test_leaderboards(self):
        stores = re.findall(r'store = "(\w+)"', CONFIG)
        self.assertEqual(len(stores), len(set(stores)))
        self.assertEqual(len(stores), 6)


RARITIES = rows(NEEDLES, "Needles.rarities = {")
TYPES = rows(NEEDLES, "Needles.types = {")
SKINS = rows(NEEDLES, "Needles.skins = {")


class Collection(unittest.TestCase):
    def test_lots_to_collect(self):
        self.assertGreaterEqual(len(TYPES), 10)
        self.assertGreaterEqual(len(SKINS), 30)
        self.assertGreaterEqual(len(TYPES) * len(SKINS), 300)
        for kind in (TYPES, SKINS):
            ids = [r["id"] for r in kind]
            self.assertEqual(len(ids), len(set(ids)))

    def test_every_rarity_has_skins_and_rarer_is_worth_more(self):
        ids = {r["id"] for r in RARITIES}
        for r in RARITIES:
            self.assertGreaterEqual(sum(1 for s in SKINS if s["rarity"] == r["id"]), 2, r["id"])
        mults = [r["mult"] for r in RARITIES]
        weights = [r["weight"] for r in RARITIES]
        self.assertEqual(mults, sorted(mults), "rarer pays more")
        self.assertEqual(weights, sorted(weights, reverse=True), "rarer turns up less")
        self.assertTrue(all(s["rarity"] in ids for s in SKINS))
        self.assertIn("golden", {s["id"] for s in SKINS}, "Golden Needle rounds give the Golden skin")
        top = sum(r["weight"] for r in RARITIES if r["id"] in ("legendary", "mythic")) / sum(weights)
        self.assertLess(top, 0.03, "Legendary and Mythic stay special")

    def test_every_skin_and_type_can_be_drawn(self):
        look = (SHARED / "NeedleLook.luau").read_text()
        for t in TYPES:
            if t["id"] != "sewing":  # the default shape
                self.assertIn(f'typeId == "{t["id"]}"', look, t["id"])
        for s in SKINS:
            self.assertIn(s["pattern"], ("solid", "two", "stripes", "gradient", "rainbow"), s["id"])

    def test_needles_are_earned_never_bought(self):
        shop = (SERVER / "ShopManager.luau").read_text()
        self.assertNotIn("Needles", shop, "the shop and Robux never hand out collectible needles")
        self.assertIn("Needles.roll", (SERVER / "CollectionManager.luau").read_text())


class Powerups(unittest.TestCase):
    def test_only_helpful_powerups_and_each_is_handled(self):
        block = CONFIG[CONFIG.index("Config.Powerups = {"):]
        block = block[: block.index("} }")]
        kinds = re.findall(r'\{ id = "(\w+)"', block)
        self.assertEqual(set(kinds), {"speed", "compass", "birdseye", "glint", "coins"})
        server = (SERVER / "Powerups.luau").read_text()
        client = (ROOT / "src" / "client" / "PowerupFx.luau").read_text()
        for k in kinds:
            self.assertIn(f'"{k}"', server + client, k)
        self.assertNotIn("Robux", server, "power-ups are found on the map, never bought")


class RobuxShop(unittest.TestCase):
    def test_every_robux_item_is_on_the_list_handled_and_fair(self):
        passes = re.findall(r"(\w+) = 0", re.search(r"^Config\.GamePasses = \{(.*)\}", CONFIG, re.M).group(1))
        products = re.findall(r"(\w+) = 0", re.search(r"^Config\.Products = \{(.*)\}", CONFIG, re.M).group(1))
        robux = (SHARED / "Robux.luau").read_text()
        listed = re.findall(r'key = "(\w+)", pass = (true|false)', robux)
        self.assertEqual({k for k, p in listed if p == "true"}, set(passes), "every pass is in the shop")
        self.assertEqual({k for k, p in listed if p == "false"}, set(products), "every product is in the shop")
        shop = (SERVER / "ShopManager.luau").read_text()
        packs = table("CoinPacks")
        for name in products:
            self.assertTrue(f'"{name}"' in shop or name in packs, f"{name} gives something")
        code = "\n".join(line.split("--")[0] for line in shop.splitlines())  # not the comments
        for word in ("Powerup", "Needles", "Hint", "NextNumber", "math.random"):
            self.assertNotIn(word, code, f"Robux never buys {word}")
        self.assertIn("Pass_GrandBooth", (SERVER / "LobbySocial.luau").read_text())
        self.assertIn("starterBought", shop, "the Starter Bundle is once per player")

    def test_coins_have_plenty_to_buy(self):
        priced = [i for i in ITEMS if i["price"] > 0]
        self.assertGreaterEqual(len(priced), 12)
        self.assertGreater(sum(i["price"] for i in priced), max(table("CoinPacks").values()) * 5, "packs don't buy the whole shop")


if __name__ == "__main__":
    unittest.main()

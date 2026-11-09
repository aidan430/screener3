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
PLACE = [float(v) for v in re.search(r"placeCoins = \{ ([\d., ]+) \}", CONFIG).group(1).split(",")]


def xp_need(level: int) -> float:
    return LEVELS["xpBase"] + LEVELS["xpStep"] * (level - 1)


def place_coins(place, diff, streak=0, double=False):
    """Mirror of Rules.placeCoins."""
    base = PLACE[min(place, len(PLACE)) - 1]
    streak_mult = 1 + min(REWARDS["winStreakMax"], REWARDS["winStreakStep"] * max(0, streak)) if place == 1 else 1
    return int(base * diff["coins"] * streak_mult * (2 if double else 1) + 0.5)


CHESTS = block_table("Chests")
CHEST_COINS = [float(v) for v in re.search(r"coins = \{ (\d+), (\d+) \}", CONFIG).groups()]


class Rounds(unittest.TestCase):
    def test_timings_follow_the_brief(self):
        self.assertTrue(10 <= ROUND["lobbyCountdown"] <= 20)
        self.assertTrue(120 <= ROUND["duration"] <= 300)
        self.assertLess(ROUND["speedDuration"], ROUND["duration"])
        self.assertEqual(ROUND["results"], 10)
        self.assertEqual(ROUND["minPlayers"], 1, "a lone player still gets practice rounds")
        self.assertEqual(ROUND["maxPlayers"], 10, "ten players on a map")

    def test_difficulties_get_harder(self):
        easy, normal, hard = DIFFS
        self.assertGreater(hard["clutter"], normal["clutter"])
        self.assertGreater(hard["dim"], easy["dim"])
        self.assertGreater(hard["coins"], easy["coins"], "harder rounds pay more")

    def test_modifiers_and_chests(self):
        self.assertEqual({m["id"] for m in MODS}, {"speed", "lowlight", "keys", "brawl"})
        self.assertIn("Config.GoldenChance", CONFIG)
        self.assertEqual(CHESTS["count"], 5, "five chests a map")
        self.assertTrue(0 < CHESTS["keyChance"] < 1, "a chest holds coins or a key")
        keys = re.findall(r'\{ id = "(\w+)", name = "\w+ Key"', CONFIG)
        self.assertEqual(set(keys), {b["id"] for b in rows(CONFIG, "Config.Boxes = {")}, "a key for every box")
        spawner = (SERVER / "ChestSpawner.luau").read_text()
        for check in ("canOpen", "CH.reach", "chest.opened", "AntiCheat.flagged"):
            self.assertIn(check, spawner, "the server checks every chest opening")


class Rewards(unittest.TestCase):
    def test_higher_places_pay_more(self):
        normal = DIFFS[1]
        self.assertGreater(place_coins(1, normal), place_coins(2, normal))
        self.assertGreater(place_coins(2, normal), place_coins(3, normal))
        self.assertEqual(place_coins(1, normal, double=True), place_coins(1, normal) * 2)
        self.assertGreater(place_coins(1, normal, streak=3), place_coins(1, normal))

    def test_ranking_goes_chests_then_tagouts_then_coins(self):
        rules = (SHARED / "Rules.luau").read_text()
        body = rules[rules.index("function Rules.rank"):]
        self.assertLess(body.index("chests ~="), body.index("elims ~="))
        self.assertLess(body.index("elims ~="), body.index("x.coins > y.coins"))

    def test_levels_take_longer_as_you_go(self):
        self.assertLess(xp_need(1), xp_need(10))
        mx = block_table("MatchXp")
        place = [float(v) for v in re.search(r"MatchXp = \{ place = \{ ([\d., ]+) \}", CONFIG).group(1).split(",")]
        avg_chest = sum(CHEST_COINS) / 2
        first_win_xp = place[0] + mx["played"] + 2 * avg_chest * mx["perCoin"] + 2 * mx["perChest"]  # 1st with two chests
        self.assertLess(xp_need(1) / first_win_xp, 3, "a couple of good rounds reach level 2")
        self.assertGreater(mx["perElimination"], 0, "tagging players out earns XP")


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
        kinds = {"chest", "win", "play", "key", "hard", "tagout", "collect", "rare"}
        ids = {i["id"] for i in ITEMS}
        self.assertTrue(all(q["kind"] in kinds for q in POOL))
        self.assertGreaterEqual(len({q["kind"] for q in POOL}), 3, "three different kinds a day")
        for q in POOL:
            self.assertGreater(q["coins"], 0)
            if "cosmetic" in q:
                self.assertIn(q["cosmetic"], ids)
        handled = "".join((SERVER / f).read_text() for f in ("QuestManager.luau", "RewardManager.luau", "CollectionManager.luau", "Combat.luau"))
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
            self.assertIn(s["pattern"], ("solid", "two", "stripes", "gradient", "rainbow", "bands", "sheen", "split", "tri", "candy"), s["id"])

    def test_needles_are_earned_never_bought(self):
        shop = (SERVER / "ShopManager.luau").read_text()
        self.assertNotIn("Needles", shop, "the shop and Robux never hand out collectible needles")
        self.assertIn("Boxes.roll", (SERVER / "BoxManager.luau").read_text(), "needles come from boxes")


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
        box_products = set(re.findall(r'product = "(\w+)"', CONFIG))
        for name in products:
            self.assertTrue(f'"{name}"' in shop or name in packs or name in box_products, f"{name} gives something")
        code = "\n".join(line.split("--")[0] for line in shop.splitlines())  # not the comments
        for word in ("Powerup", "Hint", "Combat", "Hearts"):
            self.assertNotIn(word, code, f"Robux never buys {word}")
        self.assertIn("Pass_GrandBooth", (SERVER / "LobbySocial.luau").read_text())
        self.assertIn("starterBought", shop, "the Starter Bundle is once per player")

    def test_coins_have_plenty_to_buy(self):
        priced = [i for i in ITEMS if i["price"] > 0]
        self.assertGreaterEqual(len(priced), 12)
        self.assertGreater(sum(i["price"] for i in priced), max(table("CoinPacks").values()) * 5, "packs don't buy the whole shop")


BOXES = rows(CONFIG, "Config.Boxes = {")


class BoxOpenings(unittest.TestCase):
    def test_odds_add_up_and_every_rarity_has_skins(self):
        self.assertEqual({b["id"] for b in BOXES}, {"hay", "harvest", "starlight"})
        rarity_ids = [r["id"] for r in RARITIES]
        for line in CONFIG[CONFIG.index("Config.Boxes = {"):].splitlines()[1:4]:
            box = re.search(r'id = "(\w+)"', line).group(1)
            series = re.search(r'series = "(\w+)"', line)
            odds = dict((k, float(v)) for k, v in re.findall(r"(\w+) = ([\d.]+)", line.split("odds = {")[1]))
            self.assertAlmostEqual(sum(odds.values()), 100, msg=box)
            for rid in rarity_ids:
                if odds.get(rid, 0) > 0:
                    own = [x for x in SKINS if x["rarity"] == rid and series and x.get("series") == series.group(1)]
                    regular = [x for x in SKINS if x["rarity"] == rid and "series" not in x]
                    self.assertTrue(own or regular, f"{box} {rid}")
        top = [b for b in BOXES if b["id"] == "starlight"][0]
        self.assertGreater(top["coins"], [b for b in BOXES if b["id"] == "hay"][0]["coins"], "dearer boxes cost more")

    def test_series_skins_only_from_their_box(self):
        series = {x["series"] for x in SKINS if "series" in x}
        self.assertEqual(series, {"harvest", "starlight"})
        self.assertIn("not s.series", NEEDLES, "finds never give a box's own skins")

    def test_odds_shown_restricted_regions_and_pity(self):
        server = (SERVER / "BoxManager.luau").read_text()
        screen = (ROOT / "src" / "client" / "BoxScreen.luau").read_text()
        self.assertIn("ArePaidRandomItemsRestricted", server)
        self.assertIn("BoxesAllowed", server)
        self.assertIn("Boxes.odds", screen, "the exact odds are on the Boxes screen")
        self.assertIn("pity", server)
        pity = int(re.search(r"Config\.Boxes = \{ pity = (\d+)", CONFIG).group(1))
        self.assertTrue(5 <= pity <= 20, "a Rare-or-better guarantee comes round reasonably often")
        reel = (ROOT / "src" / "client" / "BoxReel.luau").read_text()
        self.assertIn("result.skin", reel, "the reel lands on what the server rolled")

    def test_thrown_needles_take_two_hearts_and_are_checked(self):
        throw = (SERVER / "CombatThrow.luau").read_text()
        t = table("Throw")
        self.assertEqual(t["damage"], 2)
        self.assertGreater(t["cooldown"], table("Combat")["cooldown"], "throws are rarer than pokes")
        self.assertLess(t["damage"], table("Combat")["hearts"], "one throw never tags someone out from full")
        self.assertIn("Spherecast", throw, "walls stop a throw")
        self.assertIn("Combat.damage", throw, "the same safe-time rules as a poke")
        self.assertIn("NeedleAway", (SERVER / "Combat.luau").read_text(), "no pokes while it's flying")

    def test_a_dash_never_trips_the_anticheat(self):
        dash, ac = table("Dash"), block_table("AntiCheat")
        moved = dash["speed"] * dash["seconds"] + 26 * (ac["checkEvery"] - dash["seconds"])  # dashing with Hay Boots on
        self.assertLess(moved / ac["checkEvery"], ac["maxSpeed"])
        self.assertGreater(dash["cooldown"], 1)

    def test_very_rare_openings_are_announced_and_keys_open_boxes(self):
        boxes = (SERVER / "BoxManager.luau").read_text()
        at = float(re.search(r"announceAt = ([\d.]+)", CONFIG).group(1))
        self.assertEqual(at, 0.5)
        self.assertIn("Config.Boxes.announceAt", boxes)
        self.assertIn("Remotes.Announce:FireAllClients", boxes)
        self.assertIn("BoxManager.announce", (SERVER / "ShopManager.luau").read_text(), "Robux openings too")
        self.assertIn("data.keys[box.id] -= 1", boxes, "a key is used up")
        # which rarities would be announced: those with a chance at or below announceAt in their box
        announced = []
        for line in CONFIG[CONFIG.index("Config.Boxes = {"):].splitlines()[1:4]:
            box = re.search(r'id = "(\w+)"', line).group(1)
            odds = dict((k, float(v)) for k, v in re.findall(r"(\w+) = ([\d.]+)", line.split("odds = {")[1]))
            announced += [(box, r) for r, v in odds.items() if 0 < v <= at]
        self.assertIn(("hay", "mythic"), announced)

    def test_combat_is_the_same_for_every_skin(self):
        combat = (SERVER / "Combat.luau").read_text()
        self.assertNotIn("rarity", combat)
        self.assertNotIn("Robux", combat)


class Trading(unittest.TestCase):
    def test_trades_are_safe(self):
        trade = (SERVER / "TradeManager.luau").read_text()
        self.assertIn("unready(t)", trade, "any change un-readies both")
        self.assertIn("countdown", trade)
        self.assertIn("isn't there any more", trade, "ownership is checked again before the swap")
        self.assertIn("DataManager.save(p)", trade, "both saves are written straight away")
        self.assertIn("RoundManager.current()", trade, "never during a round")


if __name__ == "__main__":
    unittest.main()

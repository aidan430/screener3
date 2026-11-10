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
        self.assertEqual({m["id"] for m in MODS}, {"speed", "lowlight", "powers", "brawl"})
        self.assertIn("Config.GoldenChance", CONFIG)
        self.assertEqual(CHESTS["count"], 5, "five chests a map")
        self.assertTrue(0 < CHESTS["powerupChance"] < 1, "a chest holds coins or a power-up")
        spawner_roll = (SERVER / "ChestSpawner.luau").read_text()
        self.assertNotIn("key =", spawner_roll, "chests never hold a key (keys open boxes of needles)")
        self.assertNotIn("OneOfOne", (SERVER / "RoundManager.luau").read_text(), "chests never hold a needle, not even a 1 of 1")
        self.assertIn("Powerups.give", (SERVER / "RoundManager.luau").read_text(), "a chest's power-up works at once")
        keys = re.findall(r'\{ id = "(\w+)", name = "\w+ Key"', CONFIG)
        self.assertEqual(set(keys), {b["id"] for b in rows(CONFIG, "Config.Boxes = {")} - {"heirloom"}, "a key for every box but the Heirloom Box (coins or Robux only)")
        spawner = (SERVER / "ChestSpawner.luau").read_text()
        for check in ("canOpen", "CH.reach", "chest.opened", "AntiCheat.flagged", "chest.top", "CH.hitLock"):
            self.assertIn(check, spawner, "the server checks every chest opening")

    def test_chests_are_hard_to_reach(self):
        c = CONFIG[CONFIG.index("Config.Chests = {"):]
        c = c[: c.index("\n}")]
        lo, hi = [float(v) for v in re.search(r"perch = \{ ([\d.]+), ([\d.]+) \}", c).groups()]
        golden = float(re.search(r"goldenPerch = ([\d.]+)", c).group(1))
        self.assertGreater(lo, 4, "every chest is up on a perch you have to climb")
        self.assertGreater(golden, hi, "the Golden Chest stands tallest")
        self.assertGreaterEqual(CHESTS["hold"], 2.5, "opening takes long enough to be interrupted")
        self.assertGreater(CHESTS["hitLock"], 0)
        spawner = (SERVER / "ChestSpawner.luau").read_text()
        self.assertIn("nearestSpawn", spawner, "chests go far from the spawns")
        self.assertIn("3.2 * (steps + 1)", spawner, "every jump up a perch stays easy")
        self.assertIn('"HitAt"', (SERVER / "Combat.luau").read_text())
        self.assertIn('GetAttribute("Chest")', (ROOT / "src" / "client" / "CombatFx.luau").read_text(), "a hit cancels the hold")


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
        builders = "".join((SERVER / f"Maps{x}.luau").read_text() for x in ("A", "B", "C", "D", "Big"))
        self.assertGreaterEqual(len(MAP_ROWS), 15)
        for m in MAP_ROWS:
            self.assertRegex(builders, rf"function Maps(?:[ABCD]|Big)\.{m['builder']}\(ctx\)", m["id"])
        ab = "".join((SERVER / f"Maps{x}.luau").read_text() for x in "AB")
        c = (SERVER / "MapsC.luau").read_text() + (SERVER / "MapsD.luau").read_text()
        counts = re.findall(r"maze\.spawns\((\d+)\)", builders)
        self.assertEqual(len(re.findall(r"maze\.spawns\(", ab)), len(re.findall(r"function Maps[AB]\.\w+\(ctx\)", ab)), "every map in MapsA and B places its spawns")
        self.assertEqual(c.count("\n\tfinish(ctx, maze)"), len(re.findall(r"function Maps[CD]\.\w+\(ctx\)", c)), "every MapsC/D map finishes (spawns) itself")
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
        kinds = {"chest", "win", "play", "power", "hard", "tagout", "collect", "rare"}
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
        boards = CONFIG[CONFIG.index("Config.Boards = {"):]
        stores = re.findall(r'store = "(\w+)"', boards[: boards.index("\n}")])
        self.assertEqual(len(stores), len(set(stores)))
        self.assertEqual(len(stores), 7)


RARITIES = rows(NEEDLES, "Needles.rarities = {")
TYPES = rows((SHARED / "NeedleTypes.luau").read_text(), "return {")
SKINS = rows(NEEDLES, "Needles.skins = {") + rows((SHARED / "NeedleSkins.luau").read_text(), "return {")


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
            if r["id"] != "unique":  # the 1 of 1 is the only one of its kind
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
            data = "".join(f.read_text() for f in sorted(SHARED.glob("Shapes*.luau")))
            if t["id"] != "sewing":  # the default shape
                self.assertTrue(f'typeId == "{t["id"]}"' in look or f"\t{t['id']} = {{" in data, t["id"])
        for s in SKINS:
            self.assertIn(s["pattern"], ("solid", "two", "stripes", "gradient", "rainbow", "bands", "sheen", "split", "tri", "candy", "fleck", "wave"), s["id"])

    def test_novelty_shapes_are_graded_rarer_and_worth_more(self):
        grades = {"classic", "fancy", "exotic", "masterwork", "heirloom"}
        self.assertTrue(all(t.get("grade") in grades for t in TYPES))
        classic = [t for t in TYPES if t["grade"] == "classic"]
        novel = [t for t in TYPES if t["grade"] != "classic"]
        self.assertEqual(len(novel), 82, "82 novelty shapes")
        shapes = "".join(f.read_text() for f in sorted(SHARED.glob("Shapes*.luau"))) + (SHARED / "NeedleLook.luau").read_text()
        for t in novel:
            self.assertTrue(f"\t{t['id']} = {{" in shapes or f'typeId == "{t["id"]}"' in shapes, t["id"] + " is drawn")
        top_classic = max(t["value"] for t in classic)
        order = ["fancy", "exotic", "masterwork", "heirloom"]
        for t in novel:
            self.assertGreater(t["value"], top_classic, t["id"] + " is worth more than any classic shape")
        for lo, hi in zip(order, order[1:]):  # each grade rarer and worth more than the one before
            self.assertGreater(min(t["weight"] for t in novel if t["grade"] == lo), max(t["weight"] for t in novel if t["grade"] == hi))
            self.assertLess(max(t["value"] for t in novel if t["grade"] == lo), min(t["value"] for t in novel if t["grade"] == hi))
        self.assertLess(sum(t["weight"] for t in novel) / sum(t["weight"] for t in TYPES), 0.2, "novelty shapes stay special")

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
        self.assertEqual({b["id"] for b in BOXES}, {"hay", "harvest", "starlight", "heirloom"})
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

    def test_heirloom_box_tiers_price_and_odds_on_show(self):
        box = [b for b in BOXES if b["id"] == "heirloom"][0]
        self.assertEqual(box["coins"], 100000)
        self.assertEqual(box["product"], "HeirloomBox")
        line = CONFIG[CONFIG.index('{ id = "heirloom"'):]
        line = line[: line.index("} } },") + 6]
        tiers = re.findall(r'\{ (grade|rarity) = "(\w+)", percent = ([\d.]+) \}', line)
        self.assertEqual([(k, i, float(p)) for k, i, p in tiers], [("grade", "heirloom", 10.0), ("rarity", "mythic", 40.0), ("grade", "exotic", 50.0)])
        odds = dict((k, float(v)) for k, v in re.findall(r"(\w+) = ([\d.]+)", line.split("odds = {")[1].split("}")[0]))
        self.assertAlmostEqual(sum(odds.values()), 100, msg="the shape tiers' skin odds")
        self.assertTrue([x for x in SKINS if x["rarity"] == "mythic" and "series" not in x], "regular Mythic skins exist")
        self.assertTrue([t for t in TYPES if t["grade"] == "exotic"] and [t for t in TYPES if t["grade"] == "heirloom"])
        self.assertIn("Boxes.tiers", (ROOT / "src" / "client" / "BoxScreen.luau").read_text(), "every tier's odds are shown")
        self.assertIn("HeirloomBox", (SHARED / "Robux.luau").read_text())
        self.assertIn("HeirloomBox = 0", CONFIG)

    def test_aim_settings_are_checked_and_applied(self):
        block = CONFIG[CONFIG.index("Config.Aim = {"):]
        block = block[: block.index("\n}\n")]
        sens = [float(v) for v in re.search(r"sensitivity = \{ ([\d., ]+) \}", block).group(1).split(",")]
        fov = [float(v) for v in re.search(r"fov = \{ ([\d., ]+) \}", block).group(1).split(",")]
        for lo, hi, step, default in (sens, fov):
            self.assertTrue(lo < default < hi and step > 0)
        self.assertEqual(fov[3], 70, "Roblox's own field of view is the default")
        self.assertIn('outlines = { "black", "white", "none" }', block)
        for key in ("reticleSize", "reticleThickness", "reticleOpacity", "reticleOutlineThickness"):
            lo, hi, step, default = [float(v) for v in re.search(key + r" = \{ ([\d., ]+) \}", block).group(1).split(",")]
            self.assertTrue(0 < lo <= default <= hi and step > 0, key)
        screen = (ROOT / "src" / "client" / "Screens2.luau").read_text()
        for key in ("reticleThickness", "reticleOpacity", "reticleOutlineThickness", "reticleOutline"):
            self.assertIn(key, screen, key + ": players can change it")
        self.assertIn('"none"', block, "the reticle can be hidden")
        aim = (SHARED / "AimSettings.luau").read_text()
        self.assertIn("math.clamp", aim)
        self.assertIn("AimSettings.clean", (SERVER / "Requests.luau").read_text(), "saved aim settings are checked")
        self.assertIn("AimSettings.clean", (SERVER / "DataManager.luau").read_text(), "loaded aim settings are checked")
        client = (ROOT / "src" / "client" / "Aim.luau").read_text()
        self.assertIn("MouseDeltaSensitivity", client)
        self.assertIn("FieldOfView", client)
        self.assertIn("Aim.fov()", (ROOT / "src" / "client" / "DashFx.luau").read_text(), "a dash returns to your field of view")

    def test_tag_out_streaks_raise_the_multiplier(self):
        line = re.search(r"^Config\.Streak = \{(.*)$", CONFIG, re.M).group(1)
        step = float(re.search(r"step = ([\d.]+)", line).group(1))
        top = float(re.search(r"max = ([\d.]+)", line).group(1))
        mults = [min(top, 1 + step * (n - 1)) for n in range(1, 8)]
        self.assertEqual(mults[0], 1, "the first tag-out pays the usual")
        self.assertEqual(mults, sorted(mults), "a longer streak never pays less")
        self.assertLessEqual(top, 3, "streaks stay a bonus, not a runaway")
        combat = (SERVER / "Combat.luau").read_text()
        streaks = (SERVER / "Streaks.luau").read_text()
        self.assertIn('target:SetAttribute("Streak", 0)', streaks, "being tagged out ends your streak")
        self.assertIn("Streaks.multiplier(streak)", streaks)
        self.assertIn('"elimWeight", mult', combat, "the streak carries into match XP")
        self.assertIn("elimWeight * X.perElimination", (SERVER / "MatchXp.luau").read_text())
        self.assertIn("Remotes.TagOut", combat)
        self.assertIn("Remotes.Feed:FireAllClients", streaks, "every tag-out goes in the feed")

    def test_a_marked_player_glows_through_walls_but_runs_faster(self):
        line = re.search(r"marked = \{ at = (\d+), speed = ([\d.]+)", CONFIG)
        self.assertEqual(int(line.group(1)), 10)
        self.assertEqual(float(line.group(2)), 1.5)
        streaks = (SERVER / "Streaks.luau").read_text()
        self.assertIn("AlwaysOnTop", streaks, "seen through walls")
        self.assertIn("Streaks.unmark(target)", streaks, "tagging a Marked player out ends it")
        self.assertIn("Streaks.walkSpeed", (SERVER / "Powerups.luau").read_text(), "a speed power-up ending doesn't undo Marked speed")
        self.assertIn("Streaks.clear()", (SERVER / "Combat.luau").read_text(), "the round ending ends it")

    def test_time_trial_practice(self):
        block = CONFIG[CONFIG.index("Config.Practice = {"):]
        block = block[: block.index("}\n")]
        nums = dict((k, float(v)) for k, v in re.findall(r"(\w+) = (-?[\d.]+)", block))
        self.assertEqual(nums["seconds"], 180, "3 minutes")
        self.assertGreater(nums["dummies"], 0)
        self.assertGreater(nums["chests"], 0)
        self.assertIn('id = "trial"', CONFIG)
        self.assertRegex(CONFIG, r'id = "trial".*ascending = true.*seconds = true', "fastest first, in tenths")
        practice = (SERVER / "Practice.luau").read_text()
        for word in ("RewardManager", "grant(", "CollectionManager", "d.keys", "MatchXp"):
            self.assertNotIn(word, practice, "practice gives no coins, XP, keys or needles")
        self.assertIn("trialBest", practice)
        self.assertIn("finish(player, run, false)", practice, "the clock runs out")
        self.assertIn('GetAttribute("Practicing")', (SERVER / "RoundManager.luau").read_text(), "a run isn't cut short by a round")
        self.assertIn("Combat.onDummy", (SERVER / "CombatThrow.luau").read_text())
        self.assertIn('"PracticeStall"', (SERVER / "LobbyBuilder.luau").read_text())

    def test_four_game_platforms_start_at_ten_or_after_a_countdown(self):
        block = CONFIG[CONFIG.index("Config.Pads = {"):]
        block = block[: block.index("\n\n")]
        pads = dict((k, float(v)) for k, v in re.findall(r"(\w+) = (-?[\d.]+)", block))
        self.assertEqual(pads["count"], 4)
        self.assertEqual(pads["size"], 10, "a game is 10 players")
        self.assertEqual(ROUND["maxPlayers"], pads["size"], "a game holds a full platform")
        self.assertLess(pads["fullCountdown"], pads["countdown"], "a full platform goes almost at once")
        self.assertGreaterEqual(pads["minPlayers"], 2, "a live game needs company; Studio can test alone")
        gp = (SERVER / "GamePads.luau").read_text()
        self.assertIn("ReserveServer(game.PlaceId)", gp, "each game gets its own server")
        self.assertIn("RunService:IsStudio()", gp, "in Studio the round plays here")
        self.assertIn("RoundManager.play", gp)
        gs = (SERVER / "GameServer.luau").read_text()
        self.assertIn("PrivateServerOwnerId == 0", gs, "a game server knows it's one")
        self.assertIn("TeleportService.TeleportAsync", gs, "and sends everyone back to the lobby after its round")
        main = (SERVER / "Main.server.luau").read_text()
        self.assertIn("GameServer.isGameServer()", main)
        self.assertNotIn("lobbyCountdown", (SERVER / "RoundManager.luau").read_text(), "rounds only start from a platform or a game server")

    def test_start_up_never_waits_on_one_system(self):
        main = (SERVER / "Main.server.luau").read_text()
        self.assertIn("waited < 5", main, "a slow start-up step can't stop rounds or the Practice Yard starting")
        self.assertIn("task.spawn(pcall", (SERVER / "OneOfOne.luau").read_text(), "cross-server messaging starts in its own thread")
        self.assertIn('why:find("Studio")', (SERVER / "DataManager.luau").read_text(), "Studio without API access plays unsaved at once")
        self.assertIn("grip = { 0, 180, 90 }", CONFIG, "the needle points out of the hand, not over the shoulder")

    def test_small_maps_still_get_every_chest(self):
        chests = (SERVER / "ChestSpawner.luau").read_text()
        self.assertIn("ctx.maze.cells", chests, "with few dead ends, chests go in other corridors")
        self.assertIn("CH.spread * 0.45", chests, "closer together only if they must be")
        self.assertIn("nudges", chests, "a prop in the way: try beside it")
        self.assertIn("for _, gap in ipairs({ 3, 2, 1 })", (SERVER / "MazeKit.luau").read_text(), "small mazes still give everyone a spawn")

    def test_heirloom_shapes_give_off_an_aura(self):
        look = (SHARED / "NeedleLook.luau").read_text()
        self.assertIn('grade == "heirloom"', look)
        self.assertIn("NeedleAura.add", look)
        aura = (SHARED / "NeedleAura.luau").read_text()
        self.assertIn("Config.Aura", aura)
        self.assertNotIn("Flicker", aura, "the aura is steady: nothing flashes")
        self.assertIn("Config.Aura = {", CONFIG)

    def test_first_person_rig_is_complete_and_wired(self):
        fp = (SHARED / "FirstPerson.luau").read_text()
        for name in ("inspect", "jab", "throw"):
            block = fp[fp.index(f"\t\t{name} = {{"):]
            block = block[: block.index("\n\t\t} },")]
            length = float(re.search(r"length = ([\d.]+)", block).group(1))
            times = [float(t) for t in re.findall(r"\{ t = ([\d.]+),", block)]
            self.assertEqual(times[0], 0, name + " starts at the hold pose")
            self.assertAlmostEqual(times[-1], length, msg=name + " ends at its length")
            self.assertEqual(times, sorted(times), name + " keys in order")
        view = (ROOT / "src" / "client" / "ViewModel.luau").read_text()
        self.assertIn('GetAttribute("Key")', view)
        self.assertIn('SetAttribute("Key"', (SERVER / "Combat.luau").read_text(), "the tool says which needle it is")
        self.assertIn('ViewModel.play("inspect")', (ROOT / "src" / "client" / "CombatFx.luau").read_text())
        self.assertIn('ViewModel.play("throw")', (ROOT / "src" / "client" / "ThrowFx.luau").read_text())
        self.assertIn("ViewModel.start()", (ROOT / "src" / "client" / "UIController.luau").read_text())

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

    def test_poke_and_throw_have_cooldowns_you_can_see(self):
        self.assertGreater(table("Combat")["cooldown"], 0)
        self.assertGreater(table("Throw")["cooldown"], table("Combat")["cooldown"])
        combat, throw = (SERVER / "Combat.luau").read_text(), (SERVER / "CombatThrow.luau").read_text()
        self.assertIn("C.cooldown", combat, "the server enforces the poke cooldown")
        self.assertIn("T.cooldown", throw, "the server enforces the throw cooldown")
        bars = (ROOT / "src" / "client" / "CooldownBars.luau").read_text()
        self.assertIn('"POKE"', bars)
        self.assertIn('"THROW"', bars)

    def test_a_dash_never_trips_the_anticheat(self):
        dash, ac = table("Dash"), block_table("AntiCheat")
        moved = dash["speed"] * dash["seconds"] + 26 * (ac["checkEvery"] - dash["seconds"])  # dashing with Hay Boots on
        self.assertLess(moved / ac["checkEvery"], ac["maxSpeed"])
        self.assertGreater(dash["cooldown"], 1)

    def test_very_rare_openings_are_announced_and_keys_open_boxes(self):
        boxes = (SERVER / "BoxManager.luau").read_text()
        at = float(re.search(r"Config\.Boxes = \{[^\n]*announceAt = ([\d.]+)", CONFIG).group(1))
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

    def test_the_one_of_one(self):
        block = CONFIG[CONFIG.index("Config.OneOfOne = {"):]
        block = block[: block.index("} }")]
        self.assertIn("chance = 1 / 12000000", block)
        self.assertIn("chance = 1 / 5000000", block, "the Galaxy Gossamer: 1 in 5 million")
        chances = [int(n) for n in re.findall(r"chance = 1 / (\d+)", block)]
        self.assertEqual(chances, sorted(chances, reverse=True), "the rarer is rolled first")
        self.assertEqual(len(set(re.findall(r'record = "(\w+)"', block))), 2, "each has its own one-time claim")
        self.assertGreaterEqual(int(re.search(r"throwDamage = (\d+)", block).group(1)), table("Combat")["hearts"], "one throw tags out")
        unique = [x for x in SKINS if x["rarity"] == "unique"]
        self.assertEqual([x["id"] for x in unique], ["gossamer", "galaxygossamer"])
        for u in unique:
            self.assertLess(u["thin"], 0.3, u["id"] + " is paper thin")
            self.assertGreater(u["see"], 0.5, u["id"] + " is hard to see")
        self.assertEqual([r["weight"] for r in RARITIES if r["id"] == "unique"], [0], "never in a box's normal rarity roll")
        for line in CONFIG[CONFIG.index("Config.Boxes = {"):].splitlines()[1:4]:
            self.assertNotIn("unique", line, "its own roll, not a rarity in a box's odds")
        one = (SERVER / "OneOfOne.luau").read_text()
        self.assertIn("UpdateAsync", one, "claimed once, across every server")
        self.assertIn("_Studio", one, "testing in Studio never claims the real one")
        boxes = (SERVER / "BoxManager.luau").read_text()
        self.assertIn("OneOfOne.roll(player)", boxes, "every box open rolls for the 1 of 1s")
        self.assertIn("BoxManager.rollUnique(player)", (SERVER / "ShopManager.luau").read_text(), "a box opened with Robux too")
        self.assertIn("Config.OneOfOne.list", (ROOT / "src" / "client" / "BoxScreen.luau").read_text(), "their odds are shown before every open")

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

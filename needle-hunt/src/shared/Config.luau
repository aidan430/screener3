-- Every tunable number for A Needle in a Haystack. Change values here; nothing else needs to
-- change. Maps, cosmetics and quests have their own data modules (Maps, Cosmetics, Quests).
local Config = {}

-- Rounds (server/RoundManager). Seconds.
Config.Round = {
	lobbyCountdown = 15, -- in the lobby before a round
	loadCountdown = 3, -- 3, 2, 1 in the map before searching starts
	duration = 180, -- a normal round
	speedDuration = 90, -- a Speed Round
	grace = 10, -- after the first find, everyone else still has this long (2nd, 3rd...)
	results = 10, -- the results screen
	minPlayers = 1, -- 1 = a solo player still gets (practice) rounds
	winsNeedPlayers = 2, -- a win counts towards wins and weekly winners only with this many playing
}

-- Difficulty: picked each round by weight. needle = its length in studs; glint = a soft sparkle
-- (easy only); clutter = loose straws scattered round the map; decoys = fake needles; dim =
-- how much darker the light is; moving = tumbling hay bundles that drift about.
Config.Difficulty = {
	{ id = "easy", name = "Easy", weight = 30, needle = 3.6, glint = true, clutter = 160, decoys = 0, dim = 0, moving = 0, coins = 1.0 },
	{ id = "normal", name = "Normal", weight = 50, needle = 2.8, glint = false, clutter = 260, decoys = 0, dim = 0, moving = 0, coins = 1.25 },
	{ id = "hard", name = "Hard", weight = 20, needle = 2.0, glint = false, clutter = 380, decoys = 4, dim = 0.35, moving = 4, coins = 1.6 },
}

-- Modifiers: a round gets one with this chance (then by weight). The Golden Needle is a
-- separate, rarer roll on top.
Config.ModifierChance = 0.35
Config.Modifiers = {
	{ id = "double", name = "Double Needle", text = "Two needles: both must be found", weight = 30 },
	{ id = "speed", name = "Speed Round", text = "Half the time!", weight = 30 },
	{ id = "lowlight", name = "Low Light", text = "The lights are low", weight = 20 },
	{ id = "camo", name = "Camouflage", text = "The needle matches the hay", weight = 20 },
}
Config.GoldenChance = 0.05 -- a Golden Needle: triple rewards, and the needle you keep is Golden

-- The needle collection (shared/Needles, server/CollectionManager): extra luck for a better skin
-- (added to 1, multiplying every rarity above Common) for 1st place and for Hard rounds.
Config.Collection = { firstLuck = 0.5, hardLuck = 0.5 }

-- The owner's own needle model (server/NeedleModel): its asset ID once the imported model is
-- saved to Roblox (Studio: right-click the model > Save to Roblox). 0 = use the built needle.
Config.NeedleModel = { asset = 0 }

-- Haystacks (MapKit.haystack): smooth, lumpy terrain domes in `material`, recoloured `colour`
-- (the arena's terrain is cleared between rounds). model = the owner's haystack model's asset ID
-- (server/HaystackModel; saved to Roblox from Studio): when it loads, every haystack uses it.
-- The textures uploaded with that model, for reference (the saved model carries them itself):
--   material0: 139923378561945, 82802973824193, 131881570420382, 134403754765000
--   material1: 125383755787779, 83696294561694, 117010844111225, 87942777253086
Config.Haystacks = { material = "Sand", colour = { 226, 186, 88 }, model = 0 }

-- Finding (server/NeedleSpawner). Studs and seconds.
Config.Find = {
	reach = 14, -- how close your character must be to claim the needle (clicks and taps)
	hitbox = 1.6, -- the invisible box round the needle you click or tap (the same on every device)
	thickness = 0.2, -- how thick the needle's shaft is (studs): thick enough to spot, thin enough to hide
	decoyLockout = 3, -- clicking a decoy: no claims for this long
	clicksPerSecond = 6, -- more than this and the extra clicks are ignored
	jitter = 0.6, -- the needle moves this far from its hiding spot, so spots can't be memorised
	maxSpotHeight = 6.5, -- spots higher than this above the floor need `climb = true` (a reachable loft)
}

-- Anti-exploit (server/AntiCheat).
-- Testing (Roblox Studio only, never in a live game): revealNeedle = true outlines the hidden
-- needle through walls and prints where it is, so you can test finding it.
Config.Testing = { revealNeedle = false }

-- Power-ups (server/Powerups): `count` glowing pickups float in the maze's corridors each round;
-- walk into one to take it, and another appears somewhere else `respawn` seconds later. Only
-- helpful ones (nothing slows or blinds anyone else), picked by weight. icon = shown on the orb.
--   speed: walk at `walkSpeed` for `seconds`     compass: an arrow to the nearest needle
--   birdseye: a look down from above the maze    glint: needles (and decoys!) within `range` sparkle
--   coins: a pouch of coins (doubled with 2x Coins) and a little XP
-- image = the uploaded icon's asset ID (assets/powerups/<id>.png: Studio > Asset Manager > Images,
-- or Creator Dashboard > Decals; copy its ID here). 0 = show the `icon` glyph instead.
Config.Powerups = { count = 8, respawn = 20, kinds = {
	{ id = "speed", name = "Hay Boots", icon = "»", image = 78113734507119, colour = { 110, 190, 70 }, weight = 30, seconds = 12, walkSpeed = 26 },
	{ id = "compass", name = "Compass", icon = "▲", image = 90767287093904, colour = { 240, 130, 40 }, weight = 20, seconds = 6 },
	{ id = "birdseye", name = "Bird's Eye", icon = "◉", image = 79032355368145, colour = { 70, 160, 240 }, weight = 15, seconds = 5, height = 55 },
	{ id = "glint", name = "Glint", icon = "✦", image = 127033997986783, colour = { 170, 110, 240 }, weight = 20, seconds = 8, range = 40 },
	{ id = "coins", name = "Coin Pouch", icon = "●", image = 133288309337957, colour = { 255, 205, 70 }, weight = 15, coins = 25, xp = 10 },
} }

-- XP after each match (server/MatchXp), shown as a breakdown on the results screen.
--   place: finishers 1st, 2nd, 3rd, then everyone else who finished; played: everyone at the end
--   perCoin: for each coin collected in the match; perNeedle: each needle found; perElimination
Config.MatchXp = { place = { 120, 90, 70, 50 }, played = 20, perCoin = 0.5, perNeedle = 40, perElimination = 25 }

-- Needle combat (server/Combat, client/CombatFx): during the search everyone carries their
-- showcase needle and can poke others. Three pokes and you're tagged out: you pop back at a maze
-- start after `respawn` seconds, with `safe` seconds when nobody can poke you. Hearts come back one
-- every `regen` seconds. Every skin pokes the same (looks only). reach is in studs.
Config.Combat = { hearts = 3, regen = 8, cooldown = 0.7, reach = 8, respawn = 5, safe = 3, eliminationCoins = 10 }
-- How the Needle tool sits in the hand, in degrees (X, Y, Z): turn it here if it points the wrong
-- way in Studio. scale = the needle's size in the hand. inspect = seconds the inspect lasts.
Config.NeedleTool = { grip = { 0, 90, 0 }, scale = 1.6, inspect = 2.4 }

-- Boxes (server/BoxManager, client/BoxScreen): open one for a needle for your collection. odds are
-- each rarity's chance in percent (shown in the game before you open one). series = the box's own
-- skins (Needles.skins with that series); a rarity the series doesn't have comes from the regular
-- skins. product = the Config.Products name that opens it for Robux (nil = coins only). pity:
-- every this many opens without Rare or better, the next is Rare or better (also shown).
Config.Boxes = { pity = 10, list = {
	{ id = "hay", name = "Hay Box", coins = 400, colour = { 226, 186, 88 }, odds = { common = 60, uncommon = 25, rare = 10, epic = 4, legendary = 0.9, mythic = 0.1 } },
	{ id = "harvest", name = "Harvest Box", coins = 1500, product = "HarvestBox", series = "harvest", colour = { 230, 120, 50 }, odds = { common = 40, uncommon = 30, rare = 18, epic = 8, legendary = 3.5, mythic = 0.5 } },
	{ id = "starlight", name = "Starlight Box", coins = 5000, product = "StarlightBox", series = "starlight", colour = { 120, 110, 240 }, odds = { common = 0, uncommon = 45, rare = 30, epic = 16, legendary = 7, mythic = 2 } },
} }

-- Trading (server/TradeManager, client/TradeScreen): in the lobby, two players swap needles.
-- Both must press Ready; any change un-readies both; then a `countdown` before it happens.
Config.Trading = { maxItems = 6, countdown = 5, requestCooldown = 10 }

Config.AntiCheat = {
	checkEvery = 0.5, -- seconds between movement checks
	maxSpeed = 70, -- studs a second a character may move (walking, jumping, falling) outside a teleport
	strikesToKick = 0, -- 0 = never kick; just put them back where they were
	fallY = -40, -- below this height (a fall off a map) a character respawns
}

-- Rewards (server/RewardManager). Coins and XP.
Config.Rewards = {
	findCoins = 60, findXp = 0, -- the first finder, at the very start of a round (halves by the end); XP comes from Config.MatchXp
	place = { 1, 0.6, 0.4, 0.25 }, -- 1st, 2nd, 3rd, the rest
	top3Coins = 15, top3Xp = 0,
	playCoins = 5, playXp = 0, -- for being there at the end of a round
	golden = 3, -- times everything for a Golden Needle
	winStreakStep = 0.1, winStreakMax = 0.5, -- +10% per win in a row, up to +50%
	loginCoins = 25, loginStreakMax = 7, -- daily login: 25 x streak day, up to day 7
}

-- Levels: level L needs xpBase + xpStep x (L - 1) XP.
Config.Levels = { xpBase = 100, xpStep = 25, max = 500 }

-- Hints: a free hint a day (two with the Extra Hint pass). A hint says roughly where the
-- needle is: its compass direction, how far and whether it's high or low.
Config.Hints = { free = 1, pass = 1, nearStuds = 15, farStuds = 45 }

-- Saving (server/DataManager). Change DataStoreName to start everyone afresh.
Config.DataStoreName = "NeedleHunt_v1"
Config.AutosaveSeconds = 60
Config.LoadRetries = 3

-- Leaderboards (server/LeaderboardManager): OrderedDataStore names. weekly gets the week
-- number added. Writes are batched every flushSeconds; boards re-read every readSeconds.
Config.Boards = {
	{ id = "needles", name = "Most Needles", store = "NH_Needles_v1", ascending = false },
	{ id = "fastest", name = "Fastest Find", store = "NH_Fastest_v1", ascending = true, seconds = true },
	{ id = "level", name = "Highest Level", store = "NH_Level_v1", ascending = false },
	{ id = "coins", name = "Most Coins Earned", store = "NH_Coins_v1", ascending = false },
	{ id = "weekly", name = "This Week's Winners", store = "NH_WeeklyWins_v1_", ascending = false, weekly = true },
	{ id = "collection", name = "Most Valuable Collection", store = "NH_Collection_v1", ascending = false },
}
Config.BoardRows = 10
Config.BoardFlushSeconds = 120
Config.BoardReadSeconds = 180

-- Robux (server/ShopManager, shared/Robux for what the shop says). 0 = not on sale yet: create the
-- pass or product on the Creator Dashboard (README: Selling with Robux), then put its ID here.
-- The only random things Robux can buy are boxes (Config.Boxes: odds always shown, hidden where
-- paid random items are restricted). Robux never buys a power-up, a hint mid-round or combat power.
Config.GamePasses = { DoubleCoins = 0, ExtraHint = 0, Supporter = 0, GrandBooth = 0 }
Config.Products = { StarterBundle = 0, CoinsSmall = 0, CoinsMedium = 0, CoinsLarge = 0, CoinShower = 0, HarvestBox = 0, StarlightBox = 0 }
Config.CoinPacks = { CoinsSmall = 500, CoinsMedium = 1500, CoinsLarge = 4000 } -- coins each pack gives
Config.CoinShower = { coins = 100 } -- every player in the server gets this, the buyer too
Config.GrandBooth = { needles = 6 } -- needles on show at a Grand Booth (3 otherwise)
Config.StarterBundle = { coins = 500, cosmetic = "t_sparkle" } -- what the Starter Bundle gives (never a collectible needle)

-- Sounds: Roblox's built-in sounds; swap in your own Toolbox IDs ("rbxassetid://...").
Config.Sounds = {
	found = "rbxasset://sounds/electronicpingshort.wav",
	click = "rbxasset://sounds/button.wav",
	whoosh = "rbxasset://sounds/swoosh.wav",
	countdown = "rbxasset://sounds/clickfast.wav",
}
Config.Music = "" -- a looping lobby track ID, or "" for none

-- Where things are. The lobby sits at the origin; maps are built far away, one at a time.
Config.LobbyCentre = Vector3.new(0, 0, 0)
Config.ArenaCentre = Vector3.new(0, 0, 600)

return Config

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
Config.Powerups = { count = 8, respawn = 20, kinds = {
	{ id = "speed", name = "Hay Boots", icon = "»", colour = { 255, 170, 60 }, weight = 30, seconds = 12, walkSpeed = 26 },
	{ id = "compass", name = "Compass", icon = "▲", colour = { 90, 170, 255 }, weight = 20, seconds = 6 },
	{ id = "birdseye", name = "Bird's Eye", icon = "◉", colour = { 170, 120, 255 }, weight = 15, seconds = 5, height = 55 },
	{ id = "glint", name = "Glint", icon = "✦", colour = { 255, 240, 140 }, weight = 20, seconds = 8, range = 40 },
	{ id = "coins", name = "Coin Pouch", icon = "●", colour = { 255, 205, 70 }, weight = 15, coins = 25, xp = 10 },
} }

Config.AntiCheat = {
	checkEvery = 0.5, -- seconds between movement checks
	maxSpeed = 70, -- studs a second a character may move (walking, jumping, falling) outside a teleport
	strikesToKick = 0, -- 0 = never kick; just put them back where they were
	fallY = -40, -- below this height (a fall off a map) a character respawns
}

-- Rewards (server/RewardManager). Coins and XP.
Config.Rewards = {
	findCoins = 60, findXp = 80, -- the first finder, at the very start of a round (halves by the end)
	place = { 1, 0.6, 0.4, 0.25 }, -- 1st, 2nd, 3rd, the rest
	top3Coins = 15, top3Xp = 20,
	playCoins = 5, playXp = 10, -- for being there at the end of a round
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

-- Robux (server/ShopManager). 0 = not on sale yet: create the pass or product on the Creator
-- Dashboard, then put its ID here. Nothing here is a random reward.
Config.GamePasses = { DoubleCoins = 0, ExtraHint = 0, Supporter = 0 }
Config.Products = { StarterBundle = 0 }
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

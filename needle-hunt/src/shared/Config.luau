-- Every tunable number for A Needle in a Haystack. Change values here; nothing else needs to
-- change. Maps, cosmetics and quests have their own data modules (Maps, Cosmetics, Quests).
local Config = {}

-- Rounds (server/RoundManager). Seconds.
Config.Round = {
	loadCountdown = 3, -- 3, 2, 1 in the map before the round starts
	duration = 180, -- a normal round (a map can set its own: Hayfield Farm's is 300)
	onlyMap = "bigfarm", -- play just this map (shared/Maps); nil = all of them in turn
	speedDuration = 90, -- a Speed Round
	grace = 15, -- once the last chest is open, this long to finish fights before the results
	results = 10, -- the results screen
	minPlayers = 1, -- 1 = a solo player still gets (practice) rounds
	maxPlayers = 10, -- players on one map (set the place's Max Players to 10 in Game Settings too)
	winsNeedPlayers = 2, -- a win counts towards wins and weekly winners only with this many playing
}

-- Difficulty: picked each round by weight. clutter = loose straws scattered round the map; dim =
-- how much darker the light is; moving = tumbling hay bundles that drift about; coins = times
-- the coins in every chest and the place coins.
Config.Difficulty = {
	{ id = "easy", name = "Easy", weight = 30, clutter = 160, dim = 0, moving = 0, coins = 1.0 },
	{ id = "normal", name = "Normal", weight = 50, clutter = 260, dim = 0, moving = 0, coins = 1.25 },
	{ id = "hard", name = "Hard", weight = 20, clutter = 380, dim = 0.35, moving = 4, coins = 1.6 },
}

-- Modifiers: a round gets one with this chance (then by weight). The Golden Chest is a
-- separate, rarer roll on top.
Config.ModifierChance = 0.35
Config.Modifiers = {
	{ id = "speed", name = "Speed Round", text = "Half the time!", weight = 35 },
	{ id = "lowlight", name = "Low Light", text = "The lights are low", weight = 30 },
	{ id = "powers", name = "Power Round", text = "Every chest holds a power-up", weight = 15 },
	{ id = "brawl", name = "Brawl", text = "Tag-outs pay double", weight = 20 },
}
Config.GoldenChance = 0.08 -- one chest is a Golden Chest: big coins and a power-up

-- Chests (server/ChestSpawner): `count` on every map, worth fighting for. They go in the dead ends
-- furthest from where players start, at least `spread` studs apart, each up on a perch `perch`
-- studs high (min, max; never above the maze's walls) reached by jumping up a few steps; a Golden
-- Chest stands on the tallest perch in the middle of a clearing. You must be up on the perch,
-- within `reach`, and hold E for `hold` seconds; a poke or a throw stops you, and for `hitLock`
-- seconds after a hit you can't open one. Inside, never a needle: a power-up (one of
-- Config.Powerups' kinds, used at once) with `powerupChance`, otherwise `coins` (min, max; times
-- the difficulty's coins). The Golden Chest holds `goldenCoins` and a power-up. `keys` are the box
-- keys players already have from before (chests no longer hold them; the Boxes screen still opens
-- one with each).
Config.Chests = {
	count = 5, spread = 30, hold = 3, reach = 8, hitLock = 1.5, perch = { 4.5, 8 }, goldenPerch = 9.5,
	powerupChance = 0.4, coins = { 30, 90 }, goldenCoins = { 200, 300 },
	keys = {
		{ id = "hay", name = "Hay Key", weight = 70 },
		{ id = "harvest", name = "Harvest Key", weight = 25 },
		{ id = "starlight", name = "Starlight Key", weight = 5 },
	},
}

-- The 1 of 1s (server/OneOfOne): paper-thin, nearly invisible Sewing Needles, one of each in the
-- whole game. Every box opened (coins, a key or Robux: server/BoxManager) has each one's `chance` of
-- holding it, shown with the box's odds, but only one can ever exist: the first to open it claims it
-- (`record`) in a DataStore shared by every server (Studio uses its own store, so testing never
-- claims the real ones). Thrown, any of them takes `throwDamage` hearts: an instant tag-out. Chests
-- never hold one. Found: announced on every server.
Config.OneOfOne = { store = "NH_OneOfOne_v1", throwDamage = 3, list = {
	{ key = "sewing:gossamer", chance = 1 / 12000000, record = "owner", odds = "1 in 12,000,000" }, -- the rarer is rolled first
	{ key = "sewing:galaxygossamer", chance = 1 / 5000000, record = "galaxy", odds = "1 in 5,000,000" },
} }

-- Places at the end of a round: by chests opened, then tag-outs, then coins collected. Places
-- pay coins (placeCoins, 1st to 4th, the rest get the last; times the difficulty's coins).

-- Haystacks (MapKit.haystack): smooth, lumpy terrain domes in `material`, recoloured `colour`
-- (the arena's terrain is cleared between rounds). model = the owner's haystack model's asset ID
-- (server/HaystackModel; saved to Roblox from Studio): when it loads, every haystack uses it.
-- The textures uploaded with that model, for reference (the saved model carries them itself):
--   material0: 139923378561945, 82802973824193, 131881570420382, 134403754765000
--   material1: 125383755787779, 83696294561694, 117010844111225, 87942777253086
Config.Haystacks = { material = "Sand", colour = { 226, 186, 88 }, model = 0 }

-- Anti-exploit (server/AntiCheat).
-- Testing (Roblox Studio only, never in a live game): revealChests = true outlines the chests
-- through walls, so you can test opening them.
Config.Testing = { revealChests = false }

-- Power-ups (server/Powerups): `count` glowing pickups float in the maze's corridors each round;
-- walk into one to take it, and another appears somewhere else `respawn` seconds later. Only
-- helpful ones (nothing slows or blinds anyone else), picked by weight. icon = shown on the orb.
--   speed: walk at `walkSpeed` for `seconds`     compass: an arrow to the nearest unopened chest
--   birdseye: a look down from above the maze    glint: unopened chests within `range` sparkle
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
--   place: 1st, 2nd, 3rd, then everyone else (by chests, tag-outs, coins); played: everyone at the end
--   perCoin: for each coin collected in the match; perChest: each chest opened; perElimination
Config.MatchXp = { place = { 120, 90, 70, 50 }, played = 20, perCoin = 0.5, perChest = 40, perElimination = 25 }

-- Tag-out streaks (server/Combat, client/StreakFx): each tag-out in a row without being tagged out
-- yourself raises your multiplier on that tag-out's coins and XP by `step`, up to `max`
-- (1x, 1.5x, 2x, 2.5x, then 3x). Being tagged out, or the round ending, resets it. From `announceAt`
-- in a row everyone in the round hears about it. names = the callout for that streak (and above).
-- marked: at `at` in a row you're Marked (server/Streaks) until you're tagged out or the round ends:
-- a `colour` outline everyone sees through walls, but you walk `speed` x faster.
-- feed = how many lines the tag-out feed shows (client/FeedFx), and for how many seconds.
Config.Streak = { step = 0.5, max = 3, announceAt = 3, names = { "TAGGED OUT!", "DOUBLE TAG!", "TRIPLE TAG!", "UNSTOPPABLE!", "HAYSTACK HERO!" },
	marked = { at = 10, speed = 1.5, colour = { 255, 0, 0 } }, feed = { lines = 5, seconds = 7 } }

-- Needle combat (server/Combat, client/CombatFx): during the search everyone carries their
-- showcase needle and can poke others. Three pokes and you're tagged out: you pop back at a maze
-- start after `respawn` seconds, with `safe` seconds when nobody can poke you. Hearts come back one
-- every `regen` seconds. Every skin pokes the same (looks only). reach is in studs.
Config.Combat = { hearts = 3, regen = 8, cooldown = 0.7, reach = 8, respawn = 5, safe = 3, eliminationCoins = 10 }
-- Throwing your needle (Q, or the Throw button): it flies straight where you aim at `speed`
-- studs a second, up to `range`; walls stop it. A hit takes `damage` hearts. Your needle is out of
-- your hand (no pokes) until it comes back, `back` seconds after the throw; `cooldown` between throws.
Config.Throw = { damage = 2, range = 45, speed = 90, radius = 1.2, back = 1.2, cooldown = 4 }
-- Dashing (C, B on a controller, or the Dash button): a quick burst along the way you're moving
-- (or facing) at `speed` studs a second for `seconds`, then `cooldown` before the next. Kept well
-- under Config.AntiCheat.maxSpeed, so a dash never looks like cheating.
Config.Dash = { speed = 55, seconds = 0.22, cooldown = 3 }
-- How the Needle tool sits in the hand, in degrees (X, Y, Z), as CFrame.Angles: { 0, 180, 90 } turns
-- the needle's length (its +X, point at the end) to the grip's up, so it points out of the hand the
-- way a sword does. Turn it here if it points the wrong way in Studio. scale = the needle's size in the hand. (How long the inspect lasts comes from the
-- first-person rig, shared/FirstPerson: anims.inspect.length.)
-- Classic studs (server/MapKit): parts with these names (floors, walls, platforms) are made plain
-- Plastic with studs on top and inlets underneath (Roblox draws studs on Plastic only). Parts in a
-- `keep` material (see-through glass and ice) stay as they are. Props keep their own materials.
-- Off while the maps go for a realistic look (studs need plain Plastic); `on = true` brings them back.
Config.Studs = { on = false, names = { "Ground", "Countryside", "Road", "Plaza", "Path", "PadPaving", "PadRim", "Deck", "StartPad", "MazeWall", "Hedge", "Wall", "Perch", "Step", "Climb", "Shelf" }, keep = { "Glass", "Ice" } }

Config.NeedleTool = { grip = { 0, 180, 90 }, scale = 1.6 }

-- The Heirloom aura (shared/NeedleAura): energy round every Heirloom-shaped needle, in its skin's
-- colours. shell = a shimmering ForceField skin round every piece (shellGrow x its size + shellPad
-- studs at scale 1); wisps and
-- sparks = particles a second; rise = how fast wisps float up; lift = how much the colours are
-- brightened towards white (so dark skins glow too); light = the glow's brightness and range.
-- gradient = the aura's own colours, from the eye end to the point (remove it to use the skin's).
Config.Aura = { gradient = { { 70, 0, 0 }, { 190, 0, 0 } }, shell = true, shellGrow = 1.14, shellPad = 0.07, wisps = 16, wispSize = 0.45, sparks = 10, rise = 1.8, lift = 0.12, light = 2.2, lightRange = 8 }

-- Boxes (server/BoxManager, client/BoxScreen): open one for a needle for your collection. odds are
-- each rarity's chance in percent (shown in the game before you open one). series = the box's own
-- skins (Needles.skins with that series); a rarity the series doesn't have comes from the regular
-- skins. product = the Config.Products name that opens it for Robux (nil = coins only). pity:
-- every this many opens without Rare or better, the next is Rare or better (also shown). Keys from
-- chests open a box free. announceAt: a needle whose rarity had this % chance or less in its box
-- is announced to the whole server.
Config.Boxes = { pity = 10, announceAt = 0.5, list = {
	{ id = "hay", name = "Hay Box", coins = 400, colour = { 226, 186, 88 }, odds = { common = 60, uncommon = 25, rare = 10, epic = 4, legendary = 0.9, mythic = 0.1 } },
	{ id = "harvest", name = "Harvest Box", coins = 1500, product = "HarvestBox", series = "harvest", colour = { 230, 120, 50 }, odds = { common = 40, uncommon = 30, rare = 18, epic = 8, legendary = 3.5, mythic = 0.5 } },
	{ id = "starlight", name = "Starlight Box", coins = 5000, product = "StarlightBox", series = "starlight", colour = { 120, 110, 240 }, odds = { common = 0, uncommon = 45, rare = 30, epic = 16, legendary = 7, mythic = 2 } },
	-- tiers: the box first picks a tier by percent. A grade tier gives a shape of that grade
	-- (by the shapes' own weights) in a skin rolled by `odds`; a rarity tier gives a skin of that
	-- rarity on any shape (by the usual shape odds). Every tier, and every Heirloom shape's own
	-- chance, is shown before opening. Robux price: 1,000 (set on the HeirloomBox product).
	{ id = "heirloom", name = "Heirloom Box", coins = 100000, product = "HeirloomBox", colour = { 230, 160, 110 }, odds = { uncommon = 45, rare = 30, epic = 16, legendary = 7, mythic = 2 },
		tiers = { { grade = "heirloom", percent = 10 }, { rarity = "mythic", percent = 40 }, { grade = "exotic", percent = 50 } } },
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
	placeCoins = { 60, 40, 25, 10 }, -- 1st, 2nd, 3rd, the rest (who opened a chest or tagged someone)
	playCoins = 5, -- for being there at the end of a round
	winStreakStep = 0.1, winStreakMax = 0.5, -- +10% place coins per win in a row, up to +50%
	loginCoins = 25, loginStreakMax = 7, -- daily login: 25 x streak day, up to day 7
}

-- Levels: level L needs xpBase + xpStep x (L - 1) XP.
Config.Levels = { xpBase = 100, xpStep = 25, max = 500 }

-- Hints: a free hint a day (two with the Extra Hint pass). A hint says roughly where the nearest
-- unopened chest is: its direction and how far.
Config.Hints = { free = 1, pass = 1, nearStuds = 15, farStuds = 45 }

-- Saving (server/DataManager). Change DataStoreName to start everyone afresh.
Config.DataStoreName = "NeedleHunt_v1"
Config.AutosaveSeconds = 60
Config.LoadRetries = 3

-- Leaderboards (server/LeaderboardManager): OrderedDataStore names. weekly gets the week
-- number added. Writes are batched every flushSeconds; boards re-read every readSeconds.
Config.Boards = {
	{ id = "chests", name = "Most Chests Opened", store = "NH_Chests_v1", ascending = false },
	{ id = "tagouts", name = "Most Tag-outs", store = "NH_TagOuts_v1", ascending = false },
	{ id = "level", name = "Highest Level", store = "NH_Level_v1", ascending = false },
	{ id = "coins", name = "Most Coins Earned", store = "NH_Coins_v1", ascending = false },
	{ id = "weekly", name = "This Week's Winners", store = "NH_WeeklyWins_v1_", ascending = false, weekly = true },
	{ id = "collection", name = "Most Valuable Collection", store = "NH_Collection_v1", ascending = false },
	{ id = "trial", name = "Fastest Time Trial", store = "NH_TimeTrial_v1", ascending = true, seconds = true }, -- stored in tenths
}
Config.BoardRows = 10
Config.BoardFlushSeconds = 120
Config.BoardReadSeconds = 180

-- Robux (server/ShopManager, shared/Robux for what the shop says). 0 = not on sale yet: create the
-- pass or product on the Creator Dashboard (README: Selling with Robux), then put its ID here.
-- The only random things Robux can buy are boxes (Config.Boxes: odds always shown, hidden where
-- paid random items are restricted). Robux never buys a power-up, a hint mid-round or combat power.
Config.GamePasses = { DoubleCoins = 0, ExtraHint = 0, Supporter = 0, GrandBooth = 0 }
Config.Products = { StarterBundle = 0, CoinsSmall = 0, CoinsMedium = 0, CoinsLarge = 0, CoinShower = 0, HarvestBox = 0, StarlightBox = 0, HeirloomBox = 0 }
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

-- The game platforms in the lobby (server/GamePads): `count` of them, each for a game of up to
-- `size` players. Stand on one to join (PLAY takes you to the fullest). At `size` it starts after
-- `fullCountdown` seconds; with at least `minPlayers` (`studioMinPlayers` in Studio) a `countdown`
-- starts and the game goes with whoever is on it. A game gets its own server (a private server of
-- this place, server/GameServer), plays one round and sends everyone back to the lobby. In Studio,
-- where teleports don't work, the round is played in this server instead. Each is `radius` studs
-- across the middle, `spacing` apart in a row at z = `z`. `portal`: the column's height, its slow
-- breath (seconds), sparks a second when empty and when full, its light's range, and the size in studs of the
-- board above it (game, count, status).
Config.Pads = { count = 4, size = 10, minPlayers = 2, studioMinPlayers = 1, countdown = 60, fullCountdown = 5, radius = 9, spacing = 22, z = 8,
	portal = { height = 9, breathe = 2.5, rate = 12, fullRate = 45, light = 20, boardWidth = 6, boardHeight = 3.2 },
	colours = { { 255, 206, 80 }, { 110, 200, 120 }, { 90, 160, 240 }, { 230, 120, 170 } } }

-- A game's own server (server/GameServer): it waits up to `wait` seconds for the players a platform
-- sent, plays one round, then `afterRound` seconds later sends everyone back to the lobby.
Config.GameServer = { wait = 20, afterRound = 2 }

-- The Practice Yard's Time Trial (server/Practice, server/PracticeYard, client/PracticeFx): your own
-- yard of straw dummies and chests on perches. A countdown, then `seconds` to tag out every dummy
-- and open every chest. Practice only: no coins, XP or keys, but a full clear goes on the Fastest
-- Time Trial board. Dummies have `hearts` (a poke takes 1, a throw Config.Throw.damage); `moving`
-- of them slide to and fro. Chests sit `perch` studs up and open with Config.Chests.hold. Each
-- player's yard is built at centre + (slot - 1) x spacing on Z, and gone when they leave.
-- Aim settings each player picks (Settings, Aim; shared/AimSettings checks them, client/Aim applies
-- them): mouse sensitivity, field of view, the reticle's size (x its normal size) and thickness (its
-- lines, in pixels), opacity (1 = solid) and outline thickness (pixels) as { min, max, step,
-- default }; the reticle's shape (none hides it), colour and outline colour (none for no outline).
Config.Aim = {
	sensitivity = { 0.2, 3, 0.1, 1 },
	fov = { 60, 100, 5, 70 },
	reticleSize = { 0.5, 2.5, 0.1, 1 },
	reticleThickness = { 1, 6, 1, 2 },
	reticleOpacity = { 0.2, 1, 0.1, 1 },
	reticleOutlineThickness = { 1, 3, 1, 1 },
	outlines = { "black", "white", "none" },
	reticles = { "crossdot", "dot", "cross", "circle", "none" },
	colours = { { "white", 255, 255, 255 }, { "red", 235, 40, 45 }, { "yellow", 255, 214, 60 }, { "green", 80, 230, 110 }, { "cyan", 70, 220, 240 }, { "pink", 255, 110, 200 } },
}

Config.Practice = { seconds = 180, countdown = 3, dummies = 8, moving = 3, hearts = 3, chests = 5, perch = { 3.5, 7 },
	size = 100, centre = Vector3.new(-700, 0, 0), spacing = 180, backAfter = 10 }

Config.Stance = require(script.Parent.ConfigMoves).Stance -- crouch and slide
Config.Look = require(script.Parent.ConfigLook) -- the sun, sky, haze and wind presets

return Config

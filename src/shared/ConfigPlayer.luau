-- Stamina, fitness and the metal detector (Config.luau merges this file in: read and tune
-- them as Config.Stamina, Config.Fitness, Config.MetalDetector).
local Config = {}

-- Each swing carves a dent this big where you hit (on your screen), down to `floor` of how full
-- the clump really is, so you see the damage without the heap looking emptier than it is.
Config.Dent = { radius = 1.8, floor = 0.4 }

-- Sprinting (Shift / L3 / RUN): this many times your walking speed.
Config.Sprint = { multiplier = 1.6 }

-- Stamina: each harvest click spends perHarvest; it refills regenPerSecond all the time. Out of
-- breath (0), you rest regenDelay seconds, then until it's back to `recover`. Fitness upgrades
-- it (coins; level n costs price x growth^(n-1); stat: max, regen or walk = Humanoid.WalkSpeed).
Config.Stamina = { max = 100, perHarvest = 1, regenPerSecond = 2.5, regenDelay = 1, recover = 15, walkSpeed = 16 }
Config.Fitness = {
	{ id = "arms", name = "Stronger Arms", stat = "max", per_level = 50, levels = 5, price = 285, growth = 3, text = "+50 stamina per level" },
	{ id = "breath", name = "Second Wind", stat = "regen", per_level = 0.25, levels = 4, price = 475, growth = 3, text = "+0.25 stamina a second per level" },
	{ id = "boots", name = "Light Boots", stat = "walk", per_level = 1.5, levels = 4, price = 570, growth = 3, text = "+1.5 walking speed per level" },
}
-- Metal detector (bought once): hold `key` to sweep. Within `range` studs of your needle's clump
-- it beeps, faster and higher the closer your head is (signal 1-5; beep = seconds per signal).
Config.MetalDetector = { price = 855, range = 30, levels = 5, pollSeconds = 0.25, key = "V", beep = { 1.2, 0.9, 0.65, 0.45, 0.28 } }

-- Touch screens (phones, tablets). A touch that stays within dragPixels and lifts before
-- holdSeconds harvests once at the crosshair; one held still longer keeps harvesting; one that
-- moves further is looking around and never harvests. Touches starting in the bottom-left
-- stickArea (share of the screen's width, and of its height from the top) belong to the
-- thumbstick. minScale: the smallest UI scale on touch screens, so text stays readable and
-- buttons tappable. The action pad (right side, above the jump button): button size, gap, columns.
Config.Touch = {
	holdSeconds = 0.35,
	dragPixels = 14,
	stickArea = { 0.4, 1 / 3 },
	minScale = 0.68,
	padButton = { 76, 50 },
	padGap = 6,
	padColumns = 3,
}

Config.SkinPulseSeconds = 3 -- one slow swell and fade of an animated skin's glow
Config.SkinGleamSeconds = 0.9 -- how long a skin's shine takes to sweep along the tool
-- A new farmer's first straws come off faster (the loose outer hay), so the first half hour
-- shows real progress: factor x straws for the first `straws` harvested by hand (saved, once).
Config.EarlyBoost = { straws = 20000, factor = 3 }
Config.LobbyAfterSearches = 200 -- new farmers start on their farm; after this many harvests, they arrive in Sky Meadow
Config.CameraZoom = { near = 6, far = 18 } -- the optional over-the-shoulder view (V): studs from your head
Config.CinematicsOn = true -- the story's camera scenes (shared/Cinematics); false = talk only
Config.ToolScale = 0.5 -- the built tools' size: 1 = the 6-stud pitchfork, which held out too far in first person
Config.ToolFanSpin = 9 -- radians a second the Twin Turbines' fans turn while held

-- The shop's tool pictures: the owner's tool sheet (an uploaded image, 1408 x 768 as drawn) and,
-- for each tool in Config.Tools order, the square of it to show: { left, top, width, height } as
-- shares of the sheet. image = "" shows no pictures.
Config.ToolSheet = { image = "rbxassetid://137332962726664", cells = {
	{ 0.025, 0.091, 0.192, 0.352 }, { 0.170, 0.111, 0.206, 0.378 }, { 0.330, 0.111, 0.206, 0.378 }, { 0.487, 0.091, 0.206, 0.378 }, { 0.636, 0.091, 0.206, 0.378 },
	{ 0.799, 0.072, 0.199, 0.365 }, { 0.028, 0.527, 0.227, 0.417 }, { 0.256, 0.527, 0.234, 0.430 }, { 0.497, 0.527, 0.241, 0.443 }, { 0.735, 0.534, 0.234, 0.430 },
} }

return Config

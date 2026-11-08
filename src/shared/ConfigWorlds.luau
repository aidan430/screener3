-- The four portal worlds (Config.luau merges this file in: read and tune them as Config.Worlds,
-- Config.WorldMoods and the other Config.World* numbers).
local Config = {}

-- One row per world, in unlock order. price = coins to open its portal once (saved);
-- multiplier = coins per straw there, times the normal straw value (and your coin multiplier);
-- straws = how many straws its haystack holds before a fresh one (with a new needle) grows;
-- x, z = the world's centre (studs; stay far from the farm and from the lobby, Config.Lobby).
Config.Worlds = {
	{ id = "moon", name = "The Moon", price = 75000, multiplier = 3, straws = 60000, x = 0, z = 2500 },
	{ id = "lava", name = "Ember Lands", price = 750000, multiplier = 6, straws = 120000, x = 2500, z = 0 },
	{ id = "atlantis", name = "Bubble City", price = 5000000, multiplier = 12, straws = 240000, x = 0, z = -2500 },
	{ id = "field", name = "Haystack Stadium", price = 25000000, multiplier = 25, straws = 480000, x = -2500, z = 0 },
}
Config.WorldSize = 300 -- each world is about this many studs across
Config.WorldInside = 220 -- within this many studs (flat) of a world's centre you are "in" it
Config.WorldNeedleEarliest = 0.25 -- a world's needle hides after this share of its straws
Config.WorldNeedleSearches = 5000 -- the needle pays this many clicks of straw at that world's rate
Config.WorldHaystackSize = 30 -- the haystack's main ball (studs)

-- The portal arches stand in the lobby (ConfigLobby.luau: Config.LobbyPortals).

-- Moon gravity: an upward push cancelling this share of normal gravity while you're there.
Config.MoonLift = 0.7
-- Lava never hurts: stepping on it nudges you back to the bank at this speed (studs/s).
Config.LavaPush = { out = 30, up = 50, every = 0.4, toastEvery = 4 }
Config.WorldFadeSeconds = 1.6 -- the light eases this long on arrival and on leaving
Config.WorldTitleSeconds = 3.5 -- the world's name stays on screen this long

-- The light in each world (applied on your own screen only, eased in and out).
Config.WorldMoods = {
	moon = { clock = 0, brightness = 2, ambient = { 90, 96, 112 }, outdoor = { 150, 156, 176 }, shift = { 196, 210, 255 }, color = { 10, 10, 18 }, decay = { 0, 0, 0 }, density = 0, haze = 0, glare = 0 },
	lava = { clock = 18.2, brightness = 1.6, ambient = { 110, 52, 40 }, outdoor = { 170, 86, 60 }, shift = { 255, 128, 64 }, color = { 255, 120, 70 }, decay = { 120, 34, 20 }, density = 0.42, haze = 2, glare = 0.4 },
	atlantis = { clock = 13, brightness = 1.4, ambient = { 60, 104, 134 }, outdoor = { 96, 156, 186 }, shift = { 120, 204, 255 }, color = { 60, 140, 190 }, decay = { 20, 64, 112 }, density = 0.5, haze = 2.4, glare = 0 },
	field = { clock = 14, brightness = 3, ambient = { 112, 112, 112 }, outdoor = { 176, 176, 176 }, shift = { 255, 250, 240 }, color = { 200, 222, 255 }, decay = { 150, 180, 220 }, density = 0.2, haze = 0.6, glare = 0.2 },
}

-- Each world's hay (three shades) for its haystack.
Config.WorldHay = {
	moon = { { 196, 200, 210 }, { 170, 176, 188 }, { 222, 226, 234 } },
	lava = { { 240, 124, 40 }, { 220, 96, 30 }, { 255, 160, 70 } },
	atlantis = { { 70, 170, 140 }, { 50, 140, 116 }, { 110, 200, 170 } },
	field = { { 96, 176, 70 }, { 76, 150, 56 }, { 130, 200, 96 } },
}

return Config

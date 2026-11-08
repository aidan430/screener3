-- The lobby: a floating meadow island where everyone arrives, with a walk-in portal arch to the
-- farm and to each world (Config.luau merges this file in: read and tune them as
-- Config.Lobby, Config.LobbyPortals and the other Config.Lobby* numbers).
local Config = {}

Config.LobbyName = "Sky Meadow"
-- The island's centre (x, z; studs) and the height of its grass. Far from the farm (about 170
-- from the middle) and from the four worlds (2,500 out on each axis, 220 round each).
Config.Lobby = { x = 1300, floor = 0, z = 1300 }
Config.LobbyRadius = 70 -- the island is this many studs from its centre to its rim (140 across)
Config.LobbyInside = 130 -- within this many studs (flat) of the centre you are "in" the lobby
Config.LobbyArrival = { 0, 40 } -- where you arrive ({ x, z } from the centre), facing the arches (north)

-- The portal arches, in a semicircle 48 studs north of the centre, facing it. id "farm" is your
-- farm (free, always open); the others are Config.Worlds ids, opened once with coins.
-- at = { x, z } from the lobby's centre.
Config.LobbyPortals = {
	{ id = "moon", at = { -43.1, -21 } },
	{ id = "lava", at = { -25.4, -40.7 } },
	{ id = "farm", at = { 0, -48 } },
	{ id = "atlantis", at = { 25.4, -40.7 } },
	{ id = "field", at = { 43.1, -21 } },
}
Config.LobbyFarmColour = { 242, 196, 82 } -- the farm arch's glow (straw gold)
-- The arch on the farm that leads back here: x studs west of the middle, `past` studs beyond the
-- south edge of the build area (Config.PlotSize / 2), and never nearer than `behind` studs south
-- of where you arrive (Config.FarmEntrance). It faces the haystack.
Config.LobbyFarmPortal = { x = -26, past = 8, behind = 14 }
Config.PortalTexture = "" -- the portals' flowing light: upload assets/portal/portal-flow.png, paste "rbxassetid://..."
Config.PortalModel = 0 -- your own portal design saved to Roblox (its asset ID); or put a Model named Portal in ServerStorage > Designs
Config.PortalFlow = 4
-- The built-in portal's design (server/PortalShape), as the Portal Designer page sends it.
-- shape: "round" | "arch" | "door" | "hex"; radius (round, hex) or width and height (arch, door);
-- thick and depth: the frame's stones; stones: how many round the frame; base: "round" |
-- "square" | "none"; lanterns: 0, 2 or 4; glow: the opening's see-through (0 solid .. 1 clear).
Config.PortalDesign = { -- the owner's design, sent from the Portal Designer on 8 Nov 2026
	shape = "arch", radius = 5.6, width = 10.6, height = 13, thick = 2.2, depth = 4, stones = 18,
	base = "round", lanterns = 2, gem = false, sign = true, lip = true, glow = 0.5, material = "Granite",
	stoneA = { 0, 0, 0 }, stoneB = { 0, 0, 0 }, wood = { 92, 66, 3 },
}

return Config

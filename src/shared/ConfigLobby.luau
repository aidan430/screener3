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
Config.PortalFlow = 2.5 -- studs a second the portals' light flows upwards
Config.LobbyPortalCooldown = 2 -- seconds between two trips through any arch
Config.LobbyFade = { into = 0.35, hold = 0.3, out = 0.9 } -- the soft fade round every trip (seconds)
Config.LobbyNudge = { back = 26, up = 12 } -- a locked arch eases you back out (studs/s)
Config.LobbyFallBelow = -60 -- anyone who drifts off the island below this height is set back on it

-- The lobby's light (eased in on your own screen, like a world's): a bright, soft sky morning.
Config.LobbyMood = { clock = 13, brightness = 2.6, ambient = { 112, 118, 132 }, outdoor = { 172, 182, 198 }, shift = { 255, 246, 232 }, color = { 214, 230, 255 }, decay = { 156, 182, 220 }, density = 0.3, haze = 1.2, glare = 0.2 }

return Config

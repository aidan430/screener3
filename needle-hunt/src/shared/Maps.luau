-- The maps: what each is called, its light and its colours. server/MapsA and server/MapsB build
-- them (`builder` names the function) and list their hiding spots as they place each prop, so
-- every spot sits on a real surface in reach. Add a map: a line here plus a builder.
--   look: the name of a preset in shared/ConfigLook (sun, sky, haze, clouds, grade): server/Look.
--   lighting: the old plain light, kept for the dev previews (dev/preview/render.html) only.
--   straw: the colour of loose straw (and of a camouflaged needle); clutter tints vary round it.
local Maps = {}

Maps.list = {
	-- the big map (server/MapsBig): duration = its round length, powerups = orbs about, landmarkChests =
	-- how many chests go up on its climbable landmarks (the rest deep in its mazes)
	{ id = "bigfarm", name = "Hayfield Farm", builder = "bigfarm", look = "harvest", weight = 20, duration = 300, powerups = 18, landmarkChests = 3,
		lighting = { ClockTime = 14.5, Brightness = 2.7, Ambient = { 124, 118, 102 }, OutdoorAmbient = { 158, 150, 130 }, FogEnd = 1400, FogColor = { 205, 226, 246 } },
		straw = { 226, 188, 92 }, ground = { 100, 158, 72 } },
	{ id = "field", name = "Classic Haystack Field", builder = "field", look = "noon", weight = 25,
		lighting = { ClockTime = 14, Brightness = 2.6, Ambient = { 120, 116, 104 }, OutdoorAmbient = { 150, 146, 134 }, FogEnd = 900, FogColor = { 200, 225, 245 } },
		straw = { 226, 188, 92 }, ground = { 104, 160, 76 } },
	{ id = "barn", name = "Barn Interior", builder = "barn", look = "interior", weight = 20,
		lighting = { ClockTime = 13, Brightness = 1.4, Ambient = { 120, 96, 70 }, OutdoorAmbient = { 110, 90, 66 }, FogEnd = 400, FogColor = { 120, 96, 70 } },
		straw = { 214, 172, 80 }, ground = { 120, 86, 56 } },
	{ id = "sunset", name = "Farm at Sunset", builder = "sunset", look = "dusk", weight = 20,
		lighting = { ClockTime = 17.7, Brightness = 2.2, Ambient = { 130, 96, 80 }, OutdoorAmbient = { 170, 120, 96 }, FogEnd = 700, FogColor = { 250, 170, 120 } },
		straw = { 232, 170, 84 }, ground = { 120, 150, 70 } },
	{ id = "forest", name = "Night Forest", builder = "forest", look = "night", weight = 15,
		lighting = { ClockTime = 0.5, Brightness = 1.1, Ambient = { 70, 80, 110 }, OutdoorAmbient = { 90, 100, 140 }, FogEnd = 260, FogColor = { 30, 40, 64 } },
		straw = { 196, 170, 100 }, ground = { 52, 84, 52 } },
	{ id = "attic", name = "Abandoned Attic", builder = "attic", look = "interior", weight = 20,
		lighting = { ClockTime = 15, Brightness = 1.2, Ambient = { 110, 100, 90 }, OutdoorAmbient = { 100, 92, 84 }, FogEnd = 300, FogColor = { 110, 100, 90 } },
		straw = { 206, 176, 112 }, ground = { 112, 86, 64 } },
	-- from the owner's Gemini map sheets (server/MapsC)
	{ id = "pumpkin", name = "Pumpkin Patch", builder = "pumpkin", look = "gold", weight = 15,
		lighting = { ClockTime = 15, Brightness = 2.6, Ambient = { 124, 116, 100 }, OutdoorAmbient = { 156, 146, 128 }, FogEnd = 900, FogColor = { 205, 225, 245 } },
		straw = { 226, 188, 92 }, ground = { 96, 156, 70 } },
	{ id = "corn", name = "Harvest Corn Maze", builder = "corn", look = "gold", weight = 15,
		lighting = { ClockTime = 15.5, Brightness = 2.7, Ambient = { 132, 120, 96 }, OutdoorAmbient = { 168, 150, 118 }, FogEnd = 900, FogColor = { 220, 226, 236 } },
		straw = { 232, 196, 96 }, ground = { 170, 140, 84 } },
	{ id = "sunflower", name = "Sunflower Labyrinth", builder = "sunflower", look = "noon", weight = 15,
		lighting = { ClockTime = 13, Brightness = 2.8, Ambient = { 126, 120, 100 }, OutdoorAmbient = { 160, 152, 128 }, FogEnd = 900, FogColor = { 210, 230, 248 } },
		straw = { 226, 188, 92 }, ground = { 150, 112, 72 } },
	{ id = "orchard", name = "Apple Orchard", builder = "orchard", look = "noon", weight = 15,
		lighting = { ClockTime = 12.5, Brightness = 2.7, Ambient = { 120, 120, 104 }, OutdoorAmbient = { 150, 154, 134 }, FogEnd = 900, FogColor = { 205, 228, 248 } },
		straw = { 222, 190, 100 }, ground = { 104, 164, 74 } },
	{ id = "windmill", name = "Windmill Hill", builder = "windmill", look = "gold", weight = 15,
		lighting = { ClockTime = 16, Brightness = 2.6, Ambient = { 128, 118, 100 }, OutdoorAmbient = { 160, 148, 126 }, FogEnd = 900, FogColor = { 214, 226, 240 } },
		straw = { 226, 188, 92 }, ground = { 104, 158, 76 } },
	-- the second batch (server/MapsD)
	{ id = "frozen", name = "Frozen Farm", builder = "frozen", look = "overcast", weight = 15,
		lighting = { ClockTime = 13, Brightness = 2.4, Ambient = { 140, 146, 160 }, OutdoorAmbient = { 176, 184, 200 }, FogEnd = 900, FogColor = { 226, 236, 248 } },
		straw = { 226, 196, 120 }, ground = { 236, 242, 250 } },
	{ id = "greenhouse", name = "Rainy Greenhouse", builder = "greenhouse", look = "overcast", weight = 15,
		lighting = { ClockTime = 11, Brightness = 2.0, Ambient = { 120, 128, 132 }, OutdoorAmbient = { 148, 158, 166 }, FogEnd = 900, FogColor = { 196, 210, 220 } },
		straw = { 214, 184, 104 }, ground = { 150, 150, 156 } },
	{ id = "marsh", name = "Duck Pond Marsh", builder = "marsh", look = "overcast", weight = 15,
		lighting = { ClockTime = 14, Brightness = 2.6, Ambient = { 118, 124, 106 }, OutdoorAmbient = { 150, 158, 136 }, FogEnd = 900, FogColor = { 206, 228, 236 } },
		straw = { 214, 184, 104 }, ground = { 150, 112, 76 } },
	{ id = "market", name = "Hay Market", builder = "market", look = "noon", weight = 15,
		lighting = { ClockTime = 14.5, Brightness = 2.7, Ambient = { 128, 120, 102 }, OutdoorAmbient = { 162, 152, 128 }, FogEnd = 900, FogColor = { 214, 228, 244 } },
		straw = { 226, 188, 92 }, ground = { 200, 170, 120 } },
	{ id = "fair", name = "County Fair", builder = "fair", look = "noon", weight = 15,
		lighting = { ClockTime = 15, Brightness = 2.8, Ambient = { 130, 122, 112 }, OutdoorAmbient = { 166, 156, 144 }, FogEnd = 900, FogColor = { 218, 230, 248 } },
		straw = { 226, 188, 92 }, ground = { 214, 186, 140 } },
}

-- The lobby's light, between rounds.
Maps.lobbyLook = "noon"
Maps.lobbyLighting = { ClockTime = 14.5, Brightness = 2.5, Ambient = { 120, 116, 104 }, OutdoorAmbient = { 150, 146, 134 }, FogEnd = 1200, FogColor = { 200, 225, 245 } }

local byId = {}
for _, m in ipairs(Maps.list) do
	byId[m.id] = m
end

function Maps.get(id)
	return byId[id]
end

return Maps

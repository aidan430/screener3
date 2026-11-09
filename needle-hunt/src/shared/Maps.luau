-- The maps: what each is called, its light and its colours. server/MapsA and server/MapsB build
-- them (`builder` names the function) and list their hiding spots as they place each prop, so
-- every spot sits on a real surface in reach. Add a map: a line here plus a builder.
--   lighting: Lighting's ClockTime, Brightness, Ambient, OutdoorAmbient, FogEnd, FogColor.
--   straw: the colour of loose straw (and of a camouflaged needle); clutter tints vary round it.
local Maps = {}

Maps.list = {
	{ id = "field", name = "Classic Haystack Field", builder = "field", weight = 25,
		lighting = { ClockTime = 14, Brightness = 2.6, Ambient = { 120, 116, 104 }, OutdoorAmbient = { 150, 146, 134 }, FogEnd = 900, FogColor = { 200, 225, 245 } },
		straw = { 226, 188, 92 }, ground = { 104, 160, 76 } },
	{ id = "barn", name = "Barn Interior", builder = "barn", weight = 20,
		lighting = { ClockTime = 13, Brightness = 1.4, Ambient = { 120, 96, 70 }, OutdoorAmbient = { 110, 90, 66 }, FogEnd = 400, FogColor = { 120, 96, 70 } },
		straw = { 214, 172, 80 }, ground = { 120, 86, 56 } },
	{ id = "sunset", name = "Farm at Sunset", builder = "sunset", weight = 20,
		lighting = { ClockTime = 17.7, Brightness = 2.2, Ambient = { 130, 96, 80 }, OutdoorAmbient = { 170, 120, 96 }, FogEnd = 700, FogColor = { 250, 170, 120 } },
		straw = { 232, 170, 84 }, ground = { 120, 150, 70 } },
	{ id = "forest", name = "Night Forest", builder = "forest", weight = 15,
		lighting = { ClockTime = 0.5, Brightness = 1.1, Ambient = { 70, 80, 110 }, OutdoorAmbient = { 90, 100, 140 }, FogEnd = 260, FogColor = { 30, 40, 64 } },
		straw = { 196, 170, 100 }, ground = { 52, 84, 52 } },
	{ id = "attic", name = "Abandoned Attic", builder = "attic", weight = 20,
		lighting = { ClockTime = 15, Brightness = 1.2, Ambient = { 110, 100, 90 }, OutdoorAmbient = { 100, 92, 84 }, FogEnd = 300, FogColor = { 110, 100, 90 } },
		straw = { 206, 176, 112 }, ground = { 112, 86, 64 } },
}

-- The lobby's light, between rounds.
Maps.lobbyLighting = { ClockTime = 14.5, Brightness = 2.5, Ambient = { 120, 116, 104 }, OutdoorAmbient = { 150, 146, 134 }, FogEnd = 1200, FogColor = { 200, 225, 245 } }

local byId = {}
for _, m in ipairs(Maps.list) do
	byId[m.id] = m
end

function Maps.get(id)
	return byId[id]
end

return Maps

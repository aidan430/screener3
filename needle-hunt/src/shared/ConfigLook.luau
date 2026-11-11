-- The look of the world (server/Look): the sun, sky, haze, clouds, glow, colour grade and wind for
-- each kind of map, as presets. A map names one in shared/Maps (`look = "harvest"`); the lobby uses
-- Maps.lobbyLook. Config.luau merges this in as Config.Look. Colours are { r, g, b }.
-- These are starting points chosen on paper: tune them in Studio (Play, graphics level at maximum).
--
-- The place file (default.project.json) sets what scripts cannot: realistic lighting, the modern
-- materials and 3D grass on terrain. Look only warns if that didn't load.
local Look = {}

-- sunElevation (degrees above the horizon): if given, Look picks the clock time between Sun.from
-- and Sun.to whose sun is nearest that height (a low sun would black out the maze corridors).
Look.Sun = { from = 12.5, to = 17.5, step = 0.05 }

-- A darker round (the difficulty's dim, plus a Low Light round): per 1.0 of dim, exposure drops by
-- `exposure`, both ambients lose `ambient` of themselves, the haze thickens by `density`, colour
-- fades by `saturation` and the tint moves `tint` of the way to `tintTo`.
Look.Dim = { exposure = 1.6, ambient = 0.5, density = 0.1, saturation = 0.15, tint = 0.5, tintTo = { 200, 214, 255 } }

-- The wind gusts: every `every` seconds (a random time between the two) it is the preset's wind
-- times a random amount between `strength`'s two numbers. It moves grass, clouds and particles.
Look.Gust = { every = { 6, 10 }, strength = { 0.7, 1.3 } }

Look.Sky = { SunAngularSize = 14, MoonAngularSize = 9, StarCount = 3000 }

local function preset(t)
	return t
end

Look.presets = {
	harvest = preset({ ClockTime = 15, sunElevation = 36, Brightness = 3, ExposureCompensation = 0.05, ShadowSoftness = 0.2,
		Ambient = { 58, 54, 62 }, OutdoorAmbient = { 108, 104, 116 }, ColorShift_Top = { 52, 32, 10 },
		atmosphere = { Density = 0.3, Offset = 0.25, Haze = 1.5, Glare = 0.3, Color = { 228, 198, 148 }, Decay = { 116, 104, 120 } },
		clouds = { Cover = 0.52, Density = 0.35, Color = { 255, 240, 222 } },
		bloom = { Intensity = 0.6, Size = 28, Threshold = 1.7 },
		grade = { Contrast = 0.12, Saturation = 0.08, TintColor = { 255, 245, 232 } },
		sunRays = { Intensity = 0.1, Spread = 0.6 }, wind = { 9, 0, 4 } }),
	gold = preset({ ClockTime = 16.2, Brightness = 3, ExposureCompensation = 0.1, ShadowSoftness = 0.25,
		Ambient = { 58, 52, 62 }, OutdoorAmbient = { 104, 98, 112 }, ColorShift_Top = { 60, 38, 12 },
		atmosphere = { Density = 0.3, Offset = 0.25, Haze = 1.6, Glare = 0.35, Color = { 232, 196, 140 }, Decay = { 120, 98, 110 } },
		clouds = { Cover = 0.55, Density = 0.35, Color = { 255, 236, 214 } },
		bloom = { Intensity = 0.8, Size = 28, Threshold = 1.8 },
		grade = { Contrast = 0.12, Saturation = 0.1, TintColor = { 255, 244, 230 } },
		sunRays = { Intensity = 0.12, Spread = 0.6 }, wind = { 9, 0, 4 } }),
	noon = preset({ ClockTime = 13.5, Brightness = 3, ExposureCompensation = 0, ShadowSoftness = 0.15,
		Ambient = { 60, 62, 66 }, OutdoorAmbient = { 95, 100, 108 }, ColorShift_Top = { 12, 8, 0 },
		atmosphere = { Density = 0.28, Offset = 0.25, Haze = 0.6, Glare = 0.1, Color = { 199, 206, 214 }, Decay = { 106, 112, 125 } },
		clouds = { Cover = 0.5, Density = 0.3, Color = { 255, 255, 255 } },
		bloom = { Intensity = 0.5, Size = 24, Threshold = 2 },
		grade = { Contrast = 0.08, Saturation = 0.05, TintColor = { 255, 255, 255 } },
		sunRays = { Intensity = 0.05, Spread = 0.4 }, wind = { 6, 0, 3 } }),
	overcast = preset({ ClockTime = 12.5, Brightness = 1.3, ExposureCompensation = 0.25, ShadowSoftness = 1,
		Ambient = { 96, 100, 106 }, OutdoorAmbient = { 150, 154, 160 }, ColorShift_Top = { 0, 0, 0 },
		atmosphere = { Density = 0.42, Offset = 0.1, Haze = 2.4, Glare = 0, Color = { 190, 196, 204 }, Decay = { 120, 126, 134 } },
		clouds = { Cover = 0.92, Density = 0.55, Color = { 200, 204, 210 } },
		bloom = { Intensity = 0.3, Size = 24, Threshold = 2 },
		grade = { Contrast = 0.05, Saturation = -0.12, TintColor = { 236, 242, 255 } },
		wind = { 12, 0, 5 } }),
	dusk = preset({ ClockTime = 17.5, Brightness = 2.4, ExposureCompensation = 0.25, ShadowSoftness = 0.4,
		Ambient = { 70, 54, 66 }, OutdoorAmbient = { 124, 96, 104 }, ColorShift_Top = { 110, 56, 18 },
		atmosphere = { Density = 0.36, Offset = 0.3, Haze = 2.2, Glare = 0.8, Color = { 250, 170, 120 }, Decay = { 96, 70, 120 } },
		clouds = { Cover = 0.6, Density = 0.4, Color = { 255, 190, 150 } },
		bloom = { Intensity = 0.9, Size = 32, Threshold = 1.6 },
		grade = { Contrast = 0.14, Saturation = 0.14, TintColor = { 255, 232, 214 } },
		sunRays = { Intensity = 0.2, Spread = 0.7 }, wind = { 5, 0, 2 } }),
	night = preset({ ClockTime = 0.5, Brightness = 1.6, ExposureCompensation = 0.6, ShadowSoftness = 0.5,
		Ambient = { 38, 46, 72 }, OutdoorAmbient = { 64, 76, 112 }, ColorShift_Top = { 0, 8, 30 },
		atmosphere = { Density = 0.42, Offset = 0.1, Haze = 1.2, Glare = 0, Color = { 60, 74, 110 }, Decay = { 20, 26, 44 } },
		clouds = { Cover = 0.35, Density = 0.3, Color = { 120, 130, 160 } },
		bloom = { Intensity = 1, Size = 30, Threshold = 1.2 },
		grade = { Contrast = 0.1, Saturation = -0.1, TintColor = { 214, 226, 255 } },
		wind = { 3, 0, 1 } }),
	interior = preset({ ClockTime = 15, Brightness = 2, ExposureCompensation = 0.4, ShadowSoftness = 0.5,
		Ambient = { 104, 88, 70 }, OutdoorAmbient = { 120, 104, 86 }, ColorShift_Top = { 40, 26, 8 },
		atmosphere = { Density = 0.2, Offset = 0, Haze = 0.8, Glare = 0, Color = { 190, 160, 120 }, Decay = { 90, 76, 60 } },
		clouds = { Cover = 0.4, Density = 0.3, Color = { 255, 255, 255 } },
		bloom = { Intensity = 0.6, Size = 24, Threshold = 1.6 },
		grade = { Contrast = 0.08, Saturation = 0, TintColor = { 255, 240, 220 } },
		wind = { 0, 0, 0 } }),
}

-- Detail on each player's own device (client/LookFx): if the frame rate averaged over `window`
-- seconds stays under `lowFps` during a round, the detail drops a step. blur: the lobby's soft
-- far blur (depth of field): its strength, the distance in focus and how deep that band is.
Look.Tiers = { window = 4, lowFps = 28, blur = { far = 0.15, focus = 120, radius = 50 } }

-- The land (server/Landscape): terrain colours; Hayfield Farm's floor materials by quarter style
-- (corn, vines, hedge, stonehedge) and its roads; the frame of fields and hills round the arena
-- (from `inner` to `outer` studs out: `mounds` low hills at mound.at out, and a ridge of
-- ridge.radius balls ridge.at out whose tops are ridge.top high, hiding the world's edge);
-- the water; and the lobby's mounds. Sizes are studs, on the terrain's 4-stud grid.
Look.Terrain = {
	colours = { Grass = { 88, 124, 54 }, LeafyGrass = { 96, 118, 60 }, Ground = { 134, 108, 76 }, Mud = { 84, 66, 50 }, Cobblestone = { 150, 146, 136 }, Rock = { 112, 110, 104 } },
	play = 188, depth = 16,
	quarters = { corn = "Ground", vines = "Mud", hedge = "Grass", stonehedge = "LeafyGrass" },
	yards = { corn = "Cobblestone", vines = "Ground", hedge = "Ground", stonehedge = "Cobblestone" }, yard = 14,
	road = { half = 8, rut = 4, ring = { 156, 180 }, ringRuts = { { 160, 164 }, { 172, 176 } }, cross = 12 },
	frame = { inner = 188, outer = 440, mounds = 24, mound = { at = { 290, 330 }, radius = 70, top = { 12, 24 }, lane = 40 }, ridge = { at = 392, radius = 90, top = 40, every = 96 } },
	water = { x = -292, z = 0, radius = 20, depth = 5, colour = { 58, 92, 84 } },
	lobby = { mounds = 12, at = 150, radius = 46, top = { 14, 18, 22 } },
}

return Look

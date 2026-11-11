-- The look of the world, from Config.Look's presets: the sun, sky, haze (Atmosphere), clouds, glow
-- (Bloom), colour grade, sun rays and wind. Look.init makes those once; Look.apply(name, dim)
-- switches preset (server/RoundManager: a map's look for its round, the lobby's between rounds).
-- Everything here is set on the server and copies to every player. Realistic lighting, the modern
-- materials and terrain grass come from the place file (scripts can't set them): init warns if the
-- lighting didn't load that way.
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local L = Config.Look

local Look = {}
local fx = {} -- atmosphere, clouds, bloom, grade, sunRays
local solved = {} -- [preset] = { clock, sun (a unit vector towards the sun, or nil) }
local wind = Vector3.zero
local rng = Random.new()

local function rgb(c)
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function make(class, parent)
	local found = parent:FindFirstChildOfClass(class)
	if found then
		return found
	end
	local made = Instance.new(class)
	made.Parent = parent
	return made
end

-- Sets each key of `values` on `instance` (a { r, g, b } becomes a colour).
local function set(instance, values)
	for key, value in pairs(values) do
		instance[key] = if type(value) == "table" then rgb(value) else value
	end
end

local function sunAt(clock)
	Lighting.ClockTime = clock
	local ok, dir = pcall(Lighting.GetSunDirection, Lighting)
	return if ok and typeof(dir) == "Vector3" then dir else nil
end

-- The clock time (and the sun's direction then) for a preset: the one whose sun is nearest
-- sunElevation if it asks for a height, else its own ClockTime.
local function solve(p)
	local clock, sun = p.ClockTime, sunAt(p.ClockTime)
	if p.sunElevation and sun then
		local best = math.huge
		local t = L.Sun.from
		while t <= L.Sun.to do
			local dir = sunAt(t)
			local off = if dir then math.abs(math.deg(math.asin(math.clamp(dir.Y, -1, 1))) - p.sunElevation) else math.huge
			if off < best then
				best, clock, sun = off, t, dir
			end
			t += L.Sun.step
		end
	end
	return { clock = clock, sun = sun }
end

-- The direction towards the sun in a preset (a unit vector), or nil if it couldn't be read.
function Look.sunFor(name)
	return solved[name] and solved[name].sun
end

-- Switches to a preset. dim (0 and up) darkens it: a harder difficulty, a Low Light round.
function Look.apply(name, dim)
	if not fx.atmosphere then -- asked before start-up got to it
		Look.init()
	end
	local p = L.presets[name] or L.presets.noon
	local s = solved[name] or solved.noon or { clock = p.ClockTime }
	dim = dim or 0
	local D = L.Dim
	Lighting.ClockTime = s.clock
	Lighting.Brightness, Lighting.ShadowSoftness = p.Brightness, p.ShadowSoftness
	Lighting.ExposureCompensation = p.ExposureCompensation - D.exposure * dim
	local keep = 1 - D.ambient * math.min(dim, 1)
	local ambient, outdoor = rgb(p.Ambient), rgb(p.OutdoorAmbient)
	Lighting.Ambient = Color3.new(ambient.R * keep, ambient.G * keep, ambient.B * keep) -- before OutdoorAmbient: the engine keeps that at least as bright
	Lighting.OutdoorAmbient = Color3.new(outdoor.R * keep, outdoor.G * keep, outdoor.B * keep)
	Lighting.ColorShift_Top = rgb(p.ColorShift_Top)
	set(fx.atmosphere, p.atmosphere)
	fx.atmosphere.Density = math.min(1, p.atmosphere.Density + D.density * dim)
	set(fx.clouds, p.clouds)
	set(fx.bloom, p.bloom)
	set(fx.grade, p.grade)
	fx.grade.Brightness = 0
	fx.grade.Saturation = p.grade.Saturation - D.saturation * dim
	fx.grade.TintColor = rgb(p.grade.TintColor):Lerp(rgb(D.tintTo), math.min(1, D.tint * dim))
	fx.sunRays.Enabled = p.sunRays ~= nil
	if p.sunRays then
		set(fx.sunRays, p.sunRays)
	end
	wind = Vector3.new(p.wind[1], p.wind[2], p.wind[3])
	workspace.GlobalWind = wind
end

function Look.init()
	if fx.atmosphere then
		return
	end
	Lighting.GlobalShadows = true
	Lighting.EnvironmentDiffuseScale, Lighting.EnvironmentSpecularScale = 1, 1
	Lighting.ColorShift_Bottom = Color3.new(0, 0, 0)
	fx.atmosphere = make("Atmosphere", Lighting)
	set(make("Sky", Lighting), L.Sky)
	fx.bloom = make("BloomEffect", Lighting)
	fx.grade = make("ColorCorrectionEffect", Lighting)
	fx.sunRays = make("SunRaysEffect", Lighting)
	fx.clouds = make("Clouds", workspace.Terrain)
	local ok, style = pcall(function()
		return Lighting.LightingStyle
	end)
	if ok and style ~= Enum.LightingStyle.Realistic then
		warn("[Look] the place file's lighting did not load as Realistic: see README, The realistic look")
	end
	for name, p in pairs(L.presets) do
		solved[name] = solve(p)
	end
	Look.apply("noon")
	task.spawn(function() -- gusts
		while true do
			task.wait(rng:NextNumber(L.Gust.every[1], L.Gust.every[2]))
			workspace.GlobalWind = wind * rng:NextNumber(L.Gust.strength[1], L.Gust.strength[2])
		end
	end)
end

return Look

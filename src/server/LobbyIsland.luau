-- The lobby's island, Sky Meadow: a round floating meadow (Config.Lobby, Config.LobbyRadius)
-- with a rocky underside, soft clouds round it, a cobbled plaza with a fountain, benches, a
-- lily pond, lanterns, flower boxes, hay bales, a welcome sign and the Robux Corner's sign.
-- Plain anchored parts; the arches themselves are built by server/Lobby.luau.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Build = require(script.Parent.Build)
local Kit = require(script.Parent.SceneryKit)

local Island = {}

local GRASS = { 126, 184, 96 }
local STONE = { 196, 186, 170 }
local ROCK = { 122, 104, 88 }
local WATER = { 128, 196, 226 }
local WOOD = { 150, 108, 70 }
local HAY = { 226, 190, 98 }
local FLOWERS = { { 246, 168, 196 }, { 255, 226, 120 }, { 196, 170, 246 }, { 255, 250, 244 }, { 250, 160, 120 } }

-- A point { x, z } studs from the centre, at angle `deg` clockwise from north (-z).
local function around(radius, deg)
	local a = math.rad(deg)
	return radius * math.sin(a), -radius * math.cos(a)
end

-- A flat round slab whose top is at height `top`.
local function disc(parent, base, name, x, z, radius, top, height, colour, material, opts)
	local cf = CFrame.new(x, top - height / 2, z) * CFrame.Angles(0, 0, math.rad(90))
	return Kit.part(parent, base, name, Vector3.new(height, radius * 2, radius * 2), cf, colour, material, opts)
end

-- A frame at { x, z } on the island looking at { tx, tz } (its -Z faces there).
local function facing(base, x, z, tx, tz)
	local here, there = base * Vector3.new(x, 0, z), base * Vector3.new(tx, 0, tz)
	if (there - here).Magnitude < 0.1 then
		return CFrame.new(here)
	end
	return CFrame.lookAt(here, there)
end

local function body(folder, base, R)
	local m = Kit.model(folder, "Island")
	disc(m, base, "Meadow", 0, 0, R, 0, 3, GRASS, "Grass")
	disc(m, base, "Rim", 0, 0, R + 1.2, -0.5, 3, { 150, 132, 104 }, "Slate")
	local layers = { { 0.97, -3, 7 }, { 0.84, -9, 8 }, { 0.64, -16, 9 }, { 0.42, -24, 10 }, { 0.2, -33, 12 } }
	for i, l in ipairs(layers) do
		local shade = 1 - i * 0.06
		disc(m, base, "Underside", 0, 0, R * l[1], l[2], l[3], { ROCK[1] * shade, ROCK[2] * shade, ROCK[3] * shade }, "Rock")
	end
	-- a low stone wall round the rim, with an invisible rail above it so nobody strolls off
	local segments = 36
	for i = 1, segments do
		local x, z = around(R - 0.6, i * 360 / segments)
		local cf = facing(base, x, z, 0, 0)
		Build.part({ name = "RimWall", size = Vector3.new(2 * math.pi * R / segments + 0.3, 1.6, 1.2), cframe = cf * CFrame.new(0, 0.8, 0), color = STONE, material = "Slate", parent = m })
		Build.part({ name = "RimRail", size = Vector3.new(2 * math.pi * R / segments + 0.3, 10, 1), cframe = cf * CFrame.new(0, 6.5, 0), transparency = 1, shadow = false, parent = m })
	end
end

local function sky(folder, base, R)
	local m = Kit.model(folder, "Clouds")
	local rng = Random.new(7)
	for i = 1, 16 do
		local x, z = around(R + rng:NextNumber(40, 110), i * 22.5 + rng:NextNumber(-8, 8))
		local y = if i % 3 == 0 then rng:NextNumber(30, 60) else rng:NextNumber(-55, -15)
		for j = 1, 3 do
			local size = rng:NextNumber(16, 30)
			Kit.part(m, base, "Cloud", Vector3.new(size, size * 0.6, size), Vector3.new(x + j * 12 - 24, y + rng:NextNumber(-3, 3), z + rng:NextNumber(-6, 6)), { 252, 252, 255 }, "SmoothPlastic", { shape = "Ball", collide = false, shadow = false, transparency = 0.25 })
		end
	end
	for i = 1, 6 do -- little floating islets
		local x, z = around(R + rng:NextNumber(25, 55), i * 60 + 20)
		local y, r = rng:NextNumber(-20, 6), rng:NextNumber(4, 8)
		disc(m, base, "Islet", x, z, r, y, 1.6, GRASS, "Grass")
		disc(m, base, "IsletRock", x, z, r * 0.7, y - 1.6, 4, ROCK, "Rock")
	end
end

local function plaza(folder, base)
	local m = Kit.model(folder, "Plaza")
	disc(m, base, "Plaza", 0, 0, 22, 0.15, 0.4, STONE, "Cobblestone")
	-- paths from the plaza to each arch, and from where you arrive
	local ends = {}
	for _, p in ipairs(Config.LobbyPortals) do
		table.insert(ends, p.at)
	end
	table.insert(ends, { Config.LobbyArrival[1], Config.LobbyArrival[2] + 6 })
	for _, e in ipairs(ends) do
		local dir = Vector3.new(e[1], 0, e[2]).Unit
		local a, b = dir * 20, Vector3.new(e[1], 0, e[2]) - dir * 2
		Kit.part(m, base, "Path", Vector3.new(6, 0.3, (b - a).Magnitude), CFrame.lookAt((a + b) / 2 + Vector3.new(0, -0.05, 0), b + Vector3.new(0, -0.05, 0)), STONE, "Cobblestone")
	end
	-- the fountain: a stone basin, a column, a little bowl and a glowing straw-gold ball
	disc(m, base, "FountainBasin", 0, 0, 7, 0.9, 0.8, STONE, "Slate")
	disc(m, base, "FountainWater", 0, 0, 6.2, 1.15, 0.3, WATER, "Glass", { transparency = 0.2, collide = false })
	for i = 1, 16 do
		local x, z = around(6.6, i * 22.5)
		Kit.part(m, base, "FountainRim", Vector3.new(2.9, 0.9, 1), facing(CFrame.new(), x, z, 0, 0) * CFrame.new(0, 1.35, 0), STONE, "Slate")
	end
	Kit.post(m, base, "FountainColumn", Vector3.new(0, 0.9, 0), 5, 1.6, STONE, "Slate")
	local bowl = disc(m, base, "FountainBowl", 0, 0, 2.6, 6.2, 0.8, STONE, "Slate")
	local orb = Kit.part(m, base, "FountainOrb", Vector3.new(1.8, 1.8, 1.8), Vector3.new(0, 7.3, 0), HAY, "Neon", { shape = "Ball", collide = false })
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness = Color3.fromRGB(255, 220, 150), 18, 0.8
	light.Parent = orb
	local drops = Instance.new("ParticleEmitter") -- water spilling softly from the bowl
	drops.Color = ColorSequence.new(Build.rgb(WATER))
	drops.Rate, drops.Lifetime, drops.Speed = 26, NumberRange.new(0.8, 1.1), NumberRange.new(2.5, 3.5)
	drops.SpreadAngle = Vector2.new(180, 10)
	drops.Acceleration = Vector3.new(0, -14, 0)
	drops.Size = NumberSequence.new(0.25)
	drops.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	drops.Parent = bowl
end

local function bench(parent, cf)
	local m = Kit.model(parent, "Bench")
	Kit.part(m, cf, "BenchSeat", Vector3.new(5, 0.4, 1.6), Vector3.new(0, 1.6, 0), WOOD, "WoodPlanks")
	Kit.part(m, cf, "BenchBack", Vector3.new(5, 1.4, 0.3), Vector3.new(0, 2.7, 0.75), WOOD, "WoodPlanks")
	for _, x in ipairs({ -2.1, 2.1 }) do
		Kit.part(m, cf, "BenchLeg", Vector3.new(0.4, 1.4, 1.4), Vector3.new(x, 0.7, 0), { 70, 62, 58 }, "Metal")
	end
end

local function flowerBox(parent, cf, rng)
	local m = Kit.model(parent, "FlowerBox")
	Kit.part(m, cf, "Planter", Vector3.new(5, 1.4, 1.8), Vector3.new(0, 0.7, 0), WOOD, "WoodPlanks")
	Kit.part(m, cf, "Soil", Vector3.new(4.6, 0.2, 1.4), Vector3.new(0, 1.42, 0), { 96, 70, 48 }, "Ground")
	for i = 1, 6 do
		local x = -2 + (i - 1) * 0.8
		local h = rng:NextNumber(0.6, 1.2)
		Kit.bit(m, cf, "Stem", Vector3.new(0.15, h, 0.15), Vector3.new(x, 1.5 + h / 2, rng:NextNumber(-0.3, 0.3)), { 90, 150, 70 }, "Grass")
		Kit.bit(m, cf, "Flower", Vector3.new(0.6, 0.6, 0.6), Vector3.new(x, 1.5 + h, 0), FLOWERS[rng:NextInteger(1, #FLOWERS)], "SmoothPlastic", "Ball")
	end
end

local function bales(parent, cf)
	local m = Kit.model(parent, "HayBales")
	for i, at in ipairs({ Vector3.new(-3.2, 3, 0), Vector3.new(3.2, 3, 0), Vector3.new(0, 8.2, 0) }) do
		Kit.part(m, cf, "RoundBale", Vector3.new(5, 6, 6), CFrame.new(at) * CFrame.Angles(0, if i == 3 then 0.3 else 0, 0), HAY, "Fabric", { shape = "Cylinder" })
	end
	Kit.part(m, cf, "SquareBale", Vector3.new(4, 2.2, 2.4), Vector3.new(0, 1.1, -5), HAY, "Fabric")
end

local function pond(folder, base, x, z)
	local m = Kit.model(folder, "Pond")
	disc(m, base, "PondEdge", x, z, 9.6, 0.3, 0.6, STONE, "Slate")
	disc(m, base, "PondWater", x, z, 8.6, 0.4, 0.2, WATER, "Glass", { transparency = 0.15 })
	local rng = Random.new(3)
	for i = 1, 5 do
		local dx, dz = around(rng:NextNumber(2, 6), i * 72 + rng:NextNumber(-20, 20))
		disc(m, base, "LilyPad", x + dx, z + dz, rng:NextNumber(0.7, 1.1), 0.52, 0.1, { 96, 160, 82 }, "Grass", { collide = false })
		if i % 2 == 1 then
			Kit.bit(m, base, "LilyFlower", Vector3.new(0.5, 0.5, 0.5), Vector3.new(x + dx, 0.75, z + dz), FLOWERS[1], "SmoothPlastic", "Ball")
		end
	end
	for i = 1, 9 do
		local dx, dz = around(9.2, i * 26 + 140)
		Kit.bit(m, base, "Reed", Vector3.new(0.25, 3 + (i % 3), 0.25), Vector3.new(x + dx, 1.5 + (i % 3) / 2, z + dz), { 106, 150, 72 }, "Grass")
	end
	bench(m, facing(base, x + 13, z + 9, x, z))
	bench(m, facing(base, x + 4, z + 15, x, z))
end

local function details(folder, base, R)
	local m = Kit.model(folder, "Decor")
	for i = 1, 4 do -- benches round the fountain
		local x, z = around(13, i * 90 - 45)
		bench(m, facing(base, x, z, 0, 0))
	end
	for i = 0, 9 do -- lanterns round the rim (one gap for the Robux Corner's sign)
		local x, z = around(R - 5, i * 36 + 18)
		if i ~= 3 then
			Kit.lantern(m, facing(base, x, z, 0, 0), 7)
		end
	end
	local a = Config.LobbyArrival
	for _, side in ipairs({ -5, 5 }) do
		Kit.lantern(m, facing(base, a[1] + side, a[2] - 10, 0, 0), 6)
	end
	local rng = Random.new(5)
	for _, deg in ipairs({ -150, -130, -110, -48, -16, 16, 48, 190, 205 }) do
		local x, z = around(R - 8, deg)
		flowerBox(m, facing(base, x, z, 0, 0), rng)
	end
	local bx, bz = around(R - 12, -90)
	bales(m, facing(base, bx, bz, 0, 0))
	local hx, hz = around(R - 12, 215)
	bales(m, facing(base, hx, hz, 0, 0))
	pond(m, base, -40, 20)
	-- the welcome sign beside where you arrive, and the Robux Corner's sign behind its pads
	Kit.sign(m, facing(base, a[1] - 12, a[2] - 6, a[1], a[2] + 6), "Welcome to " .. Config.LobbyName .. "!\nWalk into an arch to travel", 11)
	local sx, sz = around(R - 5, 129)
	Kit.sign(m, facing(base, sx, sz, 0, 0), "Robux Corner\nOptional extras", 11)
end

-- Builds the island under `folder`; returns the frame at its centre (y = the grass).
function Island.build(folder)
	local l = Config.Lobby
	local base = CFrame.new(l.x, l.floor, l.z)
	local R = Config.LobbyRadius
	body(folder, base, R)
	sky(folder, base, R)
	plaza(folder, base)
	details(folder, base, R)
	return base
end

return Island

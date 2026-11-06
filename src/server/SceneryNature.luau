-- The living countryside (see Scenery): dirt lanes, the duck pond, the pumpkin and corn
-- fields, an apple orchard, and autumn trees and bushes filling every gap left in the ring
-- between the plots and the fence (Kit.RING_IN to Kit.RING_OUT).
-- Terrain Grass is never used here (it is kept for the straw heaps).
local Kit = require(script.Parent.SceneryKit)

local Nature = {}
local C = Kit.C
local part, bit = Kit.part, Kit.bit
local terrain = workspace.Terrain
local ORIGIN = CFrame.new()

Nature.POND = Vector3.new(-100, 0, 205)
Nature.POND_RADIUS = 24
Nature.WATER_Y = -1

-- (terrain is pulled in by Config.FarmScale here; the parts are pulled in after building)
local function dirt(x, z, sx, sz, material)
	local k = Kit.SCALE
	terrain:FillBlock(CFrame.new(x * k, -2, z * k), Vector3.new(sx * k, 4, sz * k), material or Enum.Material.Ground)
end

function Nature.terrain()
	dirt(0, -210, 16, 100) -- the north lane, from the end of the road out through the gate
	dirt(-22, -169, 336, 8) -- the farmyard lane, silos to chicken run
	dirt(-125, -175.5, 20, 5) -- in front of the barn doors
	dirt(60, -178.5, 6, 11) -- up to the farmhouse steps
	dirt(-164, 0, 8, 290) -- the pens' lane, along their gates
	dirt(206, -91, 62, 124) -- the pumpkin patch
	dirt(206, 92, 62, 124) -- the corn rows
	dirt(-200, -127, 16, 12, Enum.Material.Mud) -- the pigs' favourite mud
	local k = Kit.SCALE
	local pond, r = Nature.POND * k, Nature.POND_RADIUS * k
	terrain:FillCylinder(CFrame.new(pond.X, -4, pond.Z), 8, r + 4, Enum.Material.Mud)
	terrain:FillCylinder(CFrame.new(pond.X, -3, pond.Z), 6, r, Enum.Material.Air)
	terrain:FillCylinder(CFrame.new(pond.X, -3.5, pond.Z), 5, r, Enum.Material.Water)
	terrain.WaterColor = Color3.fromRGB(86, 124, 112)
	terrain.WaterWaveSize = 0.05
	terrain.WaterWaveSpeed = 4
end

local function tree(m, base, rng, height)
	Kit.post(m, base, "Trunk", Vector3.zero, height, rng:NextNumber(2, 3), { 96, 66, 44 }, "Wood")
	for _ = 1, 3 do
		local s = rng:NextNumber(9, 15)
		local offset = Vector3.new(rng:NextNumber(-3.5, 3.5), height + rng:NextNumber(-1, 4), rng:NextNumber(-3.5, 3.5))
		part(m, base, "Leaves", Vector3.new(s, s, s), offset, Kit.AUTUMN[rng:NextInteger(1, #Kit.AUTUMN)], "Fabric", { shape = "Ball", collide = false })
	end
end

local function bush(m, base, rng)
	local color = if rng:NextNumber() < 0.6 then { 96, 122, 52 } else Kit.AUTUMN[rng:NextInteger(1, #Kit.AUTUMN)]
	for _ = 1, rng:NextInteger(2, 3) do
		local s = rng:NextNumber(3, 6)
		bit(m, base, "Bush", Vector3.new(s, s, s), Vector3.new(rng:NextNumber(-2, 2), s * 0.35, rng:NextNumber(-2, 2)), color, "Fabric", "Ball")
	end
end

-- Trees and bushes wherever the farm is clear, between the plots and the tree line.
local function wilds(folder)
	local m = Kit.model(folder, "Trees")
	local rng = Random.new(23)
	local planted = 0
	local edge = Kit.RING_OUT - 2
	local function inRing(x, z, margin)
		return math.max(math.abs(x), math.abs(z)) > Kit.RING_IN + margin and Kit.clear(x, z, margin)
	end
	for _ = 1, 700 do
		local x, z = rng:NextNumber(-edge, edge), rng:NextNumber(-edge, edge)
		if planted < 70 and inRing(x, z, 8) then
			tree(m, CFrame.new(x, 0, z) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0), rng, rng:NextNumber(10, 18))
			planted += 1
		end
	end
	local bushes = Kit.model(folder, "Bushes")
	for _ = 1, 600 do
		local x, z = rng:NextNumber(-edge, edge), rng:NextNumber(-edge, edge)
		if inRing(x, z, 3) then
			bush(bushes, CFrame.new(x, 0, z), rng)
		end
	end
end

local function orchard(folder)
	local m = Kit.model(folder, "Orchard")
	local rng = Random.new(5)
	for x = 48, 228, 20 do -- a smaller orchard: ten trees by three rows, south-east
		for z = 182, 226, 22 do
			local base = CFrame.new(x + rng:NextNumber(-2, 2), 0, z + rng:NextNumber(-2, 2))
			Kit.post(m, base, "Trunk", Vector3.zero, 7, 1.6, { 104, 72, 48 }, "Wood")
			for _, o in ipairs({ { -1.5, 8, 0, 9 }, { 1.6, 9, 0.8, 8 } }) do
				part(m, base, "Leaves", Vector3.new(o[4], o[4], o[4]), Vector3.new(o[1], o[2], o[3]), { 104, 128, 56 }, "Fabric", { shape = "Ball", collide = false })
			end
			for _ = 1, 5 do
				local a, b = rng:NextNumber(0, 6.28), rng:NextNumber(-0.4, 0.9)
				local at = Vector3.new(math.cos(a) * math.cos(b) * 4.6, 8.5 + math.sin(b) * 4.4, math.sin(a) * math.cos(b) * 4.6)
				bit(m, base, "Apple", Vector3.new(0.8, 0.8, 0.8), at, { 196, 54, 44 }, "SmoothPlastic", "Ball")
			end
			if rng:NextNumber() < 0.5 then
				bit(m, base, "FallenApple", Vector3.new(0.8, 0.8, 0.8), Vector3.new(rng:NextNumber(-3, 3), 0.4, rng:NextNumber(-3, 3)), { 196, 54, 44 }, "SmoothPlastic", "Ball")
			end
		end
	end
end

local function pumpkins(folder)
	local m = Kit.model(folder, "PumpkinPatch")
	local rng = Random.new(31)
	for x = 180, 234, 9 do
		part(m, ORIGIN, "Row", Vector3.new(3, 0.6, 118), Vector3.new(x, 0.3, -91), C.soil, "Sand", { collide = false })
		bit(m, ORIGIN, "Vine", Vector3.new(1.4, 0.3, 116), Vector3.new(x, 0.7, -91), { 92, 118, 50 }, "Fabric")
		for z = -147, -35, 7 do
			local far = math.abs(x - 207) > 4 or math.abs(z + 91) > 4 -- leave room for the scarecrow
			if far and rng:NextNumber() < 0.75 then
				local s = rng:NextNumber(1.8, 3.2)
				local tone = { 232 + rng:NextInteger(-12, 12), 124 + rng:NextInteger(-20, 20), 36 }
				local at = Vector3.new(x + rng:NextNumber(-0.6, 0.6), s * 0.45 + 0.4, z + rng:NextNumber(-1, 1))
				part(m, ORIGIN, "Pumpkin", Vector3.new(s, s, s), at, tone, "SmoothPlastic", { shape = "Ball", collide = false })
				bit(m, ORIGIN, "Stem", Vector3.new(0.3, 0.7, 0.3), at + Vector3.new(0, s / 2, 0), C.stem, "Wood")
			end
		end
	end
end

local function corn(folder)
	local m = Kit.model(folder, "CornRows")
	local rng = Random.new(41)
	for x = 179, 235, 8 do
		part(m, ORIGIN, "Row", Vector3.new(2.4, 0.5, 118), Vector3.new(x, 0.25, 92), C.soil, "Sand", { collide = false })
		for z = 35, 149, 4.5 do
			if math.abs(x - 207) < 6 and math.abs(z - 92) < 5 then
				continue -- room for the scarecrow
			end
			local h = rng:NextNumber(6.5, 9)
			local base = CFrame.new(x + rng:NextNumber(-0.4, 0.4), 0, z) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0)
			bit(m, base, "Stalk", Vector3.new(0.45, h, 0.45), Vector3.new(0, h / 2, 0), { 188, 168, 82 }, "Fabric")
			bit(m, base, "CornLeaf", Vector3.new(3.4, 0.15, 0.7), CFrame.new(0, h * 0.55, 0) * CFrame.Angles(0, 0, math.rad(-25)), { 168, 160, 70 }, "Fabric")
			if rng:NextNumber() < 0.5 then
				bit(m, base, "Cob", Vector3.new(0.6, 1.4, 0.6), CFrame.new(0.4, h * 0.6, 0) * CFrame.Angles(0, 0, math.rad(-20)), { 240, 200, 90 }, "SmoothPlastic")
			end
		end
	end
end

-- Reeds and cattails round the pond, lily pads, a little dock and some smooth stones.
local function pondside(folder)
	local m = Kit.model(folder, "Pond")
	local rng = Random.new(17)
	local pond, r = Nature.POND, Nature.POND_RADIUS
	for _ = 1, 70 do
		local a = rng:NextNumber(0, math.pi * 2)
		if math.abs(math.cos(a)) > 0.2 or math.sin(a) > 0 then -- not on the dock (north side)
			local d = rng:NextNumber(r - 3, r + 3)
			local h = rng:NextNumber(3, 6)
			local base = CFrame.new(pond.X + math.cos(a) * d, -1.5, pond.Z + math.sin(a) * d) * CFrame.Angles(rng:NextNumber(-0.15, 0.15), 0, rng:NextNumber(-0.15, 0.15))
			bit(m, base, "Reed", Vector3.new(0.2, h, 0.2), Vector3.new(0, h / 2, 0), { 112, 132, 60 }, "Fabric")
			if rng:NextNumber() < 0.4 then
				bit(m, base, "Cattail", Vector3.new(0.45, 1.2, 0.45), Vector3.new(0, h - 0.4, 0), { 110, 70, 40 }, "Fabric")
			end
		end
	end
	for _ = 1, 14 do
		local a, d = rng:NextNumber(0, math.pi * 2), rng:NextNumber(6, r - 6)
		local at = CFrame.new(pond.X + math.cos(a) * d, Nature.WATER_Y + 0.05, pond.Z + math.sin(a) * d)
		bit(m, at, "LilyPad", Vector3.new(0.15, 2.6, 2.6), CFrame.Angles(0, 0, math.rad(90)), { 96, 140, 70 }, "SmoothPlastic", "Cylinder")
		if rng:NextNumber() < 0.35 then
			bit(m, at, "LilyFlower", Vector3.new(0.7, 0.7, 0.7), Vector3.new(0.4, 0.3, 0), { 246, 190, 210 }, "SmoothPlastic", "Ball")
		end
	end
	local dock = CFrame.new(pond.X, 0, pond.Z - r + 7)
	part(m, dock, "Dock", Vector3.new(6, 0.6, 18), Vector3.new(0, 0.9, 0), C.plank, "WoodPlanks")
	for _, x in ipairs({ -2.6, 2.6 }) do
		for _, z in ipairs({ -8, 0, 8 }) do
			part(m, dock, "DockPost", Vector3.new(0.7, 4, 0.7), Vector3.new(x, -0.6, z), C.darkWood, "Wood")
		end
	end
	for i = 1, 10 do
		local a = i / 10 * math.pi * 2 + 0.3
		local s = rng:NextNumber(1.5, 3.5)
		bit(m, CFrame.new(pond.X + math.cos(a) * (r + 5), s * 0.2, pond.Z + math.sin(a) * (r + 5)), "Stone", Vector3.new(s, s * 0.7, s), Vector3.zero, { 150, 144, 136 }, "Slate")
	end
end

function Nature.build(folder)
	local jobs = { wilds, orchard, pumpkins, corn, pondside }
	for _, job in ipairs(jobs) do
		local ok, err = pcall(job, folder)
		if not ok then
			warn("[Scenery] nature part failed: " .. tostring(err))
		end
	end
end

return Nature

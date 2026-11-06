-- Animal pens just west of the plots and the cute blocky animals in them: pigs, cows and sheep
-- along the pens' lane, chickens (with their coop) in the farmyard to the north, and ducks on
-- the pond to the south. The animals are anchored, walk-through
-- Models (pivot at their feet, facing local -Z); client/Animals moves them gently. Each one
-- carries attributes: Kind, PenMin/PenMax (where it may wander), HeadHinge/TailHinge (local
-- points its "Head" and "Tail" parts turn about).
local Kit = require(script.Parent.SceneryKit)

local Pens = {}
local C = Kit.C
local part, bit = Kit.part, Kit.bit

-- A rail fence round a pen, with a gate gap in the middle of its east side (toward the lane).
local function pen(m, cx, cz, w, d)
	local fence = Kit.model(m, "PenFence")
	local half = { w / 2, d / 2 }
	for _, side in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
		local alongX = side[1] == 0
		local length = if alongX then w else d
		local gated = side[1] == 1
		local spans = if gated then { { -length / 2, -3 }, { 3, length / 2 } } else { { -length / 2, length / 2 } }
		local function at(along, y)
			return if alongX then Vector3.new(cx + along, y, cz + side[2] * half[2]) else Vector3.new(cx + side[1] * half[1], y, cz + along)
		end
		for _, span in ipairs(spans) do
			local n = math.max(1, math.floor((span[2] - span[1]) / 5 + 0.5))
			for i = 0, n do
				local along = span[1] + (span[2] - span[1]) * i / n
				part(fence, CFrame.new(), "PenPost", Vector3.new(0.7, if gated and math.abs(along) < 4 then 5 else 4, 0.7), at(along, 2), C.wood, "Wood")
			end
			for _, y in ipairs({ 1.6, 3.2 }) do
				local l = span[2] - span[1]
				part(fence, CFrame.new(), "PenRail", if alongX then Vector3.new(l, 0.35, 0.3) else Vector3.new(0.3, 0.35, l), at((span[1] + span[2]) / 2, y), C.plank, "Wood")
			end
		end
	end
	return Vector3.new(cx - w / 2 + 4, 0, cz - d / 2 + 4), Vector3.new(cx + w / 2 - 4, 0, cz + d / 2 - 4)
end

local function trough(m, base, water)
	part(m, base, "Trough", Vector3.new(6, 1.6, 2), Vector3.new(0, 0.8, 0), if water then C.metal else C.wood, if water then "Metal" else "WoodPlanks")
	bit(m, base, if water then "TroughWater" else "TroughFeed", Vector3.new(5.6, 0.2, 1.6), Vector3.new(0, 1.55, 0), if water then { 96, 140, 150 } else C.hay, "SmoothPlastic")
end

-- A little red chicken coop on stilts, door facing local -Z, with a ramp down.
local function coop(m, base)
	for _, x in ipairs({ -2.6, 2.6 }) do
		for _, z in ipairs({ -3.4, 3.4 }) do
			part(m, base, "CoopStilt", Vector3.new(0.6, 2.4, 0.6), Vector3.new(x, 1.2, z), C.darkWood, "Wood")
		end
	end
	part(m, base, "Coop", Vector3.new(6, 4, 8), Vector3.new(0, 4.4, 0), C.red, "WoodPlanks")
	for _, s in ipairs({ -1, 1 }) do
		part(m, base, "CoopRoof", Vector3.new(4.4, 0.4, 9), CFrame.new(s * 1.9, 7.2, 0) * CFrame.Angles(0, 0, s * math.rad(-30)), C.roof, "WoodPlanks")
	end
	bit(m, base, "CoopDoor", Vector3.new(1.8, 2, 0.2), Vector3.new(0, 3.6, -4.05), C.shadow, "Wood")
	Kit.beam(m, base, "Ramp", Vector3.new(0, 2.6, -4.1), Vector3.new(0, 0.2, -8), 1.6, C.plank, "WoodPlanks", { collide = false })
end

-- Builds an animal: `parts` is a list of { name, size, position, colour, shape?, material? }.
local function animal(folder, kind, at, yaw, parts, head, tail, min, max)
	local m = Instance.new("Model")
	m.Name = kind
	local root = CFrame.new(at) * CFrame.Angles(0, yaw, 0)
	local r = part(m, root, "Root", Vector3.new(1, 1, 1), Vector3.zero, C.trim, "SmoothPlastic", { collide = false, shadow = false, transparency = 1 })
	m.PrimaryPart = r
	for _, p in ipairs(parts) do
		bit(m, root, p[1], p[2], p[3], p[4], p[6] or "SmoothPlastic", p[5])
	end
	m:SetAttribute("Kind", kind)
	m:SetAttribute("PenMin", min)
	m:SetAttribute("PenMax", max)
	m:SetAttribute("HeadHinge", head)
	m:SetAttribute("TailHinge", tail)
	m.Parent = folder
	return m
end

local V = Vector3.new
local PINK, BLACK, CREAM, YELLOW, RED = { 236, 160, 164 }, { 40, 36, 36 }, { 240, 234, 220 }, { 240, 196, 70 }, { 210, 60, 50 }

local function cow(folder, at, yaw, min, max, brown)
	local coat = if brown then { 158, 104, 66 } else { 242, 238, 228 }
	local spot = if brown then CREAM else BLACK
	local p = {
		{ "Body", V(4, 3.4, 7.4), V(0, 4.6, 0), coat },
		{ "Spot", V(0.2, 1.6, 2), V(2.05, 4.9, 1), spot },
		{ "Spot", V(0.2, 1.4, 1.8), V(-2.05, 4.3, -1.6), spot },
		{ "Spot", V(2, 0.2, 2.2), V(0.6, 6.35, 1.6), spot },
		{ "Udder", V(1.6, 0.8, 1.4), V(0, 2.6, 1.8), PINK },
		{ "Head", V(2.6, 2.6, 2.8), V(0, 6, -4.8), coat },
		{ "Head", V(2.4, 1.4, 0.8), V(0, 5.4, -6.4), PINK },
		{ "Head", V(0.45, 0.45, 0.45), V(0.8, 6.6, -6.25), BLACK, "Ball" },
		{ "Head", V(0.45, 0.45, 0.45), V(-0.8, 6.6, -6.25), BLACK, "Ball" },
		{ "Head", V(0.4, 0.9, 0.4), V(0.9, 7.6, -4.6), CREAM },
		{ "Head", V(0.4, 0.9, 0.4), V(-0.9, 7.6, -4.6), CREAM },
		{ "Head", V(1, 0.4, 0.6), V(1.7, 6.8, -4.4), coat },
		{ "Head", V(1, 0.4, 0.6), V(-1.7, 6.8, -4.4), coat },
		{ "Tail", V(0.3, 3, 0.3), V(0, 4.7, 3.85), coat },
		{ "Tail", V(0.6, 0.8, 0.6), V(0, 3.1, 3.85), spot },
	}
	for _, x in ipairs({ -1.4, 1.4 }) do
		for _, z in ipairs({ -2.6, 2.6 }) do
			table.insert(p, { "Leg", V(1, 3, 1), V(x, 1.5, z), coat })
		end
	end
	return animal(folder, "Cow", at, yaw, p, V(0, 6, -3.6), V(0, 6.1, 3.85), min, max)
end

local function pig(folder, at, yaw, min, max)
	local p = {
		{ "Body", V(3, 2.6, 4.6), V(0, 2.6, 0), PINK },
		{ "Head", V(2.2, 2.2, 1.8), V(0, 3, -3), PINK },
		{ "Head", V(1.2, 0.9, 0.5), V(0, 2.7, -4.1), { 222, 132, 140 } },
		{ "Head", V(0.35, 0.35, 0.35), V(0.55, 3.5, -3.92), BLACK, "Ball" },
		{ "Head", V(0.35, 0.35, 0.35), V(-0.55, 3.5, -3.92), BLACK, "Ball" },
		{ "Head", V(0.8, 0.2, 0.7), V(0.75, 4.15, -2.7), { 222, 132, 140 } },
		{ "Head", V(0.8, 0.2, 0.7), V(-0.75, 4.15, -2.7), { 222, 132, 140 } },
		{ "Tail", V(0.3, 0.3, 0.8), V(0, 3.3, 2.6), PINK },
		{ "Tail", V(0.4, 0.4, 0.4), V(0, 3.6, 2.9), PINK, "Ball" },
	}
	for _, x in ipairs({ -1, 1 }) do
		for _, z in ipairs({ -1.6, 1.6 }) do
			table.insert(p, { "Leg", V(0.8, 1.4, 0.8), V(x, 0.7, z), PINK })
		end
	end
	return animal(folder, "Pig", at, yaw, p, V(0, 3, -2.2), V(0, 3.3, 2.3), min, max)
end

local function sheep(folder, at, yaw, min, max)
	local dark = { 62, 54, 52 }
	local p = {
		{ "Body", V(2.6, 2.2, 3.6), V(0, 2.9, 0), CREAM, nil, "Fabric" },
		{ "Wool", V(2.9, 2.9, 2.9), V(0, 3.1, -0.9), CREAM, "Ball", "Fabric" },
		{ "Wool", V(2.9, 2.9, 2.9), V(0, 3.1, 0.9), CREAM, "Ball", "Fabric" },
		{ "Wool", V(2.4, 2.4, 2.4), V(0, 3.7, 0), CREAM, "Ball", "Fabric" },
		{ "Head", V(1.4, 1.6, 1.8), V(0, 3.6, -2.6), dark },
		{ "Head", V(1.3, 1.3, 1.3), V(0, 4.5, -2.3), CREAM, "Ball", "Fabric" },
		{ "Head", V(0.8, 0.3, 0.4), V(0.95, 3.9, -2.3), dark },
		{ "Head", V(0.8, 0.3, 0.4), V(-0.95, 3.9, -2.3), dark },
		{ "Head", V(0.3, 0.3, 0.3), V(0.42, 3.9, -3.5), CREAM, "Ball" },
		{ "Head", V(0.3, 0.3, 0.3), V(-0.42, 3.9, -3.5), CREAM, "Ball" },
		{ "Tail", V(0.9, 0.9, 0.9), V(0, 3.3, 2.3), CREAM, "Ball", "Fabric" },
	}
	for _, x in ipairs({ -0.9, 0.9 }) do
		for _, z in ipairs({ -1.3, 1.3 }) do
			table.insert(p, { "Leg", V(0.6, 1.8, 0.6), V(x, 0.9, z), dark })
		end
	end
	return animal(folder, "Sheep", at, yaw, p, V(0, 3.6, -1.8), V(0, 3.5, 2), min, max)
end

local function chicken(folder, at, yaw, min, max, brown)
	local feathers = if brown then { 176, 108, 60 } else { 246, 242, 232 }
	local p = {
		{ "Body", V(1.4, 1.3, 1.8), V(0, 1.5, 0.1), feathers },
		{ "Wing", V(0.2, 0.8, 1.2), V(0.75, 1.5, 0.1), feathers },
		{ "Wing", V(0.2, 0.8, 1.2), V(-0.75, 1.5, 0.1), feathers },
		{ "Tail", V(0.9, 1.1, 0.5), V(0, 2.1, 1.1), feathers },
		{ "Head", V(0.9, 1, 0.9), V(0, 2.5, -0.8), feathers },
		{ "Head", V(0.3, 0.3, 0.45), V(0, 2.4, -1.4), YELLOW },
		{ "Head", V(0.2, 0.5, 0.6), V(0, 3.1, -0.8), RED },
		{ "Head", V(0.2, 0.35, 0.2), V(0, 2.05, -1.25), RED },
		{ "Head", V(0.2, 0.2, 0.2), V(0.42, 2.65, -1.05), BLACK, "Ball" },
		{ "Head", V(0.2, 0.2, 0.2), V(-0.42, 2.65, -1.05), BLACK, "Ball" },
		{ "Leg", V(0.2, 0.9, 0.2), V(0.3, 0.45, 0), YELLOW },
		{ "Leg", V(0.2, 0.9, 0.2), V(-0.3, 0.45, 0), YELLOW },
	}
	return animal(folder, "Chicken", at, yaw, p, V(0, 2.1, -0.5), V(0, 1.8, 0.9), min, max)
end

local function duck(folder, at, yaw, min, max, mallard)
	local coat = if mallard then { 150, 120, 92 } else { 246, 244, 236 }
	local p = {
		{ "Body", V(1.4, 1, 2.2), V(0, 0.3, 0), coat },
		{ "Tail", V(0.6, 0.4, 0.5), V(0, 0.7, 1.2), coat },
		{ "Head", V(0.9, 0.9, 0.9), V(0, 1.3, -0.9), if mallard then { 60, 110, 70 } else coat },
		{ "Head", V(0.5, 0.2, 0.5), V(0, 1.2, -1.5), { 238, 150, 50 } },
		{ "Head", V(0.18, 0.18, 0.18), V(0.46, 1.45, -1.05), BLACK, "Ball" },
		{ "Head", V(0.18, 0.18, 0.18), V(-0.46, 1.45, -1.05), BLACK, "Ball" },
	}
	return animal(folder, "Duck", at, yaw, p, V(0, 0.8, -0.6), V(0, 0.6, 1), min, max)
end

-- Puts `count` animals at random spots inside min..max.
local function herd(folder, rng, count, min, max, make)
	for i = 1, count do
		local at = Vector3.new(rng:NextNumber(min.X, max.X), min.Y, rng:NextNumber(min.Z, max.Z))
		make(folder, at, rng:NextNumber(0, math.pi * 2), min, max, i % 2 == 0)
	end
end

function Pens.build(folder)
	local m = Kit.model(folder, "Pens")
	local animals = Instance.new("Folder")
	animals.Name = "Animals"
	animals.Parent = folder
	local rng = Random.new(3)
	-- each pen's gate (east side) opens onto the pens' lane at x -164; their east fences line up at -170
	local min, max = pen(m, -202, -40, 64, 60) -- cows
	trough(m, CFrame.new(-228, 0, -58) * CFrame.Angles(0, math.pi / 2, 0), true)
	trough(m, CFrame.new(-228, 0, -24) * CFrame.Angles(0, math.pi / 2, 0), false)
	herd(animals, rng, 4, min, max, cow)
	min, max = pen(m, -198, 45, 56, 48) -- sheep
	trough(m, CFrame.new(-198, 0, 63), true)
	herd(animals, rng, 4, min, max, sheep)
	min, max = pen(m, -194, -120, 48, 40) -- pigs, with their mud
	trough(m, CFrame.new(-188, 0, -134), false)
	herd(animals, rng, 3, min, max, pig)
	min, max = pen(m, 135, -205, 48, 40) -- chickens and their coop, in the farmyard
	coop(m, CFrame.lookAt(Vector3.new(121, 0, -205), Vector3.new(160, 0, -205)))
	herd(animals, rng, 9, min + Vector3.new(8, 0, 0), max, chicken)
	-- ducks paddle about the pond (centred at -100, 205, radius 24; the dock is on its north side)
	herd(animals, rng, 4, Vector3.new(-114, -1.1, 198), Vector3.new(-86, -1.1, 218), duck)
end

return Pens

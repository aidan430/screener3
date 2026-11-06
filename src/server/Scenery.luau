-- The countryside of Hollow Creek Farm, packed into the ring between the plots and the fence
-- (about 162 to 238 studs out): a farmyard (silos, barn, farmhouse, chicken run) and the
-- windmill to the north, animal pens to the west, pumpkin and corn fields to the east, the
-- water tower, duck pond, a meadow and the orchard to the south, and a split-rail fence round
-- the farm. All plain anchored Parts in workspace.Scenery; animals and windmill
-- sails are animated on each client (client/Animals). Nothing here goes inside the plots or on
-- the roads.
local Build = require(script.Parent.Build)
local Kit = require(script.Parent.SceneryKit)
local Props = require(script.Parent.SceneryProps)
local Nature = require(script.Parent.SceneryNature)
local Pens = require(script.Parent.SceneryAnimals)

local Scenery = {}
local C = Kit.C
local part, bit, beam = Kit.part, Kit.bit, Kit.beam

local function facing(x, z, toX, toZ)
	return CFrame.lookAt(Vector3.new(x, 0, z), Vector3.new(toX, 0, toZ))
end

-- A big red barn with a gambrel roof, sliding doors and a hay loft opening. Front is local -Z.
local function barn(folder, base)
	local m = Kit.model(folder, "Barn")
	local W, D, H = 40, 52, 20
	part(m, base, "Foundation", Vector3.new(W + 1, 1.5, D + 1), Vector3.new(0, 0.75, 0), C.stone, "Cobblestone")
	part(m, base, "BarnWalls", Vector3.new(W, H, D), Vector3.new(0, H / 2, 0), C.red, "WoodPlanks")
	for _, x in ipairs({ -W / 2, W / 2 }) do
		for _, z in ipairs({ -D / 2, D / 2 }) do
			part(m, base, "CornerTrim", Vector3.new(1.2, H, 1.2), Vector3.new(x, H / 2, z), C.trim, "WoodPlanks")
		end
		for _, z in ipairs({ -14, 0, 14 }) do -- side windows
			part(m, base, "Window", Vector3.new(0.4, 4, 4), Vector3.new(x * 1.01, 11, z), C.shadow, "Wood")
			part(m, base, "WindowTrim", Vector3.new(0.3, 4.8, 0.6), Vector3.new(x * 1.02, 11, z), C.trim, "WoodPlanks", { collide = false })
			part(m, base, "WindowTrim", Vector3.new(0.3, 0.6, 4.8), Vector3.new(x * 1.02, 11, z), C.trim, "WoodPlanks", { collide = false })
		end
	end
	-- the gambrel roof: a steep lower slope and a shallow upper one on each side
	local profile = { { W / 2 + 1.4, H - 0.8 }, { W * 0.32, H + 9 }, { 0, H + 13 } }
	for _, s in ipairs({ -1, 1 }) do
		for i = 1, 2 do
			local a, b = profile[i], profile[i + 1]
			local p1, p2 = Vector3.new(s * a[1], a[2], 0), Vector3.new(s * b[1], b[2], 0)
			local angle = math.atan2(p2.Y - p1.Y, p2.X - p1.X)
			part(m, base, "Roof", Vector3.new((p2 - p1).Magnitude + 0.6, 0.8, D + 2), CFrame.new((p1 + p2) / 2) * CFrame.Angles(0, 0, angle), C.roof, "WoodPlanks")
		end
	end
	part(m, base, "RoofRidge", Vector3.new(1.4, 1, D + 2.4), Vector3.new(0, H + 13.3, 0), C.darkWood, "Wood")
	for _, z in ipairs({ -D / 2 + 0.4, D / 2 - 0.4 }) do -- the gable ends, in planks
		for t = 0, 12 do
			local half = if t < 9 then W / 2 - (W / 2 - W * 0.32) * (t + 0.5) / 9 else W * 0.32 * (1 - (t - 8.5) / 4)
			part(m, base, "Gable", Vector3.new(half * 2, 1.02, 0.8), Vector3.new(0, H + t + 0.5, z), C.red, "WoodPlanks")
		end
	end
	local front = -D / 2
	-- the hay loft opening, with its hood, hoist beam and a bale peeking out
	part(m, base, "LoftOpening", Vector3.new(7, 6, 0.3), Vector3.new(0, H + 5, front - 0.15), C.shadow, "Wood")
	for _, e in ipairs({ { 0, H + 8.2, 8.2, 0.6 }, { 0, H + 1.8, 8.2, 0.6 }, { -3.8, H + 5, 0.6, 6.8 }, { 3.8, H + 5, 0.6, 6.8 } }) do
		bit(m, base, "LoftTrim", Vector3.new(e[3], e[4], 0.3), Vector3.new(e[1], e[2], front - 0.35), C.trim, "WoodPlanks")
	end
	part(m, base, "HoistBeam", Vector3.new(0.8, 0.8, 5), Vector3.new(0, H + 9.4, front - 2), C.darkWood, "Wood")
	bit(m, base, "Rope", Vector3.new(0.15, 3.2, 0.15), Vector3.new(0, H + 7.4, front - 4), { 196, 170, 120 }, "Fabric")
	bit(m, base, "HangingBale", Vector3.new(2.4, 1.6, 1.6), Vector3.new(0, H + 5, front - 4), C.hay, "Fabric")
	bit(m, base, "LoftBale", Vector3.new(3, 2, 1.6), Vector3.new(1.4, H + 3, front - 0.4), C.hay, "Fabric")
	-- the big doors, slid open on their rail
	part(m, base, "Doorway", Vector3.new(16, 15, 0.4), Vector3.new(0, 7.5, front - 0.2), C.shadow, "Wood")
	part(m, base, "DoorRail", Vector3.new(36, 0.5, 0.5), Vector3.new(0, 15.6, front - 0.9), C.black, "Metal", { collide = false })
	for _, x in ipairs({ -12.5, 12.5 }) do
		local z = front - 0.8
		part(m, base, "BarnDoor", Vector3.new(9, 15, 0.6), Vector3.new(x, 7.5, z), C.red, "WoodPlanks")
		for _, e in ipairs({ { 0, 14.6, 9, 0.8 }, { 0, 0.4, 9, 0.8 }, { -4.1, 7.5, 0.8, 15 }, { 4.1, 7.5, 0.8, 15 } }) do
			bit(m, base, "DoorTrim", Vector3.new(e[3], e[4], 0.3), Vector3.new(x + e[1], e[2], z - 0.4), C.trim, "WoodPlanks")
		end
		for _, s in ipairs({ -1, 1 }) do
			beam(m, base, "DoorBrace", Vector3.new(x - 3.6 * s, 1, z - 0.45), Vector3.new(x + 3.6 * s, 14, z - 0.45), 0.7, C.trim, "WoodPlanks", { collide = false })
		end
	end
	for _, x in ipairs({ -18, 18 }) do
		Kit.lantern(m, base * CFrame.new(x, 0, front - 3), 7)
	end
	-- a weathervane on the ridge
	bit(m, base, "VanePost", Vector3.new(0.3, 4, 0.3), Vector3.new(0, H + 15.6, 6), C.black, "Metal")
	bit(m, base, "VaneArrow", Vector3.new(0.3, 0.3, 4), Vector3.new(0, H + 17, 6), C.black, "Metal")
	bit(m, base, "VaneRooster", Vector3.new(0.3, 1.4, 1.6), Vector3.new(0, H + 18, 6), C.black, "Metal")
	-- square bales stacked by the door
	for i, p in ipairs({ { 0, 0 }, { 3.2, 0 }, { 1.6, 1 } }) do
		part(m, base, "SquareBale" .. i, Vector3.new(3, 2, 2), Vector3.new(W / 2 - 3 + p[1], 1 + p[2] * 2, front - 5), C.hay, "Fabric")
	end
end

-- One window on a wall: `frame` is the window's centre on the wall, local -Z pointing out.
local function window(m, frame)
	bit(m, frame, "WindowFrame", Vector3.new(4.2, 5.2, 0.3), Vector3.new(0, 0, -0.15), C.trim, "WoodPlanks")
	bit(m, frame, "WindowGlow", Vector3.new(3.4, 4.4, 0.3), Vector3.new(0, 0, -0.25), { 230, 168, 96 }, "Neon")
	bit(m, frame, "Mullion", Vector3.new(0.3, 4.4, 0.2), Vector3.new(0, 0, -0.45), C.trim, "WoodPlanks")
	bit(m, frame, "Mullion", Vector3.new(3.4, 0.3, 0.2), Vector3.new(0, 0, -0.45), C.trim, "WoodPlanks")
	for _, x in ipairs({ -2.9, 2.9 }) do
		bit(m, frame, "Shutter", Vector3.new(1.4, 4.8, 0.25), Vector3.new(x, 0, -0.15), { 70, 96, 72 }, "WoodPlanks")
	end
end

-- A two-storey farmhouse with a porch, warm windows and a smoking chimney. Front is local -Z.
local function farmhouse(folder, base)
	local m = Kit.model(folder, "Farmhouse")
	local W, D, H = 34, 24, 17
	part(m, base, "Foundation", Vector3.new(W + 1, 1, D + 1), Vector3.new(0, 0.5, 0), C.stone, "Cobblestone")
	part(m, base, "HouseWalls", Vector3.new(W, H, D), Vector3.new(0, H / 2 + 1, 0), C.cream, "WoodPlanks")
	Build.roof({ name = "Roof", color = { 116, 64, 52 }, material = "WoodPlanks", parent = m }, base * CFrame.new(0, H + 1, 0) * CFrame.Angles(0, math.rad(90), 0), D + 3, W)
	local chimney = part(m, base, "Chimney", Vector3.new(3.4, H + 15, 3.4), Vector3.new(W / 2 - 4, (H + 17) / 2, 4), { 150, 74, 58 }, "Brick")
	part(m, base, "ChimneyCap", Vector3.new(4.2, 0.8, 4.2), Vector3.new(W / 2 - 4, H + 16.4, 4), C.stone, "Concrete")
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Rate = 1.5
	smoke.Lifetime = NumberRange.new(6, 9)
	smoke.Speed = NumberRange.new(2, 3)
	smoke.SpreadAngle = Vector2.new(8, 8)
	smoke.EmissionDirection = Enum.NormalId.Top
	smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 7) })
	smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1) })
	smoke.Color = ColorSequence.new(Color3.fromRGB(226, 218, 210))
	smoke.Parent = chimney
	local front = -D / 2
	for _, x in ipairs({ -11, 11 }) do
		window(m, base * CFrame.new(x, 6.5, front))
	end
	for _, x in ipairs({ -11, 0, 11 }) do
		window(m, base * CFrame.new(x, 13.5, front))
	end
	for _, s in ipairs({ -1, 1 }) do
		for _, y in ipairs({ 6.5, 13.5 }) do
			window(m, base * CFrame.new(s * W / 2, y, 0) * CFrame.Angles(0, -s * math.pi / 2, 0))
		end
	end
	part(m, base, "FrontDoor", Vector3.new(3.6, 7, 0.3), Vector3.new(0, 5.5, front - 0.15), { 74, 96, 70 }, "WoodPlanks")
	bit(m, base, "DoorKnob", Vector3.new(0.4, 0.4, 0.4), Vector3.new(1.2, 5.2, front - 0.4), { 220, 180, 80 }, "Metal", "Ball")
	-- the porch: floor, steps, posts, rail and a sloping roof
	local pz = front - 4
	part(m, base, "Porch", Vector3.new(W - 4, 1.2, 8), Vector3.new(0, 1.6, pz), C.plank, "WoodPlanks")
	part(m, base, "Step", Vector3.new(6, 1.5, 1.4), Vector3.new(0, 0.75, front - 8.7), C.plank, "WoodPlanks")
	part(m, base, "Step", Vector3.new(6, 0.8, 1.4), Vector3.new(0, 0.4, front - 10.1), C.plank, "WoodPlanks")
	for _, x in ipairs({ -14.5, -3.4, 3.4, 14.5 }) do
		part(m, base, "PorchPost", Vector3.new(0.8, 7.6, 0.8), Vector3.new(x, 6, front - 7.4), C.trim, "Wood")
	end
	part(m, base, "PorchRoof", Vector3.new(W - 2, 0.6, 9.4), CFrame.new(0, 10.2, pz - 0.4) * CFrame.Angles(math.rad(-7), 0, 0), { 116, 64, 52 }, "WoodPlanks")
	for _, x in ipairs({ -9, 9 }) do
		for _, y in ipairs({ 3, 4.6 }) do
			part(m, base, "PorchRail", Vector3.new(11, 0.35, 0.35), Vector3.new(x, y, front - 7.4), C.trim, "Wood", { collide = y > 4 })
		end
	end
	part(m, base, "Bench", Vector3.new(5, 0.5, 1.6), Vector3.new(-9, 3.6, front - 2), C.darkWood, "Wood")
	part(m, base, "BenchBack", Vector3.new(5, 2, 0.4), Vector3.new(-9, 4.8, front - 1.2), C.darkWood, "Wood")
	for i, p in ipairs({ { 5.8, 2.2 }, { 8.4, 1.1 }, { -5.8, 1.6 } }) do
		local s = p[2] + 0.4
		bit(m, base, "PorchPumpkin" .. i, Vector3.new(s, s, s), Vector3.new(p[1], 2.2 + s / 2 - 0.1, front - 6), C.pumpkin, "SmoothPlastic", "Ball")
	end
	Kit.lantern(m, base * CFrame.new(-6, 0, front - 12), 6)
	Kit.lantern(m, base * CFrame.new(6, 0, front - 12), 6)
end

-- A grain silo: a ribbed tall cylinder with a dome and a ladder.
local function silo(folder, base, dia, height)
	local m = Kit.model(folder, "Silo")
	Kit.post(m, base, "SiloBody", Vector3.zero, height, dia, { 198, 194, 184 }, "CorrugatedSteel")
	for y = 6, height - 4, 8 do
		Kit.post(m, base, "SiloBand", Vector3.new(0, y, 0), 0.6, dia + 0.4, { 150, 146, 140 }, "Metal", { collide = false })
	end
	part(m, base, "SiloDome", Vector3.new(dia, dia, dia), Vector3.new(0, height, 0), { 214, 210, 200 }, "Metal", { shape = "Ball" })
	local z = -(dia / 2 + 0.4)
	for _, x in ipairs({ -0.8, 0.8 }) do
		bit(m, base, "LadderRail", Vector3.new(0.25, height - 3, 0.25), Vector3.new(x, height / 2 + 0.5, z), C.black, "Metal")
	end
	for y = 2, height - 2, 2 do
		bit(m, base, "LadderRung", Vector3.new(1.6, 0.2, 0.2), Vector3.new(0, y, z), C.black, "Metal")
	end
end

-- A wooden windmill. Its sails (model "Sails", PrimaryPart "Hub") turn on each client.
local function windmill(folder, base)
	local m = Kit.model(folder, "Windmill")
	Kit.post(m, base, "MillBase", Vector3.zero, 8, 18, { 160, 146, 128 }, "Cobblestone")
	Kit.post(m, base, "MillBody", Vector3.new(0, 8, 0), 12, 15, { 172, 128, 84 }, "WoodPlanks")
	Kit.post(m, base, "MillTop", Vector3.new(0, 20, 0), 10, 12, { 186, 140, 92 }, "WoodPlanks")
	Kit.post(m, base, "Gallery", Vector3.new(0, 7.6, 0), 0.6, 22, C.darkWood, "WoodPlanks")
	part(m, base, "MillCap", Vector3.new(13, 13, 13), Vector3.new(0, 30, 0), { 120, 70, 54 }, "WoodPlanks", { shape = "Ball" })
	part(m, base, "MillDoor", Vector3.new(3.4, 6, 0.4), Vector3.new(0, 3, -8.9), C.shadow, "Wood")
	for _, y in ipairs({ 13, 24 }) do
		bit(m, base, "MillWindow", Vector3.new(2, 2.4, 0.3), Vector3.new(0, y, if y < 20 then -7.5 else -6), { 230, 168, 96 }, "Neon")
	end
	bit(m, base, "Axle", Vector3.new(1.4, 1.4, 5), Vector3.new(0, 28, -8.2), C.darkWood, "Wood")
	local sails = Kit.model(m, "Sails")
	local hubCf = base * CFrame.new(0, 28, -10.6)
	local hub = bit(sails, hubCf, "Hub", Vector3.new(2.6, 2.6, 2.6), Vector3.zero, C.darkWood, "Wood", "Ball")
	sails.PrimaryPart = hub
	for k = 0, 3 do
		local arm = hubCf * CFrame.Angles(0, 0, k * math.pi / 2)
		bit(sails, arm, "Spar", Vector3.new(0.7, 18, 0.5), Vector3.new(0, 9.6, 0), C.darkWood, "Wood")
		bit(sails, arm, "SailCloth", Vector3.new(4.2, 13, 0.2), Vector3.new(2.6, 11.5, 0.3), { 236, 224, 200 }, "Fabric")
		bit(sails, arm, "SailEdge", Vector3.new(0.25, 13.4, 0.3), Vector3.new(4.8, 11.5, 0.3), C.darkWood, "Wood")
		for y = 5.5, 17.5, 4 do
			bit(sails, arm, "SailBar", Vector3.new(4.8, 0.25, 0.3), Vector3.new(2.5, y, 0.1), C.darkWood, "Wood")
		end
	end
	Kit.lantern(m, base * CFrame.new(4, 0, -11), 6)
end

function Scenery.build()
	local folder = Instance.new("Folder")
	folder.Name = "Scenery"
	folder.Parent = workspace
	local jobs = {
		{ "lanes and pond", function() Nature.terrain() end },
		{ "barn", function() barn(folder, facing(-125, -205, -125, 0)) end },
		{ "silos", function()
			silo(folder, CFrame.new(-202, 0, -190), 16, 46)
			silo(folder, CFrame.new(-202, 0, -214), 14, 40)
			silo(folder, CFrame.new(-180, 0, -204), 12, 34)
		end },
		{ "farmhouse", function() farmhouse(folder, facing(60, -207, 60, 0)) end },
		{ "windmill", function() windmill(folder, facing(210, -210, 0, 0)) end },
		{ "props", function() Props.build(folder) end },
		{ "nature", function() Nature.build(folder) end },
		{ "animals", function() Pens.build(folder) end },
	}
	for _, job in ipairs(jobs) do
		local ok, err = pcall(job[2])
		if not ok then
			warn("[Scenery] " .. job[1] .. " failed: " .. tostring(err))
		end
	end
	Kit.compact(folder) -- laid out at full size, then pulled in close round the haystack
end

return Scenery

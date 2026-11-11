-- What you see beyond Hayfield Farm's hedge, down the four lanes that run on from the road ends
-- (built once a server by server/Landscape.backdrop, on its flat fields): a red barn with twin
-- silos, a farmhouse with a lit window and a smoking chimney, three wind pumps, a pond with a
-- jetty, post-and-rail fences along the lanes, round bales and clumps of far trees. Sized a little
-- over life so it reads from across the map. Nobody can reach any of it.
local MapKit = require(script.Parent.MapKit)
local WallKit = require(script.Parent.WallKit)

local Vista = {}
local deco = WallKit.deco

local function box(ctx, name, size, x, y, z, colour, material, shadow)
	return deco(ctx, { Name = name, Size = size, CFrame = CFrame.new(MapKit.at(ctx, x, y, z)), Color = colour, Material = material }, shadow)
end

local function drum(ctx, name, height, diameter, x, y, z, colour, material)
	return deco(ctx, { Name = name, Shape = "Cylinder", Size = Vector3.new(height, diameter, diameter), CFrame = CFrame.new(MapKit.at(ctx, x, y, z)) * CFrame.Angles(0, 0, math.rad(90)), Color = colour, Material = material }, true)
end

local function tree(ctx, x, z, h)
	box(ctx, "FarTrunk", Vector3.new(1.6, h, 1.6), x, h / 2, z, { 86, 66, 48 }, "Wood", true)
	local green = WallKit.tone(ctx, { 78, 110, 48 }, 0.15)
	for _, turn in ipairs({ 0, 45 }) do
		deco(ctx, { Name = "FarLeaves", Size = Vector3.new(9, 8, 9), CFrame = CFrame.new(MapKit.at(ctx, x, h + 2, z)) * CFrame.Angles(0, math.rad(turn), 0), Color = green, Material = "LeafyGrass" }, turn == 0)
	end
end

local function pitched(ctx, x, y, z, width, depth, colour) -- a roof: two slabs meeting at a ridge along X
	for _, side in ipairs({ -1, 1 }) do
		deco(ctx, { Name = "FarRoof", Size = Vector3.new(width, 0.5, depth / 2 / math.cos(math.rad(34)) + 0.6), CFrame = CFrame.new(MapKit.at(ctx, x, y + depth / 4 * math.tan(math.rad(34)), z + side * depth / 4)) * CFrame.Angles(math.rad(side * 34), 0, 0), Color = colour, Material = "Metal" }, true)
	end
end

function Vista.build(ctx)
	local r = Random.new(11)
	-- the red barn and twin silos, down the -Z lane
	box(ctx, "FarBarn", Vector3.new(36, 16, 24), 0, 8, -304, { 142, 52, 44 }, "WoodPlanks", true)
	pitched(ctx, 0, 16, -304, 38, 26, { 132, 136, 138 })
	box(ctx, "FarBarnDoor", Vector3.new(10, 11, 0.4), 0, 5.5, -291.8, { 232, 226, 210 }, "WoodPlanks")
	for _, s in ipairs({ { 26, 24, 9 }, { 36, 18, 8 } }) do
		drum(ctx, "FarSilo", s[2], s[3], s[1], s[2] / 2, -306, { 150, 156, 160 }, "Metal")
		deco(ctx, { Name = "FarSiloCap", Shape = "Ball", Size = Vector3.new(s[3], s[3] * 0.6, s[3]), CFrame = CFrame.new(MapKit.at(ctx, s[1], s[2], -306)), Color = { 128, 134, 140 }, Material = "Metal" })
	end
	-- the farmhouse, down the +Z lane
	box(ctx, "FarHouse", Vector3.new(22, 12, 16), 0, 6, 304, { 226, 220, 204 }, "Plaster", true)
	pitched(ctx, 0, 12, 304, 24, 18, { 96, 84, 78 })
	box(ctx, "FarChimney", Vector3.new(2.4, 7, 2.4), 7, 17, 304, { 132, 84, 70 }, "Brick", true)
	box(ctx, "FarDoor", Vector3.new(2.6, 5, 0.3), 0, 2.5, 295.8, { 70, 52, 38 }, "WoodPlanks")
	for _, wx in ipairs({ -6.5, 6.5 }) do
		box(ctx, "FarWindow", Vector3.new(2.6, 3, 0.3), wx, 7, 295.8, { 255, 196, 120 }, "Neon")
	end
	local smoke = Instance.new("ParticleEmitter")
	smoke.Rate, smoke.Lifetime, smoke.Speed, smoke.SpreadAngle = 3, NumberRange.new(5, 8), NumberRange.new(3, 4), Vector2.new(8, 8)
	smoke.Size = NumberSequence.new(1.5, 6)
	smoke.Transparency = NumberSequence.new(0.5, 1)
	smoke.Color, smoke.Drag = ColorSequence.new(Color3.fromRGB(210, 206, 200)), 1
	smoke.EmissionDirection = Enum.NormalId.Top
	smoke.Parent = box(ctx, "FarChimneyTop", Vector3.new(1.6, 0.2, 1.6), 7, 20.7, 304, { 60, 56, 54 }, "Slate")
	tree(ctx, -22, 300, 26)
	-- three wind pumps, down the +X lane
	for _, p in ipairs({ { 300, -18 }, { 306, 6 }, { 296, 26 } }) do
		for _, leg in ipairs({ { -1.6, -1.6 }, { 1.6, -1.6 }, { -1.6, 1.6 }, { 1.6, 1.6 } }) do
			box(ctx, "PumpLeg", Vector3.new(0.4, 18, 0.4), p[1] + leg[1], 9, p[2] + leg[2], { 96, 100, 104 }, "Metal")
		end
		for i = 0, 5 do
			deco(ctx, { Name = "PumpBlade", Size = Vector3.new(0.15, 6.4, 0.7), CFrame = CFrame.new(MapKit.at(ctx, p[1] - 2, 18.5, p[2])) * CFrame.Angles(math.rad(i * 30), 0, 0), Color = { 150, 156, 160 }, Material = "Metal" })
		end
		box(ctx, "PumpVane", Vector3.new(4, 1.6, 0.15), p[1] + 2, 18.5, p[2], { 128, 44, 38 }, "Metal")
	end
	-- the pond's jetty, down the -X lane (server/Landscape fills the water)
	for i = 0, 7 do
		box(ctx, "Jetty", Vector3.new(2.2, 0.3, 5), -262 - i * 2.4, 0.6, 0, WallKit.tone(ctx, { 112, 96, 80 }, 0.1), "WoodPlanks")
	end
	for _, s in ipairs({ -1, 1 }) do -- fences along the lanes, round bales in the fields, far trees
		for i = 0, 9 do
			local d = 192 + i * 8
			for _, side in ipairs({ -8, 8 }) do
				box(ctx, "FarPost", Vector3.new(0.6, 4, 0.6), side, 2, s * d, { 112, 96, 80 }, "Wood")
				box(ctx, "FarPost", Vector3.new(0.6, 4, 0.6), s * d, 2, side, { 112, 96, 80 }, "Wood")
				if i % 2 == 0 and i < 9 then
					box(ctx, "FarRail", Vector3.new(0.25, 0.4, 16), side, 3, s * (d + 8), { 104, 88, 70 }, "Wood")
					box(ctx, "FarRail", Vector3.new(16, 0.4, 0.25), s * (d + 8), 3, side, { 104, 88, 70 }, "Wood")
				end
			end
		end
		for _ = 1, 10 do
			drum(ctx, "FarBale", 5, 5, s * r:NextNumber(40, 170), 2.5, s * r:NextNumber(196, 228), { 214, 180, 90 }, "Grass").CFrame *= CFrame.Angles(math.rad(90), r:NextNumber(0, 3), 0)
		end
		for _ = 1, 9 do -- clumps of trees on the flat fields beside the map
			local cx, cz = s * r:NextNumber(60, 180), -s * r:NextNumber(204, 240)
			for _ = 1, r:NextInteger(2, 4) do
				tree(ctx, cx + r:NextNumber(-10, 10), cz + r:NextNumber(-8, 8), r:NextNumber(14, 22))
				tree(ctx, cz + r:NextNumber(-8, 8), cx + r:NextNumber(-10, 10), r:NextNumber(14, 22))
			end
		end
	end
end

return Vista

-- Map builders: Night Forest and Abandoned Attic (see MapsA for how a builder works).
local MapKit = require(script.Parent.MapKit)

local MapsB = {}

local function ring(ctx, count, radius)
	for i = 1, count do
		local a = i / count * math.pi * 2
		MapKit.spawnAt(ctx, math.cos(a) * radius, math.sin(a) * radius)
	end
end

-- Night Forest: tall trees in fog, fallen logs, mossy rocks, glowing mushrooms and a few lanterns
-- so the paths stay readable in the dark.
function MapsB.forest(ctx)
	local r = ctx.rng
	MapKit.ground(ctx, 130, 130, ctx.def.ground, "Grass")
	for _ = 1, 26 do
		MapKit.tree(ctx, r:NextNumber(-55, 55), r:NextNumber(-55, 55), r:NextNumber(14, 22), { 40, 76, 50 })
	end
	for _ = 1, 9 do -- fallen logs: spots along their tops
		local x, z, turn = r:NextNumber(-48, 48), r:NextNumber(-48, 48), r:NextNumber() * math.pi
		local log = MapKit.part(ctx, { Name = "Log", Shape = "Cylinder", Size = Vector3.new(r:NextNumber(8, 14), 2.2, 2.2), CFrame = CFrame.new(MapKit.at(ctx, x, 1.1, z)) * CFrame.Angles(0, turn, 0), Color = { 92, 66, 44 }, Material = "Wood" })
		for _ = 1, 2 do
			MapKit.spot(ctx, (log.CFrame * CFrame.new(r:NextNumber(-3, 3), 1.1, 0)).Position)
		end
		MapKit.spotsOn(ctx, log, 0, 2)
	end
	for _ = 1, 12 do -- rocks
		local rock = MapKit.part(ctx, { Name = "Rock", Shape = "Ball", Size = Vector3.one * r:NextNumber(2.5, 5), CFrame = CFrame.new(MapKit.at(ctx, r:NextNumber(-50, 50), 0.6, r:NextNumber(-50, 50))), Color = { 96, 104, 100 }, Material = "Slate" })
		MapKit.spotsOn(ctx, rock, 0, 2)
	end
	for _ = 1, 16 do -- glowing mushrooms
		local x, z = r:NextNumber(-50, 50), r:NextNumber(-50, 50)
		MapKit.part(ctx, { Name = "Stalk", Size = Vector3.new(0.3, 0.8, 0.3), CFrame = CFrame.new(MapKit.at(ctx, x, 0.4, z)), Color = { 230, 226, 210 }, Material = "SmoothPlastic", CanCollide = false })
		MapKit.part(ctx, { Name = "Cap", Shape = "Ball", Size = Vector3.new(1.1, 1.1, 1.1), CFrame = CFrame.new(MapKit.at(ctx, x, 0.9, z)), Color = { 120, 200, 255 }, Material = "Neon", CanCollide = false })
	end
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2
		MapKit.part(ctx, { Name = "LanternPost", Size = Vector3.new(0.4, 6, 0.4), CFrame = CFrame.new(MapKit.at(ctx, math.cos(a) * 30, 3, math.sin(a) * 30)), Color = { 60, 50, 40 }, Material = "Wood" })
		MapKit.lamp(ctx, MapKit.at(ctx, math.cos(a) * 30, 6.4, math.sin(a) * 30), { 255, 190, 110 }, 34)
	end
	ring(ctx, 8, 20)
	MapKit.clutter(ctx, ctx.diff.clutter, 52, 52)
	MapKit.moving(ctx, ctx.diff.moving, 40, 40)
end

-- Abandoned Attic: a long, low room under a sloping roof, full of boxes, trunks, an old table,
-- a wardrobe, sheet-covered furniture and dusty lamps, lit by a round window at each end.
function MapsB.attic(ctx)
	local r = ctx.rng
	local L, Wd, H = 72, 32, 16
	local wood, dark = { 132, 98, 66 }, { 96, 70, 48 }
	MapKit.ground(ctx, L + 6, Wd + 6, ctx.def.ground, "WoodPlanks")
	for _, side in ipairs({ -1, 1 }) do -- the sloping roof
		MapKit.wall(ctx, CFrame.new(MapKit.at(ctx, 0, H / 2 + 2, side * Wd / 4)) * CFrame.Angles(side * math.rad(-55), 0, 0), Vector3.new(L, 1, Wd * 0.9), dark, "WoodPlanks")
		MapKit.wall(ctx, CFrame.new(MapKit.at(ctx, 0, 1.5, side * Wd / 2)), Vector3.new(L, 3, 1), wood, "WoodPlanks")
	end
	for _, side in ipairs({ -1, 1 }) do -- end walls with a round window
		MapKit.wall(ctx, CFrame.new(MapKit.at(ctx, side * L / 2, H / 2, 0)), Vector3.new(1, H, Wd), wood, "WoodPlanks")
		local win = MapKit.part(ctx, { Name = "Window", Shape = "Cylinder", Size = Vector3.new(1.2, 6, 6), CFrame = CFrame.new(MapKit.at(ctx, side * (L / 2 - 0.2), 9, 0)), Color = { 255, 236, 190 }, Material = "Neon", CanCollide = false })
		local light = Instance.new("SpotLight")
		light.Face, light.Range, light.Angle, light.Brightness = if side > 0 then Enum.NormalId.Left else Enum.NormalId.Right, 50, 70, 2
		light.Color = Color3.fromRGB(255, 226, 170)
		light.Parent = win
	end
	for _ = 1, 22 do -- boxes, some stacked
		local x, z = r:NextNumber(-L / 2 + 5, L / 2 - 5), r:NextNumber(-Wd / 2 + 4, Wd / 2 - 4)
		local s = r:NextNumber(2, 3.4)
		MapKit.crate(ctx, x, 0, z, s)
		if r:NextNumber() < 0.4 then
			MapKit.crate(ctx, x, s, z, s * 0.8)
		end
	end
	for _ = 1, 5 do -- trunks
		local t = MapKit.part(ctx, { Name = "Trunk", Size = Vector3.new(4.5, 2.6, 2.6), CFrame = CFrame.new(MapKit.at(ctx, r:NextNumber(-30, 30), 1.3, r:NextNumber(-10, 10))) * CFrame.Angles(0, r:NextNumber() * math.pi, 0), Color = { 110, 70, 46 }, Material = "Wood" })
		MapKit.spotsOn(ctx, t, 1, 1)
	end
	-- an old table, a wardrobe and furniture under dust sheets
	local top = MapKit.part(ctx, { Name = "Table", Size = Vector3.new(8, 0.5, 4.5), CFrame = CFrame.new(MapKit.at(ctx, 6, 3, 2)), Color = wood, Material = "Wood" })
	for _, d in ipairs({ { -3.6, -1.9 }, { 3.6, -1.9 }, { -3.6, 1.9 }, { 3.6, 1.9 } }) do
		MapKit.part(ctx, { Name = "Leg", Size = Vector3.new(0.5, 2.8, 0.5), CFrame = CFrame.new(MapKit.at(ctx, 6 + d[1], 1.4, 2 + d[2])), Color = dark, Material = "Wood" })
	end
	MapKit.spotsOn(ctx, top, 3, 2)
	local wardrobe = MapKit.wall(ctx, CFrame.new(MapKit.at(ctx, -26, 4.5, -10)), Vector3.new(6, 9, 3), dark, "Wood")
	MapKit.spotsOn(ctx, wardrobe, 0, 3)
	for _ = 1, 4 do
		local sheet = MapKit.part(ctx, { Name = "DustSheet", Size = Vector3.new(r:NextNumber(4, 6), r:NextNumber(3, 4.5), r:NextNumber(3, 4)), CFrame = CFrame.new(MapKit.at(ctx, r:NextNumber(-28, 28), 2, r:NextNumber(-9, 9))), Color = { 226, 222, 210 }, Material = "Fabric" })
		MapKit.spotsOn(ctx, sheet, 1, 2)
	end
	for i = 0, 2 do
		MapKit.lamp(ctx, MapKit.at(ctx, -24 + i * 24, 11, 0), { 255, 214, 150 }, 26)
	end
	ring(ctx, 8, 8)
	MapKit.clutter(ctx, ctx.diff.clutter, L / 2 - 4, Wd / 2 - 4)
	MapKit.moving(ctx, ctx.diff.moving, L / 2 - 8, Wd / 2 - 6)
end

return MapsB

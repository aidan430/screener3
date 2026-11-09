-- Map builders: Night Forest (a thicket maze) and Abandoned Attic (a maze of stacked boxes under
-- the roof). See MapsA for how a builder works.
local MapKit = require(script.Parent.MapKit)
local MazeKit = require(script.Parent.MazeKit)
local MapsA = require(script.Parent.MapsA)

local MapsB = {}

-- Night Forest: paths through dark thickets in the fog; trees, logs, rocks and glowing mushrooms
-- in the corridors, and lanterns in the clearings so you can find your way.
function MapsB.forest(ctx)
	local r = ctx.rng
	MapKit.ground(ctx, 130, 130, ctx.def.ground, "Grass")
	MapKit.edges(ctx, 63, 63, ctx.def.ground)
	local maze = MazeKit.build(ctx, { cols = 8, rows = 8, size = 15, height = 10, style = "thicket", loops = 0.18, rooms = 3 })
	for _, room in ipairs(maze.rooms) do
		MapKit.tree(ctx, room.x, room.z, r:NextNumber(16, 22), { 40, 76, 50 })
		MapKit.part(ctx, { Name = "LanternPost", Size = Vector3.new(0.4, 6, 0.4), CFrame = CFrame.new(MapKit.at(ctx, room.x + 6, 3, room.z + 6)), Color = { 60, 50, 40 }, Material = "Wood" })
		MapKit.lamp(ctx, MapKit.at(ctx, room.x + 6, 6.4, room.z + 6), { 255, 190, 110 }, 34)
		local log = MapKit.part(ctx, { Name = "Log", Shape = "Cylinder", Size = Vector3.new(10, 2.2, 2.2), CFrame = CFrame.new(MapKit.at(ctx, room.x - 5, 1.1, room.z - 4)) * CFrame.Angles(0, r:NextNumber() * math.pi, 0), Color = { 92, 66, 44 }, Material = "Wood" })
		MapKit.spot(ctx, (log.CFrame * CFrame.new(r:NextNumber(-3, 3), 1.1, 0)).Position)
		MapKit.spotsOn(ctx, log, 0, 2)
	end
	for _ = 1, 8 do
		local x, z = MapsA.inCell(ctx, maze, 2.5)
		MapKit.tree(ctx, x, z, r:NextNumber(14, 20), { 40, 76, 50 })
	end
	for _ = 1, 10 do
		local x, z = MapsA.inCell(ctx, maze, 2.5)
		local rock = MapKit.part(ctx, { Name = "Rock", Shape = "Ball", Size = Vector3.one * r:NextNumber(2.5, 4), CFrame = CFrame.new(MapKit.at(ctx, x, 0.6, z)), Color = { 96, 104, 100 }, Material = "Slate" })
		MapKit.spotsOn(ctx, rock, 0, 2)
	end
	for _ = 1, 18 do -- glowing mushrooms light the way
		local x, z = MapsA.inCell(ctx, maze, 1.5)
		MapKit.part(ctx, { Name = "Stalk", Size = Vector3.new(0.3, 0.8, 0.3), CFrame = CFrame.new(MapKit.at(ctx, x, 0.4, z)), Color = { 230, 226, 210 }, Material = "SmoothPlastic", CanCollide = false })
		MapKit.part(ctx, { Name = "Cap", Shape = "Ball", Size = Vector3.new(1.1, 1.1, 1.1), CFrame = CFrame.new(MapKit.at(ctx, x, 0.9, z)), Color = { 120, 200, 255 }, Material = "Neon", CanCollide = false })
	end
	maze.spawns(8)
	MapKit.clutter(ctx, ctx.diff.clutter, 58, 58)
	MapKit.moving(ctx, ctx.diff.moving, 45, 45)
end

-- Abandoned Attic: a long room under a sloping roof, its floor a maze of stacked boxes; trunks,
-- an old table, a wardrobe and furniture under dust sheets in the corners and the clearing, lit
-- by a round window at each end and dusty lamps.
function MapsB.attic(ctx)
	local r = ctx.rng
	local L, Wd, H = 80, 48, 20
	local wood, dark = { 132, 98, 66 }, { 96, 70, 48 }
	MapKit.ground(ctx, L + 6, Wd + 6, ctx.def.ground, "WoodPlanks")
	-- the roof: two slopes, low (3 studs) at the side walls, up to a flat ridge at about 19.6
	local slope, tilt = 20, math.rad(55)
	for _, side in ipairs({ -1, 1 }) do
		local run, rise = slope / 2 * math.cos(tilt), slope / 2 * math.sin(tilt)
		MapKit.wall(ctx, CFrame.new(MapKit.at(ctx, 0, 3 + rise, side * (Wd / 2 - run))) * CFrame.Angles(side * tilt, 0, 0), Vector3.new(L, 1, slope), dark, "WoodPlanks")
		MapKit.wall(ctx, CFrame.new(MapKit.at(ctx, 0, 1.5, side * Wd / 2)), Vector3.new(L, 3, 1), wood, "WoodPlanks")
	end
	MapKit.wall(ctx, CFrame.new(MapKit.at(ctx, 0, 3 + slope * math.sin(tilt) + 0.2, 0)), Vector3.new(L, 1, Wd - 4 * slope / 2 * math.cos(tilt) + 2), dark, "WoodPlanks")
	for _, side in ipairs({ -1, 1 }) do -- end walls with a round window
		MapKit.wall(ctx, CFrame.new(MapKit.at(ctx, side * L / 2, H / 2, 0)), Vector3.new(1, H, Wd), wood, "WoodPlanks")
		local win = MapKit.part(ctx, { Name = "Window", Shape = "Cylinder", Size = Vector3.new(1.2, 6, 6), CFrame = CFrame.new(MapKit.at(ctx, side * (L / 2 - 0.2), 12, 0)), Color = { 255, 236, 190 }, Material = "Neon", CanCollide = false })
		local light = Instance.new("SpotLight")
		light.Face, light.Range, light.Angle, light.Brightness = if side > 0 then Enum.NormalId.Left else Enum.NormalId.Right, 60, 70, 2
		light.Color = Color3.fromRGB(255, 226, 170)
		light.Parent = win
	end
	local maze = MazeKit.build(ctx, { cols = 8, rows = 3, size = 9.5, height = 6, style = "crates", loops = 0.22, rooms = 1 })
	for _, room in ipairs(maze.rooms) do -- the old table in the clearing
		local top = MapKit.part(ctx, { Name = "Table", Size = Vector3.new(7, 0.5, 4), CFrame = CFrame.new(MapKit.at(ctx, room.x, 3, room.z)), Color = wood, Material = "Wood" })
		for _, d in ipairs({ { -3.1, -1.6 }, { 3.1, -1.6 }, { -3.1, 1.6 }, { 3.1, 1.6 } }) do
			MapKit.part(ctx, { Name = "Leg", Size = Vector3.new(0.5, 2.8, 0.5), CFrame = CFrame.new(MapKit.at(ctx, room.x + d[1], 1.4, room.z + d[2])), Color = dark, Material = "Wood" })
		end
		MapKit.spotsOn(ctx, top, 3, 2)
	end
	for _ = 1, 4 do
		local x, z = MapsA.inCell(ctx, maze, 2)
		local t = MapKit.part(ctx, { Name = "Trunk", Size = Vector3.new(3.4, 2.4, 2.2), CFrame = CFrame.new(MapKit.at(ctx, x, 1.2, z)) * CFrame.Angles(0, r:NextNumber() * math.pi, 0), Color = { 110, 70, 46 }, Material = "Wood" })
		MapKit.spotsOn(ctx, t, 1, 1)
	end
	for _ = 1, 3 do
		local x, z = MapsA.inCell(ctx, maze, 2)
		local sheet = MapKit.part(ctx, { Name = "DustSheet", Size = Vector3.new(r:NextNumber(3, 4), r:NextNumber(3, 4), r:NextNumber(3, 3.6)), CFrame = CFrame.new(MapKit.at(ctx, x, 1.8, z)), Color = { 226, 222, 210 }, Material = "Fabric" })
		MapKit.spotsOn(ctx, sheet, 1, 2)
	end
	for i = 0, 3 do
		MapKit.lamp(ctx, MapKit.at(ctx, -30 + i * 20, 15, 0), { 255, 214, 150 }, 30)
	end
	maze.spawns(8)
	MapKit.clutter(ctx, ctx.diff.clutter, L / 2 - 4, Wd / 2 - 8)
	MapKit.moving(ctx, ctx.diff.moving, L / 2 - 8, Wd / 2 - 10)
end

return MapsB

-- Map builders: Classic Haystack Field (a hedge maze), Barn Interior (a maze of stall walls) and
-- Farm at Sunset (a maze of stacked hay bales). shared/Maps holds their names, light and colours.
-- Each builds round ctx.centre with MapKit and MazeKit: the maze records its own hiding spots
-- (dead ends, wall feet); props go inside cells and clearings and add theirs. Then the round's
-- loose straw (ctx.diff.clutter) and, on Hard, tumbling hay (ctx.diff.moving).
local MapKit = require(script.Parent.MapKit)
local MazeKit = require(script.Parent.MazeKit)

local MapsA = {}

-- A random spot inside a maze cell, clear of its walls.
local function inCell(ctx, maze, margin)
	local cell = maze.randomCell()
	local room = maze.size / 2 - 1 - (margin or 1.5)
	return cell.x + ctx.rng:NextNumber(-room, room), cell.z + ctx.rng:NextNumber(-room, room)
end
MapsA.inCell = inCell

local function finish(ctx, half)
	MapKit.clutter(ctx, ctx.diff.clutter, half, half)
	MapKit.moving(ctx, ctx.diff.moving, half * 0.8, half * 0.8)
end

-- Classic Haystack Field: a hedge maze over the field, haystacks in its clearings, bales and
-- hay carts tucked into the corridors.
function MapsA.field(ctx)
	local r = ctx.rng
	MapKit.ground(ctx, 140, 140, ctx.def.ground, "Grass")
	MapKit.edges(ctx, 68, 68, ctx.def.ground)
	local maze = MazeKit.build(ctx, { cols = 8, rows = 8, size = 16, height = 10, style = "hedge", loops = 0.15, rooms = 3 })
	for _, room in ipairs(maze.rooms) do
		MapKit.haystack(ctx, room.x + r:NextNumber(-3, 3), room.z + r:NextNumber(-3, 3), r:NextNumber(5, 6.5), r:NextNumber(9, 12))
	end
	for _ = 1, 14 do
		local x, z = inCell(ctx, maze, 2.5)
		MapKit.bale(ctx, x, 0, z, r:NextNumber() * math.pi)
	end
	for _ = 1, 6 do
		local x, z = inCell(ctx, maze, 3)
		MapKit.crate(ctx, x, 0, z, 2.5)
	end
	maze.spawns(8)
	finish(ctx, 62)
end

-- Barn Interior: a red barn whose floor is a maze of wooden stall walls under the hay loft;
-- stairs up the west wall to the loft, crates and bales in the stalls, warm lamps above.
function MapsA.barn(ctx)
	local r = ctx.rng
	local W, D, H = 76, 52, 24
	local wood, dark = { 150, 96, 60 }, { 110, 70, 44 }
	MapKit.ground(ctx, W + 10, D + 10, ctx.def.ground, "WoodPlanks")
	for _, w in ipairs({ { 0, -D / 2, W, 1 }, { 0, D / 2, W, 1 }, { -W / 2, 0, 1, D }, { W / 2, 0, 1, D } }) do
		MapKit.wall(ctx, CFrame.new(MapKit.at(ctx, w[1], H / 2, w[2])), Vector3.new(w[3], H, w[4]), { 168, 70, 56 }, "WoodPlanks")
	end
	MapKit.wall(ctx, CFrame.new(MapKit.at(ctx, 0, H + 0.5, 0)), Vector3.new(W, 1, D), dark, "WoodPlanks")
	local loftZ = -D / 2 + 7
	MapKit.wall(ctx, CFrame.new(MapKit.at(ctx, 0, 10, loftZ)), Vector3.new(W - 2, 1, 14), wood, "WoodPlanks")
	for i = 0, 11 do -- stairs up the west wall, outside the maze
		MapKit.wall(ctx, CFrame.new(MapKit.at(ctx, -W / 2 + 3.5, 0.4 + i * 0.8, loftZ + 7 + 19 - i * 1.6)), Vector3.new(5, 0.8, 1.7), wood, "WoodPlanks")
	end
	for _ = 1, 8 do
		MapKit.bale(ctx, r:NextNumber(-W / 2 + 10, W / 2 - 6), 10.5, loftZ + r:NextNumber(-4, 4), r:NextNumber() * 3, true)
	end
	for i = 0, 4 do
		MapKit.spot(ctx, MapKit.at(ctx, -W / 2 + 12 + i * 12, 10.5, loftZ + 6), true)
	end
	local maze = MazeKit.build(ctx, { cols = 6, rows = 4, size = 11, height = 8, style = "planks", loops = 0.2, rooms = 1, ox = 3.5, oz = 0 })
	for _ = 1, 10 do
		local x, z = inCell(ctx, maze, 1.5)
		MapKit.crate(ctx, x, 0, z, r:NextNumber(1.8, 2.6))
	end
	for _ = 1, 6 do
		local x, z = inCell(ctx, maze, 2.5)
		MapKit.bale(ctx, x, 0, z, r:NextNumber() * 3)
	end
	for i = 0, 3 do
		MapKit.lamp(ctx, MapKit.at(ctx, -W / 2 + 12 + i * 17, H - 3, 6), { 255, 196, 120 }, 30)
	end
	maze.spawns(8)
	finish(ctx, 32)
end

-- Farm at Sunset: a maze of hay-bale walls four high across the farm, with the farmhouse, the
-- tractor and a little crop patch with its scarecrow in the clearings.
function MapsA.sunset(ctx)
	local r = ctx.rng
	MapKit.ground(ctx, 140, 140, ctx.def.ground, "Grass")
	MapKit.edges(ctx, 68, 68, ctx.def.ground)
	local maze = MazeKit.build(ctx, { cols = 8, rows = 8, size = 16, height = 10, style = "bales", loops = 0.15, rooms = 3 })
	for i, room in ipairs(maze.rooms) do
		if i == 1 then -- the farmhouse
			local house = MapKit.wall(ctx, CFrame.new(MapKit.at(ctx, room.x, 7, room.z)), Vector3.new(16, 14, 12), { 236, 226, 200 }, "WoodPlanks")
			MapKit.part(ctx, { Name = "Roof", Size = Vector3.new(18, 2, 14), CFrame = CFrame.new(house.Position + Vector3.new(0, 8, 0)), Color = { 150, 60, 50 }, Material = "Slate" })
			MapKit.spotsOn(ctx, house, 0, 4)
		elseif i == 2 then -- the tractor
			local body = MapKit.wall(ctx, CFrame.new(MapKit.at(ctx, room.x, 2.5, room.z)), Vector3.new(8, 3, 4.5), { 196, 52, 40 }, "SmoothPlastic")
			MapKit.part(ctx, { Name = "Cab", Size = Vector3.new(3.5, 3.5, 4), CFrame = body.CFrame * CFrame.new(-2, 3, 0), Color = { 196, 52, 40 }, Material = "SmoothPlastic" })
			for _, w in ipairs({ { -3, 2.2 }, { 3, 1.4 } }) do
				for _, side in ipairs({ -1, 1 }) do
					MapKit.part(ctx, { Name = "Wheel", Shape = "Cylinder", Size = Vector3.new(1, w[2] * 2, w[2] * 2), CFrame = CFrame.new(MapKit.at(ctx, room.x + w[1], w[2], room.z + side * 2.8)) * CFrame.Angles(0, math.pi / 2, 0), Color = { 40, 40, 44 }, Material = "Fabric" })
				end
			end
			MapKit.spotsOn(ctx, body, 1, 4)
		else -- crops and the scarecrow
			for row = 0, 4 do
				local x = room.x - 10 + row * 5
				MapKit.part(ctx, { Name = "Crops", Size = Vector3.new(2, 1.2, 22), CFrame = CFrame.new(MapKit.at(ctx, x, 0.6, room.z)), Color = { 90, 140, 60 }, Material = "Grass" })
				MapKit.spot(ctx, MapKit.at(ctx, x + 2.5, 0, room.z + r:NextNumber(-9, 9)))
			end
			MapKit.part(ctx, { Name = "Pole", Size = Vector3.new(0.5, 9, 0.5), CFrame = CFrame.new(MapKit.at(ctx, room.x + 1, 4.5, room.z)), Color = { 120, 84, 50 }, Material = "Wood" })
			MapKit.part(ctx, { Name = "Scarecrow", Shape = "Ball", Size = Vector3.one * 2.4, CFrame = CFrame.new(MapKit.at(ctx, room.x + 1, 9.5, room.z)), Color = { 214, 186, 140 }, Material = "Fabric" })
		end
	end
	for _ = 1, 10 do
		local x, z = inCell(ctx, maze, 2.5)
		MapKit.bale(ctx, x, 0, z, r:NextNumber() * 3)
	end
	maze.spawns(8)
	finish(ctx, 62)
end

return MapsA

-- Map builders from the owner's Gemini map sheets: Pumpkin Patch, Harvest Corn Maze, Sunflower
-- Labyrinth, Apple Orchard and Windmill Hill. Each is a maze (server/MazeKit; the new wall styles
-- are in server/MazeWalls) with its landmarks in the clearings and its props in the corridors
-- (server/FarmProps). Chests go on perches in the dead ends and the Golden Chest in a clearing
-- (server/ChestSpawner), as on every map. shared/Maps holds their names, light and colours.
local MapKit = require(script.Parent.MapKit)
local MazeKit = require(script.Parent.MazeKit)
local FarmProps = require(script.Parent.FarmProps)
local inCell = require(script.Parent.MapsA).inCell

local MapsC = {}

local function base(ctx, style, rooms)
	MapKit.ground(ctx, 140, 140, ctx.def.ground, "Grass")
	MapKit.edges(ctx, 68, 68, ctx.def.ground)
	return MazeKit.build(ctx, { cols = 8, rows = 8, size = 16, height = 10, style = style, loops = 0.15, rooms = rooms or 3 })
end

local function finish(ctx, maze)
	maze.spawns(10)
	MapKit.clutter(ctx, ctx.diff.clutter, 62, 62)
	MapKit.moving(ctx, ctx.diff.moving, 50, 50)
end

-- Pumpkin Patch: walls of twisting vines, pumpkin patches in the clearings with a scarecrow and a
-- cart of pumpkins, pumpkins tucked along the corridors.
function MapsC.pumpkin(ctx)
	local maze = base(ctx, "vines")
	for i, room in ipairs(maze.rooms) do
		FarmProps.patch(ctx, room.x, room.z, 7, 6)
		if i == 1 then
			FarmProps.cart(ctx, room.x + 4, room.z - 4, "pumpkins")
		else
			FarmProps.scarecrow(ctx, room.x - 3, room.z + 3, if i == 2 then { 120, 80, 50 } else { 70, 120, 60 })
		end
	end
	for _ = 1, 16 do
		local x, z = inCell(ctx, maze, 2)
		FarmProps.pumpkin(ctx, x, z)
	end
	finish(ctx, maze)
end

-- Harvest Corn Maze: walls of tall golden corn, a red silo in the biggest clearing, hay wagons,
-- scarecrows and crows on posts.
function MapsC.corn(ctx)
	local maze = base(ctx, "corn")
	for i, room in ipairs(maze.rooms) do
		if i == 1 then
			FarmProps.silo(ctx, room.x, room.z, 22)
		elseif i == 2 then
			FarmProps.cart(ctx, room.x, room.z, "hay")
			FarmProps.scarecrow(ctx, room.x + 6, room.z + 5, { 60, 120, 140 })
		else
			FarmProps.scarecrow(ctx, room.x, room.z, { 170, 60, 70 })
			FarmProps.crowPost(ctx, room.x + 5, room.z - 5)
		end
	end
	for _ = 1, 8 do
		local x, z = inCell(ctx, maze, 2.5)
		MapKit.bale(ctx, x, 0, z, ctx.rng:NextNumber() * 3)
	end
	for _ = 1, 4 do
		local x, z = inCell(ctx, maze, 3)
		FarmProps.crowPost(ctx, x, z)
	end
	finish(ctx, maze)
end

-- Sunflower Labyrinth: walls of giant sunflowers, a wooden lookout tower you can climb in the
-- middle clearing, picnic blankets in the others.
function MapsC.sunflower(ctx)
	local maze = base(ctx, "sunflowers")
	local cloths = { { 220, 70, 80 }, { 90, 130, 220 }, { 230, 120, 170 } }
	for i, room in ipairs(maze.rooms) do
		if i == 1 then
			FarmProps.tower(ctx, room.x, room.z, 9)
		else
			FarmProps.picnic(ctx, room.x + 2, room.z, cloths[i])
			FarmProps.scarecrow(ctx, room.x - 5, room.z + 4)
		end
	end
	for _ = 1, 6 do
		local x, z = inCell(ctx, maze, 3)
		FarmProps.picnic(ctx, x, z, cloths[ctx.rng:NextInteger(1, 3)])
	end
	for _ = 1, 6 do
		local x, z = inCell(ctx, maze, 2.5)
		MapKit.bale(ctx, x, 0, z, ctx.rng:NextNumber() * 3)
	end
	finish(ctx, maze)
end

-- Apple Orchard: a clipped hedge maze inside a ring of apple trees, the cider press in a
-- clearing, apple crates and ladders along the corridors.
function MapsC.orchard(ctx)
	local maze = base(ctx, "hedge")
	for i = 0, 15 do -- the ring of apple trees, outside the maze
		for _, side in ipairs({ -1, 1 }) do
			local t = -60 + i * 8
			FarmProps.appleTree(ctx, t, side * 66)
			FarmProps.appleTree(ctx, side * 66, t)
		end
	end
	for i, room in ipairs(maze.rooms) do
		if i == 1 then
			FarmProps.ciderPress(ctx, room.x, room.z)
		else
			FarmProps.cart(ctx, room.x, room.z, "apples")
		end
	end
	for _ = 1, 10 do
		local x, z = inCell(ctx, maze, 3)
		FarmProps.appleCrates(ctx, x, z)
	end
	for _ = 1, 6 do -- ladders leaning on the hedges (for looks: the hedges stay too tall to see over)
		local cell = maze.randomCell()
		FarmProps.ladder(ctx, CFrame.new(MapKit.at(ctx, cell.x + 6.4, 0, cell.z)) * CFrame.Angles(0, math.pi / 2, math.rad(-12)), 9)
	end
	finish(ctx, maze)
end

-- Windmill Hill: a maze of dry-stone walls and hedges on dusty ground, the windmill turning in the
-- middle clearing, flour sacks everywhere.
function MapsC.windmill(ctx)
	local maze = base(ctx, "stonehedge")
	MapKit.part(ctx, { Name = "Dust", Size = Vector3.new(130, 0.2, 130), CFrame = CFrame.new(MapKit.at(ctx, 0, 0.05, 0)), Color = { 196, 160, 110 }, Material = "Sand", CanCollide = false })
	for i, room in ipairs(maze.rooms) do
		if i == 1 then
			FarmProps.windmill(ctx, room.x, room.z)
		else
			for _ = 1, 4 do
				FarmProps.flourSack(ctx, room.x + ctx.rng:NextNumber(-6, 6), room.z + ctx.rng:NextNumber(-6, 6))
			end
			FarmProps.scarecrow(ctx, room.x, room.z, { 140, 90, 50 })
		end
	end
	for _ = 1, 14 do
		local x, z = inCell(ctx, maze, 2)
		FarmProps.flourSack(ctx, x, z)
	end
	finish(ctx, maze)
end

return MapsC

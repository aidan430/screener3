-- Hayfield Farm: one big map (about 360 studs across, several times the others). Four farm quarters,
-- each its own maze with gates out to the roads: the Corn Maze (the silo), the Pumpkin Patch (the
-- lookout tower), the Orchard (the barn and its loft) and Windmill Hill (the windmill). Two roads
-- cross in the middle, where the Hay Tower stands; another runs all round the edge, past the water
-- tower, and that's where everyone starts. Chests are hard to get (server/Landmarks): up the silo
-- ladder, in the barn loft, on the lookout and the windmill balcony, on the water tower, deep in
-- the mazes; the Golden Chest is on top of the Hay Tower. shared/Maps sets its light and round time.
local MapKit = require(script.Parent.MapKit)
local MazeKit = require(script.Parent.MazeKit)
local FarmProps = require(script.Parent.FarmProps)
local Landmarks = require(script.Parent.Landmarks)
local inCell = require(script.Parent.MapsA).inCell

local MapsBig = {}
local Q, HALF, RING = 82, 185, 168 -- a quarter's centre, the edge, the ring road

local function road(ctx, x, z, sx, sz)
	MapKit.part(ctx, { Name = "Road", Size = Vector3.new(sx, 0.2, sz), CFrame = CFrame.new(MapKit.at(ctx, x, 0.05, z)), Color = { 176, 146, 100 }, Material = "Ground" })
end

local function scatter(ctx, maze, n, margin, fn)
	for _ = 1, n do
		local x, z = inCell(ctx, maze, margin)
		fn(x, z)
	end
end

local QUARTERS = {
	{ style = "corn", x = -Q, z = -Q, landmark = "silo", props = function(ctx, maze, room)
		FarmProps.cart(ctx, room.x, room.z, "hay")
		FarmProps.scarecrow(ctx, room.x + 6, room.z + 5, { 60, 120, 140 })
		scatter(ctx, maze, 6, 3, function(x, z) FarmProps.crowPost(ctx, x, z) end)
		scatter(ctx, maze, 8, 2.5, function(x, z) MapKit.bale(ctx, x, 0, z, ctx.rng:NextNumber() * 3) end)
	end },
	{ style = "vines", x = Q, z = -Q, landmark = "lookout", props = function(ctx, maze, room)
		FarmProps.patch(ctx, room.x, room.z, 9, 7)
		FarmProps.cart(ctx, room.x + 6, room.z - 6, "pumpkins")
		scatter(ctx, maze, 18, 2, function(x, z) FarmProps.pumpkin(ctx, x, z) end)
	end },
	{ style = "hedge", x = -Q, z = Q, landmark = "barnLoft", props = function(ctx, maze, room)
		FarmProps.ciderPress(ctx, room.x, room.z)
		scatter(ctx, maze, 10, 3, function(x, z) FarmProps.appleCrates(ctx, x, z) end)
	end },
	{ style = "stonehedge", x = Q, z = Q, landmark = "windmill", props = function(ctx, maze, room)
		for _ = 1, 5 do
			FarmProps.flourSack(ctx, room.x + ctx.rng:NextNumber(-7, 7), room.z + ctx.rng:NextNumber(-7, 7))
		end
		scatter(ctx, maze, 14, 2, function(x, z) FarmProps.flourSack(ctx, x, z) end)
	end },
}

function MapsBig.bigfarm(ctx)
	MapKit.ground(ctx, HALF * 2 + 20, HALF * 2 + 20, ctx.def.ground, "Grass")
	MapKit.edges(ctx, HALF, HALF, ctx.def.ground)
	road(ctx, 0, 0, 20, HALF * 2 - 4) -- the two roads through the middle
	road(ctx, 0, 0, HALF * 2 - 4, 20)
	for _, s in ipairs({ -1, 1 }) do -- the ring road
		road(ctx, 0, s * RING, HALF * 2 - 4, 24)
		road(ctx, s * RING, 0, 24, HALF * 2 - 4)
	end
	ctx.landmarks = {}
	local all = { cells = {}, deadEnds = {}, rooms = {}, height = 10, size = 16 }
	for _, q in ipairs(QUARTERS) do
		local maze = MazeKit.build(ctx, { cols = 9, rows = 9, size = 16, height = 10, style = q.style, loops = 0.12, rooms = 2, ox = q.x, oz = q.z, doors = 2 })
		local rooms = maze.rooms
		table.insert(ctx.landmarks, Landmarks[q.landmark](ctx, rooms[1].x, rooms[1].z))
		q.props(ctx, maze, rooms[2] or rooms[1])
		for _, key in ipairs({ "cells", "deadEnds" }) do
			table.move(maze[key], 1, #maze[key], #all[key] + 1, all[key])
		end
		table.insert(all.rooms, rooms[2] or rooms[1]) -- (the landmark's clearing is taken)
	end
	table.insert(ctx.landmarks, Landmarks.waterTower(ctx, -RING, RING))
	ctx.goldenSpot = Landmarks.hayTower(ctx, 0, 0)
	for i = 0, 15 do -- apple trees and pines along the ring road's outer side
		local t = -150 + i * 20
		for _, s in ipairs({ -1, 1 }) do
			MapKit.tree(ctx, t, s * (HALF - 6), 12, { 70, 140, 60 })
			MapKit.tree(ctx, s * (HALF - 6), t, 12, { 70, 140, 60 })
		end
	end
	function all.randomCell()
		return all.cells[ctx.rng:NextInteger(1, #all.cells)]
	end
	ctx.maze = all -- one maze of the four quarters, for chests, power-ups and hints
	for i = 0, 9 do -- everyone starts round the ring road, facing in
		local a = i / 10 * math.pi * 2 + 0.3
		local d = RING / math.max(math.abs(math.cos(a)), math.abs(math.sin(a)))
		local x, z = math.cos(a) * d, math.sin(a) * d
		table.insert(ctx.spawns, CFrame.lookAt(MapKit.at(ctx, x, 3, z), MapKit.at(ctx, 0, 3, 0)))
	end
	MapKit.clutter(ctx, ctx.diff.clutter * 3, HALF - 10, HALF - 10)
	MapKit.moving(ctx, ctx.diff.moving * 3, 150, 150)
end

return MapsBig

-- More maps from the owner's Gemini sheets: Frozen Farm, Rainy Greenhouse, Duck Pond Marsh, Hay
-- Market and County Fair. Mazes (server/MazeKit; walls from server/MazeWalls) with landmarks in the
-- clearings (server/FarmProps2) and chests on perches like every map. shared/Maps has their light.
local MapKit = require(script.Parent.MapKit)
local MazeKit = require(script.Parent.MazeKit)
local FarmProps = require(script.Parent.FarmProps)
local P2 = require(script.Parent.FarmProps2)
local inCell = require(script.Parent.MapsA).inCell

local MapsD = {}

local function base(ctx, style, material)
	MapKit.ground(ctx, 140, 140, ctx.def.ground, material or "Grass")
	MapKit.edges(ctx, 68, 68, ctx.def.ground)
	return MazeKit.build(ctx, { cols = 8, rows = 8, size = 16, height = 10, style = style, loops = 0.15, rooms = 3 })
end

local function finish(ctx, maze)
	maze.spawns(10)
	MapKit.clutter(ctx, ctx.diff.clutter, 62, 62)
	MapKit.moving(ctx, ctx.diff.moving, 50, 50)
end

local function scatter(ctx, maze, n, margin, fn)
	for _ = 1, n do
		local x, z = inCell(ctx, maze, margin)
		fn(x, z)
	end
end

-- Frozen Farm: snow-capped hay-bale walls, a snowy barn, a frozen pond with a sled, a water tower,
-- snowmen in the corridors and snowy pines all round outside.
function MapsD.frozen(ctx)
	local maze = base(ctx, "snowbales", "Snow")
	for i = 0, 11 do
		local t = -55 + i * 10
		for _, side in ipairs({ -1, 1 }) do
			P2.pine(ctx, t, side * 74, true)
			P2.pine(ctx, side * 74, t, true)
		end
	end
	for i, room in ipairs(maze.rooms) do
		if i == 1 then
			P2.barn(ctx, room.x, room.z, true)
		elseif i == 2 then
			P2.pond(ctx, room.x, room.z, 7, true)
			P2.sled(ctx, room.x + 8, room.z - 6)
		else
			P2.waterTower(ctx, room.x, room.z, true)
		end
	end
	scatter(ctx, maze, 6, 3, function(x, z)
		P2.snowman(ctx, x, z)
	end)
	scatter(ctx, maze, 6, 2.5, function(x, z)
		MapKit.bale(ctx, x, 0, z, ctx.rng:NextNumber() * 3)
	end)
	finish(ctx, maze)
end

-- Rainy Greenhouse: frosted glass walls over potting shelves, the great glass dome in a clearing,
-- lily ponds, benches of pots, watering cans and puddles.
function MapsD.greenhouse(ctx)
	local maze = base(ctx, "glass", "Concrete")
	for i, room in ipairs(maze.rooms) do
		if i == 1 then
			P2.dome(ctx, room.x, room.z)
		else
			P2.pond(ctx, room.x, room.z, 6, false)
		end
	end
	scatter(ctx, maze, 8, 3, function(x, z)
		P2.bench(ctx, x, z)
	end)
	scatter(ctx, maze, 8, 2, function(x, z)
		P2.wateringCan(ctx, x, z)
	end)
	scatter(ctx, maze, 14, 1, function(x, z)
		P2.puddle(ctx, x, z)
	end)
	finish(ctx, maze)
end

-- Duck Pond Marsh: walls of tall reeds round a boardwalk floor, ponds with lily pads and ducks in
-- the clearings, and the boathouse.
function MapsD.marsh(ctx)
	local maze = base(ctx, "reeds", "WoodPlanks")
	for i, room in ipairs(maze.rooms) do
		if i == 1 then
			P2.boathouse(ctx, room.x, room.z)
		else
			P2.pond(ctx, room.x, room.z, 8, false)
			for _ = 1, 3 do
				P2.duck(ctx, room.x + ctx.rng:NextNumber(-5, 5), room.z + ctx.rng:NextNumber(-5, 5))
			end
		end
	end
	scatter(ctx, maze, 8, 2, function(x, z)
		P2.pond(ctx, x, z, 2.2, false)
	end)
	scatter(ctx, maze, 5, 3, function(x, z)
		FarmProps.crowPost(ctx, x, z)
	end)
	finish(ctx, maze)
end

-- Hay Market: lanes between the backs of market stalls under striped awnings, a well in the main
-- clearing, carts of vegetables, bunting strung over the lanes.
function MapsD.market(ctx)
	local maze = base(ctx, "stalls", "Sand")
	for i, room in ipairs(maze.rooms) do
		if i == 1 then
			P2.well(ctx, room.x, room.z)
		else
			FarmProps.cart(ctx, room.x, room.z, if i == 2 then "pumpkins" else "apples")
		end
	end
	for _ = 1, 10 do -- bunting across the lanes, above the stall tops
		local cell = maze.randomCell()
		P2.bunting(ctx, cell.x - 8, cell.z + ctx.rng:NextNumber(-4, 4), cell.x + 8, cell.z + ctx.rng:NextNumber(-4, 4), 11)
	end
	scatter(ctx, maze, 8, 3, function(x, z)
		FarmProps.appleCrates(ctx, x, z)
	end)
	finish(ctx, maze)
end

-- County Fair: lanes between candy-striped tents and booths, the Ferris wheel and the carousel
-- turning in the clearings, balloon sellers and prize booths along the way.
function MapsD.fair(ctx)
	local maze = base(ctx, "tents", "Sand")
	for i, room in ipairs(maze.rooms) do
		if i == 1 then
			P2.ferrisWheel(ctx, room.x, room.z)
		elseif i == 2 then
			P2.carousel(ctx, room.x, room.z)
		else
			P2.balloons(ctx, room.x - 4, room.z)
			P2.prizeBooth(ctx, room.x + 4, room.z)
		end
	end
	scatter(ctx, maze, 6, 3, function(x, z)
		P2.balloons(ctx, x, z)
	end)
	scatter(ctx, maze, 4, 4, function(x, z)
		P2.prizeBooth(ctx, x, z)
	end)
	finish(ctx, maze)
end

return MapsD

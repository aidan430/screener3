-- Mazes for the maps: a grid of cells carved into a maze (a random depth-first walk, so every cell
-- can be reached), then a few extra walls knocked through so there are loops (no long dead
-- walks back), and a few 2x2 clearings opened up for big props. Walls are built in a style:
--   hedge   tall clipped hedges          bales   hay bales stacked four high
--   planks  wooden stall partitions      crates  stacked wooden boxes
--   thicket dark, uneven bushes (forest)
-- Every wall is taller than a jump, so you search corridor by corridor. Dead ends get hiding
-- spots at their back wall, and some corridors get spots along a wall's foot.
-- MazeKit.build(ctx, opts) -> maze. opts: cols, rows, size (cell width), height, style,
--   loops (share of extra walls removed), rooms (how many clearings), ox, oz (centre offset).
-- maze.cellCentre(c, r), maze.cells, maze.deadEnds, maze.rooms ({ centre, cells }),
-- maze.randomCell(), maze.spawns(n).
local MapKit = require(script.Parent.MapKit)

local MazeKit = {}
local T = 2 -- wall thickness

local function wall(ctx, style, a, b, height)
	local mid, len = (a + b) / 2, (b - a).Magnitude + T
	local along = CFrame.lookAt(mid, mid + (b - a))
	if style == "hedge" or style == "thicket" then
		local colour = if style == "hedge" then { 58, 112, 56 } else { 34, 64, 40 }
		MapKit.part(ctx, { Name = "MazeWall", Size = Vector3.new(T, height, len), CFrame = along * CFrame.new(0, height / 2, 0), Color = colour, Material = "LeafyGrass" })
		if style == "thicket" then -- an uneven top
			for i = 0, math.floor(len / 5) do
				local s = ctx.rng:NextNumber(2.5, 4)
				MapKit.part(ctx, { Name = "Bush", Shape = "Ball", Size = Vector3.one * s, CFrame = along * CFrame.new(0, height - 0.3, -len / 2 + i * 5 + 2), Color = { 40, 76, 46 }, Material = "LeafyGrass", CanCollide = false })
			end
		end
	elseif style == "bales" then
		local straw = ctx.def.straw
		for level = 0, 3 do
			local shade = 0.86 + ((level % 2) * 0.1)
			local skew = if level % 2 == 0 then 0 else 1 -- bricked, like a real stack
			MapKit.part(ctx, { Name = "MazeWall", Size = Vector3.new(T + 0.5, 2.5, len - skew), CFrame = along * CFrame.new(0, 1.25 + level * 2.5, 0), Color = { straw[1] * shade, straw[2] * shade, straw[3] * shade }, Material = "Grass" })
			for i = 0, math.floor(len / 4) - 1 do -- the twine round each bale
				MapKit.part(ctx, { Name = "Twine", Size = Vector3.new(T + 0.56, 2.52, 0.15), CFrame = along * CFrame.new(0, 1.25 + level * 2.5, -len / 2 + skew / 2 + 2 + i * 4), Color = { 150, 100, 60 }, Material = "Fabric", CanCollide = false, CanQuery = false })
			end
		end
	elseif style == "planks" then
		MapKit.part(ctx, { Name = "MazeWall", Size = Vector3.new(T * 0.6, height, len), CFrame = along * CFrame.new(0, height / 2, 0), Color = { 128, 82, 50 }, Material = "WoodPlanks" })
		for _, z in ipairs({ -len / 2 + 0.4, len / 2 - 0.4 }) do
			MapKit.part(ctx, { Name = "Post", Size = Vector3.new(1.2, height + 0.6, 1.2), CFrame = along * CFrame.new(0, (height + 0.6) / 2, z), Color = { 96, 62, 38 }, Material = "Wood" })
		end
	else -- crates
		local n = math.max(1, math.floor(len / 3))
		local s = len / n
		for i = 0, n - 1 do
			for level = 0, math.floor(height / s) do
				local turn = CFrame.Angles(0, ctx.rng:NextNumber(-0.08, 0.08), 0)
				MapKit.part(ctx, { Name = "MazeWall", Size = Vector3.new(T + 0.6, s, s), CFrame = along * CFrame.new(0, s / 2 + level * s, -len / 2 + s / 2 + i * s) * turn, Color = { 150 - level * 8, 106 - level * 6, 64 }, Material = "WoodPlanks" })
			end
		end
	end
end

function MazeKit.build(ctx, o)
	local cols, rows, size, rng = o.cols, o.rows, o.size, ctx.rng
	local east, south, seen = {}, {}, {}
	for c = 1, cols do
		east[c], south[c], seen[c] = {}, {}, {}
		for r = 1, rows do
			east[c][r], south[c][r] = c < cols, r < rows
		end
	end
	-- carve: a random depth-first walk
	local stack = { { rng:NextInteger(1, cols), rng:NextInteger(1, rows) } }
	seen[stack[1][1]][stack[1][2]] = true
	while #stack > 0 do
		local c, r = stack[#stack][1], stack[#stack][2]
		local options = {}
		for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
			local nc, nr = c + d[1], r + d[2]
			if nc >= 1 and nc <= cols and nr >= 1 and nr <= rows and not seen[nc][nr] then
				table.insert(options, { nc, nr, d })
			end
		end
		if #options == 0 then
			table.remove(stack)
		else
			local nc, nr, d = table.unpack(options[rng:NextInteger(1, #options)])
			if d[1] == 1 then east[c][r] = false elseif d[1] == -1 then east[nc][nr] = false elseif d[2] == 1 then south[c][r] = false else south[nc][nr] = false end
			seen[nc][nr] = true
			table.insert(stack, { nc, nr })
		end
	end
	-- loops: knock out a share of the remaining inner walls
	for c = 1, cols do
		for r = 1, rows do
			if east[c][r] and rng:NextNumber() < (o.loops or 0.15) then east[c][r] = false end
			if south[c][r] and rng:NextNumber() < (o.loops or 0.15) then south[c][r] = false end
		end
	end
	-- clearings: 2x2 blocks with no walls inside, spread out
	local rooms, taken = {}, {}
	for _ = 1, (o.rooms or 0) * 6 do
		if #rooms >= (o.rooms or 0) then break end
		local c, r = rng:NextInteger(1, cols - 1), rng:NextInteger(1, rows - 1)
		local free = true
		for _, q in ipairs(taken) do
			if math.abs(q[1] - c) < 3 and math.abs(q[2] - r) < 3 then free = false end
		end
		if free then
			east[c][r], east[c][r + 1], south[c][r], south[c + 1][r] = false, false, false, false
			table.insert(taken, { c, r })
			table.insert(rooms, { c = c, r = r })
		end
	end
	local maze = { cols = cols, rows = rows, size = size, cells = {}, deadEnds = {}, rooms = {} }
	ctx.maze = maze -- for server/Powerups
	local x0, z0 = (o.ox or 0) - cols * size / 2, (o.oz or 0) - rows * size / 2
	function maze.cellCentre(c, r)
		return x0 + (c - 0.5) * size, z0 + (r - 0.5) * size
	end
	local function at(x, z)
		return MapKit.at(ctx, x, 0, z)
	end
	-- the walls: inner ones, then the outside
	for c = 1, cols do
		for r = 1, rows do
			local x, z = x0 + c * size, z0 + r * size
			if east[c][r] then wall(ctx, o.style, at(x, z - size), at(x, z), o.height) end
			if south[c][r] then wall(ctx, o.style, at(x - size, z), at(x, z), o.height) end
		end
	end
	local x1, z1 = x0 + cols * size, z0 + rows * size
	for _, w in ipairs({ { x0, z0, x1, z0 }, { x0, z1, x1, z1 }, { x0, z0, x0, z1 }, { x1, z0, x1, z1 } }) do
		wall(ctx, o.style, at(w[1], w[2]), at(w[3], w[4]), o.height)
	end
	-- cells, dead ends and their hiding spots
	local inRoom = {}
	for _, room in ipairs(rooms) do
		local cx, cz = maze.cellCentre(room.c, room.r)
		table.insert(maze.rooms, { x = cx + size / 2, z = cz + size / 2 })
		for _, d in ipairs({ { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } }) do
			inRoom[(room.c + d[1]) .. "," .. (room.r + d[2])] = true
		end
	end
	for c = 1, cols do
		for r = 1, rows do
			local x, z = maze.cellCentre(c, r)
			local walls = {
				{ c == cols or east[c][r], 1, 0 }, { c == 1 or east[c - 1][r], -1, 0 },
				{ r == rows or south[c][r], 0, 1 }, { r == 1 or south[c][r - 1], 0, -1 },
			}
			local closed = {}
			for _, w in ipairs(walls) do
				if w[1] then table.insert(closed, w) end
			end
			if not inRoom[c .. "," .. r] then
				table.insert(maze.cells, { c = c, r = r, x = x, z = z })
			end
			local reach = size / 2 - T / 2 - 0.9
			if #closed == 3 then -- a dead end: two spots against its back wall
				table.insert(maze.deadEnds, { x = x, z = z })
				for _, w in ipairs(closed) do
					if rng:NextNumber() < 0.7 then
						local side = rng:NextNumber(-0.3, 0.3) * size
						MapKit.spot(ctx, at(x + w[2] * reach + w[3] * side, z + w[3] * reach + w[2] * side))
					end
				end
			elseif #closed > 0 and rng:NextNumber() < 0.35 then -- a corridor: one along a wall's foot
				local w = closed[rng:NextInteger(1, #closed)]
				local side = rng:NextNumber(-0.35, 0.35) * size
				MapKit.spot(ctx, at(x + w[2] * reach + w[3] * side, z + w[3] * reach + w[2] * side))
			end
		end
	end
	function maze.randomCell()
		return maze.cells[rng:NextInteger(1, #maze.cells)]
	end
	-- n spawn cells spread through the maze (every other cell of a shuffled list, far apart)
	function maze.spawns(n)
		local list = table.clone(maze.cells)
		for i = #list, 2, -1 do
			local j = rng:NextInteger(1, i)
			list[i], list[j] = list[j], list[i]
		end
		local picked = {}
		for _, cell in ipairs(list) do
			local ok = true
			for _, p in ipairs(picked) do
				if math.abs(p.c - cell.c) + math.abs(p.r - cell.r) < 3 then ok = false end
			end
			if ok then table.insert(picked, cell) end
			if #picked >= n then break end
		end
		for _, cell in ipairs(picked) do
			MapKit.spawnAt(ctx, cell.x, cell.z)
		end
	end
	return maze
end

return MazeKit

-- Draws a player's haystack as terrain from their save. Each player's screen draws only its own
-- haystack (they all stand in the same place), so this runs on the client; the server keeps
-- the save and checks every harvest against it. Usage: require(HeapTerrain)(Config).
return function(Config)
	local Layout = require(script.Parent.Layout)(Config)
	local HeapTerrain = {}
	local HEAP = Enum.Material.Grass -- recoloured to straw; its grass blades read as loose straw
	local STEPS = 8 -- a clump shrinks in this many visible steps as it's harvested
	local PER_CLUMP = Config.TotalStraws // Config.Clumps
	HeapTerrain.MATERIAL = HEAP

	function HeapTerrain.origin(centreX, centreZ)
		local x, z = Layout.origin(centreX, centreZ)
		return Vector3.new(x, 0, z)
	end

	-- How full a clump's cell looks: the heap's rounded outside, shrinking as it's harvested.
	function HeapTerrain.fullness(index, left)
		if left <= 0 then
			return 0
		end
		local step = math.ceil(left / PER_CLUMP * STEPS) / STEPS
		return Layout.shape[index] * (0.3 + 0.7 * step)
	end

	local function leftOf(removed, partial, index)
		if string.sub(removed, index, index) == "1" then
			return 0
		end
		return partial[tostring(index)] or PER_CLUMP
	end

	local function span()
		local s = Config.ClumpSize
		return s, math.ceil(Config.PileRadiusBottom / s) + 1
	end

	-- The whole heap, from the save's `removed` string and `partial` table.
	function HeapTerrain.draw(terrain, o, removed, partial)
		local s, n = span()
		local materials, amounts = {}, {}
		for x = 1, 2 * n + 1 do
			materials[x], amounts[x] = {}, {}
			for y = 1, Config.PileLayers do
				materials[x][y], amounts[x][y] = {}, {}
				for z = 1, 2 * n + 1 do
					materials[x][y][z], amounts[x][y][z] = Enum.Material.Air, 0
				end
			end
		end
		for index, cell in ipairs(Layout.cell) do
			local amount = HeapTerrain.fullness(index, leftOf(removed, partial, index))
			if amount > 0 then
				local x, y, z = cell[1] + n + 1, cell[2] + 1, cell[3] + n + 1
				materials[x][y][z], amounts[x][y][z] = HEAP, amount
			end
		end
		local corner = o - Vector3.new(n * s + s / 2, 0, n * s + s / 2)
		terrain:WriteVoxels(Region3.new(corner, corner + Vector3.new((2 * n + 1) * s, Config.PileLayers * s, (2 * n + 1) * s)), s, materials, amounts)
	end

	local function region(o, index)
		local c = Layout[index]
		if not c then
			return nil
		end
		local centre = o + Vector3.new(c[1], c[2], c[3])
		local half = Vector3.new(1, 1, 1) * (Config.ClumpSize / 2)
		return Region3.new(centre - half, centre + half)
	end

	-- How full a clump's cell looks on this screen right now (0..1).
	function HeapTerrain.occupancy(terrain, o, index)
		local r = region(o, index)
		if not r then
			return 0
		end
		local _, amounts = terrain:ReadVoxels(r, Config.ClumpSize)
		return amounts[1][1][1]
	end

	-- One clump, after a harvest or a machine took from it. `cap` (optional) keeps it from
	-- looking fuller than it does now (the dents you've made stay; it never grows back).
	function HeapTerrain.cell(terrain, o, index, left, cap)
		local r = region(o, index)
		if not r then
			return
		end
		local amount = HeapTerrain.fullness(index, left)
		if cap and amount > 0 then
			amount = math.min(amount, cap)
		end
		terrain:WriteVoxels(r, Config.ClumpSize, { { { if amount > 0 then HEAP else Enum.Material.Air } } }, { { { amount } } })
	end

	return HeapTerrain
end

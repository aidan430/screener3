-- Where each clump sits in the heap: one cell of the 4-stud terrain grid each, in
-- Config.PileLayers layers that taper from PileRadiusBottom to a peak (curved by PileCurve), trimmed
-- at the bottom edge to exactly Config.Clumps. Always the same order (bottom to top), so a clump's
-- index means the same clump in every visit; saves refer to clumps by index.
-- Plain Luau: no Roblox services. Returns a list of { x, y, z } offsets from the heap's base centre,
-- with these extras:
--   .cell[i] = { gx, layer, gz }       .lookup(gx, layer, gz) -> index or nil
--   .shape[i] = terrain fullness 0..1 that rounds the heap's outside smoothly
--   .core[i] = how far out the clump is, 0 at the middle to 1 at the outside
--   .machineOrder = indices from the outside skin inwards (machines peel the heap evenly)
--   .needleSpots = indices deep inside the upper heap, where the needle hides
--   .origin(x, z) = the heap's base centre for a plot centre, on the terrain grid
return function(Config)
	local s = Config.ClumpSize
	local layerCount = Config.PileLayers
	local r0, r1, curve = Config.PileRadiusBottom, Config.PileRadiusTop, Config.PileCurve
	local layers, radius = {}, {}
	local total = 0
	for i = 0, layerCount - 1 do
		local r = r1 + (r0 - r1) * (1 - i / (layerCount - 1)) ^ curve
		radius[i] = r
		local n = math.floor(r / s)
		local layer = {}
		for gx = -n, n do
			for gz = -n, n do
				if (gx * s) ^ 2 + (gz * s) ^ 2 <= r * r then
					table.insert(layer, { gx, i, gz, gx * gx + gz * gz })
				end
			end
		end
		total += #layer
		layers[i + 1] = layer
	end
	-- too many: trim the outermost clumps of the lowest layers, a quarter of a layer at most
	local excess = total - Config.Clumps
	for _, layer in ipairs(layers) do
		if excess <= 0 then
			break
		end
		table.sort(layer, function(a, b)
			if a[4] ~= b[4] then
				return a[4] > b[4]
			elseif a[1] ~= b[1] then
				return a[1] < b[1]
			end
			return a[3] < b[3]
		end)
		local cut = math.min(excess, math.floor(#layer / 4))
		for _ = 1, cut do
			table.remove(layer, 1)
		end
		excess -= cut
	end
	local out = { cell = {}, shape = {}, core = {}, machineOrder = {}, needleSpots = {} }
	local grid = {}
	for _, layer in ipairs(layers) do
		table.sort(layer, function(a, b)
			if a[1] ~= b[1] then
				return a[1] < b[1]
			end
			return a[3] < b[3]
		end)
		for _, c in ipairs(layer) do
			table.insert(out, { c[1] * s, c[2] * s + s / 2, c[3] * s })
			local index = #out
			local r = radius[c[2]]
			local d = math.sqrt(c[4]) * s
			out.cell[index] = { c[1], c[2], c[3] }
			out.shape[index] = math.clamp((r - d) / s + 0.5, 0.35, 1)
			out.core[index] = math.clamp(d / math.max(r, s), 0, 1)
			grid[c[1] .. "," .. c[2] .. "," .. c[3]] = index
		end
	end
	function out.lookup(gx, layer, gz)
		return grid[gx .. "," .. layer .. "," .. gz]
	end
	-- outside first (most exposed), then lower first, then by index, so the order never changes
	for i = 1, #out do
		out.machineOrder[i] = i
	end
	table.sort(out.machineOrder, function(a, b)
		local ca, cb = math.floor(out.core[a] * 8), math.floor(out.core[b] * 8)
		if ca ~= cb then
			return ca > cb
		elseif out.cell[a][2] ~= out.cell[b][2] then
			return out.cell[a][2] < out.cell[b][2]
		end
		return a < b
	end)
	local low, high = Config.NeedleHeight[1] * layerCount, Config.NeedleHeight[2] * layerCount
	for i = 1, #out do
		local layer = out.cell[i][2]
		if layer >= low and layer <= high and out.core[i] <= Config.NeedleCore then
			table.insert(out.needleSpots, i)
		end
	end
	function out.origin(x, z)
		return math.floor(x / s) * s + s / 2, math.floor(z / s) * s + s / 2
	end
	return out
end

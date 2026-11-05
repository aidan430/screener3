-- Where each clump sits in the pile: a tapering stack of Config.PileLayers layers, trimmed
-- at the bottom edge to exactly Config.Clumps. Always the same order (bottom to top), so a
-- clump's index means the same clump in every visit; saves refer to clumps by index.
-- Plain Luau: no Roblox services. Returns { {x, y, z}, ... } offsets from the pile's base centre.
return function(Config)
	local s = Config.ClumpSize
	local layerCount = Config.PileLayers
	local layers = {}
	local total = 0
	for i = 0, layerCount - 1 do
		local r = Config.PileRadiusBottom - (Config.PileRadiusBottom - Config.PileRadiusTop) * i / (layerCount - 1)
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
	local out = {}
	for _, layer in ipairs(layers) do
		table.sort(layer, function(a, b)
			if a[1] ~= b[1] then
				return a[1] < b[1]
			end
			return a[3] < b[3]
		end)
		for _, c in ipairs(layer) do
			table.insert(out, { c[1] * s, c[2] * s + s / 2, c[3] * s })
		end
	end
	return out
end

-- Map builders: Classic Haystack Field, Barn Interior and Farm at Sunset (shared/Maps holds their
-- names, light and colours). Each builds round ctx.centre with MapKit, records its hiding spots
-- as it goes, adds at least six spawn points, then scatters the round's loose straw
-- (ctx.diff.clutter) and, on Hard, tumbling hay (ctx.diff.moving).
local MapKit = require(script.Parent.MapKit)

local MapsA = {}

local function ring(ctx, count, radius)
	for i = 1, count do
		local a = i / count * math.pi * 2
		MapKit.spawnAt(ctx, math.cos(a) * radius, math.sin(a) * radius)
	end
end

local function finish(ctx, half)
	MapKit.clutter(ctx, ctx.diff.clutter, half, half)
	MapKit.moving(ctx, ctx.diff.moving, half * 0.8, half * 0.8)
end

-- Classic Haystack Field: open grass, round haystacks, bales in heaps, a cart and fences.
function MapsA.field(ctx)
	local r = ctx.rng
	MapKit.ground(ctx, 140, 140, ctx.def.ground, "Grass")
	MapKit.edges(ctx, 68, 68, ctx.def.ground)
	for _, e in ipairs({ { -60, -60, 60, -60 }, { 60, -60, 60, 60 }, { 60, 60, -60, 60 }, { -60, 60, -60, -60 } }) do
		MapKit.fence(ctx, e[1], e[2], e[3], e[4])
	end
	for _ = 1, 9 do
		MapKit.haystack(ctx, r:NextNumber(-48, 48), r:NextNumber(-48, 48), r:NextNumber(5, 7.5), r:NextNumber(9, 13))
	end
	for _ = 1, 7 do -- heaps of bales: a row of three with one on top
		local x, z, turn = r:NextNumber(-50, 50), r:NextNumber(-50, 50), r:NextNumber() * math.pi
		local along = Vector3.new(math.cos(turn), 0, -math.sin(turn)) * 4.1
		for i = -1, 1 do
			MapKit.bale(ctx, x + along.X * i, 0, z + along.Z * i, turn)
		end
		MapKit.bale(ctx, x, 2.5, z, turn)
	end
	for _ = 1, 4 do -- a hay cart: a crate on wheels
		local x, z = r:NextNumber(-45, 45), r:NextNumber(-45, 45)
		MapKit.crate(ctx, x, 0.8, z, 4)
		for _, d in ipairs({ { -2, -2 }, { 2, -2 }, { -2, 2 }, { 2, 2 } }) do
			MapKit.part(ctx, { Name = "Wheel", Shape = "Cylinder", Size = Vector3.new(0.4, 1.6, 1.6), CFrame = CFrame.new(MapKit.at(ctx, x + d[1], 0.8, z + d[2])), Color = { 90, 64, 40 }, Material = "Wood" })
		end
	end
	ring(ctx, 8, 30)
	finish(ctx, 55)
end

-- Barn Interior: a big wooden barn with stalls, stacked bales, crates, a hay loft up the stairs
-- along one side, and warm hanging lamps.
function MapsA.barn(ctx)
	local r = ctx.rng
	local W, D, H = 76, 52, 24
	local wood, dark = { 150, 96, 60 }, { 110, 70, 44 }
	MapKit.ground(ctx, W + 10, D + 10, ctx.def.ground, "WoodPlanks")
	for _, w in ipairs({ { 0, -D / 2, W, 1 }, { 0, D / 2, W, 1 }, { -W / 2, 0, 1, D }, { W / 2, 0, 1, D } }) do
		MapKit.wall(ctx, CFrame.new(MapKit.at(ctx, w[1], H / 2, w[2])), Vector3.new(w[3], H, w[4]), { 168, 70, 56 }, "WoodPlanks")
	end
	MapKit.wall(ctx, CFrame.new(MapKit.at(ctx, 0, H + 0.5, 0)), Vector3.new(W, 1, D), dark, "WoodPlanks")
	-- the loft along the back wall, at 10 studs, and stairs up to it
	local loftZ = -D / 2 + 7
	MapKit.wall(ctx, CFrame.new(MapKit.at(ctx, 0, 10, loftZ)), Vector3.new(W - 2, 1, 14), wood, "WoodPlanks")
	for i = 0, 11 do
		MapKit.wall(ctx, CFrame.new(MapKit.at(ctx, -W / 2 + 4, 0.4 + i * 0.8, loftZ + 7 + 19 - i * 1.6)), Vector3.new(6, 0.8, 1.7), wood, "WoodPlanks")
	end
	for _ = 1, 8 do
		MapKit.bale(ctx, r:NextNumber(-W / 2 + 10, W / 2 - 6), 10.5, loftZ + r:NextNumber(-4, 4), r:NextNumber() * 3, true)
	end
	for i = 0, 4 do -- the loft's edge spots
		MapKit.spot(ctx, MapKit.at(ctx, -W / 2 + 12 + i * 12, 10.5, loftZ + 6), true)
	end
	-- stalls down the front: low walls with bales and crates between
	for i = 0, 4 do
		local x = -W / 2 + 12 + i * 13
		MapKit.wall(ctx, CFrame.new(MapKit.at(ctx, x, 2, D / 2 - 7)), Vector3.new(0.6, 4, 12), dark, "WoodPlanks")
		MapKit.bale(ctx, x + 4, 0, D / 2 - 5, math.pi / 2)
		MapKit.bale(ctx, x + 4, 2.5, D / 2 - 5, math.pi / 2)
		MapKit.crate(ctx, x + 7.5, 0, D / 2 - 10, 2.5)
	end
	for _ = 1, 10 do
		MapKit.crate(ctx, r:NextNumber(-W / 2 + 8, W / 2 - 8), 0, r:NextNumber(-4, 10), r:NextNumber(2, 3.5))
	end
	for _ = 1, 6 do
		MapKit.bale(ctx, r:NextNumber(-W / 2 + 8, W / 2 - 8), 0, r:NextNumber(-6, 12), r:NextNumber() * 3)
	end
	for i = 0, 3 do
		MapKit.lamp(ctx, MapKit.at(ctx, -W / 2 + 12 + i * 17, H - 3, 0), { 255, 196, 120 }, 30)
	end
	ring(ctx, 8, 12)
	finish(ctx, 32)
end

-- Farm at Sunset: a farmhouse, a tractor, a scarecrow over rows of crops, haystacks and bales
-- in long orange light.
function MapsA.sunset(ctx)
	local r = ctx.rng
	MapKit.ground(ctx, 140, 140, ctx.def.ground, "Grass")
	MapKit.edges(ctx, 68, 68, ctx.def.ground)
	local house = MapKit.wall(ctx, CFrame.new(MapKit.at(ctx, -38, 8, -38)), Vector3.new(24, 16, 18), { 236, 226, 200 }, "WoodPlanks")
	MapKit.part(ctx, { Name = "Roof", Size = Vector3.new(26, 2, 20), CFrame = CFrame.new(house.Position + Vector3.new(0, 9, 0)), Color = { 150, 60, 50 }, Material = "Slate" })
	MapKit.spotsOn(ctx, house, 0, 4)
	-- the tractor
	local body = MapKit.wall(ctx, CFrame.new(MapKit.at(ctx, 30, 2.5, -30)), Vector3.new(8, 3, 4.5), { 196, 52, 40 }, "SmoothPlastic")
	MapKit.part(ctx, { Name = "Cab", Size = Vector3.new(3.5, 3.5, 4), CFrame = body.CFrame * CFrame.new(-2, 3, 0), Color = { 196, 52, 40 }, Material = "SmoothPlastic" })
	for _, w in ipairs({ { -3, 2.2, 3.6 }, { 3, 1.4, 2.2 } }) do
		for _, side in ipairs({ -1, 1 }) do
			MapKit.part(ctx, { Name = "Wheel", Shape = "Cylinder", Size = Vector3.new(1, w[3] * 2, w[3] * 2), CFrame = CFrame.new(MapKit.at(ctx, 30 + w[1], w[3], -30 + side * 2.8)) * CFrame.Angles(0, math.pi / 2, 0), Color = { 40, 40, 44 }, Material = "Fabric" })
		end
	end
	MapKit.spotsOn(ctx, body, 1, 4)
	-- rows of crops and a scarecrow
	for row = 0, 7 do
		local x = -10 + row * 5
		MapKit.part(ctx, { Name = "Crops", Size = Vector3.new(2, 1.2, 36), CFrame = CFrame.new(MapKit.at(ctx, x, 0.6, 30)), Color = { 90, 140, 60 }, Material = "Grass" })
		for _ = 1, 2 do
			MapKit.spot(ctx, MapKit.at(ctx, x + 2.5, 0, 30 + r:NextNumber(-16, 16)))
		end
	end
	MapKit.part(ctx, { Name = "Pole", Size = Vector3.new(0.5, 9, 0.5), CFrame = CFrame.new(MapKit.at(ctx, 7, 4.5, 30)), Color = { 120, 84, 50 }, Material = "Wood" })
	MapKit.part(ctx, { Name = "Scarecrow", Shape = "Ball", Size = Vector3.one * 2.4, CFrame = CFrame.new(MapKit.at(ctx, 7, 9.5, 30)), Color = { 214, 186, 140 }, Material = "Fabric" })
	for _ = 1, 7 do
		MapKit.haystack(ctx, r:NextNumber(-50, 50), r:NextNumber(-50, 10), r:NextNumber(5, 7), r:NextNumber(9, 12))
	end
	for _ = 1, 10 do
		MapKit.bale(ctx, r:NextNumber(-50, 50), 0, r:NextNumber(-50, 50), r:NextNumber() * 3)
	end
	for _, e in ipairs({ { -60, 60, 60, 60 }, { 60, -60, 60, 60 } }) do
		MapKit.fence(ctx, e[1], e[2], e[3], e[4])
	end
	ring(ctx, 8, 26)
	finish(ctx, 55)
end

return MapsA

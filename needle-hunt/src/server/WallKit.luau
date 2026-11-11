-- Dressing for maze walls (server/MazeWalls builds each wall's solid core, then calls these):
-- leafy panels, lumps and sprigs that break up a hedge's flat faces and straight top, a dark foot
-- where it meets the ground, cap stones, moss and ivy on a dry-stone wall, a bean-and-gourd trellis
-- for the vines, leaves and soil ridges for the corn. Everything here is to look at only: it can't
-- be walked into, clicked or hit, and small pieces cast no shadow. It draws from its own random
-- numbers, so the mazes, chests and spawns come out the same with or without it.
-- A wall's frame `cf` sits on the floor at its middle: X across the wall, Y up, Z along it.
local MapKit = require(script.Parent.MapKit)

local WallKit = {}

local function rng(ctx)
	ctx.decoRng = ctx.decoRng or Random.new(4117)
	return ctx.decoRng
end

-- A colour near `c`: lighter or darker by up to `by` (0.1 = 10%).
function WallKit.tone(ctx, c, by)
	local k = 1 + rng(ctx):NextNumber(-by, by)
	return { math.clamp(c[1] * k, 0, 255), math.clamp(c[2] * k, 0, 255), math.clamp(c[3] * k, 0, 255) }
end

-- A part to look at only. fine = true for the smallest pieces (kept in a "Fine" folder, so a
-- weak device could drop them); shadow = true if it should cast one.
function WallKit.deco(ctx, props, shadow, fine)
	if fine and not ctx.fine then
		ctx.fine = Instance.new("Folder")
		ctx.fine.Name = "Fine"
		ctx.fine.Parent = ctx.model
	end
	props.CanCollide, props.CanQuery, props.CanTouch, props.CastShadow = false, false, false, shadow == true
	props.Parent = if fine then ctx.fine else nil
	return MapKit.part(ctx, props)
end

local GREENS = { { 58, 100, 48 }, { 66, 108, 50 }, { 52, 92, 44 } }

-- A clipped hedge's dressing. y0 lifts it (a hedge growing on a stone wall); share scales how much.
function WallKit.hedge(ctx, cf, len, height, T, y0, share)
	local r = rng(ctx)
	y0, share = y0 or 0, share or 1
	local n = math.max(1, math.floor(len / 16 * 3 * share + 0.5))
	for side = -1, 1, 2 do -- leafy panels standing a little proud of each face
		for i = 1, n do
			local l = len / n * r:NextNumber(0.78, 0.94)
			local h = height - r:NextNumber(0.8, 1.8)
			local z = -len / 2 + (i - 0.5) * len / n + r:NextNumber(-0.5, 0.5)
			WallKit.deco(ctx, { Name = "HedgeFace", Size = Vector3.new(0.5, h, l), CFrame = cf * CFrame.new(side * (T / 2 + r:NextNumber(0.08, 0.3)), y0 + 0.7 + h / 2, z) * CFrame.Angles(0, math.rad(r:NextNumber(-3, 3)), 0), Color = WallKit.tone(ctx, GREENS[r:NextInteger(1, #GREENS)], 0.08), Material = "LeafyGrass" })
		end
	end
	if y0 == 0 then -- a dark foot, so it sits in the ground instead of on it
		WallKit.deco(ctx, { Name = "HedgeFoot", Size = Vector3.new(T + 0.9, 0.9, len), CFrame = cf * CFrame.new(0, 0.45, 0), Color = { 40, 52, 34 }, Material = "LeafyGrass" })
	end
	for i = 1, n do -- lumps that break the straight top
		local l = r:NextNumber(3.5, 5)
		local z = -len / 2 + (i - 0.5) * len / n + r:NextNumber(-1.5, 1.5)
		local diamond = i % 3 == 0
		WallKit.deco(ctx, { Name = "HedgeTop", Size = if diamond then Vector3.new(1.8, 1.8, 2.6) else Vector3.new(T + 0.4, 1.3, l), CFrame = cf * CFrame.new(r:NextNumber(-0.2, 0.2), y0 + height - 0.2, z) * CFrame.Angles(0, 0, math.rad(if diamond then 45 else r:NextNumber(-8, 8))), Color = WallKit.tone(ctx, { 84, 128, 60 }, 0.08), Material = "LeafyGrass" }, true)
	end
	for _ = 1, math.floor(len / 16 * 2 * share + 0.5) do -- sprigs the shears missed
		WallKit.deco(ctx, { Name = "Sprig", Size = Vector3.new(0.15, 1.2, 0.15), CFrame = cf * CFrame.new(r:NextNumber(-0.6, 0.6), y0 + height + 0.5, r:NextNumber(-len / 2 + 1, len / 2 - 1)) * CFrame.Angles(math.rad(r:NextNumber(-20, 20)), 0, math.rad(r:NextNumber(-20, 20))), Color = { 96, 134, 62 }, Material = "LeafyGrass" }, false, true)
	end
end

-- A dry-stone wall's dressing: cap stones (a ledge under the hedge), moss, ivy and a fallen stone.
function WallKit.stone(ctx, cf, len, stoneH, T)
	local r = rng(ctx)
	local n = math.max(1, math.floor(len / 4.2))
	for i = 1, n do
		local l = len / n
		WallKit.deco(ctx, { Name = "CapStone", Size = Vector3.new(T + 1.4, 0.45, l - 0.06), CFrame = cf * CFrame.new(r:NextNumber(-0.08, 0.08), stoneH + 0.1, -len / 2 + (i - 0.5) * l) * CFrame.Angles(0, math.rad(r:NextNumber(-2, 2)), 0), Color = WallKit.tone(ctx, { 124, 120, 112 }, 0.08), Material = "Slate" })
	end
	for _ = 1, math.floor(len / 16 * 2 + 0.5) do
		local side = if r:NextNumber() < 0.5 then -1 else 1
		local z = r:NextNumber(-len / 2 + 1, len / 2 - 1)
		WallKit.deco(ctx, { Name = "Moss", Size = Vector3.new(1.2, 0.15, 2), CFrame = cf * CFrame.new(side * (T / 2 + 0.2), stoneH + 0.36, z), Color = { 86, 112, 60 }, Material = "LeafyGrass" }, false, true)
		local h = r:NextNumber(2, 4)
		WallKit.deco(ctx, { Name = "Ivy", Size = Vector3.new(0.12, h, 0.5), CFrame = cf * CFrame.new(-side * (T / 2 + 0.36), stoneH - h / 2, z + 2), Color = { 40, 70, 40 }, Material = "LeafyGrass" }, false, true)
	end
	if r:NextNumber() < 0.5 then
		local side = if r:NextNumber() < 0.5 then -1 else 1
		WallKit.deco(ctx, { Name = "FallenStone", Size = Vector3.new(1.2, 0.8, 1.5), CFrame = cf * CFrame.new(side * (T / 2 + 1.2), 0.4, r:NextNumber(-len / 2 + 1, len / 2 - 1)) * CFrame.Angles(0, r:NextNumber(0, 3), 0), Color = WallKit.tone(ctx, { 150, 148, 142 }, 0.1), Material = "Slate" }, false, true)
	end
end

-- Footing stones along a hedge's foot (the hedge half of a stone-and-hedge maze).
function WallKit.footings(ctx, cf, len, T)
	local r = rng(ctx)
	for i = 1, math.max(1, math.floor(len / 4)) do
		local l = r:NextNumber(2.5, 4)
		WallKit.deco(ctx, { Name = "Footing", Size = Vector3.new(T + 1, 0.9, l), CFrame = cf * CFrame.new(r:NextNumber(-0.1, 0.1), 0.45, -len / 2 + (i - 0.5) * len / math.max(1, math.floor(len / 4))) * CFrame.Angles(0, math.rad(r:NextNumber(-3, 3)), 0), Color = WallKit.tone(ctx, { 150, 148, 140 }, 0.1), Material = "Slate" })
	end
end

-- The vines as a bean-and-gourd trellis: posts and a rail, leaf slabs set as diamonds (some
-- breaking the top line), hanging stems and a gourd or two.
function WallKit.trellis(ctx, cf, len, height, T)
	local r = rng(ctx)
	for i = 0, math.max(1, math.floor(len / 8)) do
		local z = -len / 2 + 0.3 + i * (len - 0.6) / math.max(1, math.floor(len / 8))
		WallKit.deco(ctx, { Name = "TrellisPost", Size = Vector3.new(T + 0.5, height + 1, 0.6), CFrame = cf * CFrame.new(0, (height + 1) / 2, z), Color = WallKit.tone(ctx, { 112, 96, 80 }, 0.08), Material = "Wood" }, true)
	end
	WallKit.deco(ctx, { Name = "TrellisRail", Size = Vector3.new(0.4, 0.4, len), CFrame = cf * CFrame.new(0, height + 0.6, 0), Color = { 104, 88, 70 }, Material = "Wood" })
	local leaves = { { 58, 98, 44 }, { 74, 116, 50 }, { 92, 128, 58 } }
	for i = 0, math.floor(len / 2) - 1 do
		local side = if i % 2 == 0 then -1 else 1
		local s = r:NextNumber(3, 4.2)
		local top = i % 3 == 0
		WallKit.deco(ctx, { Name = "LeafSlab", Size = Vector3.new(0.6, s, s), CFrame = cf * CFrame.new(side * (T / 2 + r:NextNumber(0, 0.25)), if top then r:NextNumber(height - 1, height + 0.5) else r:NextNumber(2.5, height - 1.5), -len / 2 + 1 + i * 2) * CFrame.Angles(math.rad(45 + r:NextNumber(-15, 15)), 0, 0), Color = WallKit.tone(ctx, leaves[r:NextInteger(1, 3)], 0.06), Material = "LeafyGrass" }, top)
	end
	for _ = 1, math.floor(len / 16 * 4 + 0.5) do
		local side = if r:NextNumber() < 0.5 then -1 else 1
		local z = r:NextNumber(-len / 2 + 1, len / 2 - 1)
		local h = r:NextNumber(5, 9)
		WallKit.deco(ctx, { Name = "Stem", Size = Vector3.new(0.22, h, 0.22), CFrame = cf * CFrame.new(side * (T / 2 + 0.08), h / 2 + 0.5, z) * CFrame.Angles(math.rad(r:NextNumber(15, 25) * (if r:NextNumber() < 0.5 then -1 else 1)), 0, 0), Color = { 70, 58, 40 }, Material = "Wood" }, false, true)
		if r:NextNumber() < 0.5 then
			local d = r:NextNumber(0.9, 1.3)
			WallKit.deco(ctx, { Name = "Gourd", Shape = "Ball", Size = Vector3.one * d, CFrame = cf * CFrame.new(side * (T / 2 + 0.35), r:NextNumber(1.2, 4), z + 1), Color = if r:NextNumber() < 0.6 then { 204, 108, 36 } else { 150, 160, 60 }, Material = "SmoothPlastic" }, false, true)
		end
	end
end

-- Corn: a long leaf through every other stalk's place and a soil ridge along each side.
function WallKit.corn(ctx, cf, len, height, T)
	local r = rng(ctx)
	for i = 0, math.floor(len / 2.8) do
		local z = -len / 2 + 0.5 + i * 2.8
		local x = r:NextNumber(-0.6, 0.6)
		WallKit.deco(ctx, { Name = "CornLeaf", Size = Vector3.new(0.08, 0.5, 3.2), CFrame = cf * CFrame.new(x, height * r:NextNumber(0.35, 0.7), z) * CFrame.Angles(0, r:NextNumber(0, math.pi), 0) * CFrame.Angles(math.rad(r:NextNumber(20, 40)), 0, 0), Color = WallKit.tone(ctx, { 150, 150, 74 }, 0.1), Material = "Grass" }, false, true)
	end
	for side = -1, 1, 2 do
		WallKit.deco(ctx, { Name = "SoilRidge", Size = Vector3.new(1.3, 0.5, len), CFrame = cf * CFrame.new(side * (T / 2 + 0.15), 0.2, 0), Color = { 112, 90, 62 }, Material = "Ground" })
	end
end

return WallKit

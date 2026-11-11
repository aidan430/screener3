-- More maze wall styles (server/MazeKit uses these when a map asks for one; it has its own
-- hedge, thicket, bales, planks and crates). Each builds one wall from a to b (both on the floor),
-- `height` tall and T studs thick, always taller than a jump:
--   vines       twisting green vines with leafy lumps (Pumpkin Patch)
--   corn        tall golden corn stalks with ears and tassels (Harvest Corn Maze)
--   sunflowers  green stalks topped with big sunflower heads (Sunflower Labyrinth)
--   stone       a dry-stone wall of grey blocks with a hedge on top (Windmill Hill)
--   stonehedge  stone or hedge, picked wall by wall (Windmill Hill's mix)
--   snowbales   hay bales three high under thick snow, with fence posts (Frozen Farm)
--   glass       greenhouse panels in green and blue frames, frosted so you see shapes, not
--               faces, with shelves of pots along the bottom (Rainy Greenhouse)
--   reeds       tall, round-topped marsh reeds (Duck Pond Marsh)
--   stalls      the backs of market stalls under striped awnings (Hay Market)
--   tents       fairground tents and booths in candy stripes (County Fair)
local MapKit = require(script.Parent.MapKit)
local WallKit = require(script.Parent.WallKit) -- the dressing: leaves, lumps, cap stones

local MazeWalls = {}

local function along(a, b)
	local mid = (a + b) / 2
	return CFrame.lookAt(mid, mid + (b - a)), (b - a).Magnitude
end

function MazeWalls.vines(ctx, a, b, height, T)
	local cf, l = along(a, b)
	local len = l + T
	MapKit.part(ctx, { Name = "MazeWall", Size = Vector3.new(T, height, len), CFrame = cf * CFrame.new(0, height / 2, 0), Color = WallKit.tone(ctx, { 44, 84, 40 }, 0.06), Material = "LeafyGrass" })
	WallKit.trellis(ctx, cf, len, height, T)
end

-- A clipped hedge (server/MazeKit's "hedge" style comes here).
function MazeWalls.hedge(ctx, a, b, height, T)
	local cf, l = along(a, b)
	local len = l + T
	MapKit.part(ctx, { Name = "MazeWall", Size = Vector3.new(T, height, len), CFrame = cf * CFrame.new(0, height / 2, 0), Color = WallKit.tone(ctx, { 46, 82, 42 }, 0.06), Material = "LeafyGrass" })
	WallKit.hedge(ctx, cf, len, height, T)
end

function MazeWalls.corn(ctx, a, b, height, T)
	local cf, l = along(a, b)
	local len = l + T
	MapKit.part(ctx, { Name = "MazeWall", Size = Vector3.new(T * 0.8, height * 0.85, len), CFrame = cf * CFrame.new(0, height * 0.425, 0), Color = { 122, 112, 60 }, Material = "Grass" })
	WallKit.corn(ctx, cf, len, height, T)
	for i = 0, math.floor(len / 1.4) do -- stalks, each with leaves, a cob and a tassel
		local z = -len / 2 + 0.5 + i * 1.4
		local x = ctx.rng:NextNumber(-0.6, 0.6)
		local h = height + ctx.rng:NextNumber(0.5, 2)
		MapKit.part(ctx, { Name = "Stalk", Size = Vector3.new(0.35, h, 0.35), CFrame = cf * CFrame.new(x, h / 2, z) * CFrame.Angles(math.rad(ctx.rng:NextNumber(-4, 4)), 0, math.rad(ctx.rng:NextNumber(-4, 4))), Color = WallKit.tone(ctx, if i % 3 == 0 then { 128, 138, 66 } else { 196, 170, 92 }, 0.1), Material = "Grass", CanCollide = false, CanQuery = false, CastShadow = i % 2 == 0 })
		MapKit.part(ctx, { Name = "Tassel", Size = Vector3.new(0.9, 0.9, 0.2), CFrame = cf * CFrame.new(x, h + 0.2, z) * CFrame.Angles(0, 0, math.rad(45)), Color = { 236, 204, 110 }, Material = "Grass", CanCollide = false, CanQuery = false })
		if ctx.rng:NextNumber() < 0.45 then
			local side = if ctx.rng:NextNumber() < 0.5 then -1 else 1
			MapKit.part(ctx, { Name = "Cob", Shape = "Cylinder", Size = Vector3.new(1.3, 0.55, 0.55), CFrame = cf * CFrame.new(x + side * 0.55, h * 0.55, z) * CFrame.Angles(0, 0, math.rad(70)), Color = { 250, 210, 60 }, Material = "SmoothPlastic", CanCollide = false, CanQuery = false })
		end
	end
end

function MazeWalls.sunflowers(ctx, a, b, height, T)
	local cf, l = along(a, b)
	local len = l + T
	MapKit.part(ctx, { Name = "MazeWall", Size = Vector3.new(T, height * 0.8, len), CFrame = cf * CFrame.new(0, height * 0.4, 0), Color = { 70, 136, 56 }, Material = "LeafyGrass" })
	for i = 0, math.floor(len / 2.4) do
		local z = -len / 2 + 1 + i * 2.4
		local h = height + ctx.rng:NextNumber(-0.5, 1.5)
		local head = cf * CFrame.new(0, h, z) * CFrame.Angles(0, if ctx.rng:NextNumber() < 0.5 then 0 else math.pi, 0)
		MapKit.part(ctx, { Name = "Stem", Size = Vector3.new(0.35, h, 0.35), CFrame = cf * CFrame.new(0, h / 2, z), Color = { 60, 126, 46 }, Material = "Grass", CanCollide = false, CanQuery = false })
		MapKit.part(ctx, { Name = "Petals", Shape = "Cylinder", Size = Vector3.new(0.3, 2.6, 2.6), CFrame = head * CFrame.Angles(0, math.rad(90), 0), Color = { 255, 206, 40 }, Material = "SmoothPlastic", CanCollide = false })
		MapKit.part(ctx, { Name = "Seeds", Shape = "Cylinder", Size = Vector3.new(0.4, 1.3, 1.3), CFrame = head * CFrame.new(0, 0, 0.08) * CFrame.Angles(0, math.rad(90), 0), Color = { 96, 58, 30 }, Material = "Fabric", CanCollide = false })
	end
end

function MazeWalls.stone(ctx, a, b, height, T)
	local cf, l = along(a, b)
	local len = l + T
	local stoneH = math.min(5, height * 0.55)
	local n = math.max(1, math.floor(len / 2.6))
	local s = len / n
	for row = 0, 1 do
		for i = 0, n - 1 do -- blocks, each row shifted half a block and a little rough
			local z = -len / 2 + s / 2 + i * s + (if row == 1 and i < n - 1 then s / 2 else 0)
			local shade = ctx.rng:NextInteger(150, 182)
			MapKit.part(ctx, { Name = "MazeWall", Size = Vector3.new(T + 0.6, stoneH / 2, s - 0.08), CFrame = cf * CFrame.new(0, stoneH / 4 + row * stoneH / 2, z) * CFrame.Angles(0, ctx.rng:NextNumber(-0.04, 0.04), 0), Color = { shade - 8, shade - 10, shade - 16 }, Material = "Slate" })
		end
	end
	MapKit.part(ctx, { Name = "MazeWall", Size = Vector3.new(T, height - stoneH, len), CFrame = cf * CFrame.new(0, stoneH + (height - stoneH) / 2, 0), Color = WallKit.tone(ctx, { 48, 84, 42 }, 0.06), Material = "LeafyGrass" })
	WallKit.stone(ctx, cf, len, stoneH, T)
	WallKit.hedge(ctx, cf, len, height - stoneH, T, stoneH, 0.67)
end

function MazeWalls.stonehedge(ctx, a, b, height, T)
	if ctx.rng:NextNumber() < 0.5 then
		MazeWalls.stone(ctx, a, b, height, T)
	else
		local cf, l = along(a, b)
		MapKit.part(ctx, { Name = "MazeWall", Size = Vector3.new(T, height, l + T), CFrame = cf * CFrame.new(0, height / 2, 0), Color = WallKit.tone(ctx, { 46, 82, 42 }, 0.06), Material = "LeafyGrass" })
		WallKit.hedge(ctx, cf, l + T, height, T)
		WallKit.footings(ctx, cf, l + T, T)
	end
end

function MazeWalls.snowbales(ctx, a, b, height, T)
	local cf, l = along(a, b)
	local len = l + T
	local h = height / 3
	for lv = 0, 2 do
		MapKit.part(ctx, { Name = "MazeWall", Size = Vector3.new(T + 0.6, h, len - (lv % 2) * 0.6), CFrame = cf * CFrame.new(0, h / 2 + lv * h, 0), Color = { 214, 178, 96 }, Material = "Grass" })
	end
	MapKit.part(ctx, { Name = "Snow", Size = Vector3.new(T + 1.4, 1.1, len + 0.4), CFrame = cf * CFrame.new(0, height + 0.4, 0), Color = { 246, 250, 255 }, Material = "Snow" })
	for i = 0, math.floor(len / 8) do
		local z = -len / 2 + 0.6 + i * 8
		for _, side in ipairs({ -1, 1 }) do
			MapKit.part(ctx, { Name = "Post", Size = Vector3.new(0.6, height + 0.6, 0.6), CFrame = cf * CFrame.new(side * (T / 2 + 0.6), (height + 0.6) / 2, z), Color = { 104, 66, 40 }, Material = "Wood" })
		end
	end
end

function MazeWalls.glass(ctx, a, b, height, T)
	local cf, l = along(a, b)
	local len = l + T
	local frame = if ctx.rng:NextNumber() < 0.5 then { 140, 210, 150 } else { 120, 180, 230 }
	MapKit.part(ctx, { Name = "MazeWall", Size = Vector3.new(T * 0.4, height, len), CFrame = cf * CFrame.new(0, height / 2, 0), Color = { 200, 230, 240 }, Material = "Glass", Transparency = 0.45 })
	for i = 0, math.floor(len / 4) do
		MapKit.part(ctx, { Name = "Frame", Size = Vector3.new(T * 0.6, height, 0.35), CFrame = cf * CFrame.new(0, height / 2, -len / 2 + i * 4), Color = frame, Material = "SmoothPlastic" })
	end
	for _, y in ipairs({ height * 0.5, height }) do
		MapKit.part(ctx, { Name = "Frame", Size = Vector3.new(T * 0.6, 0.35, len), CFrame = cf * CFrame.new(0, y, 0), Color = frame, Material = "SmoothPlastic" })
	end
	MapKit.part(ctx, { Name = "Shelf", Size = Vector3.new(T + 1.6, 3, len), CFrame = cf * CFrame.new(0, 1.5, 0), Color = { 176, 130, 84 }, Material = "WoodPlanks" }) -- solid up to the knee
	for i = 0, math.floor(len / 2.5) do
		if ctx.rng:NextNumber() < 0.6 then
			local side = if ctx.rng:NextNumber() < 0.5 then -1 else 1
			MapKit.part(ctx, { Name = "Pot", Shape = "Cylinder", Size = Vector3.new(1, 1, 1), CFrame = cf * CFrame.new(side * (T / 2 + 0.4), 3.5, -len / 2 + 1 + i * 2.5) * CFrame.Angles(0, 0, math.rad(90)), Color = { 196, 104, 60 }, Material = "Slate" })
			MapKit.part(ctx, { Name = "Plant", Shape = "Ball", Size = Vector3.new(1.1, 1, 1.1), CFrame = cf * CFrame.new(side * (T / 2 + 0.4), 4.3, -len / 2 + 1 + i * 2.5), Color = { 80, 160, 70 }, Material = "LeafyGrass", CanCollide = false })
		end
	end
end

function MazeWalls.reeds(ctx, a, b, height, T)
	local cf, l = along(a, b)
	local len = l + T
	MapKit.part(ctx, { Name = "MazeWall", Size = Vector3.new(T, height * 0.8, len), CFrame = cf * CFrame.new(0, height * 0.4, 0), Color = { 78, 130, 64 }, Material = "LeafyGrass" })
	for i = 0, math.floor(len / 1.1) do
		local h = height + ctx.rng:NextNumber(-1, 2.5)
		local x, z = ctx.rng:NextNumber(-0.8, 0.8), -len / 2 + 0.5 + i * 1.1
		local g = ctx.rng:NextInteger(120, 160)
		MapKit.part(ctx, { Name = "Reed", Size = Vector3.new(0.9, h - 0.45, 0.9), CFrame = cf * CFrame.new(x, (h - 0.45) / 2, z), Color = { 70, g, 60 }, Material = "SmoothPlastic", CanCollide = false })
		MapKit.part(ctx, { Name = "ReedTip", Shape = "Ball", Size = Vector3.new(0.9, 0.9, 0.9), CFrame = cf * CFrame.new(x, h - 0.45, z), Color = { 70, g, 60 }, Material = "SmoothPlastic", CanCollide = false })
	end
end

local STRIPES = { { 220, 60, 60 }, { 70, 130, 220 }, { 70, 170, 90 } }

function MazeWalls.stalls(ctx, a, b, height, T)
	local cf, l = along(a, b)
	local len = l + T
	MapKit.part(ctx, { Name = "MazeWall", Size = Vector3.new(T + 0.4, height, len), CFrame = cf * CFrame.new(0, height / 2, 0), Color = { 176, 160, 110 }, Material = "Plaster" })
	local n = math.max(1, math.floor(len / 6))
	for i = 0, n - 1 do -- an awning on one side or the other, white and a colour in stripes
		local z = -len / 2 + (i + 0.5) * len / n
		local side = if (i + math.floor(ctx.rng:NextNumber() * 2)) % 2 == 0 then -1 else 1
		local colour = STRIPES[ctx.rng:NextInteger(1, #STRIPES)]
		for k = 0, 3 do
			MapKit.part(ctx, { Name = "Awning", Size = Vector3.new(3, 0.3, len / n / 4), CFrame = cf * CFrame.new(side * (T / 2 + 1.4), height - 2, z - len / n / 2 + (k + 0.5) * len / n / 4) * CFrame.Angles(0, 0, math.rad(side * -18)), Color = if k % 2 == 0 then colour else { 250, 248, 240 }, Material = "Fabric", CanCollide = false })
		end
		if ctx.rng:NextNumber() < 0.6 then
			MapKit.part(ctx, { Name = "Produce", Size = Vector3.new(1.6, 1.2, 2.4), CFrame = cf * CFrame.new(side * (T / 2 + 1), 0.6, z), Color = { 150, 106, 64 }, Material = "WoodPlanks" })
			MapKit.part(ctx, { Name = "Veg", Size = Vector3.new(1.4, 0.5, 2.2), CFrame = cf * CFrame.new(side * (T / 2 + 1), 1.4, z), Color = if ctx.rng:NextNumber() < 0.5 then { 220, 60, 50 } else { 90, 170, 70 }, Material = "SmoothPlastic", CanCollide = false })
		end
	end
end

local CANDY = { { 245, 140, 190 }, { 120, 180, 240 }, { 250, 200, 90 }, { 240, 150, 90 }, { 180, 140, 230 } }

function MazeWalls.tents(ctx, a, b, height, T)
	local cf, l = along(a, b)
	local len = l + T
	local n = math.max(1, math.floor(len / 4.5))
	local s = len / n
	for i = 0, n - 1 do -- one tent or booth per step: a striped block with a peaked top
		local z = -len / 2 + (i + 0.5) * s
		local colour = CANDY[ctx.rng:NextInteger(1, #CANDY)]
		local h = height - 2.5
		MapKit.part(ctx, { Name = "MazeWall", Size = Vector3.new(T + 2, h, s), CFrame = cf * CFrame.new(0, h / 2, z), Color = colour, Material = "Fabric" })
		MapKit.part(ctx, { Name = "Stripe", Size = Vector3.new(T + 2.06, h, s * 0.3), CFrame = cf * CFrame.new(0, h / 2, z), Color = { 252, 250, 246 }, Material = "Fabric" })
		local roof = MapKit.part(ctx, { Name = "Roof", Size = Vector3.new(s * 0.9, 2.6, T + 2.4), CFrame = cf * CFrame.new(0, h + 1.3, z) * CFrame.Angles(0, math.rad(90), 0), Color = colour, Material = "Fabric" })
		roof.Shape = Enum.PartType.Wedge
		MapKit.part(ctx, { Name = "MazeWall", Size = Vector3.new(T, 2.5, s), CFrame = cf * CFrame.new(0, h + 1.25, z), Transparency = 1 }) -- keeps the wall full height
		MapKit.part(ctx, { Name = "Flag", Size = Vector3.new(0.15, 1.6, 0.15), CFrame = cf * CFrame.new(0, h + 3.4, z), Color = { 120, 90, 60 }, Material = "Wood", CanCollide = false })
		MapKit.part(ctx, { Name = "Pennant", Size = Vector3.new(0.1, 0.6, 0.9), CFrame = cf * CFrame.new(0, h + 3.9, z + 0.5), Color = CANDY[ctx.rng:NextInteger(1, #CANDY)], Material = "Fabric", CanCollide = false })
	end
end

return MazeWalls

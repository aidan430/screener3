-- More maze wall styles (server/MazeKit uses these when a map asks for one; it has its own
-- hedge, thicket, bales, planks and crates). Each builds one wall from a to b (both on the floor),
-- `height` tall and T studs thick, always taller than a jump:
--   vines       twisting green vines with leafy lumps (Pumpkin Patch)
--   corn        tall golden corn stalks with ears and tassels (Harvest Corn Maze)
--   sunflowers  green stalks topped with big sunflower heads (Sunflower Labyrinth)
--   stone       a dry-stone wall of grey blocks with a hedge on top (Windmill Hill)
--   stonehedge  stone or hedge, picked wall by wall (Windmill Hill's mix)
local MapKit = require(script.Parent.MapKit)

local MazeWalls = {}

local function along(a, b)
	local mid = (a + b) / 2
	return CFrame.lookAt(mid, mid + (b - a)), (b - a).Magnitude
end

function MazeWalls.vines(ctx, a, b, height, T)
	local cf, l = along(a, b)
	local len = l + T
	MapKit.part(ctx, { Name = "MazeWall", Size = Vector3.new(T, height, len), CFrame = cf * CFrame.new(0, height / 2, 0), Color = { 52, 120, 48 }, Material = "LeafyGrass" })
	for i = 0, math.floor(len / 3.2) do -- lumpy leaves and twisting vines over it
		local z = -len / 2 + 1.2 + i * 3.2
		local s = ctx.rng:NextNumber(2.2, 3.2)
		MapKit.part(ctx, { Name = "Leaves", Shape = "Ball", Size = Vector3.one * s, CFrame = cf * CFrame.new(ctx.rng:NextNumber(-0.4, 0.4), height - 0.4 + ctx.rng:NextNumber(-0.3, 0.4), z), Color = { 70, 150, 58 }, Material = "LeafyGrass", CanCollide = false })
		for _, side in ipairs({ -1, 1 }) do
			if ctx.rng:NextNumber() < 0.6 then
				MapKit.part(ctx, { Name = "Vine", Shape = "Cylinder", Size = Vector3.new(height * 0.9, 0.5, 0.5), CFrame = cf * CFrame.new(side * (T / 2 + 0.15), height / 2, z) * CFrame.Angles(0, 0, math.rad(90 + ctx.rng:NextNumber(-25, 25))), Color = { 40, 104, 40 }, Material = "Grass", CanCollide = false, CanQuery = false })
			end
		end
	end
end

function MazeWalls.corn(ctx, a, b, height, T)
	local cf, l = along(a, b)
	local len = l + T
	MapKit.part(ctx, { Name = "MazeWall", Size = Vector3.new(T * 0.8, height * 0.85, len), CFrame = cf * CFrame.new(0, height * 0.425, 0), Color = { 196, 168, 70 }, Material = "Grass" })
	for i = 0, math.floor(len / 1.4) do -- stalks, each with leaves, a cob and a tassel
		local z = -len / 2 + 0.5 + i * 1.4
		local x = ctx.rng:NextNumber(-0.6, 0.6)
		local h = height + ctx.rng:NextNumber(0.5, 2)
		MapKit.part(ctx, { Name = "Stalk", Size = Vector3.new(0.35, h, 0.35), CFrame = cf * CFrame.new(x, h / 2, z), Color = { 214, 186, 82 }, Material = "Grass", CanCollide = false, CanQuery = false })
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
			MapKit.part(ctx, { Name = "MazeWall", Size = Vector3.new(T + 0.6, stoneH / 2, s - 0.08), CFrame = cf * CFrame.new(0, stoneH / 4 + row * stoneH / 2, z) * CFrame.Angles(0, ctx.rng:NextNumber(-0.04, 0.04), 0), Color = { shade, shade, shade + 6 }, Material = "Slate" })
		end
	end
	MapKit.part(ctx, { Name = "MazeWall", Size = Vector3.new(T, height - stoneH, len), CFrame = cf * CFrame.new(0, stoneH + (height - stoneH) / 2, 0), Color = { 66, 128, 56 }, Material = "LeafyGrass" })
end

function MazeWalls.stonehedge(ctx, a, b, height, T)
	if ctx.rng:NextNumber() < 0.5 then
		MazeWalls.stone(ctx, a, b, height, T)
	else
		local cf, l = along(a, b)
		MapKit.part(ctx, { Name = "MazeWall", Size = Vector3.new(T, height, l + T), CFrame = cf * CFrame.new(0, height / 2, 0), Color = { 62, 124, 54 }, Material = "LeafyGrass" })
	end
end

return MazeWalls

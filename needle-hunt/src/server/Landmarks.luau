-- Climbable landmarks for a big map (server/MapsBig). Each is a challenge to reach, and returns the
-- top where a chest can stand (server/ChestSpawner puts chests on ctx.landmarks):
--   silo        a ladder (a climbable truss) up the side to a catwalk on top
--   lookout     a tall tower reached by jumping up stepping posts round it
--   barnLoft    a barn whose loft you reach by jumping up stacked bales inside
--   windmill    a balcony round the windmill, reached by jumping stones spiralling up
--   waterTower  a ladder up a leg to the deck on top
--   hayTower    the tallest: big bales spiralling up round a pole (the Golden Chest's)
-- Jumps are a little apart and a little up (Roblox's jump: about 7 up, 12 across at a run), so each
-- takes care but no tricks. Positions are map-local (x, z on the floor), as MapKit.at.
local MapKit = require(script.Parent.MapKit)
local FarmProps = require(script.Parent.FarmProps)

local Landmarks = {}
local WOOD, DARK = { 150, 104, 62 }, { 104, 70, 42 }

local function part(ctx, props)
	return MapKit.part(ctx, props)
end

local function block(ctx, size, x, y, z, colour, material) -- a box whose top is at y
	return part(ctx, { Name = "Climb", Size = size, CFrame = CFrame.new(MapKit.at(ctx, x, y - size.Y / 2, z)), Color = colour or WOOD, Material = material or "WoodPlanks" })
end

local function top(ctx, x, y, z)
	return MapKit.at(ctx, x, y, z)
end

-- A climbable ladder: a TrussPart from the floor to `h` (Roblox lets you climb a truss).
local function ladder(ctx, x, z, h)
	local t = Instance.new("TrussPart")
	t.Name, t.Anchored, t.Size = "Ladder", true, Vector3.new(2, math.ceil(h / 2) * 2, 2)
	t.CFrame, t.Color, t.Material = CFrame.new(MapKit.at(ctx, x, t.Size.Y / 2, z)), Color3.fromRGB(110, 76, 46), Enum.Material.Wood
	t.Parent = ctx.model
	return t
end

-- Jumping stones spiralling up round (x, z): from about 2.5 up to `h`, `r` out.
local function spiral(ctx, x, z, r, h, size, colour, material)
	local n = math.ceil(h / 2.4)
	local a0 = ctx.rng:NextNumber() * math.pi * 2
	for i = 1, n do
		local a = a0 + i * 0.62
		block(ctx, Vector3.new(size, 1, size), x + math.cos(a) * r, h * i / n - 0.1, z + math.sin(a) * r, colour, material)
	end
	return a0 + n * 0.62
end

function Landmarks.silo(ctx, x, z)
	local h = 24
	local tube = part(ctx, { Name = "Silo", Shape = "Cylinder", Size = Vector3.new(h, 9, 9), CFrame = CFrame.new(MapKit.at(ctx, x, h / 2, z)) * CFrame.Angles(0, 0, math.rad(90)), Color = { 196, 50, 44 }, Material = "Metal" })
	for i = 1, 3 do
		part(ctx, { Name = "Band", Shape = "Cylinder", Size = Vector3.new(0.4, 9.2, 9.2), CFrame = CFrame.new(MapKit.at(ctx, x, i * h / 4, z)) * CFrame.Angles(0, 0, math.rad(90)), Color = { 230, 230, 230 }, Material = "Metal" })
	end
	block(ctx, Vector3.new(12, 1, 12), x, h + 0.6, z, { 120, 124, 130 }, "DiamondPlate") -- the catwalk on top
	for _, s in ipairs({ { 0, 6 }, { 0, -6 }, { -6, 0 } }) do -- a rail round it (open where the ladder comes up)
		part(ctx, { Name = "Rail", Size = Vector3.new(if s[1] == 0 then 12 else 0.4, 1.2, if s[1] == 0 then 0.4 else 12), CFrame = CFrame.new(MapKit.at(ctx, x + s[1], h + 1.2, z + s[2])), Color = { 90, 94, 100 }, Material = "Metal" })
	end
	ladder(ctx, x + 6.2, z + 2, h + 0.6)
	MapKit.spotsOn(ctx, tube, 0, 3)
	return top(ctx, x - 2, h + 0.6, z - 2)
end

function Landmarks.lookout(ctx, x, z)
	local h = 15
	for _, l in ipairs({ { -3, -3 }, { 3, -3 }, { -3, 3 }, { 3, 3 } }) do
		part(ctx, { Name = "Leg", Size = Vector3.new(1, h + 5, 1), CFrame = CFrame.new(MapKit.at(ctx, x + l[1], (h + 5) / 2, z + l[2])), Color = DARK, Material = "Wood" })
	end
	block(ctx, Vector3.new(8, 1, 8), x, h, z)
	part(ctx, { Name = "Roof", Size = Vector3.new(9, 0.6, 9), CFrame = CFrame.new(MapKit.at(ctx, x, h + 5, z)), Color = { 150, 74, 50 }, Material = "WoodPlanks" })
	spiral(ctx, x, z, 8.5, h - 2.2, 3, WOOD, "WoodPlanks") -- posts up round it, then a jump onto the deck
	return top(ctx, x, h, z)
end

function Landmarks.barnLoft(ctx, x, z)
	local W, D, H, loftY = 26, 18, 16, 10
	local red = { 170, 60, 50 }
	for _, w in ipairs({ { 0, D / 2, W, 1 }, { -W / 2, 0, 1, D }, { W / 2, 0, 1, D } }) do
		MapKit.wall(ctx, CFrame.new(MapKit.at(ctx, x + w[1], H / 2, z + w[2])), Vector3.new(w[3], H, w[4]), red, "WoodPlanks")
	end
	for _, side in ipairs({ -1, 1 }) do -- the front, with a wide doorway in the middle
		MapKit.wall(ctx, CFrame.new(MapKit.at(ctx, x + side * (W / 4 + 2), H / 2, z - D / 2)), Vector3.new(W / 2 - 4, H, 1), red, "WoodPlanks")
	end
	MapKit.wall(ctx, CFrame.new(MapKit.at(ctx, x, H - 2, z - D / 2)), Vector3.new(8, 4, 1), red, "WoodPlanks")
	part(ctx, { Name = "Roof", Size = Vector3.new(W + 2, 1, D + 2), CFrame = CFrame.new(MapKit.at(ctx, x, H + 0.5, z)), Color = { 90, 70, 60 }, Material = "Slate" })
	block(ctx, Vector3.new(W - 2, 1, D / 2), x, loftY, z + D / 4) -- the loft, across the back half
	for i, b in ipairs({ { -8, -4, 2.5 }, { -3, -6, 5 }, { 2, -4, 7.5 } }) do -- bales stacked up to it
		for lv = 1, i do
			MapKit.bale(ctx, x + b[1], (lv - 1) * 2.5, z + b[2], 0)
		end
	end
	return top(ctx, x + 6, loftY, z + D / 4)
end

function Landmarks.windmill(ctx, x, z)
	FarmProps.windmill(ctx, x, z)
	local h = 12
	part(ctx, { Name = "Balcony", Shape = "Cylinder", Size = Vector3.new(1, 15, 15), CFrame = CFrame.new(MapKit.at(ctx, x, h - 0.5, z)) * CFrame.Angles(0, 0, math.rad(90)), Color = WOOD, Material = "WoodPlanks" })
	spiral(ctx, x, z, 10, h - 2.2, 3, { 170, 168, 160 }, "Slate")
	return top(ctx, x + 6, h, z)
end

function Landmarks.waterTower(ctx, x, z)
	local h = 14
	for _, l in ipairs({ { -2.5, -2.5 }, { 2.5, -2.5 }, { -2.5, 2.5 }, { 2.5, 2.5 } }) do
		part(ctx, { Name = "Leg", Size = Vector3.new(0.8, h, 0.8), CFrame = CFrame.new(MapKit.at(ctx, x + l[1], h / 2, z + l[2])), Color = DARK, Material = "Wood" })
	end
	part(ctx, { Name = "Tank", Shape = "Cylinder", Size = Vector3.new(6, 8, 8), CFrame = CFrame.new(MapKit.at(ctx, x, h + 3, z)) * CFrame.Angles(0, 0, math.rad(90)), Color = WOOD, Material = "WoodPlanks" })
	block(ctx, Vector3.new(9, 1, 9), x, h + 6.5, z, DARK)
	ladder(ctx, x + 4.6, z, h + 6.5)
	return top(ctx, x - 1.5, h + 6.5, z)
end

-- The Hay Tower in the middle of the map: big bales spiralling up round a pole to a deck on top.
function Landmarks.hayTower(ctx, x, z)
	local h = 26
	part(ctx, { Name = "Pole", Shape = "Cylinder", Size = Vector3.new(h + 6, 3, 3), CFrame = CFrame.new(MapKit.at(ctx, x, (h + 6) / 2, z)) * CFrame.Angles(0, 0, math.rad(90)), Color = DARK, Material = "Wood" })
	local n = math.ceil(h / 2.4)
	for i = 1, n do
		local a = i * 0.7
		local y = h * i / n
		part(ctx, { Name = "Climb", Size = Vector3.new(5, 2.5, 4), CFrame = CFrame.new(MapKit.at(ctx, x + math.cos(a) * 7, y - 1.25, z + math.sin(a) * 7)) * CFrame.Angles(0, -a, 0), Color = ctx.def.straw, Material = "Grass" })
	end
	block(ctx, Vector3.new(10, 1, 10), x, h + 0.5, z, WOOD)
	part(ctx, { Name = "Flag", Size = Vector3.new(0.2, 3, 4), CFrame = CFrame.new(MapKit.at(ctx, x, h + 7, z + 2)), Color = { 255, 205, 70 }, Material = "Fabric", CanCollide = false })
	return top(ctx, x, h + 0.5, z)
end

return Landmarks

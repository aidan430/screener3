-- Farm props for the maps from the owner's Gemini sheets (server/MapsC): pumpkins, scarecrows,
-- carts, a silo, crows on posts, picnic blankets, a lookout tower, apple trees and crates, a cider
-- press, ladders, a windmill with turning sails and flour sacks. Positions are map-local (x, z on
-- the floor, as MapKit.at); each returns its main part. Big props add hiding spots round their foot.
local TweenService = game:GetService("TweenService")

local MapKit = require(script.Parent.MapKit)

local FarmProps = {}
local WOOD, DARK = { 150, 104, 62 }, { 104, 70, 42 }

local function p(ctx, props)
	return MapKit.part(ctx, props)
end

function FarmProps.pumpkin(ctx, x, z, size)
	size = size or ctx.rng:NextNumber(1.6, 3.4)
	local body = p(ctx, { Name = "Pumpkin", Shape = "Ball", Size = Vector3.new(size * 1.25, size, size * 1.25), CFrame = CFrame.new(MapKit.at(ctx, x, size * 0.45, z)), Color = { 240, 130, 30 }, Material = "SmoothPlastic" })
	p(ctx, { Name = "Stem", Size = Vector3.new(0.3, 0.6, 0.3) * math.max(1, size / 2), CFrame = body.CFrame * CFrame.new(0, size * 0.52, 0) * CFrame.Angles(0, 0, 0.3), Color = { 90, 120, 40 }, Material = "Wood", CanCollide = false })
	return body
end

-- A patch of pumpkins round a point, some big.
function FarmProps.patch(ctx, x, z, n, spread)
	for _ = 1, n do
		FarmProps.pumpkin(ctx, x + ctx.rng:NextNumber(-spread, spread), z + ctx.rng:NextNumber(-spread, spread))
	end
	MapKit.spot(ctx, MapKit.at(ctx, x + spread + 1, 0, z))
end

function FarmProps.scarecrow(ctx, x, z, shirt)
	local base = CFrame.new(MapKit.at(ctx, x, 0, z)) * CFrame.Angles(0, ctx.rng:NextNumber() * math.pi * 2, 0)
	local pole = p(ctx, { Name = "Pole", Size = Vector3.new(0.5, 7, 0.5), CFrame = base * CFrame.new(0, 3.5, 0), Color = DARK, Material = "Wood" })
	p(ctx, { Name = "Arms", Size = Vector3.new(5, 0.4, 0.4), CFrame = base * CFrame.new(0, 5, 0), Color = DARK, Material = "Wood" })
	p(ctx, { Name = "Shirt", Size = Vector3.new(2.2, 2.4, 1.2), CFrame = base * CFrame.new(0, 4.6, 0), Color = shirt or { 60, 110, 170 }, Material = "Fabric" })
	p(ctx, { Name = "Head", Shape = "Ball", Size = Vector3.one * 1.6, CFrame = base * CFrame.new(0, 6.6, 0), Color = { 226, 196, 130 }, Material = "Fabric" })
	p(ctx, { Name = "Hat", Shape = "Cylinder", Size = Vector3.new(0.25, 2.6, 2.6), CFrame = base * CFrame.new(0, 7.4, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = { 200, 160, 80 }, Material = "Fabric" })
	p(ctx, { Name = "HatTop", Shape = "Cylinder", Size = Vector3.new(0.9, 1.4, 1.4), CFrame = base * CFrame.new(0, 7.9, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = { 200, 160, 80 }, Material = "Fabric" })
	MapKit.spot(ctx, MapKit.at(ctx, x + 1.4, 0, z))
	return pole
end

-- A wooden cart, its load pumpkins, hay or apples.
function FarmProps.cart(ctx, x, z, load)
	local base = CFrame.new(MapKit.at(ctx, x, 0, z)) * CFrame.Angles(0, ctx.rng:NextNumber() * math.pi * 2, 0)
	local bed = p(ctx, { Name = "Cart", Size = Vector3.new(6, 1.6, 3.6), CFrame = base * CFrame.new(0, 2.2, 0), Color = WOOD, Material = "WoodPlanks" })
	for _, w in ipairs({ { -1.8, -2.1 }, { -1.8, 2.1 }, { 1.8, -2.1 }, { 1.8, 2.1 } }) do
		p(ctx, { Name = "Wheel", Shape = "Cylinder", Size = Vector3.new(0.4, 2.6, 2.6), CFrame = base * CFrame.new(w[1], 1.3, w[2]) * CFrame.Angles(0, math.rad(90), 0), Color = DARK, Material = "Wood" })
	end
	p(ctx, { Name = "Handle", Size = Vector3.new(4, 0.3, 0.3), CFrame = base * CFrame.new(4.6, 1.6, 0) * CFrame.Angles(0, 0, math.rad(-15)), Color = DARK, Material = "Wood", CanCollide = false })
	for i = 1, 5 do
		local o = base * CFrame.new(ctx.rng:NextNumber(-2.2, 2.2), 3.4, ctx.rng:NextNumber(-1.2, 1.2))
		if load == "hay" then
			p(ctx, { Name = "Load", Size = Vector3.new(2.4, 1.4, 1.6), CFrame = o * CFrame.Angles(0, i, 0), Color = ctx.def.straw, Material = "Grass" })
		else
			local apple = load == "apples"
			p(ctx, { Name = "Load", Shape = "Ball", Size = Vector3.one * (if apple then 0.9 else 1.6), CFrame = o, Color = if apple then { 210, 40, 40 } else { 240, 130, 30 }, Material = "SmoothPlastic" })
		end
	end
	MapKit.spotsOn(ctx, bed, 1, 2)
	return bed
end

function FarmProps.silo(ctx, x, z, h)
	h = h or 22
	local tube = p(ctx, { Name = "Silo", Shape = "Cylinder", Size = Vector3.new(h, 9, 9), CFrame = CFrame.new(MapKit.at(ctx, x, h / 2, z)) * CFrame.Angles(0, 0, math.rad(90)), Color = { 196, 50, 44 }, Material = "Metal" })
	for i = 1, 3 do
		p(ctx, { Name = "Band", Shape = "Cylinder", Size = Vector3.new(0.4, 9.2, 9.2), CFrame = CFrame.new(MapKit.at(ctx, x, i * h / 4, z)) * CFrame.Angles(0, 0, math.rad(90)), Color = { 230, 230, 230 }, Material = "Metal" })
	end
	p(ctx, { Name = "Dome", Shape = "Ball", Size = Vector3.one * 9, CFrame = CFrame.new(MapKit.at(ctx, x, h, z)), Color = { 210, 210, 214 }, Material = "Metal" })
	MapKit.spotsOn(ctx, tube, 0, 4)
	return tube
end

function FarmProps.crowPost(ctx, x, z)
	local post = p(ctx, { Name = "Post", Size = Vector3.new(0.7, 6, 0.7), CFrame = CFrame.new(MapKit.at(ctx, x, 3, z)), Color = DARK, Material = "Wood" })
	p(ctx, { Name = "Crow", Shape = "Ball", Size = Vector3.new(1.2, 1, 1.6), CFrame = CFrame.new(MapKit.at(ctx, x, 6.5, z)), Color = { 28, 28, 34 }, Material = "SmoothPlastic", CanCollide = false })
	p(ctx, { Name = "Beak", Size = Vector3.new(0.3, 0.25, 0.5), CFrame = CFrame.new(MapKit.at(ctx, x, 6.7, z - 0.9)), Color = { 240, 180, 40 }, Material = "SmoothPlastic", CanCollide = false })
	return post
end

function FarmProps.picnic(ctx, x, z, colour)
	local cloth = p(ctx, { Name = "Picnic", Size = Vector3.new(6, 0.12, 6), CFrame = CFrame.new(MapKit.at(ctx, x, 0.06, z)) * CFrame.Angles(0, ctx.rng:NextNumber() * 1.5, 0), Color = colour or { 220, 70, 80 }, Material = "Fabric", CanCollide = false })
	for i = 0, 2 do -- checks
		p(ctx, { Name = "Check", Size = Vector3.new(6, 0.14, 0.9), CFrame = cloth.CFrame * CFrame.new(0, 0.01, -2 + i * 2), Color = { 250, 245, 240 }, Material = "Fabric", CanCollide = false })
	end
	p(ctx, { Name = "Basket", Size = Vector3.new(1.6, 1.1, 1.1), CFrame = cloth.CFrame * CFrame.new(1.4, 0.6, 1.2), Color = { 180, 130, 70 }, Material = "Fabric" })
	MapKit.spot(ctx, (cloth.CFrame * CFrame.new(-1.2, 0.1, -1)).Position)
	return cloth
end

-- A lookout tower: four legs, a deck `h` up with a rail, and steps round one side.
function FarmProps.tower(ctx, x, z, h)
	h = h or 9
	for _, l in ipairs({ { -2.6, -2.6 }, { 2.6, -2.6 }, { -2.6, 2.6 }, { 2.6, 2.6 } }) do
		p(ctx, { Name = "Leg", Size = Vector3.new(0.8, h + 4, 0.8), CFrame = CFrame.new(MapKit.at(ctx, x + l[1], (h + 4) / 2, z + l[2])), Color = DARK, Material = "Wood" })
	end
	local deck = p(ctx, { Name = "Deck", Size = Vector3.new(7, 0.8, 7), CFrame = CFrame.new(MapKit.at(ctx, x, h, z)), Color = WOOD, Material = "WoodPlanks" })
	p(ctx, { Name = "Roof", Size = Vector3.new(8, 0.6, 8), CFrame = CFrame.new(MapKit.at(ctx, x, h + 4.2, z)), Color = { 150, 74, 50 }, Material = "WoodPlanks" })
	for i = 1, math.floor(h / 1.2) do -- steps up the south side
		p(ctx, { Name = "Step", Size = Vector3.new(3, 0.5, 1.4), CFrame = CFrame.new(MapKit.at(ctx, x - 1.5 + 0, i * 1.2 - 0.3, z + 3.5 + h - i * 1.2)), Color = WOOD, Material = "WoodPlanks" })
	end
	MapKit.spotsOn(ctx, deck, 1, 0, true)
	return deck
end

function FarmProps.appleTree(ctx, x, z)
	MapKit.tree(ctx, x, z, ctx.rng:NextNumber(9, 12), { 70, 140, 60 })
	for _ = 1, 6 do
		local a, r = ctx.rng:NextNumber() * math.pi * 2, ctx.rng:NextNumber(2, 3.4)
		p(ctx, { Name = "Apple", Shape = "Ball", Size = Vector3.one * 0.8, CFrame = CFrame.new(MapKit.at(ctx, x + math.cos(a) * r, ctx.rng:NextNumber(8, 11), z + math.sin(a) * r)), Color = { 214, 40, 40 }, Material = "SmoothPlastic", CanCollide = false })
	end
end

function FarmProps.appleCrates(ctx, x, z)
	for i = 0, ctx.rng:NextInteger(1, 3) do
		local c = MapKit.crate(ctx, x + (i % 2) * 2.8, if i >= 2 then 2.5 else 0, z, 2.5)
		for _ = 1, 3 do
			p(ctx, { Name = "Apple", Shape = "Ball", Size = Vector3.one * 0.7, CFrame = c.CFrame * CFrame.new(ctx.rng:NextNumber(-0.7, 0.7), 1.35, ctx.rng:NextNumber(-0.7, 0.7)), Color = { 214, 40, 40 }, Material = "SmoothPlastic", CanCollide = false })
		end
	end
end

function FarmProps.ciderPress(ctx, x, z)
	local barrel = p(ctx, { Name = "Barrel", Shape = "Cylinder", Size = Vector3.new(4, 4.4, 4.4), CFrame = CFrame.new(MapKit.at(ctx, x, 2, z)) * CFrame.Angles(0, 0, math.rad(90)), Color = { 150, 96, 52 }, Material = "WoodPlanks" })
	for _, dx in ipairs({ -2.8, 2.8 }) do
		p(ctx, { Name = "Frame", Size = Vector3.new(0.8, 8, 0.8), CFrame = CFrame.new(MapKit.at(ctx, x + dx, 4, z)), Color = DARK, Material = "Wood" })
	end
	p(ctx, { Name = "Beam", Size = Vector3.new(6.4, 0.9, 0.9), CFrame = CFrame.new(MapKit.at(ctx, x, 7.6, z)), Color = DARK, Material = "Wood" })
	p(ctx, { Name = "Screw", Size = Vector3.new(0.5, 3, 0.5), CFrame = CFrame.new(MapKit.at(ctx, x, 5.6, z)), Color = { 90, 90, 96 }, Material = "Metal" })
	MapKit.spotsOn(ctx, barrel, 0, 3)
	return barrel
end

function FarmProps.ladder(ctx, cf, h)
	for _, dx in ipairs({ -0.9, 0.9 }) do
		p(ctx, { Name = "Rail", Size = Vector3.new(0.25, h, 0.25), CFrame = cf * CFrame.new(dx, h / 2, 0), Color = WOOD, Material = "Wood", CanCollide = false })
	end
	for i = 1, math.floor(h / 1.1) do
		p(ctx, { Name = "Rung", Size = Vector3.new(1.8, 0.2, 0.2), CFrame = cf * CFrame.new(0, i * 1.1, 0), Color = WOOD, Material = "Wood", CanCollide = false })
	end
end

-- A windmill: a stone tower, a wooden cap and four sails that turn slowly.
function FarmProps.windmill(ctx, x, z)
	local tower = p(ctx, { Name = "Windmill", Shape = "Cylinder", Size = Vector3.new(14, 9, 9), CFrame = CFrame.new(MapKit.at(ctx, x, 7, z)) * CFrame.Angles(0, 0, math.rad(90)), Color = { 170, 168, 160 }, Material = "Slate" })
	p(ctx, { Name = "Cap", Size = Vector3.new(8, 6, 8), CFrame = CFrame.new(MapKit.at(ctx, x, 17, z)), Color = WOOD, Material = "WoodPlanks" })
	p(ctx, { Name = "Roof", Size = Vector3.new(8.6, 1, 8.6), CFrame = CFrame.new(MapKit.at(ctx, x, 20.4, z)), Color = { 150, 74, 50 }, Material = "Slate" })
	local hub = p(ctx, { Name = "Hub", Shape = "Cylinder", Size = Vector3.new(1.5, 2, 2), CFrame = CFrame.new(MapKit.at(ctx, x, 17, z - 4.6)) * CFrame.Angles(0, math.rad(90), 0), Color = DARK, Material = "Wood", CanCollide = false })
	for k = 0, 3 do
		local sail = p(ctx, { Name = "Sail", Size = Vector3.new(2.6, 11, 0.3), CFrame = hub.CFrame * CFrame.Angles(math.rad(k * 90), 0, 0) * CFrame.new(-0.4, 6, 0) * CFrame.Angles(0, math.rad(90), 0), Color = { 236, 226, 200 }, Material = "Fabric", CanCollide = false, CanQuery = false, Anchored = false })
		local weld = Instance.new("WeldConstraint")
		weld.Part0, weld.Part1, weld.Parent = hub, sail, sail
	end
	MapKit.spin(hub, 12)
	MapKit.spotsOn(ctx, tower, 0, 5)
	return tower
end

function FarmProps.flourSack(ctx, x, z)
	local sack = p(ctx, { Name = "Sack", Size = Vector3.new(1.8, 2.2, 1.4), CFrame = CFrame.new(MapKit.at(ctx, x, 1.1, z)) * CFrame.Angles(0, ctx.rng:NextNumber() * 3, 0), Color = { 214, 192, 150 }, Material = "Fabric" })
	p(ctx, { Name = "Flour", Shape = "Ball", Size = Vector3.new(1.5, 0.7, 1.1), CFrame = sack.CFrame * CFrame.new(0, 1.15, 0), Color = { 248, 246, 240 }, Material = "Sand", CanCollide = false })
	return sack
end

return FarmProps

-- More props for the maps from the Gemini sheets (server/MapsD): a snowy barn, snowy pines, a
-- frozen pond, a snowman, a sled, a water tower; a glass dome, potting benches, watering cans,
-- puddles, a lily pond; a boathouse and ducks; a well and bunting; a Ferris wheel and a carousel
-- that turn, balloon bunches and prize booths. Positions are map-local (x, z), as MapKit.at.
local TweenService = game:GetService("TweenService")

local MapKit = require(script.Parent.MapKit)

local FarmProps2 = {}
local WOOD, DARK = { 150, 104, 62 }, { 104, 70, 42 }
local CANDY = { { 245, 140, 190 }, { 120, 180, 240 }, { 250, 200, 90 }, { 240, 150, 90 }, { 180, 140, 230 } }

local function p(ctx, props)
	return MapKit.part(ctx, props)
end

local spin = MapKit.spin -- turns forever, slowly (anything welded to it turns too)

local function weld(hub, part)
	part.Anchored = false
	local w = Instance.new("WeldConstraint")
	w.Part0, w.Part1, w.Parent = hub, part, part
end

function FarmProps2.barn(ctx, x, z, snowy)
	local body = p(ctx, { Name = "Barn", Size = Vector3.new(14, 10, 11), CFrame = CFrame.new(MapKit.at(ctx, x, 5, z)), Color = { 170, 60, 50 }, Material = "WoodPlanks" })
	for _, side in ipairs({ -1, 1 }) do
		p(ctx, { Name = "Roof", Size = Vector3.new(15, 0.8, 7.4), CFrame = CFrame.new(MapKit.at(ctx, x, 12, z + side * 3)) * CFrame.Angles(math.rad(side * 32), 0, 0), Color = if snowy then { 244, 248, 255 } else { 90, 70, 60 }, Material = if snowy then "Snow" else "Slate" })
	end
	p(ctx, { Name = "Door", Size = Vector3.new(4, 6, 0.3), CFrame = CFrame.new(MapKit.at(ctx, x, 3, z - 5.6)), Color = { 240, 236, 226 }, Material = "WoodPlanks" })
	MapKit.spotsOn(ctx, body, 0, 4)
	return body
end

function FarmProps2.pine(ctx, x, z, snowy)
	p(ctx, { Name = "Trunk", Size = Vector3.new(1.2, 3, 1.2), CFrame = CFrame.new(MapKit.at(ctx, x, 1.5, z)), Color = DARK, Material = "Wood" })
	for i = 0, 2 do
		local w = 7 - i * 2
		p(ctx, { Name = "Pine", Shape = "Ball", Size = Vector3.new(w, 3.4, w), CFrame = CFrame.new(MapKit.at(ctx, x, 4 + i * 2.6, z)), Color = if snowy and i == 2 then { 240, 246, 252 } else { 50, 104, 70 }, Material = if snowy and i == 2 then "Snow" else "LeafyGrass" })
	end
end

function FarmProps2.pond(ctx, x, z, r, frozen)
	local pond = p(ctx, { Name = "Pond", Shape = "Cylinder", Size = Vector3.new(0.3, r * 2, r * 2), CFrame = CFrame.new(MapKit.at(ctx, x, 0.12, z)) * CFrame.Angles(0, 0, math.rad(90)), Color = if frozen then { 170, 220, 245 } else { 80, 160, 210 }, Material = if frozen then "Ice" else "Glass", Transparency = if frozen then 0 else 0.15 })
	p(ctx, { Name = "Bank", Shape = "Cylinder", Size = Vector3.new(0.24, r * 2 + 2, r * 2 + 2), CFrame = CFrame.new(MapKit.at(ctx, x, 0.08, z)) * CFrame.Angles(0, 0, math.rad(90)), Color = if frozen then { 246, 250, 255 } else { 120, 96, 70 }, Material = if frozen then "Snow" else "Mud", CanCollide = false })
	if not frozen then
		for _ = 1, math.floor(r * 1.2) do -- lily pads
			local a, d = ctx.rng:NextNumber() * math.pi * 2, ctx.rng:NextNumber(0.5, r - 1)
			p(ctx, { Name = "Lily", Shape = "Cylinder", Size = Vector3.new(0.1, 1.6, 1.6), CFrame = CFrame.new(MapKit.at(ctx, x + math.cos(a) * d, 0.3, z + math.sin(a) * d)) * CFrame.Angles(0, 0, math.rad(90)), Color = { 70, 160, 70 }, Material = "SmoothPlastic", CanCollide = false })
		end
	end
	MapKit.spot(ctx, MapKit.at(ctx, x + r + 1.6, 0, z))
	return pond
end

function FarmProps2.snowman(ctx, x, z)
	for i, s in ipairs({ 3.2, 2.4, 1.7 }) do
		p(ctx, { Name = "Snowman", Shape = "Ball", Size = Vector3.one * s, CFrame = CFrame.new(MapKit.at(ctx, x, ({ 1.5, 3.9, 5.8 })[i], z)), Color = { 248, 250, 255 }, Material = "Snow" })
	end
	p(ctx, { Name = "Nose", Size = Vector3.new(0.3, 0.3, 0.9), CFrame = CFrame.new(MapKit.at(ctx, x, 5.8, z - 1)), Color = { 250, 140, 40 }, Material = "SmoothPlastic", CanCollide = false })
	p(ctx, { Name = "Scarf", Shape = "Cylinder", Size = Vector3.new(0.5, 2.2, 2.2), CFrame = CFrame.new(MapKit.at(ctx, x, 4.9, z)) * CFrame.Angles(0, 0, math.rad(90)), Color = { 210, 50, 60 }, Material = "Fabric", CanCollide = false })
end

function FarmProps2.sled(ctx, x, z)
	local seat = p(ctx, { Name = "Sled", Size = Vector3.new(2, 0.4, 4), CFrame = CFrame.new(MapKit.at(ctx, x, 0.9, z)) * CFrame.Angles(0, ctx.rng:NextNumber() * 3, 0), Color = { 196, 50, 44 }, Material = "WoodPlanks" })
	for _, dx in ipairs({ -0.8, 0.8 }) do
		p(ctx, { Name = "Runner", Size = Vector3.new(0.2, 0.3, 4.4), CFrame = seat.CFrame * CFrame.new(dx, -0.5, 0.1), Color = { 80, 80, 90 }, Material = "Metal" })
	end
end

function FarmProps2.waterTower(ctx, x, z, snowy)
	for _, l in ipairs({ { -1.8, -1.8 }, { 1.8, -1.8 }, { -1.8, 1.8 }, { 1.8, 1.8 } }) do
		p(ctx, { Name = "Leg", Size = Vector3.new(0.6, 9, 0.6), CFrame = CFrame.new(MapKit.at(ctx, x + l[1], 4.5, z + l[2])), Color = DARK, Material = "Wood" })
	end
	local tank = p(ctx, { Name = "Tank", Shape = "Cylinder", Size = Vector3.new(5, 6, 6), CFrame = CFrame.new(MapKit.at(ctx, x, 11.5, z)) * CFrame.Angles(0, 0, math.rad(90)), Color = WOOD, Material = "WoodPlanks" })
	p(ctx, { Name = "Cap", Shape = "Ball", Size = Vector3.new(6.4, 2.6, 6.4), CFrame = CFrame.new(MapKit.at(ctx, x, 14.2, z)), Color = if snowy then { 246, 250, 255 } else { 120, 80, 50 }, Material = if snowy then "Snow" else "WoodPlanks" })
	return tank
end

function FarmProps2.dome(ctx, x, z)
	local glass = p(ctx, { Name = "Dome", Shape = "Ball", Size = Vector3.new(15, 15, 15), CFrame = CFrame.new(MapKit.at(ctx, x, 3, z)), Color = { 210, 236, 245 }, Material = "Glass", Transparency = 0.6, CanCollide = false })
	for k = 0, 3 do
		p(ctx, { Name = "Rib", Shape = "Cylinder", Size = Vector3.new(0.3, 15.1, 15.1), CFrame = CFrame.new(glass.Position) * CFrame.Angles(0, math.rad(k * 45), 0), Color = { 240, 244, 248 }, Material = "Metal", CanCollide = false, CanQuery = false, Transparency = 0.2 })
	end
	p(ctx, { Name = "Fountain", Shape = "Cylinder", Size = Vector3.new(1, 5, 5), CFrame = CFrame.new(MapKit.at(ctx, x, 0.5, z)) * CFrame.Angles(0, 0, math.rad(90)), Color = { 190, 190, 196 }, Material = "Slate" })
	MapKit.spot(ctx, MapKit.at(ctx, x + 3.4, 0, z))
end

function FarmProps2.bench(ctx, x, z)
	local top = p(ctx, { Name = "Bench", Size = Vector3.new(5, 0.4, 2), CFrame = CFrame.new(MapKit.at(ctx, x, 2.4, z)) * CFrame.Angles(0, ctx.rng:NextInteger(0, 1) * math.pi / 2, 0), Color = { 196, 150, 96 }, Material = "WoodPlanks" })
	for _, dx in ipairs({ -2.1, 2.1 }) do
		p(ctx, { Name = "Leg", Size = Vector3.new(0.4, 2.2, 1.8), CFrame = top.CFrame * CFrame.new(dx, -1.1, 0), Color = { 150, 106, 64 }, Material = "Wood" })
	end
	for i = -1, 1 do
		p(ctx, { Name = "Pot", Shape = "Cylinder", Size = Vector3.new(0.9, 0.9, 0.9), CFrame = top.CFrame * CFrame.new(i * 1.6, 0.65, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = { 196, 104, 60 }, Material = "Slate", CanCollide = false })
	end
	MapKit.spotsOn(ctx, top, 1, 1)
end

function FarmProps2.wateringCan(ctx, x, z)
	local colour = CANDY[ctx.rng:NextInteger(1, #CANDY)]
	local can = p(ctx, { Name = "Can", Shape = "Cylinder", Size = Vector3.new(1.4, 1.3, 1.3), CFrame = CFrame.new(MapKit.at(ctx, x, 0.7, z)) * CFrame.Angles(0, 0, math.rad(90)), Color = colour, Material = "SmoothPlastic" })
	p(ctx, { Name = "Spout", Size = Vector3.new(0.25, 0.25, 1.4), CFrame = can.CFrame * CFrame.new(0.2, 0, -0.9) * CFrame.Angles(math.rad(30), 0, 0), Color = colour, Material = "SmoothPlastic", CanCollide = false })
end

function FarmProps2.puddle(ctx, x, z)
	p(ctx, { Name = "Puddle", Shape = "Cylinder", Size = Vector3.new(0.06, ctx.rng:NextNumber(2, 4), ctx.rng:NextNumber(2, 4)), CFrame = CFrame.new(MapKit.at(ctx, x, 0.04, z)) * CFrame.Angles(0, 0, math.rad(90)), Color = { 120, 170, 220 }, Material = "Glass", Transparency = 0.3, CanCollide = false })
end

function FarmProps2.boathouse(ctx, x, z)
	local house = p(ctx, { Name = "Boathouse", Size = Vector3.new(10, 7, 8), CFrame = CFrame.new(MapKit.at(ctx, x, 3.5, z)), Color = { 130, 110, 96 }, Material = "WoodPlanks" })
	p(ctx, { Name = "Roof", Size = Vector3.new(11, 1, 9), CFrame = CFrame.new(MapKit.at(ctx, x, 7.5, z)), Color = { 90, 80, 76 }, Material = "Slate" })
	MapKit.spotsOn(ctx, house, 0, 3)
end

function FarmProps2.duck(ctx, x, z)
	p(ctx, { Name = "Duck", Shape = "Ball", Size = Vector3.new(1.2, 0.9, 1.6), CFrame = CFrame.new(MapKit.at(ctx, x, 0.6, z)), Color = { 250, 236, 120 }, Material = "SmoothPlastic", CanCollide = false })
	p(ctx, { Name = "Head", Shape = "Ball", Size = Vector3.one * 0.7, CFrame = CFrame.new(MapKit.at(ctx, x, 1.2, z - 0.6)), Color = { 250, 236, 120 }, Material = "SmoothPlastic", CanCollide = false })
end

function FarmProps2.well(ctx, x, z)
	local ring = p(ctx, { Name = "Well", Shape = "Cylinder", Size = Vector3.new(2.4, 5, 5), CFrame = CFrame.new(MapKit.at(ctx, x, 1.2, z)) * CFrame.Angles(0, 0, math.rad(90)), Color = { 170, 168, 160 }, Material = "Slate" })
	for _, dx in ipairs({ -2, 2 }) do
		p(ctx, { Name = "Post", Size = Vector3.new(0.5, 5, 0.5), CFrame = CFrame.new(MapKit.at(ctx, x + dx, 2.5, z)), Color = DARK, Material = "Wood" })
	end
	p(ctx, { Name = "Roof", Size = Vector3.new(5.6, 0.6, 3.4), CFrame = CFrame.new(MapKit.at(ctx, x, 5.2, z)), Color = { 150, 74, 50 }, Material = "WoodPlanks" })
	MapKit.spotsOn(ctx, ring, 0, 3)
end

-- A string of little flags between two points (map-local x, z), high over a corridor.
function FarmProps2.bunting(ctx, ax, az, bx, bz, y)
	local a, b = MapKit.at(ctx, ax, y, az), MapKit.at(ctx, bx, y, bz)
	local len = (b - a).Magnitude
	p(ctx, { Name = "String", Size = Vector3.new(0.08, 0.08, len), CFrame = CFrame.lookAt((a + b) / 2, b), Color = { 240, 240, 240 }, Material = "Fabric", CanCollide = false, CanQuery = false })
	for i = 1, math.floor(len / 1.6) do
		local pos = a:Lerp(b, i * 1.6 / len) - Vector3.new(0, 0.45 + math.sin(i / len * 1.6 * math.pi) * 0.3, 0)
		p(ctx, { Name = "Flag", Size = Vector3.new(0.05, 0.8, 0.7), CFrame = CFrame.lookAt(pos, pos + (b - a)) * CFrame.Angles(0, math.rad(90), 0), Color = CANDY[(i % #CANDY) + 1], Material = "Fabric", CanCollide = false, CanQuery = false })
	end
end

function FarmProps2.ferrisWheel(ctx, x, z)
	for _, dz in ipairs({ -1.5, 1.5 }) do
		for _, dx in ipairs({ -4, 4 }) do
			p(ctx, { Name = "Leg", Size = Vector3.new(0.8, 13, 0.8), CFrame = CFrame.new(MapKit.at(ctx, x + dx * 0.5, 6.2, z + dz)) * CFrame.Angles(0, 0, math.rad(dx > 0 and 17 or -17)), Color = { 230, 230, 236 }, Material = "Metal" })
		end
	end
	local hub = p(ctx, { Name = "Hub", Shape = "Cylinder", Size = Vector3.new(3.4, 1.4, 1.4), CFrame = CFrame.new(MapKit.at(ctx, x, 12.5, z)) * CFrame.Angles(0, math.rad(90), 0), Color = { 250, 200, 90 }, Material = "Metal", CanCollide = false })
	for k = 0, 7 do
		local a = k * math.pi / 4
		local spoke = p(ctx, { Name = "Spoke", Size = Vector3.new(0.3, 9, 0.3), CFrame = CFrame.new(hub.Position) * CFrame.Angles(0, 0, a) * CFrame.new(0, 4.5, 0), Color = { 236, 236, 240 }, Material = "Metal", CanCollide = false, CanQuery = false })
		local car = p(ctx, { Name = "Car", Size = Vector3.new(1.8, 1.6, 2.2), CFrame = CFrame.new(hub.Position + Vector3.new(-math.sin(a) * 9, math.cos(a) * 9, 0)), Color = CANDY[k % #CANDY + 1], Material = "SmoothPlastic", CanCollide = false, CanQuery = false })
		weld(hub, spoke)
		weld(hub, car)
	end
	spin(hub, 30)
	MapKit.spot(ctx, MapKit.at(ctx, x + 5, 0, z + 4))
end

function FarmProps2.carousel(ctx, x, z)
	local floor = p(ctx, { Name = "Carousel", Shape = "Cylinder", Size = Vector3.new(0.8, 12, 12), CFrame = CFrame.new(MapKit.at(ctx, x, 0.4, z)) * CFrame.Angles(0, 0, math.rad(90)), Color = { 240, 230, 210 }, Material = "WoodPlanks" })
	local top = p(ctx, { Name = "Canopy", Shape = "Ball", Size = Vector3.new(13, 4, 13), CFrame = CFrame.new(MapKit.at(ctx, x, 7, z)), Color = { 120, 180, 240 }, Material = "Fabric", CanCollide = false })
	p(ctx, { Name = "Pole", Shape = "Cylinder", Size = Vector3.new(7, 1.2, 1.2), CFrame = CFrame.new(MapKit.at(ctx, x, 3.8, z)) * CFrame.Angles(0, 0, math.rad(90)), Color = { 250, 200, 90 }, Material = "Metal" })
	for k = 0, 5 do -- little horses on poles, turning with the canopy
		local a = k * math.pi / 3
		local pos = MapKit.at(ctx, x + math.cos(a) * 4.2, 2.4, z + math.sin(a) * 4.2)
		weld(top, p(ctx, { Name = "Horse", Size = Vector3.new(0.8, 1.2, 2.2), CFrame = CFrame.lookAt(pos, pos + Vector3.new(-math.sin(a), 0, math.cos(a))), Color = CANDY[k % #CANDY + 1], Material = "SmoothPlastic", CanCollide = false, CanQuery = false }))
		weld(top, p(ctx, { Name = "Rod", Size = Vector3.new(0.15, 5, 0.15), CFrame = CFrame.new(pos + Vector3.new(0, 1.6, 0)), Color = { 250, 200, 90 }, Material = "Metal", CanCollide = false, CanQuery = false }))
	end
	spin(top, 16, "y")
	MapKit.spotsOn(ctx, floor, 1, 3)
end

function FarmProps2.balloons(ctx, x, z)
	p(ctx, { Name = "Cart", Size = Vector3.new(1.4, 2, 1.4), CFrame = CFrame.new(MapKit.at(ctx, x, 1, z)), Color = { 240, 236, 226 }, Material = "WoodPlanks" })
	for i = 1, 7 do
		local pos = MapKit.at(ctx, x + ctx.rng:NextNumber(-1.4, 1.4), 6 + ctx.rng:NextNumber(0, 2), z + ctx.rng:NextNumber(-1.4, 1.4))
		p(ctx, { Name = "Balloon", Shape = "Ball", Size = Vector3.new(1.3, 1.6, 1.3), CFrame = CFrame.new(pos), Color = CANDY[i % #CANDY + 1], Material = "SmoothPlastic", CanCollide = false, CanQuery = false })
	end
end

function FarmProps2.prizeBooth(ctx, x, z)
	local colour = CANDY[ctx.rng:NextInteger(1, #CANDY)]
	local counter = p(ctx, { Name = "Booth", Size = Vector3.new(6, 3, 3), CFrame = CFrame.new(MapKit.at(ctx, x, 1.5, z)), Color = colour, Material = "WoodPlanks" })
	for _, dx in ipairs({ -2.8, 2.8 }) do
		p(ctx, { Name = "Post", Size = Vector3.new(0.4, 7, 0.4), CFrame = CFrame.new(MapKit.at(ctx, x + dx, 3.5, z + 1.2)), Color = { 240, 236, 226 }, Material = "Wood" })
	end
	p(ctx, { Name = "Awning", Size = Vector3.new(6.6, 0.4, 3.6), CFrame = CFrame.new(MapKit.at(ctx, x, 7, z)), Color = colour, Material = "Fabric" })
	for i = -1, 1 do -- prizes on the counter
		p(ctx, { Name = "Prize", Shape = "Ball", Size = Vector3.one * 1.1, CFrame = CFrame.new(MapKit.at(ctx, x + i * 1.8, 3.6, z)), Color = CANDY[(i + 2) % #CANDY + 1], Material = "Fabric", CanCollide = false })
	end
	MapKit.spotsOn(ctx, counter, 0, 2)
end

return FarmProps2

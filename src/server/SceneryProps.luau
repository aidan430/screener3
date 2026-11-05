-- Farm props for the countryside (see Scenery): a tractor and trailer, carts, round hay bales,
-- scarecrows, a mailbox, the gate arch, signs, lane lanterns and a wooden water tower.
local Build = require(script.Parent.Build)
local Kit = require(script.Parent.SceneryKit)

local Props = {}
local C = Kit.C
local part, bit, beam = Kit.part, Kit.bit, Kit.beam
local ORANGE = { 222, 128, 40 }
local RUBBER = { 38, 34, 34 }
local RIM = { 236, 190, 60 }

local function facing(x, z, toX, toZ)
	return CFrame.lookAt(Vector3.new(x, 0, z), Vector3.new(toX, 0, toZ))
end

local function wheel(m, base, at, width, dia)
	part(m, base, "Tyre", Vector3.new(width, dia, dia), at, RUBBER, "SmoothPlastic", { shape = "Cylinder" })
	bit(m, base, "Rim", Vector3.new(width + 0.1, dia * 0.48, dia * 0.48), at, RIM, "Metal", "Cylinder")
end

-- A little orange tractor, parked. Front is local -Z.
function Props.tractor(parent, base)
	local m = Kit.model(parent, "Tractor")
	part(m, base, "Chassis", Vector3.new(4, 1.6, 10), Vector3.new(0, 3, 0), ORANGE, "Metal")
	part(m, base, "Hood", Vector3.new(3.4, 2.6, 5), Vector3.new(0, 5, -2.6), ORANGE, "Metal")
	bit(m, base, "Grille", Vector3.new(3, 2, 0.3), Vector3.new(0, 4.8, -5.2), C.black, "DiamondPlate")
	for _, x in ipairs({ -1.1, 1.1 }) do
		bit(m, base, "Headlight", Vector3.new(0.6, 0.6, 0.2), Vector3.new(x, 5.4, -5.4), { 255, 232, 180 }, "Neon")
	end
	Kit.post(m, base, "Exhaust", Vector3.new(1, 6.3, -3.4), 3.4, 0.5, C.black, "Metal", { collide = false })
	part(m, base, "Seat", Vector3.new(2, 0.6, 2), Vector3.new(0, 5, 2.6), C.black, "Fabric")
	part(m, base, "SeatBack", Vector3.new(2, 1.8, 0.4), Vector3.new(0, 6.1, 3.6), C.black, "Fabric")
	beam(m, base, "Steering", Vector3.new(0, 5, 0.2), Vector3.new(0, 6.6, 1.2), 0.3, C.black, "Metal", { collide = false })
	for _, x in ipairs({ -2.9, 2.9 }) do
		wheel(m, base, Vector3.new(x, 3.2, 2.6), 1.8, 6.4)
		part(m, base, "Fender", Vector3.new(1.9, 0.4, 6.6), Vector3.new(x, 6.6, 2.6), ORANGE, "Metal")
		wheel(m, base, Vector3.new(x * 0.8, 1.8, -3.4), 1.2, 3.6)
		for _, z in ipairs({ 0.8, 4.4 }) do
			bit(m, base, "RoofPost", Vector3.new(0.3, 4.4, 0.3), Vector3.new(x * 0.66, 9, z), C.black, "Metal")
		end
	end
	part(m, base, "CabRoof", Vector3.new(4.6, 0.4, 4.8), Vector3.new(0, 11.3, 2.6), ORANGE, "Metal")
end

-- A wooden trailer with its tongue toward local -Z, loaded with square bales.
function Props.trailer(parent, base)
	local m = Kit.model(parent, "Trailer")
	part(m, base, "Bed", Vector3.new(6, 0.6, 10), Vector3.new(0, 3, 0), C.plank, "WoodPlanks")
	for _, x in ipairs({ -2.8, 2.8 }) do
		part(m, base, "Side", Vector3.new(0.4, 1.6, 10), Vector3.new(x, 4.1, 0), C.wood, "WoodPlanks")
		wheel(m, base, Vector3.new(x * 1.18, 1.7, 0), 1, 3.4)
	end
	for _, z in ipairs({ -4.8, 4.8 }) do
		part(m, base, "End", Vector3.new(6, 1.6, 0.4), Vector3.new(0, 4.1, z), C.wood, "WoodPlanks")
	end
	beam(m, base, "Tongue", Vector3.new(0, 2.7, -5), Vector3.new(0, 2.2, -8.5), 0.5, C.darkWood, "Wood", { collide = false })
	for i, p in ipairs({ { -1.4, -2.6, 0 }, { 1.4, -2.6, 0 }, { -1.4, 1, 0 }, { 1.4, 1, 0 }, { 0, -0.8, 1 } }) do
		part(m, base, "TrailerBale" .. i, Vector3.new(2.2, 2, 3.4), Vector3.new(p[1], 4.3 + p[3] * 2, p[2]), C.hay, "Fabric")
	end
end

-- A two-wheeled wooden cart, handles resting on the ground toward local -Z, with a load.
function Props.cart(parent, base, loadColor)
	local m = Kit.model(parent, "Cart")
	part(m, base, "CartBed", Vector3.new(4, 0.4, 6), Vector3.new(0, 2.4, 0.6), C.plank, "WoodPlanks")
	for _, x in ipairs({ -1.9, 1.9 }) do
		part(m, base, "CartSide", Vector3.new(0.3, 1.2, 6), Vector3.new(x, 3.2, 0.6), C.wood, "WoodPlanks")
		part(m, base, "CartWheel", Vector3.new(0.4, 4, 4), Vector3.new(x * 1.3, 2, 1), C.darkWood, "Wood", { shape = "Cylinder" })
		bit(m, base, "Spoke", Vector3.new(0.45, 3.6, 0.3), Vector3.new(x * 1.3, 2, 1), C.wood, "Wood")
		bit(m, base, "Spoke", Vector3.new(0.45, 0.3, 3.6), Vector3.new(x * 1.3, 2, 1), C.wood, "Wood")
		beam(m, base, "Handle", Vector3.new(x * 0.8, 2.4, -2.4), Vector3.new(x * 0.7, 0.4, -6), 0.35, C.darkWood, "Wood", { collide = false })
	end
	for _, z in ipairs({ -2.3, 3.5 }) do
		part(m, base, "CartEnd", Vector3.new(4, 1.2, 0.3), Vector3.new(0, 3.2, z), C.wood, "WoodPlanks")
	end
	local rng = Random.new(math.floor(base.Position.X * 7 + base.Position.Z))
	for i = 1, 7 do
		local s = rng:NextNumber(1.3, 1.8)
		bit(m, base, "Load" .. i, Vector3.new(s, s, s), Vector3.new(rng:NextNumber(-1, 1), 3.4 + rng:NextNumber(0, 0.6), 0.6 + rng:NextNumber(-2, 2)), loadColor, "SmoothPlastic", "Ball")
	end
end

-- A pyramid of round hay bales lying on their sides (3, then 2, then 1).
function Props.bales(parent, base)
	local m = Kit.model(parent, "HayBales")
	for row = 0, 2 do
		for i = 0, 2 - row do
			local at = Vector3.new(0, 3 + row * 5.2, (i - (2 - row) / 2) * 6.1)
			part(m, base, "RoundBale", Vector3.new(5, 6, 6), at, C.hay, "Fabric", { shape = "Cylinder" })
			bit(m, base, "BaleSwirl", Vector3.new(5.1, 3.6, 3.6), at, { 198, 158, 78 }, "Fabric", "Cylinder")
		end
	end
end

-- A friendly scarecrow on a post, facing local -Z.
function Props.scarecrow(parent, base)
	local m = Kit.model(parent, "Scarecrow")
	part(m, base, "Pole", Vector3.new(0.6, 8, 0.6), Vector3.new(0, 4, 0.4), C.darkWood, "Wood")
	bit(m, base, "Shirt", Vector3.new(2.4, 2.8, 1.2), Vector3.new(0, 5.6, 0), { 176, 62, 50 }, "Fabric")
	bit(m, base, "Sleeves", Vector3.new(6.4, 0.9, 0.9), Vector3.new(0, 6.4, 0), { 70, 96, 140 }, "Fabric")
	bit(m, base, "Trousers", Vector3.new(2.2, 1.6, 1.1), Vector3.new(0, 3.6, 0), { 92, 76, 58 }, "Fabric")
	for _, x in ipairs({ -3.4, 3.4 }) do
		bit(m, base, "StrawHand", Vector3.new(0.8, 0.6, 0.6), Vector3.new(x, 6.2, 0), C.hay, "Fabric")
	end
	bit(m, base, "SackHead", Vector3.new(2, 2, 2), Vector3.new(0, 8, 0), { 226, 200, 150 }, "Fabric", "Ball")
	for _, x in ipairs({ -0.4, 0.4 }) do
		bit(m, base, "Eye", Vector3.new(0.3, 0.3, 0.3), Vector3.new(x, 8.2, -0.95), C.black, "SmoothPlastic", "Ball")
	end
	bit(m, base, "HatBrim", Vector3.new(0.2, 3.6, 3.6), CFrame.new(0, 8.9, 0) * CFrame.Angles(0, 0, math.rad(90)), { 196, 160, 90 }, "Fabric", "Cylinder")
	bit(m, base, "HatTop", Vector3.new(1.2, 1.8, 1.8), CFrame.new(0, 9.5, 0) * CFrame.Angles(0, 0, math.rad(90)), { 196, 160, 90 }, "Fabric", "Cylinder")
end

function Props.mailbox(parent, base)
	local m = Kit.model(parent, "Mailbox")
	part(m, base, "MailPost", Vector3.new(0.5, 4, 0.5), Vector3.new(0, 2, 0), C.darkWood, "Wood")
	part(m, base, "MailBox", Vector3.new(1.4, 1.4, 2.6), Vector3.new(0, 4.6, 0), { 176, 62, 50 }, "Metal")
	bit(m, base, "MailFlag", Vector3.new(0.1, 1.2, 0.4), Vector3.new(0.8, 5.2, 0.6), RIM, "Metal")
end

-- A wooden water tower on four braced legs, with a stepped roof.
function Props.waterTower(parent, base)
	local m = Kit.model(parent, "WaterTower")
	local corners = { { -6, -6 }, { 6, -6 }, { 6, 6 }, { -6, 6 } }
	for i, c in ipairs(corners) do
		part(m, base, "Leg", Vector3.new(1.2, 22, 1.2), Vector3.new(c[1], 11, c[2]), C.darkWood, "Wood")
		local n = corners[i % 4 + 1]
		beam(m, base, "Brace", Vector3.new(c[1], 2, c[2]), Vector3.new(n[1], 20, n[2]), 0.5, C.wood, "Wood", { collide = false })
		beam(m, base, "Brace", Vector3.new(n[1], 2, n[2]), Vector3.new(c[1], 20, c[2]), 0.5, C.wood, "Wood", { collide = false })
	end
	part(m, base, "Deck", Vector3.new(16, 0.8, 16), Vector3.new(0, 22.4, 0), C.plank, "WoodPlanks")
	Kit.post(m, base, "Tank", Vector3.new(0, 22.8, 0), 12, 14, { 150, 106, 66 }, "WoodPlanks")
	for _, y in ipairs({ 24.5, 28.5, 32.5 }) do
		Kit.post(m, base, "Hoop", Vector3.new(0, y, 0), 0.5, 14.4, C.black, "Metal", { collide = false })
	end
	for i, d in ipairs({ 15.5, 11.5, 7.5, 3.5 }) do
		Kit.post(m, base, "TankRoof", Vector3.new(0, 34.8 + (i - 1) * 1.2, 0), 1.2, d, { 116, 64, 52 }, "WoodPlanks")
	end
	beam(m, base, "Spout", Vector3.new(0, 25, -7), Vector3.new(0, 17, -11), 0.7, C.black, "Metal", { collide = false })
	for y = 2, 22, 2 do
		bit(m, base, "Rung", Vector3.new(1.4, 0.2, 0.2), Vector3.new(6, y, -6.8), C.darkWood, "Wood")
	end
end

-- The gate arch where the north lane leaves the farm, and the farm's name over it.
local function gate(parent)
	local m = Kit.model(parent, "FarmGate")
	local base = facing(0, -478, 0, 0) -- the sign faces into the farm
	for _, x in ipairs({ -13, 13 }) do
		part(m, base, "GatePost", Vector3.new(1.6, 15, 1.6), Vector3.new(x, 7.5, 0), C.darkWood, "Wood")
		Kit.lantern(m, base * CFrame.new(x * 1.25, 0, -1), 6)
	end
	part(m, base, "GateBeam", Vector3.new(30, 1.2, 1.2), Vector3.new(0, 14.6, 0), C.darkWood, "Wood")
	local board = part(m, base, "GateSign", Vector3.new(18, 3.4, 0.5), Vector3.new(0, 11.8, 0), { 214, 176, 118 }, "WoodPlanks", { collide = false })
	Build.text(board, Enum.NormalId.Front, "Hollow Creek Farm", { pixels = 30 })
end

function Props.build(folder)
	local m = Kit.model(folder, "Props")
	Props.tractor(m, facing(-40, -242, 100, -242))
	Props.trailer(m, facing(-54, -242, 100, -242))
	Props.cart(m, facing(116, -230, 116, 0), C.pumpkin)
	Props.cart(m, facing(186, -6, 0, -6), C.pumpkin)
	Props.cart(m, facing(-44, 238, 0, 0), { 196, 54, 44 })
	for _, p in ipairs({ { -35, -284 }, { -195, -140 }, { 320, -150 }, { 40, 215 } }) do
		Props.bales(m, facing(p[1], p[2], 0, 0))
	end
	Props.scarecrow(m, facing(250, -70, 0, -70))
	Props.scarecrow(m, facing(252, 76, 0, 76))
	Props.mailbox(m, facing(-12, -196, 0, -196))
	Props.waterTower(m, facing(-270, 258, 0, 0))
	gate(m)
	for i, z in ipairs({ -180, -245, -300, -350, -400, -450 }) do
		Kit.lantern(m, CFrame.new(if i % 2 == 0 then 11 else -11, 0, z), 7)
	end
	for _, s in ipairs({
		{ "Farmyard", 14, -200 },
		{ "Pumpkin Patch", 188, -40 },
		{ "Corn Rows", 188, 40 },
		{ "Duck Pond", -50, 226 },
		{ "Meadow Pens", -180, 14 },
		{ "Orchard", 212, 204 },
	}) do
		Kit.sign(m, facing(s[2], s[3], 0, 0), s[1], 10)
	end
end

return Props

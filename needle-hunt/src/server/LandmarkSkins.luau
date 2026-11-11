-- Dressing for Hayfield Farm's landmarks (server/Landmarks builds the parts you climb, then calls
-- these): seams, hoops and a hatch on the silo; braces, a pitched roof and a lamp on the lookout;
-- weathered red boards, a stone plinth, cream trim, a tin roof and lanterns on the barn; footing
-- stones, a door, windows and a railing on the windmill; braces and hoops on the water tower.
-- All of it is to look at only (server/WallKit.deco): nothing new to bump into or stand on.
local MapKit = require(script.Parent.MapKit)
local WallKit = require(script.Parent.WallKit)

local Skins = {}
local deco, tone = WallKit.deco, WallKit.tone
local TIMBER, TIN, CREAM, STONE = { 112, 96, 80 }, { 132, 136, 138 }, { 232, 226, 210 }, { 138, 132, 122 }

local function at(ctx, x, y, z)
	return MapKit.at(ctx, x, y, z)
end

-- A ring of `n` pieces round (x, z) at radius r: fn(angle, position on the ring at height 0).
local function ring(ctx, x, z, r, n, fn)
	for i = 0, n - 1 do
		local a = i / n * math.pi * 2
		fn(a, x + math.cos(a) * r, z + math.sin(a) * r)
	end
end

local function upright(pos, height, diameter) -- a cylinder standing up
	return CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(height, diameter, diameter)
end

function Skins.silo(ctx, x, z, h)
	ring(ctx, x, z, 4.55, 12, function(a, px, pz) -- seam ribs
		deco(ctx, { Name = "Rib", Size = Vector3.new(0.18, h, 0.5), CFrame = CFrame.new(at(ctx, px, h / 2, pz)) * CFrame.Angles(0, -a, 0), Color = { 132, 138, 144 }, Material = "Metal" })
	end)
	for _, y in ipairs({ 2, 8, 14, 20, 23.6 }) do -- hoops
		local cf, size = upright(at(ctx, x, y, z), 0.25, 9.25)
		deco(ctx, { Name = "Hoop", Shape = "Cylinder", Size = size, CFrame = cf, Color = { 120, 126, 132 }, Material = "Metal" })
	end
	local cf, size = upright(at(ctx, x, 20.9, z), 1.6, 9.12) -- its red band: the corn quarter's mark from far off
	deco(ctx, { Name = "Band", Shape = "Cylinder", Size = size, CFrame = cf, Color = { 128, 44, 38 }, Material = "Metal" })
	for i = 1, 6 do -- rust under the hoops
		local a = i * 1.1
		local l = 2 + (i % 3) * 1.6
		deco(ctx, { Name = "Rust", Size = Vector3.new(0.1, l, 0.8), CFrame = CFrame.new(at(ctx, x + math.cos(a) * 4.58, 14 - l / 2 - (i % 2) * 6, z + math.sin(a) * 4.58)) * CFrame.Angles(0, -a, 0), Color = { 128, 78, 50 }, Material = "CorrodedMetal" }, false, true)
	end
	deco(ctx, { Name = "Hatch", Size = Vector3.new(2, 3.2, 0.3), CFrame = CFrame.new(at(ctx, x, 1.8, z - 4.5)), Color = { 96, 102, 108 }, Material = "Metal" })
	deco(ctx, { Name = "HatchFrame", Size = Vector3.new(2.5, 3.7, 0.2), CFrame = CFrame.new(at(ctx, x, 1.85, z - 4.4)), Color = { 70, 74, 80 }, Material = "Metal" })
	MapKit.lamp(ctx, at(ctx, x, 4.4, z - 4.9), { 255, 200, 130 }, 18)
end

function Skins.lookout(ctx, x, z, h)
	for _, s in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do -- cross braces and girts between the legs
		local face = CFrame.new(at(ctx, x + s[1] * 3, 0, z + s[2] * 3)) * CFrame.Angles(0, if s[1] ~= 0 then 0 else math.rad(90), 0)
		for _, y in ipairs({ 5, 11 }) do
			for _, lean in ipairs({ -1, 1 }) do
				deco(ctx, { Name = "Brace", Size = Vector3.new(0.35, 0.35, 8), CFrame = face * CFrame.new(0, y, 0) * CFrame.Angles(math.rad(lean * 42), 0, 0), Color = tone(ctx, TIMBER, 0.08), Material = "Wood" })
			end
			deco(ctx, { Name = "Girt", Size = Vector3.new(0.4, 0.4, 6), CFrame = face * CFrame.new(0, y + 3, 0), Color = TIMBER, Material = "Wood" })
		end
	end
	for _, side in ipairs({ -1, 1 }) do -- a pitched tin roof over the flat one
		deco(ctx, { Name = "RoofPitch", Size = Vector3.new(9.8, 0.3, 5.6), CFrame = CFrame.new(at(ctx, x, h + 6.5, z + side * 2.3)) * CFrame.Angles(math.rad(side * 28), 0, 0), Color = tone(ctx, { 96, 112, 98 }, 0.05), Material = "Metal" }, true)
	end
	deco(ctx, { Name = "Ridge", Size = Vector3.new(10, 0.4, 0.6), CFrame = CFrame.new(at(ctx, x, h + 7.75, z)), Color = { 80, 92, 82 }, Material = "Metal" })
	deco(ctx, { Name = "Pole", Size = Vector3.new(0.2, 3, 0.2), CFrame = CFrame.new(at(ctx, x, h + 9.4, z)), Color = TIMBER, Material = "Wood" }, false, true)
	deco(ctx, { Name = "Pennant", Size = Vector3.new(0.08, 1.2, 2.2), CFrame = CFrame.new(at(ctx, x, h + 10.2, z + 1.2)), Color = { 232, 128, 40 }, Material = "Fabric" }, false, true)
	MapKit.lamp(ctx, at(ctx, x, h + 4.2, z), { 255, 200, 130 }, 18)
end

function Skins.barn(ctx, x, z, W, D, H)
	local reds = { { 142, 52, 44 }, { 128, 46, 40 }, { 156, 64, 52 } }
	local function boards(cx, cz, along, length, out) -- vertical boards outside one wall
		local n = math.floor(length / 1.4)
		for i = 1, n do
			local t = -length / 2 + (i - 0.5) * length / n
			local colour = if i % 8 == 0 then { 150, 132, 118 } else reds[(i * 7) % 3 + 1]
			local px, pz = cx + (if along == "x" then t else out * 0.65), cz + (if along == "z" then t else out * 0.65)
			deco(ctx, { Name = "Board", Size = if along == "x" then Vector3.new(length / n - 0.1, H, 0.25) else Vector3.new(0.25, H, length / n - 0.1), CFrame = CFrame.new(at(ctx, px, H / 2, pz)), Color = tone(ctx, colour, 0.05), Material = "WoodPlanks" })
		end
	end
	boards(x, z + D / 2, "x", W, 1)
	boards(x - W / 2, z, "z", D, -1)
	boards(x + W / 2, z, "z", D, 1)
	for _, side in ipairs({ -1, 1 }) do
		boards(x + side * (W / 4 + 2), z - D / 2, "x", W / 2 - 4, -1)
		deco(ctx, { Name = "DoorPost", Size = Vector3.new(0.5, 12, 0.5), CFrame = CFrame.new(at(ctx, x + side * 4.2, 6, z - D / 2 - 0.7)), Color = CREAM, Material = "WoodPlanks" })
		for _, cz in ipairs({ -D / 2, D / 2 }) do -- cream corner boards
			deco(ctx, { Name = "Corner", Size = Vector3.new(0.5, H, 0.5), CFrame = CFrame.new(at(ctx, x + side * (W / 2 + 0.6), H / 2, z + cz + (if cz < 0 then -0.6 else 0.6))), Color = CREAM, Material = "WoodPlanks" })
		end
		-- a tin roof pitched from the eaves to a ridge along the barn's length
		local run = D / 2 + 1.4
		deco(ctx, { Name = "RoofPitch", Size = Vector3.new(W + 3, 0.35, run / math.cos(math.rad(32))), CFrame = CFrame.new(at(ctx, x, H + 1 + run * math.tan(math.rad(32)) / 2, z + side * run / 2)) * CFrame.Angles(math.rad(side * 32), 0, 0), Color = tone(ctx, TIN, 0.05), Material = "Metal" }, true)
		for step = 1, 4 do -- the gable ends, in shrinking boards up to the ridge
			local halfWidth = run * (1 - (step - 0.5) / 4.6)
			deco(ctx, { Name = "Gable", Size = Vector3.new(0.4, 1.4, halfWidth * 2), CFrame = CFrame.new(at(ctx, x + side * (W / 2 + 0.4), H + 0.3 + step * 1.36, z)), Color = tone(ctx, reds[step % 3 + 1], 0.05), Material = "WoodPlanks" })
		end
	end
	deco(ctx, { Name = "DoorHead", Size = Vector3.new(9, 0.5, 0.5), CFrame = CFrame.new(at(ctx, x, 12.2, z - D / 2 - 0.7)), Color = CREAM, Material = "WoodPlanks" })
	deco(ctx, { Name = "RidgeCap", Size = Vector3.new(W + 3.4, 0.4, 0.9), CFrame = CFrame.new(at(ctx, x, H + 1.2 + (D / 2 + 1.4) * math.tan(math.rad(32)), z)), Color = { 110, 114, 118 }, Material = "Metal" })
	for _, p in ipairs({ { 0, D / 2 + 0.85, W + 1.7, 0.7 }, { -W / 2 - 0.85, 0, 0.7, D + 1.7 }, { W / 2 + 0.85, 0, 0.7, D + 1.7 } }) do -- a stone plinth round the foot
		deco(ctx, { Name = "Plinth", Size = Vector3.new(p[3], 1.4, p[4]), CFrame = CFrame.new(at(ctx, x + p[1], 0.7, z + p[2])), Color = tone(ctx, STONE, 0.05), Material = "Cobblestone" })
	end
	local ridge = H + 1.4 + (D / 2 + 1.4) * math.tan(math.rad(32))
	deco(ctx, { Name = "Cupola", Size = Vector3.new(3, 3, 3), CFrame = CFrame.new(at(ctx, x, ridge + 1.3, z)), Color = CREAM, Material = "WoodPlanks" }, true)
	deco(ctx, { Name = "CupolaRoof", Size = Vector3.new(3.8, 0.4, 3.8), CFrame = CFrame.new(at(ctx, x, ridge + 3, z)), Color = { 110, 114, 118 }, Material = "Metal" })
	deco(ctx, { Name = "Vane", Size = Vector3.new(0.12, 2.2, 0.12), CFrame = CFrame.new(at(ctx, x, ridge + 4.3, z)), Color = { 60, 60, 64 }, Material = "Metal" }, false, true)
	deco(ctx, { Name = "VaneArrow", Size = Vector3.new(2.4, 0.3, 0.08), CFrame = CFrame.new(at(ctx, x, ridge + 5, z)), Color = { 60, 60, 64 }, Material = "Metal" }, false, true)
	MapKit.lamp(ctx, at(ctx, x - 6, 8.6, z), { 255, 196, 120 }, 20) -- two hanging lanterns inside
	MapKit.lamp(ctx, at(ctx, x + 6, 8.6, z - 2), { 255, 196, 120 }, 20)
end

function Skins.windmill(ctx, x, z, balconyY)
	ring(ctx, x, z, 5.5, 12, function(a, px, pz) -- footing stones round the tower
		deco(ctx, { Name = "Footing", Size = Vector3.new(0.9, 2.2, 2.9), CFrame = CFrame.new(at(ctx, px, 1.1, pz)) * CFrame.Angles(0, -a, 0), Color = tone(ctx, STONE, 0.08), Material = "Cobblestone" })
	end)
	deco(ctx, { Name = "Door", Size = Vector3.new(0.3, 4.6, 2.2), CFrame = CFrame.new(at(ctx, x + 4.6, 2.3, z)), Color = { 70, 52, 38 }, Material = "WoodPlanks" })
	deco(ctx, { Name = "DoorStone", Size = Vector3.new(0.5, 0.6, 3), CFrame = CFrame.new(at(ctx, x + 4.6, 4.9, z)), Color = STONE, Material = "Slate" })
	for i, y in ipairs({ 6, 9.5 }) do -- dark windows up the tower
		local a = i * 2.1
		deco(ctx, { Name = "Window", Size = Vector3.new(0.2, 1.6, 1), CFrame = CFrame.new(at(ctx, x + math.cos(a) * 4.5, y, z + math.sin(a) * 4.5)) * CFrame.Angles(0, -a, 0), Color = { 40, 40, 48 }, Material = "Glass" }, false, true)
	end
	ring(ctx, x, z, 7.3, 12, function(a, px, pz) -- the balcony's railing
		deco(ctx, { Name = "RailPost", Size = Vector3.new(0.25, 2.6, 0.25), CFrame = CFrame.new(at(ctx, px, balconyY + 1.3, pz)), Color = TIMBER, Material = "Wood" }, false, true)
		if a > 0.6 then -- open where the stepping stones arrive
			deco(ctx, { Name = "Rail", Size = Vector3.new(0.2, 0.2, 3.9), CFrame = CFrame.new(at(ctx, x + math.cos(a + 0.26) * 7.3, balconyY + 2.5, z + math.sin(a + 0.26) * 7.3)) * CFrame.Angles(0, -(a + 0.26), 0), Color = TIMBER, Material = "Wood" }, false, true)
		end
	end)
end

function Skins.waterTower(ctx, x, z, h)
	for _, s in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
		local face = CFrame.new(at(ctx, x + s[1] * 2.5, h / 2, z + s[2] * 2.5)) * CFrame.Angles(0, if s[1] ~= 0 then 0 else math.rad(90), 0)
		for _, lean in ipairs({ -1, 1 }) do
			deco(ctx, { Name = "Brace", Size = Vector3.new(0.3, 0.3, 11), CFrame = face * CFrame.Angles(math.rad(lean * 62), 0, 0), Color = tone(ctx, TIMBER, 0.08), Material = "Wood" })
		end
	end
	for _, y in ipairs({ h + 1, h + 3, h + 5 }) do -- iron hoops round the tank
		local cf, size = upright(at(ctx, x, y, z), 0.3, 8.2)
		deco(ctx, { Name = "Hoop", Shape = "Cylinder", Size = size, CFrame = cf, Color = { 70, 66, 62 }, Material = "CorrodedMetal" })
	end
	deco(ctx, { Name = "Pipe", Size = Vector3.new(0.5, h, 0.5), CFrame = CFrame.new(at(ctx, x, h / 2, z)), Color = { 96, 100, 104 }, Material = "Metal" })
end

return Skins

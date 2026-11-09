-- The hand tools' shapes (Config.Tools[n].shape), drawn from the owner's tool sheet: the Garden
-- Trowel, the Wooden and Iron Pitchforks, the Steel and Golden Rakes and the Super Sifter. Same
-- space and return value as ToolParts (see there).
local P = require(script.Parent.ToolParts)

local ToolHand = {}
local ROLL, FLAT, UPRIGHT = P.ROLL, P.FLAT, P.UPRIGHT
local GREY, DARK, RUBBER = P.GREY, P.DARK, P.RUBBER
local TWINE, WOOD = { 200, 172, 120 }, { 150, 105, 62 }

-- Bands of twine or rope round the handle at each y.
local function lashing(k, ys, width)
	for _, y in ipairs(ys) do
		P.trim(k, Vector3.new(0.12, width, width), CFrame.new(0, y, 0) * ROLL, TWINE, "Fabric", "Cylinder")
	end
end

-- A metal collar where the handle meets the head, with rivets if asked.
local function collar(k, y, rivets)
	P.trim(k, Vector3.new(0.55, 0.42, 0.42), CFrame.new(0, y, 0) * ROLL, GREY, "Metal", "Cylinder")
	if rivets then
		for _, x in ipairs({ -0.21, 0.21 }) do
			P.trim(k, Vector3.new(0.1, 0.1, 0.1), CFrame.new(x, y, 0), DARK, "Metal", "Ball")
		end
	end
end

-- Garden Trowel: a chunky wooden handle wrapped in twine, a metal ferrule and neck, and a worn,
-- rusty pointed scoop with raised sides, where the hay sits.
function ToolHand.trowel(k)
	P.trim(k, Vector3.new(1.7, 0.52, 0.52), CFrame.new(0, -0.25, 0) * ROLL, WOOD, "Wood", "Cylinder")
	P.trim(k, Vector3.new(0.56, 0.56, 0.56), CFrame.new(0, -1.1, 0), WOOD, "Wood", "Ball")
	lashing(k, { -0.75, -0.55, -0.35, -0.15 }, 0.58)
	P.trim(k, Vector3.new(0.3, 0.34, 0.34), CFrame.new(0, 0.7, 0) * ROLL, GREY, "Metal", "Cylinder")
	P.bar(k, Vector3.new(0, 0.8, 0), Vector3.new(0, 1.25, 0.12), 0.14, DARK, "Metal")
	P.head(k, Vector3.new(1.0, 1.3, 0.08), CFrame.new(0, 1.9, 0.14))
	P.head(k, Vector3.new(0.72, 0.72, 0.08), CFrame.new(0, 2.55, 0.14) * CFrame.Angles(0, 0, math.rad(45))) -- the point
	for _, side in ipairs({ -1, 1 }) do -- the raised sides of the scoop
		P.head(k, Vector3.new(0.08, 1.25, 0.2), CFrame.new(side * 0.48, 1.85, 0.22) * CFrame.Angles(0, math.rad(side * 25), 0))
	end
	return { length = 1.6, hold = -0.35, seat = CFrame.new(0, 1.85, 0.18) * UPRIGHT, load = 1.0, hidden = true }
end

-- Pitchforks: a crossbar and three straight prongs with round tips. Wooden: chunky wooden prongs
-- bound on with rope. Iron: thick iron prongs on a riveted collar and a wooden knob on the end.
local function fork(k, metal)
	local thick = if metal then 0.2 else 0.24
	local gap, top = 0.5, 4.9
	P.trim(k, Vector3.new(0.4, 0.4, 0.4), CFrame.new(0, -3, 0), WOOD, "Wood", "Ball")
	if metal then
		collar(k, 2.75, true)
		P.bar(k, Vector3.new(0, 2.95, 0), Vector3.new(0, 3.2, 0.02), 0.22)
	else
		lashing(k, { 2.45, 2.62, 2.79 }, 0.4)
		P.bar(k, Vector3.new(-0.2, 2.5, 0.16), Vector3.new(0.2, 3.1, 0.16), 0.07, TWINE, "Fabric") -- the rope's cross
		P.bar(k, Vector3.new(0.2, 2.5, 0.16), Vector3.new(-0.2, 3.1, 0.16), 0.07, TWINE, "Fabric")
	end
	P.head(k, Vector3.new(2 * gap + thick, thick, thick), CFrame.new(0, 3.2, 0))
	for i = -1, 1 do
		local x = i * gap
		P.head(k, Vector3.new(thick, top - 3.2, thick), CFrame.new(x, (top + 3.2) / 2, 0))
		P.head(k, Vector3.new(thick * 1.25, thick * 1.25, thick * 1.25), CFrame.new(x, top, 0), "Ball")
	end
	return { length = 6, hold = -1.5, seat = CFrame.new(0, 4.0, 0.1) * UPRIGHT, load = 1.9 }
end

function ToolHand.fork3(k)
	return fork(k, false)
end

function ToolHand.fork4(k)
	return fork(k, true)
end

-- Rakes: a socket and a flat head that widens towards ten straight teeth with round ends. Steel:
-- a blue grip on the end. Golden: all gold, a gold end cap and a little sparkle.
local function rake(k, golden)
	local trim = if golden then { 255, 214, 90 } else GREY
	if golden then
		P.trim(k, Vector3.new(0.3, 0.42, 0.42), CFrame.new(0, -2.9, 0) * ROLL, trim, "Metal", "Cylinder")
	else
		P.trim(k, Vector3.new(1.0, 0.4, 0.4), CFrame.new(0, -2.55, 0) * ROLL, { 60, 120, 200 }, "Fabric", "Cylinder")
	end
	P.trim(k, Vector3.new(0.5, 0.38, 0.38), CFrame.new(0, 2.75, 0) * ROLL, trim, "Metal", "Cylinder")
	P.bar(k, Vector3.new(0, 2.95, 0), Vector3.new(0, 3.3, 0.02), 0.2, trim, "Metal")
	P.head(k, Vector3.new(1.3, 0.45, 0.1), CFrame.new(0, 3.5, 0))
	local plate = P.head(k, Vector3.new(2.1, 0.4, 0.1), CFrame.new(0, 3.9, 0))
	for _, side in ipairs({ -1, 1 }) do -- the flared shoulders
		P.head(k, Vector3.new(0.55, 0.12, 0.1), CFrame.new(side * 0.82, 3.68, 0) * CFrame.Angles(0, 0, math.rad(side * 40)))
	end
	for i = 0, 9 do
		local x = -0.99 + i * 0.22
		P.head(k, Vector3.new(0.11, 0.85, 0.11), CFrame.new(x, 4.5, 0))
		P.head(k, Vector3.new(0.13, 0.13, 0.13), CFrame.new(x, 4.92, 0), "Ball")
	end
	if golden then
		P.emitter(plate, Color3.fromRGB(255, 240, 180), 3, 0.5, { 0.12, 0 })
	end
	return { length = 6, hold = -1.5, seat = CFrame.new(0, 3.95, 0.08) * UPRIGHT, load = 2.3 }
end

function ToolHand.rake(k)
	return rake(k, false)
end

function ToolHand.goldrake(k)
	return rake(k, true)
end

-- The Super Sifter: held like a pan by a short grip with a trigger; a dark round frame, a glowing
-- mesh and little lights round the rim.
function ToolHand.sifter(k)
	P.trim(k, Vector3.new(1.2, 0.44, 0.44), CFrame.new(0, -0.3, 0) * ROLL, RUBBER, "Fabric", "Cylinder")
	P.trim(k, Vector3.new(0.14, 0.3, 0.32), CFrame.new(0, 0.05, -0.28), DARK, "SmoothPlastic") -- the trigger
	P.trim(k, Vector3.new(0.5, 0.3, 0.4), CFrame.new(0, 0.55, 0.05), DARK, "SmoothPlastic")
	local r, y = 1.25, 1.95
	local mesh = P.head(k, Vector3.new(0.04, r * 2, r * 2), CFrame.new(0, y, 0) * FLAT, "Cylinder")
	mesh.Transparency = 0.3
	P.light(mesh, mesh.Color, 5)
	for _, x in ipairs({ -0.75, -0.25, 0.25, 0.75 }) do -- the mesh, both ways
		local span = 2 * math.sqrt(r * r - x * x)
		P.trim(k, Vector3.new(0.04, span, 0.04), CFrame.new(x, y, 0.03), DARK, "Metal")
		P.trim(k, Vector3.new(span, 0.04, 0.04), CFrame.new(0, y + x, 0.03), DARK, "Metal")
	end
	P.ring(k, CFrame.new(0, y, 0.06), r + 0.1, 20, 0.26, 0.34, { 64, 68, 80 }, "SmoothPlastic")
	P.ring(k, CFrame.new(0, y, -0.12), r + 0.14, 20, 0.22, 0.12, { 46, 48, 58 }, "SmoothPlastic")
	for i = 0, 7 do -- little lights round the rim
		local a = i / 8 * math.pi * 2 + math.pi / 8
		P.head(k, Vector3.new(0.13, 0.13, 0.13), CFrame.new(math.cos(a) * (r + 0.1), y + math.sin(a) * (r + 0.1), 0.24), "Ball")
	end
	return { length = 1.2, hold = -0.3, seat = CFrame.new(0, y, 0.04) * UPRIGHT, load = 2.0, material = "SmoothPlastic" }
end

return ToolHand

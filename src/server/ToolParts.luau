-- The farm tools' shapes, built from parts welded to the tool's Handle (Config.Tools[n].shape).
-- Space: the Handle runs along Y with the working end at +Y, +Z is up when held and X is
-- sideways (Tools.make holds every tool straight out in front, like the spade). A shape
-- builds its parts and returns how to hold it: { length = the handle's length, hold = where
-- the hand grips (Y), seat = where the carried hay's bottom sits, load = the hay's biggest
-- size, material = the handle's material, hidden = true to hide the handle }.
-- "Head" parts take the tool's (or skin's) head colour and material; "Trim" parts keep theirs.
local ToolParts = {}

local ROLL = CFrame.Angles(0, 0, math.rad(90)) -- a cylinder lying along the handle
local FLAT = CFrame.Angles(0, math.rad(90), 0) -- a cylinder lying flat, its face up
local UPRIGHT = CFrame.Angles(math.rad(90), 0, 0) -- turns the carried hay's up to +Z
ToolParts.ROLL, ToolParts.FLAT, ToolParts.UPRIGHT = ROLL, FLAT, UPRIGHT

local GREY, DARK, RUBBER = { 150, 154, 160 }, { 70, 72, 78 }, { 46, 46, 50 }
ToolParts.GREY, ToolParts.DARK, ToolParts.RUBBER = GREY, DARK, RUBBER

-- One part welded to the handle. `colour` is a Color3 or {r, g, b}.
function ToolParts.piece(k, name, size, cf, colour, material, shape)
	local part = Instance.new("Part")
	part.Name = name
	if shape then
		part.Shape = Enum.PartType[shape]
	end
	part.Size = size
	part.Color = if typeof(colour) == "Color3" then colour else Color3.fromRGB(colour[1], colour[2], colour[3])
	part.Material = if typeof(material) == "EnumItem" then material else Enum.Material[material]
	part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
	part.Massless = true
	part.CastShadow = false
	part.CFrame = k.handle.CFrame * cf
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1 = k.handle, part
	weld.Parent = part
	part.Parent = k.tool
	return part
end

function ToolParts.head(k, size, cf, shape)
	return ToolParts.piece(k, "Head", size, cf, k.colour, k.material, shape)
end

function ToolParts.trim(k, size, cf, colour, material, shape)
	return ToolParts.piece(k, "Trim", size, cf, colour, material or "SmoothPlastic", shape)
end

-- A square rod from `a` to `b` (Vector3s in handle space, not straight up or down).
function ToolParts.bar(k, a, b, thick, colour, material)
	local cf = CFrame.lookAt((a + b) / 2, b, Vector3.new(0, 0, 1))
	local size = Vector3.new(thick, thick, (b - a).Magnitude)
	if colour then
		return ToolParts.trim(k, size, cf, colour, material)
	end
	return ToolParts.head(k, size, cf)
end

-- A ring of `count` blocks round `centre` in its X-Y plane, from angle `from` to `to`
-- (radians, a full circle by default). `colour` nil makes them Head parts.
function ToolParts.ring(k, centre, radius, count, thick, height, colour, material, from, to)
	from, to = from or 0, to or math.pi * 2
	local step = (to - from) / count
	local length = 2 * radius * math.tan(math.abs(step) / 2) + thick
	local parts = {}
	for i = 0, count - 1 do
		local a = from + step * (i + 0.5)
		local cf = centre * CFrame.new(radius * math.cos(a), radius * math.sin(a), 0) * CFrame.Angles(0, 0, a)
		local size = Vector3.new(thick, length, height)
		table.insert(parts, if colour then ToolParts.trim(k, size, cf, colour, material) else ToolParts.head(k, size, cf))
	end
	return parts
end

-- A rubber grip where the hand holds, and a cap on the back end.
local function grip(k, y, back)
	ToolParts.trim(k, Vector3.new(1.1, 0.4, 0.4), CFrame.new(0, y, 0) * ROLL, RUBBER, "Fabric", "Cylinder")
	ToolParts.trim(k, Vector3.new(0.18, 0.42, 0.42), CFrame.new(0, back, 0) * ROLL, DARK, "Metal", "Cylinder")
end

-- A metal collar where the handle meets the head.
local function collar(k, y)
	ToolParts.trim(k, Vector3.new(0.55, 0.4, 0.4), CFrame.new(0, y, 0) * ROLL, GREY, "Metal", "Cylinder")
end

-- Pitchforks: tines that run forward and curl up at the tips. Wooden: 3; Iron: 4 and a D-grip.
local function fork(k, tines, dgrip)
	grip(k, -1.5, -3)
	collar(k, 2.75)
	local gap = 0.45
	ToolParts.head(k, Vector3.new((tines - 1) * gap + 0.3, 0.3, 0.3), CFrame.new(0, 3.05, 0))
	for i = 1, tines do
		local x = (i - (tines + 1) / 2) * gap
		ToolParts.head(k, Vector3.new(0.13, 1.4, 0.13), CFrame.new(x, 3.85, 0))
		ToolParts.bar(k, Vector3.new(x, 4.5, 0), Vector3.new(x, 5.05, 0.28), 0.11)
	end
	if dgrip then -- a D-shaped handle on the back end, for two-handed lifting
		ToolParts.trim(k, Vector3.new(0.8, 0.14, 0.14), CFrame.new(0, -3.75, 0), DARK, "Metal")
		ToolParts.bar(k, Vector3.new(-0.08, -3.0, 0), Vector3.new(-0.4, -3.75, 0), 0.13, DARK, "Metal")
		ToolParts.bar(k, Vector3.new(0.08, -3.0, 0), Vector3.new(0.4, -3.75, 0), 0.13, DARK, "Metal")
	end
	return { length = 6, hold = -1.5, seat = CFrame.new(0, 4.0, 0.08) * UPRIGHT, load = 1.2 + tines * 0.35 }
end

function ToolParts.fork3(k)
	return fork(k, 3, false)
end

function ToolParts.fork4(k)
	return fork(k, 4, true)
end

-- Rakes: a wide bar braced by a bow, nine teeth that run forward and curl up. The golden rake
-- adds gold knobs and a gold collar.
local function rake(k, golden)
	grip(k, -1.5, -3)
	collar(k, 2.55)
	local trim = if golden then { 255, 214, 90 } else GREY
	ToolParts.head(k, Vector3.new(2.7, 0.3, 0.3), CFrame.new(0, 3.3, 0))
	for _, side in ipairs({ -1, 1 }) do
		ToolParts.bar(k, Vector3.new(side * 0.12, 2.75, 0), Vector3.new(side * 1.2, 3.3, 0), 0.14)
		if golden then
			ToolParts.trim(k, Vector3.new(0.42, 0.42, 0.42), CFrame.new(side * 1.45, 3.3, 0), trim, "Metal", "Ball")
		end
	end
	for i = -4, 4 do
		local x = i * 0.3
		ToolParts.head(k, Vector3.new(0.11, 0.9, 0.11), CFrame.new(x, 3.85, 0))
		ToolParts.bar(k, Vector3.new(x, 4.25, 0), Vector3.new(x, 4.6, 0.3), 0.1)
	end
	if golden then
		ToolParts.trim(k, Vector3.new(0.3, 0.46, 0.46), CFrame.new(0, 2.3, 0) * ROLL, trim, "Metal", "Cylinder")
	end
	return { length = 6, hold = -1.5, seat = CFrame.new(0, 3.85, 0.06) * UPRIGHT, load = 2.5 }
end

function ToolParts.rake(k)
	return rake(k, false)
end

function ToolParts.goldrake(k)
	return rake(k, true)
end

-- The Super Sifter: a round sieve with a crossed mesh and a glowing rim on a long handle.
function ToolParts.sifter(k)
	grip(k, -1.5, -3)
	collar(k, 2.6)
	local r, y = 1.2, 4.0
	ToolParts.trim(k, Vector3.new(0.06, r * 2, r * 2), CFrame.new(0, y, 0) * FLAT, { 210, 214, 220 }, "DiamondPlate", "Cylinder").Transparency = 0.2
	for _, x in ipairs({ -0.6, 0, 0.6 }) do -- the mesh, both ways
		local span = 2 * math.sqrt(r * r - x * x)
		ToolParts.trim(k, Vector3.new(0.05, span, 0.05), CFrame.new(x, y, 0.05), DARK, "Metal")
		ToolParts.trim(k, Vector3.new(span, 0.05, 0.05), CFrame.new(0, y + x, 0.05), DARK, "Metal")
	end
	ToolParts.ring(k, CFrame.new(0, y, 0.12), r, 16, 0.18, 0.32)
	return { length = 6, hold = -1.5, seat = CFrame.new(0, y, 0.06) * UPRIGHT, load = 2.1 }
end

return ToolParts

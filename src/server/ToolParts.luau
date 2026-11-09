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

-- A place in the shape's own space, shrunk to the tool's real size (k.scale, Config.ToolScale):
-- shapes are drawn full size and every piece shrinks together.
function ToolParts.scaled(k, cf)
	return CFrame.new(cf.Position * k.scale) * cf.Rotation
end

-- One part welded to the handle. `colour` is a Color3 or {r, g, b}.
function ToolParts.piece(k, name, size, cf, colour, material, shape)
	size, cf = size * k.scale, ToolParts.scaled(k, cf)
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

-- Little effects: drifting sparkles or puffs, and a soft glow.
function ToolParts.emitter(part, colour, rate, speed, size, direction)
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(colour)
	e.Rate, e.Speed, e.Lifetime = rate, NumberRange.new(speed * 0.5, speed), NumberRange.new(0.4, 0.8)
	e.Size = NumberSequence.new(size[1], size[2])
	e.Transparency = NumberSequence.new(0.6, 1)
	e.LightEmission = 0.6
	e.SpreadAngle = Vector2.new(15, 15)
	e.EmitDirection = direction or Enum.NormalId.Top
	e.Parent = part
	return e
end

function ToolParts.light(part, colour, range)
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness = colour, range, 0.8
	l.Parent = part
end

return ToolParts

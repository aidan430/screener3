-- Builds a needle of any type in any skin out of parts (shared/Needles): for the NEEDLE FOUND!
-- reveal, the Collection screen (inside ViewportFrames) and the lobby's showcase pedestals.
-- The needle lies along X, eye end at -X, point at +X, about 2-3 studs long at scale 1. The
-- novelty shapes (swordfish, firework, jackhammer, shooting star) keep that rule: their point (a
-- bill, a nose cone, a chisel, a star) is at +X.
-- The shaft is cut into segments so patterns (stripes, gradient, rainbow, bands, sheen, split,
-- tri, candy) show along it.
-- fat (1 = true to life) thickens it for display: the UI and pedestals use about 2, so a needle
-- reads as a bold little trophy instead of a hairline.
local Needles = require(script.Parent.Needles)
local Shapes = {} -- shapes kept as data, in as many files as dev/shapes.py needed
for _, name in ipairs({ "ShapesA", "ShapesB", "ShapesC", "ShapesD", "ShapesE", "ShapesF" }) do
	local file = script.Parent:FindFirstChild(name)
	for id, ops in pairs(if file then require(file) else {}) do
		Shapes[id] = ops
	end
end
local PART = { B = nil, C = "Cylinder", S = "Ball" }

local NeedleLook = {}

local function rgb(c)
	return Color3.fromRGB(c[1], c[2], c[3])
end

-- The colour of shaft segment i of n for a skin.
local function colourAt(skin, i, n)
	local a, b = rgb(skin.colours[1]), rgb(skin.colours[2] or skin.colours[1])
	local t = (i - 0.5) / n
	local pattern = skin.pattern
	if pattern == "stripes" then
		return if i % 2 == 1 then a else b
	elseif pattern == "gradient" then
		return a:Lerp(b, t)
	elseif pattern == "rainbow" then
		return Color3.fromHSV(t * 0.85, 0.65, 1)
	elseif pattern == "bands" then -- thin bands of the second colour
		return if i % 3 == 0 then b else a
	elseif pattern == "sheen" then -- light running along the middle
		return a:Lerp(b, 1 - math.abs(2 * t - 1))
	elseif pattern == "split" then
		return if t < 0.5 then a else b
	elseif pattern == "tri" then -- three colours along it (the third is also the eye)
		return rgb(skin.colours[math.min(3, math.floor(t * 2) + 1)] or skin.colours[1])
	elseif pattern == "candy" then -- every colour in turn
		return rgb(skin.colours[(i - 1) % #skin.colours + 1])
	end
	return a
end

local function accent(skin)
	if skin.pattern == "rainbow" then
		return Color3.fromHSV(0.85, 0.5, 1)
	elseif skin.pattern == "tri" then
		return rgb(skin.colours[3] or skin.colours[2] or skin.colours[1])
	end
	return if skin.pattern == "solid" then rgb(skin.colours[1]) else rgb(skin.colours[2] or skin.colours[1])
end

function NeedleLook.build(typeId, skinId, scale, fat)
	scale, fat = scale or 1, fat or 1
	local skin = Needles.skin(skinId) or Needles.skin("steel")
	fat *= skin.thin or 1 -- a paper-thin skin (the 1 of 1)
	local model = Instance.new("Model")
	model.Name = Needles.name(typeId, skin.id)
	local material = Enum.Material[skin.material] or Enum.Material.Metal
	local root = Instance.new("Part")
	root.Name, root.Size, root.Transparency, root.Anchored = "Root", Vector3.one * 0.1, 1, true
	root.CanCollide, root.CanQuery, root.CanTouch = false, false, false
	root.Parent = model
	model.PrimaryPart = root

	-- onCurve: its position isn't thickened (a curve or a star keeps its shape); keep: nor is its
	-- size (a flat fin stays a fin)
	local function part(size, cf, colour, shape, onCurve, keep)
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
		p.Shape = Enum.PartType[shape or "Block"]
		if keep then
			p.Size = size * scale
		elseif shape == "Ball" then
			p.Size = size * scale * fat
		else
			p.Size = Vector3.new(size.X, size.Y * fat, size.Z * fat) * scale
		end
		local y = if onCurve then cf.Position.Y else cf.Position.Y * fat -- a curve keeps its shape
		p.CFrame = CFrame.new(Vector3.new(cf.Position.X, y, cf.Position.Z) * scale) * cf.Rotation
		p.Color, p.Material, p.Transparency = colour, material, skin.see or 0
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = model
		return p
	end
	-- a shaft from x0 to x1, d thick, in n patterned segments (y offsets it sideways)
	local function shaft(x0, x1, d, n, y, flat)
		local len = (x1 - x0) / n
		for i = 1, n do
			local cf = CFrame.new(x0 + (i - 0.5) * len, y or 0, 0)
			if flat then
				part(Vector3.new(len + 0.01, d, flat), cf, colourAt(skin, i, n))
			else
				part(Vector3.new(len + 0.01, d, d), cf, colourAt(skin, i, n), "Cylinder")
			end
		end
	end
	local function tip(x, d, steps)
		for i = 1, steps do
			local k = 1 - i / (steps + 1)
			part(Vector3.new(0.08, d * k, d * k), CFrame.new(x + i * 0.07, 0, 0), colourAt(skin, 6, 6), "Cylinder")
		end
	end
	local function eye(x, len, gap, d)
		for _, s in ipairs({ -1, 1 }) do
			part(Vector3.new(len, d * 0.45, d * 0.45), CFrame.new(x, s * gap, 0), accent(skin), "Cylinder")
		end
		part(Vector3.new(d * 0.6, gap * 2 + d * 0.45, d * 0.5), CFrame.new(x - len / 2, 0, 0), accent(skin))
	end
	local function ball(x, d, y, onCurve)
		part(Vector3.one * d, CFrame.new(x, y or 0, 0), accent(skin), "Ball", onCurve)
	end

	if typeId == "pin" then
		shaft(-0.75, 0.85, 0.06, 6)
		tip(0.85, 0.06, 2)
		ball(-0.85, 0.28)
	elseif typeId == "quilting" then
		shaft(-0.6, 0.6, 0.07, 5)
		tip(0.6, 0.07, 2)
		eye(-0.7, 0.18, 0.03, 0.07)
	elseif typeId == "darning" then
		shaft(-1.15, 1.1, 0.12, 7)
		tip(1.1, 0.12, 3)
		eye(-1.3, 0.34, 0.07, 0.12)
	elseif typeId == "embroidery" then
		shaft(-0.85, 0.85, 0.09, 6)
		tip(0.85, 0.09, 3)
		eye(-1.02, 0.34, 0.08, 0.1)
	elseif typeId == "tapestry" then
		shaft(-0.95, 1.0, 0.11, 6)
		ball(1.03, 0.13)
		eye(-1.12, 0.34, 0.07, 0.11)
	elseif typeId == "safety" then
		shaft(-0.9, 0.85, 0.06, 6, 0.13)
		shaft(-0.75, 0.85, 0.06, 6, -0.13)
		for i = 0, 7 do -- the coil
			local a = i / 8 * math.pi * 2
			part(Vector3.new(0.06, 0.06, 0.06), CFrame.new(-0.95 + math.cos(a) * 0.13, math.sin(a) * 0.13, 0), accent(skin), "Ball")
		end
		part(Vector3.new(0.24, 0.38, 0.12), CFrame.new(0.95, 0, 0), accent(skin))
	elseif typeId == "knitting" then
		shaft(-1.45, 1.3, 0.18, 8)
		tip(1.3, 0.18, 4)
		ball(-1.6, 0.4)
	elseif typeId == "crochet" then
		shaft(-1.3, 1.1, 0.16, 7)
		part(Vector3.new(0.6, 0.24, 0.1), CFrame.new(-0.2, 0, 0), accent(skin))
		part(Vector3.new(0.22, 0.12, 0.12), CFrame.new(1.21, 0, 0), colourAt(skin, 7, 7), "Cylinder")
		part(Vector3.new(0.16, 0.07, 0.08), CFrame.new(1.28, 0.07, 0) * CFrame.Angles(0, 0, math.rad(-40)), colourAt(skin, 7, 7))
	elseif typeId == "bodkin" then
		shaft(-1.1, 1.0, 0.2, 7, 0, 0.05)
		ball(1.05, 0.16)
		part(Vector3.new(0.3, 0.06, 0.07), CFrame.new(-0.85, 0, 0), Color3.fromRGB(30, 30, 36))
	elseif typeId == "curved" then
		local n, r = 9, 0.95
		for i = 1, n do -- an arc, the point at one end and the eye at the other
			local a = math.rad(20 + (i - 0.5) * 140 / n)
			part(Vector3.new(r * math.rad(140 / n) + 0.02, 0.08, 0.08), CFrame.new(-math.cos(a) * r, math.sin(a) * r - 0.5, 0) * CFrame.Angles(0, 0, math.pi / 2 - a), colourAt(skin, i, n), "Cylinder", true) -- along the curve
		end
		ball(-math.cos(math.rad(20)) * r, 0.1, math.sin(math.rad(20)) * r - 0.5, true)
	elseif typeId == "sailmaker" then
		shaft(-1.2, 0.9, 0.14, 7)
		tip(0.9, 0.16, 3)
		part(Vector3.new(1.6, 0.03, 0.03), CFrame.new(-0.2, 0.08, 0), accent(skin))
		eye(-1.36, 0.3, 0.07, 0.13)
	elseif typeId == "swordfish" then -- the bill is the needle; a tapered body, a tall sail, a forked tail
		shaft(0.42, 1.55, 0.05, 6)
		tip(1.55, 0.05, 3)
		local body = { 0.07, 0.15, 0.24, 0.3, 0.31, 0.27, 0.18, 0.1 }
		for i, d in ipairs(body) do
			part(Vector3.new(0.23, d, d * 0.75), CFrame.new(-1.45 + i * 0.23, 0, 0), colourAt(i, #body), "Cylinder")
		end
		for k = 0, 5 do -- the sail: overlapping panels, tallest at the front, sweeping back
			local h = 0.6 - k * 0.09
			part(Vector3.new(0.16, h, 0.02), CFrame.new(-0.08 - k * 0.12, 0.28 + h / 2, 0) * CFrame.Angles(0, 0, math.rad(-14)), accent(skin), nil, true, true)
		end
		for _, s in ipairs({ -1, 1 }) do
			part(Vector3.new(0.55, 0.16, 0.02), CFrame.new(-1.42, s * 0.2, 0) * CFrame.Angles(0, 0, math.rad(s * 58)), accent(skin), nil, true, true) -- the tail
			part(Vector3.new(0.28, 0.06, 0.02), CFrame.new(-0.1, s * -0.18, 0) * CFrame.Angles(0, 0, math.rad(s * 25)), accent(skin), nil, true, true) -- side fins
		end
		part(Vector3.one * 0.07, CFrame.new(0.2, 0.06, 0.1), Color3.fromRGB(20, 20, 26), "Ball", true) -- an eye
	elseif typeId == "firework" then -- a rocket on its stick: striped tube, nose cone, fins, a spark at the end
		shaft(-1.65, -0.25, 0.05, 4)
		for i = 1, 5 do
			part(Vector3.new(0.22, 0.3, 0.3), CFrame.new(-0.2 + i * 0.2, 0, 0), colourAt(i, 5), "Cylinder")
		end
		for i = 1, 4 do -- the nose cone
			local k = 1 - i / 5
			part(Vector3.new(0.09, 0.3 * k, 0.3 * k), CFrame.new(0.94 + i * 0.08, 0, 0), accent(skin), "Cylinder")
		end
		for _, s in ipairs({ -1, 1 }) do
			part(Vector3.new(0.38, 0.34, 0.03), CFrame.new(0.0, s * 0.42, 0) * CFrame.Angles(0, 0, math.rad(s * -30)), accent(skin), nil, true, true)
		end
		for k = 0, 5 do -- sparks fizzing off the end of the stick
			local a = k / 6 * math.pi * 2
			part(Vector3.one * 0.07, CFrame.new(-1.72 + math.cos(a) * 0.16, math.sin(a) * 0.16, 0), Color3.fromRGB(255, 220, 120), "Ball", true, true)
		end
		ball(-1.72, 0.12)
	elseif typeId == "jackhammer" then -- a chisel bit for a point, a ribbed body, a motor and T-handles
		shaft(0.45, 1.45, 0.08, 4)
		part(Vector3.new(0.14, 0.14, 0.03), CFrame.new(1.52, 0, 0), colourAt(4, 4)) -- the flat chisel end
		part(Vector3.new(0.12, 0.22, 0.22), CFrame.new(0.4, 0, 0), accent(skin), "Cylinder") -- the collar
		for i = 1, 4 do
			part(Vector3.new(0.26, if i % 2 == 0 then 0.36 else 0.4, if i % 2 == 0 then 0.36 else 0.4), CFrame.new(0.4 - i * 0.25, 0, 0), colourAt(i, 4), "Cylinder")
		end
		part(Vector3.new(0.4, 0.46, 0.4), CFrame.new(-0.84, 0, 0), accent(skin)) -- the motor
		part(Vector3.new(0.22, 0.1, 0.1), CFrame.new(-1.12, 0, 0), accent(skin))
		part(Vector3.new(1.1, 0.1, 0.1), CFrame.new(-1.26, 0, 0) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(40, 40, 46), "Cylinder", true, true) -- the handle bar
		for _, s in ipairs({ -1, 1 }) do
			part(Vector3.new(0.3, 0.18, 0.18), CFrame.new(-1.26, 0, s * 0.45) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(25, 25, 30), "Cylinder", true, true) -- grips
		end
	elseif typeId == "shootingstar" then -- a five-pointed star leading a long fading trail
		local n = 9
		for i = 1, n do -- the trail, thin at the eye end and widening towards the star
			local d = 0.03 + 0.1 * (i / n)
			part(Vector3.new(2.2 / n + 0.01, d, d), CFrame.new(-1.45 + (i - 0.5) * 2.2 / n, 0, 0), colourAt(i, n), "Cylinder")
		end
		for _, s in ipairs({ -1, 1 }) do -- two thinner streaks beside it
			part(Vector3.new(1.2, 0.025, 0.025), CFrame.new(0.1, s * 0.12, 0) * CFrame.Angles(0, 0, math.rad(s * 4)), colourAt(n, n), "Cylinder", true)
		end
		local centre = CFrame.new(1.1, 0, 0)
		for k = 0, 4 do -- the points, each a long and a short bar so it tapers, in the star's own plane
			local a = math.rad(90 + k * 72)
			part(Vector3.new(0.5, 0.15, 0.07), centre * CFrame.Angles(0, 0, a) * CFrame.new(0.25, 0, 0), accent(skin), nil, true, true)
			part(Vector3.new(0.26, 0.26, 0.08), centre * CFrame.Angles(0, 0, a) * CFrame.new(0.13, 0, 0), accent(skin), nil, true, true)
		end
		part(Vector3.one * 0.34, centre, accent(skin), "Ball", true, true)
	elseif Shapes[typeId] then -- a shape kept as data: each op a shaft, a tip or one part
		for _, op in ipairs(Shapes[typeId]) do
			if op[1] == "s" then
				shaft(op[2], op[3], op[4], op[5], op[6])
			elseif op[1] == "t" then
				tip(op[2], op[3], op[4])
			else -- { "p", size x/y/z, position x/y/z, turn x/y/z (degrees), colour, part, flags }
				local c = op[11]
				local colour = if type(c) == "table" then Color3.fromRGB(c[1], c[2], c[3]) elseif c == "a" then accent(skin) else colourAt(skin, tonumber(string.match(c, "^c(%d+)")), tonumber(string.match(c, "/(%d+)$")))
				local cf = CFrame.new(op[5], op[6], op[7]) * CFrame.Angles(math.rad(op[8]), math.rad(op[9]), math.rad(op[10]))
				part(Vector3.new(op[2], op[3], op[4]), cf, colour, PART[op[12]], op[13] % 2 == 1, op[13] >= 2) -- flags: 1 keep its place, 2 keep its size
			end
		end
	else -- sewing
		shaft(-0.9, 0.85, 0.08, 6)
		tip(0.85, 0.08, 3)
		eye(-1.03, 0.24, 0.05, 0.09)
	end
	if skin.glow then
		local light = Instance.new("PointLight")
		light.Color, light.Range, light.Brightness = rgb(skin.colours[1]), 6 * scale, 1
		light.Parent = root
	end
	if skin.sparkle then
		local e = Instance.new("ParticleEmitter")
		e.Rate, e.Lifetime, e.Speed = 4, NumberRange.new(0.5, 0.9), NumberRange.new(0.2, 0.6)
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.12 * scale), NumberSequenceKeypoint.new(1, 0) })
		e.LightEmission, e.Color = 1, ColorSequence.new(Color3.new(1, 1, 1), rgb(skin.colours[2] or skin.colours[1]))
		e.Shape, e.ShapeStyle = Enum.ParticleEmitterShape.Box, Enum.ParticleEmitterShapeStyle.Volume
		root.Size = Vector3.new(2.4, 0.4, 0.4) * scale
		e.Parent = root
	end
	return model
end

return NeedleLook

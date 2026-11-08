-- The built-in portal, shaped by Config.PortalDesign (the owner designs it in the Portal Designer
-- page, which mirrors this file to show the same portal): a frame of stones following one of four
-- outlines (round moon gate, round-topped arch, square door, hexagon) on a round or square plinth
-- or none, a glowing inner lip, an opening of light in the portal's colour, a keystone gem,
-- lanterns and a sign. Frames stop at the floor, so you walk straight in.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Build = require(script.Parent.Build)
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local PortalShape = {}
local UPRIGHT = CFrame.Angles(0, 0, math.rad(90)) -- a cylinder standing on end
local FACING = CFrame.Angles(0, math.rad(90), 0) -- a cylinder whose flat side faces the players
local SIN60 = math.sin(math.rad(60))

local function floorOf(d)
	return if d.base == "none" then 0 else 1.1
end

-- The frame's centre line as blocks { x, y, length, angle } in the portal's X-Y plane (y up
-- from the ground; angle points the block's X outwards). `inset` shrinks the shape (the lip).
function PortalShape.outline(d, inset)
	local floor, blocks = floorOf(d), {}
	local cx, cy = 0, 0
	local function add(ax, ay, bx, by)
		local mx, my = (ax + bx) / 2, (ay + by) / 2
		local tx, ty = bx - ax, by - ay
		local length = math.sqrt(tx * tx + ty * ty)
		if length < 1e-3 or my < floor - 0.2 then
			return
		end
		local nx, ny = ty / length, -tx / length
		if (mx - cx) * nx + (my - cy) * ny < 0 then
			nx, ny = -nx, -ny
		end
		table.insert(blocks, { x = mx, y = my, length = length, angle = math.atan2(ny, nx) })
	end
	local function line(ax, ay, bx, by, count)
		for i = 0, count - 1 do
			add(ax + (bx - ax) * i / count, ay + (by - ay) * i / count, ax + (bx - ax) * (i + 1) / count, ay + (by - ay) * (i + 1) / count)
		end
	end
	local function arc(r, from, to, count)
		for i = 0, count - 1 do
			local a, b = from + (to - from) * i / count, from + (to - from) * (i + 1) / count
			add(cx + r * math.cos(a), cy + r * math.sin(a), cx + r * math.cos(b), cy + r * math.sin(b))
		end
	end
	if d.shape == "round" then
		cy = floor + d.radius - math.min(1.2, d.radius * 0.25)
		arc(d.radius - inset, 0, math.pi * 2, d.stones)
	elseif d.shape == "hex" then
		cy = floor + d.radius * SIN60 - 0.3
		local r, each = d.radius - inset, math.max(1, math.floor(d.stones / 6 + 0.5))
		for k = 0, 5 do
			local a, b = math.rad(60 * k), math.rad(60 * (k + 1))
			line(r * math.cos(a), cy + r * math.sin(a), r * math.cos(b), cy + r * math.sin(b), each)
		end
	else -- door or arch: two sides from the floor, joined across the top
		local w, h = d.width - 2 * inset, d.height - inset
		local top = if d.shape == "arch" then floor + h - w / 2 else floor + h
		cx, cy = 0, (floor + top) / 2
		local perimeter = 2 * (top - floor) + (if d.shape == "arch" then math.pi * w / 2 else w)
		local per = perimeter / d.stones
		local sides = math.max(1, math.floor((top - floor) / per + 0.5))
		line(-w / 2, floor, -w / 2, top, sides)
		if d.shape == "arch" then
			cy = top
			arc(w / 2, math.pi, 0, math.max(2, math.floor(math.pi * w / 2 / per + 0.5)))
		else
			line(-w / 2, top, w / 2, top, math.max(1, math.floor(w / per + 0.5)))
		end
		line(w / 2, top, w / 2, floor, sides)
	end
	return blocks
end

-- Sizes the rest of the portal is placed by: half its width, its top, and its opening.
function PortalShape.measure(d)
	local floor = floorOf(d)
	if d.shape == "round" or d.shape == "hex" then
		local cy = if d.shape == "round" then floor + d.radius - math.min(1.2, d.radius * 0.25) else floor + d.radius * SIN60 - 0.3
		local inner = (if d.shape == "round" then d.radius else d.radius * SIN60) - d.thick / 2 - 0.1
		return { half = d.radius + d.thick / 2, top = cy + d.radius + d.thick / 2, floor = floor, open = { kind = "disc", y = cy, size = 2 * inner } }
	end
	local w = d.width - d.thick
	local spring = floor + d.height - d.width / 2
	return { half = d.width / 2 + d.thick / 2, top = floor + d.height + d.thick / 2, floor = floor,
		open = { kind = d.shape, width = w, height = d.height - d.thick / 2, spring = spring } }
end

-- Builds it at `cf` in `colour`; returns the face over the opening (for Kit.trigger).
function PortalShape.build(cf, colour, parent, title, subtitle, Kit, flowOn)
	local d = Config.PortalDesign
	local m = PortalShape.measure(d)
	local model = Instance.new("Model")
	model.Name = "Portal"
	local stoneA, stoneB, material = d.stoneA, d.stoneB, d.material or "Slate"
	local span = 2 * m.half + 4
	if d.base == "round" then
		Build.part({ name = "PortalStep", shape = "Cylinder", size = Vector3.new(0.6, span, span), cframe = cf * CFrame.new(0, 0.3, 0) * UPRIGHT, color = stoneA, material = material, parent = model })
		Build.part({ name = "PortalStep", shape = "Cylinder", size = Vector3.new(0.5, span - 3, span - 3), cframe = cf * CFrame.new(0, 0.85, 0) * UPRIGHT, color = stoneB, material = material, parent = model })
	elseif d.base == "square" then
		Build.part({ name = "PortalStep", size = Vector3.new(span, 0.6, 7), cframe = cf * CFrame.new(0, 0.3, 0), color = stoneA, material = material, parent = model })
		Build.part({ name = "PortalStep", size = Vector3.new(span - 2, 0.5, 5), cframe = cf * CFrame.new(0, 0.85, 0), color = stoneB, material = material, parent = model })
	end
	for i, b in ipairs(PortalShape.outline(d, 0)) do
		Build.part({ name = "PortalStone", size = Vector3.new(d.thick, b.length + d.thick * 0.5, d.depth), cframe = cf * CFrame.new(b.x, b.y, 0) * CFrame.Angles(0, 0, b.angle), color = if i % 2 == 0 then stoneA else stoneB, material = material, parent = model })
	end
	if d.lip then
		for _, b in ipairs(PortalShape.outline(d, d.thick / 2 + 0.08)) do
			Build.part({ name = "PortalLip", size = Vector3.new(0.2, b.length + 0.1, d.depth * 0.35), cframe = cf * CFrame.new(b.x, b.y, 0) * CFrame.Angles(0, 0, b.angle), color = colour, material = "Neon", transparency = 0.15, collide = false, parent = model })
		end
	end
	local o, glow = m.open, d.glow or 0.55
	local sheets, faceY, faceW, faceH = {}, 0, 0, 0
	if o.kind == "disc" then
		table.insert(sheets, Build.part({ name = "PortalDisc", shape = "Cylinder", size = Vector3.new(0.2, o.size, o.size), cframe = cf * CFrame.new(0, o.y, 0) * FACING, color = colour, material = "Neon", transparency = glow, collide = false, parent = model }))
		faceY, faceW, faceH = o.y, o.size, o.size
	else
		local boxTop = if o.kind == "arch" then o.spring else m.floor + o.height
		table.insert(sheets, Build.part({ name = "PortalSheet", size = Vector3.new(o.width, boxTop - m.floor + 0.2, 0.2), cframe = cf * CFrame.new(0, (m.floor - 0.2 + boxTop) / 2 + 0.1, 0), color = colour, material = "Neon", transparency = glow, collide = false, parent = model }))
		if o.kind == "arch" then
			table.insert(sheets, Build.part({ name = "PortalDisc", shape = "Cylinder", size = Vector3.new(0.19, o.width, o.width), cframe = cf * CFrame.new(0, o.spring, 0) * FACING, color = colour, material = "Neon", transparency = glow, collide = false, parent = model }))
		end
		faceY, faceW, faceH = m.floor + o.height / 2, o.width, o.height
	end
	for _, sheet in ipairs(sheets) do
		flowOn(sheet, colour, if sheet.Shape == Enum.PartType.Cylinder then { Enum.NormalId.Left, Enum.NormalId.Right } else { Enum.NormalId.Front, Enum.NormalId.Back })
	end
	if d.gem then
		local gem = Build.part({ name = "PortalGem", size = Vector3.new(1.4, 1.8, 1.4), cframe = cf * CFrame.new(0, m.top + 0.4, 0) * CFrame.Angles(0, math.rad(45), 0), color = colour, material = "Neon", parent = model })
		Kit.light(gem, colour, 10, 0.6)
	end
	local spots = {}
	for _, x in ipairs({ -(m.half + 1), m.half + 1 }) do
		if d.lanterns >= 2 then
			table.insert(spots, Vector3.new(x, 0, -2.6))
		end
		if d.lanterns >= 4 then
			table.insert(spots, Vector3.new(x, 0, 2.6))
		end
	end
	for _, at in ipairs(spots) do
		Build.part({ name = "PortalPost", size = Vector3.new(0.4, 3.2, 0.4), cframe = cf * CFrame.new(at.X, m.floor + 1.6, at.Z), color = d.wood, material = "Wood", parent = model })
		local lamp = Build.part({ name = "PortalLantern", size = Vector3.new(0.8, 0.9, 0.8), cframe = cf * CFrame.new(at.X, m.floor + 3.6, at.Z), color = colour, material = "Neon", collide = false, parent = model })
		Build.part({ name = "PortalLanternCap", size = Vector3.new(1, 0.2, 1), cframe = cf * CFrame.new(at.X, m.floor + 4.15, at.Z), color = d.wood, material = "Wood", parent = model })
		Kit.light(lamp, colour, 8, 0.5)
	end
	local face = Build.part({ name = "PortalGlow", size = Vector3.new(faceW, faceH, 0.3), cframe = cf * CFrame.new(0, faceY, 0), transparency = 1, collide = false, shadow = false, parent = model })
	Kit.light(face, colour, 16, 1)
	Kit.drift(face, colour, 6, 1.2, 0.35)
	if d.sign then
		local sign = Kit.sign(cf * CFrame.new(0, m.top + (if d.gem then 2.9 else 2.0), 0), Vector3.new(math.max(9, 2 * m.half - 1), 3.2, 0.4), title .. "\n" .. subtitle, { 40, 34, 48 }, colour, model)
		sign.Material = Enum.Material.Slate
	end
	model.Parent = parent
	return face
end

return PortalShape

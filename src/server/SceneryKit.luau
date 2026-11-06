-- Shared helpers for the countryside around the plots (see Scenery): a part maker that works
-- in a local frame, the farm's warm sunset colours, and the areas the scenery keeps clear.
local Build = require(script.Parent.Build)

local Kit = {}
Kit.SCALE = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")).FarmScale

-- Pulls everything built under `root` towards the middle by Kit.SCALE: each model and loose part
-- keeps its size and turn and moves to SCALE x its position (heights stay), and animals' pens
-- shrink to match. The countryside is laid out at full size and then pulled in this way.
function Kit.compact(root)
	local k = Kit.SCALE
	local function pull(v)
		return Vector3.new(v.X * k, v.Y, v.Z * k)
	end
	for _, child in ipairs(root:GetChildren()) do
		if child:IsA("Folder") then
			Kit.compact(child)
		elseif child:IsA("Model") then
			local pivot = child:GetPivot()
			child:PivotTo(pivot - pivot.Position + pull(pivot.Position))
			for _, name in ipairs({ "PenMin", "PenMax" }) do
				local v = child:GetAttribute(name)
				if typeof(v) == "Vector3" then
					child:SetAttribute(name, pull(v))
				end
			end
		elseif child:IsA("BasePart") then
			child.CFrame = child.CFrame - child.Position + pull(child.Position)
		end
	end
end

Kit.C = {
	red = { 168, 52, 42 },
	trim = { 240, 232, 214 },
	wood = { 122, 86, 52 },
	darkWood = { 84, 58, 38 },
	plank = { 164, 120, 76 },
	roof = { 92, 70, 64 },
	cream = { 236, 222, 190 },
	stone = { 150, 140, 128 },
	metal = { 184, 184, 178 },
	black = { 44, 38, 36 },
	shadow = { 40, 28, 22 },
	hay = { 222, 184, 92 },
	pumpkin = { 232, 124, 36 },
	stem = { 92, 110, 48 },
	glow = { 255, 196, 120 },
	soil = { 104, 74, 48 },
}
Kit.AUTUMN = { { 214, 120, 40 }, { 196, 72, 44 }, { 232, 176, 54 }, { 150, 150, 58 }, { 178, 96, 40 } }

-- The countryside fills the ring between the plots (which end at 155, their fences at 156.5)
-- and the boundary fence at 245. Nothing is built nearer the centre than RING_IN.
Kit.RING_IN = 162
Kit.RING_OUT = 238

-- Areas kept clear of trees and bushes: the plots and hub, lanes, buildings, pens, fields.
-- Each is { minX, minZ, maxX, maxZ }.
Kit.KEEP_CLEAR = {
	{ -162, -162, 162, 162 }, -- plots, their fences, roads and hub
	{ -14, -262, 14, -160 }, -- north lane to the gate, its lanterns and the mailbox
	{ -195, -175, 150, -163 }, -- farmyard lane
	{ -213, -225, -171, -179 }, -- silos
	{ -150, -235, -100, -168 }, -- barn
	{ -94, -203, -61, -187 }, -- tractor and trailer
	{ -56, -224, -40, -199 }, -- bales
	{ 38, -226, 82, -176 }, -- farmhouse
	{ 89, -193, 103, -176 }, -- cart by the farmhouse
	{ 108, -228, 162, -182 }, -- chicken run
	{ 186, -234, 234, -186 }, -- windmill
	{ -238, -146, -159, 74 }, -- pig, cow and sheep pens and their lane
	{ -216, 100, -174, 148 }, -- bales and cart past the sheep
	{ -216, 192, -192, 220 }, -- water tower
	{ -134, 164, -58, 238 }, -- duck pond
	{ -34, 184, 36, 222 }, -- south meadow: bales, cart, scarecrow
	{ 38, 164, 240, 240 }, -- orchard
	{ 166, -160, 240, 160 }, -- pumpkin patch, east meadow, corn rows
}

function Kit.clear(x, z, margin)
	margin = margin or 0
	for _, r in ipairs(Kit.KEEP_CLEAR) do
		if x > r[1] - margin and x < r[3] + margin and z > r[2] - margin and z < r[4] + margin then
			return false
		end
	end
	return true
end

function Kit.model(parent, name)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

-- One anchored part at `at` (a CFrame or Vector3) in the frame `base`.
-- opts: shape, collide (default true), shadow (default true), transparency, class
function Kit.part(parent, base, name, size, at, color, material, opts)
	local spec = {}
	if opts then
		for k, v in pairs(opts) do
			spec[k] = v
		end
	end
	spec.name = name
	spec.size = size
	spec.cframe = base * (if typeof(at) == "Vector3" then CFrame.new(at) else at)
	spec.color = color
	spec.material = material or "SmoothPlastic"
	spec.parent = parent
	return Build.part(spec)
end

-- A small decoration: walk-through, and only the bigger bits cast shadows.
function Kit.bit(parent, base, name, size, at, color, material, shape)
	return Kit.part(parent, base, name, size, at, color, material, { collide = false, shape = shape, shadow = size.Magnitude > 3 })
end

-- A square beam from local point a to local point b (not straight up: use a part for that).
function Kit.beam(parent, base, name, a, b, thick, color, material, opts)
	local length = (b - a).Magnitude
	return Kit.part(parent, base, name, Vector3.new(thick, thick, length), CFrame.lookAt((a + b) / 2, b), color, material, opts)
end

-- A standing cylinder whose bottom centre is at local point `at`.
function Kit.post(parent, base, name, at, height, diameter, color, material, opts)
	local cf = CFrame.new(at + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	local o = opts or {}
	o.shape = "Cylinder"
	return Kit.part(parent, base, name, Vector3.new(height, diameter, diameter), cf, color, material, o)
end

-- A glowing lantern on a short post, with a soft warm light.
function Kit.lantern(parent, base, height)
	height = height or 7
	Kit.part(parent, base, "LanternPost", Vector3.new(0.6, height, 0.6), Vector3.new(0, height / 2, 0), Kit.C.darkWood, "Wood", { collide = false })
	Kit.bit(parent, base, "LanternCap", Vector3.new(1.6, 0.4, 1.6), Vector3.new(0, height + 1.4, 0), Kit.C.black, "Metal")
	local glow = Kit.bit(parent, base, "Lantern", Vector3.new(1.1, 1.3, 1.1), Vector3.new(0, height + 0.6, 0), Kit.C.glow, "Neon")
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 186, 116)
	light.Range = 16
	light.Brightness = 1.2
	light.Parent = glow
	return glow
end

-- A wooden sign on two posts, facing local -Z. Plain, friendly words only.
function Kit.sign(parent, base, text, width)
	width = width or 10
	for _, x in ipairs({ -width / 2 + 0.6, width / 2 - 0.6 }) do
		Kit.part(parent, base, "SignPost", Vector3.new(0.6, 6, 0.6), Vector3.new(x, 3, 0), Kit.C.darkWood, "Wood", { collide = false })
	end
	local board = Kit.part(parent, base, "SignBoard", Vector3.new(width, 2.6, 0.4), Vector3.new(0, 5, 0), { 214, 176, 118 }, "WoodPlanks", { collide = false })
	Build.text(board, Enum.NormalId.Front, text, { pixels = 30 })
	return board
end

return Kit

-- The Golden Loft: the secret level in the clouds above the hub, with its golden haystack.
-- (Each player's main pile is built on their plot by Piles.luau.)
local Build = require(script.Parent.Build)
local World = require(script.Parent.World)

local Haystack = {}

local GOLD = { { 250, 206, 70 }, { 240, 186, 50 }, { 255, 224, 110 } }

local function mound(centre, size, parent)
	local function ball(label, diameter, offset, colour)
		local part = Build.part({ name = label, shape = "Ball", size = Vector3.new(diameter, diameter, diameter), cframe = CFrame.new(centre + offset), color = colour, material = "Sand", parent = parent })
		part.Reflectance = 0.15
		return part
	end
	ball("GoldenCore", size, Vector3.new(0, size * 0.14, 0), GOLD[1])
	for i = 1, 10 do
		local a = i / 10 * math.pi * 2
		ball("GoldenLump", size * (0.5 + (i % 3) * 0.06), Vector3.new(math.cos(a) * size * 0.36, size * 0.02, math.sin(a) * size * 0.36), GOLD[i % 3 + 1])
	end
	ball("GoldenTop", size * 0.42, Vector3.new(size * 0.04, size * 0.58, -size * 0.04), GOLD[3])
end

function Haystack.build()
	local loft = Instance.new("Model")
	loft.Name = "Loft"
	Build.part({ name = "LoftFloor", size = Vector3.new(90, 2, 90), cframe = CFrame.new(World.LOFT - Vector3.new(0, 1, 0)), color = { 214, 184, 130 }, material = "WoodPlanks", parent = loft })
	for i = 0, 3 do
		local a = i / 4 * math.pi * 2
		local cf = CFrame.new(World.LOFT + Vector3.new(math.cos(a) * 44, 2.5, math.sin(a) * 44)) * CFrame.Angles(0, -a, 0)
		Build.part({ name = "LoftRail", size = Vector3.new(1, 5, 90), cframe = cf, color = { 122, 86, 52 }, material = "Wood", parent = loft })
		local lamp = Build.part({ name = "LoftLamp", size = Vector3.new(2, 2, 2), cframe = cf * CFrame.new(0, 6, 0), color = { 255, 214, 90 }, material = "Neon", parent = loft })
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 200, 80)
		light.Range = 40
		light.Brightness = 1.2
		light.Parent = lamp
	end
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		Build.part({ name = "Cloud", shape = "Ball", size = Vector3.new(44, 44, 44), cframe = CFrame.new(World.LOFT + Vector3.new(math.cos(a) * 34, -22, math.sin(a) * 34)), color = { 255, 240, 220 }, material = "Sand", collide = false, shadow = false, transparency = 0.15, parent = loft })
	end
	local pad = Build.part({ name = "LoftPad", size = Vector3.new(8, 0.4, 8), cframe = CFrame.new(World.LOFT + Vector3.new(0, 0.2, 36)), color = { 245, 200, 66 }, material = "Neon", parent = loft })
	local back = Instance.new("ProximityPrompt")
	back.ActionText = "Go back down"
	back.ObjectText = "Golden Loft"
	back.HoldDuration = 0
	back.RequiresLineOfSight = false
	back:SetAttribute("Action", "down")
	back.Parent = pad
	mound(World.LOFT + Vector3.new(0, 0, -8), 34, loft)
	loft.Parent = workspace
end

return Haystack

-- The giant haystack everyone searches, and the golden haystack of the secret Loft.
-- Progress is per player (saved), so the mounds never shrink; the HUD shows your own progress.
local Build = require(script.Parent.Build)
local World = require(script.Parent.World)

local Haystack = {}

local HAY = { { 226, 190, 92 }, { 212, 172, 76 }, { 236, 204, 112 } }
local GOLD = { { 250, 206, 70 }, { 240, 186, 50 }, { 255, 224, 110 } }

local function mound(name, centre, size, colours, parent, seed)
	local model = Instance.new("Model")
	model.Name = name
	local function ball(label, diameter, offset, colour, material)
		return Build.part({ name = label, shape = "Ball", size = Vector3.new(diameter, diameter, diameter), cframe = CFrame.new(centre + offset), color = colour, material = material or "Grass", parent = model })
	end
	local core = ball("Core", size, Vector3.new(0, size * 0.14, 0), colours[1])
	local rng = Random.new(seed)
	for i = 1, 10 do
		local a = i / 10 * math.pi * 2
		local d = size * (0.5 + (i % 3) * 0.06)
		ball("Lump", d, Vector3.new(math.cos(a) * size * 0.36, size * 0.02, math.sin(a) * size * 0.36), colours[i % 3 + 1])
	end
	ball("Top", size * 0.42, Vector3.new(size * 0.04, size * 0.58, -size * 0.04), colours[3])
	for _ = 1, 40 do
		local a = rng:NextNumber() * math.pi * 2
		local h = rng:NextNumber(size * 0.1, size * 0.62)
		local r = size * 0.48 - h * 0.45
		Build.part({
			name = "Straw",
			shape = "Cylinder",
			size = Vector3.new(rng:NextNumber(3, 6), 0.2, 0.2),
			cframe = CFrame.new(centre + Vector3.new(math.cos(a) * r, h, math.sin(a) * r)) * CFrame.Angles(rng:NextNumber(-1, 1), a, rng:NextNumber(-0.6, 0.6)),
			color = { 246, 222, 140 },
			collide = false,
			shadow = false,
			parent = model,
		})
	end
	if colours == GOLD then
		for _, part in ipairs(model:GetChildren()) do
			if part:IsA("BasePart") and part.Name ~= "Straw" then
				part.Material = Enum.Material.Sand
				part.Reflectance = 0.15
			end
		end
	end
	model.WorldPivot = CFrame.new(centre)
	model:SetAttribute("Centre", centre)
	model.Parent = parent
	return model, core
end

function Haystack.build()
	local folder = Instance.new("Folder")
	folder.Name = "Haystacks"
	folder.Parent = workspace
	mound("Haystack", World.HAYSTACK, 56, HAY, folder, 1)
	-- the Golden Loft: a platform in the clouds above the barn, reached from the loft hatch
	local loft = Instance.new("Model")
	loft.Name = "Loft"
	local floor = Build.part({ name = "LoftFloor", size = Vector3.new(90, 2, 90), cframe = CFrame.new(World.LOFT - Vector3.new(0, 1, 0)), color = { 214, 184, 130 }, material = "WoodPlanks", parent = loft })
	floor.Reflectance = 0.05
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
	local cloud = Build.part({ name = "Cloud", shape = "Ball", size = Vector3.new(130, 30, 130), cframe = CFrame.new(World.LOFT - Vector3.new(0, 16, 0)), color = { 255, 240, 220 }, material = "Sand", collide = false, transparency = 0.15, parent = loft })
	cloud.CastShadow = false
	local sign = Build.part({ name = "LoftSign", size = Vector3.new(16, 3, 0.4), cframe = CFrame.new(World.LOFT + Vector3.new(0, 8, 42)), color = { 60, 44, 30 }, material = "Wood", parent = loft })
	Build.text(sign, Enum.NormalId.Back, "THE GOLDEN LOFT: golden straw pays 20x", { color = Color3.fromRGB(245, 200, 66) })
	local pad = Build.part({ name = "LoftPad", size = Vector3.new(8, 0.4, 8), cframe = CFrame.new(World.LOFT + Vector3.new(0, 0.2, 36)), color = { 245, 200, 66 }, material = "Neon", parent = loft })
	Build.text(pad, Enum.NormalId.Top, "step here to go back down", { color = Color3.fromRGB(60, 44, 30), pixels = 24 })
	loft.Parent = folder
	mound("GoldenHaystack", World.LOFT + Vector3.new(0, 0, -8), 34, GOLD, folder, 2)
end

-- Which haystack the player can search from `position`: "hay", "gold" or nil.
function Haystack.at(position, range)
	local function near(centre, r)
		return Vector3.new(position.X - centre.X, 0, position.Z - centre.Z).Magnitude <= r and math.abs(position.Y - centre.Y) < 40
	end
	if near(World.HAYSTACK, range) then
		return "hay"
	elseif near(World.LOFT + Vector3.new(0, 0, -8), range * 0.75) then
		return "gold"
	end
	return nil
end

return Haystack

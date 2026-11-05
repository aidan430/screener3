-- Hollow Creek Farm, smaller now: four plots around a hub with the merchant, the Wheel of
-- Fortune and the golden door to the secret Golden Loft. Sunset light, fence and trees.
local Lighting = game:GetService("Lighting")

local Build = require(script.Parent.Build)

local World = {}
local terrain = workspace.Terrain
local AUTUMN = { { 214, 120, 40 }, { 196, 72, 44 }, { 232, 176, 54 }, { 150, 150, 58 } }
local WOOD = { 122, 86, 52 }

World.MERCHANT = Vector3.new(0, 0, -36) -- on the north road
World.WHEEL = Vector3.new(0, 0, 36) -- on the south road
World.DOOR = Vector3.new(36, 0, 0) -- the golden door, on the east road
World.LOFT = Vector3.new(0, 330, 0) -- the secret level floats high above the hub

local function prompt(parent, action, text, object, key)
	local p = Instance.new("ProximityPrompt")
	p.ActionText = text
	p.ObjectText = object
	p.HoldDuration = 0
	p.MaxActivationDistance = 12
	p.RequiresLineOfSight = false
	p.KeyboardKeyCode = key or Enum.KeyCode.E
	p:SetAttribute("Action", action)
	p.Parent = parent
	return p
end

function World.ground()
	terrain:SetMaterialColor(Enum.Material.LeafyGrass, Color3.fromRGB(118, 136, 58)) -- Grass is the straw heap
	terrain:SetMaterialColor(Enum.Material.Ground, Color3.fromRGB(124, 94, 62))
	terrain:SetMaterialColor(Enum.Material.Cobblestone, Color3.fromRGB(152, 138, 120))
	terrain:FillBlock(CFrame.new(0, -8, 0), Vector3.new(420, 16, 420), Enum.Material.LeafyGrass)
	terrain:FillBlock(CFrame.new(0, -2, 0), Vector3.new(30, 4, 330), Enum.Material.Ground)
	terrain:FillBlock(CFrame.new(0, -2, 0), Vector3.new(330, 4, 30), Enum.Material.Ground)
	terrain:FillCylinder(CFrame.new(0, -2, 0), 4, 22, Enum.Material.Cobblestone)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = CFrame.new(0, 0.5, 0)
	spawn.Color = Color3.fromRGB(196, 150, 92)
	spawn.Material = Enum.Material.WoodPlanks
	spawn.Duration = 0
	spawn.Neutral = true
	spawn.Parent = workspace
end

function World.lighting()
	Lighting.ClockTime = 17.4
	Lighting.Brightness = 2.2
	Lighting.Ambient = Color3.fromRGB(86, 70, 60)
	Lighting.OutdoorAmbient = Color3.fromRGB(170, 136, 112)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 196, 146)
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.6
	Lighting.GlobalShadows = true
	for _, old in ipairs(Lighting:GetChildren()) do
		if old:IsA("Atmosphere") or old:IsA("PostEffect") then
			old:Destroy()
		end
	end
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.3
	atmosphere.Offset = 0.15
	atmosphere.Color = Color3.fromRGB(255, 204, 158)
	atmosphere.Decay = Color3.fromRGB(176, 108, 78)
	atmosphere.Glare = 0.5
	atmosphere.Haze = 1.4
	atmosphere.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.5
	bloom.Size = 20
	bloom.Threshold = 1.4
	bloom.Parent = Lighting
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Saturation = 0.12
	grade.Contrast = 0.06
	grade.TintColor = Color3.fromRGB(255, 246, 234)
	grade.Parent = Lighting
end

local function fence(folder)
	local half = 165
	for _, side in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
		for i = -16, 16 do
			local along = i * 10
			local pos = if side[1] ~= 0 then Vector3.new(side[1] * half, 0, along) else Vector3.new(along, 0, side[2] * half)
			Build.part({ name = "Post", size = Vector3.new(1.2, 5, 1.2), cframe = CFrame.new(pos + Vector3.new(0, 2.5, 0)), color = WOOD, material = "Wood", parent = folder })
		end
		for _, h in ipairs({ 1.6, 3.4 }) do
			local size = if side[1] ~= 0 then Vector3.new(0.5, 0.45, half * 2) else Vector3.new(half * 2, 0.45, 0.5)
			Build.part({ name = "Rail", size = size, cframe = CFrame.new(side[1] * half, h, side[2] * half), color = WOOD, material = "Wood", parent = folder })
		end
	end
end

local function trees(folder)
	local rng = Random.new(7)
	for i = 1, 36 do
		local a = i / 36 * math.pi * 2
		local r = rng:NextNumber(185, 205)
		local base = CFrame.new(math.cos(a) * r, 0, math.sin(a) * r)
		local height = rng:NextNumber(10, 16)
		Build.post({ name = "Trunk", color = { 96, 66, 44 }, material = "Wood", parent = folder }, base, height, 2.6)
		for _ = 1, 3 do
			local size = rng:NextNumber(10, 16)
			local offset = Vector3.new(rng:NextNumber(-4, 4), height + rng:NextNumber(0, 5), rng:NextNumber(-4, 4))
			Build.part({ name = "Leaves", shape = "Ball", size = Vector3.new(size, size, size), cframe = base * CFrame.new(offset), color = AUTUMN[rng:NextInteger(1, #AUTUMN)], material = "Grass", parent = folder })
		end
	end
end

local function merchant(folder)
	local cf = CFrame.lookAt(World.MERCHANT, Vector3.new(0, 0, 0))
	Build.part({ name = "Counter", size = Vector3.new(12, 3.6, 3), cframe = cf * CFrame.new(0, 1.8, -1), color = { 150, 104, 60 }, material = "WoodPlanks", parent = folder })
	for _, x in ipairs({ -5.5, 5.5 }) do
		Build.part({ name = "StallPost", size = Vector3.new(0.7, 10, 0.7), cframe = cf * CFrame.new(x, 5, 3), color = WOOD, material = "Wood", parent = folder })
	end
	local awning = Build.part({ name = "Awning", size = Vector3.new(14, 0.4, 9), cframe = cf * CFrame.new(0, 10.2, 1) * CFrame.Angles(math.rad(-8), 0, 0), color = { 200, 60, 50 }, material = "Fabric", parent = folder })
	for i = 0, 6 do
		Build.part({ name = "Stripe", size = Vector3.new(1, 0.42, 9), cframe = awning.CFrame * CFrame.new(-6 + i * 2, 0, 0), color = { 246, 240, 226 }, material = "Fabric", parent = folder })
	end
	local body = cf * CFrame.new(0, 0, 3)
	Build.part({ name = "MerchantBody", size = Vector3.new(2.4, 3.2, 1.4), cframe = body * CFrame.new(0, 3.6, 0), color = { 80, 110, 70 }, material = "Fabric", parent = folder })
	local head = Build.part({ name = "MerchantHead", shape = "Ball", size = Vector3.new(1.8, 1.8, 1.8), cframe = body * CFrame.new(0, 6.1, 0), color = { 230, 190, 150 }, parent = folder })
	Build.part({ name = "MerchantHat", shape = "Cylinder", size = Vector3.new(0.3, 3.4, 3.4), cframe = body * CFrame.new(0, 6.9, 0) * CFrame.Angles(0, 0, math.rad(90)), color = { 112, 84, 48 }, material = "Fabric", parent = folder })
	local coins = Build.part({ name = "CoinPile", shape = "Ball", size = Vector3.new(1.4, 1.4, 1.4), cframe = cf * CFrame.new(3, 4.1, -1), color = { 245, 200, 66 }, material = "Metal", parent = folder })
	coins.Reflectance = 0.3
	prompt(head, "sell", "Sell your straw", "Hay Merchant")
end

local function wheel(folder)
	local cf = CFrame.lookAt(World.WHEEL, Vector3.new(0, 0, 0))
	Build.part({ name = "WheelStand", size = Vector3.new(2, 14, 2), cframe = cf * CFrame.new(0, 7, 1.5), color = WOOD, material = "Wood", parent = folder })
	local disc = Build.part({ name = "WheelDisc", shape = "Cylinder", size = Vector3.new(0.6, 16, 16), cframe = cf * CFrame.new(0, 13, 0) * CFrame.Angles(0, math.rad(90), 0), color = { 245, 200, 66 }, material = "SmoothPlastic", parent = folder })
	Build.part({ name = "WheelPointer", size = Vector3.new(1, 2.4, 0.6), cframe = cf * CFrame.new(0, 21.6, -0.6), color = { 200, 50, 50 }, material = "Neon", parent = folder })
	local sign = Build.part({ name = "WheelSign", size = Vector3.new(14, 2.4, 0.4), cframe = cf * CFrame.new(0, 2.4, -1), color = { 246, 234, 204 }, material = "WoodPlanks", parent = folder })
	Build.text(sign, Enum.NormalId.Front, "WHEEL OF FORTUNE: odds shown before you spin")
	prompt(disc, "wheel", "See the wheel", "Wheel of Fortune")
end

local function door(folder)
	local cf = CFrame.lookAt(World.DOOR, Vector3.new(0, 0, 0))
	for _, x in ipairs({ -4, 4 }) do
		Build.part({ name = "DoorPost", size = Vector3.new(1.2, 12, 1.2), cframe = cf * CFrame.new(x, 6, 0), color = { 200, 160, 60 }, material = "Metal", parent = folder })
	end
	Build.part({ name = "DoorTop", size = Vector3.new(9.2, 1.2, 1.4), cframe = cf * CFrame.new(0, 12.6, 0), color = { 200, 160, 60 }, material = "Metal", parent = folder })
	local panel = Build.part({ name = "GoldenDoor", size = Vector3.new(6.8, 11, 0.5), cframe = cf * CFrame.new(0, 5.5, 0), color = { 255, 214, 90 }, material = "Neon", transparency = 0.25, parent = folder })
	Build.text(panel, Enum.NormalId.Front, "THE GOLDEN LOFT\n???", { color = Color3.fromRGB(110, 70, 20), pixels = 30 })
	prompt(panel, "loft", "Enter", "Golden Door")
end

function World.build()
	World.lighting()
	local farm = Instance.new("Folder")
	farm.Name = "Farm"
	farm.Parent = workspace
	fence(farm)
	trees(farm)
	merchant(farm)
	wheel(farm)
	door(farm)
	for i = 0, 3 do
		local a = i / 4 * math.pi * 2 + math.pi / 4
		local base = CFrame.new(math.cos(a) * 19, 0, math.sin(a) * 19)
		Build.post({ name = "LampPost", color = { 52, 48, 46 }, material = "Metal", parent = farm }, base, 9, 0.6)
		local lamp = Build.part({ name = "Lamp", size = Vector3.new(1.6, 1.6, 1.6), cframe = base * CFrame.new(0, 9.6, 0), color = { 255, 196, 110 }, material = "Neon", parent = farm })
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 190, 120)
		light.Range = 22
		light.Brightness = 1.6
		light.Parent = lamp
	end
end

return World

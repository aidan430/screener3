-- Hollow Creek Farm at sunset: terrain, plaza, the merchant's stall, the machine yard, the
-- barn with the Golden Loft above it, fence and trees. The haystacks are in Haystack.luau.
local Lighting = game:GetService("Lighting")

local Build = require(script.Parent.Build)

local World = {}
local terrain = workspace.Terrain
local AUTUMN = { { 214, 120, 40 }, { 196, 72, 44 }, { 232, 176, 54 }, { 150, 150, 58 } }
local WOOD = { 122, 86, 52 }

World.HAYSTACK = Vector3.new(0, 0, -110) -- the giant haystack, north of the plaza
World.MERCHANT = Vector3.new(74, 0, 10) -- the merchant's stall, east
World.YARD = Vector3.new(-80, 0, 0) -- the machine yard, west
World.BARN = Vector3.new(0, 0, 96) -- the barn, south; the Golden Loft is above it
World.LOFT = Vector3.new(0, 130, 96) -- the secret level floats high above the barn

function World.ground()
	terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(118, 136, 58))
	terrain:SetMaterialColor(Enum.Material.Ground, Color3.fromRGB(124, 94, 62))
	terrain:SetMaterialColor(Enum.Material.Cobblestone, Color3.fromRGB(152, 138, 120))
	terrain:FillBlock(CFrame.new(0, -8, 0), Vector3.new(640, 16, 640), Enum.Material.Grass)
	terrain:FillCylinder(CFrame.new(0, -2, 0), 4, 30, Enum.Material.Cobblestone)
	for _, target in ipairs({ World.HAYSTACK, World.MERCHANT, World.YARD, World.BARN }) do
		local dir = Vector3.new(target.X, 0, target.Z).Unit
		local from, to = dir * 28 + Vector3.new(0, -2, 0), target - dir * 20 + Vector3.new(0, -2, 0)
		terrain:FillBlock(CFrame.lookAt((from + to) / 2, to), Vector3.new(7, 4, (to - from).Magnitude), Enum.Material.Ground)
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.CFrame = CFrame.new(0, 0.5, 16) -- faces north, towards the haystack
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
	atmosphere.Density = 0.32
	atmosphere.Offset = 0.2
	atmosphere.Color = Color3.fromRGB(255, 204, 158)
	atmosphere.Decay = Color3.fromRGB(176, 108, 78)
	atmosphere.Glare = 0.5
	atmosphere.Haze = 1.6
	atmosphere.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.5
	bloom.Size = 20
	bloom.Threshold = 1.4
	bloom.Parent = Lighting
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Saturation = 0.1
	grade.Contrast = 0.06
	grade.TintColor = Color3.fromRGB(255, 246, 234)
	grade.Parent = Lighting
end

local function fence(folder)
	local count, radius = 56, 200
	for i = 0, count - 1 do
		local a, b = i / count * math.pi * 2, (i + 1) / count * math.pi * 2
		local p = Vector3.new(math.cos(a) * radius, 0, math.sin(a) * radius)
		local q = Vector3.new(math.cos(b) * radius, 0, math.sin(b) * radius)
		Build.part({ name = "Post", size = Vector3.new(1.2, 5, 1.2), cframe = CFrame.new(p + Vector3.new(0, 2.5, 0)), color = WOOD, material = "Wood", parent = folder })
		for _, h in ipairs({ 1.6, 3.4 }) do
			local mid = (p + q) / 2 + Vector3.new(0, h, 0)
			Build.part({ name = "Rail", size = Vector3.new(0.5, 0.45, (q - p).Magnitude), cframe = CFrame.lookAt(mid, q + Vector3.new(0, h, 0)), color = WOOD, material = "Wood", parent = folder })
		end
	end
end

local function trees(folder)
	local rng = Random.new(7)
	for i = 1, 40 do
		local a = i / 40 * math.pi * 2 + rng:NextNumber(-0.05, 0.05)
		local r = rng:NextNumber(218, 275)
		local base = CFrame.new(math.cos(a) * r, 0, math.sin(a) * r)
		local height = rng:NextNumber(10, 16)
		Build.post({ name = "Trunk", color = { 96, 66, 44 }, material = "Wood", parent = folder }, base, height, 2.6)
		for _ = 1, 3 do
			local size = rng:NextNumber(10, 17)
			local offset = Vector3.new(rng:NextNumber(-4, 4), height + rng:NextNumber(0, 5), rng:NextNumber(-4, 4))
			Build.part({ name = "Leaves", shape = "Ball", size = Vector3.new(size, size, size), cframe = base * CFrame.new(offset), color = AUTUMN[rng:NextInteger(1, #AUTUMN)], material = "Grass", parent = folder })
		end
	end
end

local function plaza(folder)
	for i = 0, 3 do
		local a = i / 4 * math.pi * 2 + math.pi / 4
		local base = CFrame.new(math.cos(a) * 24, 0, math.sin(a) * 24)
		Build.post({ name = "LampPost", color = { 52, 48, 46 }, material = "Metal", parent = folder }, base, 9, 0.6)
		local lamp = Build.part({ name = "Lamp", size = Vector3.new(1.6, 1.6, 1.6), cframe = base * CFrame.new(0, 9.6, 0), color = { 255, 196, 110 }, material = "Neon", parent = folder })
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 190, 120)
		light.Range = 22
		light.Brightness = 1.6
		light.Parent = lamp
	end
	local signs = { { "HAYSTACK", World.HAYSTACK }, { "MERCHANT", World.MERCHANT }, { "MACHINE YARD", World.YARD }, { "BARN", World.BARN } }
	Build.post({ name = "Signpost", color = WOOD, material = "Wood", parent = folder }, CFrame.new(0, 0, -4), 11, 1)
	for i, sign in ipairs(signs) do
		local towards = Vector3.new(sign[2].X, 0, sign[2].Z).Unit
		local cf = CFrame.lookAt(Vector3.new(0, 10.4 - i * 1.4, -4) + towards * 4.4, Vector3.new(0, 10.4 - i * 1.4, -4) + towards * 20)
		local board = Build.part({ name = sign[1], size = Vector3.new(8, 1.3, 0.35), cframe = cf, color = { 214, 184, 130 }, material = "WoodPlanks", parent = folder })
		Build.text(board, Enum.NormalId.Front, sign[1])
		Build.text(board, Enum.NormalId.Back, sign[1])
	end
end

local function merchant(folder)
	local cf = CFrame.lookAt(World.MERCHANT, Vector3.new(0, 0, World.MERCHANT.Z)) -- the counter faces the plaza
	Build.part({ name = "Counter", size = Vector3.new(12, 3.6, 3), cframe = cf * CFrame.new(0, 1.8, -3), color = { 150, 104, 60 }, material = "WoodPlanks", parent = folder })
	for _, x in ipairs({ -5.5, 5.5 }) do
		Build.part({ name = "StallPost", size = Vector3.new(0.7, 10, 0.7), cframe = cf * CFrame.new(x, 5, 2), color = WOOD, material = "Wood", parent = folder })
	end
	local awning = Build.part({ name = "Awning", size = Vector3.new(14, 0.4, 9), cframe = cf * CFrame.new(0, 10.2, -1) * CFrame.Angles(math.rad(-8), 0, 0), color = { 200, 60, 50 }, material = "Fabric", parent = folder })
	for i = 0, 6 do
		Build.part({ name = "Stripe", size = Vector3.new(1, 0.42, 9), cframe = awning.CFrame * CFrame.new(-6 + i * 2, 0, 0), color = { 246, 240, 226 }, material = "Fabric", parent = folder })
	end
	local sign = Build.part({ name = "MerchantSign", size = Vector3.new(10, 2, 0.4), cframe = cf * CFrame.new(0, 7.2, 2), color = { 246, 234, 204 }, material = "WoodPlanks", parent = folder })
	Build.text(sign, Enum.NormalId.Front, "HAY MERCHANT: straw bought here")
	-- the merchant himself
	local body = cf * CFrame.new(0, 0, 5)
	Build.part({ name = "MerchantBody", size = Vector3.new(2.4, 3.2, 1.4), cframe = body * CFrame.new(0, 3.6, 0), color = { 80, 110, 70 }, material = "Fabric", parent = folder })
	Build.part({ name = "MerchantHead", shape = "Ball", size = Vector3.new(1.8, 1.8, 1.8), cframe = body * CFrame.new(0, 6.1, 0), color = { 230, 190, 150 }, parent = folder })
	Build.part({ name = "MerchantHat", shape = "Cylinder", size = Vector3.new(0.3, 3.4, 3.4), cframe = body * CFrame.new(0, 6.9, 0) * CFrame.Angles(0, 0, math.rad(90)), color = { 112, 84, 48 }, material = "Fabric", parent = folder })
	for _, x in ipairs({ -1.9, 1.9 }) do
		Build.part({ name = "MerchantLeg", size = Vector3.new(0.9, 2, 0.9), cframe = body * CFrame.new(x * 0.4, 1, 0), color = { 60, 50, 44 }, material = "Fabric", parent = folder })
	end
	Build.part({ name = "Scales", size = Vector3.new(2, 0.3, 1.2), cframe = cf * CFrame.new(-3, 3.75, -3), color = { 200, 170, 80 }, material = "Metal", parent = folder })
	local coins = Build.part({ name = "CoinPile", shape = "Ball", size = Vector3.new(1.6, 1, 1.6), cframe = cf * CFrame.new(3, 3.9, -3), color = { 245, 200, 66 }, material = "Metal", parent = folder })
	coins.Reflectance = 0.3
end

local function yard(folder)
	local cf = CFrame.new(World.YARD)
	terrain:FillBlock(cf * CFrame.new(0, -2, 0), Vector3.new(44, 4, 34), Enum.Material.Ground)
	for _, z in ipairs({ -17, 17 }) do
		Build.part({ name = "YardRail", size = Vector3.new(44, 0.5, 0.5), cframe = cf * CFrame.new(0, 2.4, z), color = WOOD, material = "Wood", parent = folder })
	end
	local sign = Build.part({ name = "YardSign", size = Vector3.new(12, 2.2, 0.4), cframe = cf * CFrame.new(0, 7, -17) , color = { 246, 234, 204 }, material = "WoodPlanks", parent = folder })
	Build.text(sign, Enum.NormalId.Front, "MACHINE YARD: your machines work here")
	Build.text(sign, Enum.NormalId.Back, "MACHINE YARD")
	for _, x in ipairs({ -6, 6 }) do
		Build.part({ name = "SignPost", size = Vector3.new(0.6, 7, 0.6), cframe = cf * CFrame.new(x, 3.5, -17), color = WOOD, material = "Wood", parent = folder })
	end
end

local function barn(folder)
	local cf = CFrame.lookAt(World.BARN, Vector3.new(0, 0, 0)) -- the doors face the plaza
	Build.part({ name = "BarnWalls", size = Vector3.new(30, 18, 22), cframe = cf * CFrame.new(0, 9, 0), color = { 176, 52, 40 }, material = "WoodPlanks", parent = folder })
	Build.roof({ name = "BarnRoof", color = { 86, 62, 52 }, material = "Slate", parent = folder }, cf * CFrame.new(0, 18, 0) * CFrame.Angles(0, math.rad(90), 0), 32, 21.9)
	Build.part({ name = "BarnDoorFrame", size = Vector3.new(10, 12, 0.3), cframe = cf * CFrame.new(0, 6, -11.1), color = { 240, 232, 214 }, material = "WoodPlanks", parent = folder })
	Build.part({ name = "BarnDoor", size = Vector3.new(8.6, 10.6, 0.3), cframe = cf * CFrame.new(0, 5.8, -11.2), color = { 150, 42, 34 }, material = "WoodPlanks", parent = folder })
	-- the loft hatch: the way up to the Golden Loft (the client opens it once all ten achievements are done)
	local hatch = Build.part({ name = "LoftHatch", size = Vector3.new(5, 5, 0.4), cframe = cf * CFrame.new(0, 14.5, -11.2), color = { 60, 44, 30 }, material = "Wood", parent = folder })
	Build.text(hatch, Enum.NormalId.Front, "GOLDEN LOFT\n10 achievements open it", { color = Color3.fromRGB(245, 200, 66), pixels = 30 })
	local window = Build.part({ name = "LoftGlow", size = Vector3.new(4, 4, 0.2), cframe = cf * CFrame.new(0, 14.5, -11.45), color = { 255, 214, 90 }, material = "Neon", transparency = 0.6, collide = false, parent = folder })
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 200, 80)
	light.Range = 18
	light.Brightness = 0.8
	light.Parent = window
end

function World.build()
	World.lighting()
	local farm = Instance.new("Folder")
	farm.Name = "Farm"
	farm.Parent = workspace
	fence(farm)
	trees(farm)
	plaza(farm)
	merchant(farm)
	yard(farm)
	barn(farm)
end

return World

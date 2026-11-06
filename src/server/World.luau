-- Hollow Creek Farm: four plots around a hub with the merchant, the Wheel of Fortune and the
-- golden door to the secret Golden Loft. Sunset light, and a close ring of countryside (see
-- Scenery) packed round the plots, inside the fence and tree line.
local Lighting = game:GetService("Lighting")

local Build = require(script.Parent.Build)
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local World = {}
local terrain = workspace.Terrain
local AUTUMN = { { 214, 120, 40 }, { 196, 72, 44 }, { 232, 176, 54 }, { 150, 150, 58 } }
local WOOD = { 122, 86, 52 }
local GROUND = math.floor(520 * Config.FarmScale) -- the ground is GROUND x GROUND studs
local FENCE = math.floor(245 * Config.FarmScale) -- the boundary fence, this far from the middle

-- The haystack stands in the middle now, so these stand round it, facing it.
World.MERCHANT = Vector3.new(-50, 0, 62) -- west of where you arrive, clear of the Robux pads
World.WHEEL = Vector3.new(50, 0, 62) -- east of where you arrive, clear of the Robux pads
World.DOOR = Vector3.new(86, 0, 0) -- the golden door, on the east road
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
	-- Terrain Grass is kept for the straw heaps, so the fields are LeafyGrass in an autumn green.
	local g = if Config.GroundTexture ~= "" then Config.GroundTint else { 118, 136, 58 }
	terrain:SetMaterialColor(Enum.Material.LeafyGrass, Color3.fromRGB(g[1], g[2], g[3]))
	terrain:SetMaterialColor(Enum.Material.Ground, Color3.fromRGB(124, 94, 62))
	terrain:SetMaterialColor(Enum.Material.Cobblestone, Color3.fromRGB(152, 138, 120))
	terrain:FillBlock(CFrame.new(0, -8, 0), Vector3.new(GROUND, 16, GROUND), Enum.Material.LeafyGrass)
	terrain:FillBlock(CFrame.new(0, -2, 0), Vector3.new(24, 4, FENCE * 2), Enum.Material.Ground)
	terrain:FillBlock(CFrame.new(0, -2, 0), Vector3.new(FENCE * 2, 4, 24), Enum.Material.Ground)
	terrain:FillCylinder(CFrame.new(0, -2, 0), 4, 58, Enum.Material.Cobblestone) -- the yard the haystack stands in
	-- a few soft hills just past the edge of the ground, so the world fades into countryside
	local rng = Random.new(11)
	for i = -2, 2 do
		for _, side in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
			local along = i * 120 + rng:NextNumber(-12, 12)
			local out = GROUND / 2 + 45 -- low enough at the fence that it stays clear
			local centre = if side[1] ~= 0 then Vector3.new(side[1] * out, -40, along) else Vector3.new(along, -40, side[2] * out)
			terrain:FillBall(centre, rng:NextNumber(58, 72), Enum.Material.LeafyGrass)
		end
	end
	for _, c in ipairs({ { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }) do
		terrain:FillBall(Vector3.new(c[1] * (GROUND / 2 + 30), -40, c[2] * (GROUND / 2 + 30)), rng:NextNumber(62, 70), Enum.Material.LeafyGrass)
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = CFrame.new(Config.FarmEntrance[1], 0.5, Config.FarmEntrance[3] + 10) -- south of the haystack
	spawn.Color = Color3.fromRGB(196, 150, 92)
	spawn.Material = Enum.Material.WoodPlanks
	spawn.Duration = 0
	spawn.Neutral = true
	spawn.Parent = workspace
end

function World.lighting()
	-- a golden late afternoon: warm, but neutral enough that straw looks like straw (the old
	-- pink-orange sunset light turned the haystacks salmon-pink in the shade)
	Lighting.ClockTime = 16.2
	Lighting.Brightness = 2.4
	Lighting.Ambient = Color3.fromRGB(80, 78, 72)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 146, 134)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 236, 205)
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
	atmosphere.Color = Color3.fromRGB(240, 226, 200)
	atmosphere.Decay = Color3.fromRGB(150, 132, 110)
	atmosphere.Glare = 0.4
	atmosphere.Haze = 0.9
	atmosphere.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.5
	bloom.Size = 20
	bloom.Threshold = 1.4
	bloom.Parent = Lighting
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Saturation = 0.12
	grade.Contrast = 0.06
	grade.TintColor = Color3.fromRGB(255, 250, 240)
	grade.Parent = Lighting
end

local function fence(folder)
	local gate = 14 -- a gap where the north lane leaves the farm
	for _, side in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
		local gated = side[2] == -1
		local count = math.ceil(FENCE / 10)
		for i = -count, count do
			local along = i * FENCE / count
			if not (gated and math.abs(along) < gate) then
				local pos = if side[1] ~= 0 then Vector3.new(side[1] * FENCE, 0, along) else Vector3.new(along, 0, side[2] * FENCE)
				Build.part({ name = "Post", size = Vector3.new(1.2, 5, 1.2), cframe = CFrame.new(pos + Vector3.new(0, 2.5, 0)), color = WOOD, material = "Wood", parent = folder })
			end
		end
		local spans = if gated then { { -FENCE, -gate }, { gate, FENCE } } else { { -FENCE, FENCE } }
		for _, span in ipairs(spans) do
			local mid, length = (span[1] + span[2]) / 2, span[2] - span[1]
			for _, h in ipairs({ 1.6, 3.4 }) do
				local size = if side[1] ~= 0 then Vector3.new(0.5, 0.45, length) else Vector3.new(length, 0.45, 0.5)
				local at = if side[1] ~= 0 then Vector3.new(side[1] * FENCE, h, mid) else Vector3.new(mid, h, side[2] * FENCE)
				Build.part({ name = "Rail", size = size, cframe = CFrame.new(at), color = WOOD, material = "Wood", parent = folder })
			end
		end
	end
end

-- The tree line: a band of autumn trees just outside the fence, against the hills.
local function trees(folder)
	local rng = Random.new(7)
	local half = GROUND / 2
	for i = 1, 112 do
		local depth = rng:NextNumber(FENCE + 5, half - 2)
		local along = rng:NextNumber(-half + 2, half - 2)
		local side = i % 4
		local x, z = if side < 2 then (side * 2 - 1) * depth else along, if side < 2 then along else (side * 2 - 5) * depth
		if not (z < 0 and math.abs(x) < 24) then -- keep the north lane clear
			local base = CFrame.new(x, 0, z)
			local height = rng:NextNumber(10, 18)
			Build.post({ name = "Trunk", color = { 96, 66, 44 }, material = "Wood", parent = folder }, base, height, rng:NextNumber(2.2, 3.2))
			for _ = 1, 3 do
				local size = rng:NextNumber(10, 17)
				local offset = Vector3.new(rng:NextNumber(-4, 4), height + rng:NextNumber(0, 5), rng:NextNumber(-4, 4))
				Build.part({ name = "Leaves", shape = "Ball", size = Vector3.new(size, size, size), cframe = base * CFrame.new(offset), color = AUTUMN[rng:NextInteger(1, #AUTUMN)], material = "Fabric", parent = folder })
			end
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
	for i = 0, 7 do -- lamps in a ring round the haystack
		local a = i / 8 * math.pi * 2 + math.pi / 8
		local base = CFrame.new(math.cos(a) * 62, 0, math.sin(a) * 62)
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

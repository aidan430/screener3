-- Hollow Creek Farm at sunset: terrain, plaza, paths, fence, trees, signpost and the notice
-- board. The landmarks beside each haystack come from Landmarks.
local Lighting = game:GetService("Lighting")

local Build = require(script.Parent.Build)
local Landmarks = require(script.Parent.Landmarks)

local World = {}
local notice = {}

local terrain = workspace.Terrain
local AUTUMN = { { 214, 120, 40 }, { 196, 72, 44 }, { 232, 176, 54 }, { 150, 150, 58 } }
local WOOD = { 122, 86, 52 }

-- Ground and the spawn point come first, so nobody spawns into the void.
function World.ground()
	terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(118, 136, 58))
	terrain:SetMaterialColor(Enum.Material.Ground, Color3.fromRGB(124, 94, 62))
	terrain:SetMaterialColor(Enum.Material.Cobblestone, Color3.fromRGB(152, 138, 120))
	terrain:FillBlock(CFrame.new(0, -8, 0), Vector3.new(640, 16, 640), Enum.Material.Grass)
	terrain:FillCylinder(CFrame.new(0, -2, 0), 4, 34, Enum.Material.Cobblestone)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.CFrame = CFrame.new(0, 0.5, 20) -- faces north, towards the notice board
	spawn.Color = Color3.fromRGB(196, 150, 92)
	spawn.Material = Enum.Material.WoodPlanks
	spawn.Duration = 0
	spawn.Neutral = true
	spawn.TopSurface = Enum.SurfaceType.Smooth
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
	local rays = Instance.new("SunRaysEffect")
	rays.Intensity = 0.06
	rays.Spread = 0.5
	rays.Parent = Lighting
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Saturation = 0.1
	grade.Contrast = 0.06
	grade.TintColor = Color3.fromRGB(255, 246, 234)
	grade.Parent = Lighting
end

local function paths(piles)
	for _, pile in ipairs(piles) do
		local target = Vector3.new(pile.x, -2, pile.z)
		local dir = Vector3.new(pile.x, 0, pile.z).Unit
		local from = dir * 30 + Vector3.new(0, -2, 0)
		local to = target - dir * 16
		terrain:FillBlock(CFrame.lookAt((from + to) / 2, to), Vector3.new(7, 4, (to - from).Magnitude), Enum.Material.Ground)
	end
end

local function fence(folder)
	local count, radius = 56, 214
	for i = 0, count - 1 do
		local a = i / count * math.pi * 2
		local b = (i + 1) / count * math.pi * 2
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
		local r = rng:NextNumber(232, 290)
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
	-- signpost in the middle, one arm per side of the farm
	Build.post({ name = "Signpost", color = WOOD, material = "Wood", parent = folder }, CFrame.new(0, 0, 0), 12, 1)
	local arms = { { "NORTH", -90, 10.6 }, { "EAST", 0, 9.4 }, { "SOUTH", 90, 8.2 }, { "WEST", 180, 7 } }
	for _, arm in ipairs(arms) do
		local cf = CFrame.new(0, arm[3], 0) * CFrame.Angles(0, math.rad(-arm[2]), 0) * CFrame.new(4.6, 0, 0)
		local board = Build.part({ name = arm[1], size = Vector3.new(8, 1.5, 0.35), cframe = cf, color = { 214, 184, 130 }, material = "WoodPlanks", parent = folder })
		Build.text(board, Enum.NormalId.Front, arm[1] .. " FIELDS")
		Build.text(board, Enum.NormalId.Back, arm[1] .. " FIELDS")
	end
	-- lamps around the plaza
	for i = 0, 3 do
		local a = i / 4 * math.pi * 2 + math.pi / 4
		local base = CFrame.new(math.cos(a) * 26, 0, math.sin(a) * 26)
		Build.post({ name = "LampPost", color = { 52, 48, 46 }, material = "Metal", parent = folder }, base, 9, 0.6)
		local lamp = Build.part({ name = "Lamp", size = Vector3.new(1.6, 1.6, 1.6), cframe = base * CFrame.new(0, 9.6, 0), color = { 255, 196, 110 }, material = "Neon", parent = folder })
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 190, 120)
		light.Range = 22
		light.Brightness = 1.6
		light.Parent = lamp
	end
	-- a few hay bales to sit on
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		local cf = CFrame.new(math.cos(a) * 20, 1.5, math.sin(a) * 20) * CFrame.Angles(0, -a, 0)
		Build.part({ name = "Bale", size = Vector3.new(5, 3, 3), cframe = cf, color = { 220, 184, 96 }, material = "Grass", parent = folder })
	end
	-- the notice board shows the current case
	local boardCf = CFrame.lookAt(Vector3.new(0, 7, -14), Vector3.new(0, 7, 20))
	for _, x in ipairs({ -7.4, 7.4 }) do
		Build.part({ name = "BoardLeg", size = Vector3.new(0.8, 12, 0.8), cframe = boardCf * CFrame.new(x, -1, 0.4), color = WOOD, material = "Wood", parent = folder })
	end
	local board = Build.part({ name = "NoticeBoard", size = Vector3.new(14, 8, 0.5), cframe = boardCf, color = { 92, 64, 40 }, material = "WoodPlanks", parent = folder })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.LightInfluence = 0.5
	gui.Parent = board
	local paper = Instance.new("Frame")
	paper.Size = UDim2.new(1, -30, 1, -30)
	paper.Position = UDim2.fromOffset(15, 15)
	paper.BackgroundColor3 = Color3.fromRGB(246, 234, 204)
	paper.Parent = gui
	local function line(name, y, height, font, size)
		local label = Instance.new("TextLabel")
		label.Name = name
		label.Size = UDim2.new(1, -30, height, 0)
		label.Position = UDim2.new(0, 15, y, 0)
		label.BackgroundTransparency = 1
		label.Font = font
		label.TextScaled = true
		label.TextWrapped = true
		label.TextColor3 = Color3.fromRGB(58, 38, 22)
		label.Text = ""
		local limit = Instance.new("UITextSizeConstraint")
		limit.MaxTextSize = size
		limit.Parent = label
		label.Parent = paper
		return label
	end
	notice.case = line("Case", 0.05, 0.14, Enum.Font.FredokaOne, 40)
	notice.title = line("Title", 0.2, 0.18, Enum.Font.FredokaOne, 64)
	notice.intro = line("Intro", 0.42, 0.34, Enum.Font.Gotham, 34)
	notice.help = line("Help", 0.8, 0.14, Enum.Font.GothamBold, 30)
	notice.help.Text = "Search any haystack. Every search can turn up a clue."
end

function World.setNotice(number, title, intro)
	if notice.case then
		notice.case.Text = "CASE #" .. number
		notice.title.Text = title
		notice.intro.Text = intro
	end
end

function World.build(piles)
	World.lighting()
	local farm = Instance.new("Folder")
	farm.Name = "Farm"
	farm.Parent = workspace
	paths(piles)
	fence(farm)
	trees(farm)
	plaza(farm)
	local landmarks = Instance.new("Folder")
	landmarks.Name = "Landmarks"
	landmarks.Parent = workspace
	for _, pile in ipairs(piles) do
		Landmarks.build(pile, landmarks)
	end
end

return World

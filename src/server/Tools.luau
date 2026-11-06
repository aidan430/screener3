-- The search tools: one Tool per level, built in its own shape (ToolParts, ToolGadgets) or
-- wearing an uploaded model (ToolLook), coloured from Config.Tools or the equipped skin.
-- The tool goes in StarterGear too, so players keep it when they respawn.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local HayLook = require(Shared:WaitForChild("HayLook"))(Config)
local Build = require(script.Parent.Build)
local ToolLook = require(script.Parent.ToolLook)
local ToolParts = require(script.Parent.ToolParts)
local ToolGadgets = require(script.Parent.ToolGadgets)

local Tools = {}

-- A skin on any tool: an uploaded model loses its own texture and takes the skin's colour and
-- material (so the Galaxy, Lava... skins show on it too), and every skinned tool gives off a
-- gentle sparkle in the skin's colour.
function Tools.wearSkin(tool, look, skin)
	local c = Build.rgb(skin.head)
	local texture = skin.texture or ""
	if texture ~= "" then
		-- a patterned skin: the uploaded texture wraps the model; built-in forks get it on every face
		for _, part in ipairs(tool:GetDescendants()) do
			if part:IsA("SurfaceAppearance") then
				part:Destroy()
			elseif part:IsA("MeshPart") and part.Name ~= "Load" then
				part.TextureID = texture
				part.Color = Color3.new(1, 1, 1)
			elseif part:IsA("BasePart") and part.Name ~= "Load" and part.Transparency < 1 then
				part.Material = Enum.Material.SmoothPlastic
				for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
					local t = Instance.new("Texture")
					t.Texture = texture
					t.Face = face
					t.StudsPerTileU, t.StudsPerTileV = Config.SkinTextureStuds, Config.SkinTextureStuds
					t.Parent = part
				end
			end
		end
	elseif look then
		for _, part in ipairs(look:GetDescendants()) do
			if part:IsA("SurfaceAppearance") then
				part:Destroy()
			end
		end
		for _, part in ipairs(tool:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "Load" and part.Name ~= "Handle" then
				if part:IsA("MeshPart") then
					part.TextureID = ""
				end
				part.Color = c
				part.Material = Enum.Material[skin.material]
			end
		end
	end
	local handle = tool:FindFirstChild("Handle")
	if handle then
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Name = "SkinSparkle"
		sparkle.Color = ColorSequence.new(c, Color3.new(1, 1, 1))
		sparkle.LightEmission = 0.7
		sparkle.Rate, sparkle.Lifetime, sparkle.Speed = 5, NumberRange.new(0.5, 0.9), NumberRange.new(0.6, 1.6)
		sparkle.Size = NumberSequence.new(0.18, 0)
		sparkle.Parent = handle
		local light = Instance.new("PointLight")
		light.Name = "SkinGlow" -- client/SkinFx swells and fades it on skins with a pulse
		light.Color, light.Range, light.Brightness = c, 6, 0.6
		light.Parent = handle
		if skin.twinkle then -- little stars that wink on and off along the tool
			local star = Instance.new("ParticleEmitter")
			star.Name = "SkinTwinkle"
			star.Color = ColorSequence.new(Color3.new(1, 1, 1), c)
			star.LightEmission = 1
			star.Rate, star.Lifetime, star.Speed = skin.twinkle, NumberRange.new(0.4, 0.7), NumberRange.new(0)
			star.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.22), NumberSequenceKeypoint.new(1, 0) })
			star.Parent = handle
		end
	end
	tool:SetAttribute("Skin", skin.id) -- client/SkinFx animates it
end

-- The skin (from the Wheel of Fortune) recolours the tool; "" is the plain tool.
local function skinOf(id)
	for _, prize in ipairs(Config.Wheel) do
		if prize.id == id and not prize.reveal then
			return prize
		end
	end
	return nil
end

function Tools.make(level, skinId)
	local def = Config.Tools[level]
	local skin = skinOf(skinId or "")
	local tool = Instance.new("Tool")
	tool.Name = def.name
	tool.ToolTip = Format.commas(def.power) .. " straws a click, carries " .. Format.commas(def.capacity)
	tool.CanBeDropped = false
	-- held like the spade: straight out in front, the working end forward (the handle's +Y
	-- points away from you and its +Z points up), the hand a little behind the middle
	tool.Grip = CFrame.new(0, -1.5, 0) * CFrame.Angles(math.rad(90), 0, 0)
	tool:SetAttribute("Level", level)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.3, 6, 0.3)
	handle.Color = Build.rgb(if skin then skin.shaft else def.shaft)
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.Massless = true
	handle.CFrame = CFrame.new()
	handle.Parent = tool
	local look, length = ToolLook.make(def)
	-- where the hay sits (its bottom, in the handle's space) and how big it can get
	local seat, maxLoad = nil, Config.LoadSize
	if look then
		-- an imported model, held straight out in front with its working end forward and up,
		-- like a scoop holding the hay. The handle's -Z points away from the hand.
		handle.Size = Vector3.new(0.3, 0.3, length)
		handle.Transparency = 1
		tool.Grip = CFrame.new(0, 0, length * 0.38) -- the hand near the back end
		local point = if def.flip == false then CFrame.Angles(math.rad(-90), 0, 0) else CFrame.Angles(math.rad(90), 0, 0)
		look.CFrame = handle.CFrame * CFrame.Angles(0, 0, math.rad(def.roll or 0)) * point * look:GetAttribute("Turn")
		local w = Instance.new("WeldConstraint")
		w.Part0, w.Part1 = handle, look
		w.Parent = look
		look.Parent = tool
		seat = CFrame.new(0, def.bladeTop or 0.15, -length * (def.loadAt or 0.3))
		maxLoad = def.loadSize or length * 0.45
	else
		local build = ToolParts[def.shape] or ToolGadgets[def.shape] or ToolParts.fork3
		local spec = build({
			tool = tool,
			handle = handle,
			colour = Build.rgb(if skin then skin.head else def.head),
			material = Enum.Material[if skin then skin.material else def.material],
		})
		handle.Size = Vector3.new(0.3, spec.length, 0.3)
		handle.Material = Enum.Material[spec.material or "Wood"]
		tool.Grip = CFrame.new(0, spec.hold, 0) * CFrame.Angles(math.rad(90), 0, 0)
		seat, maxLoad = spec.seat, spec.load
	end
	-- the hay you've harvested sits on the working end and grows as you harvest (see Carry.luau)
	local load = HayLook.lump(0.2, false)
	load.Name = "Load"
	load.Massless = true
	load.Transparency = 1
	load:SetAttribute("Seat", seat) -- Carry keeps the hay's bottom here as it grows
	load:SetAttribute("MaxSize", maxLoad)
	local weld = Instance.new("Weld")
	weld.Name = "LoadWeld"
	weld.Part0, weld.Part1 = handle, load
	weld.C0 = seat
	weld.Parent = load
	load.Parent = tool
	if skin then
		Tools.wearSkin(tool, look, skin)
	end
	return tool
end

local function clear(container, character)
	local equipped = false
	if container then
		for _, item in ipairs(container:GetChildren()) do
			if item:IsA("Tool") and item:GetAttribute("Level") ~= nil then
				equipped = equipped or container == character
				item:Destroy()
			end
		end
	end
	return equipped
end

-- True if the player holds or carries a search tool.
function Tools.has(player)
	local function holds(container)
		for _, item in ipairs(container and container:GetChildren() or {}) do
			if item:IsA("Tool") and item:GetAttribute("Level") ~= nil then
				return true
			end
		end
		return false
	end
	return holds(player:FindFirstChildOfClass("Backpack")) or holds(player.Character)
end

-- Replace whatever search tool the player has with the one for `level`. May wait briefly.
function Tools.give(player, level, skinId)
	local gear = player:FindFirstChild("StarterGear") or player:WaitForChild("StarterGear", 10)
	local backpack = player:FindFirstChildOfClass("Backpack")
	local character = player.Character
	clear(gear, nil)
	clear(backpack, nil)
	local wasEquipped = clear(character, character)
	if gear then
		Tools.make(level, skinId).Parent = gear
	end
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if backpack and humanoid and humanoid.Health > 0 then
		local tool = Tools.make(level, skinId)
		tool.Parent = backpack
		if wasEquipped then
			humanoid:EquipTool(tool)
		end
	end
end

return Tools

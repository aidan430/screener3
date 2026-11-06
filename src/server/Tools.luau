-- The search tools: a pitchfork-shaped Tool per level, coloured from Config.Tools.
-- The tool goes in StarterGear too, so players keep it when they respawn.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local HayLook = require(Shared:WaitForChild("HayLook"))(Config)
local Build = require(script.Parent.Build)
local ToolLook = require(script.Parent.ToolLook)

local Tools = {}

local function attach(tool, handle, size, offset, colour, material)
	local part = Instance.new("Part")
	part.Name = "Head"
	part.Size = size
	part.Color = colour
	part.Material = material
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.CFrame = handle.CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = part
	weld.Parent = part
	part.Parent = tool
	return part
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
	-- on a fork the hay rests on top of the tines (the handle's +Z is up when held)
	local seat, maxLoad = CFrame.new(0, 3.75, 0.2) * CFrame.Angles(math.rad(90), 0, 0), Config.LoadSize
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
		local colour = Build.rgb(if skin then skin.head else def.head)
		local material = Enum.Material[if skin then skin.material else def.material]
		attach(tool, handle, Vector3.new(1.7, 0.3, 0.3), CFrame.new(0, 2.9, 0), colour, material)
		for x = -1, 1 do
			attach(tool, handle, Vector3.new(0.16, 1.5, 0.16), CFrame.new(x * 0.7, 3.75, 0), colour, material)
		end
	end
	-- the hay you've harvested sits on the tines and grows as you harvest (see Carry.luau)
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

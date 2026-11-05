-- The search tools: a pitchfork-shaped Tool per level, coloured from Config.Tools.
-- The tool goes in StarterGear too, so players keep it when they respawn.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Build = require(script.Parent.Build)

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
end

function Tools.make(level)
	local def = Config.Tools[level]
	local tool = Instance.new("Tool")
	tool.Name = def.name
	tool.ToolTip = Format.commas(def.power) .. " straws a search"
	tool.CanBeDropped = false
	tool.Grip = CFrame.new(0, -1, 0) -- held a little below the middle, fork up
	tool:SetAttribute("Level", level)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.3, 6, 0.3)
	handle.Color = Build.rgb(def.shaft)
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.Massless = true
	handle.CFrame = CFrame.new()
	handle.Parent = tool
	local colour, material = Build.rgb(def.head), Enum.Material[def.material]
	attach(tool, handle, Vector3.new(1.7, 0.3, 0.3), CFrame.new(0, 2.9, 0), colour, material)
	for x = -1, 1 do
		attach(tool, handle, Vector3.new(0.16, 1.5, 0.16), CFrame.new(x * 0.7, 3.75, 0), colour, material)
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
function Tools.give(player, level)
	local gear = player:FindFirstChild("StarterGear") or player:WaitForChild("StarterGear", 10)
	local backpack = player:FindFirstChildOfClass("Backpack")
	local character = player.Character
	clear(gear, nil)
	clear(backpack, nil)
	local wasEquipped = clear(character, character)
	if gear then
		Tools.make(level).Parent = gear
	end
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if backpack and humanoid and humanoid.Health > 0 then
		local tool = Tools.make(level)
		tool.Parent = backpack
		if wasEquipped then
			humanoid:EquipTool(tool)
		end
	end
end

return Tools

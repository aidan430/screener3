-- Free building on your own plot: place pieces, machines and generators you've bought, take
-- them back, and ride elevators. Placements are saved relative to the plot's centre.
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))(Config)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local PlayerData = require(script.Parent.PlayerData)
local Plots = require(script.Parent.Plots)
local Pieces = require(script.Parent.Pieces)

local Structures = {}

-- Lights every machine and generator on the player's plot for the current power.
local function relight(player)
	local d = PlayerData.get(player)
	if d then
		local plot = Economy.plot(d.placed, PlayerData.flags(player).doubleMachines)
		Structures.light(player, plot.machines > 0 and plot.share >= 1)
	end
end

local function builtFolder(plotIndex)
	local plot = Plots.folder(plotIndex)
	local folder = plot:FindFirstChild("Built")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Built"
		folder.Parent = plot
	end
	return folder
end

local function spawnPiece(plotIndex, entry, slot)
	local cf = CFrame.new(Plots.centre(plotIndex) + Vector3.new(entry.x, entry.y, entry.z)) * CFrame.Angles(0, math.rad(entry.r), 0)
	local model = Pieces.make(entry.k, cf)
	if model then
		model:SetAttribute("Slot", slot)
		model.Parent = builtFolder(plotIndex)
	end
	return model
end

-- Rebuilds everything the player has placed (on joining).
function Structures.build(plotIndex, d)
	for slot, entry in ipairs(d.placed) do
		spawnPiece(plotIndex, entry, slot)
	end
	local owner = Plots.owner(plotIndex)
	if owner then
		task.defer(relight, owner)
	end
end

-- Renumbers the models after a removal so Slot attributes match d.placed again.
local function renumber(plotIndex, d)
	builtFolder(plotIndex):ClearAllChildren()
	Structures.build(plotIndex, d)
end

local function place(player, id, position, rotation)
	local d, plotIndex = PlayerData.get(player), Plots.of(player)
	if not d or not plotIndex then
		return false, "You don't have a plot yet."
	end
	if type(id) ~= "string" or not Economy.item(id) or (d.inventory[id] or 0) <= 0 then
		return false, "Buy that in the shop first."
	end
	if typeof(position) ~= "Vector3" or type(rotation) ~= "number" or rotation ~= rotation then
		return false, "Can't build there."
	end
	if not Plots.contains(plotIndex, position, 1) then
		return false, "You can only build on your own plot."
	end
	if #d.placed >= Config.MaxPlaced then
		return false, "Your plot is full (" .. Config.MaxPlaced .. " things)."
	end
	local rel = position - Plots.centre(plotIndex)
	local entry = { k = id, x = math.floor(rel.X * 10 + 0.5) / 10, y = math.floor(rel.Y * 10 + 0.5) / 10, z = math.floor(rel.Z * 10 + 0.5) / 10, r = rotation % 360 }
	PlayerData.update(player, function(data)
		data.inventory[id] -= 1
		table.insert(data.placed, entry)
	end)
	spawnPiece(plotIndex, entry, #d.placed)
	relight(player)
	return true, Economy.item(id).def.name .. " placed."
end

local function remove(player, model)
	local d, plotIndex = PlayerData.get(player), Plots.of(player)
	if not d or not plotIndex or typeof(model) ~= "Instance" or model.Parent ~= builtFolder(plotIndex) then
		return false, "That isn't yours to take."
	end
	local slot = model:GetAttribute("Slot")
	local entry = slot and d.placed[slot]
	if not entry then
		return false, "Can't take that."
	end
	PlayerData.update(player, function(data)
		table.remove(data.placed, slot)
		data.inventory[entry.k] = (data.inventory[entry.k] or 0) + 1
	end)
	renumber(plotIndex, d)
	relight(player)
	return true, Economy.item(entry.k).def.name .. " back in your inventory."
end

-- Machine and generator lamps: green when there's enough power, red when not.
function Structures.light(player, running)
	local plotIndex = Plots.of(player)
	if not plotIndex then
		return
	end
	for _, model in ipairs(builtFolder(plotIndex):GetChildren()) do
		local item = Economy.item(model:GetAttribute("Item") or "")
		if item and item.kind ~= "piece" then
			Pieces.light(model, item.kind == "generator" or running)
		end
	end
end

function Structures.init()
	Remotes.Place.OnServerInvoke = place
	Remotes.Remove.OnServerInvoke = remove
	ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		local direction = prompt:GetAttribute("Direction")
		local model = prompt:FindFirstAncestorOfClass("Model")
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not direction or not model or not root or model:GetAttribute("Item") ~= "elevator" then
			return
		end
		local base = model:GetPivot()
		local target = if direction == "up" then base * CFrame.new(0, 54, 0) else base * CFrame.new(0, 3.5, 0)
		root.CFrame = target
		root.AssemblyLinearVelocity = Vector3.zero
	end)
end

return Structures

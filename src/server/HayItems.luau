-- Every physical bit of hay lying on a plot: bundles (loose hay), bales, wrapped bales and
-- pellet sacks. Each is one unanchored part on the plot's "Loose" folder, owned by a player,
-- carrying its straws as an attribute. Straws lying loose are counted in `d.loose` (saved),
-- so nothing is lost if the server stops or the player leaves.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local HayLook = require(Shared:WaitForChild("HayLook"))(Config)

local PlayerData = require(script.Parent.PlayerData)
local Plots = require(script.Parent.Plots)
local Build = require(script.Parent.Build)

local HayItems = {}
HayItems.onTouch = nil -- set by Processing: function(item, hit)

function HayItems.folder(plotIndex)
	local plot = Plots.folder(plotIndex)
	local folder = plot:FindFirstChild("Loose")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Loose"
		folder.Parent = plot
	end
	return folder
end

function HayItems.ownerOf(item)
	return Players:GetPlayerByUserId(item:GetAttribute("Owner") or 0)
end

function HayItems.full(plotIndex)
	return #HayItems.folder(plotIndex):GetChildren() >= Config.MaxLooseHay
end

-- Removes an item; its straws leave the loose count. Returns its straws (0 if already taken).
function HayItems.resolve(item, player)
	local straws = item:GetAttribute("Straws") or 0
	item:SetAttribute("Straws", 0) -- so a second touch in the same moment counts nothing
	item:Destroy()
	if player and straws > 0 then
		PlayerData.update(player, function(data)
			data.loose = math.max(0, data.loose - straws)
		end)
	end
	return straws
end

local function block(size, cf, colour, material)
	return Build.part({ size = size, cframe = cf, color = colour, material = material, parent = nil })
end

local function band(item, cf, size, colour, material)
	local part = Build.part({ size = size, cframe = cf, color = colour, material = material, collide = false })
	part.Anchored = false
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1 = item, part
	weld.Parent = part
	part.Parent = item
end

local looks = {}
function looks.bundle(straws, cf)
	local part = HayLook.lump(math.clamp(1.6 + straws / 1500, 1.6, 4), false)
	part.CanCollide, part.CanTouch, part.CanQuery = true, true, true
	part.CFrame = cf
	return part
end
function looks.bale(_, cf)
	local part = block(Vector3.new(6, 3, 4), cf, Config.HeapColour, "Grass")
	for _, x in ipairs({ -1.6, 1.6 }) do -- the two strings round the bale
		band(part, cf * CFrame.new(x, 0, 0), Vector3.new(0.15, 3.05, 4.05), { 120, 60, 40 }, "Fabric")
	end
	return part
end
function looks.wrapped(_, cf)
	local part = block(Vector3.new(6, 3, 4), cf, { 236, 240, 232 }, "SmoothPlastic")
	band(part, cf, Vector3.new(6.05, 0.6, 4.05), { 90, 150, 90 }, "SmoothPlastic") -- a green stripe
	return part
end
function looks.pellet(_, cf)
	local part = block(Vector3.new(2.2, 1.4, 1.6), cf, { 196, 160, 96 }, "Fabric")
	band(part, cf * CFrame.new(0, 0.71, 0), Vector3.new(1.4, 0.1, 1.0), { 120, 84, 46 }, "Fabric")
	return part
end

-- Makes an item of `kind` holding `straws` at `cf`, moving at `velocity`. Returns it, or nil
-- if the plot already has as much loose hay as it may.
function HayItems.spawn(player, kind, straws, cf, velocity)
	local plotIndex = Plots.of(player)
	if not plotIndex or HayItems.full(plotIndex) or not looks[kind] then
		return nil
	end
	local item = looks[kind](straws, cf)
	item.Name = kind
	item.Anchored = false
	item:SetAttribute("Kind", kind)
	item:SetAttribute("Owner", player.UserId)
	item:SetAttribute("Straws", straws)
	item:SetAttribute("Born", os.time())
	if kind ~= "bundle" then
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Pick up"
		prompt.ObjectText = if kind == "bale" then "Hay bale" elseif kind == "wrapped" then "Wrapped bale" else "Pellet sack"
		prompt.HoldDuration = 0.2
		prompt.MaxActivationDistance = 9
		prompt:SetAttribute("Action", "pickup")
		prompt.Parent = item
	end
	item.Parent = HayItems.folder(plotIndex)
	item:SetNetworkOwner(nil)
	item.AssemblyLinearVelocity = velocity or Vector3.zero
	item.Touched:Connect(function(hit)
		if HayItems.onTouch then
			HayItems.onTouch(item, hit)
		end
	end)
	PlayerData.update(player, function(data)
		data.loose += straws
	end)
	return item
end

return HayItems

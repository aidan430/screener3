-- Box openings (Config.Boxes, shared/Boxes). Coin boxes open through Remotes.Box ("open"); the
-- dearer boxes can also be opened with Robux (a developer product: server/ShopManager calls
-- openInto from ProcessReceipt, then Remotes.BoxResult shows the reel). The server rolls; the
-- odds are shown before every open; every Config.Boxes.pity opens without Rare or better, the
-- next is Rare or better. Where paid random items are restricted (PolicyService), boxes are off
-- for that player: BoxesAllowed = false, and the Boxes screen and stall say so.
local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Boxes = require(Shared:WaitForChild("Boxes"))
local Needles = require(Shared:WaitForChild("Needles"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local DataManager = require(script.Parent.DataManager)
local CollectionManager = require(script.Parent.CollectionManager)

local BoxManager = {}
local rng = Random.new()
local busy = {}

-- Opens `box` into a player's data (call inside DataManager.update). Returns the result.
function BoxManager.openInto(data, box)
	local pityHit = data.boxPity >= Config.Boxes.pity - 1
	local typeId, skinId = Boxes.roll(box, rng, pityHit)
	local result = CollectionManager.addTo(data, typeId, skinId)
	local good = Needles.rarity(result.rarityId).mult >= Needles.rarity("rare").mult
	data.boxPity = if good then 0 else data.boxPity + 1
	data.boxesOpened += 1
	result.box, result.pity = box.id, data.boxPity
	return result
end

local function allowed(player)
	return player:GetAttribute("BoxesAllowed") == true
end

local function openWithCoins(player, boxId)
	local box = Boxes.get(boxId)
	local d = DataManager.get(player)
	if not box or not d then
		return false, "?"
	elseif not allowed(player) then
		return false, "Boxes aren't available where you are."
	elseif busy[player] then
		return false, "One at a time!"
	elseif d.coins < box.coins then
		return false, "You need " .. (box.coins - d.coins) .. " more coins."
	end
	busy[player] = true
	local result
	DataManager.update(player, function(data)
		data.coins -= box.coins
		result = BoxManager.openInto(data, box)
	end)
	CollectionManager.after(player, result)
	task.delay(1, function()
		busy[player] = nil
	end)
	return true, result
end

-- What the Boxes screen needs: whether boxes are on, and how near the pity guarantee you are.
local function info(player)
	local d = DataManager.get(player)
	return { allowed = allowed(player), pity = d and d.boxPity or 0, pityAt = Config.Boxes.pity, coins = d and d.coins or 0 }
end

local function checkPolicy(player)
	local ok, policy = pcall(PolicyService.GetPolicyInfoForPlayerAsync, PolicyService, player)
	-- unknown (the check failed) counts as restricted: boxes stay off rather than risk it
	player:SetAttribute("BoxesAllowed", ok and policy ~= nil and policy.ArePaidRandomItemsRestricted == false)
end

function BoxManager.init()
	Remotes.Box.OnServerInvoke = function(player, action, boxId)
		if action == "info" then
			return info(player)
		elseif action == "open" and type(boxId) == "string" then
			return openWithCoins(player, boxId)
		end
		return nil
	end
	Players.PlayerAdded:Connect(checkPolicy)
	for _, p in ipairs(Players:GetPlayers()) do
		task.spawn(checkPolicy, p)
	end
	Players.PlayerRemoving:Connect(function(player)
		busy[player] = nil
	end)
end

return BoxManager

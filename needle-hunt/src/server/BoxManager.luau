-- Box openings (Config.Boxes, shared/Boxes). Boxes open through Remotes.Box with coins ("open") or
-- a key from a round's chest ("key"); the
-- dearer boxes can also be opened with Robux (a developer product: server/ShopManager calls
-- openInto from ProcessReceipt, then Remotes.BoxResult shows the reel). The server rolls; the
-- odds are shown before every open; every Config.Boxes.pity opens without Rare or better, the
-- next is Rare or better. Where paid random items are restricted (PolicyService), boxes are off
-- for that player: BoxesAllowed = false, and the Boxes screen and stall say so. A very rare result
-- (Config.Boxes.announceAt) is announced to the whole server (Remotes.Announce).
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
local OneOfOne = require(script.Parent.OneOfOne)

local BoxManager = {}
local rng = Random.new()
local busy = {}

-- Rolled just before a box opens, every open (coins, key or Robux): the 1 of 1 it holds, or nil.
-- Each 1 of 1 has its Config.OneOfOne chance, until someone anywhere has it (server/OneOfOne claims
-- it once, in a DataStore every server shares, which can take a moment: so not inside an update).
function BoxManager.rollUnique(player)
	return OneOfOne.roll(player)
end

-- Opens `box` into a player's data (call inside DataManager.update). unique = the 1 of 1 rolled
-- for this open (BoxManager.rollUnique), which comes out instead. Returns the result.
function BoxManager.openInto(data, box, unique)
	if unique then
		local typeId, skinId = Needles.split(unique)
		local result = CollectionManager.addTo(data, typeId, skinId)
		local entry = OneOfOne.entryFor(unique)
		data.boxPity, data.boxesOpened = 0, data.boxesOpened + 1
		result.box, result.pity, result.oneOfOne = box.id, 0, unique
		result.percent = if entry then entry.chance * 100 else 0
		return result
	end
	local pityHit = data.boxPity >= Config.Boxes.pity - 1
	local typeId, skinId, percent = Boxes.roll(box, rng, pityHit)
	local result = CollectionManager.addTo(data, typeId, skinId)
	local good = Needles.rarity(result.rarityId).mult >= Needles.rarity("rare").mult
	data.boxPity = if good then 0 else data.boxPity + 1
	data.boxesOpened += 1
	result.box, result.pity, result.percent = box.id, data.boxPity, percent
	for _, row in ipairs(if percent then {} else Boxes.odds(box)) do -- how likely that rarity was in this box
		if row.rarity.id == result.rarityId then
			result.percent = row.percent
		end
	end
	return result
end

-- After any box opening (coins, key or Robux): a needle whose rarity had Config.Boxes.announceAt
-- percent or less in its box is announced to everyone in the server.
function BoxManager.announce(player, result)
	if result.oneOfOne then -- the only one there is: saved straight away, and every server hears
		DataManager.save(player)
		OneOfOne.announce(player, result.oneOfOne)
		return
	end
	if (result.percent or 100) > Config.Boxes.announceAt then
		return
	end
	local box = Boxes.get(result.box)
	local rarity = Needles.rarity(result.rarityId)
	Remotes.Announce:FireAllClients({
		name = player.DisplayName, needle = result.name, rarity = rarity.name, colour = rarity.colour,
		box = box and box.name or "box", percent = result.percent, type = result.type, skin = result.skin,
	})
end

local function allowed(player)
	return player:GetAttribute("BoxesAllowed") == true
end

-- Opens a box with coins, or with a key from a chest (withKey). Keys are earned in rounds, never
-- bought, but open the same box with the same odds.
local function open(player, boxId, withKey)
	local box = Boxes.get(boxId)
	local d = DataManager.get(player)
	if not box or not d then
		return false, "?"
	elseif not allowed(player) then
		return false, "Boxes aren't available where you are."
	elseif busy[player] then
		return false, "One at a time!"
	elseif withKey and (d.keys[box.id] or 0) < 1 then
		return false, "You haven't got a key for that box. Chests in rounds hold them!"
	elseif not withKey and d.coins < box.coins then
		return false, "You need " .. (box.coins - d.coins) .. " more coins."
	end
	busy[player] = true
	local unique = BoxManager.rollUnique(player)
	local result
	DataManager.update(player, function(data)
		if withKey then
			data.keys[box.id] -= 1
		else
			data.coins -= box.coins
		end
		result = BoxManager.openInto(data, box, unique)
	end)
	CollectionManager.after(player, result)
	BoxManager.announce(player, result)
	task.delay(1, function()
		busy[player] = nil
	end)
	return true, result
end

-- What the Boxes screen needs: whether boxes are on, and how near the pity guarantee you are.
local function info(player)
	local d = DataManager.get(player)
	return { allowed = allowed(player), pity = d and d.boxPity or 0, pityAt = Config.Boxes.pity, coins = d and d.coins or 0, keys = d and d.keys or {} }
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
		elseif (action == "open" or action == "key") and type(boxId) == "string" then
			return open(player, boxId, action == "key")
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

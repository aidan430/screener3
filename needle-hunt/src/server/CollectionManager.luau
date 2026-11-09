-- The needle collection, on the server. Needles come from boxes (server/BoxManager: coins, keys
-- from chests, or Robux) and trades (server/TradeManager), and go in through addTo. The collection
-- is saved; its value (each different needle once) is shown, ranked on a leaderboard and on the
-- lobby's showcase pedestals. Remotes.Collection lets anyone look at the collection of a player
-- in the same server ("get") and set their own showcase needle ("showcase").
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Needles = require(Shared:WaitForChild("Needles"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local DataManager = require(script.Parent.DataManager)
local QuestManager = require(script.Parent.QuestManager)
local LeaderboardManager = require(script.Parent.LeaderboardManager)

local CollectionManager = {}

-- Puts a needle in a player's saved data (inside DataManager.update) and says what it was, for
-- the reveal: finds, boxes and trades all add needles this way.
function CollectionManager.addTo(data, typeId, skinId)
	local key = Needles.key(typeId, skinId)
	local isNew = (data.collection[key] or 0) == 0
	data.collection[key] = (data.collection[key] or 0) + 1
	if data.showcase == "" or Needles.value(typeId, skinId) > Needles.value(Needles.split(data.showcase)) then
		data.showcase = key -- your best needle goes on show until you pick one
	end
	local rarity = Needles.rarity(Needles.skin(skinId).rarity)
	return { type = typeId, skin = skinId, name = Needles.name(typeId, skinId), rarity = rarity.name, rarityId = rarity.id, value = Needles.value(typeId, skinId), new = isNew }
end

-- After a needle is added: boards and quests.
function CollectionManager.after(player, result)
	LeaderboardManager.mark(player)
	if result.new then
		QuestManager.record(player, "collect", 1)
	end
	if Needles.rarity(result.rarityId).mult >= Needles.rarity("rare").mult then
		QuestManager.record(player, "rare", 1)
	end
end

-- What a player's collection looks like to anyone in the server.
function CollectionManager.view(target)
	local d = DataManager.get(target)
	if not d then
		return nil
	end
	return { userId = target.UserId, name = target.DisplayName, entries = d.collection, value = Needles.total(d.collection), showcase = d.showcase }
end

function CollectionManager.init()
	Remotes.Collection.OnServerInvoke = function(player, action, arg)
		if action == "get" then
			local target = if type(arg) == "number" then Players:GetPlayerByUserId(arg) else player
			return target and CollectionManager.view(target)
		elseif action == "list" then -- everyone in the server, for the "Look at" buttons
			local list = {}
			for _, p in ipairs(Players:GetPlayers()) do
				local d = DataManager.get(p)
				if d then
					table.insert(list, { userId = p.UserId, name = p.DisplayName, value = Needles.total(d.collection) })
				end
			end
			return list
		elseif action == "showcase" and type(arg) == "string" then
			local d = DataManager.get(player)
			if d and (d.collection[arg] or 0) > 0 then
				DataManager.update(player, function(data)
					data.showcase = arg
				end)
				return true
			end
		end
		return nil
	end
end

return CollectionManager

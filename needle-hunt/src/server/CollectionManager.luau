-- The needle collection, on the server. Each player who finishes a round keeps the needle they
-- found: the server rolls its type and skin (shared/Needles.roll), with a little more luck for
-- 1st place and Hard rounds, and a Golden skin in a Golden Needle round. Nothing paid changes the
-- odds. The collection is saved; its value (each different needle once) is shown, ranked on a
-- leaderboard and on the lobby's showcase pedestals. Remotes.Collection lets anyone look at the
-- collection of a player in the same server ("get") and set their own showcase needle ("showcase").
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Needles = require(Shared:WaitForChild("Needles"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local DataManager = require(script.Parent.DataManager)
local QuestManager = require(script.Parent.QuestManager)
local LeaderboardManager = require(script.Parent.LeaderboardManager)

local CollectionManager = {}
local rng = Random.new()

-- Gives `player` the needle they found. Returns what it was, for the reveal.
function CollectionManager.award(player, place, diff, golden)
	local d = DataManager.get(player)
	if not d then
		return nil
	end
	local C = Config.Collection
	local luck = 1 + (if place == 1 then C.firstLuck else 0) + (if diff.id == "hard" then C.hardLuck else 0)
	local typeId, skinId = Needles.roll(rng, luck, golden)
	local key = Needles.key(typeId, skinId)
	local isNew = (d.collection[key] or 0) == 0
	DataManager.update(player, function(data)
		data.collection[key] = (data.collection[key] or 0) + 1
		if data.showcase == "" or Needles.value(typeId, skinId) > Needles.value(Needles.split(data.showcase)) then
			data.showcase = key -- your best needle goes on show until you pick one
		end
	end)
	LeaderboardManager.mark(player)
	local skin = Needles.skin(skinId)
	local rarity = Needles.rarity(skin.rarity)
	if isNew then
		QuestManager.record(player, "collect", 1)
	end
	if rarity.mult >= Needles.rarity("rare").mult then
		QuestManager.record(player, "rare", 1)
	end
	return { type = typeId, skin = skinId, name = Needles.name(typeId, skinId), rarity = rarity.name, rarityId = rarity.id, value = Needles.value(typeId, skinId), new = isNew }
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

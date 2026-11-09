-- The 1 of 1s (Config.OneOfOne). A chest rolls for each (roll); the first player to roll one claims it
-- in a DataStore every server shares, with UpdateAsync, so two servers can never both hand it out:
-- if it's already claimed (or the store can't be reached), the chest is an ordinary chest. The
-- record follows the needle when it's traded. Finding it is announced on this server and, through
-- MessagingService, on every other one. In Studio a separate store is used, so testing (set
-- a chance of 1) never claims the real ones.
local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Needles = require(Shared:WaitForChild("Needles"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local OneOfOne = {}
local O = Config.OneOfOne
local TOPIC = "NH_OneOfOne"
local rng = Random.new()

local function store()
	local name = O.store .. (if RunService:IsStudio() then "_Studio" else "")
	local ok, ds = pcall(DataStoreService.GetDataStore, DataStoreService, name)
	return if ok then ds else nil
end

-- True if this player just became the one owner of `entry` (call only after a roll hits).
local function claim(player, entry)
	local ds = store()
	if not ds then
		return false
	end
	local won = false
	local ok = pcall(function()
		ds:UpdateAsync(entry.record, function(old)
			if old ~= nil then
				return nil -- already found by someone: leave it be
			end
			won = true
			return { userId = player.UserId, name = player.Name, at = os.time() }
		end)
	end)
	return ok and won
end

local function entryFor(key)
	for _, e in ipairs(O.list) do
		if e.key == key then
			return e
		end
	end
	return nil
end
OneOfOne.entryFor = entryFor

-- A chest's roll: the key of the 1 of 1 this chest holds (claimed by `player`), or nil.
function OneOfOne.roll(player)
	for _, e in ipairs(O.list) do
		if rng:NextNumber() < e.chance and claim(player, e) then
			return e.key
		end
	end
	return nil
end

-- A 1 of 1 changed hands in a trade: its record follows it.
function OneOfOne.transfer(key, toPlayer)
	local ds, entry = store(), entryFor(key)
	if ds and entry then
		pcall(function()
			ds:UpdateAsync(entry.record, function(old)
				if type(old) ~= "table" then
					return nil
				end
				old.userId, old.name, old.tradedAt = toPlayer.UserId, toPlayer.Name, os.time()
				return old
			end)
		end)
	end
end

local function message(name, key)
	local entry = entryFor(key)
	local t, s = Needles.split(key)
	if not entry or not t then
		return nil
	end
	local unique = Needles.rarity("unique")
	return { name = name, needle = Needles.name(t, s), rarity = unique.name, colour = unique.colour, box = "chest", odds = entry.odds, type = t, skin = s }
end

-- Tells everyone, here and on every other server.
function OneOfOne.announce(player, key)
	local m = message(player.DisplayName, key)
	if m then
		Remotes.Announce:FireAllClients(m)
		pcall(MessagingService.PublishAsync, MessagingService, TOPIC, { name = player.DisplayName, key = key, job = game.JobId })
	end
end

function OneOfOne.init()
	pcall(function()
		MessagingService:SubscribeAsync(TOPIC, function(packet)
			local data = type(packet) == "table" and packet.Data
			local m = type(data) == "table" and type(data.name) == "string" and type(data.key) == "string" and message(string.sub(data.name, 1, 40), data.key)
			if m and data.job ~= game.JobId then -- (this server already told its players)
				Remotes.Announce:FireAllClients(m)
			end
		end)
	end)
end

return OneOfOne

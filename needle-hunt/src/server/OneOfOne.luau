-- The 1 of 1 (Config.OneOfOne). A chest rolls for it (roll); the first player to roll it claims it
-- in a DataStore every server shares, with UpdateAsync, so two servers can never both hand it out:
-- if it's already claimed (or the store can't be reached), the chest is an ordinary chest. The
-- record follows the needle when it's traded. Finding it is announced on this server and, through
-- MessagingService, on every other one. In Studio a separate store is used, so testing (set
-- Config.OneOfOne.chance = 1) never claims the real one.
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

-- True if this player just became the one owner (call only after a roll hits).
local function claim(player)
	local ds = store()
	if not ds then
		return false
	end
	local won = false
	local ok = pcall(function()
		ds:UpdateAsync("owner", function(old)
			if old ~= nil then
				return nil -- already found by someone: leave it be
			end
			won = true
			return { userId = player.UserId, name = player.Name, at = os.time() }
		end)
	end)
	return ok and won
end

-- A chest's roll: true if this chest holds the 1 of 1 and `player` has claimed it.
function OneOfOne.roll(player)
	return rng:NextNumber() < O.chance and claim(player)
end

-- The needle changed hands in a trade: the record follows it.
function OneOfOne.transfer(toPlayer)
	local ds = store()
	if ds then
		pcall(function()
			ds:UpdateAsync("owner", function(old)
				if type(old) ~= "table" then
					return nil
				end
				old.userId, old.name, old.tradedAt = toPlayer.UserId, toPlayer.Name, os.time()
				return old
			end)
		end)
	end
end

local function message(name)
	local t, s = Needles.split(O.key)
	local unique = Needles.rarity("unique")
	return { name = name, needle = Needles.name(t, s), rarity = unique.name, colour = unique.colour, box = "chest", odds = "1 in 12,000,000", type = t, skin = s }
end

-- Tells everyone, here and on every other server.
function OneOfOne.announce(player)
	local m = message(player.DisplayName)
	Remotes.Announce:FireAllClients(m)
	pcall(MessagingService.PublishAsync, MessagingService, TOPIC, { name = player.DisplayName, job = game.JobId })
end

function OneOfOne.init()
	pcall(function()
		MessagingService:SubscribeAsync(TOPIC, function(packet)
			local data = type(packet) == "table" and packet.Data
			if type(data) == "table" and type(data.name) == "string" and data.job ~= game.JobId then -- (this server already told its players)
				Remotes.Announce:FireAllClients(message(string.sub(data.name, 1, 40)))
			end
		end)
	end)
end

return OneOfOne

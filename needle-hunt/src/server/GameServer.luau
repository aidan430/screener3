-- A game's own server: a private (reserved) server of this same place, made by a lobby game platform
-- (server/GamePads) for its players. Here there are no platforms: it waits for the players the
-- platform sent (their TeleportData says how many) or Config.GameServer.wait seconds, plays one
-- round with everyone (server/RoundManager), then sends everyone back to a lobby server. Anyone
-- who joins late plays the next game from the lobby.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local DataManager = require(script.Parent.DataManager)
local RoundManager = require(script.Parent.RoundManager)

local GameServer = {}

-- Is this a game's own server (a reserved server: a private server nobody owns)?
function GameServer.isGameServer()
	return game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0
end

local function expected()
	for _, p in ipairs(Players:GetPlayers()) do
		local ok, join = pcall(p.GetJoinData, p)
		local data = ok and join and join.TeleportData
		if type(data) == "table" and type(data.count) == "number" then
			return data.count
		end
	end
	return nil
end

local function ready()
	local n = 0
	for _, p in ipairs(Players:GetPlayers()) do
		if DataManager.get(p) and p.Character then
			n += 1
		end
	end
	return n
end

local function backToLobby()
	for attempt = 1, 3 do
		local list = Players:GetPlayers()
		if #list == 0 then
			return
		end
		Remotes.Notify:FireAllClients({ text = "Back to the lobby...", tone = "good" })
		local ok, err = pcall(TeleportService.TeleportAsync, TeleportService, game.PlaceId, list)
		if ok then
			return
		end
		warn("[GameServer] back to the lobby failed (try " .. attempt .. "): " .. tostring(err))
		task.wait(3)
	end
end

function GameServer.run()
	local waited = 0
	while waited < Config.GameServer.wait do -- everyone the platform sent, or as many as made it
		local want = expected()
		if want and ready() >= want then
			break
		end
		waited += task.wait(0.5)
	end
	while ready() == 0 do
		task.wait(1)
	end
	RoundManager.play(Players:GetPlayers())
	task.wait(Config.GameServer.afterRound)
	backToLobby()
end

return GameServer

-- Joining a round (server/RoundManager): step on the lobby's Play pad or press PLAY (Remotes.Queue)
-- to be in the next round; everyone else roams the lobby. RoundManager takes you out of the queue
-- again after each round, and the Settings switch "Join rounds automatically" skips all this.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local LobbyBuilder = require(script.Parent.LobbyBuilder)

local JoinQueue = {}

local function free(player) -- not in a round or the Practice Yard
	return not player:GetAttribute("InRound") and not player:GetAttribute("Practicing")
end

function JoinQueue.init()
	Remotes.Queue.OnServerInvoke = function(player, want)
		if free(player) then
			player:SetAttribute("Queued", want == true)
		end
		return player:GetAttribute("Queued") == true
	end
	local pad = LobbyBuilder.playPad()
	if pad then
		pad.Touched:Connect(function(hit)
			local p = Players:GetPlayerFromCharacter(hit.Parent)
			if p and free(p) then
				p:SetAttribute("Queued", true)
			end
		end)
	end
end

return JoinQueue

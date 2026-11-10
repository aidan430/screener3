-- The game platforms in the lobby (Config.Pads; built by server/LobbyBuilder). Stand on one to join
-- its game: the count above it shows how many are on it (3/10). At 10 the game starts after a few
-- seconds; with at least Config.Pads.minPlayers a longer countdown starts and the game goes with
-- whoever is on it then. Starting, its players are teleported to a private server of this place
-- (server/GameServer plays the round there and sends them back); if that can't happen (Studio, where
-- teleports don't work, or a failed teleport), the round is played right here when this server is
-- free. PLAY (Remotes.Queue) takes you to the fullest platform that has room.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Rules = require(Shared:WaitForChild("Rules"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local LobbyBuilder = require(script.Parent.LobbyBuilder)
local RoundManager = require(script.Parent.RoundManager)
local AntiCheat = require(script.Parent.AntiCheat)

local GamePads = {}
local P = Config.Pads
local state = {} -- [i] = { endsAt, launching }

local function now()
	return workspace:GetServerTimeNow()
end

local function free(p) -- in the lobby, not in a round or the Practice Yard
	return not p:GetAttribute("InRound") and not p:GetAttribute("Practicing")
end

-- Who's standing on pad i (in the order they stepped on, up to its size).
local arrived = {}
local function onPad(i)
	local pad = LobbyBuilder.pads()[i]
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		local offset = root and (root.Position - pad.position)
		local here = offset and Vector2.new(offset.X, offset.Z).Magnitude <= P.radius + 0.5 and offset.Y > -2 and offset.Y < 8 and free(p)
		if here then
			arrived[p] = arrived[p] or { pad = i, at = os.clock() }
			if arrived[p].pad ~= i then
				arrived[p] = { pad = i, at = os.clock() }
			end
			table.insert(list, p)
		elseif arrived[p] and arrived[p].pad == i then
			arrived[p] = nil
		end
	end
	table.sort(list, function(a, b)
		return arrived[a].at < arrived[b].at
	end)
	while #list > P.size do
		table.remove(list)
	end
	return list
end

local function minPlayers()
	return if RunService:IsStudio() then P.studioMinPlayers else P.minPlayers
end

-- A game starting: its players to their own server, or (Studio, or if that fails) a round here.
local function launch(i, list)
	local s = state[i]
	s.launching, s.endsAt = true, nil
	local ok = false
	if not RunService:IsStudio() then
		ok = pcall(function()
			local code = TeleportService:ReserveServer(game.PlaceId)
			local options = Instance.new("TeleportOptions")
			options.ReservedServerAccessCode = code
			options:SetTeleportData({ pad = i, count = #list })
			TeleportService:TeleportAsync(game.PlaceId, list, options)
		end)
		if not ok then
			warn("[GamePads] teleport failed: playing game " .. i .. " here")
		end
	end
	if not ok then
		if RoundManager.busy() then
			LobbyBuilder.pads()[i].status.Text = "Waiting for the game in play..."
			task.wait(2)
		else
			task.spawn(RoundManager.play, list)
		end
	end
	task.wait(3) -- they've gone: the platform clears
	s.launching = false
end

local function tick()
	local pads = LobbyBuilder.pads()
	for i, pad in ipairs(pads) do
		local s = state[i]
		local list = onPad(i)
		pad.count.Text = #list .. "/" .. P.size
		pad.fx.Rate = P.portal.rate + (P.portal.fullRate - P.portal.rate) * math.min(#list / P.size, 1) -- the portal livens up as it fills
		if s.launching then
			pad.status.Text = "Loading the game..."
		elseif #list >= P.size then
			s.endsAt = math.min(s.endsAt or math.huge, now() + P.fullCountdown)
		elseif #list >= minPlayers() then
			s.endsAt = s.endsAt or now() + P.countdown
		else
			s.endsAt = nil
		end
		if not s.launching then
			if s.endsAt and now() >= s.endsAt then
				task.spawn(launch, i, list)
			elseif s.endsAt then
				pad.status.Text = (if #list >= P.size then "Full! Starting in " else "Starting in ") .. Rules.clock(s.endsAt - now())
			else
				pad.status.Text = if #list == 0 then "Stand here to play" else "Waiting for players"
			end
		end
	end
end

function GamePads.init()
	for i = 1, #LobbyBuilder.pads() do
		state[i] = {}
	end
	Remotes.Queue.OnServerInvoke = function(player) -- PLAY: onto the fullest platform with room
		if not free(player) or not player.Character then
			return false
		end
		local best, bestCount = nil, -1
		for i, pad in ipairs(LobbyBuilder.pads()) do
			local n = #onPad(i)
			if not state[i].launching and n < P.size and n > bestCount then
				best, bestCount = pad, n
			end
		end
		if best then
			AntiCheat.allow(player, 3)
			player.Character:PivotTo(CFrame.new(best.position + Vector3.new(math.random(-3, 3), 3, math.random(-3, 3))))
		end
		return best ~= nil
	end
	Players.PlayerRemoving:Connect(function(p)
		arrived[p] = nil
	end)
	task.spawn(function()
		while true do
			tick()
			task.wait(0.5)
		end
	end)
end

return GamePads

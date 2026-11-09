-- Basic anti-exploit: every Config.AntiCheat.checkEvery seconds, each character's position is
-- compared with the last; moving faster than Config.AntiCheat.maxSpeed (outside a teleport the
-- server made itself, see AntiCheat.allow) puts the character back and flags the player, which
-- stops them claiming a needle for a few seconds. Claims are also checked for distance and rate
-- in server/NeedleSpawner. Nothing here trusts the client.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local AntiCheat = {}
local last = {} -- [player] = { position, time }
local allowedUntil = {} -- [player] = os.clock() a server teleport is allowed until
local flaggedUntil = {} -- [player] = os.clock() claims are refused until
local strikes = {}

-- The server is about to move this player itself (to a map or back to the lobby).
function AntiCheat.allow(player, seconds)
	allowedUntil[player] = os.clock() + (seconds or 2)
	last[player] = nil
end

function AntiCheat.flagged(player)
	return (flaggedUntil[player] or 0) > os.clock()
end

local function check(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		last[player] = nil
		return
	end
	local now = os.clock()
	local prev = last[player]
	if (allowedUntil[player] or 0) > now or not prev then
		last[player] = { position = root.Position, time = now }
		return
	end
	local speed = (root.Position - prev.position).Magnitude / math.max(now - prev.time, 0.05)
	if speed > Config.AntiCheat.maxSpeed then
		root.CFrame = CFrame.new(prev.position) -- back to where they were
		root.AssemblyLinearVelocity = Vector3.zero
		flaggedUntil[player] = now + 5
		strikes[player] = (strikes[player] or 0) + 1
		warn(string.format("[AntiCheat] %s moved %.0f studs/s; put back (strike %d)", player.Name, speed, strikes[player]))
		if Config.AntiCheat.strikesToKick > 0 and strikes[player] >= Config.AntiCheat.strikesToKick then
			player:Kick("Unusual movement was detected. Please rejoin.")
		end
		return
	end
	last[player] = { position = root.Position, time = now }
end

function AntiCheat.init()
	Players.PlayerRemoving:Connect(function(player)
		last[player], allowedUntil[player], flaggedUntil[player], strikes[player] = nil, nil, nil, nil
	end)
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			AntiCheat.allow(player, 3) -- spawning is a teleport too
		end)
	end)
	task.spawn(function()
		while true do
			task.wait(Config.AntiCheat.checkEvery)
			for _, player in ipairs(Players:GetPlayers()) do
				check(player)
			end
		end
	end)
end

return AntiCheat

-- Where everyone was over the last second (Config.HitCheck.history), so a poke can be checked
-- against what the attacker saw on their screen a moment ago (server/CombatPoke). A teleport
-- (a jump of more than 30 studs) or a new character starts a player's history afresh.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Rewind = {}
local H = Config.HitCheck
local rings = {} -- [player] = { { p = position, look = flat facing, t = os.clock() }, ... } oldest first

-- How far back to look for this attacker: twice their ping plus a little, within limits.
function Rewind.window(player)
	local ok, ping = pcall(player.GetNetworkPing, player)
	ping = if ok and type(ping) == "number" and ping == ping then ping else 0
	return math.clamp(2 * ping + H.window[1], H.window[1], H.window[2])
end

-- The player's positions over the last `seconds`, newest first.
function Rewind.samples(player, seconds)
	local out, now = {}, os.clock()
	local ring = rings[player] or {}
	for i = #ring, 1, -1 do
		if now - ring[i].t > seconds and #out > 0 then
			break
		end
		table.insert(out, ring[i])
	end
	return out
end

function Rewind.init()
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		for _, player in ipairs(Players:GetPlayers()) do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if root then
				local ring = rings[player] or {}
				rings[player] = ring
				local last = ring[#ring]
				if last and (root.Position - last.p).Magnitude > 30 then
					table.clear(ring)
				end
				local look = root.CFrame.LookVector
				table.insert(ring, { p = root.Position, look = Vector3.new(look.X, 0, look.Z), t = now })
				while ring[1] and now - ring[1].t > H.history do
					table.remove(ring, 1)
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		rings[player] = nil
	end)
end

return Rewind

-- Crouching and sliding, the server's side (Config.Stance). Each player's device moves its own
-- character (client/StanceFx) and says what it's doing (Remotes.Stance: "stand", "crouch" or
-- "slide"); the server checks the message, keeps it as the player's "Stance" attribute (nil when
-- standing) for everyone else to see, hides a croucher's name tag, and ends a slide by its own
-- clock. Speed is still checked by server/AntiCheat as always.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Stance = {}
local S = Config.Stance
local seen = {} -- [player] = { window start, count, slide began }

local function humanoidOf(player)
	return player.Character and player.Character:FindFirstChildOfClass("Humanoid")
end

local function set(player, stance)
	stance = if stance == "stand" then nil else stance
	if player:GetAttribute("Stance") == stance then
		return
	end
	player:SetAttribute("Stance", stance)
	local h = humanoidOf(player)
	if h then -- a croucher's name doesn't show over the hedges
		h.DisplayDistanceType = if stance == "crouch" then Enum.HumanoidDisplayDistanceType.None else Enum.HumanoidDisplayDistanceType.Viewer
	end
end

function Stance.init()
	Remotes.Stance.OnServerEvent:Connect(function(player, stance)
		if stance ~= "stand" and stance ~= "crouch" and stance ~= "slide" then
			return
		end
		local now = os.clock()
		local s = seen[player] or { now, 0, -math.huge }
		seen[player] = s
		if now - s[1] >= 1 then
			s[1], s[2] = now, 0
		end
		s[2] += 1
		if s[2] > S.server.rate then
			return
		end
		local h = humanoidOf(player)
		if not h or h.Health <= 0 or h.WalkSpeed <= 0 then
			return set(player, "stand")
		end
		if stance == "slide" then
			if now - s[3] < S.slide.cooldown - 0.1 then
				stance = "crouch" -- too soon for another slide
			else
				s[3] = now
			end
		end
		set(player, stance)
	end)
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			set(player, "stand")
		end)
	end)
	Players.PlayerRemoving:Connect(function(player)
		seen[player] = nil
	end)
	task.spawn(function() -- slides end; nobody stays down while tagged out or held still
		while true do
			task.wait(0.2)
			local now = os.clock()
			for _, player in ipairs(Players:GetPlayers()) do
				local stance = player:GetAttribute("Stance")
				if stance then
					local h = humanoidOf(player)
					if not h or h.Health <= 0 or h.WalkSpeed <= 0 then
						set(player, "stand")
					elseif stance == "slide" and now - (seen[player] and seen[player][3] or 0) > S.server.slideMax then
						set(player, "crouch")
					end
				end
			end
		end
	end)
end

return Stance

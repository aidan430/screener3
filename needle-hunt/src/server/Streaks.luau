-- Tag-out streaks, the Marked player and the tag-out feed (Config.Streak), called by server/Combat
-- for every tag-out in a round.
--   Streak: tag-outs in a row without being tagged out yourself. Each one raises that tag-out's
--   coins and match XP (Streaks.multiplier). Being tagged out, or a round starting or ending,
--   resets it. From announceAt in a row the round hears about it.
--   Marked: at marked.at in a row you glow red and everyone can see you through walls (a
--   Highlight), but you walk marked.speed x faster, until you're tagged out or the round ends.
--   Feed: every tag-out goes to everyone's feed (client/FeedFx): who, whom, poke or throw, streak.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Streaks = {}
local S = Config.Streak
local WALK = 16

function Streaks.multiplier(streak)
	return math.min(S.max, 1 + S.step * (math.max(1, streak) - 1))
end

-- A player's walking speed when nothing else is boosting it (a Marked player is faster).
function Streaks.walkSpeed(player)
	return WALK * (player:GetAttribute("SpeedMult") or 1)
end

local function humanoidOf(player)
	return player.Character and player.Character:FindFirstChildOfClass("Humanoid")
end

local function glow(player) -- the red outline, seen through walls by everyone
	local character = player.Character
	if not character or character:FindFirstChild("MarkedGlow") then
		return
	end
	local h = Instance.new("Highlight")
	h.Name, h.DepthMode = "MarkedGlow", Enum.HighlightDepthMode.AlwaysOnTop
	h.OutlineColor = Color3.fromRGB(S.marked.colour[1], S.marked.colour[2], S.marked.colour[3])
	h.FillColor, h.FillTransparency, h.OutlineTransparency = h.OutlineColor, 0.8, 0
	h.Parent = character
	local hum = humanoidOf(player)
	if hum and hum.WalkSpeed < Streaks.walkSpeed(player) then
		hum.WalkSpeed = Streaks.walkSpeed(player)
	end
end

function Streaks.mark(player)
	player:SetAttribute("Marked", true)
	player:SetAttribute("SpeedMult", S.marked.speed)
	glow(player)
end

function Streaks.unmark(player)
	if not player:GetAttribute("Marked") then
		return
	end
	player:SetAttribute("Marked", nil)
	player:SetAttribute("SpeedMult", nil)
	local glowing = player.Character and player.Character:FindFirstChild("MarkedGlow")
	if glowing then
		glowing:Destroy()
	end
	local hum = humanoidOf(player)
	if hum and hum.WalkSpeed > WALK and hum.WalkSpeed <= WALK * S.marked.speed + 0.01 then
		hum.WalkSpeed = WALK
	end
end

-- Records a tag-out. how = "poke" or "throw". Returns the attacker's streak, its multiplier and
-- the streak the target lost.
function Streaks.tagOut(attacker, target, how, participants)
	local streak = (attacker:GetAttribute("Streak") or 0) + 1
	local ended = target:GetAttribute("Streak") or 0
	local wasMarked = target:GetAttribute("Marked") == true
	attacker:SetAttribute("Streak", streak)
	target:SetAttribute("Streak", 0)
	Streaks.unmark(target)
	local function tell(text)
		for p in pairs(participants or {}) do
			if p ~= attacker then
				Remotes.Notify:FireClient(p, { text = text, tone = "bad" })
			end
		end
	end
	if streak == S.marked.at then
		Streaks.mark(attacker)
		tell(attacker.DisplayName .. " is MARKED: " .. streak .. " in a row! You can see them through walls.")
	elseif streak >= S.announceAt and streak < S.marked.at then
		tell(attacker.DisplayName .. " is on a " .. streak .. "-tag streak!")
	end
	Remotes.Feed:FireAllClients({ by = attacker.DisplayName, byId = attacker.UserId, target = target.DisplayName, targetId = target.UserId, how = how, streak = streak, marked = attacker:GetAttribute("Marked") == true, endedMarked = wasMarked, ended = ended })
	return streak, Streaks.multiplier(streak), ended
end

-- A round starting: streaks start fresh for everyone playing.
function Streaks.reset(participants)
	for p in pairs(participants) do
		p:SetAttribute("Streak", 0)
		p:SetAttribute("BestStreak", 0)
		Streaks.unmark(p)
	end
end

-- A round over: nobody keeps a streak or stays Marked.
function Streaks.clear()
	for _, p in ipairs(Players:GetPlayers()) do
		p:SetAttribute("Streak", 0)
		Streaks.unmark(p)
	end
end

function Streaks.init()
	local function joined(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.6)
			if player:GetAttribute("Marked") then -- a new body (a fall): the glow and the speed again
				glow(player)
			end
		end)
	end
	Players.PlayerAdded:Connect(joined)
	for _, p in ipairs(Players:GetPlayers()) do
		joined(p)
	end
end

return Streaks

-- Guided goals: a step-by-step list (Config.Goals) that teaches the game. The server checks the
-- player's current goal every couple of seconds, pays its coins and moves on. The client only
-- shows the attributes: Goal (position, #Config.Goals + 1 once all are done), GoalProgress
-- ("3/10"), GoalShare (0..1).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))(Config)
local Format = require(Shared:WaitForChild("Format"))

local PlayerData = require(script.Parent.PlayerData)
local Profile = require(script.Parent.Profile)

local Goals = {}

-- How far along a goal the player is, as a number to compare with goal.n.
function Goals.value(d, goal)
	local kind = goal.kind
	if kind == "stat" then
		return d.stats[goal.key] or 0
	elseif kind == "tool" then
		return d.tool
	elseif kind == "bucket" then
		return d.bucket
	elseif kind == "silo" then
		return d.silo
	elseif kind == "clumps" then
		return Config.Clumps - Profile.clumpsLeft(d)
	elseif kind == "placed" then
		local n = 0
		for _, p in ipairs(d.placed) do
			if p.k == goal.key then
				n += 1
			end
		end
		return n
	elseif kind == "truck" then
		return d.trucks[goal.key] or 0
	elseif kind == "machines" then
		return Economy.plot(d.placed, false).machines
	elseif kind == "power" then
		return Economy.plot(d.placed, false).made
	end
	return 0
end

local function progressText(goal, have)
	if goal.kind == "tool" or goal.kind == "bucket" or goal.kind == "silo" then
		return if have >= goal.n then "1/1" else "0/1" -- a level to reach: done or not
	end
	return Format.commas(math.min(have, goal.n)) .. "/" .. Format.commas(goal.n)
end

local function share(goal, have)
	if goal.kind == "tool" or goal.kind == "bucket" or goal.kind == "silo" then
		return if have >= goal.n then 1 else 0
	end
	return math.clamp(have / math.max(goal.n, 1), 0, 1)
end

-- Pays and moves past every goal that's done (a returning player may finish several at once),
-- then shows where the player is now.
function Goals.check(player)
	local d = PlayerData.get(player)
	if not d then
		return
	end
	local goal = Config.Goals[d.goal]
	while goal and Goals.value(d, goal) >= goal.n do
		local reward = goal.reward
		PlayerData.update(player, function(data)
			data.coins += reward
			data.goal += 1
		end)
		goal = Config.Goals[d.goal]
	end
	if player:GetAttribute("Goal") ~= d.goal then
		player:SetAttribute("Goal", d.goal)
	end
	local text, fraction = "", 1
	if goal then
		local have = Goals.value(d, goal)
		text, fraction = progressText(goal, have), share(goal, have)
	end
	if player:GetAttribute("GoalProgress") ~= text then
		player:SetAttribute("GoalProgress", text)
	end
	if player:GetAttribute("GoalShare") ~= fraction then
		player:SetAttribute("GoalShare", fraction)
	end
end

function Goals.init()
	PlayerData.onLoaded(function(player)
		Goals.check(player)
	end)
	task.spawn(function()
		while true do
			task.wait(Config.GoalCheckSeconds)
			for _, player in ipairs(Players:GetPlayers()) do
				local ok, err = pcall(Goals.check, player)
				if not ok then
					warn("[Goals] " .. tostring(err))
				end
			end
		end
	end)
end

return Goals

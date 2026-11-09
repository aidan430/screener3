-- Farmer Level (Config.Levels): every lift earns XP, levels come quickly, and each one is +1
-- Strength (you carry 1% more). The server keeps the count; the screen (client/LevelBar) shows the
-- bar filling, LEVEL UP! and the x2 of a Lucky Lift from the attributes Level, Xp and XpNeed.
-- Level also shows in the player list (leaderstats) and on the Top Farmers board (LevelBoard).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))(Config)

local PlayerData = require(script.Parent.PlayerData)

local Levels = {}
local L = Config.Levels

local function show(player, d)
	player:SetAttribute("Level", d.level)
	player:SetAttribute("Xp", d.xp)
	player:SetAttribute("XpNeed", Economy.levelNeed(d.level))
	player:SetAttribute("Strength", d.level - 1)
	local stats = player:FindFirstChild("leaderstats")
	local value = stats and stats:FindFirstChild("Level")
	if stats and not value then
		value = Instance.new("IntValue")
		value.Name = "Level"
		value.Parent = stats
	end
	if value then
		value.Value = d.level
	end
end

-- Adds XP; returns how many levels it gained. Free wheel spins come every L.spinEvery levels.
function Levels.gain(player, xp)
	local d = PlayerData.get(player)
	if not d or xp <= 0 then
		return 0
	end
	local before = d.level
	PlayerData.update(player, function(data)
		data.xp += xp
		while data.level < L.maxLevel and data.xp >= Economy.levelNeed(data.level) do
			data.xp -= Economy.levelNeed(data.level)
			data.level += 1
			if data.level % L.spinEvery == 0 then
				data.spinBank += 1 -- the screen says so (client/LevelBar) and shows a spin badge
			end
		end
	end)
	show(player, d)
	return d.level - before
end

-- XP for one lift: xpPerLift x your tool's number, double if it was lucky, and a bonus for clearing a clump.
function Levels.lift(player, lucky, cleared)
	local d = PlayerData.get(player)
	local tool = d and d.tool or 1
	return Levels.gain(player, L.xpPerLift * tool * (if lucky then 2 else 1) + (if cleared then L.xpPerClump else 0))
end

function Levels.init()
	PlayerData.onLoaded(function(player)
		local d = PlayerData.get(player)
		if d then
			show(player, d)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		local level = player:GetAttribute("Level") -- the attribute: the save may already be gone
		if level then
			require(script.Parent.LevelBoard).record(player, level)
		end
	end)
end

return Levels

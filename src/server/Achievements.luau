-- The secret achievements, hidden until earned. Each watches one number; any ten open the Golden Loft.
-- Optional Roblox badges: put badge IDs into Config.BadgeIds.
local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))(Config)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local PlayerData = require(script.Parent.PlayerData)

local Achievements = {}

-- The current value of each achievement's number for a player.
function Achievements.value(player, d, stat)
	if stat == "tool" then
		return d.tool
	elseif stat == "machines" then
		return Economy.plot(d.placed, false).machines
	elseif stat == "power" then
		return Economy.plot(d.placed, false).made
	elseif stat == "needles" then
		return d.needles
	end
	return d.stats[stat] or 0
end

local function award(player, achievement)
	PlayerData.update(player, function(data)
		data.achievements[achievement.id] = true
	end)
	Remotes.Achievement:FireClient(player, { id = achievement.id, name = achievement.name, text = achievement.text, done = player:GetAttribute("Achievements"), total = #Config.Achievements })
	local badge = Config.BadgeIds[achievement.id]
	if badge and badge ~= 0 then
		task.spawn(function()
			pcall(BadgeService.AwardBadge, BadgeService, player.UserId, badge)
		end)
	end
	if player:GetAttribute("LoftOpen") then
		Remotes.Announce:FireAllClients({ kind = "loft", finder = player.DisplayName, finderId = player.UserId })
	end
end

-- Call after anything that could complete an achievement. Cheap: ten comparisons.
function Achievements.check(player)
	local d = PlayerData.get(player)
	if not d then
		return
	end
	for _, a in ipairs(Config.Achievements) do
		if not d.achievements[a.id] and Achievements.value(player, d, a.stat) >= a.goal then
			award(player, a)
		end
	end
end

function Achievements.progress(player)
	local d = PlayerData.get(player)
	local out = {}
	for _, a in ipairs(Config.Achievements) do
		local done = d ~= nil and d.achievements[a.id] == true
		-- secret until earned: the client only learns an achievement once it is done
		table.insert(out, if done then { id = a.id, name = a.name, text = a.text, done = true } else { id = a.id, done = false })
	end
	return out
end

function Achievements.init()
	Remotes.GetAchievements.OnServerInvoke = Achievements.progress
	task.spawn(function() -- machines and power change by building, so check on a timer too
		while true do
			task.wait(15)
			for _, player in ipairs(Players:GetPlayers()) do
				Achievements.check(player)
			end
		end
	end)
end

return Achievements

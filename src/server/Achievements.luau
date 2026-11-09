-- The secret achievements, hidden until earned. Each watches one number; any ten open the Golden Loft.
-- Optional Roblox badges: put badge IDs into Config.BadgeIds.
local BadgeService = game:GetService("BadgeService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))(Config)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local PlayerData = require(script.Parent.PlayerData)
local Profile = require(script.Parent.Profile)

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
	elseif stat == "hours" then
		local hour = if RunService:IsStudio() and Config.Testing.fastHours > 0 then Config.Testing.fastHours else 3600 -- (a testing switch, Studio only)
		return (d.stats.play_seconds or 0) / hour
	elseif stat == "streak" then
		return d.stats.day_streak or 0
	elseif stat == "days" then
		return d.stats.days_played or 0
	elseif stat == "clumps" then -- every clump cleared, on every heap so far
		return d.needles * Config.Clumps + Config.Clumps - Profile.clumpsLeft(d)
	elseif stat == "skins" or stat == "story" or stat == "worlds" then
		local n, set = 0, if stat == "skins" then d.skins elseif stat == "story" then d.storySeen else d.worlds
		for _, v in pairs(set) do
			n += if stat == "worlds" then (if v.unlocked then 1 else 0) else 1
		end
		return n
	elseif stat == "orders" then
		return math.max(0, d.order - 1)
	end
	return d.stats[stat] or 0
end

-- A milestone's rewards: cosmetics, coins, banked wheel spins and (powerups) every power-up.
local function reward(player, a)
	PlayerData.update(player, function(data)
		for _, id in ipairs(a.cosmetics or {}) do
			data.cosmetics[id] = true
		end
		data.coins += a.coins or 0
		data.spinBank += a.spins or 0
		if a.powerups then
			local now = os.time()
			for _, name in ipairs({ "SpeedBoost", "CoinBoost", "LuckyCharm" }) do
				data.boosts[name] = math.max(data.boosts[name] or 0, now) + Config.LegendBoostHours * 3600
			end
			data.whistles += Config.WhistleUses
		end
	end)
	if a.powerups then
		task.spawn(function() -- a Straw Blast too (Machines needs this module, so it's fetched here)
			pcall(require(script.Parent.Machines).blast, player, Config.StrawBlastAmount)
		end)
	end
end

local function award(player, achievement)
	PlayerData.update(player, function(data)
		data.achievements[achievement.id] = true
	end)
	reward(player, achievement)
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
		-- secret until earned, unless it's an open milestone (shown with its progress and prizes)
		if done or a.open then
			table.insert(out, { id = a.id, name = a.name, text = a.text, done = done, open = a.open == true, have = if d then Achievements.value(player, d, a.stat) else 0, goal = a.goal, cosmetics = a.cosmetics, spins = a.spins })
		else
			table.insert(out, { id = a.id, done = false })
		end
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

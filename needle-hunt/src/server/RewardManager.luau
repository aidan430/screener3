-- Every coin and XP point is given here, on the server: needle finds (faster = more), places,
-- playing a round to the end, win streaks, the daily login streak and quest rewards. Level-ups
-- and rewards are announced to the player. Stats for the leaderboards are kept up to date.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Rules = require(Shared:WaitForChild("Rules"))
local Quests = require(Shared:WaitForChild("Quests"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local DataManager = require(script.Parent.DataManager)
local QuestManager = require(script.Parent.QuestManager)
local LeaderboardManager = require(script.Parent.LeaderboardManager)

local RewardManager = {}

-- Match stats (server/MatchXp sets this while a round runs): track(player, "coins" | "needles" |
-- "elims", amount). Does nothing between rounds.
RewardManager.tracker = nil
function RewardManager.track(player, what, amount)
	if RewardManager.tracker then
		RewardManager.tracker(player, what, amount)
	end
end

local function hasPass(player, name)
	return player:GetAttribute("Pass_" .. name) == true
end
RewardManager.hasPass = hasPass

-- Gives coins and XP (already multiplied) and announces any level-up. Returns the levels gained.
function RewardManager.grant(player, coins, xp, why)
	local gained = 0
	if coins > 0 then
		RewardManager.track(player, "coins", coins)
	end
	DataManager.update(player, function(d)
		d.coins += coins
		d.coinsEarned += coins
		d.level, d.xp, gained = Rules.addXp(d.level, d.xp, xp)
	end)
	LeaderboardManager.mark(player)
	if why then
		Remotes.Notify:FireClient(player, { text = why .. ": +" .. Rules.commas(coins) .. " coins, +" .. xp .. " XP", tone = "good" })
	end
	if gained > 0 then
		Remotes.Notify:FireClient(player, { text = "LEVEL UP! You're level " .. player:GetAttribute("Level") .. ".", tone = "level" })
	end
	return gained
end

-- A needle claimed (each needle counts, so two in a Double Needle round).
function RewardManager.found(player, elapsed, golden)
	DataManager.update(player, function(d)
		d.needles += 1
		if d.bestTime == 0 or elapsed < d.bestTime then
			d.bestTime = math.floor(elapsed * 10 + 0.5) / 10
		end
	end)
	LeaderboardManager.mark(player)
	RewardManager.track(player, "needles", 1)
	QuestManager.record(player, "find", 1)
	QuestManager.record(player, "fast", 1, { seconds = elapsed })
	if golden then
		QuestManager.record(player, "golden", 1)
	end
end

-- A player finished the round in `place` (1 = first to find every needle). Returns coins, xp.
function RewardManager.placed(player, place, elapsed, duration, diff, golden, playerCount)
	local d = DataManager.get(player)
	if not d then
		return 0, 0
	end
	local coins, xp = Rules.findReward(place, elapsed, duration, diff, golden, d.winStreak, hasPass(player, "DoubleCoins"))
	if place == 1 and playerCount >= Config.Round.winsNeedPlayers then
		DataManager.update(player, function(data)
			data.wins += 1
			data.winStreak += 1
			local week = Rules.week()
			if data.weekly.week ~= week then
				data.weekly = { week = week, wins = 0 }
			end
			data.weekly.wins += 1
		end)
		QuestManager.record(player, "win", 1)
	end
	RewardManager.grant(player, coins, xp, nil)
	return coins, xp
end

-- Everyone still in the map at the end of a round. `won` = they placed first.
function RewardManager.played(player, diff, won)
	local mult = if hasPass(player, "DoubleCoins") then 2 else 1
	DataManager.update(player, function(d)
		d.rounds += 1
		if not won then
			d.winStreak = 0
		end
	end)
	RewardManager.grant(player, Config.Rewards.playCoins * mult, Config.Rewards.playXp, nil)
	QuestManager.record(player, "play", 1)
	if diff.id == "hard" then
		QuestManager.record(player, "hard", 1)
	end
end

-- The daily login streak: the first visit each day (UTC) pays loginCoins x the streak day.
local function login(player, d)
	local today = Quests.today()
	if d.lastDay == today then
		return
	end
	local streak = if d.lastDay == today - 1 then d.loginStreak + 1 else 1
	DataManager.update(player, function(data)
		data.loginStreak, data.lastDay = streak, today
	end)
	local coins = Config.Rewards.loginCoins * math.min(streak, Config.Rewards.loginStreakMax)
	RewardManager.grant(player, coins, 0, "Day " .. streak .. " login bonus")
end

function RewardManager.init()
	DataManager.onLoaded(login)
	QuestManager.grant = RewardManager.grant
end

return RewardManager

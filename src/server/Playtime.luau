-- Time played and days in a row, for the milestone achievements (ConfigCosmetics). Every minute
-- a player is in the game adds to stats.play_seconds; the first visit of each day (UTC) counts a
-- day played and carries the streak on (yesterday too) or starts it again. Totals, never one long
-- sitting: nothing rewards playing without a break.
local Players = game:GetService("Players")

local PlayerData = require(script.Parent.PlayerData)
local Achievements = require(script.Parent.Achievements)

local Playtime = {}

local function today()
	return math.floor(os.time() / 86400)
end

local function visit(player)
	local d = PlayerData.get(player)
	if not d or d.stats.last_day == today() then
		return
	end
	PlayerData.update(player, function(data)
		local s = data.stats
		s.day_streak = if s.last_day == today() - 1 then (s.day_streak or 0) + 1 else 1
		s.days_played = (s.days_played or 0) + 1
		s.last_day = today()
	end)
	Achievements.check(player)
end

function Playtime.init()
	PlayerData.onLoaded(visit)
	task.spawn(function()
		while true do
			task.wait(60)
			for _, player in ipairs(Players:GetPlayers()) do
				if PlayerData.get(player) then
					PlayerData.update(player, function(data)
						data.stats.play_seconds = (data.stats.play_seconds or 0) + 60
					end)
					visit(player) -- past midnight while playing
					Achievements.check(player)
				end
			end
		end
	end)
end

return Playtime

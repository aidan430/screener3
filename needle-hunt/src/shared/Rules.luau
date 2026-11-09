-- The game's arithmetic in one place, shared by the server (which decides) and the client
-- (which only shows): levels, round rewards, and weighted picks. dev/test_rules.py mirrors it.
local Config = require(script.Parent.Config)

local Rules = {}

-- XP needed to go from `level` to the next.
function Rules.xpNeed(level)
	return Config.Levels.xpBase + Config.Levels.xpStep * (level - 1)
end

-- Adds xp to a level/xp pair; returns the new level, the new xp and how many levels it gained.
function Rules.addXp(level, xp, gain)
	xp += gain
	local before = level
	while level < Config.Levels.max and xp >= Rules.xpNeed(level) do
		xp -= Rules.xpNeed(level)
		level += 1
	end
	return level, xp, level - before
end

-- Coins and XP for finding a needle: `place` (1 = first), `elapsed` seconds into a round of
-- `duration`, at difficulty `diff` (a Config.Difficulty row), golden or not, with a win streak.
-- Faster finds pay more: the time bonus falls from 100% to 50% over the round.
function Rules.findReward(place, elapsed, duration, diff, golden, streak, doubleCoins)
	local R = Config.Rewards
	local placeMult = R.place[math.min(place, #R.place)]
	local speed = 0.5 + 0.5 * math.clamp(1 - elapsed / math.max(duration, 1), 0, 1)
	local streakMult = 1 + math.min(R.winStreakMax, R.winStreakStep * math.max(0, streak))
	local mult = placeMult * speed * (diff.coins or 1) * (if golden then R.golden else 1)
	local coins = math.floor(R.findCoins * mult * streakMult * (if doubleCoins then 2 else 1) + 0.5)
	local xp = math.floor(R.findXp * mult + 0.5)
	if place <= 3 then
		coins += R.top3Coins * (if doubleCoins then 2 else 1)
		xp += R.top3Xp
	end
	return coins, xp
end

-- Picks one row from a list of tables with `weight` fields.
function Rules.pick(list, rng)
	local total = 0
	for _, row in ipairs(list) do
		total += row.weight
	end
	local roll = rng:NextNumber() * total
	for _, row in ipairs(list) do
		roll -= row.weight
		if roll <= 0 then
			return row
		end
	end
	return list[#list]
end

-- The ISO-ish week number (weeks since 1970, starting Mondays, UTC): the weekly board's key.
function Rules.week(now)
	return math.floor(((now or os.time()) / 86400 + 3) / 7)
end

-- "1:05" from seconds.
function Rules.clock(seconds)
	seconds = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

-- "12,345".
function Rules.commas(n)
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end

return Rules

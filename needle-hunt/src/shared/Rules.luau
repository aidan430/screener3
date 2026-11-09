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

-- Coins for finishing a round in `place` (1 = first) at difficulty `diff` (a Config.Difficulty
-- row), with a win streak and maybe the 2x Coins pass.
function Rules.placeCoins(place, diff, streak, doubleCoins)
	local R = Config.Rewards
	local base = R.placeCoins[math.min(place, #R.placeCoins)]
	local streakMult = if place == 1 then 1 + math.min(R.winStreakMax, R.winStreakStep * math.max(0, streak)) else 1
	return math.floor(base * (diff.coins or 1) * streakMult * (if doubleCoins then 2 else 1) + 0.5)
end

-- Who placed where: by chests opened, then tag-outs, then coins collected (more is better).
-- Returns the players in order; only players who opened a chest or tagged someone place.
function Rules.rank(stats)
	local list = {}
	for player, s in pairs(stats) do
		if s.chests > 0 or s.elims > 0 then
			table.insert(list, player)
		end
	end
	table.sort(list, function(a, b)
		local x, y = stats[a], stats[b]
		if x.chests ~= y.chests then
			return x.chests > y.chests
		elseif x.elims ~= y.elims then
			return x.elims > y.elims
		end
		return x.coins > y.coins
	end)
	return list
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

-- Daily quests: every day (UTC) everyone gets the same three, picked from this pool, so the
-- lobby's Daily Challenge board can show them. Add a quest by adding a line.
--   kind: what counts (server/QuestManager records these)
--     find      a needle you found            win     a round you won (1st)
--     play      a round you were in at the end fast    a find in under `under` seconds
--     hard      a Hard round you were in at the end    golden  a Golden Needle you found
--   n: how many. Rewards: coins, xp, and sometimes a cosmetic (Cosmetics id).
local Quests = {}

Quests.pool = {
	{ id = "find5", kind = "find", n = 5, text = "Find 5 needles", coins = 150, xp = 200 },
	{ id = "find3", kind = "find", n = 3, text = "Find 3 needles", coins = 90, xp = 120 },
	{ id = "win2", kind = "win", n = 2, text = "Win 2 rounds", coins = 160, xp = 220 },
	{ id = "win1", kind = "win", n = 1, text = "Win a round", coins = 80, xp = 110 },
	{ id = "play10", kind = "play", n = 10, text = "Play 10 rounds", coins = 120, xp = 180 },
	{ id = "play5", kind = "play", n = 5, text = "Play 5 rounds", coins = 60, xp = 90 },
	{ id = "fast60", kind = "fast", n = 1, under = 60, text = "Find a needle in under 60 seconds", coins = 120, xp = 160, cosmetic = "ti_eagle" },
	{ id = "fast30", kind = "fast", n = 1, under = 30, text = "Find a needle in under 30 seconds", coins = 200, xp = 260 },
	{ id = "hard1", kind = "hard", n = 1, text = "Complete a Hard round", coins = 100, xp = 150 },
	{ id = "golden1", kind = "golden", n = 1, text = "Find a Golden Needle", coins = 300, xp = 400 },
	{ id = "finder10", kind = "find", n = 10, text = "Find 10 needles", coins = 260, xp = 350, cosmetic = "ti_finder" },
}

Quests.perDay = 3

-- Today's day number (UTC).
function Quests.today(now)
	return math.floor((now or os.time()) / 86400)
end

-- The three quests for `day`: a fixed shuffle of the pool seeded by the day, so every server
-- agrees. Golden-needle quests are rarer: they're only picked on every fourth day.
function Quests.forDay(day)
	local rng = Random.new(day * 7919 + 17)
	local pool = {}
	for _, q in ipairs(Quests.pool) do
		if q.kind ~= "golden" or day % 4 == 0 then
			table.insert(pool, q)
		end
	end
	local picked, kinds = {}, {}
	while #picked < Quests.perDay and #pool > 0 do
		local q = table.remove(pool, rng:NextInteger(1, #pool))
		if not kinds[q.kind] then -- three different kinds of quest
			kinds[q.kind] = true
			table.insert(picked, q)
		end
	end
	return picked
end

local byId = {}
for _, q in ipairs(Quests.pool) do
	byId[q.id] = q
end

function Quests.get(id)
	return byId[id]
end

return Quests

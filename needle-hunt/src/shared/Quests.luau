-- Daily quests: every day (UTC) everyone gets the same three, picked from this pool, so the
-- lobby's Daily Challenge board can show them. Add a quest by adding a line.
--   kind: what counts (server/QuestManager records these)
--     chest     a chest you opened                     win     a round you won (1st)
--     play      a round you were in at the end         key     a key you found in a chest
--     hard      a Hard round you were in at the end    tagout  a player you tagged out
--     collect   a needle new to your collection        rare    a Rare (or better) needle from a box
--   n: how many. Rewards: coins, xp, and sometimes a cosmetic (Cosmetics id).
local Quests = {}

Quests.pool = {
	{ id = "chest5", kind = "chest", n = 5, text = "Open 5 chests", coins = 150, xp = 200 },
	{ id = "chest3", kind = "chest", n = 3, text = "Open 3 chests", coins = 90, xp = 120 },
	{ id = "win2", kind = "win", n = 2, text = "Win 2 rounds", coins = 160, xp = 220 },
	{ id = "win1", kind = "win", n = 1, text = "Win a round", coins = 80, xp = 110 },
	{ id = "play10", kind = "play", n = 10, text = "Play 10 rounds", coins = 120, xp = 180 },
	{ id = "play5", kind = "play", n = 5, text = "Play 5 rounds", coins = 60, xp = 90 },
	{ id = "key1", kind = "key", n = 1, text = "Find a key in a chest", coins = 120, xp = 160, cosmetic = "ti_eagle" },
	{ id = "tagout3", kind = "tagout", n = 3, text = "Tag out 3 players", coins = 120, xp = 160 },
	{ id = "tagout8", kind = "tagout", n = 8, text = "Tag out 8 players", coins = 220, xp = 300 },
	{ id = "hard1", kind = "hard", n = 1, text = "Complete a Hard round", coins = 100, xp = 150 },
	{ id = "chest12", kind = "chest", n = 12, text = "Open 12 chests", coins = 260, xp = 350, cosmetic = "ti_finder" },
	{ id = "collect3", kind = "collect", n = 3, text = "Add 3 new needles to your collection", coins = 140, xp = 180 },
	{ id = "rare1", kind = "rare", n = 1, text = "Get a Rare (or better) needle from a box", coins = 160, xp = 220 },
}

Quests.perDay = 3

-- Today's day number (UTC).
function Quests.today(now)
	return math.floor((now or os.time()) / 86400)
end

-- The three quests for `day`: a fixed shuffle of the pool seeded by the day, so every server
-- agrees.
function Quests.forDay(day)
	local rng = Random.new(day * 7919 + 17)
	local pool = table.clone(Quests.pool)
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

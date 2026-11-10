-- The match's stats and its end (Config.MatchXp, Config.Rewards): counted while the round runs
-- (RewardManager.track: coins collected, chests opened, players tagged out). At the end, places go
-- by chests, then tag-outs, then coins (shared/Rules.rank); places pay coins; everyone gets XP for
-- their place, every coin, every chest and every tag-out, and sees their own breakdown.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Rules = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Rules"))
local RewardManager = require(script.Parent.RewardManager)

local MatchXp = {}
local stats = nil

function MatchXp.begin(round)
	stats = {}
	for p in pairs(round.participants) do
		stats[p] = { coins = 0, chests = 0, elims = 0, elimWeight = 0, bestStreak = 0 } -- elimWeight: tag-outs x their streak multipliers
	end
	RewardManager.tracker = function(player, what, amount)
		local s = stats and stats[player]
		if s and s[what] then
			s[what] += amount
		end
	end
end

-- This round's stats so far, for the HUD scoreboard: { [player] = { coins, chests, elims } }.
function MatchXp.current()
	return stats
end

-- Places, place coins and XP for everyone. Returns the results rows (in place order) and each
-- player's XP breakdown keyed by tostring(userId).
function MatchXp.finish(round)
	local X = Config.MatchXp
	RewardManager.tracker = nil
	local present = {}
	for p, s in pairs(stats or {}) do
		if p.Parent and round.participants[p] then
			present[p] = s
		end
	end
	local order = Rules.rank(present)
	round.order = order
	local rows, xp = {}, {}
	for place, p in ipairs(order) do
		local s = present[p]
		local coins = RewardManager.placed(p, place, round.diff, round.count)
		table.insert(rows, { name = p.DisplayName, userId = p.UserId, place = place, chests = s.chests, elims = s.elims, coins = s.coins + coins })
	end
	for p, s in pairs(present) do
		local place = table.find(order, p)
		local row = {
			place = place, placeXp = (if place then X.place[math.min(place, #X.place)] else 0) + X.played,
			coins = s.coins, coinXp = math.floor(s.coins * X.perCoin + 0.5),
			chests = s.chests, chestXp = s.chests * X.perChest,
			elims = s.elims, elimXp = math.floor(s.elimWeight * X.perElimination + 0.5), bestStreak = s.bestStreak,
		}
		row.total = row.placeXp + row.coinXp + row.chestXp + row.elimXp
		RewardManager.grant(p, 0, row.total, nil)
		xp[tostring(p.UserId)] = row
	end
	stats = nil
	return rows, xp
end

-- A round that ended early (an error): nothing more is counted.
function MatchXp.cancel()
	RewardManager.tracker = nil
	stats = nil
end

return MatchXp

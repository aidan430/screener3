-- XP after each match (Config.MatchXp): for where you placed, every coin you collected in the
-- match, every needle you found and every player you tagged out. Counted while the round runs
-- (RewardManager.track) and given at the results, where each player sees their own breakdown.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local RewardManager = require(script.Parent.RewardManager)

local MatchXp = {}
local stats = nil

function MatchXp.begin(round)
	stats = {}
	for p in pairs(round.participants) do
		stats[p] = { coins = 0, needles = 0, elims = 0 }
	end
	RewardManager.tracker = function(player, what, amount)
		local s = stats and stats[player]
		if s and s[what] then
			s[what] += amount
		end
	end
end

-- Gives everyone their match XP. Returns each player's breakdown, keyed by tostring(userId).
function MatchXp.finish(round)
	local X = Config.MatchXp
	local out = {}
	RewardManager.tracker = nil
	for p, s in pairs(stats or {}) do
		if p.Parent and round.participants[p] then
			local place = table.find(round.order, p)
			local placeXp = (if place then X.place[math.min(place, #X.place)] else 0) + X.played
			local row = {
				place = place, placeXp = placeXp,
				coins = s.coins, coinXp = math.floor(s.coins * X.perCoin + 0.5),
				needles = s.needles, needleXp = s.needles * X.perNeedle,
				elims = s.elims, elimXp = s.elims * X.perElimination,
			}
			row.total = row.placeXp + row.coinXp + row.needleXp + row.elimXp
			RewardManager.grant(p, 0, row.total, nil)
			out[tostring(p.UserId)] = row
		end
	end
	stats = nil
	return out
end

-- A round that ended early (an error): nothing more is counted.
function MatchXp.cancel()
	RewardManager.tracker = nil
	stats = nil
end

return MatchXp

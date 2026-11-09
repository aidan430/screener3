-- What runs alongside a round's search, started and stopped together by server/RoundManager:
-- the power-ups (server/Powerups), needle combat (server/Combat) and the match XP count
-- (server/MatchXp).
local Powerups = require(script.Parent.Powerups)
local Combat = require(script.Parent.Combat)
local MatchXp = require(script.Parent.MatchXp)

local RoundExtras = {}

function RoundExtras.start(ctx, round)
	MatchXp.begin(round)
	Combat.start(round)
	Powerups.start(ctx, round)
end

-- At the results: the match XP for everyone (returns the breakdowns), then combat stops.
function RoundExtras.finish(round)
	Combat.stop()
	return MatchXp.finish(round)
end

function RoundExtras.stop()
	Combat.stop()
	MatchXp.cancel()
	Powerups.stop()
end

return RoundExtras

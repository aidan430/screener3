-- Coins, search power, needle odds and haystack size. Plain maths: no Roblox services.
-- Usage: local Economy = require(Shared.Economy)(Config)
return function(Config)
	local Economy = {}

	function Economy.tool(level)
		local tools = Config.Tools
		return tools[math.clamp(level, 1, #tools)]
	end

	-- straws searched in one go with this tool
	function Economy.power(level)
		return Economy.tool(level).power
	end

	function Economy.multiplier(rebirths, doubleCoins)
		local m = 1 + Config.RebirthCoinBonus * rebirths
		if doubleCoins then
			m *= 2
		end
		return m
	end

	function Economy.coinsFor(straws, multiplier)
		if straws <= 0 then
			return 0
		end
		return math.floor(straws * Config.CoinsPerStraw * multiplier + 0.5)
	end

	function Economy.rebirthCost(rebirths)
		return Config.RebirthBaseCost * (rebirths + 1)
	end

	-- The needle is equally likely to be any straw still in its haystack, so a handful of
	-- straws finds it with probability handful / remaining. The last handful always does.
	function Economy.needleChance(handful, remaining)
		if remaining <= 0 then
			return 0
		end
		return math.min(1, handful / remaining)
	end

	-- A haystack's size follows the cube root of what is left (its volume shrinks with it).
	function Economy.pileScale(remaining, total)
		if total <= 0 then
			return Config.MinPileScale
		end
		local left = math.clamp(remaining / total, 0, 1)
		return Config.MinPileScale + (1 - Config.MinPileScale) * left ^ (1 / 3)
	end

	return Economy
end

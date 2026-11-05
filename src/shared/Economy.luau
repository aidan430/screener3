-- Rates, prices and odds. Plain maths: no Roblox services.
-- Usage: local Economy = require(Shared.Economy)(Config)
return function(Config)
	local Economy = {}

	local function perkLevel(data, id)
		return (data.perks and data.perks[id]) or 0
	end

	function Economy.tool(level)
		return Config.Tools[math.clamp(level, 1, #Config.Tools)]
	end

	function Economy.bag(level)
		return Config.Bags[math.clamp(level, 1, #Config.Bags)]
	end

	-- straws one search takes, with the Sharpened perk and any speed boost
	function Economy.power(data, speedBoost)
		local p = Economy.tool(data.tool).power * (1 + Config.Perks[1].per_level * perkLevel(data, "sharp"))
		if speedBoost then
			p *= 2
		end
		return math.max(1, math.floor(p + 0.5))
	end

	function Economy.cooldown(data)
		return Config.SearchCooldown * (1 - Config.Perks[2].per_level * perkLevel(data, "swift"))
	end

	function Economy.luckyChance(data, charm)
		local c = Config.LuckyChance + Config.Perks[3].per_level * perkLevel(data, "lucky")
		return if charm then c * 5 else c
	end

	-- straws a second from the player's machines
	function Economy.machineRate(data, doubled)
		local rate = 0
		for i, m in ipairs(Config.Machines) do
			rate += ((data.machines and data.machines[i]) or 0) * m.rate
		end
		return if doubled then rate * 2 else rate
	end

	function Economy.machineCount(data)
		local n = 0
		for i in ipairs(Config.Machines) do
			n += (data.machines and data.machines[i]) or 0
		end
		return n
	end

	function Economy.machinePrice(index, owned)
		local m = Config.Machines[index]
		return math.floor(m.price * m.growth ^ owned + 0.5)
	end

	-- perks are priced for the tool you hold: the free fork pays Wooden Pitchfork prices
	function Economy.perkPrice(data, perkIndex)
		local perk = Config.Perks[perkIndex]
		local level = perkLevel(data, perk.id)
		local scale = math.max(Economy.tool(data.tool).price, Config.Tools[2].price) / Config.Tools[2].price
		return math.floor(perk.price * perk.growth ^ level * scale + 0.5)
	end

	function Economy.perksMaxed(data)
		for _, perk in ipairs(Config.Perks) do
			if perkLevel(data, perk.id) < perk.levels then
				return false
			end
		end
		return true
	end

	function Economy.coinMultiplier(flags)
		local m = 1
		if flags.vip then
			m += Config.VipCoinBonus
		end
		if flags.coinBoost then
			m *= 2
		end
		return m
	end

	-- what the merchant pays for `straws` straws (golden straws pay Loft.coinMultiplier more)
	function Economy.coinsFor(straws, golden, multiplier)
		local each = Config.CoinsPerStraw * (if golden then Config.Loft.coinMultiplier else 1)
		return math.floor(straws * each * multiplier + 0.5)
	end

	-- where the needle hides: a straw index, never in the first `earliest` share
	function Economy.needleAt(total, earliest, rng)
		return math.floor(total * earliest + rng:NextNumber() * total * (1 - earliest)) + 1
	end

	-- 0 (cold) to 1 (the next handful has it): how warm the Needle Detector shows
	function Economy.warmth(searched, needleAt, total)
		local left = needleAt - searched
		if left <= 0 then
			return 1
		end
		return math.clamp(1 - left / (total * 0.1), 0, 1)
	end

	return Economy
end

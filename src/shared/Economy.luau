-- Rates, prices, power and odds. Plain maths: no Roblox services.
-- Usage: local Economy = require(Shared.Economy)(Config)
return function(Config)
	local Economy = {}

	Economy.STRAWS_PER_CLUMP = Config.TotalStraws // Config.Clumps

	-- every buildable item by id: { def = ..., kind = "piece" | "machine" | "generator" }
	local items = {}
	for kind, list in pairs({ piece = Config.Pieces, machine = Config.Machines, generator = Config.Generators }) do
		for _, def in ipairs(list) do
			items[def.id] = { def = def, kind = kind }
		end
	end

	function Economy.item(id)
		return items[id]
	end

	local function perkLevel(data, id)
		return (data.perks and data.perks[id]) or 0
	end

	function Economy.tool(level)
		return Config.Tools[math.clamp(level, 1, #Config.Tools)]
	end

	function Economy.silo(level)
		return Config.Silos[math.clamp(level, 1, #Config.Silos)]
	end

	-- straws one click takes, with the Sharpened perk and any speed boost
	function Economy.power(data, speedBoost)
		local p = Economy.tool(data.tool).power * (1 + Config.Perks[1].per_level * perkLevel(data, "sharp"))
		if speedBoost then
			p *= 2
		end
		return math.max(1, math.floor(p + 0.5))
	end

	function Economy.capacity(data)
		return Economy.tool(data.tool).capacity
	end

	function Economy.cooldown(data)
		return Config.SearchCooldown * (1 - Config.Perks[2].per_level * perkLevel(data, "swift"))
	end

	function Economy.luckyChance(data, charm)
		local c = Config.LuckyChance + Config.Perks[3].per_level * perkLevel(data, "lucky")
		return if charm then c * 5 else c
	end

	-- Power made, power drawn, machines placed and straws a second, from the placed list.
	function Economy.plot(placed, doubleMachines)
		local made, draw, rate, machines = 0, 0, 0, 0
		for _, p in ipairs(placed or {}) do
			local item = items[p.k]
			if item and item.kind == "generator" then
				made += item.def.power
			elseif item and item.kind == "machine" then
				draw += item.def.draw
				rate += item.def.rate
				machines += 1
			end
		end
		local share = if draw > 0 then math.min(1, made / draw) else 0
		rate *= share * (if doubleMachines then 2 else 1)
		return { made = made, draw = draw, rate = rate, machines = machines, share = share }
	end

	-- how many of an item a player has bought (in their inventory or placed)
	function Economy.owned(data, id)
		local n = (data.inventory and data.inventory[id]) or 0
		for _, p in ipairs(data.placed or {}) do
			if p.k == id then
				n += 1
			end
		end
		return n
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

	function Economy.coinMultiplier(flags, needles)
		local m = 1 + 0.2 * (needles or 0)
		if flags.vip then
			m += Config.VipCoinBonus
		end
		if flags.coinBoost then
			m *= 2
		end
		return m
	end

	function Economy.coinsFor(straws, golden, multiplier)
		local each = Config.CoinsPerStraw * (if golden then Config.Loft.coinMultiplier else 1)
		return math.floor(straws * each * multiplier + 0.5)
	end

	-- the loft's golden haystack still hides its needle at a straw index
	function Economy.needleAt(total, earliest, rng)
		return math.floor(total * earliest + rng:NextNumber() * total * (1 - earliest)) + 1
	end

	-- the Needle Detector: how close (studs) you are to the needle's clump, in words
	function Economy.warmth(distance)
		if distance <= 15 then
			return "BURNING HOT! It's right here"
		elseif distance <= 40 then
			return "hot"
		elseif distance <= 90 then
			return "warm"
		end
		return "cold"
	end

	-- the Wheel of Fortune: total weight and each prize's chance (0-1)
	function Economy.wheelOdds()
		local total = 0
		for _, prize in ipairs(Config.Wheel) do
			total += prize.weight
		end
		local odds = {}
		for i, prize in ipairs(Config.Wheel) do
			odds[i] = prize.weight / total
		end
		return odds, total
	end

	function Economy.spin(rng)
		local _, total = Economy.wheelOdds()
		local roll = rng:NextInteger(1, total)
		for i, prize in ipairs(Config.Wheel) do
			roll -= prize.weight
			if roll <= 0 then
				return i, prize
			end
		end
		return #Config.Wheel, Config.Wheel[#Config.Wheel]
	end

	return Economy
end

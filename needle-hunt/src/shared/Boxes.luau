-- Boxes (Config.Boxes): what's inside each, the exact odds, and the roll. Shared so the Boxes
-- screen shows the same odds and the same skins the server uses. The server rolls; the reel on
-- your screen only shows the result it was given.
local Config = require(script.Parent.Config)
local Needles = require(script.Parent.Needles)

local Boxes = {}

local byId = {}
for _, box in ipairs(Config.Boxes.list) do
	byId[box.id] = box
end

function Boxes.get(id)
	return byId[id]
end

-- The skins a box can give at a rarity: its series' own, or the regular ones if the series has
-- none at that rarity (and the Hay Box, which has no series, always gives regular ones).
function Boxes.skins(box, rarityId)
	local own, regular = {}, {}
	for _, s in ipairs(Needles.skins) do
		if s.rarity == rarityId then
			if box.series and s.series == box.series then
				table.insert(own, s)
			elseif not s.series then
				table.insert(regular, s)
			end
		end
	end
	return if #own > 0 then own else regular
end

-- Each rarity's chance in percent, in rarity order (the odds shown before opening).
function Boxes.odds(box)
	local total = 0
	for _, r in ipairs(Needles.rarities) do
		total += box.odds[r.id] or 0
	end
	local out = {}
	for _, r in ipairs(Needles.rarities) do
		local w = box.odds[r.id] or 0
		if w > 0 then
			table.insert(out, { rarity = r, percent = w / total * 100 })
		end
	end
	return out
end

-- A tiered box (box.tiers, the Heirloom Box): each tier's chance and what it holds, for the odds
-- shown before opening. A grade tier lists its shapes, each with its own chance in the box.
function Boxes.tiers(box)
	local out = {}
	for _, tier in ipairs(box.tiers or {}) do
		local row = { tier = tier, percent = tier.percent, shapes = {} }
		if tier.grade then
			row.grade = Needles.grade(tier.grade)
			local total = 0
			for _, t in ipairs(Needles.types) do
				total += if t.grade == tier.grade then t.weight else 0
			end
			for _, t in ipairs(Needles.types) do
				if t.grade == tier.grade then
					table.insert(row.shapes, { type = t, percent = tier.percent * t.weight / total })
				end
			end
		else
			row.rarity = Needles.rarity(tier.rarity)
		end
		table.insert(out, row)
	end
	return out
end

local function skinRoll(box, rarityId, rng, pityHit)
	local rareMult = Needles.rarity("rare").mult
	local rarity = rarityId and Needles.rarity(rarityId) or Needles.pick(Needles.rarities, function(r)
		local w = box.odds[r.id] or 0
		return if pityHit and r.mult < rareMult then 0 else w
	end, rng)
	local skins = Boxes.skins(box, rarity.id)
	return skins[rng:NextInteger(1, #skins)].id
end

-- Rolls a box. pityHit = this open is guaranteed Rare or better (Config.Boxes.pity). Returns
-- typeId, skinId, and for a tiered box how likely that pull was (percent, for announcements).
function Boxes.roll(box, rng, pityHit)
	if box.tiers then
		local row = Needles.pick(Boxes.tiers(box), function(r)
			return r.percent
		end, rng)
		if row.grade then
			local pick = Needles.pick(row.shapes, function(sh)
				return sh.percent
			end, rng)
			return pick.type.id, skinRoll(box, nil, rng, pityHit), pick.percent
		end
		local t = Needles.pick(Needles.types, function(r)
			return r.weight
		end, rng)
		return t.id, skinRoll(box, row.rarity.id, rng, pityHit), row.percent
	end
	local t = Needles.pick(Needles.types, function(row)
		return row.weight
	end, rng)
	return t.id, skinRoll(box, nil, rng, pityHit)
end

-- A filler card for the reel (looks only), by the same odds.
function Boxes.filler(box, rng)
	return Boxes.roll(box, rng, false)
end

return Boxes

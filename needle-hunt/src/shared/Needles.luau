-- The needle collection. Everyone hunts the same plain needle (fair); when you find it, it turns
-- out to be one TYPE (its shape) in one SKIN (its look), and it's yours to keep. Every type comes
-- in every skin, so the collection has types x skins entries (12 x 32 = 384).
--   value: what one is worth = type.value x the skin's rarity multiplier. A collection's value
--   is the sum of the different needles in it (duplicates show as x2, x3 but add nothing).
-- Skins are recipes, not pictures: colours, a material and a pattern, drawn by shared/NeedleLook.
--   pattern: solid | two (eye/tip in the second colour) | stripes | gradient | rainbow
--   glow = true lights it up; sparkle = true adds twinkles. Add a skin or a type with a line.
-- Collectibles are only earned by finding needles: never sold, never from anything paid.
local Needles = {}

Needles.rarities = {
	{ id = "common", name = "Common", weight = 55, mult = 1, colour = { 190, 196, 206 } },
	{ id = "uncommon", name = "Uncommon", weight = 25, mult = 2, colour = { 110, 200, 120 } },
	{ id = "rare", name = "Rare", weight = 12, mult = 5, colour = { 90, 150, 240 } },
	{ id = "epic", name = "Epic", weight = 6, mult = 12, colour = { 170, 110, 240 } },
	{ id = "legendary", name = "Legendary", weight = 1.8, mult = 40, colour = { 255, 190, 60 } },
	{ id = "mythic", name = "Mythic", weight = 0.2, mult = 150, colour = { 255, 110, 170 } },
}

-- Types: the needle's shape (see NeedleLook). weight = how often it turns up; value = its base worth.
Needles.types = {
	{ id = "sewing", name = "Sewing Needle", weight = 20, value = 10 },
	{ id = "pin", name = "Dressmaker's Pin", weight = 16, value = 8 },
	{ id = "quilting", name = "Quilting Needle", weight = 12, value = 12 },
	{ id = "darning", name = "Darning Needle", weight = 10, value = 14 },
	{ id = "embroidery", name = "Embroidery Needle", weight = 9, value = 16 },
	{ id = "tapestry", name = "Tapestry Needle", weight = 8, value = 18 },
	{ id = "safety", name = "Safety Pin", weight = 8, value = 15 },
	{ id = "knitting", name = "Knitting Needle", weight = 6, value = 22 },
	{ id = "crochet", name = "Crochet Hook", weight = 5, value = 24 },
	{ id = "bodkin", name = "Bodkin", weight = 3, value = 26 },
	{ id = "curved", name = "Curved Upholstery Needle", weight = 2, value = 30 },
	{ id = "sailmaker", name = "Sailmaker's Needle", weight = 1, value = 36 },
}

Needles.skins = {
	-- Common
	{ id = "steel", name = "Steel", rarity = "common", colours = { { 200, 205, 215 }, { 150, 156, 168 } }, material = "Metal", pattern = "solid" },
	{ id = "iron", name = "Iron", rarity = "common", colours = { { 120, 124, 132 }, { 90, 92, 100 } }, material = "Metal", pattern = "solid" },
	{ id = "brass", name = "Brass", rarity = "common", colours = { { 214, 176, 90 }, { 180, 140, 60 } }, material = "Metal", pattern = "solid" },
	{ id = "copper", name = "Copper", rarity = "common", colours = { { 196, 116, 70 }, { 150, 84, 50 } }, material = "Metal", pattern = "solid" },
	{ id = "bone", name = "Bone", rarity = "common", colours = { { 236, 228, 206 }, { 200, 188, 160 } }, material = "SmoothPlastic", pattern = "solid" },
	{ id = "oak", name = "Oak", rarity = "common", colours = { { 160, 118, 74 }, { 120, 86, 52 } }, material = "Wood", pattern = "solid" },
	{ id = "pewter", name = "Pewter", rarity = "common", colours = { { 160, 164, 170 }, { 200, 204, 210 } }, material = "Metal", pattern = "two" },
	{ id = "ink", name = "Ink", rarity = "common", colours = { { 40, 44, 56 }, { 90, 96, 110 } }, material = "SmoothPlastic", pattern = "two" },
	-- Uncommon
	{ id = "rosegold", name = "Rose Gold", rarity = "uncommon", colours = { { 236, 170, 160 }, { 200, 130, 120 } }, material = "Metal", pattern = "solid" },
	{ id = "bronze", name = "Bronze", rarity = "uncommon", colours = { { 176, 120, 60 }, { 230, 190, 120 } }, material = "Metal", pattern = "two" },
	{ id = "jade", name = "Jade", rarity = "uncommon", colours = { { 90, 170, 120 }, { 160, 220, 180 } }, material = "Glass", pattern = "gradient" },
	{ id = "cobalt", name = "Cobalt", rarity = "uncommon", colours = { { 50, 90, 200 }, { 150, 180, 255 } }, material = "Metal", pattern = "two" },
	{ id = "mint", name = "Mint", rarity = "uncommon", colours = { { 170, 240, 210 }, { 255, 255, 255 } }, material = "SmoothPlastic", pattern = "stripes" },
	{ id = "lavender", name = "Lavender", rarity = "uncommon", colours = { { 190, 160, 230 }, { 240, 220, 255 } }, material = "SmoothPlastic", pattern = "gradient" },
	{ id = "bumblebee", name = "Bumblebee", rarity = "uncommon", colours = { { 255, 210, 50 }, { 40, 36, 40 } }, material = "SmoothPlastic", pattern = "stripes" },
	-- Rare
	{ id = "frost", name = "Frost", rarity = "rare", colours = { { 170, 225, 255 }, { 255, 255, 255 } }, material = "Ice", pattern = "gradient", sparkle = true },
	{ id = "ember", name = "Ember", rarity = "rare", colours = { { 255, 120, 40 }, { 120, 30, 20 } }, material = "Neon", pattern = "gradient" },
	{ id = "ocean", name = "Ocean", rarity = "rare", colours = { { 40, 120, 200 }, { 120, 230, 240 } }, material = "Glass", pattern = "gradient" },
	{ id = "sakura", name = "Sakura", rarity = "rare", colours = { { 255, 190, 210 }, { 255, 240, 245 } }, material = "SmoothPlastic", pattern = "stripes", sparkle = true },
	{ id = "zebra", name = "Zebra", rarity = "rare", colours = { { 245, 245, 245 }, { 30, 30, 30 } }, material = "SmoothPlastic", pattern = "stripes" },
	{ id = "toxic", name = "Toxic", rarity = "rare", colours = { { 120, 255, 80 }, { 40, 80, 30 } }, material = "Neon", pattern = "two" },
	-- Epic
	{ id = "midnight", name = "Midnight", rarity = "epic", colours = { { 50, 40, 110 }, { 140, 120, 255 } }, material = "Neon", pattern = "gradient", sparkle = true },
	{ id = "aurora", name = "Aurora", rarity = "epic", colours = { { 80, 255, 180 }, { 160, 90, 255 } }, material = "Neon", pattern = "gradient" },
	{ id = "lava", name = "Lava", rarity = "epic", colours = { { 255, 80, 20 }, { 40, 20, 20 } }, material = "Neon", pattern = "stripes" },
	{ id = "candycane", name = "Candy Cane", rarity = "epic", colours = { { 230, 40, 50 }, { 255, 255, 255 } }, material = "SmoothPlastic", pattern = "stripes" },
	{ id = "galaxy", name = "Galaxy", rarity = "epic", colours = { { 40, 20, 80 }, { 230, 120, 255 } }, material = "Neon", pattern = "gradient", sparkle = true },
	-- Legendary
	{ id = "golden", name = "Golden", rarity = "legendary", colours = { { 255, 205, 70 }, { 255, 240, 170 } }, material = "Metal", pattern = "two", glow = true, sparkle = true },
	{ id = "diamond", name = "Diamond", rarity = "legendary", colours = { { 220, 245, 255 }, { 255, 255, 255 } }, material = "Glass", pattern = "solid", sparkle = true },
	{ id = "phoenix", name = "Phoenix", rarity = "legendary", colours = { { 255, 200, 60 }, { 255, 60, 30 } }, material = "Neon", pattern = "gradient", sparkle = true },
	{ id = "rainbow", name = "Rainbow", rarity = "legendary", colours = { { 255, 255, 255 }, { 255, 255, 255 } }, material = "Neon", pattern = "rainbow" },
	-- Mythic
	{ id = "starlight", name = "Starlight", rarity = "mythic", colours = { { 255, 255, 255 }, { 180, 220, 255 } }, material = "Neon", pattern = "gradient", glow = true, sparkle = true },
	{ id = "prism", name = "Prism", rarity = "mythic", colours = { { 255, 255, 255 }, { 255, 255, 255 } }, material = "Glass", pattern = "rainbow", glow = true, sparkle = true },
}

local byType, bySkin, byRarity = {}, {}, {}
for _, t in ipairs(Needles.types) do
	byType[t.id] = t
end
for _, s in ipairs(Needles.skins) do
	bySkin[s.id] = s
end
for _, r in ipairs(Needles.rarities) do
	byRarity[r.id] = r
end
function Needles.type(id)
	return byType[id]
end

function Needles.skin(id)
	return bySkin[id]
end

function Needles.rarity(id)
	return byRarity[id]
end

-- "darning:ember" for a type and a skin (how a collection saves them), and back.
function Needles.key(typeId, skinId)
	return typeId .. ":" .. skinId
end

function Needles.split(key)
	local t, s = string.match(key or "", "^(%w+):(%w+)$")
	if byType[t] and bySkin[s] then
		return t, s
	end
	return nil, nil
end

function Needles.name(typeId, skinId)
	return bySkin[skinId].name .. " " .. byType[typeId].name
end

function Needles.value(typeId, skinId)
	return byType[typeId].value * byRarity[bySkin[skinId].rarity].mult
end

-- A collection's total value: each different needle once.
function Needles.total(collection)
	local sum = 0
	for key in pairs(collection) do
		local t, s = Needles.split(key)
		if t then
			sum += Needles.value(t, s)
		end
	end
	return sum
end

local function pick(list, weightOf, rng)
	local total = 0
	for _, row in ipairs(list) do
		total += weightOf(row)
	end
	local roll = rng:NextNumber() * total
	for _, row in ipairs(list) do
		roll -= weightOf(row)
		if roll <= 0 then
			return row
		end
	end
	return list[#list]
end

-- Which needle a find turns out to be. luck (1 = normal) multiplies the chance of every rarity
-- above Common; golden = the Golden Needle event, which is always a Golden skin.
function Needles.roll(rng, luck, golden)
	local t = pick(Needles.types, function(row)
		return row.weight
	end, rng)
	if golden then
		return t.id, "golden"
	end
	local rarity = pick(Needles.rarities, function(row)
		return if row.id == "common" then row.weight else row.weight * luck
	end, rng)
	local skins = {}
	for _, s in ipairs(Needles.skins) do
		if s.rarity == rarity.id then
			table.insert(skins, s)
		end
	end
	return t.id, skins[rng:NextInteger(1, #skins)].id
end

return Needles

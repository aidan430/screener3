-- The needle collection. Everyone hunts the same plain needle (fair); when you find it, it turns
-- out to be one TYPE (its shape) in one SKIN (its look), and it's yours to keep. Every type comes
-- in every skin, so the collection has types x skins entries (36 x 60 = 2,160, plus the 1 of 1).
--   value: what one is worth = type.value x the skin's rarity multiplier. A collection's value
--   is the sum of the different needles in it (duplicates show as x2, x3 but add nothing).
-- Skins are recipes, not pictures: colours, a material and a pattern, drawn by shared/NeedleLook.
--   pattern: solid | two (eye/tip in the second colour) | stripes | gradient | rainbow | bands
--   (thin bands of the second colour) | sheen (light running along it) | split (two halves) |
--   tri (three colours, the third on the eye) | candy (all its colours in turn)
--   glow = true lights it up; sparkle = true adds twinkles. Add a skin or a type with a line.
--   series = a box's own skin: only from that box (Config.Boxes), never from a find.
-- Needles come from finds and from boxes (odds shown before opening), and can be traded.
local Needles = {}

Needles.rarities = {
	{ id = "common", name = "Common", weight = 55, mult = 1, colour = { 190, 196, 206 } },
	{ id = "uncommon", name = "Uncommon", weight = 25, mult = 2, colour = { 110, 200, 120 } },
	{ id = "rare", name = "Rare", weight = 12, mult = 5, colour = { 90, 150, 240 } },
	{ id = "epic", name = "Epic", weight = 6, mult = 12, colour = { 170, 110, 240 } },
	{ id = "legendary", name = "Legendary", weight = 1.8, mult = 40, colour = { 255, 190, 60 } },
	{ id = "mythic", name = "Mythic", weight = 0.2, mult = 150, colour = { 255, 110, 170 } },
	{ id = "unique", name = "1 of 1", weight = 0, mult = 5000, colour = { 225, 240, 255 } }, -- never rolled: see Config.OneOfOne
}

-- Grades: how special a shape is. The novelty shapes turn up far less often and are worth more.
Needles.grades = {
	{ id = "classic", name = "Classic", colour = { 190, 196, 206 } },
	{ id = "fancy", name = "Fancy", colour = { 110, 200, 160 } },
	{ id = "exotic", name = "Exotic", colour = { 90, 170, 255 } },
	{ id = "masterwork", name = "Masterwork", colour = { 255, 190, 60 } },
}

-- Types: the needle's shape (see NeedleLook). weight = how often it turns up (out of all the
-- weights together); value = its base worth (times the skin's rarity); grade = see above.
Needles.types = {
	{ id = "sewing", name = "Sewing Needle", weight = 20, value = 10, grade = "classic" },
	{ id = "pin", name = "Dressmaker's Pin", weight = 16, value = 8, grade = "classic" },
	{ id = "quilting", name = "Quilting Needle", weight = 12, value = 12, grade = "classic" },
	{ id = "darning", name = "Darning Needle", weight = 10, value = 14, grade = "classic" },
	{ id = "embroidery", name = "Embroidery Needle", weight = 9, value = 16, grade = "classic" },
	{ id = "tapestry", name = "Tapestry Needle", weight = 8, value = 18, grade = "classic" },
	{ id = "safety", name = "Safety Pin", weight = 8, value = 15, grade = "classic" },
	{ id = "knitting", name = "Knitting Needle", weight = 6, value = 22, grade = "classic" },
	{ id = "crochet", name = "Crochet Hook", weight = 5, value = 24, grade = "classic" },
	{ id = "bodkin", name = "Bodkin", weight = 3, value = 26, grade = "classic" },
	{ id = "curved", name = "Curved Upholstery Needle", weight = 2, value = 30, grade = "classic" },
	{ id = "sailmaker", name = "Sailmaker's Needle", weight = 1, value = 36, grade = "classic" },
	{ id = "firework", name = "Firework Needle", weight = 2.5, value = 45, grade = "fancy" },
	{ id = "jackhammer", name = "Jackhammer Needle", weight = 2, value = 50, grade = "fancy" },
	{ id = "swordfish", name = "Swordfish Needle", weight = 0.7, value = 65, grade = "exotic" },
	{ id = "shootingstar", name = "Shooting Star Needle", weight = 0.3, value = 90, grade = "masterwork" },
	-- shapes kept as data (shared/ShapesA and ShapesB, made by dev/shapes.py)
	{ id = "pencil", name = "Pencil Needle", weight = 1.2, value = 40, grade = "fancy" },
	{ id = "candle", name = "Candle Needle", weight = 1.0, value = 45, grade = "fancy" },
	{ id = "wand", name = "Wand Needle", weight = 0.9, value = 50, grade = "fancy" },
	{ id = "paintbrush", name = "Paintbrush Needle", weight = 1.0, value = 45, grade = "fancy" },
	{ id = "lollipop", name = "Lollipop Needle", weight = 1.1, value = 42, grade = "fancy" },
	{ id = "fork", name = "Fork Needle", weight = 1.2, value = 40, grade = "fancy" },
	{ id = "umbrella", name = "Umbrella Needle", weight = 0.9, value = 48, grade = "fancy" },
	{ id = "carrot", name = "Carrot Needle", weight = 1.2, value = 42, grade = "fancy" },
	{ id = "pitchfork", name = "Pitchfork Needle", weight = 1.0, value = 50, grade = "fancy" },
	{ id = "icecream", name = "Ice Cream Needle", weight = 1.0, value = 52, grade = "fancy" },
	{ id = "narwhal", name = "Narwhal Needle", weight = 0.6, value = 72, grade = "exotic" },
	{ id = "hummingbird", name = "Hummingbird Needle", weight = 0.6, value = 68, grade = "exotic" },
	{ id = "porcupine", name = "Porcupine Quill", weight = 0.7, value = 62, grade = "exotic" },
	{ id = "icicle", name = "Icicle Needle", weight = 0.8, value = 60, grade = "exotic" },
	{ id = "thornyrose", name = "Thorny Rose Needle", weight = 0.5, value = 70, grade = "exotic" },
	{ id = "lightning", name = "Lightning Bolt Needle", weight = 0.2, value = 100, grade = "masterwork" },
	{ id = "rocketship", name = "Rocket Ship Needle", weight = 0.25, value = 95, grade = "masterwork" },
	{ id = "cometspear", name = "Comet Spear", weight = 0.3, value = 88, grade = "masterwork" },
	{ id = "dragontooth", name = "Dragon's Tooth", weight = 0.15, value = 105, grade = "masterwork" },
	{ id = "crystalshard", name = "Crystal Shard Needle", weight = 0.2, value = 92, grade = "masterwork" },
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
	{ id = "prism", name = "Prism", rarity = "mythic", colours = { { 255, 255, 255 }, { 255, 255, 255 } }, material = "Glass", pattern = "rainbow", glow = true, sparkle = true },	-- the newer regular skins
	{ id = "denim", name = "Denim", rarity = "common", colours = { { 70, 100, 150 }, { 230, 200, 120 } }, material = "Fabric", pattern = "bands" },
	{ id = "chrome", name = "Chrome", rarity = "uncommon", colours = { { 150, 156, 170 }, { 250, 252, 255 } }, material = "Metal", pattern = "sheen" },
	{ id = "koi", name = "Koi", rarity = "rare", colours = { { 255, 120, 50 }, { 250, 248, 240 } }, material = "SmoothPlastic", pattern = "split" },
	{ id = "peppermint", name = "Peppermint", rarity = "rare", colours = { { 230, 40, 60 }, { 255, 255, 255 }, { 60, 180, 110 } }, material = "SmoothPlastic", pattern = "candy" },
	{ id = "thunder", name = "Thunder", rarity = "epic", colours = { { 255, 220, 60 }, { 40, 50, 100 } }, material = "Neon", pattern = "split", sparkle = true },
	-- Harvest Series (the Harvest Box only)
	{ id = "twine", name = "Twine", rarity = "common", series = "harvest", colours = { { 200, 160, 100 }, { 130, 90, 50 } }, material = "Fabric", pattern = "bands" },
	{ id = "barnwood", name = "Barnwood", rarity = "common", series = "harvest", colours = { { 150, 60, 50 }, { 230, 220, 200 } }, material = "Wood", pattern = "two" },
	{ id = "pumpkin", name = "Pumpkin", rarity = "uncommon", series = "harvest", colours = { { 250, 140, 40 }, { 80, 140, 60 } }, material = "SmoothPlastic", pattern = "two" },
	{ id = "clover", name = "Clover", rarity = "uncommon", series = "harvest", colours = { { 90, 180, 90 }, { 245, 250, 240 } }, material = "SmoothPlastic", pattern = "bands" },
	{ id = "sunflower", name = "Sunflower", rarity = "rare", series = "harvest", colours = { { 255, 210, 50 }, { 120, 70, 30 } }, material = "SmoothPlastic", pattern = "sheen" },
	{ id = "orchard", name = "Orchard", rarity = "rare", series = "harvest", colours = { { 210, 40, 50 }, { 120, 190, 70 } }, material = "SmoothPlastic", pattern = "split" },
	{ id = "harvestmoon", name = "Harvest Moon", rarity = "epic", series = "harvest", colours = { { 255, 150, 50 }, { 255, 230, 160 } }, material = "Neon", pattern = "sheen", glow = true },
	{ id = "scarecrow", name = "Scarecrow", rarity = "epic", series = "harvest", colours = { { 230, 190, 90 }, { 70, 100, 160 }, { 200, 50, 50 } }, material = "Fabric", pattern = "tri" },
	{ id = "goldenwheat", name = "Golden Wheat", rarity = "legendary", series = "harvest", colours = { { 255, 200, 70 }, { 200, 140, 40 } }, material = "Metal", pattern = "bands", glow = true, sparkle = true },
	{ id = "cornucopia", name = "Cornucopia", rarity = "mythic", series = "harvest", colours = { { 255, 120, 40 }, { 220, 40, 60 }, { 255, 210, 70 } }, material = "Neon", pattern = "candy", glow = true, sparkle = true },
	-- Starlight Series (the Starlight Box only)
	{ id = "moonstone", name = "Moonstone", rarity = "uncommon", series = "starlight", colours = { { 200, 210, 235 }, { 255, 255, 255 } }, material = "Glass", pattern = "sheen" },
	{ id = "dusk", name = "Dusk", rarity = "uncommon", series = "starlight", colours = { { 120, 70, 170 }, { 255, 150, 90 } }, material = "SmoothPlastic", pattern = "gradient" },
	{ id = "comet", name = "Comet", rarity = "rare", series = "starlight", colours = { { 255, 255, 255 }, { 80, 150, 255 } }, material = "Neon", pattern = "split", sparkle = true },
	{ id = "nebula", name = "Nebula", rarity = "rare", series = "starlight", colours = { { 130, 60, 200 }, { 240, 110, 200 }, { 90, 170, 255 } }, material = "Neon", pattern = "tri" },
	{ id = "supernova", name = "Supernova", rarity = "epic", series = "starlight", colours = { { 255, 255, 240 }, { 255, 130, 40 } }, material = "Neon", pattern = "sheen", sparkle = true },
	{ id = "constellation", name = "Constellation", rarity = "epic", series = "starlight", colours = { { 30, 36, 80 }, { 240, 240, 255 } }, material = "SmoothPlastic", pattern = "bands", sparkle = true },
	{ id = "eclipse", name = "Eclipse", rarity = "legendary", series = "starlight", colours = { { 20, 20, 26 }, { 255, 200, 70 } }, material = "Metal", pattern = "split", glow = true },
	{ id = "borealis", name = "Borealis", rarity = "legendary", series = "starlight", colours = { { 80, 255, 160 }, { 70, 200, 255 }, { 180, 100, 255 } }, material = "Neon", pattern = "tri", sparkle = true },
	{ id = "celestial", name = "Celestial", rarity = "mythic", series = "starlight", colours = { { 255, 255, 255 }, { 255, 210, 90 }, { 120, 170, 255 } }, material = "Glass", pattern = "tri", glow = true, sparkle = true },
	{ id = "wishingstar", name = "Wishing Star", rarity = "mythic", series = "starlight", colours = { { 255, 255, 255 }, { 255, 255, 255 } }, material = "Neon", pattern = "rainbow", glow = true, sparkle = true },
	-- the 1 of 1 (Config.OneOfOne): only one can ever exist, only from a chest, only as a Sewing Needle.
	-- thin = paper thin; see = how see-through it is (0 solid, 1 invisible)
	{ id = "gossamer", name = "Gossamer", rarity = "unique", only = "sewing", colours = { { 235, 245, 255 }, { 200, 225, 255 } }, material = "Glass", pattern = "sheen", thin = 0.18, see = 0.82, sparkle = true },
	-- designed in the Needle Skin Workshop
	{ id = "thistle", name = "Thistle", rarity = "uncommon", colours = { { 150, 255, 255 }, { 181, 26, 0 } }, material = "SmoothPlastic", pattern = "gradient", glow = true, sparkle = true },
	{ id = "cornucopiacopy", name = "Cornucopia Copy", rarity = "mythic", series = "harvest", colours = { { 255, 120, 40 }, { 220, 40, 60 } }, material = "Neon", pattern = "gradient", glow = true, sparkle = true },
	{ id = "celestialcopy", name = "Celestial Copy", rarity = "mythic", series = "starlight", colours = { { 255, 255, 255 }, { 165, 255, 139 } }, material = "Fabric", pattern = "gradient", glow = true, sparkle = true },
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
local byGrade = {}
for _, g in ipairs(Needles.grades) do
	byGrade[g.id] = g
end

function Needles.grade(id)
	return byGrade[id]
end

-- Each grade's chance (percent) of a needle's shape, from the type weights (shown with box odds).
function Needles.gradeOdds()
	local total, by = 0, {}
	for _, t in ipairs(Needles.types) do
		total += t.weight
		by[t.grade] = (by[t.grade] or 0) + t.weight
	end
	local out = {}
	for _, g in ipairs(Needles.grades) do
		table.insert(out, { grade = g, percent = (by[g.id] or 0) / total * 100 })
	end
	return out
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

-- The skins a type comes in (a skin with `only` exists on that one type alone).
function Needles.skinsFor(typeId)
	local out = {}
	for _, s in ipairs(Needles.skins) do
		if not s.only or s.only == typeId then
			table.insert(out, s)
		end
	end
	return out
end

-- How many different needles there are to collect.
function Needles.count()
	local n = 0
	for _, t in ipairs(Needles.types) do
		n += #Needles.skinsFor(t.id)
	end
	return n
end

-- "darning:ember" for a type and a skin (how a collection saves them), and back.
function Needles.key(typeId, skinId)
	return typeId .. ":" .. skinId
end

function Needles.split(key)
	local t, s = string.match(key or "", "^(%w+):(%w+)$")
	if byType[t] and bySkin[s] and (not bySkin[s].only or bySkin[s].only == t) then
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

function Needles.pick(list, weightOf, rng)
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
	local t = Needles.pick(Needles.types, function(row)
		return row.weight
	end, rng)
	if golden then
		return t.id, "golden"
	end
	local rarity = Needles.pick(Needles.rarities, function(row)
		return if row.id == "common" then row.weight else row.weight * luck
	end, rng)
	local skins = {}
	for _, s in ipairs(Needles.skins) do
		if s.rarity == rarity.id and not s.series and not s.only then -- a box's own skins never come from a find
			table.insert(skins, s)
		end
	end
	return t.id, skins[rng:NextInteger(1, #skins)].id
end

return Needles

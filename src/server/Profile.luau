-- A player's data model: what is saved, with its defaults. Anything missing or of the
-- wrong type in a saved record falls back to the default, so old saves keep working.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))(Config)
local Layout = require(Shared:WaitForChild("Layout"))(Config)

local Profile = {}
local rng = Random.new()

Profile.STATS = { "searches", "loads_filled", "straws_sold", "lucky_finds", "perks_maxed", "total_searched", "best_height" }

local function number(saved, name, default)
	local v = type(saved) == "table" and saved[name]
	return if type(v) == "number" then v else default
end

-- The needle hides deep inside the upper heap (Config.NeedleHeight, Config.NeedleCore).
function Profile.newNeedle()
	local spots = Layout.needleSpots
	return if #spots > 0 then spots[rng:NextInteger(1, #spots)] else rng:NextInteger(1, Config.Clumps)
end

function Profile.fresh(saved)
	saved = if type(saved) == "table" then saved else {}
	local d = {
		coins = number(saved, "coins", 0),
		tool = math.clamp(math.floor(number(saved, "tool", 1)), 1, #Config.Tools),
		silo = math.clamp(math.floor(number(saved, "silo", 1)), 1, #Config.Silos),
		bucket = math.clamp(math.floor(number(saved, "bucket", 1)), 1, #Config.Buckets),
		carried = number(saved, "carried", 0),
		carriedGolden = number(saved, "carriedGolden", 0),
		siloStraw = number(saved, "siloStraw", 0),
		needleClump = math.floor(number(saved, "needleClump", 0)),
		revealed = saved.revealed == true,
		needles = number(saved, "needles", 0),
		whistles = number(saved, "whistles", 0),
		lastSeen = number(saved, "lastSeen", 0),
		skin = if type(saved.skin) == "string" then saved.skin else "",
		removed = if type(saved.removed) == "string" and #saved.removed == Config.Clumps then saved.removed else string.rep("0", Config.Clumps),
		partial = {},
		perks = {},
		inventory = {},
		placed = {},
		skins = {},
		stats = {},
		achievements = {},
		boosts = {},
		receipts = {},
		loft = { searched = number(saved.loft, "searched", 0), needleAt = number(saved.loft, "needleAt", 0), needles = number(saved.loft, "needles", 0) },
	}
	if d.needleClump < 1 or d.needleClump > Config.Clumps then
		d.needleClump = Profile.newNeedle()
	end
	if string.sub(d.removed, d.needleClump, d.needleClump) == "1" then
		-- the needle's clump is gone but no new pile was started (an old save): start one now
		d.removed = string.rep("0", Config.Clumps)
		d.needleClump = Profile.newNeedle()
		d.revealed = false
	end
	if type(saved.partial) == "table" then
		for index, left in pairs(saved.partial) do
			if tonumber(index) and type(left) == "number" then
				d.partial[tostring(index)] = left
			end
		end
	end
	if string.find(d.removed, "1", 1, true) == nil then
		d.partial = {} -- a fresh pile has no half-harvested clumps
	end
	for _, perk in ipairs(Config.Perks) do
		d.perks[perk.id] = math.clamp(math.floor(number(saved.perks, perk.id, 0)), 0, perk.levels)
	end
	if type(saved.inventory) == "table" then
		for id, n in pairs(saved.inventory) do
			if Economy.item(id) and type(n) == "number" and n > 0 then
				d.inventory[id] = math.floor(n)
			end
		end
	end
	if type(saved.placed) == "table" then
		for _, p in ipairs(saved.placed) do
			if type(p) == "table" and Economy.item(p.k) and type(p.x) == "number" and type(p.y) == "number" and type(p.z) == "number" and #d.placed < Config.MaxPlaced then
				table.insert(d.placed, { k = p.k, x = p.x, y = p.y, z = p.z, r = if type(p.r) == "number" then p.r else 0 })
			end
		end
	end
	for _, prize in ipairs(Config.Wheel) do
		if not prize.reveal and type(saved.skins) == "table" and saved.skins[prize.id] == true then
			d.skins[prize.id] = true
		end
	end
	for _, name in ipairs(Profile.STATS) do
		d.stats[name] = number(saved.stats, name, 0)
	end
	for _, a in ipairs(Config.Achievements) do
		d.achievements[a.id] = type(saved.achievements) == "table" and saved.achievements[a.id] == true
	end
	for name in pairs(Config.Products) do
		d.boosts[name] = number(saved.boosts, name, 0)
	end
	if type(saved.receipts) == "table" then
		for _, id in ipairs(saved.receipts) do
			if type(id) == "string" then
				table.insert(d.receipts, id)
			end
		end
	end
	if d.loft.needleAt <= 0 then
		d.loft.needleAt = Economy.needleAt(Config.Loft.straws, Config.Loft.needleEarliest, rng)
	end
	return d
end

-- How many straws are left in clump `index` (0 if harvested).
function Profile.clumpLeft(d, index)
	if string.sub(d.removed, index, index) == "1" then
		return 0
	end
	return d.partial[tostring(index)] or Economy.STRAWS_PER_CLUMP
end

function Profile.setClumpLeft(d, index, left)
	if left <= 0 then
		d.partial[tostring(index)] = nil
		d.removed = string.sub(d.removed, 1, index - 1) .. "1" .. string.sub(d.removed, index + 1)
	else
		d.partial[tostring(index)] = left
	end
end

function Profile.clumpsLeft(d)
	local _, harvested = string.gsub(d.removed, "1", "")
	return Config.Clumps - harvested
end

return Profile

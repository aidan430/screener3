-- A player's data model: what is saved, with its defaults. Anything missing or of the
-- wrong type in a saved record falls back to the default, so old saves keep working.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))(Config)

local Profile = {}
local rng = Random.new()

Profile.STATS = { "searches", "bags_filled", "straws_sold", "lucky_finds", "perks_maxed", "total_searched" }

local function number(saved, name, default)
	local v = type(saved) == "table" and saved[name]
	return if type(v) == "number" then v else default
end

function Profile.fresh(saved)
	saved = if type(saved) == "table" then saved else {}
	local d = {
		coins = number(saved, "coins", 0),
		tool = math.clamp(math.floor(number(saved, "tool", 1)), 1, #Config.Tools),
		bag = math.clamp(math.floor(number(saved, "bag", 1)), 1, #Config.Bags),
		bagStraw = number(saved, "bagStraw", 0),
		bagGolden = number(saved, "bagGolden", 0),
		searched = number(saved, "searched", 0),
		needleAt = number(saved, "needleAt", 0),
		needles = number(saved, "needles", 0),
		whistles = number(saved, "whistles", 0),
		lastSeen = number(saved, "lastSeen", 0),
		perks = {},
		machines = {},
		stats = {},
		achievements = {},
		boosts = {},
		receipts = {},
		loft = { searched = number(saved.loft, "searched", 0), needleAt = number(saved.loft, "needleAt", 0), needles = number(saved.loft, "needles", 0) },
	}
	for _, perk in ipairs(Config.Perks) do
		d.perks[perk.id] = math.clamp(math.floor(number(saved.perks, perk.id, 0)), 0, perk.levels)
	end
	for i, m in ipairs(Config.Machines) do
		d.machines[i] = math.clamp(math.floor(number(saved.machines, i, 0)), 0, m.max)
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
	if d.needleAt <= 0 then
		d.needleAt = Economy.needleAt(Config.TotalStraws, Config.NeedleEarliest, rng)
	end
	if d.loft.needleAt <= 0 then
		d.loft.needleAt = Economy.needleAt(Config.Loft.straws, Config.Loft.needleEarliest, rng)
	end
	return d
end

return Profile

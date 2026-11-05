-- Every number you might want to tune lives here. Change it, rebuild, play-test.
-- This module requires nothing, so the server, the client and the checks can all read it.
local Config = {}

Config.Title = "Needle in the Haystack"
Config.FarmName = "Hollow Creek Farm"

-- The haystack. Everyone sees the same giant haystack, but each player's progress is their
-- own and is saved: you dig through your 5,000,000 straws, and your needle is in there.
Config.TotalStraws = 5000000
Config.NeedleEarliest = 0.6 -- the needle is never in the first 60% of the straws
Config.SearchRange = 34 -- studs from the haystack's centre (flat distance) to search it
Config.SearchCooldown = 0.3 -- seconds between searches (the Swift perk shortens it)
Config.MerchantRange = 16 -- studs from the merchant's stall to sell

-- Coins: the merchant pays this per straw. Everything coins buy is below.
Config.CoinsPerStraw = 1

-- Tools, in the order players buy them. power = straws per search. Colours are {r, g, b}.
Config.Tools = {
	{ name = "Rusty Fork", power = 1, price = 0, shaft = { 112, 82, 58 }, head = { 128, 98, 78 }, material = "CorrodedMetal" },
	{ name = "Wooden Pitchfork", power = 2, price = 400, shaft = { 160, 116, 72 }, head = { 176, 128, 82 }, material = "Wood" },
	{ name = "Iron Pitchfork", power = 3, price = 2400, shaft = { 150, 108, 66 }, head = { 165, 170, 178 }, material = "Metal" },
	{ name = "Steel Rake", power = 5, price = 10000, shaft = { 120, 84, 50 }, head = { 190, 196, 204 }, material = "Metal" },
	{ name = "Golden Rake", power = 7, price = 40000, shaft = { 120, 84, 50 }, head = { 245, 200, 66 }, material = "Metal" },
	{ name = "Hay Blower", power = 9, price = 120000, shaft = { 70, 72, 84 }, head = { 232, 92, 60 }, material = "SmoothPlastic" },
	{ name = "Super Sifter", power = 12, price = 320000, shaft = { 60, 64, 78 }, head = { 90, 200, 255 }, material = "Neon" },
	{ name = "Magnet Gloves", power = 15, price = 800000, shaft = { 200, 200, 210 }, head = { 220, 40, 40 }, material = "SmoothPlastic" },
	{ name = "Twin Turbines", power = 19, price = 1700000, shaft = { 40, 44, 52 }, head = { 255, 170, 40 }, material = "Metal" },
	{ name = "Needle Detector", power = 22, price = 3400000, shaft = { 40, 44, 52 }, head = { 70, 255, 150 }, material = "Neon" },
}
Config.DetectorLevel = 10 -- from this tool on, the HUD shows how warm the needle is

-- Bags: how much straw you can carry before selling to the merchant.
Config.Bags = {
	{ name = "Hay Pouch", size = 400, price = 0 },
	{ name = "Sack", size = 1500, price = 900 },
	{ name = "Big Sack", size = 5000, price = 6000 },
	{ name = "Cart", size = 16000, price = 40000 },
	{ name = "Wagon", size = 50000, price = 250000 },
	{ name = "Hay Lorry", size = 160000, price = 1500000 },
}

-- Machines search by themselves while you play (and need no clicking). rate = straws a
-- second each; you can own `max` of each; each one you buy costs `growth` times more.
Config.Machines = {
	{ name = "Clockwork Hen", rate = 0.15, price = 1600, growth = 1.3, max = 10, color = { 236, 180, 70 } },
	{ name = "Sorting Sieve", rate = 0.6, price = 20000, growth = 1.3, max = 10, color = { 150, 150, 160 } },
	{ name = "Steam Thresher", rate = 1.5, price = 160000, growth = 1.35, max = 8, color = { 90, 70, 60 } },
	{ name = "Hay Vacuum", rate = 3.6, price = 900000, growth = 1.4, max = 6, color = { 200, 80, 60 } },
	{ name = "Needle Magnetron", rate = 7.5, price = 4000000, growth = 1.5, max = 4, color = { 70, 255, 150 } },
}

-- Perks are bought per tool (they reset when you buy a new tool). price is for the Wooden
-- Pitchfork; it scales with the tool's price. Each level costs `growth` times more.
Config.Perks = {
	{ id = "sharp", name = "Sharpened", per_level = 0.15, levels = 5, price = 120, growth = 1.6, text = "+15% straws a search per level" },
	{ id = "swift", name = "Swift", per_level = 0.10, levels = 5, price = 120, growth = 1.6, text = "-10% search cooldown per level" },
	{ id = "lucky", name = "Lucky", per_level = 0.004, levels = 5, price = 150, growth = 1.6, text = "+0.4% chance of a lucky find per level" },
}

-- Lucky finds: odd things in the hay that the merchant pays extra for (and bits of the story).
Config.LuckyChance = 0.006 -- per search, before the Lucky perk
Config.LuckyValueSearches = 60 -- a find is worth this many searches' worth of coins

-- Saving
Config.DataStoreName = "NeedleHaystack_v2"
Config.AutosaveSeconds = 120

-- Robux. Power-ups (timed boosts) are Robux only. Nothing shows in the shop until you create
-- the item on the Creator Dashboard (after publishing) and paste its ID here. 0 = switched off.
Config.GamePasses = {
	AutoSell = 0, -- your bag sells itself to the merchant when it fills up
	VIP = 0, -- +25% coins, a golden name tag, and machines keep running for an hour after you leave
	DoubleMachines = 0, -- every machine works twice as fast
}
Config.Products = {
	SpeedBoost = 0, -- 2x straws a search for 1 hour
	CoinBoost = 0, -- 2x coins from the merchant for 1 hour
	MerchantWhistle = 0, -- sell your bag anywhere, 10 times
	StrawBlast = 0, -- search 100,000 straws at once
	LuckyCharm = 0, -- 5x lucky finds for 1 hour
}
Config.BoostSeconds = 3600
Config.WhistleUses = 10
Config.StrawBlastAmount = 100000
Config.VipCoinBonus = 0.25
Config.VipOfflineSeconds = 3600

-- Achievements: all ten open the Golden Loft, a secret level above the barn.
Config.Achievements = {
	{ id = "first_straw", name = "First Straw", text = "Search the haystack for the first time.", stat = "searches", goal = 1 },
	{ id = "bag_full", name = "Bag Full", text = "Fill your bag to the brim.", stat = "bags_filled", goal = 1 },
	{ id = "merchant", name = "Merchant's Friend", text = "Sell 100,000 straws to the merchant.", stat = "straws_sold", goal = 100000 },
	{ id = "collector", name = "Collector", text = "Own every tool, up to the Needle Detector.", stat = "tool", goal = 10 },
	{ id = "industrialist", name = "Industrialist", text = "Own 10 machines at once.", stat = "machines", goal = 10 },
	{ id = "perfectionist", name = "Perfectionist", text = "Max out all three perks on one tool.", stat = "perks_maxed", goal = 1 },
	{ id = "marathon", name = "Marathon", text = "Search for two hours in one visit.", stat = "session_seconds", goal = 7200 },
	{ id = "halfway", name = "Halfway There", text = "Search 2,500,000 straws.", stat = "searched", goal = 2500000 },
	{ id = "lucky", name = "Lucky Duck", text = "Make 25 lucky finds in the hay.", stat = "lucky_finds", goal = 25 },
	{ id = "needle", name = "Needle Finder", text = "Find the needle.", stat = "needles", goal = 1 },
}
Config.BadgeIds = {} -- optional: { first_straw = 123456 } awards a Roblox badge too

-- The Golden Loft: a smaller golden haystack where straw pays 20x and a golden needle waits.
Config.Loft = { straws = 250000, coinMultiplier = 20, needleEarliest = 0.5 }

return Config

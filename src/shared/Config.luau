-- Every number you might want to tune lives here. Change it, rebuild, play-test.
-- This module requires nothing, so the server, the client and the checks can all read it.
local Config = {}

Config.Title = "Needle in the Haystack"
Config.FarmName = "Hollow Creek Farm"

-- The haystacks
Config.TotalStraws = 5000000 -- shared equally between the haystacks in Piles.json
Config.MinPileScale = 0.3 -- an emptied haystack shrinks to this size
Config.SearchRange = 26 -- studs from a haystack's centre (flat distance) to search it
Config.SearchCooldown = 0.18 -- seconds between searches, so auto-clickers gain nothing

-- Cases (rounds)
Config.ClueChance = 0.03 -- chance that a search turns up your next clue
Config.SolvedPause = 12 -- seconds between solving a case and the next case
Config.FinderRewardSearches = 400 -- the finder earns this many searches' worth of coins
Config.HelperRewardSearches = 40 -- everyone else who searched this case earns this many

-- Coins and rebirth
Config.CoinsPerStraw = 0.1
Config.RebirthBaseCost = 2500000 -- the first rebirth; each one after costs this much more
Config.RebirthCoinBonus = 0.5 -- +50% coins for every rebirth

-- Search tools, in the order players buy them. Colours are {red, green, blue}.
Config.Tools = {
	{ name = "Rusty Fork", power = 100, price = 0, shaft = { 112, 82, 58 }, head = { 128, 98, 78 }, material = "CorrodedMetal" },
	{ name = "Wooden Pitchfork", power = 250, price = 250, shaft = { 160, 116, 72 }, head = { 176, 128, 82 }, material = "Wood" },
	{ name = "Iron Pitchfork", power = 600, price = 1500, shaft = { 150, 108, 66 }, head = { 165, 170, 178 }, material = "Metal" },
	{ name = "Golden Rake", power = 1500, price = 8000, shaft = { 120, 84, 50 }, head = { 245, 200, 66 }, material = "Metal" },
	{ name = "Hay Blower", power = 4000, price = 40000, shaft = { 70, 72, 84 }, head = { 232, 92, 60 }, material = "SmoothPlastic" },
	{ name = "Super Sifter", power = 10000, price = 200000, shaft = { 60, 64, 78 }, head = { 90, 200, 255 }, material = "Neon" },
	{ name = "Magnet Gloves", power = 25000, price = 1000000, shaft = { 200, 200, 210 }, head = { 220, 40, 40 }, material = "SmoothPlastic" },
	{ name = "Needle Detector", power = 60000, price = 5000000, shaft = { 40, 44, 52 }, head = { 70, 255, 150 }, material = "Neon" },
}
Config.DetectorLevel = 8 -- this tool also beeps when you search the haystack hiding the needle

-- Saving
Config.DataStoreName = "NeedleHaystack_v1"
Config.AutosaveSeconds = 120

-- Robux items. Nothing shows in the shop until you create the item on the Creator
-- Dashboard (after publishing) and paste its ID here. 0 = switched off.
Config.GamePasses = {
	DoubleCoins = 0, -- every search earns twice the coins
	AutoSearch = 0, -- searches by itself while you hold your tool next to a haystack
}
Config.Products = {
	ClueHint = 0, -- reveals your next clue straight away
}
Config.AutoSearchInterval = 0.6

return Config

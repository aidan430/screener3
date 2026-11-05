-- The guided goals (Config.luau merges this file in: read and tune them as Config.Goals etc.).
local Config = {}

-- Goals: a guided list, in order, each paying `reward` coins. kind: stat (d.stats[key]), tool / bucket / silo
-- (level n), clumps (harvested), placed (key on your plot), truck (key owned), machines / power (on your plot).
-- Saved by position (d.goal): add new goals at the end, or players skip or repeat one. Two a line (300-line limit).
Config.Goals = {
	{ id = "first_hay", text = "Aim at your haystack and click to lift some hay", kind = "stat", key = "searches", n = 1, reward = 25 }, { id = "fill_tool", text = "Keep harvesting until your tool is full", kind = "stat", key = "loads_filled", n = 1, reward = 50 },
	{ id = "dump", text = "Dump your hay in your trader's basket", kind = "stat", key = "dumps", n = 1, reward = 75 }, { id = "first_sale", text = "Let your trader sell 500 straws", kind = "stat", key = "straws_sold", n = 500, reward = 100 },
	{ id = "pitchfork", text = "Buy the Wooden Pitchfork in the shop (Q)", kind = "tool", n = 2, reward = 150 }, { id = "ladder", text = "Buy a Ladder and build it (B) by your heap", kind = "placed", key = "ladder", n = 1, reward = 100 },
	{ id = "clumps10", text = "Harvest 10 whole clumps", kind = "clumps", n = 10, reward = 200 }, { id = "bucket", text = "Buy a Tin Pail to carry more", kind = "bucket", n = 2, reward = 300 },
	{ id = "stairs", text = "Build some Stairs up your heap", kind = "placed", key = "stairs", n = 1, reward = 150 }, { id = "drop", text = "Press G to drop your hay as a bundle", kind = "stat", key = "drops", n = 1, reward = 150 },
	{ id = "belt", text = "Place a Conveyor Belt to carry bundles", kind = "placed", key = "conveyor", n = 1, reward = 300 }, { id = "dynamo", text = "Place a Hand-Crank Dynamo for power", kind = "placed", key = "crank", n = 1, reward = 400 },
	{ id = "hen", text = "Place a Clockwork Hen to harvest for you", kind = "placed", key = "hen", n = 1, reward = 500 }, { id = "iron", text = "Buy the Iron Pitchfork", kind = "tool", n = 3, reward = 600 },
	{ id = "clumps25", text = "Harvest 25 whole clumps", kind = "clumps", n = 25, reward = 800 }, { id = "van", text = "Buy a Farm Van to sell hay faster", kind = "truck", key = "van", n = 1, reward = 1500 },
	{ id = "sold10k", text = "Sell 10,000 straws", kind = "stat", key = "straws_sold", n = 10000, reward = 1500 }, { id = "power20", text = "Make 20 power with your generators", kind = "power", n = 20, reward = 2000 },
	{ id = "clumps50", text = "Harvest 50 whole clumps", kind = "clumps", n = 50, reward = 2500 }, { id = "machines3", text = "Have 3 machines on your plot", kind = "machines", n = 3, reward = 3000 },
	{ id = "rake", text = "Buy the Steel Rake", kind = "tool", n = 4, reward = 4000 }, { id = "silo", text = "Upgrade to a Small Silo", kind = "silo", n = 2, reward = 4000 },
	{ id = "baler", text = "Build a Bale Maker", kind = "placed", key = "baler", n = 1, reward = 10000 }, { id = "bale", text = "Feed it hay on a belt and make a bale", kind = "stat", key = "bales_made", n = 1, reward = 8000 },
	{ id = "clumps100", text = "Harvest 100 whole clumps", kind = "clumps", n = 100, reward = 15000 },
}
Config.GoalCheckSeconds = 2 -- how often the server looks at your current goal
Config.RateWindowSeconds = 60 -- the HUD's coins/min counts what you earned in this many seconds

return Config

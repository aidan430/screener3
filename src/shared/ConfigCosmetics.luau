-- Milestone cosmetics and the open achievements that unlock them (Config.luau merges this file in;
-- its Achievements are added after the secret ones in ConfigGoals). Everyone on the server sees
-- what you wear: a title above your head, a hat, a trail behind you and an aura round you.
local Config = {}

-- kind: title | hat | trail | aura. colours: one or two {r, g, b} (two make a gradient; title
-- "rainbow" cycles). hat shape: strawhat | bandana | crown | halo. rarity: what the journal says.
Config.Cosmetics = {
	{ id = "t_hayhand", kind = "title", name = "Hay Hand", rarity = "Common", colours = { { 214, 170, 80 } } },
	{ id = "h_strawhat", kind = "hat", name = "Straw Hat", rarity = "Common", shape = "strawhat", colours = { { 226, 188, 96 }, { 160, 60, 50 } } },
	{ id = "tr_golden", kind = "trail", name = "Golden Trail", rarity = "Uncommon", colours = { { 255, 214, 110 }, { 255, 240, 200 } } },
	{ id = "t_early", kind = "title", name = "Early Bird", rarity = "Uncommon", colours = { { 120, 180, 230 } } },
	{ id = "t_crusher", kind = "title", name = "Clump Crusher", rarity = "Uncommon", colours = { { 176, 84, 60 } } },
	{ id = "h_bandana", kind = "hat", name = "Farmer's Bandana", rarity = "Rare", shape = "bandana", colours = { { 190, 50, 50 }, { 245, 240, 230 } } },
	{ id = "t_fieldworker", kind = "title", name = "Field Worker", rarity = "Rare", colours = { { 96, 160, 74 } } },
	{ id = "t_fashion", kind = "title", name = "Fashion Farmer", rarity = "Rare", colours = { { 230, 120, 190 }, { 140, 90, 255 } } },
	{ id = "t_traveller", kind = "title", name = "World Traveller", rarity = "Rare", colours = { { 90, 200, 230 }, { 255, 120, 50 } } },
	{ id = "tr_worlds", kind = "trail", name = "Portal Trail", rarity = "Rare", colours = { { 90, 200, 230 }, { 255, 140, 60 } } },
	{ id = "t_storyteller", kind = "title", name = "Storyteller", rarity = "Rare", colours = { { 122, 110, 170 } } },
	{ id = "t_hero", kind = "title", name = "Haystack Hero", rarity = "Epic", colours = { { 255, 200, 70 }, { 255, 140, 40 } } },
	{ id = "a_harvestmoon", kind = "aura", name = "Harvest Moon Aura", rarity = "Epic", colours = { { 255, 214, 140 }, { 255, 160, 80 } } },
	{ id = "a_sunbeam", kind = "aura", name = "Sunbeam Aura", rarity = "Epic", colours = { { 255, 245, 190 }, { 255, 220, 90 } } },
	-- the 24-hour reward
	{ id = "t_legend", kind = "title", name = "Legend of Hollow Creek", rarity = "Legendary", colours = { { 255, 214, 90 }, { 255, 160, 60 } } },
	{ id = "h_goldcrown", kind = "hat", name = "Golden Straw Crown", rarity = "Legendary", shape = "crown", colours = { { 255, 210, 80 }, { 255, 245, 200 } } },
	{ id = "a_legend", kind = "aura", name = "Legend's Glow", rarity = "Legendary", colours = { { 255, 220, 120 }, { 255, 255, 230 } } },
	-- the 100-hour reward
	{ id = "t_keeper", kind = "title", name = "Keeper of the Stack", rarity = "Mythic", colours = { "rainbow" } },
	{ id = "h_halo", kind = "hat", name = "Starlight Halo", rarity = "Mythic", shape = "halo", colours = { { 200, 230, 255 }, { 255, 255, 255 } } },
}

-- The milestone achievements: shown with their progress (open = true), each unlocks cosmetics
-- (`cosmetics`), and may pay coins, banked free wheel spins (`spins`) or every power-up
-- (`powerups`: each timed boost for Config.LegendBoostHours, a Straw Blast and a pack of whistles).
-- stat: hours (played, in total), streak (days in a row), days, clumps (cleared, all heaps),
-- needles, skins, worlds, story (scenes seen), orders, spins, lucky_finds, straws_sold.
Config.Achievements = {
	{ id = "play1", open = true, name = "Settling In", text = "Play for 1 hour in total.", stat = "hours", goal = 1, cosmetics = { "t_hayhand" }, coins = 1000 },
	{ id = "play3", open = true, name = "Sun on Your Back", text = "Play for 3 hours in total.", stat = "hours", goal = 3, cosmetics = { "h_strawhat" }, coins = 5000 },
	{ id = "play6", open = true, name = "Golden Hours", text = "Play for 6 hours in total.", stat = "hours", goal = 6, cosmetics = { "tr_golden" }, spins = 1 },
	{ id = "play12", open = true, name = "Field Worker", text = "Play for 12 hours in total.", stat = "hours", goal = 12, cosmetics = { "t_fieldworker" }, spins = 2 },
	{ id = "play24", open = true, name = "Legend of Hollow Creek", text = "Play for 24 hours in total. Unlocks every power-up, 5 wheel spins and the Golden Straw Crown.", stat = "hours", goal = 24, cosmetics = { "t_legend", "h_goldcrown", "a_legend" }, spins = 5, powerups = true },
	{ id = "play48", open = true, name = "Sunbeam", text = "Play for 48 hours in total.", stat = "hours", goal = 48, cosmetics = { "a_sunbeam" }, spins = 3 },
	{ id = "play100", open = true, name = "Keeper of the Stack", text = "Play for 100 hours in total.", stat = "hours", goal = 100, cosmetics = { "t_keeper", "h_halo" }, spins = 10, powerups = true },
	{ id = "streak3", open = true, name = "Early Bird", text = "Play on 3 days in a row.", stat = "streak", goal = 3, cosmetics = { "t_early" }, spins = 1 },
	{ id = "streak7", open = true, name = "A Week of Hay", text = "Play on 7 days in a row.", stat = "streak", goal = 7, cosmetics = { "h_bandana" }, spins = 2 },
	{ id = "streak30", open = true, name = "Harvest Moon", text = "Play on 30 days in a row.", stat = "streak", goal = 30, cosmetics = { "a_harvestmoon" }, spins = 5 },
	{ id = "days50", open = true, name = "Regular", text = "Play on 50 different days.", stat = "days", goal = 50, spins = 5 },
	{ id = "clumps100", open = true, name = "Clump Crusher", text = "Clear 100 clumps.", stat = "clumps", goal = 100, cosmetics = { "t_crusher" }, coins = 10000 },
	{ id = "clumps1000", open = true, name = "Half a Haystack", text = "Clear 1,000 clumps.", stat = "clumps", goal = 1000, coins = 100000 },
	{ id = "clumps10000", open = true, name = "Haystack Hero", text = "Clear 10,000 clumps.", stat = "clumps", goal = 10000, cosmetics = { "t_hero" }, spins = 5 },
	{ id = "needles3", open = true, name = "Sharp Eye", text = "Find 3 needles.", stat = "needles", goal = 3, spins = 3 },
	{ id = "needles10", open = true, name = "Needle Master", text = "Find 10 needles.", stat = "needles", goal = 10, spins = 10 },
	{ id = "skins6", open = true, name = "Fashion Farmer", text = "Collect all six tool skins.", stat = "skins", goal = 6, cosmetics = { "t_fashion" } },
	{ id = "worlds4", open = true, name = "World Traveller", text = "Open all four worlds.", stat = "worlds", goal = 4, cosmetics = { "t_traveller", "tr_worlds" } },
	{ id = "story", open = true, name = "Storyteller", text = "See 20 scenes of the story.", stat = "story", goal = 20, cosmetics = { "t_storyteller" }, coins = 50000 },
	{ id = "orders25", open = true, name = "Reliable Supplier", text = "Complete 25 delivery orders.", stat = "orders", goal = 25, spins = 2 },
	{ id = "spins25", open = true, name = "Round and Round", text = "Spin the wheel 25 times.", stat = "spins", goal = 25, coins = 25000 },
	{ id = "lucky100", open = true, name = "Four-Leaf Clover", text = "Make 100 lucky finds.", stat = "lucky_finds", goal = 100, spins = 2 },
	{ id = "sold1m", open = true, name = "Market Favourite", text = "Sell 1,000,000 straws.", stat = "straws_sold", goal = 1000000, coins = 250000 },
}
-- Testing switches. They only work in Roblox Studio (never in the published game), so leaving
-- one on by mistake can't give real players anything. fastHours: one "hour" of play time takes
-- this many seconds (10 = the 24-hour reward after 4 minutes); 0 = off. unlockAll: you own every
-- cosmetic as soon as you join, to try them on in the Wardrobe.
Config.Testing = { fastHours = 0, unlockAll = false }
Config.HatScale = 1.35 -- hats a little bigger than life, so they read from across the farm
Config.HaloSpin = 0.8 -- radians a second the Starlight Halo turns
Config.LegendBoostHours = 24 -- "every power-up": each timed boost (2x Speed, 2x Coins, Lucky Charm) lasts this long

return Config

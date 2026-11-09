-- Cosmetics: looks only, never an advantage. The hidden needle always looks the same for
-- everyone (fairness); your needle skin is the trophy needle you hold up when you find it, on
-- the NEEDLE FOUND! popup and the results screen. Add an item by adding a line.
--   kind: needle | trail | title | effect
--   price: Haystack Coins in the shop (0 = not sold for coins: a starting item, a quest reward
--     or from a Robux pass, named by `source`)
--   colours: { r, g, b } for each part (needle: shaft, eye; trail: start, end)
local Cosmetics = {}

Cosmetics.items = {
	-- needle skins: 1 free + 5 for coins
	{ id = "n_silver", kind = "needle", name = "Classic Silver", price = 0, source = "start", colours = { { 205, 210, 220 }, { 150, 156, 168 } }, material = "Metal" },
	{ id = "n_copper", kind = "needle", name = "Copper", price = 400, colours = { { 196, 116, 70 }, { 150, 84, 50 } }, material = "Metal" },
	{ id = "n_rose", kind = "needle", name = "Rose Gold", price = 900, colours = { { 236, 170, 160 }, { 200, 130, 120 } }, material = "Metal" },
	{ id = "n_frost", kind = "needle", name = "Frost", price = 1600, colours = { { 170, 225, 255 }, { 120, 190, 240 } }, material = "Glass", sparkle = true },
	{ id = "n_midnight", kind = "needle", name = "Midnight", price = 2500, colours = { { 70, 60, 120 }, { 140, 120, 230 } }, material = "Neon" },
	{ id = "n_rainbow", kind = "needle", name = "Rainbow", price = 4000, colours = { { 255, 120, 120 }, { 120, 160, 255 } }, material = "Neon", rainbow = true },
	-- trails
	{ id = "t_straw", kind = "trail", name = "Straw Trail", price = 700, colours = { { 240, 200, 90 }, { 255, 240, 190 } } },
	{ id = "t_sparkle", kind = "trail", name = "Sparkle Trail", price = 1800, colours = { { 255, 255, 255 }, { 170, 220, 255 } } },
	{ id = "t_supporter", kind = "trail", name = "Supporter Trail", price = 0, source = "Supporter pass", colours = { { 255, 200, 80 }, { 255, 120, 60 } } },
	-- titles above your head
	{ id = "ti_finder", kind = "title", name = "Needle Finder", price = 0, source = "quest", colours = { { 220, 225, 235 } } },
	{ id = "ti_eagle", kind = "title", name = "Eagle Eye", price = 0, source = "quest", colours = { { 255, 214, 90 } } },
	{ id = "ti_supporter", kind = "title", name = "Supporter", price = 0, source = "Supporter pass", colours = { { 255, 160, 70 } } },
	-- found effects: the burst when you find a needle
	{ id = "e_confetti", kind = "effect", name = "Confetti Pop", price = 0, source = "start", colours = { { 255, 206, 70 }, { 110, 170, 240 } } },
	{ id = "e_stars", kind = "effect", name = "Starburst", price = 1200, colours = { { 255, 250, 220 }, { 255, 214, 90 } } },
}

Cosmetics.kinds = { "needle", "trail", "title", "effect" }
Cosmetics.kindNames = { needle = "Needle Skins", trail = "Trails", title = "Titles", effect = "Found Effects" }
Cosmetics.starting = { "n_silver", "e_confetti" } -- everyone owns these
Cosmetics.defaults = { needle = "n_silver", effect = "e_confetti" } -- and wears these

local byId = {}
for _, item in ipairs(Cosmetics.items) do
	byId[item.id] = item
end

function Cosmetics.get(id)
	return byId[id]
end

return Cosmetics

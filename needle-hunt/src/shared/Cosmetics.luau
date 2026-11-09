-- Cosmetics for Haystack Coins: looks only, never an advantage. Needles are not sold here: every
-- needle you find is yours to keep (shared/Needles, the collection). Add an item by adding a line.
--   kind: trail | title | effect
--   price: Haystack Coins in the shop (0 = not sold for coins: a starting item, a quest reward
--     or from a Robux pass, named by `source`)
--   colours: { r, g, b } (trail: start, end)
local Cosmetics = {}

Cosmetics.items = {
	-- trails
	{ id = "t_straw", kind = "trail", name = "Straw Trail", price = 700, colours = { { 240, 200, 90 }, { 255, 240, 190 } } },
	{ id = "t_sparkle", kind = "trail", name = "Sparkle Trail", price = 1800, colours = { { 255, 255, 255 }, { 170, 220, 255 } } },
	{ id = "t_meadow", kind = "trail", name = "Meadow Trail", price = 900, colours = { { 120, 200, 90 }, { 230, 250, 180 } } },
	{ id = "t_sunset", kind = "trail", name = "Sunset Trail", price = 1400, colours = { { 255, 140, 70 }, { 255, 90, 140 } } },
	{ id = "t_ocean", kind = "trail", name = "Ocean Trail", price = 2200, colours = { { 60, 150, 230 }, { 150, 240, 230 } } },
	{ id = "t_rainbow", kind = "trail", name = "Rainbow Thread", price = 4000, colours = { { 255, 90, 110 }, { 110, 140, 255 } } },
	{ id = "t_golden", kind = "trail", name = "Golden Thread", price = 6000, colours = { { 255, 214, 90 }, { 255, 250, 220 } } },
	{ id = "t_supporter", kind = "trail", name = "Supporter Trail", price = 0, source = "Supporter pass", colours = { { 255, 200, 80 }, { 255, 120, 60 } } },
	-- titles above your head
	{ id = "ti_finder", kind = "title", name = "Needle Finder", price = 0, source = "quest", colours = { { 220, 225, 235 } } },
	{ id = "ti_eagle", kind = "title", name = "Eagle Eye", price = 0, source = "quest", colours = { { 255, 214, 90 } } },
	{ id = "ti_hero", kind = "title", name = "Haystack Hero", price = 1000, colours = { { 255, 200, 90 } } },
	{ id = "ti_sharp", kind = "title", name = "Sharp Eyes", price = 1500, colours = { { 140, 220, 255 } } },
	{ id = "ti_collector", kind = "title", name = "Needle Collector", price = 2500, colours = { { 200, 150, 255 } } },
	{ id = "ti_legend", kind = "title", name = "Straw Legend", price = 5000, colours = { { 255, 170, 60 } } },
	{ id = "ti_supporter", kind = "title", name = "Supporter", price = 0, source = "Supporter pass", colours = { { 255, 160, 70 } } },
	-- found effects: the burst when you find a needle
	{ id = "e_confetti", kind = "effect", name = "Confetti Pop", price = 0, source = "start", colours = { { 255, 206, 70 }, { 110, 170, 240 } } },
	{ id = "e_stars", kind = "effect", name = "Starburst", price = 1200, colours = { { 255, 250, 220 }, { 255, 214, 90 } } },
	{ id = "e_hay", kind = "effect", name = "Hay Burst", price = 800, colours = { { 240, 200, 90 }, { 200, 150, 70 } } },
	{ id = "e_petals", kind = "effect", name = "Petal Shower", price = 2000, colours = { { 255, 150, 190 }, { 255, 240, 245 } } },
	{ id = "e_fireflies", kind = "effect", name = "Fireflies", price = 3000, colours = { { 220, 255, 120 }, { 255, 230, 120 } } },
}

Cosmetics.kinds = { "trail", "title", "effect" }
Cosmetics.kindNames = { trail = "Trails", title = "Titles", effect = "Found Effects" }
Cosmetics.starting = { "e_confetti" } -- everyone owns these
Cosmetics.defaults = { effect = "e_confetti" } -- and wears these

local byId = {}
for _, item in ipairs(Cosmetics.items) do
	byId[item.id] = item
end

function Cosmetics.get(id)
	return byId[id]
end

return Cosmetics

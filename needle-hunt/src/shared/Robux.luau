-- What the shop's Robux section says about each item (server/ShopManager does the giving; the
-- amounts come from Config). Each says exactly what it gives. key = its name in Config.GamePasses
-- or Config.Products; an item with ID 0 there isn't on sale and isn't shown.
local Config = require(script.Parent.Config)

local Robux = {}

Robux.items = {
	{ key = "StarterBundle", pass = false, once = true, name = "Starter Bundle", text = Config.StarterBundle.coins .. " coins and the Sparkle Trail. Once per player." },
	{ key = "CoinsSmall", pass = false, name = "Pouch of Coins", text = Config.CoinPacks.CoinsSmall .. " Haystack Coins for trails, titles and effects." },
	{ key = "CoinsMedium", pass = false, name = "Sack of Coins", text = Config.CoinPacks.CoinsMedium .. " Haystack Coins for trails, titles and effects." },
	{ key = "CoinsLarge", pass = false, name = "Cart of Coins", text = Config.CoinPacks.CoinsLarge .. " Haystack Coins for trails, titles and effects." },
	{ key = "CoinShower", pass = false, name = "Coin Shower", text = "Everyone in this server, you too, gets " .. Config.CoinShower.coins .. " coins." },
	{ key = "HarvestBox", pass = false, box = "harvest", name = "Harvest Box", text = "Opens one Harvest Box: one needle, odds shown in Boxes." },
	{ key = "StarlightBox", pass = false, box = "starlight", name = "Starlight Box", text = "Opens one Starlight Box: one needle, odds shown in Boxes." },
	{ key = "HeirloomBox", pass = false, box = "heirloom", name = "Heirloom Box", text = "Opens one Heirloom Box: one needle (10% Heirloom shape, 40% Mythic skin, 50% Exotic shape), odds shown in Boxes." },
	{ key = "DoubleCoins", pass = true, name = "2x Coins", text = "Every coin you earn, doubled. Forever." },
	{ key = "ExtraHint", pass = true, name = "Extra Daily Hint", text = "One more hint every day." },
	{ key = "GrandBooth", pass = true, name = "Grand Booth", text = "Your lobby booth shows your " .. Config.GrandBooth.needles .. " best needles, with a gold sign." },
	{ key = "Supporter", pass = true, name = "Supporter", text = "The Supporter title and trail. Thank you!" },
}

function Robux.id(item)
	return (if item.pass then Config.GamePasses else Config.Products)[item.key] or 0
end

return Robux

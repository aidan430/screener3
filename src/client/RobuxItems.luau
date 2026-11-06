-- Every Robux item the game sells, in shop order, with exactly what it gives (shown in the
-- shop's Robux tab and on the Robux pads). kind = "pass" (Config.GamePasses) or "product"
-- (Config.Products); key = its name there. Items whose ID is 0 aren't shown.
return {
	{ kind = "product", key = "SpeedBoost", title = "2x Speed (1 hour)", text = "Every click lifts twice the hay, for 1 hour." },
	{ kind = "product", key = "CoinBoost", title = "2x Coins (1 hour)", text = "All the hay you sell pays double, for 1 hour." },
	{ kind = "product", key = "LuckyCharm", title = "Lucky Charm (1 hour)", text = "5x the chance of a lucky find, for 1 hour." },
	{ kind = "product", key = "StrawBlast", title = "Straw Blast", text = "100,000 straws come off your haystack straight into your basket." },
	{ kind = "product", key = "MerchantWhistle", title = "Merchant's Whistle x10", text = "Send your load to your basket from anywhere, 10 times." },
	{ kind = "pass", key = "AutoSell", title = "Auto Sell", text = "When you're full, your load goes to your basket by itself." },
	{ kind = "pass", key = "DoubleMachines", title = "Double Machines", text = "Every machine harvests twice as fast, on the same power." },
	{ kind = "pass", key = "VIP", title = "VIP", text = "+25% coins, and machines keep working up to 1 hour while you're away." },
	{ kind = "pass", key = "Jetpack", title = "Jetpack", text = "Hold Space (or FLY) in the air to fly up and hover over your pile." },
	{ kind = "pass", key = "SuperTool", title = "Super Tool", text = "Any tool you hold lifts twice the hay and carries twice as much, and glows gold." },
	{ kind = "pass", key = "HayTornado", title = "Hay Tornado", text = "A machine for your farm: harvests 10 straws a second, needs no power." },
	{ kind = "pass", key = "RainbowHay", title = "Rainbow Hay", text = "Just for fun: your hay shows in shifting rainbow colours." },
	{ kind = "pass", key = "SparkleTrail", title = "Sparkle Trail", text = "Just for fun: a soft golden sparkle trail follows you." },
}

# Robux items: what to create on the Creator Dashboard

The prices are suggestions; you decide. Every description says exactly what the item gives,
matching what the game does. Icons are the PNGs in this folder.

## Game passes (bought once, kept forever)
Creator Dashboard > your game > Monetization > Passes > Create a Pass. Upload the icon, enter
the name and description, Create, then open the pass > Sales > turn on "Item for Sale" and set
the price. Copy the pass ID (the number in its page address).

| Icon | Name | Description | Suggested price | Config key |
|---|---|---|---|---|
| vip.png | VIP | +25% coins on everything you sell, and your machines keep working for up to 1 hour while you're away. | 299 | GamePasses.VIP |
| autosell.png | Auto Sell | When your tool and bucket are full, your load goes to your trader's basket by itself. | 149 | GamePasses.AutoSell |
| doublemachines.png | Double Machines | Every machine harvests twice as fast, on the same power. | 249 | GamePasses.DoubleMachines |
| supertool.png | Super Tool | Any tool you hold lifts twice the hay and carries twice as much, and glows gold. | 399 | GamePasses.SuperTool |
| haytornado.png | Hay Tornado | A machine for your farm: harvests 10 straws a second and needs no power. Place it with Build. | 349 | GamePasses.HayTornado |
| rainbowhay.png | Rainbow Hay | Just for fun: your hay shows in shifting rainbow colours. Changes nothing else. | 99 | GamePasses.RainbowHay |
| sparkletrail.png | Sparkle Trail | Just for fun: a soft golden sparkle trail follows you. Changes nothing else. | 79 | GamePasses.SparkleTrail |
| jetpack.png | Jetpack | Hold Space in the air to fly up and hover (H), so you can reach any part of your haystack. | 199 | GamePasses.Jetpack |

## Tool skins (game passes, bought once, kept forever)
Same steps as the passes above. Each skin can also be won on the Wheel of Fortune; buying it
is the sure way. Send Claude the IDs (they go in `Config.Wheel`, `pass = ...`).

| Icon | Name | Description | Suggested price |
|---|---|---|---|
| skin_rose.png | Rose Gold Skin | Your tools in rose gold, with a soft shine that glides along them. Looks only. | 99 |
| skin_ice.png | Ice Skin | Your tools in frosted ice, with little twinkling stars. Looks only. | 99 |
| skin_lava.png | Lava Skin | Your tools in glowing lava cracks that slowly flow. Looks only. | 149 |
| skin_candy.png | Candy Cane Skin | Your tools in rolling candy-cane stripes. Looks only. | 149 |
| skin_galaxy.png | Galaxy Skin | Your tools in a drifting purple galaxy full of stars. Looks only. | 199 |
| skin_diamond.png | Diamond Skin | Your tools in sparkling diamond, with a gleam every few seconds. Looks only. | 249 |

## Developer products (can be bought again)
Creator Dashboard > your game > Monetization > Developer Products > Create a Developer
Product. Upload the icon, enter the name, description and price, Create. Copy its ID.

| Icon | Name | Description | Suggested price | Config key |
|---|---|---|---|---|
| speedboost.png | 2x Speed (1 hour) | Every click lifts twice the hay, for 1 hour. | 49 | Products.SpeedBoost |
| coinboost.png | 2x Coins (1 hour) | All the hay you sell pays double, for 1 hour. | 49 | Products.CoinBoost |
| luckycharm.png | Lucky Charm (1 hour) | 5x the chance of a lucky find while you harvest, for 1 hour. | 29 | Products.LuckyCharm |
| strawblast.png | Straw Blast | 100,000 straws come off the outside of your haystack straight into your basket. | 99 | Products.StrawBlast |
| whistle.png | Merchant's Whistle x10 | Send your load to your basket from anywhere, 10 times. | 25 | Products.MerchantWhistle |
| wheelspin.png | Wheel of Fortune Spin | One extra spin (everyone gets one free spin a day): a tool skin, or (1 in 10,000) the needle's location. Odds shown in game before you buy. | 25 | Products.WheelSpin |

The Wheel is a paid random reward. The game shows the exact odds before buying and hides the
wheel where the player's region restricts paid random items (PolicyService). Check Roblox's
current rules on paid random items before you switch it on; you can leave its ID at 0 to keep
it off.

## Then
Send the IDs to Claude (or paste them into `src/shared/Config.luau` under `Config.GamePasses`
and `Config.Products`) and rebuild. Items with ID 0 stay hidden in the game.

# A Needle in a Haystack (round-based)

A fast, competitive round game for Roblox. Up to 10 players wait in a lobby, are dropped into one
of five haystack-themed mazes, and race to open the 5 chests hidden in it while poking, throwing
and dashing past each other with their needles. A chest holds coins or a key; keys open boxes in
the lobby, and boxes hold the needles players collect, show off and trade. Places go by chests
opened, then tag-outs, then coins. Coins, XP, levels, streaks, daily quests, leaderboards and a
cosmetic shop keep people coming back. Robux never buys combat power.

This is a separate game from the long-form "Needle in the Haystack" in the repo root; it shares
nothing at runtime.

## Folder structure (Rojo project: `default.project.json`)

```
needle-hunt/
  default.project.json      Rojo tree (also used by the build script)
  NeedleHunt.rbxlx          the built place file: open this in Roblox Studio
  dev/test_rules.py         data and rules tests (python3 needle-hunt/dev/test_rules.py)
  src/shared/   -> ReplicatedStorage.Shared   (ModuleScripts, read by server and client)
    Config.luau             every tunable number: round times, difficulty, modifiers, rewards,
                            levels, hints, anti-cheat, DataStore names, Robux IDs, sounds
    Rules.luau              shared arithmetic: XP curve, find rewards, weighted picks, week number
    Maps.luau               the 5 maps: names, lighting, colours, pick weights
    Cosmetics.luau          needle skins, trails, titles, found effects (prices and sources)
    Quests.luau             the daily quest pool and the day's three (same for everyone)
    Needles.luau            the collection: 12 needle types, 57 skins, rarities, values, the roll
    Boxes.luau              what's in each box, the exact odds, the box roll
    Robux.luau              what the shop says about each Robux item
    NeedleLook.luau         builds any needle type in any skin out of parts
  src/server/   -> ServerScriptService.Server
    Main.server.luau        (Script) starts everything
    RoundManager.luau       the round loop and winner detection (server-owned state)
    NeedleSpawner.luau      hides needles on validated spots; checks every claim
    DataManager.luau        DataStore load/save, session cache, safe fallback
    RewardManager.luau      coins, XP, levels, wins, streaks, daily login bonus
    QuestManager.luau       daily quest progress and rewards
    ShopManager.luau        coin shop, equipping, MarketplaceService passes and receipts
    LeaderboardManager.luau OrderedDataStore boards with batched writes and cached reads
    AntiCheat.luau          speed/teleport checks
    Requests.luau           hint and settings requests
    CollectionManager.luau  the needle you keep: rolls it, saves it, values it, shows others
    BoxManager.luau         box openings (coins and Robux), pity, PolicyService
    Combat.luau             the Needle tool, pokes, hearts, tag-outs, inspect
    MatchXp.luau            XP after each match (place, coins, needles, tag-outs)
    RoundExtras.luau        starts/stops power-ups, combat and match XP with the round
    TradeManager.luau       needle trades between players, with the safety checks
    LobbyBuilder.luau       builds the lobby
    MapKit.luau             building blocks for maps; records hiding spots
    MapsA.luau              Classic Haystack Field, Barn Interior, Farm at Sunset
    MapsB.luau              Night Forest, Abandoned Attic
  src/client/   -> StarterPlayer.StarterPlayerScripts.Client
    Main.client.luau        (LocalScript) starts the UI
    UIController.luau       puts the UI together; profile; opens windows; settings; music
    UiKit.luau              the look: colours, buttons, windows, auto-scaling for phones
    Hud.luau                coins/level/XP, round banner and timer, menu, hint button, toasts
    Results.luau            3-2-1, NEEDLE FOUND!, round results
    Screens.luau            Shop and Inventory
    Screens2.luau           Daily Quests, Leaderboard, Settings
    Screens3.luau           the Collection (yours and anyone's in the server)
    NeedleView.luau         a needle in 3D inside the UI
    BoxScreen.luau          the Boxes screen with the odds; BoxReel.luau the opening reel
    CombatFx.luau           pokes, hearts, POP!, inspect (F)
    TradeScreen.luau        the Trade screen and trade invites
    Effects.luau            sounds, particles, soft flash, camera kick, confetti
```

The ModuleScripts the brief asked for are all there: RoundManager, DataManager, NeedleSpawner,
RewardManager, QuestManager, ShopManager, LeaderboardManager and UIController.

## Getting it into Roblox Studio

**Easiest:** open `NeedleHunt.rbxlx` in Studio. Everything is already in place.

**With Rojo:** `rojo serve needle-hunt/default.project.json`, then connect from Studio.

**By hand** (if you copy scripts in yourself):

| Where in Studio | What to create |
|---|---|
| ReplicatedStorage | a **Folder** `Shared` with a **ModuleScript** for each file in `src/shared` (name = file name without `.luau`) |
| ReplicatedStorage | a **Folder** `Remotes` (see below) |
| ServerScriptService | a **Folder** `Server`: `Main` is a **Script**, every other file is a **ModuleScript** |
| StarterPlayer > StarterPlayerScripts | a **Folder** `Client`: `Main` is a **LocalScript**, the rest are **ModuleScripts** |

The lobby and maps are built by script, so there is nothing to place in Workspace or
ServerStorage.

### Remotes (ReplicatedStorage.Remotes)

| Name | Type | Direction | What for |
|---|---|---|---|
| RoundState | RemoteEvent | server → all | phase changes (lobby, loading, countdown, search, results) |
| Found | RemoteEvent | server → all | someone finished: who, place, time, rewards, where |
| Notify | RemoteEvent | server → player | toasts: rewards, level-ups, quest done, warnings |
| Profile | RemoteEvent | server → player | owned/equipped cosmetics, quests, settings |
| SaveSettings | RemoteEvent | player → server | a setting changed (only known true/false settings are kept) |
| Shop | RemoteFunction | player → server | `"buy"` or `"equip"` a cosmetic; the server decides |
| Hint | RemoteFunction | player → server | a hint during a round (limited per day) |
| Boards | RemoteFunction | player → server | the cached leaderboard rows |
| Powerup | RemoteEvent | server → player | the power-up you just took, for your screen |
| ShowOff | RemoteEvent | player → server | hold your showcase needle up (lobby only, cooldown) |
| LobbyInfo | RemoteFunction | player → server | `"best"`: who has the most valuable needle here |
| Collection | RemoteFunction | player → server | `"get"` a collection (yours or a player's in the server), `"list"` who's here, `"showcase"` a needle you own |

### Attributes the game sets

- **ReplicatedStorage:** `Phase`, `EndsAt` (server time), `MapName`, `Difficulty`, `Modifiers`,
  `Golden`, `NeedleCount`.
- **Each player:** `Coins`, `Level`, `XP`, `XPNeed`, `Needles`, `Wins`, `BestTime`,
  `LoginStreak`, `HintsUsed`, and `Pass_DoubleCoins` / `Pass_ExtraHint` / `Pass_Supporter` when
  owned. leaderstats show `Level` and `Needles`.
- **Lobby prompts:** the stall prompts carry `Opens` = `"Shop"` or `"Inventory"`.

### DataStores

| Name | Kind | Holds |
|---|---|---|
| `NeedleHunt_v1` | DataStore, key `u_<UserId>` | the whole player save |
| `NH_Needles_v1` | OrderedDataStore | needles found |
| `NH_Fastest_v1` | OrderedDataStore | best time, in tenths of a second (lowest first) |
| `NH_Level_v1` | OrderedDataStore | level |
| `NH_Coins_v1` | OrderedDataStore | coins earned (all time) |
| `NH_WeeklyWins_v1_<week>` | OrderedDataStore | wins this week (a new store each week) |
| `NH_Collection_v1` | OrderedDataStore | collection value |

**In Studio**, turn on *Game Settings > Security > Enable Studio Access to API Services*, or
nothing saves. If a save can't be loaded, that player plays unsaved for the visit (so their real
save is never overwritten) and is told so. To wipe everyone, change `Config.DataStoreName`.

### Selling with Robux (off until you set IDs)

Every item says exactly what it gives. The only random thing Robux can buy is a Harvest or
Starlight Box (odds always shown, see Boxes). Robux never buys a power-up, a hint during a
round or combat power: coins buy looks (trails, titles, found effects) and boxes.

| Item | Kind | Gives | Suggested price |
|---|---|---|---|
| Starter Bundle | product (`StarterBundle`) | 500 coins + Sparkle Trail; once per player | 49 R$ |
| Pouch of Coins | product (`CoinsSmall`) | 500 coins | 39 R$ |
| Sack of Coins | product (`CoinsMedium`) | 1,500 coins | 99 R$ |
| Cart of Coins | product (`CoinsLarge`) | 4,000 coins | 229 R$ |
| Harvest Box | product (`HarvestBox`) | opens one Harvest Box (odds in Boxes) | 49 R$ |
| Starlight Box | product (`StarlightBox`) | opens one Starlight Box (odds in Boxes) | 149 R$ |
| Heirloom Box | product (`HeirloomBox`) | opens one Heirloom Box (odds in Boxes) | 1,000 R$ |
| Coin Shower | product (`CoinShower`) | 100 coins to everyone in the server, buyer too | 49 R$ |
| 2x Coins | pass (`DoubleCoins`) | every coin earned doubled, forever | 199 R$ |
| Extra Daily Hint | pass (`ExtraHint`) | one more lobby hint a day | 79 R$ |
| Grand Booth | pass (`GrandBooth`) | your lobby booth shows 6 needles, gold sign | 149 R$ |
| Supporter | pass (`Supporter`) | Supporter title + trail | 99 R$ |

Prices are yours to choose; the shop shows whatever price Roblox has. Amounts are in
`Config.CoinPacks`, `Config.CoinShower`, `Config.StarterBundle` and `Config.GrandBooth`; the
shop's wording is in `shared/Robux.luau`.

**Setting them up:**
1. Publish the place (File > Publish to Roblox), so the experience exists on the Creator Dashboard.
2. Creator Dashboard (create.roblox.com) > your experience > **Monetization > Passes** > Create a
   Pass: name, description and a 512×512 icon for each pass; save, open it, **Sales** > On Sale,
   set the price. Copy its ID (the number in its address) into `Config.GamePasses`.
3. **Monetization > Developer Products** > Create a Developer Product for each product, with its
   price. Copy each ID into `Config.Products`.
4. Rebuild (or edit Config in Studio), publish again, and test in a live server: Studio purchases
   are free test purchases that still run the whole code path.

Anything left at 0 is hidden in the shop. Purchases are granted on the server only.
ProcessReceipt records each receipt in the save, so a repeated receipt never pays twice, and it
reports success only after the save is written. Bought coins don't count towards the Most Coins
Earned board.

## How a round works

1. **Lobby:** a 15-second countdown, shown on the HUD and above the Play pad.
2. **Loading:** the server picks the round's settings:
   - a map (never the same one twice in a row)
   - a difficulty: Easy, Normal or Hard (more clutter, darker, drifting hay; chests pay more)
   - maybe a modifier: Speed Round, Low Light, Key Round (every chest holds a key) or Brawl
     (tag-outs pay double)
   - and, sometimes, a Golden Chest (with a Starlight Key inside)

   It then builds the map and places the 5 chests.
3. **Countdown:** up to 10 players (`Config.Round.maxPlayers`) are moved in and held still for 3, 2, 1.
   Anyone beyond 10 waits in the lobby for the next round.
4. **The round:** 3 minutes (90 seconds in a Speed Round).
   - Find a chest, climb up to it and hold E (or the on-screen button) for 3 seconds to open it.
     First come, first served: once it's open, it's empty. A poke or a throw stops you.
   - Inside: coins (30 to 90, times the difficulty), or a key (30%): a Hay Key (70%), Harvest Key
     (25%) or Starlight Key (5%). A key opens one of that box in the lobby, free.
   - Poke, throw and dash (see Needle combat). Tagged out, you're back in 5 seconds.
   - Once the last chest is open, everyone has 15 seconds to finish fights.
5. **Results:** places by chests opened, then tag-outs, then coins collected. Places pay coins
   (60 / 40 / 25 / 10, times the difficulty) and match XP. Then everyone goes back to the lobby.

**Chests are made to be fought over:**
- They go in the dead ends furthest from where players start (a little shuffled each round), then
  any other recorded spot, at least 30 studs apart, each checked for a real floor and room.
- Each stands on a stone perch 4.5 to 8 studs high (never above the walls), with two or three steps
  up from the open side: easy jumps, but you're in plain sight while you climb.
- A Golden Chest stands on the tallest perch (9.5 studs), in the middle of a clearing.
- You have to be up on the perch to open it (reaching from below doesn't count), and holding takes
  3 seconds. Any hit cancels the hold, and for 1.5 seconds after a hit you can't open one. The banner counts chests left; everyone sees
who opened one and what they got. All the numbers are in `Config.Chests`.

**Anti-exploit:**
- Every chest opening is checked on the server: the round is running, you're in it, you're within
  reach, nobody opened it first, and you aren't flagged by the movement check.
- A movement check puts back anyone moving faster than 70 studs/s outside a server teleport.
- Rewards are calculated only on the server.

## The lobby: showing off

The lobby is a 170 × 170 lawn with a hedge all the way round (`server/LobbyDecor.luau` dresses it):
cobbled paths to everything, two spool fountains by the spawn, flower beds, lamp posts, trees behind
the booths, and a hay yard of haystacks behind the title sign.

**When you arrive:**
- You face the **Champion's Needle**: a podium with the single most valuable needle anyone in the server owns, big and glowing, with whose it is.
- After a few seconds, a banner tells you the same thing.

**Booths:** 12 collector booths line the sides, and each player gets one on joining.
- Each shows that player's three best needles.
- Press E at a booth to open that player's Collection.

**Over every head:** a tag shows that player's best needle in its rarity colour, and the champion gets a "♛ MOST VALUABLE NEEDLE" line. The tags hide while a round is being searched.

**Show off!** A button that holds your showcase needle over your head for 6 seconds and tells everyone what it is. Lobby only, with a 15-second wait between uses.

**Also:** benches to sit on, plus the Hall of Needles, the boards and the stalls.

Code: `server/LobbySocial.luau`, `server/LobbyShowOff.luau`, `client/LobbyUi.luau`.

Set Max Players to 10 (Game Settings > Places): a server is one map's worth of players.

## Chests

- **Testing in Studio:** `Config.Testing.revealChests = true` outlines the chests through walls.
  It only works in Studio.
- **Hints** (one free a day, two with the Extra Hint pass) say roughly where the nearest unopened
  chest is. The Compass power-up points at it; Glint makes chests near you sparkle.

**Barriers:** every outdoor map and the lobby have a hedge all the way round, with invisible walls above it up to 200 studs. Anyone who falls below a height of -40 respawns: in a round, back into the map.

## Maze maps

Every map is a maze (`server/MazeKit.luau`), so you search corridor by corridor instead of
scanning one open field. A new layout is generated every round, so nobody can learn it:
- **Building it:** a random walk carves a maze in which every cell can be reached. A few extra
  walls are then knocked through so there are loops, and two or three clearings are opened up
  for big props (haystacks, the farmhouse, the tractor, lanterns).
- **Walls:** taller than a jump, styled to each map:
  - hedges on the field
  - wooden stall walls in the barn
  - hay bales four high on the sunset farm
  - dark thickets in the forest
  - stacked boxes in the attic
- **Hiding spots:** at the back of dead ends and along the foot of walls, as well as on and
  beside the props.
- **Spawns:** players start spread out through the maze.

## Power-ups

Each round, 8 glowing orbs float in the maze's corridors (`Config.Powerups`). Walk into one to
take it; another appears somewhere else 20 seconds later. All of them help you, none slows or
blinds anyone else, and they're only ever found on the map, never bought.

| Power-up | What it does |
|---|---|
| » Hay Boots | Walk at 26 instead of 16 for 12 seconds |
| ▲ Compass | An arrow points to the nearest needle you haven't found, with its distance, for 6 seconds |
| ◉ Bird's Eye | Your camera rises above the maze for 5 seconds |
| ✦ Glint | Needles **and decoys** within 40 studs sparkle for 8 seconds |
| ● Coin Pouch | +25 coins (+50 with 2x Coins) and a little XP |

The server checks every pickup (you're in the round, it's the search, you're really at the orb)
and applies it (`server/Powerups.luau`); your screen shows it (`client/PowerupFx.luau`).

**Icons.** The round power-up icons are in `assets/powerups/` (speed, compass, birdseye, glint,
coins: 512×512 PNGs with see-through corners). Upload each in Studio (Asset Manager > Images >
Bulk Import), copy its ID into that power-up's `image` in `Config.Powerups` (all five are in), and the icon shows
over the orb and on the countdown chip. While `image = 0` the glyph (», ▲, ◉, ✦, ●) shows instead.

## Haystacks

Haystacks are smooth, lumpy terrain domes: a drum, a rounded peak and a few bulges, coloured
straw gold (`Config.Haystacks`). The arena's terrain is cleared between rounds.

To use your own haystack model:
1. Import it in Studio, then right-click it and choose **Save to Roblox**.
2. Put its asset ID in `Config.Haystacks.model`.

Every haystack in the maps and the lobby then uses a copy, scaled to fit (`server/HaystackModel`).
The 8 `Model_material` texture IDs from that import are listed there for reference; the saved
model carries them itself.

## The needle collection

Needles come out of boxes (opened with coins, keys from chests, or Robux) and trades. Each is
one of **94 shapes** in one of **110 skins** (10,340 to collect; the newest 50 are in `shared/NeedleSkins`, with two more patterns, fleck and wave), plus the one-and-only 1 of 1s.

**Shapes** are graded. Every box uses the same shape odds, shown on the Boxes screen:

| Grade | Shapes | Chance | Base value |
|---|---|---|---|
| Classic | the 12 classic needles (Sewing to Sailmaker's) | 83.1% | 8 to 36 |
| Fancy | 32: Firework, Jackhammer, Pencil, Candle, Wand, Paintbrush, Lollipop, Fork, Umbrella, Carrot, Pitchfork, Ice Cream, Corn Cob, Rolling Pin, Broom, Trowel, Wheat Stalk, Milk Bottle, Thimble Awl, Horseshoe, Watering Can, Sunflower, Wooden Spoon, Chopstick, Whisk, Crayon, Spool, Party Horn, Straw, Spinning Top, Toothbrush, Wooden Sword | 11.0% | 40 to 55 |
| Exotic | 25: Swordfish, Narwhal, Hummingbird, Porcupine Quill, Icicle, Thorny Rose, Pine Cone, Cactus Spine, Raindrop, Snowflake, Volcano, Tornado, Toadstool, Coral, Seashell, Unicorn Horn, Stingray, Woodpecker, Dragonfly, Seahorse, Hedgehog, Beetle, Scorpion Tail, Shark Fin Spear, Snail | 4.8% | 60 to 75 |
| Masterwork | 16: Shooting Star, Lightning Bolt, Rocket Ship, Comet Spear, Dragon's Tooth, Crystal Shard, Comet Gem, Ringed Planet, Phoenix Feather, Royal Sceptre, Trident, Hourglass, Rainbow Arrow, Moon Wand, Treasure Key, Lighthouse | 1.1% | 88 to 110 |
| Heirloom | 9, the special collection: **The Eye of the Needle** (1 in 15,049, the rarest shape), Treasure Map, Heirloom Tome, Star Chart, Crystal Cluster, Clockwork Gear, Astrolabe, Brass Compass, Heirloom Key | 0.14% | 150 to 260 |

**Heirloom aura:** every Heirloom shape gives off energy, shaded from dark blood red at the eye to pure red at
the point (`Config.Aura.gradient`; remove it to use each skin's own colours) (`shared/NeedleAura`,
`Config.Aura`): a rippling ForceField skin round each piece, rising wisps, sparks and a soft light,
in a hand, in first person, in flight and on pedestals. On UI screens (no particles there) it shows
as a soft glow. Preview: `previews/heirloom_aura.png`.

The types live in `shared/NeedleTypes.luau`. The 78 newest shapes are kept as data (`shared/ShapesA.luau`, `ShapesB`, `ShapesC`), made by
`dev/shapes.py`, `dev/shapes_more.py` (the 49 from the Gemini sheets) and `dev/shapes_heirloom.py` (the Heirloom collection, `previews/heirloom.png`): change a shape there and
run `python3 needle-hunt/dev/shapes.py`, which also writes the previews' copy. Previews:
`previews/needle_shapes.png`, `needle_shapes_2.png`, `needle_shapes_3.png`.

A needle's worth is its shape's base value × its skin's rarity. The novelty shapes keep the needle
rule (their point is always at the tip), so they work in the hand and when thrown.

**Skins** come in six rarities, each rarer and worth more: Common x1, Uncommon x2, Rare x5,
Epic x12, Legendary x40, Mythic x150. Each box has its own exact odds (see Boxes).

**The 1 of 1s** (`Config.OneOfOne`): two paper-thin Sewing Needles, only one of each in the whole game.
- **Gossamer:** clear as glass, 1 in 12,000,000 per chest.
- **Galaxy Gossamer:** deep purple to pink to blue, glowing and sparkling, 1 in 5,000,000 per
  chest. A little easier to see than the Gossamer, but still paper thin.

Both work the same way:
- Paper thin and nearly see-through: in your hand and in flight it's hard to spot.
- Every chest opened rolls for each (the rarer first). The first finder claims it in a DataStore
  shared by every server (UpdateAsync, one record each), so neither can be handed out twice;
  after that, chests never hold it again. It's never in a box and never sold, so it can't be bought.
- Put on show (your showcase) it's the needle you carry: **one throw tags anyone out** (pokes are
  the same as any needle, and safe time after respawning still protects people).
- Finding it is announced on every server (MessagingService). It can be traded; the record follows it.
- Worth x5000 (50,000). To test in Studio, set a `chance` in `Config.OneOfOne.list` to 1: Studio
  claims a separate store, never the real one.

**Value:**
- A needle is worth its type's base value × its rarity.
- A collection is worth its different needles added up; duplicates show as x2, x3.

**Where needles come from:** boxes (below) and trades. A needle you already have still
counts (x2, x3): keep it or trade it.

**Showing it off:**
- The **Collection** screen shows your collection or anyone's in the server, needle by needle in 3D.
- The lobby's **Hall of Needles** pedestals show the server's top three collections, each with the needle its owner chose.
- **Most Valuable Collection** is a leaderboard, and Collection value shows in the player list.
- Two daily quests use it: "Add 3 new needles" and "Get a Rare (or better) needle from a box".

**Designing more skins:**
- Print or draw on `assets/skin-template/needle_skin_template.png`.
- Fill in a name, two or three colours, a pattern (solid, two-tone, stripes, gradient, rainbow, bands, sheen, split, tri, candy), a material, a rarity and any extras (glow, sparkle). Add `series = "harvest"` (or a new series) to make it a box-only skin.
- Each card becomes one line in `shared/Needles.luau`, and every skin works on all 12 types.

Skins are recipes rather than pictures, so no image upload is needed. For painted image skins
later, free CC0 textures come from Poly Haven, ambientCG and Kenney, or the Roblox Creator Store.

## Boxes

Open a box for a needle for your collection (Boxes in the menu, or the Box Stall in the lobby).

| Box | Price | What's inside |
|---|---|---|
| Hay Box | 400 coins | the regular skins |
| Harvest Box | 1,500 coins or Robux | the Harvest Series (10 box-only skins) |
| Starlight Box | 5,000 coins or Robux | the Starlight Series (10 box-only skins), better odds |
| Heirloom Box | 100,000 coins or 1,000 Robux | 10% an Heirloom shape, 40% a Mythic skin, 50% an Exotic shape |

- **Odds:** every box's exact chance for each rarity, and the skins at each, are always on the
  Boxes screen, below the boxes. They come from `Config.Boxes` (the same numbers the server uses).
- **Guarantee:** every 10 opens without Rare or better, the next one is Rare or better. The screen
  shows how close you are.
- **Where it's restricted:** `PolicyService` says whether paid random items are allowed for each
  player. Where they aren't (or the check fails), boxes are off: the screen says so and sells
  nothing. Every needle can still be found in rounds.
- **The reel:** the server rolls first; the cards on screen are picked by the same odds and the
  strip stops on the result, on the card and never teetering on an edge. Reduce effects shortens it.
- **Robux:** create the HarvestBox, StarlightBox and HeirloomBox developer products (Selling with Robux) and put
  their IDs in `Config.Products`; the R$ button then shows their price.

**The Heirloom Box** works in tiers (`tiers` in `Config.Boxes`): it first picks Heirloom shape
(10%), Mythic skin (40%) or Exotic shape (50%). A shape tier gives one of that grade's shapes by
their own weights (the screen lists each one's chance: The Eye of the Needle is 0.48%, so pulling
it is announced to the server) in a skin rolled Uncommon 45 / Rare 30 / Epic 16 / Legendary 7 /
Mythic 2. The Mythic tier gives a regular Mythic skin on any shape. Chests never hold Heirloom
keys: it's coins or Robux only. Set its price to 1,000 Robux on the HeirloomBox product.

**Keys:** each box has a "Use a key" button showing how many of its keys you have. A key opens
the box free, with the same odds.

**Announcements:** when anyone opens a needle whose rarity had a 0.5% chance or less in its box
(`Config.Boxes.announceAt`: today the Hay Box's Mythic at 0.1% and the Harvest Box's Mythic at
0.5%), everyone in the server gets a banner with the needle turning in it and a line in the chat.

## Needle combat

During a round's search everyone carries their showcase needle (the **Needle** tool, slot 1).
Click or tap to poke the nearest player in front of you.
- 3 hearts. A poke takes one; a heart comes back every 8 seconds without a hit.
- Three gone and you're **tagged out**: a soft pop, then you're back at a maze start after 5
  seconds, with 3 seconds when nobody can poke you. You keep any needles you've found.
- Tagging someone out gives +10 coins (doubled with 2x Coins) and match XP.
- The server checks every poke: in the round, within reach, in front, off cooldown, not safe.
- Every needle pokes the same: skins are looks only, and Robux never buys combat power.
- **Throw:** press Q (or the Throw button) to throw your needle where you're aiming (the mouse;
  the middle of the screen on a phone). It flies point first, up to 45 studs; a hit takes **2
  hearts**, and a wall stops it (it sticks there for a moment). It's out of your hand for about a
  second, so no pokes meanwhile, and you can throw again after 4 seconds (`Config.Throw`). The
  server traces every throw from your head along your aim.
- **Dash:** press C (B on a controller, or the Dash button on a phone) for a quick burst forward,
  along the way you're moving (or facing). Every 3 seconds; works anywhere (`Config.Dash`). The
  DASH bar under your hearts empties when you dash and refills; full and bright means ready.
- **Cooldowns:** a poke every 0.7 s (`Config.Combat.cooldown`), a throw every 4 s
  (`Config.Throw.cooldown`), and no pokes for 1.2 s while your needle is flying. The server enforces
  them; in a round, POKE and THROW bars under the DASH bar refill as each comes back.
- **Inspect:** press F (or the Inspect button) with the Needle out: it lifts and turns in your
  hand, and everyone sees it. Works in the lobby too.
- If the needle points the wrong way in your hand, turn it with `Config.NeedleTool.grip`.
- **First person:** zoomed all the way in, you see your own arms holding the needle
  (`client/ViewModel`), posed and animated from `shared/FirstPerson.luau`: the hold, the inspect,
  the jab and the throw. The arms take your character's skin colour. Everyone else still sees the
  Needle tool in your hand. Design a new rig in the Needle Hand Rig artifact and save it to its
  shelf (or paste its Luau over `shared/FirstPerson.luau`).

All the numbers are in `Config.Combat`.

## Aim settings

Settings, **Aim** (`client/Aim`, `Config.Aim`, checked by `shared/AimSettings` on load and save):
- **Aim sensitivity** 0.2x to 3x (mouse; it scales Roblox's own camera sensitivity).
- **Field of view** 60° to 100° (Roblox's default is 70°). Dashes and finds kick it and come back to yours.
- **Reticle** in the middle of the screen in first person: Cross + dot, Dot, Cross, Circle or None,
  in white, red, yellow, green, cyan or pink, with a thin dark edge so it reads on any background.
- **Reticle size** 0.5x to 2.5x and **reticle thickness** 1 to 6 pixels.
- **Reticle opacity** 20% to 100%, and an **outline** in black, white or none, 1 to 3 pixels thick.
Changes show at once and are saved with the player's profile. Preview: `previews/aim_settings.png`.

## Practice Yard: Time Trial

From the lobby's **Practice** stall (next to the Wardrobe) or **Practice** in the menu, start a
Time Trial in your own yard (`server/Practice`, `server/PracticeYard`, `client/PracticeFx`):
- A hedged paddock with bales and crates for cover, 8 straw dummies (3 slide to and fro) and 5
  chests up on perches with steps (climb up to open, the same hold as a round's chests).
- 3-2-1 on the red start pad, then **3:00** to tag out every dummy (3 hearts each: a poke takes
  one, a throw two) and open every chest. The clock, dummies and chests left are at the top.
- Clear it all and your time is shown, and your best goes on the **Fastest Time Trial** board
  (lobby boards and the Leaderboard screen). Run out of time and you see how far you got.
- Practice only: no coins, XP, keys or needles. Leave any time; you're back in the lobby 10
  seconds after the end, or press Go again. A round never pulls you out mid-run (you join the next).
- Every number is in `Config.Practice` (time, dummies, chests, perch heights, yard size).

## Match XP

XP comes at the end of each match, with a breakdown on the results screen (`Config.MatchXp`):
your place (1st 120, 2nd 90, 3rd 70, everyone else who placed 50), +20 for playing, +0.5 per
coin collected in the match, +40 per chest opened and +25 per player tagged out.

## Trading

Menu > **Trade**: ask anyone in the server. They get Accept / No thanks.
- Both offers show side by side with each needle's rarity and value, and both totals.
- Up to 6 needles a side. Any change un-readies both players.
- When both press Ready, a 5-second countdown runs; either can still cancel.
- Then the server checks both still own everything, swaps them and saves both straight away.
- Only in the lobby, never during a round; cancelled if someone leaves or a round starts.

## Adding things

- **A map:** a row in `shared/Maps.luau`, plus a builder function in `MapsA` or `MapsB`. Use MapKit pieces, which record hiding spots for you, and add at least 6 spawn points.
- **A cosmetic:** a line in `shared/Cosmetics.luau`.
- **A needle skin or type:** a line in `shared/Needles.luau`. A new type also needs its shape in `NeedleLook.luau`.
- **A quest:** a line in `shared/Quests.luau`. Its kind must be one of find, win, play, fast, hard or golden.
- **Numbers:** everything is in `shared/Config.luau`.

## Build and test

```
python3 needle-hunt/dev/test_rules.py        # data and rules tests
python3 dev/build.py --project needle-hunt   # checks every script, writes NeedleHunt.rbxlx
```

The Python checker catches unclosed blocks, unknown names, missing requires and missing
remotes, but it can't run Roblox. Play mode in Studio is the real test.

## Test checklist (Studio)

1. Turn on API access (above). Press **Play** (1 player).
   - The lobby appears: the title sign with the turning needle, the Play pad countdown, the leaderboard, the Daily Challenge board, and the Shop and Wardrobe stalls.
   - The HUD shows your coins, level and XP, the round banner and the menu.
2. You get the "Day 1 login bonus" toast and +25 coins.
3. After 15 seconds:
   - The banner shows the map name, then 3-2-1.
   - You're in a map and can't move until GO.
4. Open a chest: hold E next to it. Use Hint if you can't find one (or `Config.Testing.revealChests`).
   - CHEST OPENED! shows the coins or the key; the banner counts down the chests left.
   - When the last chest is open the round ends 15 seconds later.
5. The results screen lists you 1st with your chests, then you're back in the lobby. Coins, XP and Chests have gone up; a key shows on its box in Boxes.
6. **Shop:** buy the Straw Trail (700 coins). To test quickly, set `Config.Chests.coins = { 2000, 2000 }` for a round and set it back after. It equips; the Inventory shows it.
7. **Inventory:** equip a trail; it follows you. Equip a title (from a quest); it floats over your head.
8. **Quests:** progress bars move after rounds; finishing one pays out with a toast.
9. **Leaderboard:** "This server" shows you; "Everyone" fills in a few minutes after publishing.
10. **Settings:**
    - Sound effects off: there's no click sound.
    - Reduce effects: no flash or camera kick.
    - Join rounds automatically off: you stay in the lobby.
11. Test → **Clients and Servers**, 2 or 3 players:
    - Whoever opens the most chests wins (ties: tag-outs, then coins).
    - Everyone sees who opened which chest and what was inside.
    - A win counts only with 2 or more playing.
12. Stop and Play again: your coins, level, cosmetics and quests are still there.
13. Open a box with a key; with `Config.Boxes.announceAt = 100` for a test, every opening shows the server-wide banner (set it back to 0.5).
14. Phone: Test → Device emulator → a phone.
    - The HUD, menu and windows scale down and stay readable.
    - Holding the chest's button opens it.
15. **Boxes:** open a Hay Box (give yourself coins first); the reel stops on a card and the needle turns. The odds show for all three boxes. In Studio, PolicyService may report boxes as restricted: then the screen says so (that's the safe answer).
16. **Combat** (2 players): equip the Needle (1), click near the other player: hearts drop, POP! shows, three pokes tag them out and they're back in 5 seconds. Press Q aiming at them: the needle flies and takes 2 hearts; aim at a wall and it sticks there. Press F to inspect. Check the needle points forwards in the hand (`Config.NeedleTool.grip`).
17. **Results:** the MATCH XP box shows your breakdown.
18. **Trade** (2 players, in the lobby): ask, accept, add needles, both Ready, wait for the countdown: the needles swap. Changing an offer un-readies both.
19. Watch the Output window for red errors throughout.

## Next 5 features after the MVP

1. **Spectate and a live race feed:** finished players watch the others, and a ticker shows who's close.
2. **Private and party rounds:** friends queue together, and a private server can lock settings (map, difficulty).
3. **Weekly events:** a Golden Needle weekend, a Night Forest week and a festive map, with event-only cosmetics for coins.
4. **More maps and moving maps:** a windy rooftop, a market stall, and a hay maze whose walls shift between rounds.
5. **Seasons:** a season pass track of free and cosmetic rewards, plus a season leaderboard with title rewards.

## Previews

`previews/` holds renders of the lobby and maps (`maps.png`), close-ups of hidden needles
(`needles.png`) and the UI (`ui.png`). They come from a JavaScript port of the map builders
rendered with three.js (`dev/preview`), not from Studio, so Roblox's lighting and materials will
look a little different.

The previews led to these fixes:
- the open maps and the lobby now run into countryside with invisible walls at the edge
  (`MapKit.edges`)
- the attic roof slopes the right way
- the lobby countdown sits low over the Play pad
- windows open a little lower, clear of the round banner

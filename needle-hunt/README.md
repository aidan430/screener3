# A Needle in a Haystack (round-based)

A fast, competitive "find the hidden object" game for Roblox. Players wait in a lobby, are
dropped into one of five haystack-themed maps, and race to click or tap one tiny needle before
the timer runs out. First to find it wins the round; everyone else gets 10 seconds to grab 2nd
and 3rd. Coins, XP, levels, streaks, daily quests, leaderboards and a cosmetic shop keep people
coming back. Nothing is pay-to-win: the hidden needle looks the same for everyone, and Robux
only buys looks, a coin booster and an extra daily hint.

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
    Needles.luau            the collection: 12 needle types, 32 skins, rarities, values, the roll
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

### Robux (optional; off until you set IDs)

Create these on the Creator Dashboard, then put the IDs in `Config.GamePasses` /
`Config.Products`. Anything left at 0 is hidden in the shop.

- Game passes: **DoubleCoins** (2x coins), **ExtraHint** (+1 hint a day), **Supporter** (title + trail)
- Developer product: **StarterBundle** (500 coins + the Sparkle Trail; never a collectible needle)

Purchases are granted on the server only. ProcessReceipt records each receipt in the save,
so a repeated receipt never pays twice, and it reports success only after the save is written.

## How a round works

1. **Lobby:** a 15-second countdown, shown on the HUD and above the Play pad.
2. **Loading:** the server picks the round's settings:
   - a map (never the same one twice in a row)
   - a difficulty: Easy, Normal or Hard
   - maybe a modifier: Double Needle, Speed Round, Low Light or Camouflage
   - and, rarely, a Golden Needle

   It then builds the map and hides the needle.
3. **Countdown:** everyone is moved into the map and held still for 3, 2, 1.
4. **Search:** 3 minutes (90 seconds in a Speed Round).
   - Click or tap the needle, or walk into it.
   - After the first find, everyone else has 10 seconds to place 2nd and 3rd.
   - In a Double Needle round you finish once you've found both.
5. **Results:** places, times and rewards for 10 seconds, then everyone goes back to the lobby.

**Hiding spots** are recorded by each map as it places its props: bale tops, crate tops, the
ground beside haystacks, the barn loft, the attic table and so on. Each round the spawner:
- checks there's a real surface under the spot, nothing solid in the way, and that it's within
  jumping height (or reachable by stairs)
- then nudges and turns the needle so spots can't be memorised.

**Difficulty:**
- **Easy:** a bigger needle with a faint glint.
- **Normal:** a standard needle, more clutter.
- **Hard:** a small needle, lots of clutter, 4 decoys (clicking one locks you out for 3 seconds), darker light and drifting hay bundles.

**Anti-exploit:**
- Every claim is checked on the server: the round is running, you're in it, your character is
  within 16 studs of the needle, and you aren't clicking more than 6 times a second.
- A movement check puts back anyone moving faster than 70 studs/s outside a server teleport and
  blocks their claims for 5 seconds.
- Rewards are calculated only on the server.

## The lobby: showing off

The lobby is a 170 × 170 wooden plaza with a hedge all the way round.

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

Set Max Players to about 12 (Game Settings > Places) to match the booths.

## Finding the needle

- **Size:** needles are 3.6 / 2.8 / 2.0 studs long (Easy / Normal / Hard) with a bigger grab box (`Config.Find`).
- **Hover:** point at a needle within reach and it lights up with a white outline and "Click to grab!".
- **Counter:** the banner counts what you've found ("0/1").
- **Once yours:** the needle vanishes from your screen, while others still see theirs.
- **Testing in Studio:** `Config.Testing.revealNeedle = true` outlines the hidden needle through walls and prints where it is. It only works in Studio.

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
Bulk Import), copy its ID into that power-up's `image` in `Config.Powerups`, and the icon shows
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

Every needle a player finds is theirs to keep. Everyone hunts the same plain needle, so it stays
fair. When you find it, the server reveals what it really was: one of **12 types** (Sewing
Needle, Dressmaker's Pin, Darning Needle, Knitting Needle, Crochet Hook, Safety Pin, Curved
Upholstery Needle and more) in one of **32 skins**. That makes 384 to collect.

**Skins** come in six rarities, each found less often and worth more:

| Rarity | Chance | Worth |
|---|---|---|
| Common | 55% | x1 |
| Uncommon | 25% | x2 |
| Rare | 12% | x5 |
| Epic | 6% | x12 |
| Legendary | 1.8% | x40 |
| Mythic | 0.2% | x150 |

**Luck:**
- 1st place and Hard rounds give extra luck (`Config.Collection`).
- A Golden Needle round always gives the Golden skin.

**Value:**
- A needle is worth its type's base value × its rarity.
- A collection is worth its different needles added up; duplicates show as x2, x3.

**Earned only:** needles are never sold for coins or Robux and never come from anything paid.

**Showing it off:**
- Everyone sees what you found as you find it.
- The results list each player's needle.
- The **Collection** screen shows your collection or anyone's in the server, needle by needle in 3D.
- The lobby's **Hall of Needles** pedestals show the server's top three collections, each with the needle its owner chose.
- **Most Valuable Collection** is a leaderboard, and Collection value shows in the player list.
- Two daily quests use it: "Add 3 new needles" and "Find a Rare (or better) needle".

**Designing more skins:**
- Print or draw on `assets/skin-template/needle_skin_template.png`.
- Fill in a name, two colours, a pattern (solid, two-tone, stripes, gradient, rainbow), a material, a rarity and any extras.
- Each card becomes one line in `shared/Needles.luau`, and every skin works on all 12 types.

Skins are recipes rather than pictures, so no image upload is needed. For painted image skins
later, free CC0 textures come from Poly Haven, ambientCG and Kenney, or the Roblox Creator Store.

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
4. Find the needle. If you can't, use Hint; one works, the second says none are left today.
   - Clicking it shows NEEDLE FOUND! with your needle skin, place, time and rewards, a burst and a soft flash.
   - The round ends 10 seconds later (or at once when you're alone).
5. The results screen lists you 1st, then you're back in the lobby. Coins, XP and Needles have gone up.
6. **Shop:** buy Copper (400 coins). To test quickly, set `Config.Rewards.findCoins = 2000` for a round and set it back after. It equips; the Inventory shows it.
7. **Inventory:** equip a trail; it follows you. Equip a title (from a quest); it floats over your head.
8. **Quests:** progress bars move after rounds; finishing one pays out with a toast.
9. **Leaderboard:** "This server" shows you; "Everyone" fills in a few minutes after publishing.
10. **Settings:**
    - Sound effects off: there's no click sound.
    - Reduce effects: no flash or camera kick.
    - Join rounds automatically off: you stay in the lobby.
11. Test → **Clients and Servers**, 2 or 3 players:
    - The first finder wins.
    - Others get 10 seconds to place.
    - A win counts only with 2 or more playing.
12. Stop and Play again: your coins, level, cosmetics and quests are still there.
13. Hard round: decoys say "A decoy!" and lock you out for 3 seconds.
14. Phone: Test → Device emulator → a phone.
    - The HUD, menu and windows scale down and stay readable.
    - Tapping the needle works.
15. Watch the Output window for red errors throughout.

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

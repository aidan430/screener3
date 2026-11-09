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

**In Studio**, turn on *Game Settings > Security > Enable Studio Access to API Services*, or
nothing saves. If a save can't be loaded, that player plays unsaved for the visit (so their real
save is never overwritten) and is told so. To wipe everyone, change `Config.DataStoreName`.

### Robux (optional; off until you set IDs)

Create these on the Creator Dashboard, then put the IDs in `Config.GamePasses` /
`Config.Products`. Anything left at 0 is hidden in the shop.

- Game passes: **DoubleCoins** (2x coins), **ExtraHint** (+1 hint a day), **Supporter** (title + trail)
- Developer product: **StarterBundle** (500 coins + the Rose Gold needle skin)

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

## Adding things

- **A map:** a row in `shared/Maps.luau`, plus a builder function in `MapsA` or `MapsB`. Use MapKit pieces, which record hiding spots for you, and add at least 6 spawn points.
- **A cosmetic:** a line in `shared/Cosmetics.luau`.
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

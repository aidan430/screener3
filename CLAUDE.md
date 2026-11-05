# Needle in the Haystack: operational brief

## What this is
An original Roblox mystery simulator. A needle is hidden somewhere in 5,000,000 straws spread
over ten haystacks on Hollow Creek Farm, an autumn farm at sunset. Players search haystacks
with a fork to earn coins, buy better tools to search faster, and turn up clues that rule
haystacks out. Whoever's handful holds the needle solves the case, everyone who searched gets
a reward, and a new case begins with a new story.

The owner publishes from Roblox Studio and owns the Roblox account, the Robux items and the
earnings. Nothing is published, sold or priced without them. The factory project that used to
live here was scratched on 2026-11-05 (git history keeps it, last at commit 10898e5).

## How it plays
- **Cases** (`server/Rounds.luau`): each case picks a story from `shared/Cases.json` and hides
  the needle in a random haystack. When it is found, rewards go out and a new case starts
  after `Config.SolvedPause` seconds. Haystacks refill for every case.
- **Searching** (`server/Search.luau`): the client only asks (Remotes.Search); the server checks
  the player holds their tool within `Config.SearchRange` of a haystack, at most one search per
  `Config.SearchCooldown`. A search takes the tool's power in straws (or what is left), pays
  coins and, in the needle's haystack, finds the needle with chance handful / remaining
  (the needle is equally likely to be any remaining straw; the last handful always finds it).
- **Clues** (`shared/Clues.luau`): built from the needle haystack's side of the farm, water,
  buildings and animals (`shared/Piles.json`), each ruling haystacks out, ending with a trace
  only one place leaves. Each search has `Config.ClueChance` of giving that player their next
  clue. Clues are personal; players can share them in chat.
- **Progress**: coins buy eight tools in order (`Config.Tools`); rebirth resets coins and tool
  for +50% coins a search. The Needle Detector also beeps at the needle's haystack.
- **Saving** (`server/PlayerData.luau`): DataStore `Config.DataStoreName`. If a load fails, the
  player plays unsaved rather than risk overwriting good data.
- **Robux** (`server/Monetization.luau`): 2x Coins and Auto Search passes, a Clue Hint product.
  All IDs are 0 (off) until the owner creates the items and their IDs go into Config.

## Layout (Rojo project: `default.project.json`)
```
src/shared/   -> ReplicatedStorage.Shared: Config, Economy, Clues, Format, Piles.json, Cases.json
src/server/   -> ServerScriptService.Server: Main (Script), World, Landmarks, Build, Haystacks,
                 Rounds, Search, PlayerData, Tools, Shop, Monetization
src/client/   -> StarterPlayerScripts.Client: Main (LocalScript), Ui, Hud, Panels, Notify, WorldFx
dev/          -> build.py (checks + writes the place file), luau.py (checker), test_rules.py
NeedleInTheHaystack.rbxlx   the built place file the owner opens in Studio (committed)
```
The world (terrain, farm, landmarks, haystacks, lighting) is built by `server/World.luau`,
`Landmarks.luau` and `Haystacks.luau` when the server starts, so it only appears in Play mode.

## Build and check
- `python3 dev/build.py` checks every script (unclosed blocks, unknown names, global functions,
  requires and remotes that don't exist, scripts placed where they never run) and writes
  `NeedleInTheHaystack.rbxlx`. `python3 dev/build.py --check` only checks.
- `python3 dev/test_rules.py` tests the data, the clue logic and the tool prices.
- With Rojo installed, `rojo build -o NeedleInTheHaystack.rbxlx` gives the same tree, and
  `rojo serve` syncs into Studio. Rojo, Lune, luau-lsp and selene could not be downloaded in the
  cloud sandbox, so the Python checker stands in; it does not type-check Roblox APIs. Studio
  Play mode is the real test: read the Output window for red errors.

## Rules
- Original content only: never copy another game's name, map, art, story or UI.
- Kid-friendly, within Roblox's Community Standards. No paid random rewards (no loot boxes);
  every Robux item says exactly what it gives.
- The server decides everything that matters (searches, coins, clues, the needle, purchases);
  the client asks and shows.
- Every tunable number lives in `src/shared/Config.luau`. Record changed defaults in NOTES.md.
- Keep files under 300 lines. No new external dependency without asking.
- Run `python3 dev/test_rules.py && python3 dev/build.py` before every commit and commit the
  rebuilt place file with the code.

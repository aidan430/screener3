# Needle in the Haystack: operational brief

## What this is
An original Roblox simulator. One giant haystack of 5,000,000 straws on Hollow Creek Farm hides
a needle. Each player's progress through it (and their needle) is their own and saved. Players
search with a tool (straw fills their bag), sell the bag to the merchant for coins, and spend
coins on tools, bags, machines (which search by themselves) and tool perks. Timed power-ups are
Robux only. Ten achievements open the Golden Loft, a secret level above the barn with a golden
haystack. A free player reaches the needle after about 18-24 hours of play (dev/pacing.py).

The owner publishes from Roblox Studio and owns the Roblox account, the Robux items and the
earnings. Nothing is published, sold or priced without them.

## How it plays
- **Searching** (`server/Search.luau`): the client only asks (Remotes.Search); the server checks
  the player holds their tool within `Config.SearchRange` of a haystack and honours the cooldown.
  A search moves `Economy.power` straws from the player's haystack into their bag. The needle is
  at a saved straw index (`needleAt`, never in the first `NeedleEarliest`); the search that
  crosses it finds it: a prize, +20% coins for good, and a fresh haystack.
- **Machines** tick every second into the bag while the player is in the game (VIP: an hour
  after leaving too). A full bag stops everything until it is sold (Auto Sell pass sells it).
- **Selling** (Remotes.Sell) needs the player within `MerchantRange` of the stall; a Merchant's
  Whistle (Robux) sells anywhere.
- **Shop** (Remotes.Buy kind,index): tools and bags in order, machines up to their max, perks
  per tool (reset on a new tool). All prices from Config via `Economy`.
- **Lucky finds**: `Finds.json`, a chance per search; coins plus a line of the mystery.
- **Achievements** (`server/Achievements.luau`): ten numbers from the player's stats; all ten set
  the `LoftOpen` attribute and `server/Loft.luau` teleports the player up or down.
- **Saving** (`server/Profile.luau`, `server/PlayerData.luau`): DataStore `Config.DataStoreName`;
  a failed load plays unsaved rather than overwrite good data.
- **Robux** (`server/Monetization.luau`): all IDs 0 (off) until the owner creates the items.

## Layout (Rojo project: `default.project.json`)
```
src/shared/   -> ReplicatedStorage.Shared: Config, Economy, Format, Finds.json
src/server/   -> ServerScriptService.Server: Main (Script), World, Build, Haystack, Profile,
                 PlayerData, Search, Shop, Achievements, Loft, Tools, Monetization
src/client/   -> StarterPlayerScripts.Client: Main (LocalScript), Ui, Hud, Shop, Panels, Notify, WorldFx
dev/          -> build.py (checks + writes the place file), luau.py (checker), test_rules.py,
                 pacing.py (how long the haystack takes; keep in step with Economy.luau)
NeedleInTheHaystack.rbxlx   the built place file the owner opens in Studio (committed)
```
The world (terrain, farm, merchant, yard, barn, loft, haystacks, lighting) is built by
`server/World.luau` and `Haystack.luau` when the server starts, so it only appears in Play mode.

## Build and check
- `python3 dev/build.py` checks every script (unclosed blocks, unknown names, global functions,
  requires and remotes that don't exist, scripts placed where they never run) and writes
  `NeedleInTheHaystack.rbxlx`. `python3 dev/build.py --check` only checks.
- `python3 dev/test_rules.py` tests the data, the achievements and the 24-hour pacing.
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

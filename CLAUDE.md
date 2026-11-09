# Needle in the Haystack: operational brief

## What this is
An original Roblox simulator, strictly first person. Four players a server. All four plots
share the middle of the farm: one haystack stands there, and each player sees and digs only
their own copy of it (their screen draws it as terrain from their save, client/PileView), and
sees only their own buildings and hay (client/OnlyMine; each plot has a collision group that
doesn't collide with the others'). Each player's heap is one smooth terrain haystack of 5,000 clumps
of 1,000 straws (5,000,000), 80 studs (22 m) high and 88 across, one clump per 4-stud terrain cell, saved clump by
clump, with the needle hidden deep in the upper heap. Players lift hay off the heap onto their
fork (visible on the tines; buckets at the hip carry more), dump it in their own trader's basket,
and buy tools, perks, buckets, a silo, building pieces (stairs, escalators, elevators, teleporters),
machines and the generators that power them, all placed freely on their plot. Robux buys
power-ups and Wheel of Fortune spins (skins, or a 1-in-10,000 needle reveal). Ten secret
achievements open the Golden Loft. Machines peel the heap from the outside in, so a free player
who never climbs finds the needle in about 29 hours; climbing up and digging in is faster.

The owner publishes from Roblox Studio and owns the Roblox account, the Robux items and the
earnings. Nothing is published, sold or priced without them.

## How it plays
- **Plots** (`server/Plots.luau`): claimed on join, released on leave, all centred on (0, 0);
  `Piles.luau` keeps the heap's data and sends it to its owner's screen, which draws it with
  `shared/HeapTerrain.luau`; the server never draws heaps (no server terrain for them), from `Layout.luau` (index order is saved order: never reorder it; change the
  DataStoreName if you must), `Structures.luau` the placed things (saved relative to the plot centre).
- **Harvesting** (`server/Search.luau`): the client sends the point it aimed at, just inside the
  heap's surface (Remotes.Harvest); the server checks it is on the player's plot and within
  `Config.Reach`, finds the nearest clump left there, equips the tool if needed, and moves straws
  onto the tool (`carried`, up to capacity). `server/Carry.luau` shows the load on tool and bucket.
- **Machines** (`server/Machines.luau`): every second, power share x machine rate straws from
  the outside of the heap inwards (`Layout.machineOrder`) into the silo. Also Straw Blast, VIP offline time, height records.
- **Selling** (`server/Hauling.luau`): dumping (your Trader's Stall basket, the hub merchant, a
  Whistle) fills your basket; the trader and your trucks sell from it every second. G drops
  hay as a bundle (`server/LooseHay.luau`); conveyors carry bundles to the basket or a bale maker.
- **Building**: Remotes.Place(id, position, rotation) / Remove(model); the server checks
  inventory and plot bounds. Elevators teleport via their prompts.
- **Wheel** (`server/Wheel.luau`): the WheelSpin product picks a weighted prize on the server.
  Odds are shown before buying; PolicyService hides it where paid random items are restricted.
- **Farmer Level** (`server/Levels.luau`, `client/LevelBar.luau`, `ConfigLevels`): every lift earns
  XP; quick level-ups (+1 Strength, a small capped carrying bonus), 6% Lucky Lifts (x2 XP), the
  auto-fork (R), and a Top Farmers board (`server/LevelBoard.luau`).
- **Feel** (`client/Juice.luau`): every effect eases; keep it relaxing, no flashing, and no
  pressure tactics around Robux.
- **Saving** (`server/Profile.luau`, `server/PlayerData.luau`): a failed load plays unsaved.

## Layout (Rojo project: `default.project.json`)
```
src/shared/  -> ReplicatedStorage.Shared: Config (+ ConfigFactory, ConfigGoals, ConfigPlayer, ConfigLevels and
                others, merged in), Economy, Layout, Format, HayLook, Finds.json
src/server/  -> ServerScriptService.Server: Main (Script), World, Scenery, Build, Plots, Piles,
                Pieces, Structures, Profile, PlayerData, Search, Machines, Shop, Achievements,
                Loft, Haystack (the loft), Wheel, Tools, ToolLook, Assets, Carry, Hauling,
                HayItems, LooseHay, Processing, Factory, Orders, Goals, Stamina, Detector,
                PiecesBelts, PiecesFactory, Monetization
src/client/  -> StarterPlayerScripts.Client: Main (LocalScript), Ui, Cursor, Juice, Hud, Shop,
                Panels, Harvest, HayFx, Teleport, Guide, OrderCard, Goals, Stamina, Detector,
                BuildMode, Notify, WorldFx, Music, Jetpack, Offer, Animals, Controls,
                TouchPad, TouchAim (phones and tablets)
dev/         -> build.py, luau.py (checker), test_rules.py, pacing.py (keep in step with Economy)
assets/hay/  the hay texture and the simplified hay model, for the owner to import in Studio
NeedleInTheHaystack.rbxlx   the built place file (committed)
```

## Build and check
- `python3 dev/build.py` checks every script (unclosed blocks, unknown names, global functions,
  requires and remotes that don't exist, scripts placed where they never run) and writes
  `NeedleInTheHaystack.rbxlx`. `python3 dev/build.py --check` only checks.
- `python3 dev/test_rules.py` tests the heap layout, the needle's hiding places, items, wheel odds,
  achievements and the pacing.
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
- Every tunable number lives in `src/shared/Config.luau` or its merged companions
  (`ConfigFactory`, `ConfigGoals`, `ConfigPlayer`). Record changed defaults in NOTES.md.
- Keep files under 300 lines. No new external dependency without asking.
- Run `python3 dev/test_rules.py && python3 dev/build.py` before every commit and commit the
  rebuilt place file with the code.

# NOTES: choices and defaults

Every default below was chosen without asking. Change any of them in `src/shared/Config.luau`
(numbers), `src/shared/Finds.json` (lucky finds and story) or `src/server/World.luau` (the hub).

## Version 3 (2026-11-05): your own 70 m pile, building, power, the wheel
Your brief: a smaller map; a pile at least 70 m high stacked from the 5 million straws; tools
that carry a set amount; stairs, escalators and elevators to climb; machines that need
generators; strictly first person; secret achievements; a Robux wheel of fortune giving tool
skins or the needle's location. Then: smooth, satisfying, relaxing animations.

Your choices when asked: clumps of straw (5 million single parts would crash Roblox), a plot each,
free placement, and a winnable needle reveal on the wheel.

- **Map:** four 140-stud plots around a hub (merchant north, wheel south, golden door east).
  About 330 by 330 studs inside the fence, down from 400 by 400. Servers should be set to 4
  players (Game Settings, Places, Max Players) since there are four plots.
- **Your pile:** 5,000 clumps of 1,000 straws, 5-stud cubes in 51 layers tapering from a
  42-stud to a 12-stud radius: 255 studs (about 71 m) high. Saved clump by clump. The needle
  is in one random clump; harvest it to the last straw to find it.
- **Pacing (dev/pacing.py, tested):** a free player who clicks 3 times a second, walks 45
  seconds to sell and buys well finds the needle after about 24 hours on average (the whole
  pile takes 35). With every Robux item: about 7 hours.
- **Tools:** 10, 1-22 straws a click, carrying 300 to 100,000. The Needle Detector (last tool)
  says how close the needle's clump is: cold, warm, hot, burning.
- **Silo:** machines harvest the top of your pile into the silo (2,000 to 500,000); selling
  empties it too. Machines need power: five generators (4-260 power), five machines (0.15-7.5
  straws/s, 2-45 power each). Short of power, every machine slows to the share you make.
- **Building:** stairs (10 up, 10 along), landings, pillars, escalators (a moving ramp),
  elevators (50 studs; press E). Placed anywhere on your own plot, up to 400 things, with Z/C
  to pick, R to turn (Shift+R for 15 degrees), click to place, X to take back.
- **First person:** the mouse is locked to the crosshair; M frees it for menus, and opening a
  menu frees it too. Q shop, B build, E use.
- **Wheel of Fortune:** Robux spins. Every spin wins: six tool skins (30%, 25%, 20%, 15%, 7%,
  2.99%) or the needle reveal (0.01%, 1 in 10,000) that makes your needle's clump glow. A skin
  you have pays coins. The odds are on screen before you can spin; the wheel is hidden (and a
  spin pays coins) where Roblox restricts paid random items.
- **Feel:** straw puffs and a soft camera push on every click, floating numbers, a combo
  counter, pop rings and a bigger push when a clump empties, coins flying into your counter,
  counters that count up, confetti for finds, every 100 clumps and the needle. Smooth easing,
  no flashing. No pressure tactics on Robux purchases. Sounds are off until you add Toolbox
  sound IDs to `Config.Sounds`.
- **Achievements (secret until earned):** First Straw, Full Load, Merchant's Friend, Collector,
  Engineer (10 machines working), Power Plant (500 power), Sky High (stand 250 studs up on your
  plot), Perfectionist, Lucky Duck, Needle Finder. All ten open the golden door to the Loft.
- **Performance:** 5,000 parts per pile, up to 20,000 with four players. Fine on computers;
  older phones may struggle. If they do, raise `ClumpSize` and lower `Clumps` together.

## Version 2 and 1, replaced
One giant shared-looking haystack (v2, commit cead0ee); ten haystacks with case rounds (v1,
commit 7d2617e). Both in git history.

## Not done yet
- A global leaderboard, daily rewards, 3D models from the Toolbox.

## Sound, music, Jetpack and one gentle offer (2026-11-05)
- **Sounds (`Config.Sounds`, `Config.SoundSettings`):** harvest, pop, coins and cheer now use
  sound files built into every Roblox client (`rbxasset://sounds/...`: the default footstep,
  landing thud and the classic short ping), so they can't go private. Harvest plays quietly
  (0.25) with a random pitch wobble of +/-6% so repeated clicks don't tire. A sound that fails to
  load stays silent. To swap one: in Studio open the Toolbox, Creator Store > Audio, filter by
  Sound Effects, search "hay rustle" / "grass rustle" / "soft chime" / "success", preview,
  right-click > Copy Asset ID, and paste it into Config as "rbxassetid://<id>".
- **Music (`Config.Music`, `MusicVolume` 0.25, `MusicFadeSeconds` 3, `MusicLoadSeconds` 10):**
  two acoustic instrumentals from the licensed library Roblox uploaded for every game, found on
  catalogue sites but not checked here: 1844140274 "Country Folk Picking" (Will Morgan) and
  1842101902 "Acoustic Nomad" (Alex Tschallener). Check them in Studio. A track that doesn't load
  in 10 seconds is skipped. To add more: Toolbox, Creator Store > Audio, filter by Music, search
  "country acoustic" / "folk guitar" / "banjo", keep calm instrumentals, paste each as
  `{ id = "rbxassetid://<id>", name = "..." }`. The ♪ button (top right; press M to free the
  mouse) turns music off for the session. Empty `Config.Music` hides the button.
- **Jetpack (game pass `Config.GamePasses.Jetpack`, 0 = off; tunables in `Config.Jetpack`):**
  hold Space in the air to rise at 18 studs/s, let go to drift down at 7, H to hover (F places
  things in build mode, so not F). Force capped at 2.5 body weights; no lift above 275 studs
  (the pile is 255, the Golden Loft is above 300). Unlimited flight by default
  (`fuelSeconds = 0`). Touch screens get FLY (hold) and HOVER buttons. To switch it on: create
  the pass on the Creator Dashboard, paste its ID. It shows in the shop's Robux tab.
- **Offer (`Config.OfferAfterClumps` 25):** once per session, after 25 clumps harvested since
  joining, one card "Enjoying the harvest?" lists Speed Boost and Jetpack if their IDs are set
  (Jetpack not if owned), with a "No thanks" button as big as the others. Nothing set: no card.

## v4: one smooth heap, visible hay, your own trader (2026-11-05)
- **The heap is terrain now.** Terrain Grass is the heap (recoloured `Config.HeapColour`, its
  grass blades read as loose straw); the ground is LeafyGrass. One clump = one 4-stud terrain
  cell: `ClumpSize` 4 (must stay 4, the terrain grid), `PileLayers` 64 (256 studs),
  `PileRadiusBottom` 38, `PileRadiusTop` 4, `PileCurve` 1.6: exactly 5,000 clumps. A clump
  shrinks in 8 visible steps as you harvest it. `DataStoreName` is now `NeedleHaystack_v4`
  (old saves number clumps differently; nobody had live saves yet).
- **Needle:** `NeedleHeight` {0.5, 0.8} of the height, `NeedleCore` 0.4 of the radius there:
  68 hiding places. Machines and Straw Blast peel from the outside in (`Layout.machineOrder`),
  reaching it after about 94% of the heap: about 34 h for a free player who never climbs
  (was 24 h), 10.5 h with Robux. Climbing and digging into the core is the shortcut.
- **Slopes:** `MaxSlopeAngle` 46: the steep heap can't be walked up; build or fly.
- **Buckets (`Config.Buckets`):** 600 / 2,000 / 6,000 / 20,000 / 60,000 extra straws for
  1.5K / 9K / 60K / 400K / 2.5M coins, in the shop's Storage tab. The tool fills first.
- **Trader's Stall:** every player gets one, `TraderDistance` 50 studs from the plot centre
  towards the hub; take it back (X) and place it anywhere, even on a platform.
  `BasketDrainSeconds` 4 is just the cart-away animation; dumping pays at once.
- **Teleporter Pad:** 25,000 coins; E on a pad lists your other pads by height.
- `LoadSize` 2.4: how big the hay on a full tool is.

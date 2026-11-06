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
- **The countryside (`Scenery*.luau`, client `Animals.luau`):** the ground is now 1000 x 1000
  studs with the fence at +/-480 (gate on the north lane) and hills beyond. North: barn, two
  silos, farmhouse, tractor. West: pens with cows, sheep, pigs and chickens that wander on each
  player's screen. East: pumpkin and corn fields. South: duck pond, windmill, water tower,
  orchard. Nothing is built within 172 studs of the centre on either axis (plots and roads).
  Scenery is built inside a pcall: if it fails it only warns in Output.

## v5: hay texture and model, hauling, trucks, conveyors, bale maker (2026-11-05)
- **Hay texture (`Config.HayTexture`, `HayNormal`, `HayTextureStuds` 8, `HayTint`):** scripts
  can't set a MaterialVariant's images, so `dev/build.py` writes a MaterialVariant "Hay" into
  MaterialService (overriding Grass, Organic pattern) when `HayTexture` has an ID. Grass is now
  only hay: the heap, the hay on tools, bundles, bales, the basket. Plot floors moved to
  LeafyGrass. To switch it on: upload `assets/hay/garden-hay.jpg` in Studio (Asset Manager >
  Import), copy its ID into `HayTexture`, rebuild.
- **Hay model (`Config.HayMesh`, `HayMeshTexture`):** `assets/hay/garden-hay-roblox.obj` is the
  supplied FBX (489,622 triangles, too many for Roblox's 20,000 limit) simplified to 7,583
  triangles and scaled to 1 stud, made by `dev/tools/decimate.py` (needs numpy; only for
  re-making the OBJ, never at build time). Import it in Studio, paste the MeshId and the
  texture's ID: lumps on tools, flying hay, bundles and the `HeapMounds` (16) round each heap
  use it (as a SpecialMesh, which scripts can set). The FBX's normal maps weren't in the file.
- **Hauling:** dumping (basket, hub merchant, Whistle, Auto Sell) fills your basket; nothing
  pays at once except golden straw. `TraderRate` 8 straws/s plus trucks (Farm Van 15/s 8K,
  Mini Truck 35/s 60K, Semi 90/s 500K, Large 220/s 3M, two of each) sell it continuously;
  each truck visibly calls every `TruckTripSeconds` (40). Bales count `BaleCompaction` (3)
  times as easily. A free player buys two vans by 9 h and mini trucks at 14 h and 32 h; the
  needle still comes at about 34 h (12 h with Robux). Semis and large trucks are headroom for
  factories.
- **Loose hay:** G (`DropKey`) drops your load as a bundle on your own plot (at most
  `MaxLooseHay` 40 loose things per plot). Conveyor Belt (800) and Conveyor Down (1,500, 10
  studs) move bundles at `ConveyorSpeed` 10. The basket's sensor takes bundles and bales.
  Bale Maker (60K, max 3): bundles in at the back, a 2,000-straw bale (`BaleStraws`) out the
  front; E picks a bale up, G puts it down. Loose hay left `LooseHayMinutes` (10) goes to the
  basket by itself; on leaving it's saved as `loose` and waits in the basket next time.
- **Lower, wider haystack (owner's request):** `PileLayers` 20 (80 studs, 22 m, was 256),
  `PileRadiusBottom` 44 (88 across), new `PileDome` 2.5 with `PileCurve` 0.7: straight sides
  that round over at the top. Still exactly 5,000 clumps; 231 hiding places for the needle;
  pacing unchanged (about 34 h). `TraderDistance` 57 and the arrival point moved out to clear
  the wider heap. "Sky High" is now "stand on top of your haystack, 75 studs up".
  `DataStoreName` is `NeedleHaystack_v5`.
- **Imported models (`server/Assets.luau`):** any tool in `Config.Tools` can wear a model you
  uploaded (`model` = asset ID, `length` studs, `flip` = false if upside down). The starter
  tool is now the owner's Garden Trowel (model 139238222017221; its mesh is 89866055047467). `Config.HayModel` (92326825877863) is
  the owner's hay; the server loads it once and shares it as `ReplicatedStorage.HayTemplate`
  for every loose bit of hay. An ID loads as a saved Model (InsertService, keeps textures) or
  else as a mesh (AssetService:CreateMeshPartAsync); if neither works the built-in look stays
  and Output says why. Both need the assets to be owned by the game's owner.
- **Ladder (200 coins, Build tab):** the owner's ladder model (111414262141412), stood up and
  scaled to 20 studs, with an invisible TrussPart inside that characters climb. Wooden rails
  and rungs stand in if the model won't load. Stack ladders to go higher.
- **Hay texture on:** `HayTexture` = the owner's uploaded image 92326825877863 (garden-hay.jpg).
  That ID is an Image, not a model, so `HayModel` is back to 0: loose hay uses the built-in
  shape in the Grass material, which now wears the same texture.
- **Owner's feedback:** `HayTextureStuds` 8 -> 3 (the texture was too big). Imported tools are
  held straight out in front, working end forward (`flip`, `roll`, `bladeTop`, `loadAt`,
  `loadSize` per tool tune it). The hay on a tool now sits on a Weld whose offset keeps its
  bottom on the blade (or tines) as it grows, so it never sinks through.
- **Grass texture on the fields:** `GroundTexture` = the owner's gltf_embedded_2 (92652087782912)
  with `GroundNormal` gltf_embedded_3 (81088945047843), every `GroundTextureStuds` 6, tint
  `GroundTint`. `dev/build.py` writes it as the MaterialVariant "Field" over LeafyGrass (the
  terrain fields and the plot floors). gltf_embedded_0 (grass blades with transparency) and
  internal_ground_... aren't used.
- **Owner's feedback (heap looked like dirt):** the first hay image (92326825877863) is dark
  brown and averaged out to soil from a distance; tinting can only darken a texture. Made
  `assets/hay/garden-hay-golden.jpg` (levels stretched and mapped onto a straw gradient, average
  colour 208,170,87); `HayTexture` is "" (plain straw gold) until that's uploaded, then
  `HayTextureStuds` 5. New `HeapLumpiness` 0.45: a fixed random dent per terrain cell, so the
  surface is lumpy like forked hay. `GroundTextureStuds` 6 -> 16 (grass bigger).

## Review fixes (2026-11-05)
Two independent reviews (server, client). Fixed: crosshair offset by the top-bar inset
(IgnoreGuiInset); Golden Loft announcement unhandled; "hold your tool" spam in build mode;
the trader faced backwards; the basket sensor missed belt-height hay; pieces placed mid-glide
off-grid; the BUILD button left the mouse free; two quick dumps hid the basket fill; the shop
window shrank when toggled quickly; loose hay could be paid twice after leave/rejoin (now
cleared with the plot, and only its owner is credited); the bale maker could lose straws or
loop forever after a take-back or a leave; a hacked client could dig straight to the needle
(only surface clumps, or ones already started, can be harvested now, and reach is measured
to the clump); infinite rotations in Place; two players loading a tool model at once got a
broken tool; the new needle wasn't saved straight away and the heap rebuilt 6 s late (now at
once); golden straw didn't auto-dump; stale Config comments.
Not done yet: session locking for saves (a very quick server hop could lose that session).

## Guided goals and coins a minute (2026-11-05)
- **Goals (`Config.Goals`, 25 of them, `server/Goals.luau`, client `Goals.luau`):** an ordered
  list that teaches the game: first hay, fill your tool, dump in the basket, a first sale, the
  Wooden Pitchfork, a ladder, 10 clumps, a Tin Pail, stairs, drop a bundle (G), a conveyor, a
  dynamo, a Clockwork Hen, the Iron Pitchfork, 25 clumps, a Farm Van, 10,000 sold, 20 power,
  50 clumps, 3 machines, the Steel Rake, a Small Silo, a Bale Maker, a bale, 100 clumps.
  Rewards 25 to 15,000 coins (55,400 in all, small next to the game's millions; `dev/pacing.py`
  doesn't count them). The server checks the current goal every `GoalCheckSeconds` (2), pays,
  and moves on; a returning player catches up on goals already met at once (paid, no fanfare).
  Saved as a position (`d.goal`): add new goals at the end. Two goals a line in Config to keep
  it under 300 lines. New saved counters: `stats.dumps`, `stats.drops`, `stats.bales_made`.
  The card sits top left, under Roblox's buttons; a soft green glow and a toast each time,
  confetti every fifth goal and the last.
- **Coins a minute:** under the coins counter, what you earned in the last
  `RateWindowSeconds` (60), counting only rises (spending and goal rewards don't count).
## Stamina, fitness and the metal detector (2026-11-05)
- **Stamina (`Config.Stamina`):** max 100, 1 per harvest click, refills 2.5 a second all the
  time (so clicking 3 a second drains only 0.5 a second: about 200 s of steady harvesting from
  full). At 0 you "catch your breath": a 1 s rest, then it refills to 15 and you carry on. The
  server owns it (`server/Stamina.luau`; attributes Stamina, StaminaMax, Winded); a slim bar
  under the crosshair shows only when it isn't full. Walking speed base 16 (Roblox's default).
- **Fitness (`Config.Fitness`, saved as `d.fitness`, shop tab "Fitness"):** Stronger Arms +50
  max stamina a level (5 levels, 300 coins x3 each level), Second Wind +0.25 refill a second (4
  levels, 500 x3: at level 2 a steady 3 clicks a second never runs out), Light Boots +1.5
  walking speed (4 levels, 600 x3; set on the Humanoid by the server on spawn and purchase).
- **Pacing:** `dev/pacing.py` caps the click rate by stamina (rested at the start of each load,
  since the walk to the trader refills it; no rest with Auto Sell) and buys Stronger Arms and
  Second Wind. Free player's needle: about 34 h (unchanged); Robux: about 12 h.
- **Metal detector (`Config.MetalDetector`, saved as `d.detector`):** 900 coins, bought once
  (Fitness tab). Hold V: the client asks `Remotes.Detect` about 4 times a second (the server
  answers at most every 0.2 s) and gets only a signal 0-5: 0 beyond 30 studs from your head to
  your needle's clump, then 1-5 in 6-stud bands. It beeps (the built-in short ping, quiet,
  pitch rising with the signal) every 1.2 / 0.9 / 0.65 / 0.45 / 0.28 s, lights 1-5 meter bars
  and pulses gently. The needle's position never leaves the server. Separate from the Needle
  Detector tool (tool 10), whose warmth on each click still works as before.

## v6: factory line, processing chain, goals, stamina (2026-11-05)
Owner's request: the depth of a factory-style needle game, with original systems only.
- **Config split** (300-line limit): `ConfigFactory.luau`, `ConfigGoals.luau` and
  `ConfigPlayer.luau` are merged into Config at load (lists append). Read them as `Config.X`.
- **Belts:** Belt Corner (300; turns hay sideways, rotate with R), Belt Splitter (2,500; pushes
  each new item left, then right), Belt Motors in the Logistics tab (`BeltSpeeds`: 10 / 14 /
  19 / 25 studs/s for 0 / 20K / 120K / 700K).
- **Feeders** (`Feeders`, Machines tab): Hay Arm (8 straws every 4 s, 6 power, 50K, max 8),
  Hay Thrower (30 every 4 s, 30 power, 900K, max 6, throws 22 studs). They take hay from the
  heap like machines (outside in, needle included) and drop bundles at their front, within
  `FeederReach` 30 of the heap. Tuned so a free player finds the needle in about 31 h (34 h
  without them); stronger feeders made it 21 h.
- **Hay Burner** (Power tab, 8K, max 6): 30 power only while it has hay; each straw burns
  `BurnerSecondsPerStraw` 0.25 s. Not counted as free power in pacing.
- **Processing:** Bale Wrapper (150K): bale in, wrapped bale out, worth x1.4. Pellet Press
  (400K): bundles in, 500-straw pellet sacks out, worth x1.7. The extra is paid as a bonus when
  they reach the basket; they haul like bales.
- **Delivery orders** (`Orders`, `OrderGrowth` 2): 8 orders in a cycle from 10 bundles (2K)
  to 60 pellet sacks (1.5M), each round x2. Shown on a card on the right.
- Code: `HayItems` (the items), `Processing` (machines' sensors), `LooseHay` (you and the hay),
  `Factory` (feeders, burners, belt speeds), `Orders`, `PiecesFactory`.

## Second review fixes (2026-11-05)
- Hay Arms and Throwers couldn't be placed after buying (missing from the build bar and the
  Inv_/Own_ attributes): fixed.
- Delivery orders now count straws, not items (dropping tiny bundles can't farm them), and
  pay a modest bonus of about 0.2-0.5 coins a straw; `OrderGrowth` 2 -> 1.5, applied to both
  the straws asked for and the reward. Was up to 50 coins a straw, doubling every round.
- Hay Burner fuel is one saved pool per player (`d.fuel`), so taking back a piece (which rebuilds
  every model) no longer wipes it; the HUD's power numbers update when burners light or go out.
- The Bale Wrapper no longer waits between taking a bale and making the wrapped one (leaving
  in between lost the straws).
- Stamina is spent only on a click that actually harvests. "You're full" is rate-limited like
  the other reasons (holding the button spammed it). Belt deliveries fill the basket without
  a toast each. Feeders restart within a second when power returns, and machine/feeder lamps
  light with power whether or not you have silo machines.
- Client: the guide line survives a respawn; a quick V tap-release-tap no longer doubles the
  detector's polling; clump milestones aren't skipped when machines take several at once;
  the left HUD column sits under the goal card on short screens; the order card hides in
  build mode; toasts sit under the top bar at every screen size; stale "sell at the merchant"
  wording.
- Not changed: the splitter's sideways push vs the belt's own motion needs checking in Studio.

## Robux items switched on (2026-11-06)
The owner created the passes and products (prices: Jetpack 175, Double Machines 249, Auto Sell
149, VIP 299; 2x Speed 49, 2x Coins 49, Lucky Charm 29, Straw Blast 99, Whistle x10 25,
Wheel Spin 25) and their IDs are in `Config.GamePasses` / `Config.Products`. A grant that
errors now returns NotProcessedYet so Roblox retries it instead of losing the purchase.

## Phones and tablets (2026-11-06)
The owner said the game wasn't mobile compatible. Every client file was checked for touch.
New tunables: `Config.Touch` (in `ConfigPlayer.luau`): `holdSeconds` 0.35, `dragPixels` 14,
`stickArea` {0.4, 1/3}, `minScale` 0.68, `padButton` {76, 50}, `padGap` 6, `padColumns` 3.
- **Harvesting by touch** (`client/TouchAim.luau`): a touch that stays within 14 px and lifts
  before 0.35 s swings once at the crosshair; held still longer it keeps harvesting (paced by
  the tool's cooldown, like holding the mouse). A touch that moves is looking around and never
  harvests. Touches on buttons, prompts, the jump button or the thumbstick area (bottom left)
  don't harvest, nor do taps while a menu is open or in build mode. The tool's own Activated
  is ignored on touch (it could fire on a camera drag). `Harvest.use` is the shared click/tap.
- **Action pad** (`client/TouchPad.luau`, `client/Controls.luau`): on touch screens a 3x3 grid
  of buttons sits on the right just above Roblox's jump button (measured from the TouchGui, or
  where Roblox puts it), clear of the thumbstick: DROP (G), HOME (T), TOOL (1, only when the
  fork isn't out), SHOP (Q), BUILD (B), MENU (achievements, finds & skins, whistle), and when
  owned DETECT (hold, V), FLY (hold; takes off from the ground too) and HOVER (H). In build mode
  the pad swaps to PLACE, TURN, TAKE BACK, NEXT, PREV (Z/C), DONE. Hidden while a menu is open.
  Shown when the device has touch and no keyboard, or a touch laptop was last touched.
  The keyboard shortcuts Q/T/G and the prompt handling moved from Main into Controls.
- **Fixed:** build mode's old touch buttons stayed on screen after leaving build mode, and
  overlapped the jetpack's; the jetpack's FLY/HOVER sat over the order card; the M "free the
  mouse" button and the key list don't apply to touch (hidden there); the left HUD column's
  buttons sat over the thumbstick (on touch they fold away: the pad and MENU have them; the
  stats stay); at the 0.55 UI scale phones got 8 px text and 22 px buttons (touch screens now
  never go below `minScale` 0.68); windows (shop 640x540) were taller than a phone screen (all
  windows now fit under the top bar, `Ui.fit`, and their bodies scroll); the shop's 9 tabs were
  37 px wide on a phone (touch: 104 px tabs in a sideways-scrolling row); the order card moves
  to the top right on touch; the build bar sits between the thumbstick and the pad on touch;
  the HUD stays inside the device safe area (ScreenInsets DeviceSafeInsets: notches); a tap to
  dismiss a banner doesn't also harvest; help texts say DETECT / FLY / TOOL / tap on touch.
- ProximityPrompts: nothing hides them or turns off ClickablePrompt, so on touch Roblox shows
  their tap button; taps on them are game-processed, so they never harvest.
- Needs checking in Studio's device emulator and on a real phone: the pad's position against
  the jump button (iPhone with notch, small Android, iPad), that a camera drag never harvests
  and a still hold does, the shop on a 390 px tall screen, and the jetpack's FLY take-off.

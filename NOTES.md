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
- Sounds and music, a global leaderboard, daily rewards, 3D models from the Toolbox.

# NOTES: choices and defaults

Every default below was chosen without asking. Change any of them in `src/shared/Config.luau`
(numbers), `src/shared/Piles.json` (haystacks and clues) or `src/shared/Cases.json` (stories).

## Version 1 (2026-11-05)
Your choices: an original "find the needle in the haystack" mystery that plays like a
simulator, with 5,000,000 straws; the theme was left to me.

- **Theme:** Hollow Creek Farm, an autumn farm at sunset (warm light, orange trees, lamps).
  It suits hay and a cosy mystery, and looks good built from simple shapes.
- **Haystacks:** 10, with 500,000 straws each, next to farm landmarks: three north (Windmill,
  Red Barn, Old Tractor), two east (Duck Pond, Apple Tree), two south (Old Well, Pumpkin
  Patch), three west (Chicken Coop, Scarecrow, Tool Shed). North is the way you face when you
  spawn; a signpost in the plaza names the four sides.
- **Finding the needle:** chance per search = straws in your handful / straws left in that
  haystack. That is the same as hiding the needle at a random straw, and the last handful
  always finds it. Bigger tools mean bigger handfuls and better odds.
- **Clues:** 2 to 4 per case. Each search has a 3% chance of giving you your next clue (about
  one every 33 searches). The clues rule haystacks out by side, water, buildings and animals;
  the last one names a trace only one place leaves (flour, duckweed, sawdust...).
- **Tools:** 8, from the Rusty Fork (100 straws a search, free) to the Needle Detector
  (60,000, 5M coins). Each costs 5 seconds to 15 minutes of searching with the one before
  (tested). Coins: 1 per 10 straws.
- **Rewards:** the finder gets 400 searches' worth of coins at their tool's power; everyone
  else who searched in that case gets 40. Next case after 12 seconds.
- **Rebirth:** costs 2.5M coins (then 5M, 7.5M...), resets coins and tool, +50% coins.
- **Anti-cheat:** the server checks you hold your tool within 26 studs of the haystack, and
  allows one search per 0.18 seconds, so auto-clickers gain nothing.
- **Saving:** coins, tool, rebirths, needles found and totals, every 2 minutes, on leaving
  and on shutdown. If loading fails, that visit isn't saved (it never overwrites good data).
- **Robux:** 2x Coins and Auto Search passes, a Clue Hint product (your next clue now; coins
  if you have every clue). All switched off until you create them and send me the IDs.
  No paid random rewards.
- **Tooling:** Roblox's build tools (Rojo, Lune, luau-lsp) couldn't be downloaded in the cloud
  sandbox, so `dev/build.py` builds the place file and `dev/luau.py` checks the code instead.
  Neither runs the game: the first real test is pressing Play in Studio.

## Not done yet (ideas for version 2)
- Sounds and music (pick them from the Studio Toolbox, or send me asset IDs).
- Bigger zones after rebirth (a barn of 50 million straws), pets that search with you, a
  global leaderboard, daily rewards, badges.
- Real 3D models from the Toolbox or a modeller in place of the simple shapes.

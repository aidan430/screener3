# NOTES: choices and defaults

Every default below was chosen without asking. Change any of them in `src/shared/Config.luau`
(numbers), `src/shared/Finds.json` (lucky finds and story) or `src/server/World.luau` (the map).

## Version 2 (2026-11-05): one big haystack, a 24-hour grind
Your brief: one big haystack; a slow process of about 24 hours to find the needle; straw sold to
a merchant; machines, better tools and tool perks bought with coins; power-ups and speed-ups
mainly with Robux; ten unique achievements; all ten open a secret level.

- **Your own haystack.** Everyone sees the same giant haystack, but each player's progress and
  needle are their own and saved, because a shared haystack couldn't add up to 24 hours across
  visits. 5,000,000 straws. The needle is never in the first 60%.
- **Pacing (tested in `dev/pacing.py`):** a free player who clicks 3 times a second, sells
  when the bag is full and always buys the best upgrade they can afford reaches the needle zone
  after about 17.6 hours and clears the haystack in 24.0. With every Robux item it takes 8-11
  hours. Early game is slow on purpose: the Rusty Fork takes 1 straw a search.
- **Merchant:** 1 coin a straw. The bag (400 straws at first, up to 160,000) must be carried to
  the stall east of the plaza. Merchant's Whistles (Robux) sell anywhere.
- **Tools:** 10, from 1 to 22 straws a search, 400 to 3.4M coins. **Perks** (per tool, reset
  on a new tool): Sharpened +15% straws a level, Swift -10% cooldown a level, Lucky +0.4%
  find chance a level; 5 levels each, prices scale with the tool.
- **Machines:** five kinds (0.15 to 7.5 straws a second each), up to 10/10/8/6/4 of each, each
  copy costs 1.3-1.5x more. They work only while you're in the game (VIP: an hour after too).
- **Lucky finds:** 0.6% a search; 12 items from the mystery (the tailor's thimble, Pip the
  magpie's feather...), worth 60 searches of coins, honey and the gold coin 2-3x.
- **Finding the needle:** a prize of 5,000 searches' worth of coins, +20% coins on everything
  forever, and a fresh haystack with a new needle (so the game goes on).
- **Robux:** passes Auto Sell, Double Machines, VIP (+25% coins, offline machines); products
  2x Speed, 2x Coins, Lucky Charm (an hour each), Straw Blast (100,000 straws at once),
  Merchant's Whistle x10. All switched off until the IDs are set. No paid random rewards.
- **Achievements (10):** First Straw, Bag Full, Merchant's Friend (100k sold), Collector (all
  tools), Industrialist (10 machines), Perfectionist (all perks maxed on one tool), Marathon
  (2 hours in one visit), Halfway There (2.5M searched), Lucky Duck (25 finds), Needle Finder.
  Optional Roblox badges via `Config.BadgeIds`.
- **The Golden Loft:** a platform in the clouds above the barn, reached from the loft hatch on
  the barn (the server teleports you, so it can't be reached by climbing). A golden haystack of
  250,000 straws paying 20x, with a golden needle of its own.
- **Anti-cheat:** the server checks position, tool and cooldown; bag room and haystack totals
  are server-side; purchases are validated server-side.

## Version 1 (2026-11-05), replaced
Ten haystacks with shared, round-based cases and clues. Kept in git history (commit 7d2617e).

## Not done yet (ideas for version 3)
- Sounds and music, a global leaderboard, daily rewards, pets that search with you.
- Real 3D models from the Toolbox in place of the simple shapes.

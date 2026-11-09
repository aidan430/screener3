-- Farmer Level: every lift of hay earns XP, so something fills on screen with every swing and a
-- level comes every few seconds at first (Config.luau merges this file in: read and tune it as
-- Config.Levels). Level L needs needBase + needStep x L XP. A lift earns xpPerLift x your tool's
-- number (a better tool levels faster), a cleared clump xpPerClump more. Each level is +1 Strength:
-- you carry carryPerLevel more (0.05%), up to carryMax (+25%, by level 501). Kept small on purpose:
-- any more and the needle comes hours sooner (dev/pacing.py). luckyChance: a Lucky Lift, x2 XP. Every bigEvery levels there's a bigger
-- cheer; every spinEvery levels a free wheel spin (a free spin, never sold).
local Config = {}

Config.Levels = { xpPerLift = 1, xpPerClump = 5, needBase = 10, needStep = 2, carryPerLevel = 0.0005, carryMax = 0.25, luckyChance = 0.06, bigEvery = 10, spinEvery = 50, maxLevel = 5000 }

-- Auto-fork: press AutoKey (or the AUTO button) and your tool keeps lifting whatever you aim at,
-- at its own speed. It still needs stamina and room on the fork, and stops when you're full.
Config.AutoKey = "R"

-- The Top Farmers board beside where you arrive: the highest Farmer Levels in every server
-- (an OrderedDataStore), refreshed every refreshSeconds. at = { x, z } from the farm's centre.
Config.LevelBoard = { at = { -18, 64 }, rows = 10, refreshSeconds = 120, store = "FarmerLevels_v1" }

return Config

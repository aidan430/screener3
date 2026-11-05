-- Stamina, fitness and the metal detector (Config.luau merges this file in: read and tune
-- them as Config.Stamina, Config.Fitness, Config.MetalDetector).
local Config = {}

-- Stamina: each harvest click spends perHarvest; it refills regenPerSecond all the time. Out of
-- breath (0), you rest regenDelay seconds, then until it's back to `recover`. Fitness upgrades
-- it (coins; level n costs price x growth^(n-1); stat: max, regen or walk = Humanoid.WalkSpeed).
Config.Stamina = { max = 100, perHarvest = 1, regenPerSecond = 2.5, regenDelay = 1, recover = 15, walkSpeed = 16 }
Config.Fitness = {
	{ id = "arms", name = "Stronger Arms", stat = "max", per_level = 50, levels = 5, price = 300, growth = 3, text = "+50 stamina per level" },
	{ id = "breath", name = "Second Wind", stat = "regen", per_level = 0.25, levels = 4, price = 500, growth = 3, text = "+0.25 stamina a second per level" },
	{ id = "boots", name = "Light Boots", stat = "walk", per_level = 1.5, levels = 4, price = 600, growth = 3, text = "+1.5 walking speed per level" },
}
-- Metal detector (bought once): hold `key` to sweep. Within `range` studs of your needle's clump
-- it beeps, faster and higher the closer your head is (signal 1-5; beep = seconds per signal).
Config.MetalDetector = { price = 900, range = 30, levels = 5, pollSeconds = 0.25, key = "V", beep = { 1.2, 0.9, 0.65, 0.45, 0.28 } }

return Config

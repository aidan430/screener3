-- The Robux corner: one holographic pad per Robux item, near where you arrive (Config.luau
-- merges this file in: read and tune them as Config.RobuxPads and the other Config.RobuxPad*).
-- Stepping on a pad only offers its item; closing Roblox's prompt costs nothing.
local Config = {}

-- One row per pad. kind "pass" = Config.GamePasses[key], "product" = Config.Products[key]; a pad
-- whose ID is 0 isn't built. at = { x, z } studs from Config.FarmEntrance (the arrival point;
-- +z is behind you as you arrive facing the haystack), so the pads move when the entrance does.
-- Two arcs of 5, 32 studs round the arrival point, off the 30-stud road (|x| > 15).
Config.RobuxPads = {
	{ kind = "pass", key = "AutoSell", at = { -18.8, 25.9 } },
	{ kind = "pass", key = "DoubleMachines", at = { -25.2, 19.7 } },
	{ kind = "pass", key = "VIP", at = { -29.7, 12 } },
	{ kind = "pass", key = "Jetpack", at = { -31.8, 3.3 } },
	{ kind = "product", key = "MerchantWhistle", at = { -31.5, -5.6 } },
	{ kind = "product", key = "SpeedBoost", at = { 18.8, 25.9 } },
	{ kind = "product", key = "CoinBoost", at = { 25.2, 19.7 } },
	{ kind = "product", key = "LuckyCharm", at = { 29.7, 12 } },
	{ kind = "product", key = "StrawBlast", at = { 31.8, 3.3 } },
	{ kind = "product", key = "WheelSpin", at = { 31.5, -5.6 } }, -- opens the wheel's odds, never a prompt
}
Config.RobuxPadFacing = { 0, 0 } -- every pad faces this point ({ x, z } from Config.FarmEntrance)
Config.RobuxPadSize = 7 -- studs across a pad
Config.RobuxPadPanelHeight = 7.5 -- studs from the ground to the middle of the floating panel
Config.RobuxPadHueSeconds = 24 -- the ring's colour takes this long to drift once round the rainbow
Config.RobuxPadBobSeconds = 3.5 -- one slow rise and fall of the panel
Config.RobuxPadBob = 0.35 -- studs the panel rises and falls
Config.RobuxPadSpinSeconds = 16 -- one slow turn of the icon's glow ring
Config.RobuxPadCooldown = 4 -- seconds between two purchase prompts from any pads
Config.RobuxPadLeave = 2 -- studs past a pad's edge before it can offer again

return Config

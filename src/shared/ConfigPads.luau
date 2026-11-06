-- The Robux corner: one holographic pad per Robux item, in the lobby (Config.luau
-- merges this file in: read and tune them as Config.RobuxPads and the other Config.RobuxPad*).
-- Stepping on a pad only offers its item; closing Roblox's prompt costs nothing.
local Config = {}

-- One row per pad. kind "pass" = Config.GamePasses[key], "product" = Config.Products[key]; a pad
-- whose ID is 0 isn't built. at = { x, z } studs from the lobby's centre (Config.Lobby; -z is
-- north, towards the portal arches), so the pads move with the lobby.
-- One arc of 10 along the lobby's east and south-east rim, 56 studs out, 10 degrees apart,
-- clear of the arches (north) and of the arrival path (south).
Config.RobuxPads = {
	{ kind = "pass", key = "AutoSell", at = { 55.7, -5.9 } },
	{ kind = "pass", key = "DoubleMachines", at = { 55.9, 3.9 } },
	{ kind = "pass", key = "VIP", at = { 54.3, 13.5 } },
	{ kind = "pass", key = "Jetpack", at = { 51.2, 22.8 } },
	{ kind = "product", key = "MerchantWhistle", at = { 46.4, 31.3 } },
	{ kind = "product", key = "SpeedBoost", at = { 40.3, 38.9 } },
	{ kind = "product", key = "CoinBoost", at = { 32.9, 45.3 } },
	{ kind = "product", key = "LuckyCharm", at = { 24.5, 50.3 } },
	{ kind = "product", key = "StrawBlast", at = { 15.4, 53.8 } },
	{ kind = "product", key = "WheelSpin", at = { 5.9, 55.7 } }, -- opens the wheel's odds, never a prompt
}
Config.RobuxPadFacing = { 0, 0 } -- every pad faces this point ({ x, z } from the lobby's centre)
Config.RobuxPadSize = 7 -- studs across a pad
Config.RobuxPadPanelHeight = 7.5 -- studs from the ground to the middle of the floating panel
Config.RobuxPadHueSeconds = 24 -- the ring's colour takes this long to drift once round the rainbow
Config.RobuxPadBobSeconds = 3.5 -- one slow rise and fall of the panel
Config.RobuxPadBob = 0.35 -- studs the panel rises and falls
Config.RobuxPadSpinSeconds = 16 -- one slow turn of the icon's glow ring
Config.RobuxPadCooldown = 4 -- seconds between two purchase prompts from any pads
Config.RobuxPadLeave = 2 -- studs past a pad's edge before it can offer again

return Config

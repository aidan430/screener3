-- Movement and combat moves beyond the basics in Config.luau (which merges this in: Config.Stance).
local Moves = {}

-- Crouching and sliding (client/StanceFx moves your own character; server/Stance keeps the
-- "Stance" attribute everyone else reads). The crouch button: Left Ctrl or V, L3 on a controller,
-- the CROUCH button on a phone. Press it while running on the ground and you slide.
--   crouchSpeed: your walk speed times this while crouched.
--   drop: how many studs the body lowers (crouch, slide; r6 for old blocky rigs); `ease` seconds
--     to go down or up; minHip: an R15 hip never goes lower than this.
--   slide: lasts `seconds`, `cooldown` between slides. It starts at your walk speed + `boost`
--     (never over `top`, kept under Config.AntiCheat.maxSpeed) and eases down to `endAt` x your walk
--     speed. You must be moving at `needSpeed` x your walk speed to start one. `fov` widens the view.
--   server: at most `rate` stance messages a second; a slide the client never ended is over after
--     `slideMax` seconds.
--   legs: how the hip, knee and ankle fold for the drop (multiples of the fold angle); waist: the
--     lean in degrees, crouched and sliding. Others see this pose.
Moves.Stance = {
	crouchSpeed = 0.5,
	drop = { crouch = 1.2, slide = 1.6, r6 = 1, minHip = 0.4 }, ease = 0.15, headroom = 1.7,
	slide = { seconds = 0.6, cooldown = 1.5, boost = 14, top = 44, endAt = 0.875, needSpeed = 0.85, fov = 5 },
	server = { rate = 8, slideMax = 0.85 },
	legs = { 1, -2, 1 }, waist = { crouch = -12, slide = 20 },
}

return Moves

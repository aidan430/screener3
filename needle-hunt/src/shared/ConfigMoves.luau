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

-- Poking (server/CombatPoke). After a poke that lands, the next is ready in `first` seconds; land
-- that one within `window` of the first and it's a ONE-TWO, then `second` before the next. A poke
-- that a Thimble blocks costs `blocked`. (A plain miss is Config.Combat.cooldown.)
Moves.Combo = { first = 0.5, second = 0.9, window = 1.2, blocked = 1.1 }

-- The Power Poke: keep holding the poke button. Charging starts `hold` seconds into the hold (and
-- never before your poke is ready), is full `charge` later and lets itself go `auto` after that.
-- Letting go early cancels it. It takes `damage` hearts, pops a Thimble, and then `cooldown`.
-- You walk at `slow` x your speed while charging. Losing a heart ends a charge.
Moves.Power = { hold = 0.25, charge = 0.7, auto = 1.5, cooldown = 1, damage = 2, slow = 0.7 }

-- The Thimble (hold R, L2 or GUARD): blocks pokes and throws from any side for as long as it's
-- held, `max` seconds at most; then `cooldown` before the next (`popped` if a Power Poke broke
-- it). You walk at `slow` x your speed and can't poke, charge or throw behind it.
Moves.Guard = { max = 1.5, cooldown = 1.2, popped = 2.5, slow = 0.5 }

-- The lunge: a poke at someone further than `from` studs (and within Config.Combat.reach + range)
-- carries you towards them at `speed` for up to `seconds`. power*: the Power Poke's.
Moves.Lunge = { range = 3, powerRange = 5, from = 4.5, speed = 40, seconds = 0.1, powerSpeed = 46, powerSeconds = 0.14 }

-- How the server checks a poke: the target may be up to reach + the lunge + `pad` away on the flat
-- and `up` studs above or below, measured against where they were at any moment in the last
-- `window` seconds (twice the attacker's ping + the first number, at most the second), so a hit
-- that looked right on your screen counts. `forgive`: a poke this early still counts.
-- `history`: seconds of positions kept (server/Rewind).
Moves.HitCheck = { pad = 1.5, up = 6, window = { 0.1, 0.35 }, forgive = 0.1, history = 1 }

-- Knockback on the player who was hit: { speed at first, speed at the end, seconds }.
Moves.Knock = { poke = { 22, 6, 0.14 }, combo = { 30, 8, 0.16 }, power = { 34, 8, 0.18 }, throw = { 26, 6, 0.14 }, blocked = { 18, 4, 0.12 } }

-- Most messages a second the server takes from one player, by remote.
Moves.Rate = { Poke = 6, Charge = 6, Guard = 6 }

-- Catching your thrown needle: press Throw again as it comes back, from `early` seconds before
-- it's in your hand to `late` after. One try a throw. A catch makes your next throw ready `gain`
-- seconds sooner.
Moves.Catch = { early = 0.25, late = 0.15, gain = 1.5 }

return Moves

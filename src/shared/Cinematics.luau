-- The story's cinematic camera moves (client/Cinematic plays them; shared/Story names one per beat
-- with `cinematic = "..."`). Each is a list of shots; a shot glides the camera from `from` to `to`
-- while it looks from `look` to `lookTo`, over `time` seconds. Positions are studs from an anchor:
--   heap   = the base centre of your own haystack (it stands 80 studs tall, about 90 across)
--   player = you: x to your right, y up, z behind you
-- The last shot holds until the scene's talking ends; then the camera glides back to you.
-- Every move is slow and smooth: no shakes, no flashes.
local Cinematics = {}

Cinematics.opening = { anchor = "heap", shots = {
	{ from = { -150, 120, 170 }, to = { -95, 70, 120 }, look = { 0, 50, 0 }, lookTo = { 0, 45, 0 }, time = 6 },
	{ from = { -95, 70, 120 }, to = { 40, 24, 95 }, look = { 0, 45, 0 }, lookTo = { 0, 30, 0 }, time = 6 },
	{ from = { 40, 24, 95 }, to = { 22, 9, 92 }, look = { 0, 30, 0 }, lookTo = { 0, 22, 0 }, time = 5 },
} }

Cinematics.upAndIn = { anchor = "heap", shots = { -- the red thread runs up and in: follow it
	{ from = { 0, 6, 70 }, to = { 0, 40, 56 }, look = { 0, 6, 0 }, lookTo = { 0, 50, 0 }, time = 5 },
	{ from = { 0, 40, 56 }, to = { 0, 108, 78 }, look = { 0, 50, 0 }, lookTo = { 0, 70, 0 }, time = 5 },
} }

Cinematics.climb = { anchor = "heap", shots = { -- stairs: how high it goes
	{ from = { 30, 4, 70 }, to = { 30, 60, 70 }, look = { 0, 10, 0 }, lookTo = { 0, 70, 0 }, time = 6 },
	{ from = { 30, 60, 70 }, to = { 20, 110, 60 }, look = { 0, 70, 0 }, lookTo = { 0, 78, 0 }, time = 4 },
} }

Cinematics.sky = { anchor = "player", shots = { -- look up: haystacks in the sky
	{ from = { 0, 3, 8 }, to = { 0, 4, 10 }, look = { 0, 3, -20 }, lookTo = { 0, 120, -60 }, time = 6 },
} }

Cinematics.pullback = { anchor = "heap", shots = { -- halfway: see how much has gone
	{ from = { 10, 20, 60 }, to = { 60, 90, 160 }, look = { 0, 25, 0 }, lookTo = { 0, 20, 0 }, time = 8 },
} }

Cinematics.needle = { anchor = "heap", shots = { -- found it: a slow circle round the heap
	{ from = { 0, 60, 140 }, to = { 140, 60, 0 }, look = { 0, 35, 0 }, lookTo = { 0, 35, 0 }, time = 5, around = true },
	{ from = { 140, 60, 0 }, to = { 0, 60, -140 }, look = { 0, 35, 0 }, lookTo = { 0, 35, 0 }, time = 5, around = true },
	{ from = { 0, 60, -140 }, to = { -140, 60, 0 }, look = { 0, 35, 0 }, lookTo = { 0, 35, 0 }, time = 5, around = true },
	{ from = { -140, 60, 0 }, to = { 0, 40, 120 }, look = { 0, 35, 0 }, lookTo = { 0, 30, 0 }, time = 5, around = true },
} }

Cinematics.arrive = { anchor = "player", shots = { -- a new world: a wide look round
	{ from = { -60, 40, 80 }, to = { 30, 18, 40 }, look = { 0, 10, -40 }, lookTo = { 0, 6, -30 }, time = 7 },
	{ from = { 30, 18, 40 }, to = { 4, 5, 14 }, look = { 0, 6, -30 }, lookTo = { 0, 4, -20 }, time = 4 },
} }

return Cinematics

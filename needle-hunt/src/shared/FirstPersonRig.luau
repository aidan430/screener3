-- The rest of the first-person view (client/ViewModel): everything the Needle Hand Rig tool
-- doesn't know. The tool writes shared/FirstPerson.luau (the arms' and the needle's hold pose, the
-- arm's size, the bob and sway amounts, and the inspect, jab and throw); this file is hand-edited
-- data: the wrist, the hand's boxes, the grip rule, the extra motion and the extra animations.
-- Check any change on the preview sheets: node dev/preview/shoot_viewmodel.js (see its header).
--
-- Studs and degrees. Camera space: +X right, +Y up, -Z ahead. A "row" is six numbers
-- { x, y, z, rx, ry, rz } added to a pose: x y z to its pos, rx ry rz to its rot (CFrame.Angles
-- order: rx turns about the parent's X, rz about the part's own Z). A layer or key may leave a
-- part's row out. With the hold as it is now:
--   right, left: a forearm about its centre, in camera space. -z reaches ahead, +rx tips the
--     hand and the needle's point up, +rz swings them to the left.
--   needle: the needle in the hand, about its grip point. -rx tips its point up (to the back of
--     the hand), ry spins it about its own length, +rz swings its point to the thumb side.
--   wrist: the right hand about the wrist (only here, not in FirstPerson's animations).
--     +rx bends it down, ry rolls it about the forearm, +rz swings it to the thumb side.
-- The hand's own axes (the right hand; the left is its mirror image): -Y to the fingertips,
-- +X the thumb side, +Z the back of the hand.
return {
	-- The framing is made at refFov. At another field of view the whole view slides along the
	-- camera's axis by pivot * (1 - tan(refFov / 2) / tan(fov / 2)), which looks exactly like
	-- scaling it by tan(fov / 2) about a point `pivot` studs ahead: keep pivot near the grip's depth.
	-- firstPerson: the view shows when the camera is within this many studs of your head.
	-- scale: the whole view is drawn this much smaller and that much nearer the camera. It looks
	-- the same on screen but stays out of walls: every other number here is at full size.
	view = { refFov = 70, pivot = 1.3, firstPerson = 1.5, scale = 0.4 },
	-- skin: the colour when your character has none. sleeveWidth: the sleeve is this much wider
	-- than the arm (FirstPerson.arm.size).
	look = { skin = { 234, 184, 146 }, skinMaterial = "SmoothPlastic", sleeveMaterial = "Fabric", sleeveWidth = 1.08 },
	-- The hand hangs from the wrist, the wrist from the forearm's hand end. FirstPerson.pose.needle
	-- is in the hand's frame, so the needle follows the wrist.
	wrist = { pos = { 0, 0, 0 }, rot = { 0, 0, -40 } },
	-- Boxes that stay on the forearm, from its hand end (+Y runs up the arm).
	--   colour: "skin", "sleeve" (FirstPerson.arm.sleeveColour) or { r, g, b }; shade multiplies it
	--   (under 1 darker, over 1 lighter); shape = "Ball" or "Cylinder" (along X) if not a block.
	cuff = {
		{ name = "Cuff", colour = "sleeve", shade = 1.15, size = { 0.37, 0.11, 0.31 }, pos = { 0, 0.15, 0 }, rot = { 0, 0, 0 } },
	},
	-- The hand's boxes, from the wrist: pos is a box's centre, its long side is Y. `open` is the
	-- same box with the hand open (the needle thrown): boxes ease between the two.
	hand = {
		{ name = "Palm", colour = "skin", size = { 0.4, 0.37, 0.16 }, pos = { 0, -0.175, 0 }, rot = { 0, 0, 0 } },
		{ name = "Index1", colour = "skin", shade = 1, size = { 0.094, 0.22, 0.115 }, pos = { 0.148, -0.41, -0.004 }, rot = { 82, 0, 0 }, open = { pos = { 0.148, -0.498, 0.067 }, rot = { 20, 0, 0 } } },
		{ name = "Index2", colour = "skin", shade = 0.95, size = { 0.094, 0.2, 0.105 }, pos = { 0.148, -0.323, -0.066 }, rot = { 190, 0, 0 }, open = { pos = { 0.148, -0.644, -0.031 }, rot = { 45, 0, 0 } } },
		{ name = "Middle1", colour = "skin", shade = 0.95, size = { 0.094, 0.23, 0.115 }, pos = { 0.049, -0.411, -0.009 }, rot = { 82, 0, 0 }, open = { pos = { 0.049, -0.503, 0.066 }, rot = { 20, 0, 0 } } },
		{ name = "Middle2", colour = "skin", shade = 0.9, size = { 0.094, 0.21, 0.105 }, pos = { 0.049, -0.319, -0.075 }, rot = { 190, 0, 0 }, open = { pos = { 0.049, -0.657, -0.038 }, rot = { 45, 0, 0 } } },
		{ name = "Ring1", colour = "skin", shade = 1, size = { 0.094, 0.22, 0.115 }, pos = { -0.049, -0.41, -0.004 }, rot = { 82, 0, 0 }, open = { pos = { -0.049, -0.498, 0.067 }, rot = { 20, 0, 0 } } },
		{ name = "Ring2", colour = "skin", shade = 0.95, size = { 0.094, 0.2, 0.105 }, pos = { -0.049, -0.323, -0.066 }, rot = { 190, 0, 0 }, open = { pos = { -0.049, -0.644, -0.031 }, rot = { 45, 0, 0 } } },
		{ name = "Pinky1", colour = "skin", shade = 0.95, size = { 0.094, 0.2, 0.115 }, pos = { -0.148, -0.409, 0.006 }, rot = { 82, 0, 0 }, open = { pos = { -0.148, -0.489, 0.071 }, rot = { 20, 0, 0 } } },
		{ name = "Pinky2", colour = "skin", shade = 0.9, size = { 0.094, 0.18, 0.105 }, pos = { -0.148, -0.33, -0.048 }, rot = { 190, 0, 0 }, open = { pos = { -0.148, -0.618, -0.017 }, rot = { 45, 0, 0 } } },
		{ name = "Thumb1", colour = "skin", shade = 0.97, size = { 0.12, 0.2, 0.12 }, pos = { 0.21, -0.3, -0.03 }, rot = { 0, 0, -40 }, open = { pos = { 0.27, -0.12, -0.03 }, rot = { 0, 0, 35 } } },
		{ name = "Thumb2", colour = "skin", shade = 0.92, size = { 0.105, 0.17, 0.105 }, pos = { 0.33, -0.4, -0.03 }, rot = { 0, 0, -30 }, open = { pos = { 0.375, -0.29, -0.03 }, rot = { 0, 0, 30 } } },
	},
	-- The left hand holds nothing: how open it is (0 a fist, 1 open). Its hold (FirstPerson.pose.left)
	-- is the right's mirror image 1.3 studs lower, out of view: lift it with `left` rows.
	left = { open = 0.7 },
	-- The grip rule, for every needle whatever its shape: the point `back` studs along from the
	-- needle's back end sits at FirstPerson.pose.needle in the hand, and the needle is scaled so
	-- its whole length is between minLength and maxLength.
	grip = { back = 0.45, minLength = 1.7, maxLength = 2.1 },
	-- A throw: the needle leaves the hand `release` seconds into FirstPerson's throw. The hand is
	-- empty until the server brings it back, or `wait` seconds on if the server never took the throw.
	throw = { release = 0.24, wait = 0.6 },
	-- Motion: each layer's rows times its weight, added to the hold and whatever is playing.
	motion = {
		-- weight sin(time * speed): -1 to 1
		breathe = { speed = 1.5, right = { 0, 0.014, 0.004, 0.6, 0, 0 }, needle = { 0, 0, 0, 0.8, 0, 0 } },
		-- the walk, per stud of FirstPerson.motion.bob: step swings side to side (weight
		-- sin(stride)), dip is each footfall (weight |cos(stride)|); eased in and out at `rate` a second.
		-- You count as walking above `least` of full speed.
		walk = { rate = 9, least = 0.1, step = { right = { 0.6, 0, 0, 0, 0, 30 }, left = { 0.6, 0, 0, 0, 0, 0 } }, dip = { right = { 0, -1, 0, -25, 0, 0 }, left = { 0, -1, 0, 0, 0, 0 } } },
		-- turning: the view lags. sway (studs) = turn speed (radians a second) * FirstPerson.motion.sway
		-- * gain, at most `max`, eased at `rate`; yaw rows per stud of sideways sway (turning left
		-- is +), pitch rows per stud of up-and-down sway (looking up is -). A negative gain leads.
		turn = { gain = 0.3, max = 0.12, rate = 10, yaw = { right = { 1, 0, 0, 0, 0, -30 }, left = { 1, 0, 0, 0, 0, 0 } }, pitch = { right = { 0, 1, 0, 30, 0, 0 }, left = { 0, 1, 0, 0, 0, 0 } } },
		-- landing: a dip that bottoms out `time` seconds after touching down and eases away; full
		-- strength from a fall of `speed` studs a second, never less than `least`
		land = { time = 0.09, speed = 45, least = 0.3, right = { 0, -0.16, 0.03, -7, 0, 0 }, left = { 0, -0.16, 0, 0, 0, 0 } },
		-- in the air (weight eased to 1 at `rate`)
		air = { rate = 7, right = { 0, 0.05, 0, 3, 0, 0 }, left = { 0, 0.05, 0, 0, 0, 0 } },
		-- the needle is away (weight eased to 1 at `rate`; the hand's boxes open by the same weight)
		away = { rate = 14, right = { 0.05, -0.1, 0.06, -6, 0, 0 }, wrist = { 0, 0, 0, 8, 0, 0 } },
		-- charging a Power Poke: the hand draws back. Behind a Thimble: the hand comes in and the
		-- needle stands up across the view (weights eased to 1 at `rate`)
		charge = { rate = 12, right = { 0.16, 0.06, 0.42, 0, 0, 0 } },
		guard = { rate = 14, right = { -0.4, 0.22, 0.15, 0, 0, 0 }, wrist = { 0, 0, 0, 0, 0, 55 } },
		-- a wall: one ray from the camera to where the needle's point would be. Weight 0 when the
		-- wall is `margin` beyond the point, 1 when it is `near` studs from the camera; in at
		-- rateIn a second, out at rateOut. The rows pull the hand in and stand the needle up.
		wall = { margin = 0.4, near = 0.5, rateIn = 28, rateOut = 9, right = { 0.15, -0.3, 0.6, 0, 0, 0 }, wrist = { 0, 0, 0, 0, 0, 70 } },
	},
	-- Animations, like FirstPerson.anims (keys may also carry a wrist row). ViewModel plays
	-- equip when the view comes up and catch when a thrown needle is back in the hand.
	anims = {
		equip = { length = 0.45, keys = {
			{ t = 0, right = { 0.2, -0.6, 0.2, -22, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
			{ t = 0.3, right = { -0.02, 0.04, -0.03, 3, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
			{ t = 0.45, right = { 0, 0, 0, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
		} },
		catch = { length = 0.4, keys = {
			{ t = 0, right = { -0.18, 0.2, -0.3, 8, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
			{ t = 0.12, right = { -0.05, 0.03, 0.08, -4, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
			{ t = 0.4, right = { 0, 0, 0, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
		} },
	},
}

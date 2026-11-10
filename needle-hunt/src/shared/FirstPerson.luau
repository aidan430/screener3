-- The first-person view of your needle (client/ViewModel): the arms and the needle drawn in
-- front of the camera. Made in the Needle Hand Rig artifact; paste a new rig over this file.
-- pos in studs, rot in degrees (CFrame.Angles order). right/left: each arm from the camera;
-- needle: from the right hand. Animation keys are offsets from the hold pose:
-- { t, right = { x, y, z, rx, ry, rz }, left = {...}, needle = {...} }, eased between keys.
return {
	pose = {
		right = { pos = { 0.85, -0.82, -0.9 }, rot = { 138, 0, -30 } },
		left = { pos = { -0.85, -1.44, -1.17 }, rot = { 103, 0, 30 } },
		needle = { pos = { 0.04, -0.3, 0 }, rot = { 0, 0, -72 } },
	},
	arm = { size = { 0.3, 1.6, 0.3 }, sleeve = 0.5, sleeveColour = { 70, 110, 170 } },
	needleLook = { scale = 0.45, fat = 1.6 },
	motion = { bob = 0.05, bobSpeed = 8, sway = 0.08 },
	anims = {
		inspect = { length = 6, keys = {
			{ t = 0, right = { 0, 0, 0, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
			{ t = 0.75, right = { 0, -0.1, 0, 10, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0.16, -0.78, -0.55, 393, -168, 140 } },
			{ t = 2.91, right = { 0, 0.12, 0, -10, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0.47, -0.16, 0.39, 0, 365, 383 } },
			{ t = 3.3, right = { 0, 0.15, 0, -12, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0.4, 0, 0, 0, 360 } },
			{ t = 3.6, right = { 0, -0.08, 0, 8, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 360 } },
			{ t = 6, right = { 0, 0, 0, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 360 } },
		} },
		jab = { length = 0.3, keys = {
			{ t = 0, right = { 0, 0, 0, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
			{ t = 0.08, right = { -0.1, 0.12, -0.6, -8, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
			{ t = 0.3, right = { 0, 0, 0, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
		} },
		throw = { length = 0.4, keys = {
			{ t = 0, right = { 0, 0, 0, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
			{ t = 0.131, right = { 0.1, 0.25, 0.1, 25, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
			{ t = 0.218, right = { -0.1, 0.05, -0.4, -20, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
			{ t = 0.4, right = { 0, 0, 0, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
		} },
	},
}

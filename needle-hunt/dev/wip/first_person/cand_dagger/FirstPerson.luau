-- The first-person view of your needle (client/ViewModel): the arms and the needle drawn in
-- front of the camera. Made in the Needle Hand Rig artifact; paste a new rig over this file.
-- pos in studs, rot in degrees (CFrame.Angles order). right/left: each arm from the camera;
-- needle: from the right hand. Animation keys are offsets from the hold pose:
-- { t, right = { x, y, z, rx, ry, rz }, left = {...}, needle = {...} }, eased between keys.
return {
	pose = {
		right = { pos = { 1.224, -0.74, -0.369 }, rot = { -64.9, -0.5, -152.4 } },
		left = { pos = { -1.224, -2.04, -0.369 }, rot = { -64.9, 0.5, 152.4 } },
		needle = { pos = { 0.215, -0.33, 0.02 }, rot = { 0, 30, -87 } },
	},
	arm = { size = { 0.3, 1.5, 0.25 }, sleeve = 0.93, sleeveColour = { 70, 110, 170 } },
	needleLook = { scale = 0.45, fat = 1.3 },
	motion = { bob = 0.045, bobSpeed = 9, sway = 0.08 },
	anims = {
		inspect = { length = 6, keys = {
			{ t = 0, right = { 0, 0, 0, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
			{ t = 0.7, right = { -0.2, 0.16, -0.1, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, -55, 0, 0 } },
			{ t = 2.2, right = { -0.24, 0.2, -0.06, 4, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, -45, 180, 0 } },
			{ t = 3.4, right = { -0.2, 0.18, -0.1, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, -60, 360, 0 } },
			{ t = 4, right = { -0.22, 0.2, -0.1, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, -50, 360, -20 } },
			{ t = 4.6, right = { -0.2, 0.17, -0.1, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, -55, 360, 10 } },
			{ t = 5.2, right = { -0.2, 0.16, -0.1, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, -55, 360, 0 } },
			{ t = 6, right = { 0, 0, 0, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 360, 0 } },
		} },
		jab = { length = 0.34, keys = {
			{ t = 0, right = { 0, 0, 0, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
			{ t = 0.05, right = { 0.04, -0.02, 0.14, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
			{ t = 0.12, right = { -0.3, 0.2, -0.72, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
			{ t = 0.18, right = { -0.26, 0.17, -0.62, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
			{ t = 0.34, right = { 0, 0, 0, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
		} },
		throw = { length = 0.5, keys = {
			{ t = 0, right = { 0, 0, 0, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
			{ t = 0.14, right = { 0.12, 0.28, 0.42, 28, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
			{ t = 0.24, right = { -0.16, 0.16, -0.55, -14, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
			{ t = 0.34, right = { -0.2, -0.02, -0.6, -26, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
			{ t = 0.5, right = { 0, 0, 0, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
		} },
	},
}

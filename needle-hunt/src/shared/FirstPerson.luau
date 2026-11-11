-- The first-person view of your needle (client/ViewModel): the arms and the needle drawn in
-- front of the camera. Made in the Needle Hand Rig artifact; paste a new rig over this file.
-- pos in studs, rot in degrees (CFrame.Angles order). right/left: each arm from the camera;
-- needle: from the right hand. Animation keys are offsets from the hold pose:
-- { t, right = { x, y, z, rx, ry, rz }, left = {...}, needle = {...} }, eased between keys.
return {
	pose = {
		right = { pos = { 1.382, -0.385, -0.759 }, rot = { -148, 62, -122.8 } },
		left = { pos = { -1.382, -1.685, -0.759 }, rot = { -148, -62, 122.8 } },
		needle = { pos = { 0.1, -0.365, -0.045 }, rot = { 0, 0, -30 } },
	},
	arm = { size = { 0.3, 1.5, 0.25 }, sleeve = 0.93, sleeveColour = { 70, 110, 170 } },
	needleLook = { scale = 0.45, fat = 1.3 },
	motion = { bob = 0.045, bobSpeed = 9, sway = 0.08 },
	anims = {
		inspect = { length = 6, keys = {
			{ t = 0, right = { 0, 0, 0, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
			{ t = 0.7, right = { -0.35, 0.05, 0.25, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 8 } },
			{ t = 2.2, right = { -0.4, 0.08, 0.3, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, -10 } },
			{ t = 3.4, right = { -0.35, 0.06, 0.25, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 10 } },
			{ t = 4, right = { -0.38, 0.08, 0.27, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, -6 } },
			{ t = 4.6, right = { -0.35, 0.05, 0.25, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 6 } },
			{ t = 5.2, right = { -0.35, 0.05, 0.25, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
			{ t = 6, right = { 0, 0, 0, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
		} },
		jab = { length = 0.34, keys = {
			{ t = 0, right = { 0, 0, 0, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
			{ t = 0.05, right = { 0.07, -0.04, 0.16, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
			{ t = 0.12, right = { -0.4, 0.23, -0.74, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
			{ t = 0.18, right = { -0.35, 0.2, -0.64, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
			{ t = 0.34, right = { 0, 0, 0, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
		} },
		throw = { length = 0.5, keys = {
			{ t = 0, right = { 0, 0, 0, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
			{ t = 0.14, right = { 0.18, 0.2, 0.5, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
			{ t = 0.24, right = { -0.3, 0.2, -0.6, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
			{ t = 0.34, right = { -0.38, 0.1, -0.7, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
			{ t = 0.5, right = { 0, 0, 0, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
		} },
	},
}

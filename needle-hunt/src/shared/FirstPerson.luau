-- The first-person view of your needle (client/ViewModel): the arms and the needle drawn in
-- front of the camera. Made in the Needle Hand Rig artifact; paste a new rig over this file.
-- pos in studs, rot in degrees (CFrame.Angles order). right/left: each arm from the camera;
-- needle: from the right hand. Animation keys are offsets from the hold pose:
-- { t, right = { x, y, z, rx, ry, rz }, left = {...}, needle = {...} }, eased between keys.
return {
	pose = {
		right = { pos = { 0.85, -0.82, -1 }, rot = { 119, 0, -30 } },
		left = { pos = { -0.85, -2.4, -1 }, rot = { 119, 0, 30 } },
		needle = { pos = { 0.04, -0.3, 0 }, rot = { 0, 0, -72 } },
	},
	arm = { size = { 0.3, 1.6, 0.3 }, sleeve = 0.5, sleeveColour = { 70, 110, 170 } },
	needleLook = { scale = 0.45, fat = 1.6 },
	motion = { bob = 0.05, bobSpeed = 8, sway = 0.08 },
	anims = {
		inspect = { length = 2.6, keys = {
			{ t = 0, right = { 0, 0, 0, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
			{ t = 0.45, right = { -0.3, 0.3, 0, -15, 0, 30 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
			{ t = 0.9, right = { -0.3, 0.3, 0, -15, 0, 30 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 120, 0, 0 } },
			{ t = 1.35, right = { -0.3, 0.3, 0, -15, 0, 30 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 240, 0, 0 } },
			{ t = 1.8, right = { -0.25, 0.28, 0, -10, 20, 25 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 360, 0, 0 } },
			{ t = 2.6, right = { 0, 0, 0, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 360, 0, 0 } },
		} },
		jab = { length = 0.3, keys = {
			{ t = 0, right = { 0, 0, 0, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
			{ t = 0.08, right = { -0.1, 0.12, -0.6, -8, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
			{ t = 0.3, right = { 0, 0, 0, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
		} },
		throw = { length = 0.55, keys = {
			{ t = 0, right = { 0, 0, 0, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
			{ t = 0.18, right = { 0.1, 0.25, 0.1, 25, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
			{ t = 0.3, right = { -0.1, 0.05, -0.4, -20, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
			{ t = 0.55, right = { 0, 0, 0, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 } },
		} },
	},
}

-- The Ember Lands: dark basalt, a smoking volcano, glowing lava rivers with stone bridges,
-- obsidian spires and drifting embers. Lava never hurts: each part in the Lava folder carries
-- the attribute Lava, and the client gently nudges you back to the bank (client Worlds.luau).
local Build = require(script.Parent.Build)
local Kit = require(script.Parent.WorldsKit)

local Lava = {}
local terrain = workspace.Terrain
local GLOW = { 255, 112, 30 }
local OBSIDIAN = { 26, 20, 36 }
local STONE = { 64, 56, 54 }

-- One river: Neon slabs from point to point (x, z offsets from the centre).
local function river(centre, points, width, folder)
	for i = 1, #points - 1 do
		local a = centre + Vector3.new(points[i][1], 0, points[i][2])
		local b = centre + Vector3.new(points[i + 1][1], 0, points[i + 1][2])
		local mid = (a + b) / 2
		local length = (b - a).Magnitude + width * 0.6
		local slab = Build.part({ name = "LavaRiver", size = Vector3.new(width, 1, length), cframe = CFrame.lookAt(mid, b) * CFrame.new(0, -0.2, 0), color = GLOW, material = "Neon", parent = folder })
		slab:SetAttribute("Lava", true)
		terrain:FillBlock(CFrame.lookAt(mid, b) * CFrame.new(0, -2, 0), Vector3.new(width + 8, 4, length), Enum.Material.CrackedLava)
		if i % 2 == 1 then
			Kit.drift(slab, { 255, 150, 60 }, 4, 2.5, 0.25)
			Kit.light(slab, GLOW, 24, 1.2)
		end
	end
end

local function bridge(at, angle, folder)
	local cf = CFrame.new(at) * CFrame.Angles(0, angle, 0)
	Build.part({ name = "Bridge", size = Vector3.new(8, 1, 22), cframe = cf * CFrame.new(0, 0.6, 0), color = STONE, material = "Slate", parent = folder })
	for _, x in ipairs({ -3.6, 3.6 }) do
		Build.part({ name = "BridgeRail", size = Vector3.new(0.6, 1.4, 22), cframe = cf * CFrame.new(x, 1.8, 0), color = { 44, 38, 38 }, material = "Slate", parent = folder })
	end
	for _, z in ipairs({ -12, 12 }) do -- a low step on and off
		Build.part({ name = "BridgeStep", size = Vector3.new(8, 0.6, 2.4), cframe = cf * CFrame.new(0, 0.3, z + (if z > 0 then 0.8 else -0.8)), color = STONE, material = "Slate", parent = folder })
	end
end

local function spire(at, height, rng, folder)
	for k = 0, 2 do
		local h = height * (1 - k * 0.25)
		local w = 3 + rng:NextNumber(0, 2) - k * 0.6
		local offset = Vector3.new(rng:NextNumber(-3, 3), 0, rng:NextNumber(-3, 3))
		local part = Build.part({ name = "ObsidianSpire", size = Vector3.new(w, h, w), cframe = CFrame.new(at + offset + Vector3.new(0, h / 2 - 1, 0)) * CFrame.Angles(rng:NextNumber(-0.12, 0.12), rng:NextNumber(0, 6), rng:NextNumber(-0.12, 0.12)), color = OBSIDIAN, material = "Glass", parent = folder })
		part.Reflectance = 0.25
		Build.part({ name = "SpireTip", class = "WedgePart", size = Vector3.new(w, w * 1.4, w), cframe = part.CFrame * CFrame.new(0, h / 2 + w * 0.7, 0), color = OBSIDIAN, material = "Glass", parent = folder })
	end
end

local function volcano(top, folder, lava)
	local base = Vector3.new(top.X, 0, top.Z)
	local height, r0, r1 = 72, 56, 13
	for y = 0, height, 4 do
		local t = y / height
		terrain:FillCylinder(CFrame.new(base + Vector3.new(0, y / 2, 0)), y + 4, r0 + (r1 - r0) * t, Enum.Material.Basalt)
	end
	terrain:FillCylinder(CFrame.new(base + Vector3.new(0, height - 2, 0)), 12, r1 - 3, Enum.Material.Air) -- the crater
	local pool = Build.part({ name = "CraterLava", shape = "Cylinder", size = Vector3.new(1, (r1 - 3) * 2, (r1 - 3) * 2), cframe = CFrame.new(base + Vector3.new(0, height - 7, 0)) * CFrame.Angles(0, 0, math.rad(90)), color = GLOW, material = "Neon", parent = lava })
	pool:SetAttribute("Lava", true)
	Kit.light(pool, GLOW, 60, 3)
	Kit.drift(pool, { 90, 84, 84 }, 10, 3, 6) -- slow smoke
	Kit.drift(pool, { 255, 160, 70 }, 8, 6, 0.4)
	-- a glowing flow down the side facing the haystack
	local dir = (Vector3.new(0, 0, 0) - Vector3.new(-1, 0, -1)).Unit
	for i = 0, 8 do
		local t = i / 8
		local r = r1 + (r0 - r1) * t
		local p = base + dir * (r - 2) + Vector3.new(0, height * (1 - t) - 2.5, 0)
		local flow = Build.part({ name = "LavaFlow", size = Vector3.new(6, 1.2, 11), cframe = CFrame.lookAt(p, p + dir) * CFrame.Angles(math.rad(-55), 0, 0), color = GLOW, material = "Neon", parent = lava })
		flow:SetAttribute("Lava", true)
	end
end

function Lava.build(w, centre, folder)
	Kit.ground(centre, Enum.Material.Basalt, 340)
	local rng = Random.new(53)
	local lava = Kit.folder("Lava", folder)
	local props = Kit.folder("Props", folder)
	volcano(centre + Vector3.new(-92, 0, -92), props, lava)
	-- two rivers that never cross the path from the return portal to the haystack
	river(centre, { { -60, -50 }, { -40, -30 }, { -50, 0 }, { -42, 30 }, { -60, 60 }, { -70, 100 }, { -64, 140 } }, 10, lava)
	river(centre, { { 50, -150 }, { 44, -110 }, { 60, -70 }, { 46, -36 }, { 58, 0 }, { 80, 36 }, { 120, 52 }, { 150, 48 } }, 9, lava)
	bridge(centre + Vector3.new(-45, 0, 15), math.rad(90) + 0.25, props)
	bridge(centre + Vector3.new(52, 0, -18), math.rad(90) - 0.3, props)
	for _ = 1, 16 do
		local a, r = rng:NextNumber(0, math.pi * 2), rng:NextNumber(40, 145)
		local p = centre + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		local nearPath = math.abs(p.X - centre.X) < 20 and p.Z - centre.Z > 60
		local nearVolcano = (p - (centre + Vector3.new(-92, 0, -92))).Magnitude < 64
		if not nearPath and not nearVolcano then
			spire(p, rng:NextNumber(14, 30), rng, props)
		end
	end
	for _ = 1, 40 do -- scattered dark rocks with glowing cracks
		local a, r = rng:NextNumber(0, math.pi * 2), rng:NextNumber(26, 150)
		local p = centre + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		if not (math.abs(p.X - centre.X) < 16 and p.Z - centre.Z > 70) then
			local s = rng:NextNumber(1.5, 4.5)
			local rock = Build.part({ name = "EmberRock", size = Vector3.new(s * 1.4, s, s * 1.2), cframe = CFrame.new(p + Vector3.new(0, s * 0.3, 0)) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 6), 0), color = STONE, material = "Slate", parent = props })
			if rng:NextNumber() < 0.4 then
				Build.part({ name = "EmberCrack", size = Vector3.new(s * 1.42, 0.2, 0.3), cframe = rock.CFrame * CFrame.new(0, 0, 0), color = GLOW, material = "Neon", collide = false, parent = props })
			end
		end
	end
	-- glowing lanterns along the arrival path
	for i = 0, 3 do
		for _, x in ipairs({ -12, 12 }) do
			local post = CFrame.new(centre + Vector3.new(x, 0, 30 + i * 22))
			Build.post({ name = "LanternPost", color = { 40, 34, 34 }, material = "Metal", parent = props }, post, 6, 0.6)
			local lamp = Build.part({ name = "Lantern", size = Vector3.new(1.4, 1.4, 1.4), cframe = post * CFrame.new(0, 6.6, 0), color = { 255, 170, 80 }, material = "Neon", parent = props })
			Kit.light(lamp, { 255, 170, 80 }, 16, 0.8)
		end
	end
	-- embers drifting up over the whole land
	local sky = Build.part({ name = "EmberCloud", size = Vector3.new(260, 1, 260), cframe = CFrame.new(centre + Vector3.new(0, 2, 0)), color = GLOW, transparency = 1, collide = false, shadow = false, parent = props })
	Kit.drift(sky, { 255, 140, 50 }, 30, 2, 0.3)
end

return Lava

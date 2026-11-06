-- The Moon: grey dust with craters and boulders, a little landed lander with its flag (a
-- golden needle on blue: our own), moon rocks, footprints, and the Earth hanging in the black sky.
-- Low gravity is applied on each player's own screen (client Worlds.luau).
local Build = require(script.Parent.Build)
local Kit = require(script.Parent.WorldsKit)

local Moon = {}
local terrain = workspace.Terrain
local DUST = { 168, 168, 172 }
local DARK = { 104, 104, 112 }

local function crater(at, radius)
	terrain:FillBall(at + Vector3.new(0, -radius * 0.45, 0), radius * 1.2, Enum.Material.Concrete) -- the raised rim
	terrain:FillBall(at + Vector3.new(0, radius * 0.35, 0), radius, Enum.Material.Air) -- the bowl
	terrain:FillBlock(CFrame.new(at + Vector3.new(0, -12, 0)), Vector3.new(radius * 2.6, 8, radius * 2.6), Enum.Material.Slate) -- never a hole to the void
end

local function lander(base, parent)
	local model = Instance.new("Model")
	model.Name = "Lander"
	local gold, white = { 214, 170, 70 }, { 230, 232, 236 }
	Build.part({ name = "Body", size = Vector3.new(10, 6, 10), cframe = base * CFrame.new(0, 8, 0) * CFrame.Angles(0, math.rad(45), 0), color = gold, material = "Foil", parent = model })
	Build.part({ name = "Cabin", size = Vector3.new(7, 6, 7), cframe = base * CFrame.new(0, 14, 0), color = white, material = "Metal", parent = model })
	local window = Build.part({ name = "Window", size = Vector3.new(2.4, 1.6, 0.2), cframe = base * CFrame.new(0, 15, -3.55), color = { 120, 190, 255 }, material = "Glass", parent = model })
	window.Transparency = 0.2
	Build.part({ name = "Hatch", size = Vector3.new(2.4, 2.6, 0.3), cframe = base * CFrame.new(0, 8, -5.1), color = DARK, material = "Metal", parent = model })
	Build.post({ name = "Antenna", color = white, material = "Metal", parent = model }, base * CFrame.new(1.8, 17, 1.8), 4, 0.3)
	Build.part({ name = "Dish", shape = "Cylinder", size = Vector3.new(0.3, 3, 3), cframe = base * CFrame.new(1.8, 21, 1.8) * CFrame.Angles(0, 0, math.rad(60)), color = white, material = "Metal", parent = model })
	for i = 0, 3 do
		local a = math.rad(45 + i * 90)
		local out = Vector3.new(math.cos(a), 0, math.sin(a))
		local foot = base.Position + out * 8.5
		local hip = base.Position + out * 4.5 + Vector3.new(0, 7, 0)
		local mid = (foot + hip) / 2
		Build.part({ name = "Leg", size = Vector3.new(0.6, 0.6, (hip - foot).Magnitude), cframe = CFrame.lookAt(mid, hip), color = { 190, 190, 196 }, material = "Metal", parent = model })
		Build.part({ name = "Foot", shape = "Cylinder", size = Vector3.new(0.4, 2.4, 2.4), cframe = CFrame.new(foot + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)), color = { 190, 190, 196 }, material = "Metal", parent = model })
	end
	for step = 0, 4 do -- a ladder down from the hatch
		Build.part({ name = "Rung", size = Vector3.new(2.2, 0.25, 0.25), cframe = base * CFrame.new(0, 1 + step * 1.3, -6.2), color = white, material = "Metal", parent = model })
	end
	model.Parent = parent
end

local function flag(at, parent)
	Build.post({ name = "FlagPole", color = { 220, 220, 224 }, material = "Metal", parent = parent }, CFrame.new(at), 12, 0.3)
	local cloth = Build.part({ name = "Flag", size = Vector3.new(6, 3.6, 0.15), cframe = CFrame.new(at + Vector3.new(3.1, 10, 0)), color = { 40, 70, 150 }, material = "Fabric", parent = parent })
	Build.part({ name = "FlagNeedle", size = Vector3.new(4.4, 0.35, 0.2), cframe = cloth.CFrame * CFrame.Angles(0, 0, math.rad(20)), color = { 245, 200, 66 }, material = "Neon", parent = parent })
	Build.part({ name = "FlagHay", shape = "Ball", size = Vector3.new(1.4, 1.4, 0.22), cframe = cloth.CFrame * CFrame.new(-1.6, -0.8, 0), color = { 240, 210, 120 }, material = "Fabric", parent = parent })
end

-- Earth: a big glowing blue ball with green land and white cloud caps, high in the sky.
local function earth(centre, parent)
	local at = centre + Vector3.new(-400, 300, 380)
	local radius = 110
	local planet = Build.part({ name = "Earth", shape = "Ball", size = Vector3.one * radius * 2, cframe = CFrame.new(at), color = { 40, 92, 176 }, material = "Neon", collide = false, shadow = false, parent = parent })
	planet.Transparency = 0.05
	local facing = (centre + Vector3.new(0, 20, 0) - at).Unit
	local look = CFrame.lookAt(at, at + facing)
	local land = { { -0.35, 0.25, 70, { 46, 140, 70 } }, { 0.3, -0.15, 80, { 70, 150, 64 } }, { 0.1, 0.45, 50, { 210, 190, 130 } }, { -0.1, -0.6, 60, { 236, 240, 248 } }, { 0.5, 0.5, 40, { 236, 240, 248 } } }
	for _, l in ipairs(land) do
		local dir = (look * CFrame.Angles(l[2], l[1], 0)).LookVector
		Build.part({ name = "EarthLand", shape = "Ball", size = Vector3.one * l[3], cframe = CFrame.new(at + dir * (radius - l[3] * 0.32)), color = l[4], material = "Neon", collide = false, shadow = false, parent = parent })
	end
	local glow = Build.part({ name = "EarthAir", shape = "Ball", size = Vector3.one * (radius * 2 + 14), cframe = CFrame.new(at), color = { 140, 200, 255 }, material = "ForceField", collide = false, shadow = false, parent = parent })
	glow.Transparency = 0.3
end

function Moon.build(w, centre, folder)
	Kit.ground(centre, Enum.Material.Slate, 340)
	terrain:FillBlock(CFrame.new(centre + Vector3.new(0, -2, 0)), Vector3.new(340, 4, 340), Enum.Material.Concrete) -- the dust on top
	local rng = Random.new(31)
	local craters = { { -80, -60, 18 }, { 70, -90, 24 }, { -110, 40, 14 }, { 100, 30, 16 }, { -40, -120, 12 }, { 120, -20, 10 }, { -120, -110, 20 }, { 40, 60, 9 }, { -60, 70, 11 } }
	for _, c in ipairs(craters) do
		crater(centre + Vector3.new(c[1], 0, c[2]), c[3])
	end
	local rocks = Kit.folder("Rocks", folder)
	for _ = 1, 70 do
		local a, r = rng:NextNumber(0, math.pi * 2), rng:NextNumber(30, 150)
		local p = centre + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		if not (math.abs(p.X - centre.X) < 16 and p.Z - centre.Z > 70) then -- keep the arrival path clear
			local s = rng:NextNumber(1, 5)
			Build.part({ name = "MoonRock", size = Vector3.new(s * rng:NextNumber(1, 1.8), s, s * rng:NextNumber(1, 1.6)), cframe = CFrame.new(p + Vector3.new(0, s * 0.3, 0)) * CFrame.Angles(rng:NextNumber(-0.5, 0.5), rng:NextNumber(0, 6), rng:NextNumber(-0.5, 0.5)), color = if rng:NextNumber() < 0.5 then DUST else DARK, material = "Slate", parent = rocks })
		end
	end
	for _ = 1, 6 do -- a few big boulders near the edge
		local a = rng:NextNumber(0, math.pi * 2)
		local p = centre + Vector3.new(math.cos(a) * 140, 0, math.sin(a) * 140)
		if p.Z - centre.Z < 90 then
			terrain:FillBall(p, rng:NextNumber(8, 14), Enum.Material.Rock)
		end
	end
	local base = CFrame.new(centre + Vector3.new(48, 0, 30))
	lander(base, folder)
	flag(centre + Vector3.new(36, 0, 44), folder)
	for i = 0, 14 do -- footprints from the lander to the haystack
		local t = i / 14
		local p = centre:Lerp(base.Position, 0.35 + t * 0.55) + Vector3.new(if i % 2 == 0 then 0.8 else -0.8, 0.05, 0)
		Build.part({ name = "Footprint", size = Vector3.new(1, 0.1, 1.8), cframe = CFrame.lookAt(p, base.Position), color = { 120, 120, 128 }, material = "Slate", collide = false, shadow = false, parent = folder })
	end
	-- a small rover parked by the lander
	local rover = CFrame.new(centre + Vector3.new(66, 0, 58)) * CFrame.Angles(0, math.rad(30), 0)
	Build.part({ name = "RoverDeck", size = Vector3.new(6, 0.6, 9), cframe = rover * CFrame.new(0, 2.4, 0), color = { 200, 200, 206 }, material = "Metal", parent = folder })
	Build.part({ name = "RoverSeat", size = Vector3.new(4, 2, 1), cframe = rover * CFrame.new(0, 3.6, 1.5), color = { 60, 60, 70 }, material = "Fabric", parent = folder })
	for _, x in ipairs({ -3.3, 3.3 }) do
		for _, z in ipairs({ -3.4, 3.4 }) do
			Build.part({ name = "RoverWheel", shape = "Cylinder", size = Vector3.new(1, 2.6, 2.6), cframe = rover * CFrame.new(x, 1.3, z), color = { 70, 70, 76 }, material = "SmoothPlastic", parent = folder })
		end
	end
	earth(centre, folder)
	-- soft lamps along the arrival path, so the dark side is never too dark
	for i = 0, 3 do
		for _, x in ipairs({ -12, 12 }) do
			local lamp = Build.part({ name = "PathLight", size = Vector3.new(1, 1, 1), cframe = CFrame.new(centre + Vector3.new(x, 0.5, 30 + i * 22)), color = { 170, 210, 255 }, material = "Neon", parent = folder })
			Kit.light(lamp, { 170, 210, 255 }, 18, 0.8)
		end
	end
end

return Moon

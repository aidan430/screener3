-- Bubble City: a domed city on the sea floor inside a great air bubble. Sand, coral, kelp,
-- sunken columns, and fish (moved on each player's screen by client Worlds.luau). Outside the
-- bubble is water; inside, the air is carved out so you walk normally.
local Build = require(script.Parent.Build)
local Kit = require(script.Parent.WorldsKit)

local Atlantis = {}
local terrain = workspace.Terrain
local MARBLE = { 222, 230, 226 }
local TEAL = { 60, 170, 170 }
local CORAL = { { 250, 120, 120 }, { 255, 170, 90 }, { 190, 110, 220 }, { 255, 210, 120 }, { 240, 90, 150 } }
local BUBBLE = 128 -- the bubble's radius (studs)

local function dome(at, radius, height, folder, glow)
	Build.part({ name = "DomeWall", shape = "Cylinder", size = Vector3.new(height, radius * 2, radius * 2), cframe = CFrame.new(at + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)), color = MARBLE, material = "Marble", parent = folder })
	local cap = Build.part({ name = "Dome", shape = "Ball", size = Vector3.one * radius * 2, cframe = CFrame.new(at + Vector3.new(0, height, 0)), color = TEAL, material = "Glass", parent = folder })
	cap.Transparency = 0.25
	Build.part({ name = "DomeBand", shape = "Cylinder", size = Vector3.new(1, radius * 2 + 0.6, radius * 2 + 0.6), cframe = CFrame.new(at + Vector3.new(0, height - 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), color = { 220, 190, 90 }, material = "Metal", parent = folder })
	for i = 0, 5 do -- glowing round windows
		local a = i / 6 * math.pi * 2
		local p = at + Vector3.new(math.cos(a) * radius, height * 0.5, math.sin(a) * radius)
		Build.part({ name = "DomeWindow", shape = "Cylinder", size = Vector3.new(0.4, 2.4, 2.4), cframe = CFrame.lookAt(p, at + Vector3.new(0, height * 0.5, 0)) * CFrame.Angles(0, math.rad(90), 0), color = glow, material = "Neon", parent = folder })
	end
	local lamp = Build.part({ name = "DomeLamp", shape = "Ball", size = Vector3.one * 2, cframe = CFrame.new(at + Vector3.new(0, height + radius + 0.6, 0)), color = glow, material = "Neon", parent = folder })
	Kit.light(lamp, glow, 26, 1)
end

local function column(at, height, tilt, broken, folder)
	local cf = CFrame.new(at) * CFrame.Angles(tilt, 0, tilt * 0.5)
	Build.part({ name = "ColumnBase", size = Vector3.new(5, 1.2, 5), cframe = CFrame.new(at + Vector3.new(0, 0.4, 0)), color = MARBLE, material = "Marble", parent = folder })
	Build.post({ name = "Column", color = MARBLE, material = "Marble", parent = folder }, cf, height, 3.2)
	if not broken then
		Build.part({ name = "ColumnTop", size = Vector3.new(4.6, 1, 4.6), cframe = cf * CFrame.new(0, height + 0.5, 0), color = MARBLE, material = "Marble", parent = folder })
	end
end

local function coral(at, rng, folder)
	local colour = CORAL[rng:NextInteger(1, #CORAL)]
	for _ = 1, rng:NextInteger(3, 6) do
		local h = rng:NextNumber(1.5, 5)
		local base = CFrame.new(at + Vector3.new(rng:NextNumber(-2, 2), 0, rng:NextNumber(-2, 2))) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), 0, rng:NextNumber(-0.4, 0.4))
		Build.post({ name = "Coral", color = colour, material = "Sand", parent = folder }, base, h, rng:NextNumber(0.6, 1.2))
		Build.part({ name = "CoralTip", shape = "Ball", size = Vector3.one * rng:NextNumber(1.2, 2), cframe = base * CFrame.new(0, h, 0), color = colour, material = "Sand", collide = false, parent = folder })
	end
end

local function kelp(at, rng, folder)
	local height = rng:NextNumber(12, 30)
	local segments = math.floor(height / 4)
	for i = 0, segments - 1 do
		local sway = math.sin(i * 0.9) * 0.8
		Build.part({ name = "Kelp", size = Vector3.new(0.8, 4.2, 1.6), cframe = CFrame.new(at + Vector3.new(sway, i * 4 + 2, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6), sway * 0.15), color = { 46, 120, 60 }, material = "Fabric", collide = false, shadow = false, parent = folder })
	end
end

-- A fish: a body, a tail and an eye, as one model the client swims round in a circle.
local function fish(centre, rng, folder, i)
	local model = Instance.new("Model")
	model.Name = "Fish"
	local colour = CORAL[rng:NextInteger(1, #CORAL)]
	local s = rng:NextNumber(0.8, 1.8)
	local radius, height = rng:NextNumber(24, 150), rng:NextNumber(5, 40)
	local phase = i * 2.4
	local at = CFrame.new(centre + Vector3.new(math.cos(phase) * radius, height, math.sin(phase) * radius))
	local body = Build.part({ name = "FishBody", shape = "Ball", size = Vector3.new(1.4, 1.2, 2.4) * s, cframe = at, color = colour, material = "SmoothPlastic", collide = false, shadow = false, parent = model })
	Build.part({ name = "FishTail", class = "WedgePart", size = Vector3.new(0.2, 1.2, 1) * s, cframe = at * CFrame.new(0, 0, 1.5 * s), color = colour, material = "SmoothPlastic", collide = false, shadow = false, parent = model })
	Build.part({ name = "FishEye", shape = "Ball", size = Vector3.one * 0.3 * s, cframe = at * CFrame.new(0.5 * s, 0.2 * s, -0.8 * s), color = { 20, 20, 30 }, collide = false, shadow = false, parent = model })
	model.PrimaryPart = body
	model:SetAttribute("Radius", radius)
	model:SetAttribute("Height", height)
	model:SetAttribute("Speed", rng:NextNumber(0.04, 0.12) * (if i % 2 == 0 then 1 else -1))
	model:SetAttribute("Phase", phase)
	model.Parent = folder
end

function Atlantis.build(w, centre, folder)
	-- the sea, then the bubble carved out of it, then the sea floor laid back under the bubble
	Kit.ground(centre, Enum.Material.Sand, 340)
	terrain:FillBlock(CFrame.new(centre + Vector3.new(0, 70, 0)), Vector3.new(340, 140, 340), Enum.Material.Water)
	terrain:FillBall(centre, BUBBLE - 2, Enum.Material.Air)
	Kit.ground(centre, Enum.Material.Sand, 340)
	local rng = Random.new(71)
	local bubble = Build.part({ name = "Bubble", shape = "Ball", size = Vector3.one * BUBBLE * 2, cframe = CFrame.new(centre), color = { 170, 230, 255 }, material = "Glass", collide = false, shadow = false, parent = folder })
	bubble.Transparency = 0.82
	local city = Kit.folder("City", folder)
	dome(centre + Vector3.new(-46, 0, -40), 14, 12, city, { 120, 240, 255 })
	dome(centre + Vector3.new(46, 0, -44), 12, 10, city, { 180, 255, 210 })
	dome(centre + Vector3.new(-62, 0, 20), 9, 8, city, { 255, 220, 140 })
	dome(centre + Vector3.new(62, 0, 16), 10, 9, city, { 200, 170, 255 })
	-- the great hall behind the haystack, with a spire
	dome(centre + Vector3.new(0, 0, -78), 22, 16, city, { 120, 240, 255 })
	Build.post({ name = "Spire", color = MARBLE, material = "Marble", parent = city }, CFrame.new(centre + Vector3.new(0, 38, -78)), 30, 3)
	local crown = Build.part({ name = "SpireLight", shape = "Ball", size = Vector3.one * 4, cframe = CFrame.new(centre + Vector3.new(0, 70, -78)), color = { 140, 250, 255 }, material = "Neon", parent = city })
	Kit.light(crown, { 140, 250, 255 }, 60, 1.5)
	-- a ring of columns round the haystack, some fallen
	for i = 0, 9 do
		local a = i / 10 * math.pi * 2 + 0.3
		local p = centre + Vector3.new(math.cos(a) * 32, 0, math.sin(a) * 32)
		if not (p.Z - centre.Z > 20 and math.abs(p.X - centre.X) < 14) then
			column(p, if i % 3 == 0 then 6 else 14, if i % 4 == 1 then 0.18 else 0, i % 3 == 0, city)
		end
	end
	local fallen = Build.post({ name = "FallenColumn", color = MARBLE, material = "Marble", parent = city }, CFrame.new(centre + Vector3.new(-28, 1.6, 52)) * CFrame.Angles(0, 0.6, math.rad(90)), 16, 3.2)
	fallen.CanCollide = true
	-- paths of pale stone to the domes
	for _, target in ipairs({ { -46, -40 }, { 46, -44 }, { -62, 20 }, { 62, 16 }, { 0, -78 } }) do
		local to = centre + Vector3.new(target[1], 0, target[2])
		local mid = (centre + to) / 2
		Build.part({ name = "Path", size = Vector3.new(5, 0.2, (to - centre).Magnitude), cframe = CFrame.lookAt(mid + Vector3.new(0, 0.1, 0), to + Vector3.new(0, 0.1, 0)), color = { 230, 220, 190 }, material = "Sandstone", parent = city })
	end
	local life = Kit.folder("Life", folder)
	for _ = 1, 50 do
		local a, r = rng:NextNumber(0, math.pi * 2), rng:NextNumber(26, 160)
		local p = centre + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		if not (math.abs(p.X - centre.X) < 16 and p.Z - centre.Z > 70) then
			if rng:NextNumber() < 0.55 then
				coral(p, rng, life)
			else
				kelp(p, rng, life)
			end
		end
	end
	local fishes = Kit.folder("Fish", folder)
	for i = 1, 28 do
		fish(centre, rng, fishes, i)
	end
	-- rising bubbles from a few vents
	for _, v in ipairs({ { -20, -20 }, { 30, 10 }, { -80, -10 }, { 90, -70 } }) do
		local vent = Build.part({ name = "Vent", shape = "Ball", size = Vector3.new(3, 1.4, 3), cframe = CFrame.new(centre + Vector3.new(v[1], 0, v[2])), color = { 120, 110, 100 }, material = "Slate", parent = life })
		Kit.drift(vent, { 220, 245, 255 }, 3, 4, 0.6)
	end
end

return Atlantis

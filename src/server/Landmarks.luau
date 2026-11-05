-- The ten farm landmarks, one behind each haystack, built from simple parts.
-- Each builder gets `cf`: a ground-level frame whose front (-Z) faces the plaza.
local Build = require(script.Parent.Build)

local Landmarks = {}
local terrain = workspace.Terrain
local builders = {}

local function p(model, cf, size, color, material, shape)
	return Build.part({ size = size, cframe = cf, color = color, material = material or "SmoothPlastic", shape = shape, parent = model })
end

function builders.windmill(model, cf)
	local stone = { 198, 182, 152 }
	p(model, cf * CFrame.new(0, 5, 0), Vector3.new(12, 10, 12), stone, "WoodPlanks")
	p(model, cf * CFrame.new(0, 14, 0), Vector3.new(10, 8, 10), stone, "WoodPlanks")
	p(model, cf * CFrame.new(0, 21.5, 0), Vector3.new(8, 7, 8), stone, "WoodPlanks")
	p(model, cf * CFrame.new(0, 26, 0), Vector3.new(9, 9, 9), { 170, 62, 50 }, "Wood", "Ball")
	p(model, cf * CFrame.new(0, 3.5, -6.05), Vector3.new(3.4, 7, 0.2), { 70, 48, 32 }, "Wood")
	-- the sails turn on each player's screen (WorldFx rotates the Blades model)
	local hub = cf * CFrame.new(0, 22, -5)
	p(model, hub * CFrame.Angles(0, math.rad(90), 0), Vector3.new(2.4, 2.2, 2.2), { 90, 70, 52 }, "Wood", "Cylinder")
	local blades = Instance.new("Model")
	blades.Name = "Blades"
	for i = 0, 3 do
		local turn = hub * CFrame.new(0, 0, -1.4) * CFrame.Angles(0, 0, math.rad(i * 90))
		p(blades, turn * CFrame.new(0, 8, 0), Vector3.new(2.6, 14, 0.3), { 238, 230, 212 }, "Fabric")
		p(blades, turn * CFrame.new(0, 8, 0.2), Vector3.new(0.5, 15, 0.4), { 110, 82, 58 }, "Wood")
	end
	blades.WorldPivot = hub * CFrame.new(0, 0, -1.4)
	blades.Parent = model
end

function builders.barn(model, cf)
	p(model, cf * CFrame.new(0, 8, 0), Vector3.new(26, 16, 20), { 176, 52, 40 }, "WoodPlanks")
	-- ridge runs across the barn; the roof stays inside the side walls so only the eaves show
	Build.roof({ color = { 86, 62, 52 }, material = "Slate", parent = model }, cf * CFrame.new(0, 16, 0) * CFrame.Angles(0, math.rad(90), 0), 28, 25.9)
	p(model, cf * CFrame.new(0, 5.5, -10.1), Vector3.new(9, 11, 0.3), { 240, 232, 214 }, "WoodPlanks")
	p(model, cf * CFrame.new(0, 5.5, -10.2), Vector3.new(7.6, 9.6, 0.3), { 150, 42, 34 }, "WoodPlanks")
end

function builders.tractor(model, cf)
	local green, red, black = { 62, 140, 62 }, { 196, 54, 40 }, { 34, 34, 36 }
	p(model, cf * CFrame.new(0, 4, 0), Vector3.new(6, 3.4, 12), green, "Metal")
	p(model, cf * CFrame.new(0, 8, 3), Vector3.new(5.6, 5, 5), green, "Metal")
	p(model, cf * CFrame.new(0, 10.7, 3), Vector3.new(6.4, 0.4, 6.4), black, "Metal")
	for _, side in ipairs({ -1, 1 }) do
		p(model, cf * CFrame.new(side * 4, 3.6, 3.6), Vector3.new(2, 7.2, 7.2), black, "Rubber", "Cylinder")
		p(model, cf * CFrame.new(side * 4.1, 3.6, 3.6), Vector3.new(2, 3, 3), red, "Metal", "Cylinder")
		p(model, cf * CFrame.new(side * 3.6, 2, -4), Vector3.new(1.6, 4, 4), black, "Rubber", "Cylinder")
	end
	Build.post({ color = black, material = "Metal", parent = model }, cf * CFrame.new(1.8, 5.6, -3), 4, 0.6)
end

function builders.pond(model, cf)
	local centre = cf.Position
	terrain:FillCylinder(CFrame.new(centre.X, -2.5, centre.Z), 5, 17, Enum.Material.Water)
	local rng = Random.new(11)
	for i = 1, 14 do
		local a = i / 14 * math.pi * 2
		local base = CFrame.new(centre + Vector3.new(math.cos(a) * 17, 0, math.sin(a) * 17))
		Build.post({ color = { 92, 120, 52 }, material = "Grass", collide = false, parent = model }, base, rng:NextNumber(3, 5.5), 0.35)
	end
	for i = 1, 3 do
		local duck = cf * CFrame.new(-6 + i * 3.5, 0.4, -2 + (i % 2) * 4) * CFrame.Angles(0, i, 0)
		p(model, duck, Vector3.new(1.6, 1.2, 2.4), { 246, 244, 236 })
		p(model, duck * CFrame.new(0, 1, -1), Vector3.new(1, 1, 1), { 62, 120, 72 })
		p(model, duck * CFrame.new(0, 0.9, -1.7), Vector3.new(0.5, 0.3, 0.5), { 240, 160, 40 })
	end
end

function builders.appletree(model, cf)
	Build.post({ color = { 96, 66, 44 }, material = "Wood", parent = model }, cf, 15, 3)
	local canopy = { { 0, 19, 0, 18 }, { 5, 16, 3, 13 }, { -5, 17, -2, 13 }, { 0, 16, 5, 12 } }
	for i, c in ipairs(canopy) do
		p(model, cf * CFrame.new(c[1], c[2], c[3]), Vector3.new(c[4], c[4], c[4]), i % 2 == 0 and { 168, 156, 52 } or { 116, 140, 50 }, "Grass", "Ball")
	end
	local rng = Random.new(5)
	for _ = 1, 12 do
		local dir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.4, 0.8), rng:NextNumber(-1, 1)).Unit
		p(model, cf * CFrame.new(Vector3.new(0, 18, 0) + dir * 9.2), Vector3.new(1.3, 1.3, 1.3), { 200, 30, 36 }, "SmoothPlastic", "Ball")
	end
end

function builders.well(model, cf)
	local stone = { 146, 140, 134 }
	Build.post({ color = stone, material = "Slate", parent = model }, cf, 3.4, 9)
	Build.post({ color = { 18, 26, 34 }, material = "SmoothPlastic", parent = model }, cf * CFrame.new(0, 3.3, 0), 0.2, 7.4)
	for _, x in ipairs({ -3.8, 3.8 }) do
		p(model, cf * CFrame.new(x, 6.4, 0), Vector3.new(0.8, 6.4, 0.8), { 110, 78, 50 }, "Wood")
	end
	for _, s in ipairs({ -1, 1 }) do
		p(model, cf * CFrame.new(s * 2.2, 10.4, 0) * CFrame.Angles(0, 0, math.rad(-s * 35)), Vector3.new(5.6, 0.3, 6.4), { 120, 60, 44 }, "WoodPlanks")
	end
	p(model, cf * CFrame.new(0, 7.6, 0) * CFrame.Angles(0, math.rad(90), 0), Vector3.new(1.4, 1.2, 1.2), { 120, 100, 80 }, "Metal", "Cylinder")
end

function builders.pumpkins(model, cf)
	terrain:FillBlock(cf * CFrame.new(0, -2, 0), Vector3.new(22, 4, 18), Enum.Material.Ground)
	local rng = Random.new(3)
	for _ = 1, 10 do
		local size = rng:NextNumber(2.4, 4.6)
		local spot = cf * CFrame.new(rng:NextNumber(-9, 9), size / 2 - 0.3, rng:NextNumber(-7, 7))
		p(model, spot, Vector3.new(size, size, size), { 232, 120, 30 }, "SmoothPlastic", "Ball")
		p(model, spot * CFrame.new(0, size / 2, 0), Vector3.new(0.35, 0.9, 0.35), { 82, 110, 40 }, "Wood")
	end
end

function builders.coop(model, cf)
	p(model, cf * CFrame.new(0, 4, 0), Vector3.new(10, 6, 8), { 232, 220, 188 }, "WoodPlanks")
	Build.roof({ color = { 170, 56, 44 }, material = "WoodPlanks", parent = model }, cf * CFrame.new(0, 7, 0), 11, 7.9)
	p(model, cf * CFrame.new(0, 2.6, -4.05), Vector3.new(2, 2.4, 0.2), { 60, 44, 30 }, "Wood")
	p(model, cf * CFrame.new(0, 1, -6.4) * CFrame.Angles(math.rad(-24), 0, 0), Vector3.new(2, 0.3, 5), { 150, 112, 70 }, "Wood")
	for i = 1, 3 do
		local hen = cf * CFrame.new(-5 + i * 2.6, 0.9, -9 + (i % 2) * 1.6) * CFrame.Angles(0, i * 2, 0)
		p(model, hen, Vector3.new(1.4, 1.4, 1.8), { 248, 246, 240 })
		p(model, hen * CFrame.new(0, 1, -0.8), Vector3.new(0.9, 0.9, 0.9), { 248, 246, 240 })
		p(model, hen * CFrame.new(0, 1.6, -0.8), Vector3.new(0.25, 0.4, 0.6), { 210, 40, 40 })
	end
end

function builders.scarecrow(model, cf)
	local wood = { 120, 88, 56 }
	p(model, cf * CFrame.new(0, 5, 0), Vector3.new(0.8, 10, 0.8), wood, "Wood")
	p(model, cf * CFrame.new(0, 8, 0), Vector3.new(8, 0.6, 0.6), wood, "Wood")
	p(model, cf * CFrame.new(0, 7.4, 0), Vector3.new(3.2, 3.6, 1.4), { 166, 58, 48 }, "Fabric")
	p(model, cf * CFrame.new(0, 10.6, 0), Vector3.new(2.6, 2.6, 2.6), { 222, 196, 138 }, "Fabric", "Ball")
	Build.post({ color = { 112, 84, 48 }, material = "Fabric", parent = model }, cf * CFrame.new(0, 11.6, 0), 0.3, 4.6)
	Build.post({ color = { 112, 84, 48 }, material = "Fabric", parent = model }, cf * CFrame.new(0, 11.8, 0), 1.6, 2.4)
	for _, x in ipairs({ -3.6, 3.6 }) do
		p(model, cf * CFrame.new(x, 8.7, 0), Vector3.new(0.8, 0.8, 1.2), { 30, 28, 32 })
	end
end

function builders.shed(model, cf)
	p(model, cf * CFrame.new(0, 4.5, 0), Vector3.new(12, 9, 10), { 124, 104, 84 }, "WoodPlanks")
	Build.roof({ color = { 76, 68, 62 }, material = "Slate", parent = model }, cf * CFrame.new(0, 9, 0), 13, 9.9)
	p(model, cf * CFrame.new(0, 3.6, -5.05), Vector3.new(4, 7.2, 0.2), { 84, 64, 46 }, "Wood")
	local lean = cf * CFrame.new(4, 3, -5.6) * CFrame.Angles(math.rad(12), 0, 0)
	p(model, lean, Vector3.new(0.3, 6, 0.3), { 150, 110, 70 }, "Wood")
	p(model, lean * CFrame.new(0, 3, 0), Vector3.new(1.4, 0.25, 0.25), { 160, 164, 170 }, "Metal")
end

function Landmarks.build(pile, parent)
	local builder = builders[pile.id]
	if not builder then
		return nil
	end
	local base = Vector3.new(pile.x, 0, pile.z)
	local origin = base + base.Unit * 30
	local model = Instance.new("Model")
	model.Name = pile.id
	builder(model, CFrame.lookAt(origin, Vector3.new(0, 0, 0)))
	model.Parent = parent
	return model
end

return Landmarks

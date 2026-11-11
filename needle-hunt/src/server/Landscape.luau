-- The land, in smooth terrain (Config.Look.Terrain): Hayfield Farm's floor (grass, bare earth, mud
-- and cobbles by quarter, dirt roads with muddy ruts), the frame of fields and hills round the
-- arena that hides the world's edge, and a few mounds beyond the lobby's hedge. Grass terrain gets
-- moving blades (the place file switches them on). Coordinates are map-local, on the 4-stud grid.
--   Landscape.floor(ctx)        every round on a terrain map: the slab, plus an invisible Ground
--                               part at the same height (server/ChestSpawner's rays want a part)
--   Landscape.farm(ctx, plan)   paints it: plan = { quarters = { { style, x, z, half, yards } }, ... }
--   Landscape.backdrop(centre)  once a server: the frame and its hills (never cleared)
--   Landscape.lobby(centre)     once: the lobby's mounds
-- MapKit.clearTerrain clears the play square only, between rounds. With Config.Studs.on the floor
-- is the old studded part and nothing here is filled.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local MapKit = require(script.Parent.MapKit)

local Landscape = {}
local T = Config.Look.Terrain
local backdropDone = false

local function terrain()
	return workspace.Terrain
end

function Landscape.colours()
	for name, c in pairs(T.colours) do
		terrain():SetMaterialColor(Enum.Material[name], Color3.fromRGB(c[1], c[2], c[3]))
	end
end

-- Refills the top layer of the floor over a rectangle (snapped outwards to the grid).
function Landscape.paint(ctx, x0, z0, x1, z1, material)
	x0, z0 = math.floor(math.min(x0, x1) / 4) * 4, math.floor(math.min(z0, z1) / 4) * 4
	x1, z1 = math.ceil(math.max(x0 + 4, x1) / 4) * 4, math.ceil(math.max(z0 + 4, z1) / 4) * 4
	terrain():FillBlock(CFrame.new(MapKit.at(ctx, (x0 + x1) / 2, -2, (z0 + z1) / 2)), Vector3.new(x1 - x0, 4, z1 - z0), Enum.Material[material])
end

function Landscape.floor(ctx)
	local size = T.play * 2
	if Config.Studs.on then -- the classic look: one studded part, as before
		return MapKit.ground(ctx, size, size, ctx.def.ground, "Grass")
	end
	Landscape.colours()
	terrain():FillBlock(CFrame.new(MapKit.at(ctx, 0, -T.depth / 2, 0)), Vector3.new(size, T.depth, size), Enum.Material.Grass)
	return MapKit.part(ctx, { Name = "Ground", Size = Vector3.new(size, 2, size), CFrame = CFrame.new(MapKit.at(ctx, 0, -1, 0)), Transparency = 1, CastShadow = false })
end

function Landscape.farm(ctx, plan)
	if Config.Studs.on then
		return
	end
	local R = T.road
	for _, q in ipairs(plan.quarters) do -- each quarter's own ground, and a yard under its clearings
		Landscape.paint(ctx, q.x - q.half, q.z - q.half, q.x + q.half, q.z + q.half, T.quarters[q.style] or "Grass")
		for _, yard in ipairs(q.yards or {}) do
			Landscape.paint(ctx, yard.x - T.yard, yard.z - T.yard, yard.x + T.yard, yard.z + T.yard, T.yards[q.style] or "Ground")
		end
	end
	local far = T.play
	for _, s in ipairs({ -1, 1 }) do -- the ring road, with two ruts
		local a, b = s * R.ring[1], s * R.ring[2]
		Landscape.paint(ctx, -R.ring[2], a, R.ring[2], b, "Ground")
		Landscape.paint(ctx, a, -R.ring[2], b, R.ring[2], "Ground")
		for _, rut in ipairs(R.ringRuts) do
			Landscape.paint(ctx, -rut[2], s * rut[1], rut[2], s * rut[2], "Mud")
			Landscape.paint(ctx, s * rut[1], -rut[2], s * rut[2], rut[2], "Mud")
		end
	end
	Landscape.paint(ctx, -R.half, -far, R.half, far, "Ground") -- the two roads through the middle
	Landscape.paint(ctx, -far, -R.half, far, R.half, "Ground")
	for _, s in ipairs({ -1, 1 }) do
		local a, b = s * R.rut, s * R.half
		Landscape.paint(ctx, a, -far, b, far, "Mud")
		Landscape.paint(ctx, -far, a, far, b, "Mud")
	end
	Landscape.paint(ctx, -R.cross, -R.cross, R.cross, R.cross, "Cobblestone") -- the crossroads
end

-- The frame of land round the arena, built once and never cleared: flat fields, low hills, and a
-- ridge that hides where the world stops. Dirt lanes run on from the four road ends.
function Landscape.backdrop(centre)
	if backdropDone or Config.Studs.on then
		return
	end
	backdropDone = true
	Landscape.colours()
	local F = T.frame
	local ctx = { centre = centre, floorY = 0 }
	local rng = Random.new(7)
	local mid, width = (F.inner + F.outer) / 2, F.outer - F.inner
	for _, s in ipairs({ -1, 1 }) do -- four slabs round the play square, tops level with its floor
		terrain():FillBlock(CFrame.new(MapKit.at(ctx, 0, -T.depth / 2, s * mid)), Vector3.new(F.outer * 2, T.depth, width), Enum.Material.Grass)
		terrain():FillBlock(CFrame.new(MapKit.at(ctx, s * mid, -T.depth / 2, 0)), Vector3.new(width, T.depth, F.inner * 2), Enum.Material.Grass)
		task.wait()
	end
	local M = F.mound
	for i = 1, F.mounds do -- low hills, clear of the lanes
		local a = (i + rng:NextNumber(-0.3, 0.3)) / F.mounds * math.pi * 2
		local d = rng:NextNumber(M.at[1], M.at[2])
		local x, z = math.cos(a) * d, math.sin(a) * d
		if math.min(math.abs(x), math.abs(z)) > M.lane then
			terrain():FillBall(MapKit.at(ctx, x, rng:NextNumber(M.top[1], M.top[2]) - M.radius, z), M.radius, Enum.Material.Grass)
		end
		if i % 6 == 0 then
			task.wait()
		end
	end
	local G = F.ridge
	for _, s in ipairs({ -1, 1 }) do -- the ridge, all the way round
		for t = -G.at, G.at, G.every do
			terrain():FillBall(MapKit.at(ctx, t, G.top - G.radius, s * G.at), G.radius, Enum.Material.Grass)
			terrain():FillBall(MapKit.at(ctx, s * G.at, G.top - G.radius, t), G.radius, Enum.Material.Grass)
		end
		task.wait()
	end
	for _, s in ipairs({ -1, 1 }) do -- the lanes running on from the field gates
		Landscape.paint(ctx, -6, s * F.inner, 6, s * 300, "Ground")
		Landscape.paint(ctx, s * F.inner, -6, s * 300, 6, "Ground")
	end
	local W = T.water -- a pond at the end of the -X lane
	terrain():FillBall(MapKit.at(ctx, W.x, W.radius * 0.6, W.z), W.radius, Enum.Material.Air)
	terrain():FillCylinder(CFrame.new(MapKit.at(ctx, W.x, -W.depth / 2 - 0.5, W.z)), W.depth, W.radius * 0.75, Enum.Material.Water)
	terrain().WaterColor = Color3.fromRGB(W.colour[1], W.colour[2], W.colour[3])
	terrain().WaterTransparency, terrain().WaterReflectance, terrain().WaterWaveSize, terrain().WaterWaveSpeed = 0.45, 0.6, 0.05, 6
	local model = Instance.new("Model") -- and what stands on the land (server/Vista)
	model.Name = "Backdrop"
	model.Parent = workspace
	ctx.model = model
	require(script.Parent.Vista).build(ctx)
end

function Landscape.lobby(centre)
	if Config.Studs.on then
		return
	end
	local B = T.lobby
	for i = 0, B.mounds - 1 do
		local a = math.rad(i * 360 / B.mounds + 15)
		terrain():FillBall(centre + Vector3.new(math.cos(a) * B.at, B.top[i % #B.top + 1] - B.radius, math.sin(a) * B.at), B.radius, Enum.Material.Grass)
	end
end

return Landscape

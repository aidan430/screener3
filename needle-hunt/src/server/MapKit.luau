-- The building kit for maps (server/MapsA, MapsB): ground, hay bales, haystacks, crates, fences,
-- trees, walls, lamps, loose straw and tumbling hay. Each prop records the hiding spots it makes
-- (on its top, or on the ground beside it) as it is placed, so a needle only ever goes on a real
-- surface; server/ChestSpawner checks each spot again before using it.
-- ctx: { model, rng, centre = Vector3, def = a Maps row, spots = {}, spawns = {}, floorY }
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local MapKit = {}

-- Config.Studs as sets: the names that get studs, the materials that keep theirs
local studNames, studKeep = {}, {}
for _, n in ipairs(Config.Studs.names) do
	studNames[n] = true
end
for _, m in ipairs(Config.Studs.keep) do
	studKeep[Enum.Material[m]] = true
end

local function rgb(c)
	return Color3.fromRGB(c[1], c[2], c[3])
end
MapKit.rgb = rgb

-- An anchored, smooth part in the map (a floor, wall or platform named in Config.Studs gets studs).
-- props: Size, CFrame, Color ({r,g,b} or Color3), Material, Shape...
function MapKit.part(ctx, props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		if k == "Color" and type(v) == "table" then
			v = rgb(v)
		elseif k == "Material" and type(v) == "string" then
			v = Enum.Material[v]
		elseif k == "Shape" and type(v) == "string" then
			v = Enum.PartType[v]
		end
		p[k] = v
	end
	if Config.Studs.on and studNames[p.Name] and not studKeep[p.Material] then -- a floor, wall or platform: classic studs
		p.Material = Enum.Material.Plastic
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Studs, Enum.SurfaceType.Inlet
	end
	p.Parent = props.Parent or ctx.model
	return p
end

-- A world position from map-local x, y (height above the floor), z.
function MapKit.at(ctx, x, y, z)
	return ctx.centre + Vector3.new(x, ctx.floorY + y, z)
end

-- A hiding spot: the needle lies flat on a surface at `pos` (its top), turned any way.
-- climb = true for spots up high that stairs or a ladder reach.
function MapKit.spot(ctx, pos, climb)
	table.insert(ctx.spots, { cf = CFrame.new(pos), climb = climb == true })
end

-- Spots on the top face of a part, and on the ground round its foot.
function MapKit.spotsOn(ctx, part, onTop, around, climb)
	local cf, size = part.CFrame, part.Size
	for _ = 1, onTop do
		local x = (ctx.rng:NextNumber() - 0.5) * size.X * 0.7
		local z = (ctx.rng:NextNumber() - 0.5) * size.Z * 0.7
		MapKit.spot(ctx, (cf * CFrame.new(x, size.Y / 2, z)).Position, climb)
	end
	for _ = 1, around do
		local a = ctx.rng:NextNumber() * math.pi * 2
		local r = math.max(size.X, size.Z) / 2 + 1.0 -- clear of the prop's corners
		local p = cf.Position + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		MapKit.spot(ctx, Vector3.new(p.X, ctx.centre.Y + ctx.floorY, p.Z))
	end
end

function MapKit.ground(ctx, sx, sz, colour, material)
	return MapKit.part(ctx, { Name = "Ground", Size = Vector3.new(sx, 2, sz), CFrame = CFrame.new(MapKit.at(ctx, 0, -1, 0)), Color = colour, Material = material or "Grass" })
end

-- The edge of an outdoor map: countryside running off to the horizon (so the map never ends in
-- mid-air), a tall hedge you can see all the way round the play area (half sizes halfX, halfZ),
-- and invisible walls on top of it up to 200 studs, so nobody walks, jumps or flies off. Neither
-- can be clicked through to (they ignore clicks and raycasts).
function MapKit.edges(ctx, halfX, halfZ, colour)
	MapKit.part(ctx, { Name = "Countryside", Size = Vector3.new(900, 2, 900), CFrame = CFrame.new(MapKit.at(ctx, 0, -1.1, 0)), Color = colour, Material = "Grass", CanQuery = false })
	for _, w in ipairs({ { 0, -halfZ, halfX * 2 + 3, 3 }, { 0, halfZ, halfX * 2 + 3, 3 }, { -halfX, 0, 3, halfZ * 2 + 3 }, { halfX, 0, 3, halfZ * 2 + 3 } }) do
		MapKit.part(ctx, { Name = "Hedge", Size = Vector3.new(w[3], 9, w[4]), CFrame = CFrame.new(MapKit.at(ctx, w[1], 4.5, w[2])), Color = { 52, 104, 52 }, Material = "LeafyGrass", CanQuery = false })
		MapKit.part(ctx, { Name = "Edge", Size = Vector3.new(w[3], 200, w[4]), CFrame = CFrame.new(MapKit.at(ctx, w[1], 109, w[2])), Transparency = 1, CanQuery = false, CastShadow = false })
	end
end

function MapKit.spawnAt(ctx, x, z)
	table.insert(ctx.spawns, CFrame.new(MapKit.at(ctx, x, 3, z)) * CFrame.Angles(0, ctx.rng:NextNumber() * math.pi * 2, 0))
end

-- A rectangular hay bale with two twine bands. y = the height of its base above the floor.
function MapKit.bale(ctx, x, y, z, turn, climb)
	local cf = CFrame.new(MapKit.at(ctx, x, y + 1.25, z)) * CFrame.Angles(0, turn or 0, 0)
	local straw = ctx.def.straw
	local bale = MapKit.part(ctx, { Name = "Bale", Size = Vector3.new(4, 2.5, 2.5), CFrame = cf, Color = straw, Material = "Grass" })
	for _, dx in ipairs({ -1, 1 }) do
		MapKit.part(ctx, { Name = "Twine", Size = Vector3.new(0.15, 2.56, 2.56), CFrame = cf * CFrame.new(dx, 0, 0), Color = { 150, 100, 60 }, Material = "Fabric", CanCollide = false, CanQuery = false })
	end
	MapKit.spotsOn(ctx, bale, 1, if y > 0 then 0 else 1, climb)
	return bale
end

-- A round haystack: stacked, shrinking cylinders under a dome. Spots round its foot.
-- A haystack: the owner's model if it's loaded (server/HaystackModel), otherwise a smooth, lumpy
-- terrain dome (a drum with a dome on top and a few bulges), coloured straw gold. Terrain cells
-- are 4 studs, so hiding spots go a little further out round its foot.
function MapKit.haystack(ctx, x, z, radius, height)
	local ground = MapKit.at(ctx, x, 0, z)
	local own = require(script.Parent.HaystackModel).place(ground, radius * 2.2, ctx.rng:NextNumber() * math.pi * 2)
	if own then
		own.Parent = ctx.model
	else
		local terrain = workspace.Terrain
		local H = Config.Haystacks
		local material = Enum.Material[H.material]
		terrain:SetMaterialColor(material, Color3.fromRGB(H.colour[1], H.colour[2], H.colour[3]))
		local domeY = math.max(radius * 0.4, height - radius)
		terrain:FillCylinder(CFrame.new(ground + Vector3.new(0, domeY / 2, 0)), domeY, radius, material)
		terrain:FillBall(ground + Vector3.new(0, domeY, 0), radius, material)
		terrain:FillBall(ground + Vector3.new(0, domeY + radius * 0.75, 0), radius * 0.6, material) -- the rounded peak
		for _ = 1, 5 do -- gentle bulges, so no two stacks look the same
			local a = ctx.rng:NextNumber() * math.pi * 2
			local up = ctx.rng:NextNumber(0.2, 0.9)
			local p = ground + Vector3.new(math.cos(a) * radius * 0.6, domeY * up + radius * 0.3, math.sin(a) * radius * 0.6)
			terrain:FillBall(p, radius * ctx.rng:NextNumber(0.25, 0.35), material)
		end
	end
	for _ = 1, 3 do
		local a = ctx.rng:NextNumber() * math.pi * 2
		MapKit.spot(ctx, MapKit.at(ctx, x + math.cos(a) * (radius + 3), 0, z + math.sin(a) * (radius + 3)))
	end
end

-- Clears the terrain haystacks round `centre` (the arena, between rounds).
function MapKit.clearTerrain(centre)
	workspace.Terrain:FillBlock(CFrame.new(centre + Vector3.new(0, 40, 0)), Vector3.new(340, 100, 340), Enum.Material.Air)
end

function MapKit.crate(ctx, x, y, z, size, climb)
	size = size or 3
	local c = MapKit.part(ctx, { Name = "Crate", Size = Vector3.one * size, CFrame = CFrame.new(MapKit.at(ctx, x, y + size / 2, z)) * CFrame.Angles(0, ctx.rng:NextNumber() * 0.6, 0), Color = { 150, 106, 64 }, Material = "WoodPlanks" })
	MapKit.spotsOn(ctx, c, 1, if y > 0 then 0 else 1, climb)
	return c
end

-- A wall or floor panel (collides). cf is its centre.
function MapKit.wall(ctx, cf, size, colour, material)
	return MapKit.part(ctx, { Name = "Wall", Size = size, CFrame = cf, Color = colour, Material = material or "WoodPlanks" })
end

-- A fence from a to b (map-local x, z pairs): posts and two rails.
function MapKit.fence(ctx, ax, az, bx, bz)
	local a, b = MapKit.at(ctx, ax, 0, az), MapKit.at(ctx, bx, 0, bz)
	local length = (b - a).Magnitude
	for i = 0, math.floor(length / 8) do
		local p = a:Lerp(b, i * 8 / length)
		MapKit.part(ctx, { Name = "Post", Size = Vector3.new(0.6, 4, 0.6), CFrame = CFrame.new(p + Vector3.new(0, 2, 0)), Color = { 120, 84, 50 }, Material = "Wood" })
	end
	for _, h in ipairs({ 1.6, 3.2 }) do
		local mid = (a + b) / 2 + Vector3.new(0, h, 0)
		MapKit.part(ctx, { Name = "Rail", Size = Vector3.new(0.3, 0.4, length), CFrame = CFrame.lookAt(mid, mid + (b - a)), Color = { 140, 100, 60 }, Material = "Wood" })
	end
end

-- A tree: a trunk and a few leafy balls. Spots among its roots.
function MapKit.tree(ctx, x, z, height, leaf)
	local h = height or 14
	MapKit.part(ctx, { Name = "Trunk", Shape = "Cylinder", Size = Vector3.new(h, 1.8, 1.8), CFrame = CFrame.new(MapKit.at(ctx, x, h / 2, z)) * CFrame.Angles(0, 0, math.rad(90)), Color = { 96, 70, 46 }, Material = "Wood" })
	for i = 1, 3 do
		local o = Vector3.new((ctx.rng:NextNumber() - 0.5) * 4, h - 1 + i, (ctx.rng:NextNumber() - 0.5) * 4)
		MapKit.part(ctx, { Name = "Leaves", Shape = "Ball", Size = Vector3.one * (8 - i), CFrame = CFrame.new(MapKit.at(ctx, x, 0, z) + o), Color = leaf or { 60, 110, 60 }, Material = "Grass", CanCollide = false })
	end
	for _ = 1, 2 do
		local a = ctx.rng:NextNumber() * math.pi * 2
		MapKit.spot(ctx, MapKit.at(ctx, x + math.cos(a) * 2.2, 0, z + math.sin(a) * 2.2))
	end
end

-- A lamp: a small glowing block with a warm light.
function MapKit.lamp(ctx, pos, colour, range)
	local p = MapKit.part(ctx, { Name = "Lamp", Size = Vector3.new(0.8, 1.2, 0.8), CFrame = CFrame.new(pos), Color = colour or { 255, 200, 120 }, Material = "Neon", CanCollide = false })
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness = p.Color, range or 22, 1.6
	light.Parent = p
	return p
end

-- Loose straws scattered on the floor: the haystack's busyness. Half land near hiding spots,
-- so a needle never sits alone on bare ground. They can't be clicked or stood on.
function MapKit.clutter(ctx, count, halfX, halfZ)
	local straw = ctx.def.straw
	for i = 1, count do
		local pos
		if i % 2 == 0 and #ctx.spots > 0 then
			local s = ctx.spots[ctx.rng:NextInteger(1, #ctx.spots)].cf.Position
			pos = s + Vector3.new((ctx.rng:NextNumber() - 0.5) * 5, 0, (ctx.rng:NextNumber() - 0.5) * 5)
		else
			pos = MapKit.at(ctx, (ctx.rng:NextNumber() * 2 - 1) * halfX, 0, (ctx.rng:NextNumber() * 2 - 1) * halfZ)
		end
		local shade = 0.75 + ctx.rng:NextNumber() * 0.4
		MapKit.part(ctx, { Name = "Straw", Size = Vector3.new(0.12, 0.08, 0.8 + ctx.rng:NextNumber() * 1.4), CFrame = CFrame.new(pos + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, ctx.rng:NextNumber() * math.pi * 2, 0),
			Color = Color3.fromRGB(math.min(255, straw[1] * shade), math.min(255, straw[2] * shade), math.min(255, straw[3] * shade)), Material = "SmoothPlastic", CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
	end
end

-- Hay bundles that drift slowly to and fro and turn (Hard rounds). They can't be clicked.
function MapKit.moving(ctx, count, halfX, halfZ)
	for _ = 1, count do
		local from = MapKit.at(ctx, (ctx.rng:NextNumber() * 2 - 1) * halfX, 1.2, (ctx.rng:NextNumber() * 2 - 1) * halfZ)
		local bundle = MapKit.part(ctx, { Name = "Tumble", Shape = "Ball", Size = Vector3.one * 2.4, CFrame = CFrame.new(from), Color = ctx.def.straw, Material = "Grass", CanCollide = false, CanQuery = false, CanTouch = false })
		local to = from + Vector3.new((ctx.rng:NextNumber() - 0.5) * 30, 0, (ctx.rng:NextNumber() - 0.5) * 30)
		TweenService:Create(bundle, TweenInfo.new(6 + ctx.rng:NextNumber() * 4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { CFrame = CFrame.new(to) * CFrame.Angles(0, math.pi, math.pi) }):Play()
	end
end

return MapKit

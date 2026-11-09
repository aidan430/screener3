-- The lobby's dressing (LobbyBuilder calls build once): a lawn crossed by cobbled paths (spawn to
-- the Champion, the Play pad and the Hall; a cross path to the boards; walks along the booths), two
-- spool fountains by the spawn, flower beds, lamp posts along the paths, trees along the hedge and
-- a hay yard of real haystacks behind the title sign. Nothing here does anything; it's to look at.
local MapKit = require(script.Parent.MapKit)

local LobbyDecor = {}

local STONE = { 196, 182, 154 }
local FLOWERS = { { 240, 90, 110 }, { 255, 200, 70 }, { 250, 248, 240 }, { 170, 110, 240 }, { 255, 140, 60 } }

-- Paths: { x, z, width (x), length (z) } just above the lawn.
local PATHS = {
	{ 0, 18, 14, 124 }, -- the avenue: spawn, Champion, stalls, Play pad, Hall
	{ 0, -8, 120, 10 }, -- the cross path to the boards
	{ 0, 62, 112, 8 }, -- the front path to the booths
	{ -59, 0, 8, 116 }, { 59, 0, 8, 116 }, -- walks along the booths
	{ 0, -26, 40, 20 }, -- the Hall's square
}
local BEDS = { { -12, 62, 6, 10 }, { 12, 62, 6, 10 }, { -12, 40, 6, 8 }, { 12, 40, 6, 8 }, { -46, -36, 10, 6 }, { 46, -36, 10, 6 }, { -46, 16, 10, 6 }, { 46, 16, 10, 6 }, { -40, 82, 12, 4 }, { 40, 82, 12, 4 } }
local LAMPS = { { -9, 76 }, { 9, 76 }, { -9, 54 }, { 9, 54 }, { -9, 36 }, { 9, 36 }, { -9, -40 }, { 9, -40 }, { -20, -14 }, { 20, -14 }, { -50, -14 }, { 50, -14 }, { -54, 40 }, { 54, 40 }, { -54, -40 }, { 54, -40 } }
local FOUNTAINS = { { -40, 72, { 196, 64, 50 } }, { 40, 72, { 76, 106, 170 } } }
local HAYSTACKS = { { -48, -70, 7, 12 }, { 48, -72, 7, 12 }, { -76, -78, 5, 9 }, { 76, -76, 5, 9 }, { -22, -78, 5, 8 }, { 24, -79, 5, 8 } }

local function upright(x, y, z, length, diameter)
	return CFrame.new(x, y, z) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(length, diameter, diameter)
end

local function bed(ctx, x, z, w, d)
	local c = MapKit.at(ctx, x, 0, z)
	MapKit.part(ctx, { Name = "Planter", Size = Vector3.new(w, 0.9, d), CFrame = CFrame.new(c + Vector3.new(0, 0.45, 0)), Color = { 120, 84, 50 }, Material = "WoodPlanks" })
	MapKit.part(ctx, { Name = "Soil", Size = Vector3.new(w - 0.6, 0.1, d - 0.6), CFrame = CFrame.new(c + Vector3.new(0, 0.95, 0)), Color = { 90, 62, 40 }, Material = "Ground", CanCollide = false })
	for i = 1, math.floor(w * d / 2) do
		local p = c + Vector3.new((ctx.rng:NextNumber() - 0.5) * (w - 1.2), 1.15, (ctx.rng:NextNumber() - 0.5) * (d - 1.2))
		MapKit.part(ctx, { Name = "Flower", Shape = "Ball", Size = Vector3.one * 0.6, CFrame = CFrame.new(p), Color = FLOWERS[(i - 1) % #FLOWERS + 1], Material = "SmoothPlastic", CanCollide = false })
	end
end

local function lampPost(ctx, x, z)
	local base = MapKit.at(ctx, x, 0, z)
	local cf, size = upright(base.X, base.Y + 4.5, base.Z, 9, 0.5)
	MapKit.part(ctx, { Name = "LampPost", Shape = "Cylinder", Size = size, CFrame = cf, Color = { 60, 56, 52 }, Material = "Metal" })
	MapKit.lamp(ctx, base + Vector3.new(0, 9.5, 0), { 255, 210, 140 }, 18)
	MapKit.part(ctx, { Name = "LampCap", Size = Vector3.new(1.4, 0.3, 1.4), CFrame = CFrame.new(base + Vector3.new(0, 10.25, 0)), Color = { 60, 56, 52 }, Material = "Metal" })
end

-- A fountain with a giant spool of thread in the middle and a needle stuck through it.
local function fountain(ctx, x, z, thread)
	local c = MapKit.at(ctx, x, 0, z)
	local cf, size = upright(c.X, c.Y + 0.8, c.Z, 1.6, 14)
	MapKit.part(ctx, { Name = "Basin", Shape = "Cylinder", Size = size, CFrame = cf, Color = { 226, 220, 206 }, Material = "Marble" })
	cf, size = upright(c.X, c.Y + 1.55, c.Z, 0.2, 12.6)
	MapKit.part(ctx, { Name = "Water", Shape = "Cylinder", Size = size, CFrame = cf, Color = { 110, 180, 220 }, Material = "Glass", Transparency = 0.25, CanCollide = false })
	for _, y in ipairs({ 2.0, 8.2 }) do
		cf, size = upright(c.X, c.Y + y, c.Z, 0.8, 5)
		MapKit.part(ctx, { Name = "SpoolEnd", Shape = "Cylinder", Size = size, CFrame = cf, Color = { 150, 106, 64 }, Material = "Wood" })
	end
	cf, size = upright(c.X, c.Y + 5.1, c.Z, 5.4, 3.6)
	local spool = MapKit.part(ctx, { Name = "Thread", Shape = "Cylinder", Size = size, CFrame = cf, Color = thread, Material = "Fabric" })
	MapKit.part(ctx, { Name = "SpoolNeedle", Shape = "Cylinder", Size = Vector3.new(8, 0.35, 0.35), CFrame = CFrame.new(c + Vector3.new(0.6, 7.4, 0)) * CFrame.Angles(0, math.rad(30), math.rad(55)), Color = { 210, 214, 224 }, Material = "Metal", CanCollide = false })
	local spray = Instance.new("ParticleEmitter") -- a soft spray falling off the spool into the basin
	spray.Rate, spray.Lifetime, spray.Speed, spray.SpreadAngle = 30, NumberRange.new(1, 1.4), NumberRange.new(6, 8), Vector2.new(30, 30)
	spray.Acceleration, spray.Transparency = Vector3.new(0, -24, 0), NumberSequence.new(0.3, 1)
	spray.Size, spray.Color = NumberSequence.new(0.35, 0.1), ColorSequence.new(Color3.fromRGB(200, 230, 255))
	local top = Instance.new("Attachment")
	top.Position = Vector3.new(3.4, 0, 0) -- the spool's top (the cylinder's axis is its X)
	top.Parent = spool
	spray.Parent = top
end

function LobbyDecor.build(ctx)
	for _, p in ipairs(PATHS) do
		MapKit.part(ctx, { Name = "Path", Size = Vector3.new(p[3], 0.12, p[4]), CFrame = CFrame.new(MapKit.at(ctx, p[1], 0.44, p[2])), Color = STONE, Material = "Cobblestone" })
	end
	local pad = MapKit.at(ctx, 0, 0.46, 6)
	local cf, size = upright(pad.X, pad.Y, pad.Z, 0.12, 32) -- the round paving under the Play pad
	MapKit.part(ctx, { Name = "PadPaving", Shape = "Cylinder", Size = size, CFrame = cf, Color = STONE, Material = "Cobblestone" })
	for _, b in ipairs(BEDS) do
		bed(ctx, b[1], b[2], b[3], b[4])
	end
	for _, l in ipairs(LAMPS) do
		lampPost(ctx, l[1], l[2])
	end
	for _, f in ipairs(FOUNTAINS) do
		fountain(ctx, f[1], f[2], f[3])
	end
	for _, side in ipairs({ -80, 80 }) do -- a row of trees behind each line of booths
		for z = -60, 60, 20 do
			MapKit.tree(ctx, side, z, 13 + ctx.rng:NextNumber() * 4)
		end
	end
	for _, t in ipairs({ { -78, 80 }, { 78, 80 }, { -60, -84 }, { 60, -84 } }) do
		MapKit.tree(ctx, t[1], t[2], 14)
	end
	for _, h in ipairs(HAYSTACKS) do -- the hay yard behind the title sign
		MapKit.haystack(ctx, h[1], h[2], h[3], h[4])
	end
	for _, b in ipairs({ { -36, -74 }, { 36, -76 }, { -60, -70 }, { 62, -66 } }) do
		MapKit.bale(ctx, b[1], 0, b[2], ctx.rng:NextNumber() * 3)
	end
end

return LobbyDecor

-- A low split-rail fence round each plot, just outside its edge, with a gap at the corner
-- nearest the hub (the plot entrance, where players arrive). A lantern and a few small hay
-- bales stand by the gap. Everything sits on the 1-3 stud border outside the plot, so the
-- plot itself stays free to build on. The road sides are walk-through (step onto your plot
-- anywhere); only the outer sides, facing the countryside, are solid. See Scenery.
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local Kit = require(script.Parent.SceneryKit)

local PlotFences = {}
local C = Kit.C
local part, bit = Kit.part, Kit.bit
local ORIGIN = CFrame.new()
local OUT = 1.2 -- the fence line, this far outside the plot's edge
local GAP = 16 -- the entrance: no fence this far along each edge from the hub corner
local POST_STEP = 8

-- One straight run of fence from a to b (world points on the ground).
local function run(m, a, b, solid)
	local length = (b - a).Magnitude
	local n = math.max(1, math.floor(length / POST_STEP + 0.5))
	for i = 0, n do
		local at = a:Lerp(b, i / n)
		part(m, ORIGIN, "RailPost", Vector3.new(0.6, 3.2, 0.6), at + Vector3.new(0, 1.6, 0), C.darkWood, "Wood", { collide = solid, shadow = false })
	end
	local mid = (a + b) / 2
	for k, y in ipairs({ 1.2, 2.5 }) do
		-- split rails: each one a touch askew, as if laid by hand
		local tilt = CFrame.Angles(0, 0, math.rad(if k == 1 then 4 else -3))
		part(m, ORIGIN, "SplitRail", Vector3.new(0.35, 0.35, length), CFrame.lookAt(mid + Vector3.new(0, y, 0), b + Vector3.new(0, y, 0)) * tilt, C.wood, "Wood", { collide = solid, shadow = false })
	end
end

-- A small square bale lying along the border.
local function bale(m, at, alongX, high)
	local size = if alongX then Vector3.new(2.4, 1.3, 1.4) else Vector3.new(1.4, 1.3, 2.4)
	part(m, ORIGIN, "SmallBale", size, at + Vector3.new(0, 0.65 + (if high then 1.3 else 0), 0), C.hay, "Fabric", { collide = false })
	bit(m, ORIGIN, "BaleTwine", size + (if alongX then Vector3.new(-1.6, 0.05, 0.05) else Vector3.new(0.05, 0.05, -1.6)), at + Vector3.new(0, 0.65 + (if high then 1.3 else 0), 0), { 150, 104, 60 }, "Fabric")
end

local function plotFence(folder, index, centre)
	local m = Kit.model(folder, "PlotFence" .. index)
	local sx, sz = math.sign(centre.X), math.sign(centre.Z)
	local half = Config.PlotSize / 2
	local inX, outX = centre.X - sx * (half + OUT), centre.X + sx * (half + OUT) -- road side, far side
	local inZ, outZ = centre.Z - sz * (half + OUT), centre.Z + sz * (half + OUT)
	local cornerX, cornerZ = centre.X - sx * half, centre.Z - sz * half -- the hub corner
	run(m, Vector3.new(inX, 0, cornerZ + sz * GAP), Vector3.new(inX, 0, outZ), false)
	run(m, Vector3.new(cornerX + sx * GAP, 0, inZ), Vector3.new(outX, 0, inZ), false)
	run(m, Vector3.new(outX, 0, inZ), Vector3.new(outX, 0, outZ), true)
	run(m, Vector3.new(inX, 0, outZ), Vector3.new(outX, 0, outZ), true)
	-- the entrance: a lantern on the last post by the north/south road, bales just past it
	Kit.lantern(m, CFrame.new(inX, 0, cornerZ + sz * GAP), 4.5)
	local bx = centre.X - sx * (half + 2.2)
	bale(m, Vector3.new(bx, 0, cornerZ + sz * (GAP + 2)), false, false)
	bale(m, Vector3.new(bx, 0, cornerZ + sz * (GAP + 4.6)), false, false)
	bale(m, Vector3.new(bx, 0, cornerZ + sz * (GAP + 3.3)), false, true)
	-- (nothing extra on the east/west road side: the middle of those roads, |z| < 13, stays clear)
end

function PlotFences.build(folder)
	local m = Kit.model(folder, "PlotFences")
	for index, c in ipairs(Config.PlotCentres) do
		plotFence(m, index, Vector3.new(c[1], 0, c[2]))
	end
end

return PlotFences

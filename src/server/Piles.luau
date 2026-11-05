-- Each player's 70 m pile: 5,000 clumps of 1,000 straws on their plot, built from their save
-- (harvested clumps stay gone). Harvesting a clump to nothing removes it; the needle is in one.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))(Config)
local Layout = require(Shared:WaitForChild("Layout"))(Config)

local HayLook = require(Shared:WaitForChild("HayLook"))(Config)
local Plots = require(script.Parent.Plots)
local Profile = require(script.Parent.Profile)

local Piles = {}
local piles = {} -- [plot index] = { folder, origin = Vector3 }
local cursor = setmetatable({}, { __mode = "k" }) -- [data] = where the machines got to in machineOrder
local terrain = workspace.Terrain
local HEAP = Enum.Material.Grass -- recoloured to straw; its grass blades read as loose straw
local STEPS = 8 -- a clump shrinks in this many visible steps as you harvest it

local function setup()
	local c = if Config.HayTexture ~= "" then Config.HayTint else Config.HeapColour
	terrain:SetMaterialColor(HEAP, Color3.fromRGB(c[1], c[2], c[3]))
	pcall(function()
		terrain.Decoration = true -- the grass blades: individual straws on the heap
	end)
end

local function origin(plotIndex)
	local centre = Plots.centre(plotIndex)
	local x, z = Layout.origin(centre.X, centre.Z)
	return Vector3.new(x, 0, z)
end

-- How full a clump's terrain cell looks: the heap's rounded outside, shrinking as it's harvested.
local function fullness(index, left)
	if left <= 0 then
		return 0
	end
	local step = math.ceil(left / Economy.STRAWS_PER_CLUMP * STEPS) / STEPS
	return Layout.shape[index] * (0.3 + 0.7 * step)
end

local function writeCell(plotIndex, index, left)
	local o = piles[plotIndex] and piles[plotIndex].origin
	if not o then
		return
	end
	local c = o + Vector3.new(Layout[index][1], Layout[index][2], Layout[index][3])
	local half = Vector3.new(1, 1, 1) * (Config.ClumpSize / 2)
	local amount = fullness(index, left)
	terrain:WriteVoxels(Region3.new(c - half, c + half), Config.ClumpSize, { { { if amount > 0 then HEAP else Enum.Material.Air } } }, { { { amount } } })
end

function Piles.position(plotIndex, clump)
	local c = Layout[clump]
	return origin(plotIndex) + Vector3.new(c[1], c[2], c[3])
end

-- The clump nearest a point on (or just inside) the heap's surface, if one is left there.
function Piles.clumpAt(plotIndex, d, point)
	local o = origin(plotIndex)
	local s = Config.ClumpSize
	local gx, layer, gz = math.floor((point.X - o.X) / s + 0.5), math.floor(point.Y / s), math.floor((point.Z - o.Z) / s + 0.5)
	local best, bestDistance = nil, math.huge
	for dx = -1, 1 do
		for dy = -1, 1 do
			for dz = -1, 1 do
				local index = Layout.lookup(gx + dx, layer + dy, gz + dz)
				if index and Profile.clumpLeft(d, index) > 0 then
					local distance = (Piles.position(plotIndex, index) - point).Magnitude
					if distance < bestDistance then
						best, bestDistance = index, distance
					end
				end
			end
		end
	end
	return best
end

-- Builds the player's heap on their plot from their data, as one smooth piece of terrain.
function Piles.build(plotIndex, d)
	setup()
	local folder = Instance.new("Folder")
	folder.Name = "Pile"
	folder.Parent = Plots.folder(plotIndex)
	local o = origin(plotIndex)
	piles[plotIndex] = { folder = folder, origin = o }
	local s = Config.ClumpSize
	local n = math.ceil(Config.PileRadiusBottom / s) + 1
	local materials, amounts = {}, {}
	for x = 1, 2 * n + 1 do
		materials[x], amounts[x] = {}, {}
		for y = 1, Config.PileLayers do
			materials[x][y], amounts[x][y] = {}, {}
			for z = 1, 2 * n + 1 do
				materials[x][y][z], amounts[x][y][z] = Enum.Material.Air, 0
			end
		end
	end
	for index, cell in ipairs(Layout.cell) do
		local amount = fullness(index, Profile.clumpLeft(d, index))
		if amount > 0 then
			local x, y, z = cell[1] + n + 1, cell[2] + 1, cell[3] + n + 1
			materials[x][y][z], amounts[x][y][z] = HEAP, amount
		end
	end
	local corner = o - Vector3.new(n * s + s / 2, 0, n * s + s / 2)
	terrain:WriteVoxels(Region3.new(corner, corner + Vector3.new((2 * n + 1) * s, Config.PileLayers * s, (2 * n + 1) * s)), s, materials, amounts)
	-- loose hay mounds spilled round the foot of the heap, so it sits in its own straw
	local rng = Random.new(plotIndex)
	for i = 1, Config.HeapMounds do
		local angle = (i / Config.HeapMounds + rng:NextNumber() * 0.05) * math.pi * 2
		local reach = Config.PileRadiusBottom + rng:NextNumber(1, 3)
		local mound = HayLook.lump(rng:NextNumber(4, 7), false)
		mound.Anchored = true
		mound.CFrame = CFrame.new(o + Vector3.new(math.cos(angle) * reach, 0.6, math.sin(angle) * reach)) * CFrame.Angles(0, rng:NextNumber() * 6.28, 0)
		mound.Parent = folder
	end
	return piles[plotIndex]
end

-- Clears a plot's heap from the terrain (when its player leaves).
function Piles.clear(plotIndex)
	local o = origin(plotIndex)
	local reach = (math.ceil(Config.PileRadiusBottom / Config.ClumpSize) + 1) * Config.ClumpSize + Config.ClumpSize / 2
	terrain:FillBlock(CFrame.new(o + Vector3.new(0, Config.PileLayers * Config.ClumpSize / 2, 0)), Vector3.new(reach * 2, Config.PileLayers * Config.ClumpSize, reach * 2), Enum.Material.Air)
	piles[plotIndex] = nil
end

-- Takes up to `amount` straws from a clump. Returns straws taken and whether the clump
-- (and so maybe the needle) is now gone.
function Piles.take(plotIndex, d, clump, amount)
	local left = Profile.clumpLeft(d, clump)
	local taken = math.min(amount, left)
	if taken <= 0 then
		return 0, false
	end
	Profile.setClumpLeft(d, clump, left - taken)
	if fullness(clump, left - taken) ~= fullness(clump, left) then
		writeCell(plotIndex, clump, left - taken)
	end
	return taken, left - taken <= 0
end

-- The next clump for the machines: they peel the heap from the outside in, bottom first.
function Piles.next(d)
	local order = Layout.machineOrder
	local i = cursor[d] or 1
	while i <= #order and string.sub(d.removed, order[i], order[i]) == "1" do
		i += 1
	end
	cursor[d] = i
	return order[i]
end

-- A fresh pile for a new needle, in the saved data (do this straight away).
function Piles.resetData(d)
	d.removed = string.rep("0", Config.Clumps)
	d.partial = {}
	d.needleClump = Profile.newNeedle()
	d.revealed = false
	cursor[d] = nil
end

-- Rebuilds the heap from the data (after resetData).
function Piles.rebuild(plotIndex, d)
	local pile = piles[plotIndex]
	if pile then
		pile.folder:Destroy()
	end
	Piles.build(plotIndex, d)
end

return Piles

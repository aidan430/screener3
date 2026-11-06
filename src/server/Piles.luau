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
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local HeapTerrain = require(Shared:WaitForChild("HeapTerrain"))(Config)

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

-- Every player's haystack stands in the same place, so each player's screen draws only its own
-- (client/PileView.luau): the server sends it the whole heap on joining and each changed clump.
local function send(plotIndex, message)
	local owner = Plots.owner(plotIndex)
	if owner then
		Remotes.PileSync:FireClient(owner, message)
	end
end

function Piles.sync(plotIndex)
	local pile = piles[plotIndex]
	if pile and pile.data then
		send(plotIndex, { kind = "full", removed = pile.data.removed, partial = pile.data.partial })
	end
end

local function writeCell(plotIndex, index, left)
	send(plotIndex, { kind = "cell", index = index, left = left })
end

function Piles.position(plotIndex, clump)
	local c = Layout[clump]
	return origin(plotIndex) + Vector3.new(c[1], c[2], c[3])
end

-- True if a clump is on the surface: started already, or next to open air (an emptied clump
-- or the outside of the heap). Players can't dig into the middle without digging their way in.
function Piles.exposed(d, index)
	if d.partial[tostring(index)] then
		return true
	end
	local c = Layout.cell[index]
	for _, o in ipairs({ { 1, 0, 0 }, { -1, 0, 0 }, { 0, 1, 0 }, { 0, -1, 0 }, { 0, 0, 1 }, { 0, 0, -1 } }) do
		local layer = c[2] + o[2]
		if layer >= 0 then -- the ground under the bottom layer isn't open air
			local next = Layout.lookup(c[1] + o[1], layer, c[3] + o[3])
			if not next or Profile.clumpLeft(d, next) <= 0 then
				return true
			end
		end
	end
	return false
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
				if index and Profile.clumpLeft(d, index) > 0 and Piles.exposed(d, index) then
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
	folder:SetAttribute("Owner", Plots.owner(plotIndex) and Plots.owner(plotIndex).UserId or 0)
	piles[plotIndex].data = d
	Piles.sync(plotIndex)
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

-- Forgets a plot's heap (when its player leaves; their screen drew it, nobody else's did).
function Piles.clear(plotIndex)
	piles[plotIndex] = nil
end

-- Straws left in a clump.
function Piles.left(d, clump)
	return Profile.clumpLeft(d, clump)
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
	if HeapTerrain.fullness(clump, left - taken) ~= HeapTerrain.fullness(clump, left) then
		writeCell(plotIndex, clump, left - taken)
	end
	return taken, left - taken <= 0
end

-- The next clump for the machines: they peel the heap from the outside in, bottom first.
function Piles.init()
	local asked = {}
	Remotes.PileSync.OnServerEvent:Connect(function(player) -- the screen asks once it's ready
		local plotIndex = Plots.of(player)
		if plotIndex and os.clock() - (asked[player] or -10) >= 3 then -- the whole heap at most every 3 s
			asked[player] = os.clock()
			Piles.sync(plotIndex)
		end
	end)
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		asked[player] = nil
	end)
end

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

-- Each player's 70 m pile: 5,000 clumps of 1,000 straws on their plot, built from their save
-- (harvested clumps stay gone). Harvesting a clump to nothing removes it; the needle is in one.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))(Config)
local Layout = require(Shared:WaitForChild("Layout"))(Config)

local Plots = require(script.Parent.Plots)
local Profile = require(script.Parent.Profile)

local Piles = {}
local piles = {} -- [plot index] = { folder, parts = { [clump index] = part }, base = Vector3 }

local HAY = {
	Color3.fromRGB(226, 190, 92),
	Color3.fromRGB(212, 172, 76),
	Color3.fromRGB(236, 204, 112),
	Color3.fromRGB(220, 182, 84),
}

local function shade(index)
	return HAY[(index * 7919) % #HAY + 1]
end

-- A partly harvested clump shrinks a little, so you can see your progress on it.
local function sizeFor(left)
	local s = Config.ClumpSize + 0.3
	local k = 0.6 + 0.4 * left / Economy.STRAWS_PER_CLUMP
	return Vector3.new(s * k, s * k, s * k)
end

function Piles.position(plotIndex, clump)
	local c = Layout[clump]
	return Plots.centre(plotIndex) + Vector3.new(c[1], c[2], c[3])
end

-- Builds the player's pile on their plot from their data. Yields a little between batches.
function Piles.build(plotIndex, d)
	local folder = Instance.new("Folder")
	folder.Name = "Pile"
	folder.Parent = Plots.folder(plotIndex)
	local pile = { folder = folder, parts = {} }
	piles[plotIndex] = pile
	for index = 1, #Layout do
		local left = Profile.clumpLeft(d, index)
		if left > 0 then
			local part = Instance.new("Part")
			part.Name = tostring(index)
			part.Anchored = true
			part.Size = sizeFor(left)
			part.CFrame = CFrame.new(Piles.position(plotIndex, index))
			part.Color = shade(index)
			part.Material = Enum.Material.Grass
			part.CastShadow = false
			part.TopSurface = Enum.SurfaceType.Smooth
			part.BottomSurface = Enum.SurfaceType.Smooth
			part:SetAttribute("Clump", index)
			part.Parent = folder
			pile.parts[index] = part
		end
		if index % 400 == 0 then
			task.wait()
		end
	end
	return pile
end

-- The part for a clump on a plot, if it still exists.
function Piles.part(plotIndex, clump)
	local pile = piles[plotIndex]
	return pile and pile.parts[clump]
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
	local part = Piles.part(plotIndex, clump)
	if part then
		if left - taken <= 0 then
			piles[plotIndex].parts[clump] = nil
			part:Destroy()
		else
			part.Size = sizeFor(left - taken)
		end
	end
	return taken, left - taken <= 0
end

-- The highest clump still standing (machines harvest the pile from the top down).
function Piles.top(d)
	for index = Config.Clumps, 1, -1 do
		if string.sub(d.removed, index, index) == "0" then
			return index
		end
	end
	return nil
end

-- A fresh pile for a new needle: every clump back.
function Piles.reset(plotIndex, d)
	d.removed = string.rep("0", Config.Clumps)
	d.partial = {}
	d.needleClump = Profile.newNeedle()
	d.revealed = false
	local pile = piles[plotIndex]
	if pile then
		pile.folder:Destroy()
		piles[plotIndex] = nil
	end
	task.spawn(Piles.build, plotIndex, d)
end

function Piles.forget(plotIndex)
	piles[plotIndex] = nil
end

return Piles

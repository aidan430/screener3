-- The four plots around the hub. A player gets a free plot when they join and gives it
-- back when they leave; their pile and buildings are rebuilt from their save each visit.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local Build = require(script.Parent.Build)

local Plots = {}
local owners = {} -- [plot index] = player
local byPlayer = {} -- [player] = plot index
local signs = {} -- [plot index] = TextLabel

function Plots.centre(index)
	local c = Config.PlotCentres[index]
	return Vector3.new(c[1], 0, c[2])
end

function Plots.folder(index)
	return workspace:WaitForChild("Plots"):WaitForChild("Plot" .. index)
end

function Plots.of(player)
	return byPlayer[player]
end

function Plots.owner(index)
	return owners[index]
end

-- True if `position` is on the plot (with a margin inside the edge), at a sensible height.
function Plots.contains(index, position, margin)
	local centre, half = Plots.centre(index), Config.PlotSize / 2 - (margin or 0)
	return math.abs(position.X - centre.X) <= half and math.abs(position.Z - centre.Z) <= half and position.Y >= -2 and position.Y <= 320
end

-- Where a player arrives on their plot: the corner nearest the hub.
function Plots.entrance(index)
	local centre = Plots.centre(index)
	return centre - centre.Unit * (Config.PlotSize / 2 - 6) + Vector3.new(0, 4, 0)
end

function Plots.build()
	local root = Instance.new("Folder")
	root.Name = "Plots"
	root.Parent = workspace
	for index in ipairs(Config.PlotCentres) do
		local folder = Instance.new("Folder")
		folder.Name = "Plot" .. index
		folder:SetAttribute("Index", index)
		folder.Parent = root
		local centre = Plots.centre(index)
		local half = Config.PlotSize / 2
		Build.part({ name = "Ground", size = Vector3.new(Config.PlotSize, 1, Config.PlotSize), cframe = CFrame.new(centre + Vector3.new(0, -0.45, 0)), color = { 124, 140, 66 }, material = "LeafyGrass", parent = folder })
		for _, side in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
			local edge = centre + Vector3.new(side[1] * half, 0.3, side[2] * half)
			local size = if side[1] ~= 0 then Vector3.new(1, 0.6, Config.PlotSize) else Vector3.new(Config.PlotSize, 0.6, 1)
			Build.part({ name = "Edge", size = size, cframe = CFrame.new(edge), color = { 150, 110, 70 }, material = "WoodPlanks", parent = folder })
		end
		local corner = centre - centre.Unit * (half - 2)
		local sign = Build.part({ name = "PlotSign", size = Vector3.new(12, 3, 0.4), cframe = CFrame.lookAt(corner + Vector3.new(0, 7, 0), Vector3.new(0, 7, 0)), color = { 246, 234, 204 }, material = "WoodPlanks", parent = folder })
		Build.post({ name = "SignPost", color = { 122, 86, 52 }, material = "Wood", parent = folder }, CFrame.new(corner), 5.5, 0.6)
		signs[index] = Build.text(sign, Enum.NormalId.Front, "FREE PLOT")
		Build.text(sign, Enum.NormalId.Back, "PLOT " .. index)
	end
end

-- Gives the player a free plot. Returns its index, or nil if all four are taken.
function Plots.claim(player)
	for index in ipairs(Config.PlotCentres) do
		if not owners[index] then
			owners[index] = player
			byPlayer[player] = index
			signs[index].Text = player.DisplayName .. "'s farm"
			return index
		end
	end
	return nil
end

Plots.onRelease = nil -- set by Main: clears the heap's terrain
function Plots.release(player)
	local index = byPlayer[player]
	if index then
		if Plots.onRelease then
			Plots.onRelease(index)
		end
		owners[index] = nil
		byPlayer[player] = nil
		signs[index].Text = "FREE PLOT"
		for _, child in ipairs(Plots.folder(index):GetChildren()) do
			if child.Name == "Pile" or child.Name == "Built" then
				child:Destroy()
			end
		end
	end
end

function Plots.init()
	Players.PlayerRemoving:Connect(Plots.release)
end

return Plots

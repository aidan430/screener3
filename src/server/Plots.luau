-- The four plots. They all share the middle of the farm: a player gets a free plot (an index)
-- when they join and gives it back when they leave; their haystack and buildings are rebuilt
-- from their save each visit. Each plot has a collision group, and groups don't collide with
-- each other, so players' buildings, hay and characters pass through other players' (each
-- player's screen also hides other players' plots: see client/OnlyMine.luau).
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local Plots = {}
local owners = {} -- [plot index] = player
local byPlayer = {} -- [player] = plot index

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

-- Where a player arrives: south of the haystack, facing it.
function Plots.entrance(index)
	local e = Config.FarmEntrance
	return Plots.centre(index) + Vector3.new(e[1], e[2] + 4, e[3])
end

function Plots.group(index)
	return "Plot" .. index
end

-- Puts a part (and everything later added under `root`) in the plot's collision group.
function Plots.tag(root, index)
	local group = Plots.group(index)
	local function set(part)
		if part:IsA("BasePart") then
			part.CollisionGroup = group
		end
	end
	set(root)
	for _, part in ipairs(root:GetDescendants()) do
		set(part)
	end
	return root.DescendantAdded:Connect(set)
end

function Plots.build()
	local root = Instance.new("Folder")
	root.Name = "Plots"
	root.Parent = workspace
	for _, name in ipairs({ "Lobby", "Plot1", "Plot2", "Plot3", "Plot4" }) do
		pcall(function()
			PhysicsService:RegisterCollisionGroup(name)
		end)
	end
	for index in ipairs(Config.PlotCentres) do
		for other in ipairs(Config.PlotCentres) do
			if other ~= index then
				PhysicsService:CollisionGroupSetCollidable(Plots.group(index), Plots.group(other), false)
			end
		end
		-- a player who hasn't got a plot yet (still loading) passes through every farm too
		PhysicsService:CollisionGroupSetCollidable("Lobby", Plots.group(index), false)
		local folder = Instance.new("Folder")
		folder.Name = "Plot" .. index
		folder:SetAttribute("Index", index)
		folder.Parent = root
		Plots.tag(folder, index)
	end
end

-- Gives the player a free plot. Returns its index, or nil if all four are taken.
function Plots.claim(player)
	for index in ipairs(Config.PlotCentres) do
		if not owners[index] then
			owners[index] = player
			byPlayer[player] = index
			-- the player's character goes in their plot's group, every time it spawns
			local function tagCharacter(character)
				Plots.tag(character, index)
			end
			if player.Character then
				tagCharacter(player.Character)
			end
			player.CharacterAdded:Connect(function(character)
				if byPlayer[player] == index then
					tagCharacter(character)
				end
			end)
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
		for _, child in ipairs(Plots.folder(index):GetChildren()) do
			if child.Name == "Pile" or child.Name == "Built" or child.Name == "Loose" then -- loose straws are saved
				child:Destroy()
			end
		end
	end
end

function Plots.init()
	Players.PlayerRemoving:Connect(Plots.release)
	-- until their data loads and they get a plot, a new player's character is in the Lobby group
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			if not byPlayer[player] then
				for _, part in ipairs(character:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CollisionGroup = "Lobby"
					end
				end
			end
		end)
	end)
end

return Plots

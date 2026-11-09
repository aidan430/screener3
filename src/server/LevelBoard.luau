-- The Top Farmers board beside where you arrive (Config.LevelBoard): a wooden sign listing the
-- highest Farmer Levels across every server, from an OrderedDataStore. Levels are written when a
-- player leaves and every refresh while they play. If the store can't be reached (Studio without
-- API access), it lists the farmers in this server instead.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local LevelBoard = {}
local B = Config.LevelBoard
local store = nil
local lines = {}

local function part(props)
	local p = Instance.new("Part")
	p.Anchored, p.TopSurface, p.BottomSurface = true, Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	return p
end

local function build()
	local model = Instance.new("Model")
	model.Name = "TopFarmers"
	local base = CFrame.new(B.at[1], 0, B.at[2]) * CFrame.Angles(0, math.rad(35), 0) -- its face (Back) turned towards where you arrive
	local wood = Color3.fromRGB(120, 84, 48)
	for _, x in ipairs({ -8, 8 }) do -- just outside the board, so they never cover the list
		part({ Name = "Post", Size = Vector3.new(1, 18, 1), CFrame = base * CFrame.new(x, 9, 0), Color = wood, Material = Enum.Material.Wood, Parent = model })
	end
	local board = part({ Name = "Board", Size = Vector3.new(15, 13, 0.6), CFrame = base * CFrame.new(0, 10.5, 0), Color = Color3.fromRGB(150, 108, 64), Material = Enum.Material.WoodPlanks, Parent = model })
	part({ Name = "Roof", Size = Vector3.new(18, 0.6, 2.4), CFrame = base * CFrame.new(0, 18.3, 0), Color = Color3.fromRGB(92, 60, 36), Material = Enum.Material.Wood, Parent = model })
	local gui = Instance.new("SurfaceGui")
	gui.Face, gui.SizingMode, gui.PixelsPerStud, gui.LightInfluence = Enum.NormalId.Back, Enum.SurfaceGuiSizingMode.PixelsPerStud, 40, 0.2
	gui.Parent = board
	local paper = Instance.new("Frame")
	paper.Size, paper.Position = UDim2.new(1, -40, 1, -40), UDim2.fromOffset(20, 20)
	paper.BackgroundColor3 = Color3.fromRGB(244, 232, 204)
	paper.Parent = gui
	local function text(y, h, size, colour, font)
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency, label.Size, label.Position = 1, UDim2.new(1, -40, 0, h), UDim2.fromOffset(20, y)
		label.Font, label.TextSize, label.TextColor3 = font or Enum.Font.Merriweather, size, colour
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = paper
		return label
	end
	local title = text(10, 56, 46, Color3.fromRGB(60, 40, 22), Enum.Font.Merriweather)
	title.Text, title.TextXAlignment = "TOP FARMERS", Enum.TextXAlignment.Center
	for i = 1, B.rows do
		lines[i] = text(70 + (i - 1) * 40, 38, 30, if i <= 3 then Color3.fromRGB(176, 120, 20) else Color3.fromRGB(70, 52, 36))
	end
	model.Parent = workspace
end

local function show(rows)
	for i = 1, B.rows do
		local r = rows[i]
		lines[i].Text = if r then i .. ".  " .. r.name .. "  ·  Level " .. r.level else ""
	end
end

local function nameOf(userId)
	local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
	return if ok then name else "Farmer"
end

local names = {}
local function refresh()
	if store then
		local ok, pages = pcall(store.GetSortedAsync, store, false, B.rows)
		if ok and pages then
			local rows = {}
			for _, entry in ipairs(pages:GetCurrentPage()) do
				local id = tonumber(entry.key)
				names[id] = names[id] or nameOf(id)
				table.insert(rows, { name = names[id], level = entry.value })
			end
			return show(rows)
		end
	end
	local rows = {} -- no store: this server's farmers
	for _, p in ipairs(Players:GetPlayers()) do
		table.insert(rows, { name = p.DisplayName, level = p:GetAttribute("Level") or 1 })
	end
	table.sort(rows, function(a, b)
		return a.level > b.level
	end)
	show(rows)
end

function LevelBoard.record(player, level)
	if store and level then
		pcall(store.SetAsync, store, tostring(player.UserId), math.floor(level))
	end
end

function LevelBoard.init()
	local ok, s = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, B.store)
	store = if ok then s else nil
	build()
	task.spawn(function()
		while true do
			for _, p in ipairs(Players:GetPlayers()) do
				LevelBoard.record(p, p:GetAttribute("Level"))
			end
			refresh()
			task.wait(B.refreshSeconds)
		end
	end)
end

return LevelBoard

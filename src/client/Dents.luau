-- Every swing leaves its mark: a dent carved in your haystack where you hit (on your screen;
-- never deeper than Config.Dent.floor of how full that clump really is), a little shudder of
-- straw, and a bar under the crosshair showing how much of that clump is left.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local HeapTerrain = require(Shared:WaitForChild("HeapTerrain"))(Config)
local Ui = require(script.Parent.Ui)
local Juice = require(script.Parent.Juice)

local player = Players.LocalPlayer
local Dents = {}
local PER_CLUMP = Config.TotalStraws // Config.Clumps
local bar, fill, text
local token = 0

local function origin()
	local plot = player:GetAttribute("Plot")
	local centre = plot and Config.PlotCentres[plot]
	return centre and HeapTerrain.origin(centre[1], centre[2])
end

local function mountBar()
	local gui = Ui.make("ScreenGui", { Name = "ClumpBar", ResetOnSpawn = false, IgnoreGuiInset = true, Parent = player:WaitForChild("PlayerGui") })
	bar = Ui.make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.5, 54), Size = UDim2.fromOffset(170, 30), BackgroundTransparency = 1, Visible = false, Parent = gui })
	text = Ui.label({ Size = UDim2.new(1, 0, 0, 16), Parent = bar }, 14)
	local track = Ui.make("Frame", { Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 8), BackgroundColor3 = Ui.colors.woodDark, BackgroundTransparency = 0.2, Parent = bar }, { Ui.corner(4) })
	fill = Ui.make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Ui.colors.hay, Parent = track }, { Ui.corner(4) })
end

-- Shows what's left in the clump you just hit, then fades away when you stop.
local function show(left)
	if not bar then
		mountBar()
	end
	token += 1
	local mine = token
	bar.Visible = true
	text.Text = if left > 0 then "This clump: " .. Format.commas(left) .. " / " .. Format.commas(PER_CLUMP) else "Clump cleared!"
	Juice.ease(fill, 0.15, { Size = UDim2.fromScale(math.clamp(left / PER_CLUMP, 0, 1), 1) })
	task.delay(1.6, function()
		if token == mine then
			bar.Visible = false
		end
	end)
end

-- A swing landed at `point` in clump `clump`, which has `left` straws left.
function Dents.hit(point, clump, left)
	if not clump or not left then
		return
	end
	show(left)
	local o = origin()
	if not o or left <= 0 then
		return -- a cleared clump is redrawn as empty by the server's update
	end
	local terrain = workspace.Terrain
	local floor = HeapTerrain.fullness(clump, left) * Config.Dent.floor
	if HeapTerrain.occupancy(terrain, o, clump) > floor + 0.02 then
		terrain:FillBall(point, Config.Dent.radius, Enum.Material.Air)
		if HeapTerrain.occupancy(terrain, o, clump) < floor then -- not deeper than the hay really goes
			HeapTerrain.cell(terrain, o, clump, left, floor)
		end
	end
	Juice.burst(point, 10, false)
end

return Dents

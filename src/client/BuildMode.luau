-- Free building in first person. Z and C pick from your inventory bar (or press M and click
-- it), aim with the crosshair, R to turn it, click (or PLACE) to build. X takes things back.
-- Touch screens: tap an item in the bar, then PLACE, TURN, TAKE BACK, NEXT/PREV on the pad.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))(Config)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Ui = require(script.Parent.Ui)
local Cursor = require(script.Parent.Cursor)
local Juice = require(script.Parent.Juice)
local TouchPad = require(script.Parent.TouchPad)

local player = Players.LocalPlayer
local BuildMode = {}
local active, removing, selected, rotation = false, false, nil, 0
local ghost, arrow, bar, buttons, status, notify = nil, nil, nil, {}, nil, nil
local hovered = nil
local removeBox = Instance.new("SelectionBox")
removeBox.Color3 = Color3.fromRGB(255, 90, 70)
removeBox.LineThickness = 0.1
removeBox.Parent = player:WaitForChild("PlayerGui")

local ALL = {}
for _, list in ipairs({ Config.Pieces, Config.Generators, Config.Machines, Config.Feeders or {} }) do
	for _, def in ipairs(list) do
		table.insert(ALL, def)
	end
end

local function myPlot()
	local index = player:GetAttribute("Plot")
	local c = index and Config.PlotCentres[index]
	return c and Vector3.new(c[1], 0, c[2]), index
end

local function aimPoint()
	local camera = workspace.CurrentCamera
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	if player:GetAttribute("Plot") then -- pass through other players' hidden buildings and hay
		params.CollisionGroup = "Plot" .. player:GetAttribute("Plot")
	end
	local ignore = {}
	local things = { player.Character, ghost, workspace:FindFirstChild("MyEffects") }
	for i = 1, 3 do
		if things[i] then
			table.insert(ignore, things[i])
		end
	end
	params.FilterDescendantsInstances = ignore
	return workspace:Raycast(camera.CFrame.Position, camera.CFrame.LookVector * 90, params)
end

local function clearGhost()
	if ghost then
		ghost:Destroy()
		ghost = nil
	end
end

local function makeGhost(def)
	clearGhost()
	local size = Vector3.new(def.size[1], def.size[2], def.size[3])
	ghost = Ui.make("Part", { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Size = size, Transparency = 0.55, Material = Enum.Material.ForceField, Color = Color3.fromRGB(120, 255, 140), Parent = workspace })
	arrow = Ui.make("Part", { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Size = Vector3.new(0.6, 0.6, 3), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 220, 90), Parent = ghost })
end

local function refreshBar()
	for id, button in pairs(buttons) do
		local n = player:GetAttribute("Inv_" .. id) or 0
		button.Visible = n > 0
		local def = Economy.item(id).def
		button.Text = def.name .. " x" .. n
		button.BackgroundColor3 = if selected == id then Ui.colors.green else Ui.colors.wood
	end
end

-- The help line, worded for keys or for the touch pad.
local function say(keys, touch)
	status.Text = if Ui.touch() then touch else keys
end

local function select(id)
	selected, removing = id, false
	makeGhost(Economy.item(id).def)
	local name = Economy.item(id).def.name
	say(name .. ": aim, R to turn, click to place. Z/C: other items. X: take back. B: done.", name .. ": aim the dot, TURN, then PLACE. Tap DONE when finished.")
	refreshBar()
end

-- Z / C (PREV / NEXT): the previous or next thing you own to build.
local function cycle(step)
	local owned = {}
	for _, def in ipairs(ALL) do
		if (player:GetAttribute("Inv_" .. def.id) or 0) > 0 then
			table.insert(owned, def.id)
		end
	end
	if #owned == 0 then
		say("Nothing to build yet: buy pieces in the Shop (Q).", "Nothing to build yet: buy pieces in the SHOP.")
		return
	end
	local at = table.find(owned, selected) or 0
	at = if step > 0 then at % #owned + 1 elseif at <= 1 then #owned else at - 1
	select(owned[at])
end

local function toggleRemove()
	removing, selected = not removing, nil
	clearGhost()
	if removing then
		say("Click something you built to take it back into your inventory.", "Aim the dot at something you built (it glows red) and tap TAKE BACK.")
	else
		say("Pick something to build.", "Pick something to build from the bar.")
	end
end

local snappedBase = nil

function BuildMode.active()
	return active
end

local function place()
	if not selected or not ghost then
		return
	end
	local base = snappedBase or (ghost.CFrame.Position - Vector3.new(0, ghost.Size.Y / 2, 0))
	local ok, message = Remotes.Place:InvokeServer(selected, base, rotation)
	notify.toast(message, if ok then Ui.colors.green else Ui.colors.red)
	if ok then
		Juice.burst(base + Vector3.new(0, 1, 0), 18)
		Juice.punch(1.5)
		if (player:GetAttribute("Inv_" .. selected) or 0) <= 0 then
			selected = nil
			clearGhost()
		end
	end
	refreshBar()
end

local function takeBack()
	if hovered then
		local ok, message = Remotes.TakeBack:InvokeServer(hovered)
		notify.toast(message, if ok then Ui.colors.wood else Ui.colors.red)
	end
end

function BuildMode.toggle(on)
	active = if on == nil then not active else on
	bar.Visible, status.Visible = active, active
	BuildMode.layout()
	if active then
		Cursor.need("key", false) -- opened from the HUD button: lock the mouse again so clicks place
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:UnequipTools()
		end
		say("Z/C to pick something to build (buy more in the Shop). B when done.", "Tap something in the bar to build it (buy more in the SHOP). DONE when finished.")
		refreshBar()
	else
		selected, removing, hovered = nil, false, nil
		removeBox.Adornee = nil
		clearGhost()
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		local backpack = player:FindFirstChildOfClass("Backpack")
		for _, tool in ipairs(backpack and backpack:GetChildren() or {}) do
			if humanoid and tool:IsA("Tool") and tool:GetAttribute("Level") ~= nil then
				humanoid:EquipTool(tool) -- back to harvesting
				break
			end
		end
	end
end

-- The item bar: along the bottom with a mouse; on touch screens between the thumbstick and
-- the action pad, above Roblox's tool bar.
function BuildMode.layout()
	if not bar then
		return
	end
	if Ui.touch() then
		local right = TouchPad.width() + 30
		bar.AnchorPoint, bar.Position, bar.Size = Vector2.new(0, 1), UDim2.new(0.36, 0, 1, -76), UDim2.new(0.64, -right, 0, 64)
		status.Position, status.Size = UDim2.new(0.5, 0, 1, -146), UDim2.new(0.6, 0, 0, 40)
	else
		bar.AnchorPoint, bar.Position, bar.Size = Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, -12), UDim2.new(0.9, 0, 0, 64)
		status.Position, status.Size = UDim2.new(0.5, 0, 1, -84), UDim2.fromOffset(560, 26)
	end
end

function BuildMode.mount(gui, notifier)
	notify = notifier
	bar = Ui.make("ScrollingFrame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12), Size = UDim2.new(0.9, 0, 0, 64), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollingDirection = Enum.ScrollingDirection.X, BackgroundTransparency = 1, ScrollBarThickness = 4, Visible = false, Parent = gui }, {
		Ui.make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	status = Ui.label({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -84), Size = UDim2.fromOffset(560, 26), Visible = false, Parent = gui }, 20)
	for order, def in ipairs(ALL) do
		local button = Ui.button(def.name, Ui.colors.wood, { LayoutOrder = order, Size = UDim2.fromOffset(150, 56), Visible = false, Parent = bar })
		button.Activated:Connect(function()
			select(def.id)
		end)
		buttons[def.id] = button
	end
	-- touch: the pad's build set (PLACE sits next to the thumb)
	for i, b in ipairs({
		{ "PLACE", function()
			if removing then
				takeBack()
			else
				place()
			end
		end, Ui.colors.green },
		{ "TURN", function()
			rotation = (rotation + 45) % 360
		end },
		{ "TAKE BACK", function()
			if removing and hovered then
				takeBack()
			else
				toggleRemove()
			end
		end, Ui.colors.red },
		{ "NEXT", function()
			cycle(1)
		end },
		{ "PREV", function()
			cycle(-1)
		end },
		{ "DONE", function()
			BuildMode.toggle(false)
		end, Ui.colors.blue },
	}) do
		TouchPad.add({ order = i, text = b[1], colour = b[3], tap = b[2], build = true })
	end
	Ui.onLayout(BuildMode.layout)
	player.AttributeChanged:Connect(function(name)
		if active and string.sub(name, 1, 4) == "Inv_" then
			refreshBar()
		end
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if input.KeyCode == Enum.KeyCode.B and not processed then
			BuildMode.toggle()
		end
		if not active or processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.Z or input.KeyCode == Enum.KeyCode.C then
			cycle(if input.KeyCode == Enum.KeyCode.C then 1 else -1)
		elseif input.KeyCode == Enum.KeyCode.R then
			rotation = (rotation + (if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then 15 else 45)) % 360
		elseif input.KeyCode == Enum.KeyCode.X then
			toggleRemove()
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 and not Cursor.isFree() or input.KeyCode == Enum.KeyCode.F then
			if removing then
				takeBack()
			else
				place()
			end
		end
	end)
	RunService.RenderStepped:Connect(function()
		if not active then
			return
		end
		local hit = aimPoint()
		local centre, index = myPlot()
		if removing then
			local model = hit and hit.Instance:FindFirstAncestorOfClass("Model")
			local built = index and workspace.Plots:FindFirstChild("Plot" .. index) and workspace.Plots["Plot" .. index]:FindFirstChild("Built")
			hovered = if model and built and model.Parent == built then model else nil
			removeBox.Adornee = hovered
			return
		end
		removeBox.Adornee = nil
		if ghost and hit and centre then
			local grid = Config.BuildGrid
			local p = hit.Position
			local snapped = Vector3.new(math.floor(p.X / grid + 0.5) * grid, p.Y, math.floor(p.Z / grid + 0.5) * grid)
			snappedBase = snapped -- place exactly where the check below was done, not mid-glide
			local cf = CFrame.new(snapped + Vector3.new(0, ghost.Size.Y / 2, 0)) * CFrame.Angles(0, math.rad(rotation), 0)
			ghost.CFrame = ghost.CFrame:Lerp(cf, 0.5) -- glides into place
			arrow.CFrame = ghost.CFrame * CFrame.new(0, ghost.Size.Y / 2 + 0.5, -ghost.Size.Z / 2)
			local half = Config.PlotSize / 2 - 1
			local inside = math.abs(snapped.X - centre.X) <= half and math.abs(snapped.Z - centre.Z) <= half
			ghost.Color = if inside then Color3.fromRGB(120, 255, 140) else Color3.fromRGB(255, 100, 90)
		end
	end)
end

return BuildMode

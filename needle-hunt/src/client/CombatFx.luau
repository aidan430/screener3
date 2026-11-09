-- Needle combat on your screen (server/Combat decides every hit):
--   click or tap with the Needle out to poke the nearest player in front of you (Remotes.Poke);
--   your hearts, top left under your level, while you're in a round's search;
--   a sparkle and a soft "POP!" where a poke lands; a gentle red edge when you're hit (no flash);
--   F (or the Inspect button while the Needle is out) to inspect it: it lifts and turns in your
--   hand for everyone to see (Remotes.Inspect).
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UiKit = require(script.Parent.UiKit)
local Effects = require(script.Parent.Effects)

local player = Players.LocalPlayer
local CombatFx = {}
local C = Config.Combat

-- The nearest other player within reach, roughly where you're facing.
local function target()
	local me = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not me then
		return nil
	end
	local look = workspace.CurrentCamera.CFrame.LookVector
	look = Vector3.new(look.X, 0, look.Z).Unit
	local best, bestDist = nil, C.reach
	for _, p in ipairs(Players:GetPlayers()) do
		local root = p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if root then
			local offset = root.Position - me.Position
			local flat = Vector3.new(offset.X, 0, offset.Z)
			if offset.Magnitude <= bestDist and (flat.Magnitude < 0.5 or look:Dot(flat.Unit) > 0.3) then
				best, bestDist = p, offset.Magnitude
			end
		end
	end
	return best
end

local function hookTool(tool, inspectButton)
	if tool.Name ~= "Needle" or tool:GetAttribute("Hooked") then
		return
	end
	tool:SetAttribute("Hooked", true)
	tool.Activated:Connect(function()
		local t = target()
		Remotes.Poke:FireServer(t and t.UserId)
	end)
	tool.Equipped:Connect(function()
		inspectButton.Visible = true
	end)
	tool.Unequipped:Connect(function()
		inspectButton.Visible = false
	end)
end

local function pop(position, colour)
	Effects.burst(position + Vector3.new(0, 1.5, 0), { colour, Color3.new(1, 1, 1) }, 18)
	local anchor = UiKit.make("Part", { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.one, CFrame = CFrame.new(position + Vector3.new(0, 3, 0)), Parent = workspace })
	local gui = UiKit.make("BillboardGui", { Size = UDim2.fromOffset(120, 50), AlwaysOnTop = true, Parent = anchor })
	local label = UiKit.label({ Text = "POP!", Font = UiKit.bold, TextColor3 = colour, TextStrokeTransparency = 0.3, Size = UDim2.fromScale(1, 1), Parent = gui }, 36)
	UiKit.pop(label, 0.6)
	UiKit.ease(gui, 0.9, { StudsOffset = Vector3.new(0, 2, 0) })
	task.delay(0.9, function()
		anchor:Destroy()
	end)
end

function CombatFx.start(gui)
	-- hearts, under the coins/level chip
	local hearts = UiKit.make("Frame", { Position = UDim2.fromOffset(16, 104), Size = UDim2.fromOffset(160, 40), BackgroundTransparency = 1, Visible = false, Parent = gui }, {
		UiKit.make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }),
	})
	UiKit.autoScale(hearts)
	local icons = {}
	for i = 1, C.hearts do
		icons[i] = UiKit.label({ LayoutOrder = i, Text = "♥", Font = UiKit.bold, TextColor3 = Color3.fromRGB(240, 90, 110), TextStrokeTransparency = 0.4, Size = UDim2.fromOffset(40, 40), Parent = hearts }, 36)
	end
	local edge = UiKit.make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 40, Parent = gui }, { UiKit.stroke(Color3.fromRGB(230, 80, 80), 0) })
	local function show()
		local n = player:GetAttribute("Hearts") or C.hearts
		hearts.Visible = ReplicatedStorage:GetAttribute("Phase") == "search" and (player:GetAttribute("Found") ~= nil)
		for i, icon in ipairs(icons) do
			icon.TextTransparency = if i <= n then 0 else 0.75
		end
	end
	player:GetAttributeChangedSignal("Hearts"):Connect(show)
	ReplicatedStorage:GetAttributeChangedSignal("Phase"):Connect(show)
	show()
	-- hits: a sparkle and a pop where they land; your own, a soft red edge that fades
	Remotes.Hit.OnClientEvent:Connect(function(m)
		pop(m.position, if m.hearts == 0 then UiKit.colors.gold else Color3.fromRGB(255, 120, 150))
		Effects.sound("click", 0.8)
		if m.to == player.UserId then
			local stroke = edge:FindFirstChildOfClass("UIStroke")
			stroke.Thickness, stroke.Transparency = 18, 0.3
			UiKit.ease(stroke, 0.8, { Transparency = 1 })
		end
	end)
	-- inspect: F, or the button while the Needle is out
	local inspectButton = UiKit.button("Inspect (F)", UiKit.colors.card, { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -150), Size = UDim2.fromOffset(150, 46), Visible = false, Parent = gui })
	UiKit.autoScale(inspectButton)
	local lastInspect = 0
	local function doInspect()
		if os.clock() - lastInspect > Config.NeedleTool.inspect then
			lastInspect = os.clock()
			Remotes.Inspect:FireServer()
		end
	end
	inspectButton.Activated:Connect(doInspect)
	ContextActionService:BindAction("InspectNeedle", function(_, state)
		if state == Enum.UserInputState.Begin and player.Character and player.Character:FindFirstChild("Needle") then
			doInspect()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.F, Enum.KeyCode.ButtonY)
	local function watch(holder)
		for _, t in ipairs(holder:GetChildren()) do
			if t:IsA("Tool") then
				hookTool(t, inspectButton)
			end
		end
		holder.ChildAdded:Connect(function(t)
			if t:IsA("Tool") then
				hookTool(t, inspectButton)
			end
		end)
	end
	player.CharacterAdded:Connect(function(character)
		inspectButton.Visible = false
		watch(character)
		watch(player:WaitForChild("Backpack"))
	end)
	if player.Character then
		watch(player.Character)
		watch(player:WaitForChild("Backpack"))
	end
end

return CombatFx

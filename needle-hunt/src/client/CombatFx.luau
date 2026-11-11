-- Needle combat on your screen (server/Combat decides every hit):
--   click or tap with the Needle out to poke the nearest player in front of you (Remotes.Poke;
--   throwing it is client/ThrowFx);
--   your hearts, top left under your level, while you're in a round's search;
--   a sparkle and a soft "POP!" where a poke lands; a gentle red edge when you're hit (no flash),
--   and a hit stops any chest you're holding open;
--   F (or the Inspect button while the Needle is out) to inspect it: it lifts and turns in your
--   hand for everyone to see (Remotes.Inspect).
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local FirstPerson = require(Shared:WaitForChild("FirstPerson"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UiKit = require(script.Parent.UiKit)
local Effects = require(script.Parent.Effects)
local ViewModel = require(script.Parent.ViewModel)
local MovesFx = require(script.Parent.MovesFx)

local player = Players.LocalPlayer
local CombatFx = {}
local C = Config.Combat
local taggedOut

local function hookTool(tool, inspectButton)
	if tool.Name ~= "Needle" or tool:GetAttribute("Hooked") then
		return
	end
	tool:SetAttribute("Hooked", true)
	tool.Activated:Connect(MovesFx.press) -- the poke; keep holding for a Power Poke (client/MovesFx)
	tool.Deactivated:Connect(MovesFx.release)
	tool.Equipped:Connect(function()
		inspectButton.Visible = true
	end)
	tool.Unequipped:Connect(function()
		inspectButton.Visible = false
	end)
end

local function pop(position, colour, amount, text)
	Effects.burst(position + Vector3.new(0, 1.5, 0), { colour, Color3.new(1, 1, 1) }, 18)
	local anchor = UiKit.make("Part", { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.one, CFrame = CFrame.new(position + Vector3.new(0, 3, 0)), Parent = workspace })
	local gui = UiKit.make("BillboardGui", { Size = UDim2.fromOffset(120, 84), AlwaysOnTop = true, Parent = anchor })
	local label = UiKit.label({ Text = text or "POP!", Font = UiKit.bold, TextColor3 = colour, TextStrokeTransparency = 0.3, Size = UDim2.new(1, 0, 0, 50), Parent = gui }, 36)
	UiKit.label({ Text = "-" .. amount .. " ♥", Font = UiKit.bold, TextStrokeTransparency = 0.3, Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 50), Parent = gui }, 24) -- hearts lost
	UiKit.pop(label, 0.6)
	UiKit.ease(gui, 0.9, { StudsOffset = Vector3.new(0, 2, 0) })
	task.delay(0.9, function()
		anchor:Destroy()
	end)
end

-- Tagged out: a calm panel in the middle counting down to your return.
taggedOut = function(gui)
	local box = UiKit.make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(400, 120), BackgroundColor3 = UiKit.colors.panel, BackgroundTransparency = 0.1, ZIndex = 35, Parent = gui }, { UiKit.corner(18), UiKit.stroke(Color3.fromRGB(255, 150, 160), 2) })
	UiKit.autoScale(box)
	UiKit.label({ Text = "TAGGED OUT", Font = UiKit.bold, TextColor3 = Color3.fromRGB(255, 150, 160), Size = UDim2.new(1, -20, 0, 44), Position = UDim2.fromOffset(10, 14), ZIndex = 36, Parent = box }, 34)
	local line = UiKit.label({ Size = UDim2.new(1, -20, 0, 30), Position = UDim2.fromOffset(10, 70), ZIndex = 36, Parent = box }, 22)
	UiKit.pop(box, 0.85)
	for n = C.respawn, 1, -1 do
		line.Text = "Back at a maze start in " .. n .. "  ·  your finds stay found"
		task.wait(1)
	end
	box:Destroy()
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
		hearts.Visible = ReplicatedStorage:GetAttribute("Phase") == "search" and player:GetAttribute("InRound") == true
		for i, icon in ipairs(icons) do
			icon.TextTransparency = if i <= n then 0 else 0.75
		end
	end
	player:GetAttributeChangedSignal("Hearts"):Connect(show)
	ReplicatedStorage:GetAttributeChangedSignal("Phase"):Connect(show)
	show()
	-- hits: a sparkle and a pop where they land; your own, a soft red edge that fades
	Remotes.Hit.OnClientEvent:Connect(function(m)
		local blocked = m.result == "blocked"
		pop(m.position, if blocked then Color3.fromRGB(170, 174, 184) elseif m.hearts == 0 then UiKit.colors.gold elseif (m.amount or 1) > 1 then Color3.fromRGB(255, 150, 60) else Color3.fromRGB(255, 120, 150), m.amount or 1,
			if blocked then "BLOCKED" elseif m.kind == "power" then "POWER!" elseif m.combo == 2 then "ONE-TWO!" else nil)
		Effects.sound("click", 0.8)
		MovesFx.hit(m)
		if m.to == player.UserId then
			-- a hit knocks you off a chest: any hold in progress stops, and starts again from empty
			local arena = workspace:FindFirstChild("Arena")
			for _, prompt in ipairs(arena and arena:GetDescendants() or {}) do
				if prompt:IsA("ProximityPrompt") and prompt:GetAttribute("Chest") and not prompt:GetAttribute("Opened") then
					prompt.Enabled = false
					task.delay(Config.Chests.hitLock, function()
						if prompt.Parent and not prompt:GetAttribute("Opened") then
							prompt.Enabled = true
						end
					end)
				end
			end
			if not blocked then
				local stroke = edge:FindFirstChildOfClass("UIStroke")
				stroke.Thickness, stroke.Transparency = 18, 0.3
				UiKit.ease(stroke, 0.8, { Transparency = 1 })
			end
			if m.hearts == 0 then
				task.spawn(taggedOut, gui)
			end
		end
	end)
	-- inspect: F, or the button while the Needle is out
	local inspectButton = UiKit.button("Inspect (F)", UiKit.colors.card, { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -150), Size = UDim2.fromOffset(150, 46), Visible = false, Parent = gui })
	UiKit.autoScale(inspectButton)
	local lastInspect = 0
	local function doInspect()
		if os.clock() - lastInspect > FirstPerson.anims.inspect.length then -- one at a time, to the end
			lastInspect = os.clock()
			Remotes.Inspect:FireServer()
			ViewModel.play("inspect")
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

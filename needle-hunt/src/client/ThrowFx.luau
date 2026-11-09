-- Throwing your needle on your screen (server/CombatThrow decides): Q, or the Throw button while
-- the Needle is out, throws it where you're aiming (the mouse, or the middle of the screen on a
-- phone). The button shows when it's ready again. Every throw anyone makes is drawn here: the
-- needle flies point first from their head to where it stops, and if it hits a wall it sticks
-- there for a moment before fading.
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Needles = require(Shared:WaitForChild("Needles"))
local NeedleLook = require(Shared:WaitForChild("NeedleLook"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UiKit = require(script.Parent.UiKit)
local Effects = require(script.Parent.Effects)

local player = Players.LocalPlayer
local ThrowFx = {}
local T = Config.Throw
local lastThrow = -math.huge

-- Where you're aiming: along the mouse (or the screen's middle on touch) from the camera.
local function aim()
	local head = player.Character and player.Character:FindFirstChild("Head")
	if not head then
		return nil
	end
	local camera = workspace.CurrentCamera
	local point = if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then camera.ViewportSize / 2 else UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(point.X, point.Y)
	local params = RaycastParams.new()
	params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, { player.Character }
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 300, params)
	local target = if hit then hit.Position else ray.Origin + ray.Direction * 300
	return (target - head.Position).Unit
end

local function throw()
	if not (player.Character and player.Character:FindFirstChild("Needle")) or os.clock() - lastThrow < T.cooldown then
		return
	end
	local dir = aim()
	if dir then
		lastThrow = os.clock()
		Remotes.Throw:FireServer(dir)
	end
end

-- Draws one throw: the thrower's needle, point first, from origin to finish.
local function flight(m)
	local typeId, skinId = Needles.split(m.key)
	local model = NeedleLook.build(typeId or "sewing", skinId or "steel", Config.NeedleTool.scale, 2)
	local dir = (m.finish - m.origin).Unit
	local face = CFrame.lookAt(Vector3.zero, dir) * CFrame.Angles(0, math.rad(90), 0) -- the needle's +X (its point) along the flight
	model:PivotTo(CFrame.new(m.origin) * face)
	model.Parent = workspace
	Effects.sound("whoosh", 1.3)
	local value = Instance.new("NumberValue")
	value.Changed:Connect(function(t)
		model:PivotTo(CFrame.new(m.origin:Lerp(m.finish, t)) * face)
	end)
	local tween = UiKit.ease(value, math.max(m.seconds, 0.05), { Value = 1 }, Enum.EasingStyle.Linear)
	tween.Completed:Wait()
	value:Destroy()
	if m.hitPlayer then
		model:Destroy() -- the hit shows as a POP (client/CombatFx)
		return
	end
	task.wait(0.8) -- stuck in the wall for a moment
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			UiKit.ease(part, 0.4, { Transparency = 1 })
		end
	end
	task.delay(0.45, function()
		model:Destroy()
	end)
end

function ThrowFx.start(gui)
	local button = UiKit.button("Throw (Q)", Color3.fromRGB(230, 120, 50), { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -204), Size = UDim2.fromOffset(150, 46), Visible = false, Parent = gui })
	UiKit.autoScale(button)
	button.Activated:Connect(throw)
	ContextActionService:BindAction("ThrowNeedle", function(_, state)
		if state == Enum.UserInputState.Begin then
			throw()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.Q, Enum.KeyCode.ButtonX)
	task.spawn(function() -- the button: only with the Needle out in a round, and when it's ready
		while true do
			local holding = player.Character and player.Character:FindFirstChild("Needle") ~= nil
			button.Visible = holding and ReplicatedStorage:GetAttribute("Phase") == "search" and player:GetAttribute("InRound") == true
			local wait = T.cooldown - (os.clock() - lastThrow)
			button.Text = if wait > 0 then string.format("Throw  %.0f", math.ceil(wait)) else "Throw (Q)"
			button.BackgroundColor3 = if wait > 0 then UiKit.colors.line else Color3.fromRGB(230, 120, 50)
			task.wait(0.2)
		end
	end)
	Remotes.Thrown.OnClientEvent:Connect(function(m)
		task.spawn(flight, m)
	end)
end

return ThrowFx

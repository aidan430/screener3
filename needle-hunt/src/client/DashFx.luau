-- Dashing (Config.Dash): C, B on a controller, or the Dash button on a phone. Your character
-- bursts along the way you're moving, or the way the camera faces if you're standing still,
-- with a soft whoosh, a short streak behind you and a little widening of the view (eased, no
-- flash). A bar under your hearts refills as the next dash comes back. Movement is your own (Roblox moves your character from your device), so the dash is
-- done here; server/AntiCheat still checks speed, and Remotes.Dash lets everyone see a puff of
-- dust where you set off.
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UiKit = require(script.Parent.UiKit)
local Effects = require(script.Parent.Effects)

local player = Players.LocalPlayer
local DashFx = {}
local D = Config.Dash
local last = -math.huge

local function dash()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 or humanoid.Sit or root.Anchored or os.clock() - last < D.cooldown then
		return
	end
	local dir = humanoid.MoveDirection
	if dir.Magnitude < 0.1 then
		local look = workspace.CurrentCamera.CFrame.LookVector
		dir = Vector3.new(look.X, 0, look.Z)
	end
	if dir.Magnitude < 0.1 then
		return
	end
	dir = Vector3.new(dir.X, 0, dir.Z).Unit
	last = os.clock()
	-- a push along the ground for a moment; gravity and jumping carry on as normal
	local attachment = Instance.new("Attachment")
	attachment.Parent = root
	local push = Instance.new("LinearVelocity")
	push.Attachment0, push.RelativeTo = attachment, Enum.ActuatorRelativeTo.World
	push.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	push.PrimaryTangentAxis, push.SecondaryTangentAxis = Vector3.xAxis, Vector3.zAxis
	push.PlaneVelocity = Vector2.new(dir.X, dir.Z) * D.speed
	push.MaxForce = 1e6
	push.Parent = root
	local trail = Instance.new("Trail")
	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	a0.Position, a1.Position = Vector3.new(0, 1, 0), Vector3.new(0, -1, 0)
	a0.Parent, a1.Parent = root, root
	trail.Attachment0, trail.Attachment1, trail.Lifetime, trail.LightEmission = a0, a1, 0.3, 0.3
	trail.Transparency = NumberSequence.new(0.5, 1)
	trail.Parent = root
	Effects.sound("whoosh", 1.1)
	if not Effects.settings.reduceEffects then
		local camera = workspace.CurrentCamera
		local fov = camera.FieldOfView
		UiKit.ease(camera, D.seconds, { FieldOfView = fov + 8 }, Enum.EasingStyle.Sine)
		task.delay(D.seconds, function()
			UiKit.ease(camera, 0.35, { FieldOfView = fov }, Enum.EasingStyle.Sine)
		end)
	end
	Remotes.Dash:FireServer()
	task.delay(D.seconds, function()
		push:Destroy()
		attachment:Destroy()
	end)
	task.delay(D.seconds + 0.35, function()
		trail:Destroy()
		a0:Destroy()
		a1:Destroy()
	end)
end

function DashFx.start(gui)
	local button = UiKit.button("Dash (C)", UiKit.colors.blue, { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -258), Size = UDim2.fromOffset(150, 46), Visible = UserInputService.TouchEnabled, Parent = gui })
	UiKit.autoScale(button)
	button.Activated:Connect(dash)
	ContextActionService:BindAction("Dash", function(_, state)
		if state == Enum.UserInputState.Begin then
			dash()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.C, Enum.KeyCode.ButtonB)
	-- the dash bar, top left under your hearts: it empties when you dash and fills back up over
	-- Config.Dash.cooldown; full (and bright) means ready
	local holder = UiKit.make("Frame", { Position = UDim2.fromOffset(16, 150), Size = UDim2.fromOffset(170, 26), BackgroundTransparency = 1, Parent = gui })
	UiKit.autoScale(holder)
	local tag = UiKit.label({ Text = "DASH", Font = UiKit.bold, Size = UDim2.fromOffset(52, 26), TextXAlignment = Enum.TextXAlignment.Left, TextStrokeTransparency = 0.5, Parent = holder }, 16)
	local back, fill = UiKit.bar(holder, { Size = UDim2.fromOffset(112, 12), Position = UDim2.fromOffset(54, 7) }, UiKit.colors.blue)
	local edge = UiKit.stroke(Color3.fromRGB(240, 236, 220), 1.5)
	edge.Parent = back
	RunService.RenderStepped:Connect(function()
		local charge = math.clamp((os.clock() - last) / D.cooldown, 0, 1)
		fill.Size = UDim2.fromScale(charge, 1)
		local ready = charge >= 1
		fill.BackgroundColor3 = if ready then UiKit.colors.blue else Color3.fromRGB(110, 130, 170)
		tag.TextColor3 = if ready then UiKit.colors.text else UiKit.colors.soft
		edge.Transparency = if ready then 0.1 else 0.6
		button.Text = if ready then "Dash (C)" else string.format("Dash  %.0f", math.ceil((1 - charge) * D.cooldown))
		button.BackgroundColor3 = if ready then UiKit.colors.blue else UiKit.colors.line
	end)
	Remotes.Dash.OnClientEvent:Connect(function(userId, position) -- someone else dashed: a puff of dust
		if userId ~= player.UserId then
			Effects.burst(position, { Color3.fromRGB(220, 200, 160), Color3.fromRGB(250, 240, 220) }, 10)
		end
	end)
end

return DashFx

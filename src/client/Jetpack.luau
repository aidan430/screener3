-- The Jetpack (a Robux game pass; the server sets the "PassJetpack" attribute when you own it).
-- In the air, hold Space (or the FLY button on touch screens) to rise, let go to drift gently
-- down, or press the hover key to stay put; WASD steers as usual. A LinearVelocity on the
-- HumanoidRootPart only sets the up/down speed, eased, with a force capped at a few body
-- weights, so it can lift you but never fling you. Tunables live in Config.Jetpack.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Ui = require(script.Parent.Ui)
local TouchPad = require(script.Parent.TouchPad)

local Jetpack = {}
local player = Players.LocalPlayer
local cfg = Config.Jetpack or {}
local rig = nil -- { root, humanoid, lift, flame } for the current character
local flying, hover, touchHeld = false, false, false
local speed = 0
local fuel = cfg.fuelSeconds or 0

local function owned()
	return player:GetAttribute("PassJetpack") == true
end

local hoverKey = Enum.KeyCode.H
pcall(function()
	hoverKey = Enum.KeyCode[cfg.hoverKey or "H"]
end)

local function build(character)
	rig, flying, hover, speed = nil, false, false, 0
	local root = character:WaitForChild("HumanoidRootPart", 10)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not root or not humanoid or not root:IsA("BasePart") or not humanoid:IsA("Humanoid") then
		return
	end
	local attachment = Ui.make("Attachment", { Name = "JetpackAttachment", Parent = root })
	local lift = Ui.make("LinearVelocity", {
		Name = "JetpackLift",
		Attachment0 = attachment,
		RelativeTo = Enum.ActuatorRelativeTo.World,
		VelocityConstraintMode = Enum.VelocityConstraintMode.Line,
		LineDirection = Vector3.new(0, 1, 0),
		LineVelocity = 0,
		MaxForce = 0,
		Enabled = false,
		Parent = root,
	})
	-- a soft flame and puff of smoke from behind your back (+Z is behind the root part)
	local nozzle = Ui.make("Attachment", { Name = "JetpackNozzle", Position = Vector3.new(0, -1.4, 0.9), Parent = root })
	local flame = Ui.make("ParticleEmitter", {
		Rate = 0,
		EmissionDirection = Enum.NormalId.Bottom,
		Lifetime = NumberRange.new(0.4, 0.9),
		Speed = NumberRange.new(4, 7),
		SpreadAngle = Vector2.new(12, 12),
		Drag = 3,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(0.4, 0.9), NumberSequenceKeypoint.new(1, 1.6) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) }),
		Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 196, 110)), ColorSequenceKeypoint.new(0.35, Color3.fromRGB(240, 150, 90)), ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 196, 190)) }),
		LightEmission = 0.25,
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-60, 60),
		Parent = nozzle,
	})
	rig = { root = root, humanoid = humanoid, lift = lift, flame = flame }
end

local function wantsUp()
	if touchHeld then
		return true
	end
	if UserInputService:GetFocusedTextBox() then
		return false -- typing in chat
	end
	local ok, pad = pcall(UserInputService.IsGamepadButtonDown, UserInputService, Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonA)
	return UserInputService:IsKeyDown(Enum.KeyCode.Space) or (ok and pad == true)
end

local function step(dt)
	if not rig or not rig.root.Parent then
		return
	end
	local root, humanoid, lift = rig.root, rig.humanoid, rig.lift
	local full = cfg.fuelSeconds or 0
	local inAir = humanoid.FloorMaterial == Enum.Material.Air and humanoid.Health > 0
	if not owned() or not inAir or humanoid.Sit then
		flying, hover = false, false
		lift.Enabled = false
		rig.flame.Rate = 0
		if full > 0 and humanoid.FloorMaterial ~= Enum.Material.Air then
			fuel = math.min(full, fuel + full / math.max(cfg.refuelSeconds or 4, 0.1) * dt)
		end
		return
	end
	local hasFuel = full <= 0 or fuel > 0
	local target = nil
	if wantsUp() and hasFuel then
		target = cfg.riseSpeed or 18
	elseif hover and hasFuel then
		target = 0
	elseif flying then
		target = -(cfg.fallSpeed or 7) -- you let go (or ran out): drift down softly
	end
	if target == nil then
		lift.Enabled = false -- an ordinary jump, no jetpack
		rig.flame.Rate = 0
		return
	end
	if not flying then
		flying = true
		speed = root.AssemblyLinearVelocity.Y -- start from how you're moving: no jolt
	end
	if target > 0 and root.Position.Y >= (cfg.ceiling or 275) then
		target = 0
	end
	if full > 0 and target >= 0 then
		fuel = math.max(0, fuel - dt)
	end
	speed += (target - speed) * (1 - math.exp(-(cfg.ease or 5) * dt))
	lift.LineVelocity = speed
	lift.MaxForce = root.AssemblyMass * workspace.Gravity * (cfg.thrust or 2.5)
	lift.Enabled = true
	rig.flame.Rate = if target > 0 then 40 elseif target == 0 then 18 else 6
end

function Jetpack.start(gui, notify)
	player.CharacterAdded:Connect(build)
	if player.Character then
		task.spawn(build, player.Character)
	end
	RunService.Heartbeat:Connect(step)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or input.KeyCode ~= hoverKey or not owned() or not rig or rig.humanoid.FloorMaterial ~= Enum.Material.Air then
			return
		end
		hover = not hover
		if notify then
			notify.toast(if hover then "Jetpack: hovering." else "Jetpack: drifting down.", Ui.colors.blue)
		end
	end)

	-- touch screens: hold FLY (on the action pad) to rise, tap HOVER to stay put
	TouchPad.add({ order = 1, text = "FLY", colour = Ui.colors.blue, show = owned, down = function()
		touchHeld = true
		if rig and rig.humanoid.FloorMaterial ~= Enum.Material.Air and owned() then
			rig.humanoid.Jump = true -- take off from the ground: no need to reach for jump too
		end
	end, up = function()
		touchHeld = false
	end })
	TouchPad.add({ order = 2, text = "HOVER", colour = Ui.colors.blue, show = owned, tap = function()
		if rig and rig.humanoid.FloorMaterial == Enum.Material.Air then
			hover = not hover
			if notify then
				notify.toast(if hover then "Jetpack: hovering." else "Jetpack: drifting down.", Ui.colors.blue)
			end
		end
	end })

	local told = false
	local function tell()
		if owned() and not told and notify then
			told = true
			notify.toast(if Ui.touch() then "Jetpack ready! Jump, then hold FLY to fly up and tap HOVER to stay put." else "Jetpack ready! In the air, hold Space to fly up, " .. (cfg.hoverKey or "H") .. " to hover.", Ui.colors.blue)
		end
	end
	player:GetAttributeChangedSignal("PassJetpack"):Connect(tell)
	tell()
end

return Jetpack

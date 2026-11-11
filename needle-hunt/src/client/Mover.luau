-- A short push along the ground on your own character (your device moves it): the poke's lunge
-- and the knockback when you're hit. One push at a time; a new one replaces the old. Gravity and
-- jumping carry on as normal. Speeds stay under Config.AntiCheat.maxSpeed.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Mover = {}
local current = nil -- { push, attachment, dir, v0, v1, start, seconds }

local function stop()
	if current then
		current.push:Destroy()
		current.attachment:Destroy()
		current = nil
	end
end

-- Pushes you along flat direction `dir`, from v0 studs a second easing to v1, for `seconds`.
function Mover.push(dir, v0, v1, seconds)
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local flat = Vector3.new(dir.X, 0, dir.Z)
	if not root or not humanoid or humanoid.Health <= 0 or root.Anchored or humanoid.WalkSpeed <= 0 or flat.Magnitude < 0.1 or seconds <= 0 then
		return
	end
	stop()
	local attachment = Instance.new("Attachment")
	attachment.Parent = root
	local push = Instance.new("LinearVelocity")
	push.Attachment0, push.RelativeTo = attachment, Enum.ActuatorRelativeTo.World
	push.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	push.PrimaryTangentAxis, push.SecondaryTangentAxis = Vector3.xAxis, Vector3.zAxis
	push.PlaneVelocity = Vector2.new(flat.Unit.X, flat.Unit.Z) * v0
	push.MaxForce = 1e6
	push.Parent = root
	current = { push = push, attachment = attachment, dir = flat.Unit, v0 = v0, v1 = v1, start = os.clock(), seconds = seconds }
end

function Mover.start()
	RunService.Heartbeat:Connect(function()
		if current then
			local t = (os.clock() - current.start) / current.seconds
			if t >= 1 or not current.push.Parent then
				stop()
			else
				current.push.PlaneVelocity = Vector2.new(current.dir.X, current.dir.Z) * (current.v0 + (current.v1 - current.v0) * t)
			end
		end
	end)
	Players.LocalPlayer.CharacterAdded:Connect(stop)
end

return Mover

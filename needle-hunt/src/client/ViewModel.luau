-- First person: your arms and your needle drawn in front of the camera, posed and animated from
-- shared/FirstPerson (made in the Needle Hand Rig artifact). Only you see these; everyone else
-- sees the Needle tool in your character's hand (server/Combat), which is hidden on your own
-- screen while you're in first person. Plays the inspect (F), jab (a poke) and throw (Q).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FP = require(Shared:WaitForChild("FirstPerson"))
local Needles = require(Shared:WaitForChild("Needles"))
local NeedleLook = require(Shared:WaitForChild("NeedleLook"))

local player = Players.LocalPlayer
local ViewModel = {}
local rig = nil -- { model, right, left, needle, key }
local playing = nil -- { name, start }
local lastYaw, sway, hiddenTool = nil, 0, nil
local ZERO = { 0, 0, 0, 0, 0, 0 }

local function v3(t)
	return Vector3.new(t[1], t[2], t[3])
end

-- pos + the offset's first three, rot + its last three (degrees), as the artifact does it
local function place(base, off, extra)
	local p = v3(base.pos) + Vector3.new(off[1], off[2], off[3]) + (extra or Vector3.zero)
	return CFrame.new(p) * CFrame.Angles(math.rad(base.rot[1] + off[4]), math.rad(base.rot[2] + off[5]), math.rad(base.rot[3] + off[6]))
end

local function block(model, size, colour, material)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Size, p.Color, p.Material = size, colour, material
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

local function skinColour(character)
	local colours = character:FindFirstChildOfClass("BodyColors")
	if colours then
		return colours.RightArmColor3
	end
	local arm = character:FindFirstChild("RightLowerArm") or character:FindFirstChild("Right Arm")
	return if arm then arm.Color else Color3.fromRGB(234, 184, 146)
end

local function makeArm(model, colour)
	local size, s = v3(FP.arm.size), math.min(FP.arm.sleeve, 0.98)
	local arm = { skin = block(model, size, colour, Enum.Material.SmoothPlastic), half = size.Y / 2 }
	if s > 0.01 then
		arm.sleeve = block(model, Vector3.new(size.X * 1.08, size.Y * s, size.Z * 1.08), Color3.fromRGB(table.unpack(FP.arm.sleeveColour)), Enum.Material.Fabric)
		arm.sleeveAt = CFrame.new(0, size.Y / 2 - size.Y * s / 2 + 0.001, 0)
	end
	return arm
end

local function build(character, key)
	if rig then
		rig.model:Destroy()
	end
	local typeId, skinId = Needles.split(key)
	local model = Instance.new("Model")
	model.Name = "NeedleViewModel"
	local colour = skinColour(character)
	rig = { model = model, key = key, right = makeArm(model, colour), left = makeArm(model, colour) }
	rig.needle = NeedleLook.build(typeId or "sewing", skinId or "steel", FP.needleLook.scale, FP.needleLook.fat)
	rig.needle.Parent = model
	rig.emitters = {}
	for _, e in ipairs(rig.needle:GetDescendants()) do
		if e:IsA("ParticleEmitter") then -- an Heirloom's aura, sparkles: they stay with the hand
			e.LockedToPart = true
			table.insert(rig.emitters, e)
		end
	end
	model.Parent = workspace.CurrentCamera
end

-- The offsets at time t of an animation: between the two keys around t, eased (as in the artifact).
local function sample(anim, t)
	local keys = anim.keys
	local a, b = keys[1], keys[#keys]
	for i = 1, #keys - 1 do
		if t >= keys[i].t and t <= keys[i + 1].t then
			a, b = keys[i], keys[i + 1]
			break
		end
	end
	local f = if b.t > a.t then math.clamp((t - a.t) / (b.t - a.t), 0, 1) else 0
	f = f * f * (3 - 2 * f)
	local out = {}
	for _, part in ipairs({ "right", "left", "needle" }) do
		local row = {}
		for i = 1, 6 do
			row[i] = a[part][i] + (b[part][i] - a[part][i]) * f
		end
		out[part] = row
	end
	return out
end

local function setToolHidden(tool)
	if hiddenTool == tool then
		return
	end
	for _, t in ipairs({ hiddenTool, tool }) do
		if t and t.Parent then
			for _, p in ipairs(t:GetDescendants()) do
				if p:IsA("BasePart") then
					p.LocalTransparencyModifier = if t == tool then 1 else 0
				end
			end
		end
	end
	hiddenTool = tool
end

local function step(dt)
	local camera = workspace.CurrentCamera
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	local tool = character and character:FindFirstChild("Needle")
	local firstPerson = head and (camera.CFrame.Position - head.Position).Magnitude < 1.5
	if not (tool and firstPerson) then
		setToolHidden(nil)
		if rig then
			rig.model.Parent = nil
		end
		return
	end
	setToolHidden(tool)
	local key = tool:GetAttribute("Key") or "sewing:steel"
	if not rig or rig.key ~= key then
		build(character, key)
	end
	rig.model.Parent = camera
	-- moving: a bob while walking, and the arms lag a little when you turn
	local look = camera.CFrame.LookVector
	local yaw = math.atan2(-look.X, -look.Z)
	local turn = if lastYaw then (yaw - lastYaw + math.pi) % (2 * math.pi) - math.pi else 0
	lastYaw = yaw
	sway += (math.clamp(-turn / math.max(dt, 1 / 240) * FP.motion.sway * 0.25, -0.25, 0.25) - sway) * math.min(1, dt * 12)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local walking = humanoid and humanoid.MoveDirection.Magnitude > 0.1 and humanoid.FloorMaterial ~= Enum.Material.Air
	local now, bob = os.clock(), if walking then FP.motion.bob else 0
	local move = Vector3.new(math.sin(now * FP.motion.bobSpeed) * bob * 0.5 + sway, -math.abs(math.cos(now * FP.motion.bobSpeed)) * bob, 0)
	local off = { right = ZERO, left = ZERO, needle = ZERO }
	if playing then
		local anim = FP.anims[playing.name]
		local t = now - playing.start
		if t >= anim.length then
			playing = nil
		else
			off = sample(anim, t)
		end
	end
	for _, side in ipairs({ "right", "left" }) do
		local arm, cf = rig[side], camera.CFrame * place(FP.pose[side], off[side], move)
		arm.skin.CFrame = cf
		if arm.sleeve then
			arm.sleeve.CFrame = cf * arm.sleeveAt
		end
		arm.at = cf
	end
	local hand = rig.right.at * CFrame.new(0, -rig.right.half, 0)
	rig.needle:PivotTo(hand * place(FP.pose.needle, off.needle))
	local away = player:GetAttribute("NeedleAway") == true -- thrown: the hand is empty until it's back
	for _, p in ipairs(rig.needle:GetDescendants()) do
		if p:IsA("BasePart") and p.Name ~= "Root" then
			p.LocalTransparencyModifier = if away then 1 else 0
		end
	end
	for _, e in ipairs(rig.emitters) do
		e.Enabled = not away
	end
end

-- Plays one of FirstPerson's animations ("inspect", "jab" or "throw") on your screen.
function ViewModel.play(name)
	if FP.anims[name] then
		playing = { name = name, start = os.clock() }
	end
end

function ViewModel.start()
	RunService:BindToRenderStep("NeedleViewModel", Enum.RenderPriority.Camera.Value + 1, step)
	player.CharacterAdded:Connect(function()
		if rig then
			rig.model:Destroy()
			rig = nil
		end
		hiddenTool, playing = nil, nil
	end)
end

return ViewModel

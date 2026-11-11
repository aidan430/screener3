-- Crouching and sliding (Config.Stance): Left Ctrl or V, L3 on a controller, or the CROUCH button
-- on a phone. Press it standing still or walking slowly and you crouch (half speed, lower, your
-- name tag hidden); press it while running on the ground and you slide, fast at first and easing
-- off; press again, jump or dash to stand. You only stand if there's room above you. Your device
-- moves your own character, so the moves are done here; the server keeps the "Stance" attribute
-- (server/Stance) and every device folds the legs of anyone who's down (the pose below).
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UiKit = require(script.Parent.UiKit)
local Aim = require(script.Parent.Aim)
local Effects = require(script.Parent.Effects)

local player = Players.LocalPlayer
local StanceFx = {}
local S = Config.Stance
local state, standHip, baseSpeed, lastSlide = "stand", nil, nil, -math.huge
local slide = nil -- { push, attachment, dir, walk, start }
local button

local function parts()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return character, humanoid, root
end

local function dropFor(humanoid, stance)
	if humanoid.RigType == Enum.HumanoidRigType.R6 then
		return S.drop.r6
	end
	local drop = math.min(S.drop[stance], (standHip or humanoid.HipHeight) - S.drop.minHip)
	return if drop < 0.2 then 0 else drop
end

local function endSlide()
	if slide then
		slide.push:Destroy()
		slide.attachment:Destroy()
		slide = nil
		if not Effects.settings.reduceEffects then
			UiKit.ease(workspace.CurrentCamera, 0.3, { FieldOfView = Aim.fov() }, Enum.EasingStyle.Sine)
		end
	end
end

-- Is there room to stand up?
local function headroom(character, root, drop)
	local params = RaycastParams.new()
	params.FilterType, params.FilterDescendantsInstances, params.RespectCanCollide = Enum.RaycastFilterType.Exclude, { character }, true
	return workspace:Spherecast(root.Position, 0.9, Vector3.yAxis * (drop + S.headroom), params) == nil
end

local function go(stance)
	local character, humanoid, root = parts()
	if not humanoid or stance == state then
		return
	end
	if state == "stand" then
		standHip, baseSpeed = humanoid.HipHeight, humanoid.WalkSpeed
	end
	if stance == "stand" and state ~= "stand" and not headroom(character, root, dropFor(humanoid, state)) then
		stance = "crouch" -- something overhead: stay down
		if state == "crouch" then
			return
		end
	end
	endSlide()
	state = stance
	local hip = if stance == "stand" then standHip else standHip - dropFor(humanoid, stance)
	UiKit.ease(humanoid, S.ease, { HipHeight = hip }, Enum.EasingStyle.Sine)
	humanoid.WalkSpeed = if stance == "crouch" then baseSpeed * S.crouchSpeed else baseSpeed
	Remotes.Stance:FireServer(stance)
	if button then
		button.Text = if stance == "stand" then "Crouch" else "Stand"
	end
end

local function startSlide(humanoid, root, dir)
	go("slide")
	if state ~= "slide" then
		return
	end
	lastSlide = os.clock()
	local attachment = Instance.new("Attachment")
	attachment.Parent = root
	local push = Instance.new("LinearVelocity")
	push.Attachment0, push.RelativeTo = attachment, Enum.ActuatorRelativeTo.World
	push.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	push.PrimaryTangentAxis, push.SecondaryTangentAxis = Vector3.xAxis, Vector3.zAxis
	push.MaxForce = 1e6
	push.Parent = root
	slide = { push = push, attachment = attachment, dir = dir, walk = baseSpeed, start = os.clock() }
	Effects.sound("whoosh", 0.8)
	if not Effects.settings.reduceEffects then
		UiKit.ease(workspace.CurrentCamera, 0.15, { FieldOfView = Aim.fov() + S.slide.fov }, Enum.EasingStyle.Sine)
	end
end

local function press()
	local _, humanoid, root = parts()
	if not humanoid or not root or humanoid.Health <= 0 or humanoid.Sit or humanoid.WalkSpeed <= 0 then
		return
	end
	if state ~= "stand" then
		return go("stand")
	end
	local v = root.AssemblyLinearVelocity
	local flat = Vector3.new(v.X, 0, v.Z)
	local running = flat.Magnitude >= S.slide.needSpeed * humanoid.WalkSpeed and humanoid.FloorMaterial ~= Enum.Material.Air
	if running and os.clock() - lastSlide >= S.slide.cooldown then
		startSlide(humanoid, root, flat.Unit)
	else
		go("crouch")
	end
end

-- Stand up (a dash or anything else that needs you on your feet).
function StanceFx.stand()
	go("stand")
end

-- Every frame: your slide's push, and the folded legs of everyone who's down (R15 only).
local function step()
	local _, humanoid = parts()
	if slide and humanoid then
		local t = (os.clock() - slide.start) / S.slide.seconds
		if t >= 1 or humanoid.FloorMaterial == Enum.Material.Air and t > 0.4 or humanoid.WalkSpeed <= 0 then
			go("stand")
		else
			local from = math.min(S.slide.top, slide.walk + S.slide.boost)
			local speed = from + (slide.walk * S.slide.endAt - from) * t
			slide.push.PlaneVelocity = Vector2.new(slide.dir.X, slide.dir.Z) * speed
		end
	end
	if humanoid and state == "crouch" and humanoid.WalkSpeed ~= baseSpeed * S.crouchSpeed then
		baseSpeed = humanoid.WalkSpeed -- the server changed your speed (boots, held still): half of the new one
		humanoid.WalkSpeed = baseSpeed * S.crouchSpeed
	end
	for _, p in ipairs(Players:GetPlayers()) do
		local stance = if p == player then (if state ~= "stand" then state else nil) else p:GetAttribute("Stance")
		local character = stance and p.Character
		local h = character and character:FindFirstChildOfClass("Humanoid")
		if h and h.RigType == Enum.HumanoidRigType.R15 then
			local stand = if p == player then standHip or h.HipHeight else h.HipHeight
			local drop = math.min(S.drop[stance], stand - S.drop.minHip)
			if drop >= 0.2 and stand > 0 then
				local phi = math.acos(math.clamp(1 - drop / stand, 0, 1))
				for _, side in ipairs({ "Left", "Right" }) do
					for i, joint in ipairs({ { "UpperLeg", "Hip" }, { "LowerLeg", "Knee" }, { "Foot", "Ankle" } }) do
						local limb = character:FindFirstChild(side .. joint[1])
						local motor = limb and limb:FindFirstChild(side .. joint[2])
						if motor and motor:IsA("Motor6D") then
							motor.Transform *= CFrame.Angles(phi * S.legs[i], 0, 0)
						end
					end
				end
				local torso = character:FindFirstChild("UpperTorso")
				local waist = torso and torso:FindFirstChild("Waist")
				if waist and waist:IsA("Motor6D") then
					waist.Transform *= CFrame.Angles(math.rad(S.waist[stance]), 0, 0)
				end
			end
		end
	end
end

function StanceFx.start(gui)
	button = UiKit.button("Crouch", UiKit.colors.blue, { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -312), Size = UDim2.fromOffset(150, 46), Visible = UserInputService.TouchEnabled, Parent = gui })
	UiKit.autoScale(button)
	button.Activated:Connect(press)
	ContextActionService:BindAction("Crouch", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			press()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.LeftControl, Enum.KeyCode.V, Enum.KeyCode.ButtonL3)
	local function fresh(character) -- a new body stands, with its own hip height
		endSlide()
		state, standHip, baseSpeed = "stand", nil, nil
		local humanoid = character:WaitForChild("Humanoid", 10)
		if humanoid then
			humanoid.Jumping:Connect(function(active)
				if active and state ~= "stand" then
					go("stand")
				end
			end)
		end
	end
	player.CharacterAdded:Connect(fresh)
	if player.Character then
		task.spawn(fresh, player.Character)
	end
	player:GetAttributeChangedSignal("Stance"):Connect(function() -- the server stood you up (tagged out, held still)
		if player:GetAttribute("Stance") == nil and state == "crouch" then
			local _, humanoid = parts()
			if humanoid and humanoid.WalkSpeed <= 0 then
				go("stand")
			end
		end
	end)
	RunService.Stepped:Connect(step)
end

return StanceFx

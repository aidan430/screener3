-- The first-person view's sense of movement: breathing, the walk, the lag when you turn, the dip
-- when you land, the empty hand while the needle is away and how near a wall is. Each comes out
-- as a weight for one of shared/FirstPersonRig.motion's layers; client/ViewModelPose.offsets
-- turns the weights into rows. Every number is in FirstPerson.motion or FirstPersonRig.motion.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FP = require(Shared:WaitForChild("FirstPerson"))
local Rig = require(Shared:WaitForChild("FirstPersonRig"))
local Pose = require(script.Parent.ViewModelPose)

local Motion = {}
local M = Rig.motion
local SHORTEST = 1 / 240 -- a frame is never treated as shorter than this (turn speed divides by it)
local s -- what carries over from frame to frame
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.RespectCanCollide = true -- grass, orbs and other things you walk through don't count as walls

-- Start again from rest (the view has just come up, or you have a new character).
function Motion.reset()
	s = { time = 0, stride = 0, walk = 0, swayX = 0, swayY = 0, air = 0, away = 0, wall = 0, fall = 0, inAir = false, w = {} }
end
Motion.reset()

-- This frame's weights, all but the wall's (Motion.wall): see ViewModelPose.offsets.
-- away: the needle is out of the hand.
function Motion.step(dt, camera, humanoid, root, away)
	local w = s.w
	s.time += dt
	w.breath = math.sin(s.time * M.breathe.speed)

	local grounded = humanoid == nil or humanoid.FloorMaterial ~= Enum.Material.Air
	local walking = humanoid ~= nil and grounded and humanoid.MoveDirection.Magnitude > M.walk.least
	s.walk = Pose.ease(s.walk, if walking then 1 else 0, M.walk.rate, dt)
	if walking then
		s.stride += dt * FP.motion.bobSpeed
	end
	w.step, w.dip = Pose.walk(s.stride, s.walk)

	-- turning: the view lags the camera (FirstPersonRig.motion.turn)
	local look = camera.CFrame.LookVector
	local yaw, pitch = math.atan2(-look.X, -look.Z), math.asin(math.clamp(look.Y, -1, 1))
	local turned = if s.yaw then (yaw - s.yaw + math.pi) % (2 * math.pi) - math.pi else 0 -- left is +
	local tilted = if s.pitch then pitch - s.pitch else 0 -- up is +
	s.yaw, s.pitch = yaw, pitch
	local perRadian = FP.motion.sway * M.turn.gain / math.max(dt, SHORTEST)
	s.swayX = Pose.ease(s.swayX, math.clamp(turned * perRadian, -M.turn.max, M.turn.max), M.turn.rate, dt)
	s.swayY = Pose.ease(s.swayY, math.clamp(-tilted * perRadian, -M.turn.max, M.turn.max), M.turn.rate, dt)
	w.swayX, w.swayY = s.swayX, s.swayY

	-- the air, and the dip when you land (harder after a longer fall)
	if not grounded then
		s.inAir = true
		s.fall = math.max(s.fall, if root then -root.AssemblyLinearVelocity.Y else 0)
	elseif s.inAir then
		s.inAir = false
		s.landed, s.power = s.time, math.clamp(s.fall / M.land.speed, M.land.least, 1)
		s.fall = 0
	end
	s.air = Pose.ease(s.air, if grounded then 0 else 1, M.air.rate, dt)
	w.air = s.air
	w.land = if s.landed then Pose.landing(Rig, s.time - s.landed, s.power) else 0

	s.away = Pose.ease(s.away, if away then 1 else 0, M.away.rate, dt)
	w.away = s.away
	-- charging a Power Poke, and behind a Thimble (the server's attributes)
	local me = game:GetService("Players").LocalPlayer
	s.charge = Pose.ease(s.charge or 0, if me:GetAttribute("Charging") then 1 else 0, M.charge.rate, dt)
	s.guard = Pose.ease(s.guard or 0, if me:GetAttribute("Guarding") then 1 else 0, M.guard.rate, dt)
	w.charge, w.guard = s.charge, s.guard
	w.wall = 0
	return w
end

-- How far into the wall pose (0..1): one short ray from the camera to where the needle's point
-- would be with no wall (tip, in camera space), past your own character and the view itself.
-- Other players and dummies don't count: the needle is meant to reach them.
function Motion.wall(dt, camera, tip, character)
	local reach = tip.Magnitude
	if s.ignoring ~= character then
		s.ignoring = character
		params.FilterDescendantsInstances = { character, camera }
	end
	local hit = workspace:Raycast(camera.CFrame.Position, camera.CFrame:VectorToWorldSpace(tip.Unit) * (reach + M.wall.margin), params)
	local distance = nil
	if hit then
		local model = hit.Instance:FindFirstAncestorOfClass("Model")
		if not (model and model:FindFirstChildOfClass("Humanoid")) then
			distance = hit.Distance
		end
	end
	local target = Pose.wall(Rig, reach, distance)
	s.wall = Pose.ease(s.wall, target, if target > s.wall then M.wall.rateIn else M.wall.rateOut, dt)
	return s.wall
end

return Motion

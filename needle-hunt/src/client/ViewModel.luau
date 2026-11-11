-- First person: your forearm, your hand and your needle drawn in front of the camera. Only you
-- see these; everyone else sees the Needle tool in your character's hand (server/Combat), which
-- is hidden on your own screen while you're in first person.
--   the pose and the inspect, jab and throw: shared/FirstPerson (made in the Needle Hand Rig tool)
--   the hand, the grip, the motion, equip and catch: shared/FirstPersonRig
--   where things go: ViewModelPose | the parts: ViewModelRig | how you're moving: ViewModelMotion
-- The view comes up with "equip"; a throw empties the hand until the needle is back ("catch").
-- In a round and in the Practice Yard the camera is locked to first person.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FP = require(Shared:WaitForChild("FirstPerson"))
local Rig = require(Shared:WaitForChild("FirstPersonRig"))
local Pose = require(script.Parent.ViewModelPose)
local ViewModelRig = require(script.Parent.ViewModelRig)
local Motion = require(script.Parent.ViewModelMotion)

local player = Players.LocalPlayer
local ViewModel = {}
-- Every animation ViewModel.play knows, by name. To add a set (combat moves, say), add that
-- module's anims table to this list: a later table wins a name.
local ANIMS = Pose.merge({ FP.anims, Rig.anims })
local view = nil -- ViewModelRig's parts for the needle in hand
local playing = nil -- { name, start }
local showing = false -- the view is up
local flight = nil -- the needle is out of the hand: when the throw let go (os.clock), or "away" once the server says so
local wasGone = false
local hiddenTool = nil

-- Your own Needle tool, hidden on your screen while you're in first person (the hand holds the one
-- you see). Set every frame, so nothing else (the camera's own scripts, a rebuilt tool) can undo it.
local function setToolHidden(tool)
	if hiddenTool == tool and tool == nil then
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

-- Is the needle out of the hand? From the moment the throw lets go of it until the server has
-- brought it back (NeedleAway cleared), or throw.wait later if the server never took the throw.
local function needleGone(now)
	if player:GetAttribute("NeedleAway") == true then
		flight = "away"
	elseif flight == "away" or (flight and now - flight > Rig.throw.wait) then
		flight = nil
	end
	return flight ~= nil
end

local function step(dt)
	local camera = workspace.CurrentCamera
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	local tool = character and character:FindFirstChild("Needle")
	local firstPerson = head and (camera.CFrame.Position - head.Position).Magnitude < Rig.view.firstPerson
	if not (tool and firstPerson) then
		setToolHidden(nil)
		if view then
			view.model.Parent = nil
		end
		showing = false
		return
	end
	setToolHidden(tool)
	local key = tool:GetAttribute("Key") or "sewing:steel"
	if not view or view.key ~= key then -- a new needle in hand
		if view then
			view.model:Destroy()
		end
		view = ViewModelRig.build(character, key)
		showing = false
	end
	view.model.Parent = camera
	if not showing then -- it rises into view
		showing = true
		Motion.reset()
		ViewModel.play("equip")
	end

	local now = os.clock()
	local rows, holding = nil, false
	if playing then
		local anim, t = ANIMS[playing.name], now - playing.start
		if playing.name == "throw" then -- it stays in the hand until the throw lets go (where throws count)
			holding = t < Rig.throw.release or not (player:GetAttribute("InRound") or player:GetAttribute("Practicing"))
			if not holding and not flight then
				flight = now
			end
		end
		if t >= anim.length then
			playing = nil
		else
			rows = Pose.sample(anim, t)
		end
	end
	local gone = needleGone(now) and not holding
	if wasGone and not gone then
		ViewModel.play("catch") -- back in the hand
	end
	wasGone = gone
	ViewModelRig.showNeedle(view, not gone)

	-- where everything goes: the hold, what's playing and how you're moving; then the wall, from
	-- where the needle's point would otherwise be
	local w = Motion.step(dt, camera, character:FindFirstChildOfClass("Humanoid"), character:FindFirstChild("HumanoidRootPart"), gone)
	local fit = Pose.fit(Rig, camera.FieldOfView)
	local frames = Pose.frames(FP, Rig, Pose.offsets(FP, Rig, rows, w), view.needle)
	w.wall = Motion.wall(dt, camera, (fit * frames.needle * Vector3.new(view.needle.front, 0, 0)) * Rig.view.scale, character)
	if w.wall > 0 then
		frames = Pose.frames(FP, Rig, Pose.offsets(FP, Rig, rows, w), view.needle)
	end
	ViewModelRig.move(view, camera.CFrame, fit, frames, w.away)
end

-- First person only while you're in a round or the Practice Yard; the lobby keeps the usual camera.
local function lockCamera()
	local locked = player:GetAttribute("InRound") == true or player:GetAttribute("Practicing") == true
	player.CameraMode = if locked then Enum.CameraMode.LockFirstPerson else Enum.CameraMode.Classic
end

-- Plays an animation on your screen by name: "inspect", "jab" or "throw" (shared/FirstPerson),
-- "equip" or "catch" (shared/FirstPersonRig), or any other in ANIMS.
function ViewModel.play(name)
	if ANIMS[name] then
		playing = { name = name, start = os.clock() }
	end
end

function ViewModel.start()
	RunService:BindToRenderStep("NeedleViewModel", Enum.RenderPriority.Camera.Value + 1, step)
	player.CharacterAdded:Connect(function()
		if view then
			view.model:Destroy()
			view = nil
		end
		hiddenTool, playing, showing, flight, wasGone = nil, nil, false, nil, false
	end)
	for _, name in ipairs({ "InRound", "Practicing" }) do
		player:GetAttributeChangedSignal(name):Connect(lockCamera)
	end
	lockCamera()
end

return ViewModel

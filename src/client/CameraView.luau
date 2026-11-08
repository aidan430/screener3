-- The optional over-the-shoulder view: V (or the View stamp, or the touch pad's View) switches
-- between first person and a camera just behind your right shoulder, so you can see yourself,
-- your skins and your farm. The crosshair still aims at the middle of the screen, so harvesting
-- works the same either way (client/Harvest casts from the camera).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Ui = require(script.Parent.Ui)
local Cursor = require(script.Parent.Cursor)
local TouchPad = require(script.Parent.TouchPad)

local player = Players.LocalPlayer
local CameraView = {}
local third = false
local stamp = nil

local function apply()
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if third then
		player.CameraMode = Enum.CameraMode.Classic
		player.CameraMinZoomDistance, player.CameraMaxZoomDistance = Config.CameraZoom.near, Config.CameraZoom.far
		if humanoid then
			humanoid.CameraOffset = Vector3.new(1.75, 0.6, 0) -- over the right shoulder, clear of the crosshair
		end
	else
		player.CameraMinZoomDistance, player.CameraMaxZoomDistance = 0.5, 0.5
		player.CameraMode = Enum.CameraMode.LockFirstPerson
		if humanoid then
			humanoid.CameraOffset = Vector3.zero
		end
	end
	if stamp then
		stamp.Caption.Text = if third then "BEHIND · V" else "EYES · V"
	end
end

function CameraView.toggle()
	third = not third
	apply()
end

function CameraView.isThird()
	return third
end

function CameraView.start(gui)
	stamp = Ui.stamp("View", "EYES · V", { AnchorPoint = Vector2.new(1, 1), Size = UDim2.fromOffset(48, 48), Parent = gui })
	Ui.autoScale(stamp)
	Ui.onLayout(function() -- bottom right, beside the music and "?" stamps (hidden on touch: the pad has View)
		stamp.Visible = not Ui.touch()
		stamp.Position = UDim2.new(1, -16 - 116 * Ui.screenScale(), 1, -16)
	end)
	stamp.Word.TextScaled = true
	stamp.Activated:Connect(CameraView.toggle)
	TouchPad.add({ order = 10, text = "View", tap = CameraView.toggle })
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.V then
			CameraView.toggle()
		end
	end)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid", 10)
		task.wait(1.2) -- the server sets first person on every spawn; put your choice back after it
		apply()
	end)
	-- behind the shoulder with a mouse: keep it locked to the crosshair (unless a menu needs it)
	RunService.RenderStepped:Connect(function()
		if third and not Cursor.isFree() and not Ui.touch() then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		end
	end)
	apply()
end

return CameraView

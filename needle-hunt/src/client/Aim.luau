-- Your aim settings (Settings, Aim; Config.Aim): mouse sensitivity, field of view, and the reticle
-- in the middle of the screen, in the shape and colour you pick. The reticle shows in first
-- person, where your aim is the middle of the screen. Effects that kick the field of view (a dash,
-- a find) come back to yours (Aim.fov).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local AimSettings = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AimSettings"))
local UiKit = require(script.Parent.UiKit)

local player = Players.LocalPlayer
local Aim = {}
local current = table.clone(AimSettings.defaults)
local holder

function Aim.fov()
	return current.fov
end

local function piece(size, pos, colour, round)
	local f = UiKit.make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, pos.X, 0.5, pos.Y), Size = UDim2.fromOffset(size.X, size.Y), BackgroundColor3 = colour, BorderSizePixel = 0, Parent = holder }, {
		UiKit.make("UIStroke", { Color = Color3.new(0, 0, 0), Transparency = 0.45, Thickness = 1 }), -- readable on any background
	})
	if round then
		UiKit.make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = f })
	end
	return f
end

-- Draws the reticle: shape is crossdot | dot | cross | circle | none.
function Aim.draw(shape, colourName)
	if not holder then
		return
	end
	holder:ClearAllChildren()
	local colour = AimSettings.colour(colourName)
	if shape == "dot" or shape == "crossdot" then
		piece(Vector2.new(if shape == "dot" then 6 else 4, if shape == "dot" then 6 else 4), Vector2.zero, colour, true)
	end
	if shape == "cross" or shape == "crossdot" then
		for _, d in ipairs({ Vector2.new(1, 0), Vector2.new(-1, 0), Vector2.new(0, 1), Vector2.new(0, -1) }) do
			local along = d * 9 -- 4 px gap, 10 px arms
			piece(if d.X ~= 0 then Vector2.new(10, 2) else Vector2.new(2, 10), along, colour, false)
		end
	elseif shape == "circle" then
		local ring = UiKit.make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1, Parent = holder }, {
			UiKit.make("UICorner", { CornerRadius = UDim.new(1, 0) }),
			UiKit.make("UIStroke", { Color = colour, Thickness = 2 }),
		})
		ring.Name = "Ring"
		piece(Vector2.new(2, 2), Vector2.zero, colour, true)
	end
end

-- Applies a player's settings (from their profile, or straight away as they change one).
function Aim.apply(settings)
	for key, default in pairs(AimSettings.defaults) do
		current[key] = AimSettings.clean(key, settings[key]) or default
	end
	UserInputService.MouseDeltaSensitivity = current.sensitivity
	local camera = workspace.CurrentCamera
	if camera then
		camera.FieldOfView = current.fov
	end
	Aim.draw(current.reticle, current.reticleColour)
end

function Aim.mount(gui)
	holder = UiKit.make("Frame", { Name = "Reticle", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(40, 40), BackgroundTransparency = 1, Visible = false, ZIndex = 5, Parent = gui })
	Aim.draw(current.reticle, current.reticleColour)
	RunService.RenderStepped:Connect(function()
		local head = player.Character and player.Character:FindFirstChild("Head")
		local camera = workspace.CurrentCamera
		holder.Visible = head ~= nil and camera ~= nil and (camera.CFrame.Position - head.Position).Magnitude < 1.5
	end)
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		if workspace.CurrentCamera then
			workspace.CurrentCamera.FieldOfView = current.fov
		end
	end)
end

return Aim

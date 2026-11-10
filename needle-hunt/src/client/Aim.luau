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

local look = {} -- the colour, opacity and outline the pieces are drawn with

local function outline(f)
	if look.outline then
		UiKit.make("UIStroke", { Color = look.outline, Thickness = look.outlineThickness, Transparency = 1 - look.opacity * 0.85, LineJoinMode = Enum.LineJoinMode.Miter, Parent = f })
	end
end

local function piece(size, pos, round)
	local f = UiKit.make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, pos.X, 0.5, pos.Y), Size = UDim2.fromOffset(size.X, size.Y), BackgroundColor3 = look.colour, BackgroundTransparency = 1 - look.opacity, BorderSizePixel = 0, Parent = holder })
	outline(f) -- readable on any background
	if round then
		UiKit.make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = f })
	end
	return f
end

local function ring(diameter, thickness, colour, transparency, z)
	return UiKit.make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(diameter, diameter), BackgroundTransparency = 1, ZIndex = z, Parent = holder }, {
		UiKit.make("UICorner", { CornerRadius = UDim.new(1, 0) }),
		UiKit.make("UIStroke", { Color = colour, Thickness = thickness, Transparency = transparency }),
	})
end

-- Draws the reticle from the settings in `o`: reticle (crossdot | dot | cross | circle | none),
-- reticleColour, reticleSize (1 = normal), reticleThickness (pixels; the dot grows with it),
-- reticleOpacity (1 = solid), reticleOutline (black | white | none) and reticleOutlineThickness.
function Aim.draw(o)
	if not holder then
		return
	end
	holder:ClearAllChildren()
	local size, thickness = o.reticleSize or 1, o.reticleThickness or 2
	look.colour, look.opacity = AimSettings.colour(o.reticleColour), o.reticleOpacity or 1
	look.outline = if o.reticleOutline == "white" then Color3.new(1, 1, 1) elseif o.reticleOutline == "none" then nil else Color3.new(0, 0, 0)
	look.outlineThickness = o.reticleOutlineThickness or 1
	local gap, arm = math.max(2, 4 * size), math.max(3, 10 * size)
	holder.Size = UDim2.fromOffset(80 * size + 20, 80 * size + 20)
	local shape = o.reticle
	if shape == "dot" or shape == "crossdot" then
		local d = math.max(2, (if shape == "dot" then 6 * size else 2 * size) + thickness)
		piece(Vector2.new(d, d), Vector2.zero, true)
	end
	if shape == "cross" or shape == "crossdot" then
		for _, dir in ipairs({ Vector2.new(1, 0), Vector2.new(-1, 0), Vector2.new(0, 1), Vector2.new(0, -1) }) do
			piece(if dir.X ~= 0 then Vector2.new(arm, thickness) else Vector2.new(thickness, arm), dir * (gap + arm / 2), false)
		end
	elseif shape == "circle" then
		local d = math.max(8, 20 * size)
		if look.outline then -- the outline is a wider ring behind the ring
			ring(d, thickness + look.outlineThickness * 2, look.outline, 1 - look.opacity * 0.85, 1)
		end
		ring(d, thickness, look.colour, 1 - look.opacity, 2)
		piece(Vector2.new(thickness, thickness), Vector2.zero, true)
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
	Aim.draw(current)
end

function Aim.mount(gui)
	holder = UiKit.make("Frame", { Name = "Reticle", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(40, 40), BackgroundTransparency = 1, Visible = false, ZIndex = 5, Parent = gui })
	Aim.draw(current)
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

-- Power-ups on your screen (server/Powerups decides; Remotes.Powerup says what you got):
--   a toast, and a chip above the bottom of the screen counting down while it lasts;
--   compass   a big arrow under the round banner pointing at the needle, with how far it is;
--   birdseye  your camera glides up above the maze, looks down, and glides back;
--   glint     the needles and decoys near you sparkle and glow (only on your screen);
--   speed and coins need nothing more than the chip and the toast.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UiKit = require(script.Parent.UiKit)
local Effects = require(script.Parent.Effects)
local Hud = require(script.Parent.Hud)

local player = Players.LocalPlayer
local PowerupFx = {}
local chips, arrow, distance

local function kindOf(id)
	for _, k in ipairs(Config.Powerups.kinds) do
		if k.id == id then
			return k
		end
	end
	return nil
end

local function chip(kind, seconds)
	local c = UiKit.make("Frame", { Size = UDim2.fromOffset(200, 40), BackgroundColor3 = UiKit.colors.panel, BackgroundTransparency = 0.1, Parent = chips }, { UiKit.corner(10), UiKit.stroke(Color3.fromRGB(kind.colour[1], kind.colour[2], kind.colour[3]), 2) })
	UiKit.label({ Font = UiKit.bold, Text = kind.icon .. "  " .. kind.name, Size = UDim2.new(1, -16, 0, 26), Position = UDim2.fromOffset(8, 2), TextXAlignment = Enum.TextXAlignment.Left, Parent = c }, 18)
	local _, fill = UiKit.bar(c, { Size = UDim2.new(1, -16, 0, 5), Position = UDim2.new(0, 8, 1, -9) }, Color3.fromRGB(kind.colour[1], kind.colour[2], kind.colour[3]))
	fill.Size = UDim2.fromScale(1, 1)
	UiKit.ease(fill, seconds, { Size = UDim2.fromScale(0, 1) }, Enum.EasingStyle.Linear)
	UiKit.pop(c, 0.7)
	Debris:AddItem(c, seconds)
end

local function compass(target, seconds)
	if not target then
		Hud.toast("You've already found every needle!", "good")
		return
	end
	arrow.Visible, distance.Visible = true, true
	local ends = os.clock() + seconds
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local camera, root = workspace.CurrentCamera, player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if os.clock() > ends or not camera or not root then
			arrow.Visible, distance.Visible = false, false
			conn:Disconnect()
			return
		end
		local v = camera.CFrame:PointToObjectSpace(target)
		arrow.Rotation = math.deg(math.atan2(v.X, -v.Z)) -- the glyph points up: 0 = straight ahead
		distance.Text = math.floor((target - root.Position).Magnitude) .. " studs"
	end)
end

local function birdseye(height, seconds)
	local camera, root = workspace.CurrentCamera, player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not camera or not root then
		return
	end
	camera.CameraType = Enum.CameraType.Scriptable
	local from = camera.CFrame
	local above = CFrame.lookAt(root.Position + Vector3.new(0, height, 6), root.Position)
	UiKit.ease(camera, 1, { CFrame = above }, Enum.EasingStyle.Sine)
	task.delay(seconds - 1, function()
		local tween = UiKit.ease(camera, 1, { CFrame = from }, Enum.EasingStyle.Sine)
		tween.Completed:Wait()
		camera.CameraType = Enum.CameraType.Custom
	end)
end

local function glint(points, seconds)
	if #points == 0 then
		Hud.toast("No needles nearby... try another corridor.", "bad")
	end
	for _, pos in ipairs(points) do
		local spark = UiKit.make("Part", { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.one, CFrame = CFrame.new(pos), Parent = workspace })
		UiKit.make("ParticleEmitter", {
			Rate = 14, Lifetime = NumberRange.new(0.5, 0.9), Speed = NumberRange.new(1, 3), SpreadAngle = Vector2.new(180, 180), LightEmission = 1,
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.5), NumberSequenceKeypoint.new(1, 0) }),
			Color = ColorSequence.new(Color3.fromRGB(255, 250, 200)), Parent = spark,
		})
		UiKit.make("PointLight", { Color = Color3.fromRGB(255, 240, 160), Range = 8, Brightness = 2, Parent = spark })
		Debris:AddItem(spark, seconds)
	end
end

function PowerupFx.start(gui)
	chips = UiKit.make("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -86), Size = UDim2.fromOffset(620, 40), BackgroundTransparency = 1, Parent = gui }, {
		UiKit.make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 8) }),
	})
	UiKit.autoScale(chips)
	arrow = UiKit.label({ Font = UiKit.bold, Text = "▲", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 180), Size = UDim2.fromOffset(90, 90), TextColor3 = Color3.fromRGB(90, 170, 255), TextStrokeTransparency = 0.2, Visible = false, ZIndex = 30, Parent = gui }, 80)
	distance = UiKit.label({ Font = UiKit.bold, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 228), Size = UDim2.fromOffset(160, 26), TextStrokeTransparency = 0.3, Visible = false, ZIndex = 30, Parent = gui }, 22)
	Remotes.Powerup.OnClientEvent:Connect(function(m)
		local kind = kindOf(m.kind)
		if not kind then
			return
		end
		Effects.sound("found", 1.5)
		if m.kind == "coins" then
			Hud.toast(kind.icon .. "  " .. kind.name .. ": +" .. (m.coins or 0) .. " coins", "good")
			return
		end
		Hud.toast(kind.icon .. "  " .. kind.name .. "!", "good")
		chip(kind, m.seconds or 5)
		if m.kind == "compass" then
			compass(m.target, m.seconds)
		elseif m.kind == "birdseye" then
			birdseye(m.height or 50, m.seconds)
		elseif m.kind == "glint" then
			glint(m.points or {}, m.seconds)
		end
	end)
end

return PowerupFx

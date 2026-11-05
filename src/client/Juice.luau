-- Feedback that makes harvesting feel good: straw bursts, floating numbers, a soft camera
-- punch, a combo streak, pop rings when a clump is cleared, coins flying to your counter,
-- and gentle milestone celebrations. Everything eases in and out; nothing flashes.
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Ui = require(script.Parent.Ui)

local player = Players.LocalPlayer
local Juice = {}
local gui, comboLabel, coinTarget = nil, nil, nil
local combo, lastHit = 0, 0
local fx = Instance.new("Folder")
fx.Name = "MyEffects"
fx.Parent = workspace

local function ease(instance, seconds, goal, style, direction)
	local tween = TweenService:Create(instance, TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), goal)
	tween:Play()
	return tween
end
Juice.ease = ease

-- Plays a sound from Config.Sounds if one is set (IDs from the Toolbox; "" = silent).
function Juice.sound(name, pitch)
	local id = Config.Sounds and Config.Sounds[name]
	if not id or id == "" then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = 0.5
	sound.PlaybackSpeed = pitch or 1
	sound.Parent = SoundService
	sound:Play()
	Debris:AddItem(sound, 3)
end

function Juice.mount(screen, coinsLabel)
	gui, coinTarget = screen, coinsLabel -- coinsLabel may be nil if the HUD failed
	comboLabel = Ui.label({ AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0.5, 40, 0.5, -30), Size = UDim2.fromOffset(220, 40), TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1, TextStrokeTransparency = 1, TextColor3 = Ui.colors.hay, Parent = screen }, 34)
end

-- A puff of straw at a world position.
function Juice.burst(position, count, golden)
	local anchor = Ui.make("Part", { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(position), Parent = fx })
	local emitter = Ui.make("ParticleEmitter", {
		Rate = 0,
		Lifetime = NumberRange.new(0.5, 1.1),
		Speed = NumberRange.new(8, 18),
		SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, -30, 0),
		Drag = 2,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0.1) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-240, 240),
		Color = ColorSequence.new(if golden then Color3.fromRGB(255, 220, 90) else Color3.fromRGB(242, 212, 120)),
		LightEmission = if golden then 0.5 else 0.1,
		Parent = anchor,
	})
	emitter:Emit(count)
	Debris:AddItem(anchor, 1.5)
end

-- A number that floats up from a world position and fades.
function Juice.float(position, text, colour)
	local anchor = Ui.make("Attachment", { WorldPosition = position, Parent = workspace.Terrain })
	local board = Ui.make("BillboardGui", { Adornee = anchor, Size = UDim2.fromScale(6, 1.6), StudsOffset = Vector3.new(math.random(-10, 10) / 10, 1, 0), AlwaysOnTop = true, LightInfluence = 0, Parent = player:WaitForChild("PlayerGui") })
	local label = Ui.label({ Text = text, Size = UDim2.fromScale(1, 1), TextColor3 = colour or Ui.colors.hay, Parent = board }, 48)
	ease(board, 0.9, { StudsOffset = board.StudsOffset + Vector3.new(0, 2.5, 0) })
	ease(label, 0.9, { TextTransparency = 1, TextStrokeTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	Debris:AddItem(board, 1)
	Debris:AddItem(anchor, 1)
end

-- A soft, quick push of the camera's field of view: you feel the hit without a jolt.
function Juice.punch(strength)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local base = 70
	camera.FieldOfView = base - (strength or 1.5)
	ease(camera, 0.18, { FieldOfView = base }, Enum.EasingStyle.Sine)
end

-- A ring that grows and fades where a clump disappeared.
function Juice.pop(position, golden)
	local ring = Ui.make("Part", { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Shape = Enum.PartType.Ball, Size = Vector3.new(2, 2, 2), CFrame = CFrame.new(position), Material = Enum.Material.Neon, Color = if golden then Color3.fromRGB(255, 214, 90) else Color3.fromRGB(255, 236, 170), Transparency = 0.3, Parent = fx })
	ease(ring, 0.45, { Size = Vector3.new(9, 9, 9), Transparency = 1 })
	Debris:AddItem(ring, 0.5)
	Juice.burst(position, 28, golden)
	Juice.punch(3)
	Juice.sound("pop", 0.9 + math.random() * 0.2)
end

-- The combo streak: harvests within 1.2 seconds of each other count up.
function Juice.hit()
	local now = os.clock()
	combo = if now - lastHit < 1.2 then combo + 1 else 1
	lastHit = now
	if comboLabel and combo >= 3 then
		comboLabel.Text = "x" .. combo .. (if combo >= 50 then " ON FIRE!" elseif combo >= 20 then " GREAT!" else "")
		comboLabel.TextTransparency, comboLabel.TextStrokeTransparency = 0, 0.4
		comboLabel.TextColor3 = Ui.colors.hay:Lerp(Color3.fromRGB(255, 120, 60), math.clamp(combo / 60, 0, 1))
		local scale = comboLabel:FindFirstChildOfClass("UIScale") or Ui.make("UIScale", { Parent = comboLabel })
		scale.Scale = 1.25
		ease(scale, 0.2, { Scale = 1 }, Enum.EasingStyle.Back)
		task.delay(1.3, function()
			if os.clock() - lastHit >= 1.2 then
				ease(comboLabel, 0.4, { TextTransparency = 1, TextStrokeTransparency = 1 })
			end
		end)
	end
	Juice.sound("harvest", 0.95 + math.min(combo, 40) * 0.006)
	return combo
end

-- Little coins that fly from the middle of the screen into your coin counter.
function Juice.coins(amount)
	if not gui or not coinTarget then
		return
	end
	local count = math.clamp(math.floor(math.log10(math.max(amount, 1)) * 3), 3, 14)
	local target = coinTarget.AbsolutePosition + coinTarget.AbsoluteSize / 2
	for i = 1, count do
		task.delay(i * 0.04, function()
			local coin = Ui.make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(18, 18), Position = UDim2.new(0.5, math.random(-60, 60), 0.5, math.random(-40, 40)), BackgroundColor3 = Color3.fromRGB(255, 206, 70), Parent = gui }, { Ui.corner(9), Ui.stroke(Color3.fromRGB(190, 130, 30), 2) })
			ease(coin, 0.55, { Position = UDim2.fromOffset(target.X, target.Y), Size = UDim2.fromOffset(10, 10) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			Debris:AddItem(coin, 0.6)
		end)
	end
	local scale = coinTarget:FindFirstChildOfClass("UIScale") or Ui.make("UIScale", { Parent = coinTarget })
	task.delay(0.55, function()
		scale.Scale = 1.15
		ease(scale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
		Juice.sound("coins")
	end)
end

-- A big, warm "well done" for milestones: confetti from the top of the screen.
function Juice.confetti()
	if not gui then
		return
	end
	local colours = { Color3.fromRGB(255, 206, 70), Color3.fromRGB(240, 120, 80), Color3.fromRGB(120, 200, 120), Color3.fromRGB(110, 170, 240) }
	for i = 1, 40 do
		local bit = Ui.make("Frame", { Size = UDim2.fromOffset(8, 14), Position = UDim2.new(math.random(), 0, 0, -20), Rotation = math.random(0, 360), BackgroundColor3 = colours[i % #colours + 1], Parent = gui }, { Ui.corner(3) })
		ease(bit, 1.6 + math.random() * 1.2, { Position = UDim2.new(bit.Position.X.Scale + (math.random() - 0.5) * 0.2, 0, 1.05, 0), Rotation = bit.Rotation + math.random(-360, 360) }, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
		Debris:AddItem(bit, 3)
	end
	Juice.sound("cheer")
end

-- Counts a TextLabel smoothly from one number to another.
function Juice.countTo(label, holder, value, format)
	if label.Text == "" then
		label.Text = format(holder.Value)
	end
	ease(holder, 0.6, { Value = value }, Enum.EasingStyle.Quart)
	if not holder:GetAttribute("Hooked") then
		holder:SetAttribute("Hooked", true)
		holder.Changed:Connect(function(v)
			label.Text = format(v)
		end)
	end
end

Juice.format = Format
return Juice

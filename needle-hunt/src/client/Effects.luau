-- Feedback you can see and hear, on your own screen only: sounds, a burst of particles where a
-- needle was found, a soft flash and a little camera kick. "Reduce effects" in Settings turns the
-- flash, the kick and the big bursts off. Nothing here strobes.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local UiKit = require(script.Parent.UiKit)

local Effects = {}
Effects.settings = { sfx = true, reduceEffects = false, music = true }
local gui = nil

function Effects.mount(screen)
	gui = screen
end

function Effects.sound(name, pitch)
	local id = Config.Sounds[name]
	if not Effects.settings.sfx or type(id) ~= "string" or id == "" then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId, s.Volume, s.PlaybackSpeed = id, 0.6, pitch or 1
	s.Parent = SoundService
	s:Play()
	Debris:AddItem(s, 4)
end

-- A burst of sparkles in a cosmetic's colours at a world position.
function Effects.burst(position, colours, count)
	if Effects.settings.reduceEffects then
		count = math.floor((count or 40) / 4)
	end
	local anchor = UiKit.make("Part", { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.one, CFrame = CFrame.new(position), Parent = workspace })
	local e = UiKit.make("ParticleEmitter", {
		Rate = 0, Lifetime = NumberRange.new(0.6, 1.2), Speed = NumberRange.new(10, 22), SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, -24, 0), Drag = 2, LightEmission = 0.5,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) }),
		Color = ColorSequence.new(colours[1], colours[2] or colours[1]), Parent = anchor,
	})
	e:Emit(count or 40)
	Debris:AddItem(anchor, 2)
end

-- A soft white glow over the screen that fades out (not a strobe), and a small FOV kick.
function Effects.flash()
	if Effects.settings.reduceEffects or not gui then
		return
	end
	local f = UiKit.make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.55, ZIndex = 50, Parent = gui })
	UiKit.ease(f, 0.5, { BackgroundTransparency = 1 })
	Debris:AddItem(f, 0.6)
	local camera = workspace.CurrentCamera
	if camera then
		local fov = require(script.Parent.Aim).fov() -- back to the player's own field of view
		camera.FieldOfView = fov - 8
		UiKit.ease(camera, 0.4, { FieldOfView = fov }, Enum.EasingStyle.Back)
	end
end

-- Confetti falling across the screen.
function Effects.confetti()
	if not gui or Effects.settings.reduceEffects then
		return
	end
	local colours = { UiKit.colors.gold, UiKit.colors.red, UiKit.colors.green, UiKit.colors.blue }
	for i = 1, 36 do
		local bit = UiKit.make("Frame", { Size = UDim2.fromOffset(8, 14), Position = UDim2.new(math.random(), 0, 0, -20), Rotation = math.random(0, 360), BackgroundColor3 = colours[i % 4 + 1], ZIndex = 40, Parent = gui }, { UiKit.corner(3) })
		UiKit.ease(bit, 1.6 + math.random() * 1.2, { Position = UDim2.new(bit.Position.X.Scale + (math.random() - 0.5) * 0.2, 0, 1.05, 0), Rotation = bit.Rotation + math.random(-360, 360) }, Enum.EasingStyle.Sine)
		Debris:AddItem(bit, 3)
	end
end

return Effects

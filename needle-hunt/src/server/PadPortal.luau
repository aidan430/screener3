-- One lobby game platform (LobbyBuilder builds Config.Pads.count of them; server/GamePads runs them):
-- a wide glowing disc in a darker rim, a shimmering portal column over it that breathes slowly, sparks
-- drifting up through it (more of them as the platform fills: GamePads sets the rate), a soft light,
-- and the board above it (game number, count, status). Gentle on purpose: nothing flashes.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local MapKit = require(script.Parent.MapKit)

local PadPortal = {}

local function upright(at, height, diameter) -- a cylinder standing up (its axis is its X)
	return CFrame.new(at) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(height, diameter, diameter)
end

local function ghost(p) -- to look at only: nothing walks on, touches or aims at it
	p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = false, false, false, false
	return p
end

-- Builds platform i at map-local (x, z); `text` is LobbyBuilder's label helper. Returns the
-- platform's record: { part, name, count, status, position, fx }.
function PadPortal.build(ctx, i, x, z, text)
	local P, look = Config.Pads, Config.Pads.portal
	local colour = P.colours[(i - 1) % #P.colours + 1]
	local c3 = Color3.fromRGB(colour[1], colour[2], colour[3])
	local d = P.radius * 2
	local base = MapKit.at(ctx, x, 0, z)
	local cf, size = upright(base + Vector3.new(0, 0.5, 0), 0.6, d + 2)
	MapKit.part(ctx, { Name = "PadRim", Shape = "Cylinder", Size = size, CFrame = cf, Color = c3:Lerp(Color3.new(0, 0, 0), 0.55), Material = "Metal" })
	cf, size = upright(base + Vector3.new(0, 0.62, 0), 0.6, d)
	local pad = ghost(MapKit.part(ctx, { Name = "GamePad" .. i, Shape = "Cylinder", Size = size, CFrame = cf, Color = c3, Material = "Neon" }))
	pad.CanQuery = true
	-- the portal column: ForceField shimmers on its own; it breathes in and out
	cf, size = upright(base + Vector3.new(0, 0.9 + look.height / 2, 0), look.height, d - 0.4)
	local column = ghost(MapKit.part(ctx, { Name = "PortalColumn", Shape = "Cylinder", Size = size, CFrame = cf, Color = c3, Material = "ForceField", Transparency = 0.15 }))
	TweenService:Create(column, TweenInfo.new(look.breathe, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Transparency = 0.55, Size = size + Vector3.new(0, 0.8, 0.8) }):Play()
	-- a ring hovering at the top of the column, turning slowly
	cf, size = upright(base + Vector3.new(0, 0.9 + look.height, 0), 0.25, d + 0.6)
	local ring = ghost(MapKit.part(ctx, { Name = "PortalRing", Shape = "Cylinder", Size = size, CFrame = cf, Color = c3, Material = "Neon", Transparency = 0.6 }))
	TweenService:Create(ring, TweenInfo.new(look.breathe, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { CFrame = cf + Vector3.new(0, -0.8, 0) }):Play()
	-- sparks rising from the disc
	local emitterPart = ghost(MapKit.part(ctx, { Name = "PortalSparks", Size = Vector3.new(d - 2, 0.1, d - 2), CFrame = CFrame.new(base + Vector3.new(0, 1, 0)), Transparency = 1 }))
	local fx = Instance.new("ParticleEmitter")
	fx.EmissionDirection, fx.Rate = Enum.NormalId.Top, look.rate
	fx.Lifetime, fx.Speed, fx.SpreadAngle = NumberRange.new(1.6, 2.6), NumberRange.new(3, 6), Vector2.new(6, 6)
	fx.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	fx.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	fx.Color = ColorSequence.new(c3, Color3.new(1, 1, 1))
	fx.LightEmission, fx.Drag, fx.RotSpeed = 0.8, 0.6, NumberRange.new(-90, 90)
	fx.Parent = emitterPart
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness = c3, look.light, 1.4
	light.Parent = emitterPart
	-- the board above it
	-- on an attachment in the (unrotated) sparks part: a billboard's offset follows its part's axes,
	-- and the disc is turned on its side, so hung on the disc it sat beside the platform
	local top = Instance.new("Attachment")
	top.Name, top.Position = "BoardPoint", Vector3.new(0, look.height + 3.5, 0)
	top.Parent = emitterPart
	local above = Instance.new("BillboardGui")
	above.Size, above.MaxDistance, above.Adornee = UDim2.fromOffset(240, 130), 140, top
	above.Parent = top
	local name = text(above, { Size = UDim2.new(1, 0, 0.32, 0), Text = "GAME " .. i, TextStrokeTransparency = 0.3 })
	local count = text(above, { Size = UDim2.new(1, 0, 0.4, 0), Position = UDim2.fromScale(0, 0.3), Text = "0/" .. P.size, TextColor3 = Color3.fromRGB(255, 214, 90), TextStrokeTransparency = 0.3 })
	local status = text(above, { Size = UDim2.new(1, 0, 0.28, 0), Position = UDim2.fromScale(0, 0.72), Text = "Stand here to play", TextColor3 = Color3.fromRGB(220, 226, 240), TextStrokeTransparency = 0.3 })
	return { part = pad, name = name, count = count, status = status, position = pad.Position, fx = fx }
end

return PadPortal

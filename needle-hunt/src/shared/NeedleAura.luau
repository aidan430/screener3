-- The Heirloom aura (Config.Aura): every needle of an Heirloom shape gives off energy, in its own
-- skin's colours. Added by shared/NeedleLook to the needle wherever it appears in the world: in a
-- hand, in first person, flying, on a lobby pedestal. (ViewportFrames, like the Collection
-- screen's, don't draw particles, so there you see the needle without it.)
--   a shimmering energy skin round every piece (the ForceField material, which ripples on its own),
--   soft wisps rising off it, a few sparks flicking outwards, and a gentle light.
-- Soft and steady by design: nothing flashes.
local Config = require(script.Parent.Config)

local NeedleAura = {}
local A = Config.Aura

local function rgb(c)
	return Color3.fromRGB(c[1], c[2], c[3])
end

-- The skin's brightest colours, lifted a little, so a dark skin still glows.
local function colours(skin)
	if skin.pattern == "rainbow" then
		return Color3.fromHSV(0.8, 0.55, 1), Color3.fromHSV(0.45, 0.55, 1)
	end
	local list = {}
	for _, c in ipairs(skin.colours) do
		local col = rgb(c)
		local _, _, v = col:ToHSV()
		table.insert(list, { col = col, v = v })
	end
	table.sort(list, function(a, b)
		return a.v > b.v
	end)
	local main, second = list[1].col, (list[2] or list[1]).col
	return main:Lerp(Color3.new(1, 1, 1), A.lift), second:Lerp(Color3.new(1, 1, 1), A.lift)
end

local function seq(a, b)
	return ColorSequence.new(a, b)
end

function NeedleAura.add(model, skin, scale)
	local cf, size = model:GetBoundingBox()
	local main, second = colours(skin)
	local thick = math.max(size.Y, size.Z)
	local aura = Instance.new("Part") -- the space the energy fills
	aura.Name, aura.Anchored, aura.CanCollide, aura.CanQuery, aura.CanTouch, aura.CastShadow = "Aura", true, false, false, false, false
	aura.Size, aura.CFrame, aura.Transparency = Vector3.new(size.X * 1.05, thick * 1.2, thick * 1.2), cf, 1
	aura.Parent = model
	if A.shell then -- an energy skin hugging every piece of the needle, rippling on its own (ForceField)
		for _, part in ipairs(model:GetChildren()) do
			if part:IsA("BasePart") and part.Name ~= "Root" and part ~= aura then
				local shell = part:Clone()
				shell:ClearAllChildren()
				shell.Name, shell.Material, shell.Color, shell.Transparency = "AuraShell", Enum.Material.ForceField, main, 0
				shell.Size = part.Size * A.shellGrow + Vector3.one * A.shellPad * scale
				shell.CFrame = part.CFrame
				shell.Parent = model
			end
		end
	end
	local wisps = Instance.new("ParticleEmitter") -- soft energy rising off it
	wisps.Name, wisps.Texture = "AuraWisps", "rbxasset://textures/particles/smoke_main.dds"
	wisps.Shape, wisps.ShapeStyle, wisps.Rate = Enum.ParticleEmitterShape.Box, Enum.ParticleEmitterShapeStyle.Volume, A.wisps
	wisps.Lifetime, wisps.Speed = NumberRange.new(0.8, 1.6), NumberRange.new(0.2 * scale, 0.6 * scale)
	wisps.Acceleration = Vector3.new(0, A.rise * scale, 0)
	wisps.Rotation, wisps.RotSpeed = NumberRange.new(0, 360), NumberRange.new(-60, 60)
	wisps.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.35, A.wispSize * scale), NumberSequenceKeypoint.new(1, 0) })
	wisps.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.25), NumberSequenceKeypoint.new(1, 1) })
	wisps.Color, wisps.LightEmission, wisps.LightInfluence = seq(main, second), 1, 0
	wisps.Parent = aura
	local sparks = Instance.new("ParticleEmitter") -- little flicks of power outwards
	sparks.Name, sparks.Texture = "AuraSparks", "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Shape, sparks.ShapeStyle, sparks.Rate = Enum.ParticleEmitterShape.Box, Enum.ParticleEmitterShapeStyle.Volume, A.sparks
	sparks.Lifetime, sparks.Speed, sparks.SpreadAngle = NumberRange.new(0.35, 0.7), NumberRange.new(1.2 * scale, 2.6 * scale), Vector2.new(180, 180)
	sparks.Drag = 4
	sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.12 * scale), NumberSequenceKeypoint.new(1, 0) })
	sparks.Transparency = NumberSequence.new(0.1, 1)
	sparks.Color, sparks.LightEmission, sparks.LightInfluence = seq(second, main), 1, 0
	sparks.Parent = aura
	local light = Instance.new("PointLight")
	light.Name, light.Color, light.Range, light.Brightness = "AuraLight", main, A.lightRange * scale, A.light
	light.Parent = aura
	return aura
end

return NeedleAura

-- The hats (Config.Cosmetics, kind "hat"), built from parts on a player's head. Each builder
-- takes the head, the cosmetic, the folder to build into and the size (Config.HatScale), and
-- returns its parts; parts already welded (to a hub that spins) carry the attribute Welded.
-- The halo's hub is welded with a Weld named CosmeticSpin, which client/WorldFx turns slowly.
local Build = require(script.Parent.Build)

local Hats = {}
local ROT90 = CFrame.Angles(0, 0, math.rad(90)) -- a cylinder standing upright

local function colour(c, i)
	local v = c.colours[i] or c.colours[1]
	return if type(v) == "table" then Build.rgb(v) else Color3.new(1, 1, 1)
end

local function bit(spec)
	spec.collide = false
	return Build.part(spec)
end

local function sparkle(part, col, rate)
	local p = Instance.new("ParticleEmitter")
	p.Color = ColorSequence.new(col, Color3.new(1, 1, 1))
	p.LightEmission, p.Rate = 1, rate
	p.Lifetime, p.Speed = NumberRange.new(0.5, 1), NumberRange.new(0.2, 0.6)
	p.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.18), NumberSequenceKeypoint.new(1, 0) })
	p.SpreadAngle = Vector2.new(180, 180)
	p.Parent = part
end

local function glow(part, col, range)
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness = col, range, 0.9
	l.Parent = part
end

function Hats.strawhat(head, c, folder, s)
	local top = head.CFrame * CFrame.new(0, head.Size.Y / 2, 0)
	return {
		bit({ size = Vector3.new(0.14, 2.9 * s, 2.9 * s), shape = "Cylinder", cframe = top * CFrame.new(0, 0.07, 0) * ROT90, color = colour(c, 1), material = "Fabric", parent = folder }),
		bit({ size = Vector3.new(0.8 * s, 1.5 * s, 1.5 * s), shape = "Cylinder", cframe = top * CFrame.new(0, 0.45 * s, 0) * ROT90, color = colour(c, 1), material = "Fabric", parent = folder }),
		bit({ size = Vector3.new(0.22 * s, 1.54 * s, 1.54 * s), shape = "Cylinder", cframe = top * CFrame.new(0, 0.2 * s, 0) * ROT90, color = colour(c, 2), material = "Fabric", parent = folder }),
	}
end

function Hats.bandana(head, c, folder, s)
	local band = head.CFrame * CFrame.new(0, head.Size.Y * 0.3, 0)
	return {
		bit({ size = Vector3.new(0.55 * s, 1.3, 1.3), shape = "Cylinder", cframe = band * ROT90, color = colour(c, 1), material = "Fabric", parent = folder }),
		bit({ size = Vector3.new(0.6 * s, 0.6 * s, 0.25), cframe = head.CFrame * CFrame.new(0, head.Size.Y * 0.22, 0.7) * CFrame.Angles(math.rad(25), 0, 0), color = colour(c, 1), material = "Fabric", parent = folder }),
		bit({ size = Vector3.new(0.2, 0.8 * s, 0.3), cframe = head.CFrame * CFrame.new(0.2, head.Size.Y * 0.05, 0.78) * CFrame.Angles(0, 0, math.rad(-20)), color = colour(c, 1), material = "Fabric", parent = folder }),
		bit({ size = Vector3.new(0.2, 0.7 * s, 0.3), cframe = head.CFrame * CFrame.new(-0.2, head.Size.Y * 0.07, 0.78) * CFrame.Angles(0, 0, math.rad(20)), color = colour(c, 1), material = "Fabric", parent = folder }),
	}
end

-- The Legendary crown: a tall gold band with eight points tipped with pearls, four coloured
-- gems round it, a golden shimmer and a soft light.
function Hats.crown(head, c, folder, s)
	local base = head.CFrame * CFrame.new(0, head.Size.Y / 2 + 0.25 * s, 0)
	local gold, shine = colour(c, 1), colour(c, 2)
	local band = bit({ size = Vector3.new(0.55 * s, 1.5 * s, 1.5 * s), shape = "Cylinder", cframe = base * ROT90, color = gold, material = "Neon", parent = folder })
	local parts = { band }
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		local x, z = math.cos(a) * 0.68 * s, math.sin(a) * 0.68 * s
		local h = if i % 2 == 0 then 0.8 else 0.55
		table.insert(parts, bit({ size = Vector3.new(0.2 * s, h * s, 0.2 * s), cframe = base * CFrame.new(x, (0.27 + h / 2) * s, z), color = gold, material = "Neon", parent = folder }))
		table.insert(parts, bit({ size = Vector3.one * 0.24 * s, shape = "Ball", cframe = base * CFrame.new(x, (0.3 + h) * s, z), color = shine, material = "Neon", parent = folder }))
	end
	for i, gem in ipairs({ { 220, 50, 70 }, { 60, 120, 230 }, { 60, 190, 110 }, { 160, 80, 220 } }) do
		local a = (i - 1) / 4 * math.pi * 2 + math.pi / 2
		table.insert(parts, bit({ size = Vector3.one * 0.3 * s, shape = "Ball", cframe = base * CFrame.new(math.cos(a) * 0.76 * s, 0, math.sin(a) * 0.76 * s), color = gem, material = "Neon", parent = folder }))
	end
	sparkle(band, gold, 8)
	glow(band, gold, 9)
	return parts
end

-- The Mythic halo: a glowing ring floating above the head that turns slowly and twinkles.
function Hats.halo(head, c, folder, s)
	local offset = CFrame.new(0, head.Size.Y / 2 + 0.85 * s, 0)
	local hub = bit({ name = "HaloHub", size = Vector3.one * 0.2, cframe = head.CFrame * offset, transparency = 1, parent = folder })
	local parts = {}
	for i = 0, 15 do
		local a = i / 16 * math.pi * 2
		local seg = bit({ size = Vector3.new(0.2 * s, 0.14 * s, 0.4 * s), cframe = hub.CFrame * CFrame.new(math.cos(a) * 0.95 * s, 0, math.sin(a) * 0.95 * s) * CFrame.Angles(0, -a, 0), color = colour(c, if i % 4 == 0 then 2 else 1), material = "Neon", parent = folder })
		seg.Anchored, seg.Massless, seg.CanQuery, seg.CanTouch = false, true, false, false
		local w = Instance.new("WeldConstraint")
		w.Part0, w.Part1 = hub, seg
		w.Parent = seg
		seg:SetAttribute("Welded", true)
		table.insert(parts, seg)
	end
	hub.Anchored, hub.Massless, hub.CanQuery, hub.CanTouch = false, true, false, false
	local spin = Instance.new("Weld")
	spin.Name = "CosmeticSpin"
	spin.Part0, spin.Part1, spin.C0 = head, hub, offset
	spin:SetAttribute("Base", offset)
	spin.Parent = hub
	hub:SetAttribute("Welded", true)
	sparkle(hub, colour(c, 1), 6)
	glow(hub, colour(c, 1), 8)
	table.insert(parts, hub)
	return parts
end

return Hats

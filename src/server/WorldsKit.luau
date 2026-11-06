-- Shared pieces for the portal worlds: the arches, signs, lights, embers and each world's
-- harvestable haystack (balls of hay like the Golden Loft's, tagged with the World attribute).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Build = require(script.Parent.Build)
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Kit = {}
local terrain = workspace.Terrain

function Kit.folder(name, parent)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

-- A soft glow on a part (PointLight unless `kind` names another light class).
function Kit.light(part, colour, range, brightness, kind)
	local light = Instance.new(kind or "PointLight")
	light.Color = Build.rgb(colour)
	light.Range = range
	light.Brightness = brightness
	if kind == "SpotLight" then
		light.Face = Enum.NormalId.Bottom
		light.Angle = 70
	end
	light.Parent = part
	return light
end

-- Slow drifting sparks (embers, bubbles, dust): calm, never flashing.
function Kit.drift(part, colour, rate, rise, size)
	local p = Instance.new("ParticleEmitter")
	p.Color = ColorSequence.new(Build.rgb(colour))
	p.LightEmission = 0.6
	p.Rate = rate
	p.Lifetime = NumberRange.new(3, 6)
	p.Speed = NumberRange.new(0.5, 2)
	p.SpreadAngle = Vector2.new(40, 40)
	p.Acceleration = Vector3.new(0, rise, 0)
	p.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size or 0.3), NumberSequenceKeypoint.new(1, 0) })
	p.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.2), NumberSequenceKeypoint.new(1, 1) })
	p.Parent = part
	return p
end

-- A flat terrain floor, its top at y = 0 like the farm's.
function Kit.ground(centre, material, size)
	terrain:FillBlock(CFrame.new(centre + Vector3.new(0, -8, 0)), Vector3.new(size, 16, size), material)
end

function Kit.prompt(part, action, text, object, worldId, hold)
	local p = Instance.new("ProximityPrompt")
	p.ActionText = text
	p.ObjectText = object
	p.HoldDuration = hold or 0
	p.MaxActivationDistance = 12
	p.RequiresLineOfSight = false
	p:SetAttribute("Action", action)
	p:SetAttribute("World", worldId)
	p.Parent = part
	return p
end

-- A sign board: text on its front (the -Z face of `cf`).
function Kit.sign(cf, size, text, colour, ink, parent)
	local board = Build.part({ name = "Sign", size = size, cframe = cf, color = colour, material = "SmoothPlastic", parent = parent })
	Build.text(board, Enum.NormalId.Front, text, { color = Build.rgb(ink), pixels = 30 })
	return board
end

-- A glowing portal arch standing at `cf` (its base), opening towards cf's look direction.
-- Returns the glowing membrane (put the prompt on it).
function Kit.arch(cf, colour, parent, title, subtitle)
	local model = Instance.new("Model")
	model.Name = "Portal"
	local stone = { 70, 66, 80 }
	Build.part({ name = "PortalStep", size = Vector3.new(13, 0.6, 4), cframe = cf * CFrame.new(0, 0.3, 0), color = stone, material = "Slate", parent = model })
	for _, x in ipairs({ -5.6, 5.6 }) do
		Build.part({ name = "PortalPillar", size = Vector3.new(1.6, 13, 1.6), cframe = cf * CFrame.new(x, 6.5, 0), color = stone, material = "Slate", parent = model })
		local gem = Build.part({ name = "PortalGem", shape = "Ball", size = Vector3.new(1.6, 1.6, 1.6), cframe = cf * CFrame.new(x, 13.9, 0), color = colour, material = "Neon", parent = model })
		Kit.light(gem, colour, 10, 0.6)
	end
	Build.part({ name = "PortalLintel", size = Vector3.new(12.8, 1.4, 1.8), cframe = cf * CFrame.new(0, 13.4, 0), color = stone, material = "Slate", parent = model })
	local membrane = Build.part({ name = "PortalGlow", size = Vector3.new(9.6, 12.2, 0.3), cframe = cf * CFrame.new(0, 6.7, 0), color = colour, material = "Neon", transparency = 0.45, collide = false, parent = model })
	Kit.light(membrane, colour, 16, 1)
	Kit.drift(membrane, colour, 6, 1.2, 0.35)
	local sign = Kit.sign(cf * CFrame.new(0, 16.4, 0), Vector3.new(12, 3.6, 0.4), title .. "\n" .. subtitle, { 40, 34, 48 }, colour, model)
	sign.Material = Enum.Material.Slate
	model.Parent = parent
	return membrane
end

-- The world's haystack: a mound of balls, each one harvestable (attribute World = id).
function Kit.haystack(worldId, centre, parent)
	local colours = Config.WorldHay[worldId]
	local size = Config.WorldHaystackSize
	local model = Instance.new("Model")
	model.Name = "Haystack"
	local function ball(label, diameter, offset, colour)
		local part = Build.part({ name = label, shape = "Ball", size = Vector3.new(diameter, diameter, diameter), cframe = CFrame.new(centre + offset), color = colour, material = "Sand", parent = model })
		part:SetAttribute("World", worldId)
		return part
	end
	ball("WorldHayCore", size, Vector3.new(0, size * 0.14, 0), colours[1])
	for i = 1, 10 do
		local a = i / 10 * math.pi * 2
		ball("WorldHayLump", size * (0.5 + (i % 3) * 0.06), Vector3.new(math.cos(a) * size * 0.36, size * 0.02, math.sin(a) * size * 0.36), colours[i % 3 + 1])
	end
	ball("WorldHayTop", size * 0.42, Vector3.new(size * 0.04, size * 0.58, -size * 0.04), colours[3])
	model.Parent = parent
	return model
end

-- Where you arrive in a world, and the return portal just behind you.
function Kit.arrival(w)
	local centre = Vector3.new(w.x, 0, w.z)
	return CFrame.lookAt(centre + Vector3.new(0, 4, 100), centre + Vector3.new(0, 4, 0))
end

function Kit.returnPortal(w, parent)
	local base = Vector3.new(w.x, 0, w.z + 114)
	local cf = CFrame.lookAt(base, Vector3.new(w.x, 0, w.z))
	local membrane = Kit.arch(cf, Config.WorldHay[w.id][3], parent, "Back to the farm", w.name)
	Kit.prompt(membrane, "portal_home", "Go back to the farm", w.name, w.id, 0)
	return membrane
end

return Kit

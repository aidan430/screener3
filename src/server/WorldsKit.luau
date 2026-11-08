-- Shared pieces for the portal worlds: the arches, signs, lights, embers and each world's
-- harvestable haystack (balls of hay like the Golden Loft's, tagged with the World attribute).
local CollectionService = game:GetService("CollectionService")
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

-- A sign board: text on its front (the -Z face of `cf`).
function Kit.sign(cf, size, text, colour, ink, parent)
	local board = Build.part({ name = "Sign", size = size, cframe = cf, color = colour, material = "SmoothPlastic", parent = parent })
	Build.text(board, Enum.NormalId.Front, text, { color = Build.rgb(ink), pixels = 30 })
	return board
end

-- A portal standing at `cf` (its base), opening towards cf's look direction (server/WorldsPortal).
-- Returns the face over its opening (put a walk-in trigger on it: Kit.trigger).
function Kit.arch(cf, colour, parent, title, subtitle)
	return require(script.Parent.WorldsPortal).build(cf, colour, parent, title, subtitle, Kit)
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

-- A walk-in trigger over an arch's membrane: walking into it travels to `to` ("lobby", "farm"
-- or a Config.Worlds id; server/Lobby.luau listens). `from` says which arch it is, so coming
-- back to the lobby lands you in front of that world's arch.
function Kit.trigger(membrane, to, from)
	local part = Build.part({ name = "PortalTrigger", size = Vector3.new(membrane.Size.X, membrane.Size.Y, 2), cframe = membrane.CFrame, transparency = 1, collide = false, shadow = false, parent = membrane.Parent })
	part.CanTouch = true -- (Build.part turns touching off for parts you walk through)
	part:SetAttribute("To", to)
	part:SetAttribute("From", from)
	CollectionService:AddTag(part, "WalkPortal")
	return part
end

-- The arch just behind where you arrive in a world: walk in to go back to the lobby.
function Kit.returnPortal(w, parent)
	local base = Vector3.new(w.x, 0, w.z + 114)
	local cf = CFrame.lookAt(base, Vector3.new(w.x, 0, w.z))
	local membrane = Kit.arch(cf, Config.WorldHay[w.id][3], parent, "Back to the lobby", Config.LobbyName)
	Kit.trigger(membrane, "lobby", w.id)
	return membrane
end

return Kit

-- The portal arches, a round "moon gate": a ring of stone rising from a two-step round plinth,
-- its face a disc of light in the portal's colour that flows upwards (Config.PortalTexture, one
-- white texture every portal tints; client/WorldFx scrolls it), a glowing inner lip, a keystone
-- gem, two lanterns at the front and a sign above. The ring stops at the floor, so you walk
-- straight in.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Build = require(script.Parent.Build)
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Portal = {}
local RADIUS = 5.6 -- the ring's middle (studs)
local FLOOR = 1.1 -- the plinth's top
local CENTRE = FLOOR + RADIUS - 1.2 -- the ring's centre: its foot sits just under the floor
local STONE, STONE2, WOOD = { 84, 78, 92 }, { 104, 98, 110 }, { 92, 66, 44 }
local UPRIGHT = CFrame.Angles(0, 0, math.rad(90)) -- a cylinder standing on end

-- Blocks round a circle in cf's X-Y plane, leaving out any below the floor.
local function ring(model, centre, radius, count, thick, depth, colourOf, material, name, transparency)
	local length = 2 * radius * math.tan(math.pi / count) + thick * 0.5
	for i = 0, count - 1 do
		local a = (i + 0.5) / count * math.pi * 2
		local y = radius * math.sin(a)
		if CENTRE + y > FLOOR - 0.2 then
			Build.part({ name = name, size = Vector3.new(thick, length, depth), cframe = centre * CFrame.new(radius * math.cos(a), y, 0) * CFrame.Angles(0, 0, a), color = colourOf(i), material = material, transparency = transparency, collide = material ~= "Neon", parent = model })
		end
	end
end

-- Builds a portal standing at `cf` (its base), opening towards cf's look direction. Returns the
-- face: an invisible flat part over the opening (Kit.trigger puts the walk-in trigger on it).
function Portal.build(cf, colour, parent, title, subtitle, Kit)
	local model = Instance.new("Model")
	model.Name = "Portal"
	Build.part({ name = "PortalStep", shape = "Cylinder", size = Vector3.new(0.6, 16, 16), cframe = cf * CFrame.new(0, 0.3, 0) * UPRIGHT, color = STONE, material = "Slate", parent = model })
	Build.part({ name = "PortalStep", shape = "Cylinder", size = Vector3.new(0.5, 13, 13), cframe = cf * CFrame.new(0, 0.85, 0) * UPRIGHT, color = STONE2, material = "Slate", parent = model })
	local centre = cf * CFrame.new(0, CENTRE, 0)
	ring(model, centre, RADIUS, 22, 1.5, 1.8, function(i)
		return if i % 2 == 0 then STONE else STONE2
	end, "Slate", "PortalStone")
	ring(model, centre, RADIUS - 0.82, 28, 0.2, 0.6, function()
		return colour
	end, "Neon", "PortalLip", 0.15)
	local opening = 2 * (RADIUS - 0.9)
	local disc = Build.part({ name = "PortalDisc", shape = "Cylinder", size = Vector3.new(0.2, opening, opening), cframe = centre * CFrame.Angles(0, math.rad(90), 0), color = colour, material = "Neon", transparency = 0.55, collide = false, parent = model })
	if Config.PortalTexture ~= "" then
		for _, face in ipairs({ Enum.NormalId.Left, Enum.NormalId.Right }) do -- the disc's two flat sides
			local flow = Instance.new("Texture")
			flow.Texture = Config.PortalTexture
			flow.Face = face
			flow.Color3 = Build.rgb(colour):Lerp(Color3.new(1, 1, 1), 0.35)
			flow.StudsPerTileU, flow.StudsPerTileV = opening, opening
			flow.Transparency = 0.1
			flow.Parent = disc
			CollectionService:AddTag(flow, "PortalFlow")
		end
	end
	local gem = Build.part({ name = "PortalGem", size = Vector3.new(1.4, 1.8, 1.4), cframe = centre * CFrame.new(0, RADIUS + 0.9, 0) * CFrame.Angles(0, math.rad(45), 0), color = colour, material = "Neon", parent = model })
	Kit.light(gem, colour, 10, 0.6)
	for _, x in ipairs({ -6.6, 6.6 }) do -- a lantern on a post at each front corner of the plinth
		Build.part({ name = "PortalPost", size = Vector3.new(0.4, 3.2, 0.4), cframe = cf * CFrame.new(x, FLOOR + 1.6, -2.6), color = WOOD, material = "Wood", parent = model })
		local lamp = Build.part({ name = "PortalLantern", size = Vector3.new(0.8, 0.9, 0.8), cframe = cf * CFrame.new(x, FLOOR + 3.6, -2.6), color = colour, material = "Neon", collide = false, parent = model })
		Build.part({ name = "PortalLanternCap", size = Vector3.new(1, 0.2, 1), cframe = cf * CFrame.new(x, FLOOR + 4.15, -2.6), color = WOOD, material = "Wood", parent = model })
		Kit.light(lamp, colour, 8, 0.5)
	end
	local face = Build.part({ name = "PortalGlow", size = Vector3.new(opening, opening, 0.3), cframe = centre, transparency = 1, collide = false, shadow = false, parent = model })
	Kit.light(face, colour, 16, 1)
	Kit.drift(face, colour, 6, 1.2, 0.35)
	local sign = Kit.sign(cf * CFrame.new(0, CENTRE + RADIUS + 3.4, 0), Vector3.new(11, 3.2, 0.4), title .. "\n" .. subtitle, { 40, 34, 48 }, colour, model)
	sign.Material = Enum.Material.Slate
	model.Parent = parent
	return face
end

return Portal

-- The gadget tools' shapes (Config.Tools[n].shape): Hay Blower, Magnet Gloves, Twin Turbines
-- and the Needle Detector. Same space and return value as ToolParts (see there).
local P = require(script.Parent.ToolParts)

local ToolGadgets = {}
local ROLL, FLAT, UPRIGHT = P.ROLL, P.FLAT, P.UPRIGHT
local GREY, DARK, RUBBER = P.GREY, P.DARK, P.RUBBER

local function emitter(part, colour, rate, speed, size, direction)
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(colour)
	e.Rate, e.Speed, e.Lifetime = rate, NumberRange.new(speed * 0.5, speed), NumberRange.new(0.4, 0.8)
	e.Size = NumberSequence.new(size[1], size[2])
	e.Transparency = NumberSequence.new(0.6, 1)
	e.LightEmission = 0.6
	e.SpreadAngle = Vector2.new(15, 15)
	e.EmitDirection = direction or Enum.NormalId.Top
	e.Parent = part
	return e
end

local function light(part, colour, range)
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness = colour, range, 0.8
	l.Parent = part
end

-- Hay Blower: held by its pistol grip; a motor body, a side fan with a grille, a long nozzle
-- that puffs a little air, and a hopper on top where the hay rides.
function ToolGadgets.blower(k)
	P.trim(k, Vector3.new(0.12, 0.22, 0.3), CFrame.new(0, 0.42, 0.05), { 200, 60, 50 }, "SmoothPlastic") -- trigger
	P.head(k, Vector3.new(1.1, 1.8, 0.9), CFrame.new(0, 0.2, 0.65))
	P.trim(k, Vector3.new(0.4, 1.2, 1.2), CFrame.new(0.72, 0, 0.65), DARK, "SmoothPlastic", "Cylinder")
	P.trim(k, Vector3.new(0.05, 0.9, 0.9), CFrame.new(0.93, 0, 0.65), GREY, "DiamondPlate", "Cylinder")
	P.trim(k, Vector3.new(2.6, 0.48, 0.48), CFrame.new(0, 2.35, 0.6) * ROLL, { 225, 225, 230 }, "SmoothPlastic", "Cylinder")
	local mouth = P.head(k, Vector3.new(0.35, 0.75, 0.75), CFrame.new(0, 3.75, 0.6) * ROLL, "Cylinder")
	emitter(mouth, Color3.fromRGB(245, 240, 225), 5, 6, { 0.3, 0.8 }, Enum.NormalId.Right)
	P.trim(k, Vector3.new(1.2, 1.3, 0.08), CFrame.new(0, 0.2, 1.14), GREY, "Metal")
	for _, s in ipairs({ -1, 1 }) do
		P.trim(k, Vector3.new(1.2, 0.08, 0.35), CFrame.new(0, 0.2 + s * 0.65, 1.3), GREY, "Metal")
		P.trim(k, Vector3.new(0.08, 1.3, 0.35), CFrame.new(s * 0.6, 0.2, 1.3), GREY, "Metal")
	end
	return { length = 1, hold = 0, seat = CFrame.new(0, 0.2, 1.18) * UPRIGHT, load = 1.15, material = "SmoothPlastic" }
end

-- Magnet Gloves: a big horseshoe magnet with silver poles, held out front; the hay floats
-- between its arms in a soft blue shimmer.
function ToolGadgets.magnet(k)
	P.trim(k, Vector3.new(1.0, 0.42, 0.42), CFrame.new(0, -0.2, 0) * ROLL, RUBBER, "Fabric", "Cylinder")
	local r = 0.85
	P.ring(k, CFrame.new(0, 1.5, 0), r, 8, 0.42, 0.42, nil, nil, math.pi, math.pi * 2)
	for _, s in ipairs({ -1, 1 }) do
		P.head(k, Vector3.new(0.42, 1.4, 0.42), CFrame.new(s * r, 2.2, 0))
		P.trim(k, Vector3.new(0.44, 0.5, 0.44), CFrame.new(s * r, 3.15, 0), { 215, 218, 224 }, "Metal")
	end
	local field = P.trim(k, Vector3.new(1.4, 0.2, 0.2), CFrame.new(0, 3.2, 0), { 150, 210, 255 }, "SmoothPlastic")
	field.Transparency = 1
	emitter(field, Color3.fromRGB(150, 210, 255), 8, 0.4, { 0.15, 0 })
	light(field, Color3.fromRGB(150, 210, 255), 5)
	return { length = 1.8, hold = -0.2, seat = CFrame.new(0, 2.5, -0.5) * UPRIGHT, load = 1.1, material = "SmoothPlastic" }
end

-- Twin Turbines: two fans in round housings on a cross frame; the fans spin (client/WorldFx
-- turns each "Spin" weld) and the hay rides on a deck between them.
function ToolGadgets.turbines(k)
	P.trim(k, Vector3.new(1.1, 0.4, 0.4), CFrame.new(0, -0.8, 0) * ROLL, RUBBER, "Fabric", "Cylinder")
	P.trim(k, Vector3.new(0.3, 0.3, 0.75), CFrame.new(0, 1.9, -0.4), DARK, "Metal")
	P.trim(k, Vector3.new(3.2, 0.35, 0.3), CFrame.new(0, 2.0, -0.85), DARK, "Metal")
	P.trim(k, Vector3.new(0.8, 1.1, 0.12), CFrame.new(0, 1.5, 0.21), { 120, 84, 50 }, "WoodPlanks")
	for _, s in ipairs({ -1, 1 }) do
		local centre = CFrame.new(s * 1.15, 2.0, 0)
		P.ring(k, centre * UPRIGHT, 0.72, 14, 0.12, 0.5)
		local hub = P.trim(k, Vector3.new(0.4, 0.36, 0.36), centre * ROLL, GREY, "Metal", "Cylinder")
		for i = 0, 2 do
			local blade = P.head(k, Vector3.new(0.3, 0.06, 0.56), centre * CFrame.Angles(0, i * math.pi * 2 / 3, 0) * CFrame.new(0, 0, 0.36) * CFrame.Angles(0, 0, math.rad(25)))
			blade:FindFirstChildOfClass("WeldConstraint").Part0 = hub -- turns with the hub
		end
		hub:FindFirstChildOfClass("WeldConstraint"):Destroy()
		local spin = Instance.new("Weld")
		spin.Name = "Spin"
		spin.Part0, spin.Part1 = k.handle, hub
		spin.C0 = centre * ROLL
		spin:SetAttribute("Base", centre * ROLL)
		spin.Parent = hub
	end
	return { length = 4, hold = -0.8, seat = CFrame.new(0, 1.5, 0.27) * UPRIGHT, load = 1.15, material = "Metal" }
end

-- Needle Detector: an arm cuff, a control box with a glowing screen, and a search coil held
-- low in front, where the hay rides.
function ToolGadgets.detector(k)
	P.trim(k, Vector3.new(1.0, 0.36, 0.36), CFrame.new(0, -1.0, 0) * ROLL, RUBBER, "Fabric", "Cylinder")
	P.ring(k, CFrame.new(0, -2.2, 0.38) * UPRIGHT, 0.34, 7, 0.08, 0.35, DARK, "SmoothPlastic", math.pi, math.pi * 2)
	P.trim(k, Vector3.new(0.12, 0.12, 0.12), CFrame.new(0, -2.2, 0.1), DARK, "Metal")
	P.trim(k, Vector3.new(0.55, 0.9, 0.45), CFrame.new(0, 0.2, 0.35), DARK, "SmoothPlastic")
	local screen = P.head(k, Vector3.new(0.42, 0.6, 0.04), CFrame.new(0, 0.25, 0.59))
	light(screen, screen.Color, 4)
	P.bar(k, Vector3.new(0, 2.4, 0), Vector3.new(0, 3.1, -0.45), 0.2, GREY, "Metal")
	P.trim(k, Vector3.new(0.12, 1.9, 1.9), CFrame.new(0, 3.55, -0.52) * FLAT, DARK, "SmoothPlastic", "Cylinder")
	P.ring(k, CFrame.new(0, 3.55, -0.46), 0.95, 16, 0.12, 0.16)
	return { length = 5, hold = -1.0, seat = CFrame.new(0, 3.55, -0.44) * UPRIGHT, load = 1.5, material = "Metal" }
end

return ToolGadgets

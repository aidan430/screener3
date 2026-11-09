-- The gadget tools' shapes (Config.Tools[n].shape), drawn from the owner's tool sheet: the Hay
-- Blower, Magnet Gloves, Twin Turbines and the Needle Detector. Same space and return value as
-- ToolParts (see there). Fans turn on every screen: client/WorldFx spins each "Spin" weld.
local P = require(script.Parent.ToolParts)

local ToolGadgets = {}
local ROLL, FLAT, UPRIGHT = P.ROLL, P.FLAT, P.UPRIGHT
local GREY, DARK, RUBBER = P.GREY, P.DARK, P.RUBBER
local SILVER = { 214, 218, 226 }

-- A fan that turns: a hub at `front` (facing +Y) with `count` blades, on a "Spin" weld.
local function fan(k, front, radius, count, colour)
	local hub = P.trim(k, Vector3.new(0.16, radius * 0.4, radius * 0.4), front * ROLL, GREY, "Metal", "Cylinder")
	local nose = P.trim(k, Vector3.new(radius * 0.35, radius * 0.35, radius * 0.35), front * CFrame.new(0, 0.08, 0), GREY, "Metal", "Ball")
	nose:FindFirstChildOfClass("WeldConstraint").Part0 = hub
	for i = 0, count - 1 do
		local cf = front * CFrame.Angles(0, i * math.pi * 2 / count, 0) * CFrame.new(0, 0, radius * 0.55) * CFrame.Angles(0, 0, math.rad(30))
		local blade = if colour then P.trim(k, Vector3.new(radius * 0.38, 0.04, radius * 0.75), cf, colour, "Metal") else P.head(k, Vector3.new(radius * 0.38, 0.04, radius * 0.75), cf)
		blade:FindFirstChildOfClass("WeldConstraint").Part0 = hub -- turns with the hub
	end
	hub:FindFirstChildOfClass("WeldConstraint"):Destroy()
	local spin = Instance.new("Weld")
	spin.Name = "Spin"
	spin.Part0, spin.Part1 = k.handle, hub
	spin.C0 = P.scaled(k, front * ROLL)
	spin:SetAttribute("Base", spin.C0)
	spin.Parent = hub
	return hub
end

-- Hay Blower: a chunky rounded body with charcoal panels, a carry handle on top, a pistol grip
-- below, and a big round nozzle at the front with its fan turning inside.
function ToolGadgets.blower(k)
	P.trim(k, Vector3.new(0.7, 0.36, 0.36), CFrame.new(0, -0.05, -0.15) * CFrame.Angles(math.rad(20), 0, 0) * ROLL, RUBBER, "Fabric", "Cylinder")
	P.trim(k, Vector3.new(0.12, 0.2, 0.26), CFrame.new(0, 0.3, -0.05), { 200, 60, 50 }, "SmoothPlastic") -- trigger
	P.head(k, Vector3.new(1.25, 1.5, 1.0), CFrame.new(0, 0.45, 0.62))
	P.head(k, Vector3.new(1.25, 1.0, 1.0), CFrame.new(0, -0.3, 0.62) * ROLL, "Cylinder") -- the rounded back
	P.trim(k, Vector3.new(1.28, 1.6, 0.34), CFrame.new(0, 0.3, 0.2), DARK, "SmoothPlastic") -- charcoal underside
	P.trim(k, Vector3.new(1.27, 0.5, 0.5), CFrame.new(0, -0.55, 0.62), DARK, "SmoothPlastic") -- the motor's end
	for _, y in ipairs({ -0.05, 0.75 }) do -- the carry handle
		P.trim(k, Vector3.new(0.18, 0.18, 0.42), CFrame.new(0, y, 1.3), DARK, "SmoothPlastic")
	end
	P.trim(k, Vector3.new(0.2, 1.0, 0.2), CFrame.new(0, 0.35, 1.5), DARK, "SmoothPlastic")
	local front = CFrame.new(0, 1.55, 0.72)
	P.head(k, Vector3.new(0.7, 1.15, 1.15), CFrame.new(0, 1.3, 0.72) * ROLL, "Cylinder")
	P.ring(k, front * UPRIGHT, 0.62, 18, 0.16, 0.24, DARK, "SmoothPlastic") -- the nozzle's lip
	P.trim(k, Vector3.new(0.04, 1.05, 1.05), CFrame.new(0, 1.62, 0.72) * ROLL, { 34, 36, 42 }, "SmoothPlastic", "Cylinder")
	local hub = fan(k, CFrame.new(0, 1.58, 0.72), 0.55, 5, { 200, 204, 212 })
	P.emitter(hub, Color3.fromRGB(245, 240, 225), 4, 6, { 0.3, 0.8 }, Enum.NormalId.Right)
	-- the hay rides on top, in front of the carry handle, where you can see it from behind
	return { length = 0.8, hold = -0.05, seat = CFrame.new(0, 1.1, 1.12) * UPRIGHT, load = 1.0, material = "SmoothPlastic", hidden = true }
end

-- One magnet glove: a silver cuff, a padded red glove with four fingers and a thumb, silver
-- knuckle bands, and a horseshoe magnet on the palm (the side facing away from you).
local function glove(k, x, thumbSide)
	P.trim(k, Vector3.new(0.5, 0.95, 0.95), CFrame.new(x, -0.45, 0.35) * ROLL, SILVER, "Metal", "Cylinder")
	P.head(k, Vector3.new(1.0, 0.5, 1.0), CFrame.new(x, 0.05, 0.45))
	for i = 0, 3 do
		local fx = x - 0.36 + i * 0.24
		P.head(k, Vector3.new(0.22, 0.42, 0.55), CFrame.new(fx, 0.05, 1.22))
		P.head(k, Vector3.new(0.22, 0.22, 0.22), CFrame.new(fx, 0.05, 1.5), "Ball")
		P.trim(k, Vector3.new(0.24, 0.44, 0.1), CFrame.new(fx, 0.05, 1.0), SILVER, "Metal")
	end
	P.head(k, Vector3.new(0.24, 0.42, 0.55), CFrame.new(x + thumbSide * 0.62, 0.05, 0.62) * CFrame.Angles(0, math.rad(thumbSide * 30), 0))
	-- the horseshoe magnet on the palm, opening upwards, with red-and-silver tips
	P.ring(k, CFrame.new(x, 0.34, 0.5) * CFrame.Angles(math.rad(90), 0, 0), 0.3, 7, 0.15, 0.12, GREY, "Metal", math.pi, math.pi * 2)
	for _, s in ipairs({ -1, 1 }) do
		P.trim(k, Vector3.new(0.15, 0.12, 0.3), CFrame.new(x + s * 0.3, 0.34, 0.65), GREY, "Metal")
		P.trim(k, Vector3.new(0.16, 0.13, 0.12), CFrame.new(x + s * 0.3, 0.34, 0.84), SILVER, "Metal")
	end
end

-- Magnet Gloves: a pair, held up in front of you, palms out; the hay floats between them in a
-- soft blue shimmer. The right glove is on the tool's grip, the left beside it.
function ToolGadgets.magnet(k)
	glove(k, 0, -1)
	glove(k, -2.3, 1)
	local field = P.trim(k, Vector3.new(0.8, 0.2, 0.2), CFrame.new(-1.15, 0.6, 0.6), { 150, 210, 255 }, "SmoothPlastic")
	field.Transparency = 1
	P.emitter(field, Color3.fromRGB(150, 210, 255), 8, 0.4, { 0.15, 0 })
	P.light(field, Color3.fromRGB(150, 210, 255), 5)
	return { length = 0.8, hold = -0.4, seat = CFrame.new(-1.15, 0.6, 0.15) * UPRIGHT, load = 1.1, material = "SmoothPlastic", hidden = true }
end

-- Twin Turbines: two amber pods side by side with black bands, a fan turning at the front of each
-- and a warm glow at the back, joined by a black bar and a looped handle you hold behind them.
function ToolGadgets.turbines(k)
	P.trim(k, Vector3.new(0.8, 0.36, 0.36), CFrame.new(0, 0, 0) * ROLL, RUBBER, "Fabric", "Cylinder") -- the grip
	P.trim(k, Vector3.new(1.4, 0.26, 0.26), CFrame.new(0, 0.45, 0), RUBBER, "Fabric") -- the loop behind the pods
	for _, s in ipairs({ -1, 1 }) do
		P.bar(k, Vector3.new(s * 0.62, 0.45, 0), Vector3.new(s * 0.62, 0.95, 0.06), 0.26, RUBBER, "Fabric")
	end
	P.trim(k, Vector3.new(2.1, 0.34, 0.34), CFrame.new(0, 1.0, 0.1), RUBBER, "Fabric")
	for _, s in ipairs({ -1, 1 }) do
		local centre = CFrame.new(s * 1.15, 1.0, 0.1)
		P.head(k, Vector3.new(1.3, 1.3, 1.3), centre * ROLL, "Cylinder")
		for _, y in ipairs({ -0.5, 0.52 }) do -- black bands
			P.trim(k, Vector3.new(0.18, 1.36, 1.36), centre * CFrame.new(0, y, 0) * ROLL, { 30, 30, 34 }, "SmoothPlastic", "Cylinder")
		end
		P.trim(k, Vector3.new(0.04, 1.05, 1.05), centre * CFrame.new(0, 0.62, 0) * ROLL, { 40, 30, 20 }, "SmoothPlastic", "Cylinder")
		fan(k, centre * CFrame.new(0, 0.64, 0), 0.6, 10, { 236, 150, 50 })
		local exhaust = P.trim(k, Vector3.new(0.04, 0.85, 0.85), centre * CFrame.new(0, -0.61, 0) * ROLL, { 255, 150, 60 }, "Neon", "Cylinder")
		P.light(exhaust, Color3.fromRGB(255, 150, 60), 4)
	end
	return { length = 0.6, hold = 0, seat = CFrame.new(0, 1.0, 0.28) * UPRIGHT, load = 1.15, material = "Fabric", hidden = true }
end

-- Needle Detector: a black grip with a silver end cap, a silver body with a glowing screen, a
-- slim neck, and a round dish at the end with glowing rings, where the hay rides.
function ToolGadgets.detector(k)
	P.trim(k, Vector3.new(1.3, 0.42, 0.42), CFrame.new(0, -1.0, 0) * ROLL, RUBBER, "Fabric", "Cylinder")
	P.trim(k, Vector3.new(0.46, 0.46, 0.46), CFrame.new(0, -1.7, 0), SILVER, "Metal", "Ball")
	P.trim(k, Vector3.new(1.1, 0.62, 0.62), CFrame.new(0, 0.1, 0) * ROLL, SILVER, "Metal", "Cylinder")
	P.trim(k, Vector3.new(0.42, 0.56, 0.06), CFrame.new(0, 0.1, 0.3), DARK, "SmoothPlastic")
	local screen = P.head(k, Vector3.new(0.32, 0.44, 0.04), CFrame.new(0, 0.1, 0.33))
	P.light(screen, screen.Color, 4)
	P.trim(k, Vector3.new(0.04, 0.36, 0.08), CFrame.new(0.31, 0.1, 0.05), GREY, "Metal") -- the needle badge
	P.trim(k, Vector3.new(1.0, 0.28, 0.28), CFrame.new(0, 1.15, 0) * ROLL, DARK, "SmoothPlastic", "Cylinder")
	P.trim(k, Vector3.new(0.34, 0.34, 0.34), CFrame.new(0, 1.7, 0), DARK, "Metal", "Ball")
	local y = 2.75
	P.trim(k, Vector3.new(0.14, 2.0, 2.0), CFrame.new(0, y, -0.05) * FLAT, SILVER, "Metal", "Cylinder")
	P.trim(k, Vector3.new(0.05, 1.7, 1.7), CFrame.new(0, y, 0.03) * FLAT, { 40, 44, 52 }, "SmoothPlastic", "Cylinder")
	P.ring(k, CFrame.new(0, y, 0.06), 0.72, 20, 0.1, 0.05)
	P.ring(k, CFrame.new(0, y, 0.06), 0.42, 14, 0.1, 0.05)
	P.head(k, Vector3.new(0.05, 0.22, 0.22), CFrame.new(0, y, 0.07) * FLAT, "Cylinder")
	return { length = 1.2, hold = -1.0, seat = CFrame.new(0, y, 0.06) * UPRIGHT, load = 1.5, material = "Fabric", hidden = true }
end

return ToolGadgets

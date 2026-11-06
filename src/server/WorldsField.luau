-- Haystack Stadium: a striped grass pitch with its lines and two goals, stands of seats on three
-- sides, four floodlight towers and a scoreboard (each player's screen writes their own world
-- score on it: client Worlds.luau). The south end is open: you arrive behind the south goal.
local Build = require(script.Parent.Build)
local Kit = require(script.Parent.WorldsKit)

local Field = {}
local WHITE = { 246, 246, 240 }
local STRIPES = { { 76, 150, 60 }, { 90, 168, 72 } }
local SEATS = { { 200, 60, 50 }, { 245, 200, 66 }, { 64, 136, 206 } }
local CONCRETE = { 170, 170, 168 }
local LONG, WIDE = 170, 100 -- the pitch runs along z

local function line(at, sx, sz, folder)
	Build.part({ name = "Line", size = Vector3.new(sx, 0.1, sz), cframe = CFrame.new(at + Vector3.new(0, 0.45, 0)), color = WHITE, material = "SmoothPlastic", parent = folder })
end

local function markings(c, folder)
	local hl, hw = LONG / 2, WIDE / 2
	line(c + Vector3.new(-hw, 0, 0), 0.6, LONG, folder)
	line(c + Vector3.new(hw, 0, 0), 0.6, LONG, folder)
	for _, s in ipairs({ -1, 1 }) do
		line(c + Vector3.new(0, 0, s * hl), WIDE, 0.6, folder)
		line(c + Vector3.new(0, 0, s * (hl - 16)), 40, 0.6, folder) -- the penalty box
		line(c + Vector3.new(-20, 0, s * (hl - 8)), 0.6, 16, folder)
		line(c + Vector3.new(20, 0, s * (hl - 8)), 0.6, 16, folder)
		line(c + Vector3.new(0, 0, s * (hl - 6)), 18, 0.6, folder) -- the goal box
		line(c + Vector3.new(-9, 0, s * (hl - 3)), 0.6, 6, folder)
		line(c + Vector3.new(9, 0, s * (hl - 3)), 0.6, 6, folder)
		Build.part({ name = "Spot", shape = "Cylinder", size = Vector3.new(0.1, 1, 1), cframe = CFrame.new(c + Vector3.new(0, 0.45, s * (hl - 11))) * CFrame.Angles(0, 0, math.rad(90)), color = WHITE, parent = folder })
		for _, x in ipairs({ -hw, hw }) do -- corner flags
			Build.post({ name = "CornerPole", color = WHITE, material = "SmoothPlastic", parent = folder }, CFrame.new(c + Vector3.new(x, 0, s * hl)), 4, 0.2)
			Build.part({ name = "CornerFlag", size = Vector3.new(0.1, 1, 1.4), cframe = CFrame.new(c + Vector3.new(x, 3.5, s * hl + 0.7 * -s)), color = { 245, 200, 66 }, material = "Fabric", collide = false, parent = folder })
		end
	end
	line(c, WIDE, 0.6, folder) -- the halfway line
	for i = 0, 35 do -- the centre circle, round the haystack
		local a = i / 36 * math.pi * 2
		local p = c + Vector3.new(math.cos(a) * 24, 0, math.sin(a) * 24)
		Build.part({ name = "Line", size = Vector3.new(0.6, 0.1, 4.4), cframe = CFrame.new(p + Vector3.new(0, 0.45, 0)) * CFrame.Angles(0, -a, 0), color = WHITE, parent = folder })
	end
end

local function goal(c, s, folder)
	local mouth = c + Vector3.new(0, 0, s * LONG / 2)
	for _, x in ipairs({ -7.3, 7.3 }) do
		Build.post({ name = "GoalPost", color = WHITE, material = "Metal", parent = folder }, CFrame.new(mouth + Vector3.new(x, 0, 0)), 8, 0.6)
		Build.post({ name = "GoalBack", color = WHITE, material = "Metal", parent = folder }, CFrame.new(mouth + Vector3.new(x, 0, s * 4)), 6, 0.3)
		Build.part({ name = "NetSide", size = Vector3.new(0.1, 7, 4), cframe = CFrame.new(mouth + Vector3.new(x, 3.5, s * 2)), color = WHITE, material = "Fabric", transparency = 0.6, parent = folder })
	end
	Build.part({ name = "Crossbar", shape = "Cylinder", size = Vector3.new(15.2, 0.6, 0.6), cframe = CFrame.new(mouth + Vector3.new(0, 8, 0)), color = WHITE, material = "Metal", parent = folder })
	Build.part({ name = "NetBack", size = Vector3.new(14.6, 6, 0.1), cframe = CFrame.new(mouth + Vector3.new(0, 3, s * 4)), color = WHITE, material = "Fabric", transparency = 0.6, parent = folder })
	Build.part({ name = "NetTop", size = Vector3.new(14.6, 0.1, 4.2), cframe = CFrame.new(mouth + Vector3.new(0, 7.2, s * 2)) * CFrame.Angles(s * math.rad(-14), 0, 0), color = WHITE, material = "Fabric", transparency = 0.6, parent = folder })
end

-- A stand: `rows` steps rising away from the pitch, seats in coloured blocks with aisles.
-- `cf` sits at the front of the lowest step, facing the pitch (its -Z); `length` along its X.
local function stand(cf, length, rows, folder)
	local sections = 5
	local gap = 3
	local each = (length - gap * (sections - 1)) / sections
	for r = 0, rows - 1 do
		local step = cf * CFrame.new(0, r * 1.6 + 0.8, r * 3 + 1.5)
		Build.part({ name = "Terrace", size = Vector3.new(length, r * 1.6 + 1.6, 3), cframe = step * CFrame.new(0, -r * 0.8, 0), color = CONCRETE, material = "Concrete", parent = folder })
		for k = 0, sections - 1 do
			local x = -length / 2 + each / 2 + k * (each + gap)
			Build.part({ name = "Seats", size = Vector3.new(each, 1.2, 1.4), cframe = step * CFrame.new(x, 1.4, 0.4), color = SEATS[(r + k) % #SEATS + 1], material = "SmoothPlastic", parent = folder })
		end
	end
	Build.part({ name = "StandBack", size = Vector3.new(length, rows * 1.6 + 8, 1), cframe = cf * CFrame.new(0, (rows * 1.6 + 8) / 2, rows * 3 + 1), color = { 120, 124, 130 }, material = "Concrete", parent = folder })
	Build.part({ name = "StandRoof", size = Vector3.new(length + 2, 0.8, rows * 3 + 4), cframe = cf * CFrame.new(0, rows * 1.6 + 8, rows * 1.5) * CFrame.Angles(math.rad(-6), 0, 0), color = { 230, 230, 234 }, material = "Metal", parent = folder })
end

local function floodlight(at, centre, folder)
	Build.post({ name = "FloodPole", color = { 150, 154, 160 }, material = "Metal", parent = folder }, CFrame.new(at), 50, 1.6)
	local head = CFrame.lookAt(at + Vector3.new(0, 52, 0), centre)
	Build.part({ name = "FloodFrame", size = Vector3.new(12, 7, 1), cframe = head * CFrame.new(0, 0, 0.6), color = { 90, 94, 100 }, material = "Metal", parent = folder })
	for x = -1, 1 do
		for y = 0, 1 do
			local lamp = Build.part({ name = "FloodLamp", size = Vector3.new(3, 2.4, 0.4), cframe = head * CFrame.new(x * 3.8, y * 3 - 1.5, 0), color = { 255, 252, 236 }, material = "Neon", parent = folder })
			if x == 0 and y == 0 then
				Kit.light(lamp, { 255, 250, 236 }, 60, 2)
			end
		end
	end
end

local function scoreboard(at, centre, folder)
	local cf = CFrame.lookAt(at, Vector3.new(centre.X, at.Y, centre.Z))
	for _, x in ipairs({ -14, 14 }) do
		Build.part({ name = "BoardLeg", size = Vector3.new(1.4, at.Y, 1.4), cframe = CFrame.new((cf * CFrame.new(x, 0, 1)).Position - Vector3.new(0, at.Y / 2, 0)), color = { 60, 62, 70 }, material = "Metal", parent = folder })
	end
	local frame = Build.part({ name = "BoardFrame", size = Vector3.new(34, 15, 1.4), cframe = cf * CFrame.new(0, 0, 0.6), color = { 245, 200, 66 }, material = "Neon", parent = folder })
	frame.CastShadow = false
	local board = Build.part({ name = "Scoreboard", size = Vector3.new(32, 13, 1), cframe = cf, color = { 18, 22, 30 }, material = "SmoothPlastic", parent = folder })
	local label = Build.text(board, Enum.NormalId.Front, "HAYSTACK STADIUM\nYour score shows here", { color = Color3.fromRGB(255, 220, 110), pixels = 20 })
	label.Name = "ScoreText"
	label.Parent.LightInfluence = 0
end

function Field.build(w, centre, folder)
	Kit.ground(centre, Enum.Material.Pavement, 340)
	local pitch = Kit.folder("Pitch", folder)
	local n = 10
	for i = 0, n - 1 do
		local z = -LONG / 2 - 6 + (LONG + 12) / n * (i + 0.5)
		Build.part({ name = "Turf", size = Vector3.new(WIDE + 12, 0.4, (LONG + 12) / n), cframe = CFrame.new(centre + Vector3.new(0, 0.2, z)), color = STRIPES[i % 2 + 1], material = "Fabric", parent = pitch })
	end
	markings(centre, pitch)
	goal(centre, -1, pitch)
	goal(centre, 1, pitch)
	local stands = Kit.folder("Stands", folder)
	stand(CFrame.lookAt(centre + Vector3.new(-62, 0, 0), centre), 150, 9, stands)
	stand(CFrame.lookAt(centre + Vector3.new(62, 0, 0), centre), 150, 9, stands)
	stand(CFrame.lookAt(centre + Vector3.new(0, 0, -96), centre), 110, 9, stands)
	-- low boards along the touchlines, with our own cheers on them
	local cheers = { "GO HAY GO!", "FIND THE NEEDLE!", "STRAW STARS", "HAY HOORAY!" }
	for _, s in ipairs({ -1, 1 }) do
		for k = 0, 3 do
			local at = centre + Vector3.new(s * 56, 1.2, -60 + k * 40)
			local board = Build.part({ name = "PitchBoard", size = Vector3.new(34, 2.4, 0.4), cframe = CFrame.lookAt(at, Vector3.new(centre.X, at.Y, at.Z)), color = SEATS[(k % 3) + 1], material = "SmoothPlastic", parent = stands })
			Build.text(board, Enum.NormalId.Front, cheers[k + 1], { color = Color3.new(1, 1, 1), pixels = 16 })
		end
	end
	for _, x in ipairs({ -84, 84 }) do
		for _, z in ipairs({ -104, 104 }) do
			floodlight(centre + Vector3.new(x, 0, z), centre, stands)
		end
	end
	scoreboard(centre + Vector3.new(0, 34, -128), centre, stands)
end

return Field

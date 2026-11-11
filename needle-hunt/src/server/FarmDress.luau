-- Hayfield Farm's finishing touches (server/MapsBig calls these; all to look at only):
--   gates    a timber frame over every gate in a maze's outside wall, with a sign plank (its
--            quarter's picture on both faces) and a
--            pennant in the quarter's colour and a warm lantern, so you know which quarter you're
--            walking into
--   balloon  a balloon on a string high over a landmark, in its quarter's colour: a bearing from
--            anywhere on the map
--   fx       dust motes drifting in the sun over the roads and yards, chaff over the corn (a few
--            invisible boxes with particle emitters, in the arena's "Fx" folder)
local MapKit = require(script.Parent.MapKit)
local WallKit = require(script.Parent.WallKit)

local FarmDress = {}
local deco = WallKit.deco
local TIMBER = { 104, 88, 70 }

-- A quarter's picture on a gate sign, in three small pieces: a corn cob, a pumpkin, an apple or
-- a windmill's sails. `face` is the sign's frame, shifted to stand just proud of one side.
local function icon(ctx, face, kind)
	local function bit(shape, size, x, y, colour, turn)
		deco(ctx, { Name = "SignIcon", Shape = shape, Size = size, CFrame = face * CFrame.new(x, y, 0) * CFrame.Angles(0, 0, math.rad(turn or 0)), Color = colour, Material = "SmoothPlastic" }, false, true)
	end
	if kind == "corn" then
		bit("Block", Vector3.new(0.6, 1.5, 0.3), 0, 0, { 250, 214, 70 }, 20)
		bit("Block", Vector3.new(0.3, 1.2, 0.2), -0.45, -0.2, { 96, 140, 60 }, 50)
		bit("Block", Vector3.new(0.3, 1.2, 0.2), 0.45, -0.2, { 96, 140, 60 }, -10)
	elseif kind == "pumpkin" then
		bit("Ball", Vector3.new(1.5, 1.2, 0.5), 0, -0.1, { 232, 128, 40 })
		bit("Block", Vector3.new(0.2, 0.5, 0.2), 0, 0.65, { 80, 110, 50 })
		bit("Block", Vector3.new(0.12, 1.1, 0.52), 0, -0.1, { 196, 100, 30 })
	elseif kind == "apple" then
		bit("Ball", Vector3.new(1.3, 1.3, 0.5), 0, -0.1, { 200, 40, 44 })
		bit("Block", Vector3.new(0.14, 0.5, 0.14), 0, 0.7, { 90, 62, 40 }, 10)
		bit("Block", Vector3.new(0.6, 0.25, 0.14), 0.35, 0.8, { 90, 150, 60 }, 20)
	else -- the mill
		bit("Block", Vector3.new(0.3, 1.9, 0.2), 0, 0, { 240, 236, 224 }, 45)
		bit("Block", Vector3.new(0.3, 1.9, 0.2), 0, 0, { 240, 236, 224 }, -45)
		bit("Block", Vector3.new(0.4, 0.4, 0.3), 0, 0, { 90, 70, 54 })
	end
end

function FarmDress.gates(ctx, maze, colour, picture)
	for _, g in ipairs(maze.gates or {}) do
		-- the gate's frame: X along the wall line, Z through the gate
		local cf = CFrame.new(MapKit.at(ctx, g.x, 0, g.z)) * CFrame.Angles(0, if g.alongX then 0 else math.rad(90), 0)
		for _, side in ipairs({ -1, 1 }) do
			deco(ctx, { Name = "GatePost", Size = Vector3.new(0.9, 12, 0.9), CFrame = cf * CFrame.new(side * 6.6, 6, 0), Color = WallKit.tone(ctx, TIMBER, 0.08), Material = "Wood" }, true)
			deco(ctx, { Name = "GateBrace", Size = Vector3.new(2.4, 0.5, 0.5), CFrame = cf * CFrame.new(side * 5.7, 10.6, 0) * CFrame.Angles(0, 0, math.rad(side * 45)), Color = TIMBER, Material = "Wood" }, false, true)
		end
		deco(ctx, { Name = "GateLintel", Size = Vector3.new(14.6, 0.9, 0.7), CFrame = cf * CFrame.new(0, 11.6, 0), Color = WallKit.tone(ctx, TIMBER, 0.08), Material = "Wood" }, true)
		deco(ctx, { Name = "GateSign", Size = Vector3.new(5, 2.2, 0.3), CFrame = cf * CFrame.new(0, 10, 0), Color = { colour[1] * 0.9, colour[2] * 0.9, colour[3] * 0.9 }, Material = "WoodPlanks" })
		for _, side in ipairs({ -1, 1 }) do -- the quarter's picture on both faces
			icon(ctx, cf * CFrame.new(0, 10, side * 0.25), picture)
		end
		deco(ctx, { Name = "PennantPole", Size = Vector3.new(0.2, 2.4, 0.2), CFrame = cf * CFrame.new(6.6, 13.2, 0), Color = TIMBER, Material = "Wood" }, false, true)
		deco(ctx, { Name = "Pennant", Size = Vector3.new(2.2, 1.2, 0.08), CFrame = cf * CFrame.new(5.4, 13.7, 0), Color = colour, Material = "Fabric" }, false, true)
		local lamp = MapKit.lamp(ctx, (cf * CFrame.new(-6.6, 9.2, 0.9)).Position, { 255, 196, 120 }, 14)
		lamp.Size, lamp.CanQuery, lamp.CanTouch, lamp.CastShadow = Vector3.new(0.7, 0.9, 0.7), false, false, false
		local light = lamp:FindFirstChildOfClass("PointLight")
		if light then
			light.Brightness, light.Shadows = 0.9, false
		end
	end
end

function FarmDress.balloon(ctx, x, z, colour, height)
	height = height or 70
	deco(ctx, { Name = "BalloonString", Size = Vector3.new(0.12, height - 28, 0.12), CFrame = CFrame.new(MapKit.at(ctx, x, 28 + (height - 28) / 2, z)), Color = { 230, 226, 214 }, Material = "Fabric" }, false, true)
	deco(ctx, { Name = "Balloon", Shape = "Ball", Size = Vector3.new(7, 8, 7), CFrame = CFrame.new(MapKit.at(ctx, x, height + 3.5, z)), Color = colour, Material = "SmoothPlastic" })
	deco(ctx, { Name = "BalloonKnot", Size = Vector3.new(0.8, 0.8, 0.8), CFrame = CFrame.new(MapKit.at(ctx, x, height - 0.3, z)) * CFrame.Angles(0, 0, math.rad(45)), Color = colour, Material = "SmoothPlastic" }, false, true)
end

-- An invisible box that sheds slow particles through its volume.
local function drift(ctx, folder, x, y, z, size, set)
	local host = deco(ctx, { Name = "Drift", Size = size, CFrame = CFrame.new(MapKit.at(ctx, x, y, z)), Transparency = 1, Parent = folder })
	host.Parent = folder
	local e = Instance.new("ParticleEmitter")
	e.Rate, e.Lifetime, e.Speed, e.SpreadAngle = set.rate, NumberRange.new(set.life[1], set.life[2]), NumberRange.new(0.2, 0.6), Vector2.new(180, 180)
	e.Size = NumberSequence.new(set.size)
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, set.clear), NumberSequenceKeypoint.new(1, 1) })
	e.Color = ColorSequence.new(Color3.fromRGB(set.colour[1], set.colour[2], set.colour[3]))
	e.LightEmission, e.Drag, e.RotSpeed = set.glow, 1.5, NumberRange.new(-60, 60)
	e.Parent = host
end

function FarmDress.fx(ctx)
	local folder = Instance.new("Folder")
	folder.Name = "Fx"
	folder.Parent = ctx.model
	local motes = { rate = 15, life = { 6, 10 }, size = 0.12, clear = 0.6, colour = { 255, 236, 190 }, glow = 0.6 }
	for _, p in ipairs({ { 0, 0 }, { -82, -82 }, { 82, 82 }, { 0, 168 }, { 168, 0 } }) do -- the crossroads, two yards, two roads
		drift(ctx, folder, p[1], 10, p[2], Vector3.new(80, 16, 80), motes)
	end
	local chaff = { rate = 6, life = { 5, 8 }, size = 0.25, clear = 0.3, colour = { 240, 220, 160 }, glow = 0.1 }
	for _, p in ipairs({ { -110, -60 }, { -55, -110 } }) do -- over the corn
		drift(ctx, folder, p[1], 12, p[2], Vector3.new(60, 6, 60), chaff)
	end
end

return FarmDress

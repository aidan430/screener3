-- What each buildable item looks like, built from parts around `cf`: the base centre on the
-- ground, facing -Z (stairs and escalators climb towards -Z). Returns the Model.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))(Config)

local Build = require(script.Parent.Build)
local Assets = require(script.Parent.Assets)

local Pieces = {}
local WOOD, DARK, METAL = { 168, 122, 74 }, { 110, 76, 46 }, { 140, 144, 150 }
local builders = {}

local function p(model, cf, size, color, material, shape)
	return Build.part({ size = size, cframe = cf, color = color, material = material or "WoodPlanks", shape = shape, parent = model })
end

function builders.stairs(model, cf)
	for i = 0, 9 do
		p(model, cf * CFrame.new(0, i + 0.5, 4.5 - i), Vector3.new(8, 1, 1), WOOD)
	end
	for _, x in ipairs({ -4.2, 4.2 }) do
		p(model, cf * CFrame.new(x, 5.5, 0) * CFrame.Angles(math.rad(45), 0, 0), Vector3.new(0.4, 1.2, 14.4), DARK, "Wood")
	end
end

function builders.landing(model, cf)
	p(model, cf * CFrame.new(0, 0.5, 0), Vector3.new(10, 1, 10), WOOD)
end

-- A ladder: the owner's imported ladder model (or wooden rails and rungs if it won't load),
-- with an invisible truss inside, which is what Roblox characters climb.
function builders.ladder(model, cf)
	local def = Economy.item("ladder").def
	local height = def.size[2]
	local template = def.model and Assets.template(def.model)
	if template then
		local look = template:Clone()
		local size = look.Size
		local turn = CFrame.new() -- stand its longest side up
		if size.X >= size.Y and size.X >= size.Z then
			turn = CFrame.Angles(0, 0, math.rad(90))
		elseif size.Z >= size.Y and size.Z >= size.X then
			turn = CFrame.Angles(math.rad(90), 0, 0)
		end
		look.Size = size * (height / math.max(size.X, size.Y, size.Z))
		look.CFrame = cf * CFrame.new(0, height / 2, 0) * turn
		look.Anchored, look.CanCollide, look.CanQuery = true, false, true
		look.Parent = model
	else
		for _, x in ipairs({ -1.5, 1.5 }) do
			p(model, cf * CFrame.new(x, height / 2, 0), Vector3.new(0.4, height, 0.4), DARK, "Wood")
		end
		for y = 1, height - 1, 1.5 do
			p(model, cf * CFrame.new(0, y, 0), Vector3.new(3, 0.25, 0.3), WOOD, "Wood")
		end
	end
	local truss = Instance.new("TrussPart")
	truss.Name = "Climb"
	truss.Anchored = true
	truss.Size = Vector3.new(2, height, 2)
	truss.CFrame = cf * CFrame.new(0, height / 2, 0)
	truss.Transparency = 1
	truss.Style = Enum.Style.NoSupports
	truss.Parent = model
end

function builders.pillar(model, cf)
	p(model, cf * CFrame.new(0, 5, 0), Vector3.new(2, 10, 2), DARK, "Wood")
end

function builders.escalator(model, cf)
	-- a moving ramp: the parts' velocity carries anyone standing on them up the slope
	local slope = cf * CFrame.new(0, 5, 0) * CFrame.Angles(math.rad(45), 0, 0)
	local belt = p(model, slope, Vector3.new(6, 0.6, 14.4), { 70, 72, 80 }, "DiamondPlate")
	belt.AssemblyLinearVelocity = (cf.LookVector + cf.UpVector).Unit * 10 -- up the slope, towards -Z
	belt:SetAttribute("Conveyor", true)
	for _, x in ipairs({ -3.4, 3.4 }) do
		p(model, slope * CFrame.new(x, 1, 0), Vector3.new(0.6, 2, 14.4), METAL, "Metal")
	end
	p(model, cf * CFrame.new(0, 10.25, -6), Vector3.new(6, 0.5, 3), METAL, "DiamondPlate")
	p(model, cf * CFrame.new(0, 0.25, 6), Vector3.new(6, 0.5, 3), METAL, "DiamondPlate")
end

function builders.elevator(model, cf)
	for _, c in ipairs({ { -4.5, -4.5 }, { 4.5, -4.5 }, { -4.5, 4.5 }, { 4.5, 4.5 } }) do
		p(model, cf * CFrame.new(c[1], 25.5, c[2]), Vector3.new(1, 51, 1), METAL, "Metal")
	end
	p(model, cf * CFrame.new(0, 0.25, 0), Vector3.new(10, 0.5, 10), METAL, "DiamondPlate")
	local top = p(model, cf * CFrame.new(0, 50.5, 0), Vector3.new(10, 1, 10), WOOD)
	local bottom = p(model, cf * CFrame.new(0, 3, -4.6), Vector3.new(2, 2, 0.4), { 245, 200, 66 }, "Neon")
	local upper = p(model, cf * CFrame.new(0, 53, 4.6), Vector3.new(2, 2, 0.4), { 245, 200, 66 }, "Neon")
	top.Name = "Top"
	for _, pair in ipairs({ { bottom, "Ride up", "up" }, { upper, "Ride down", "down" } }) do
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = pair[2]
		prompt.ObjectText = "Elevator"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 6
		prompt.RequiresLineOfSight = false
		prompt:SetAttribute("Direction", pair[3])
		prompt.Parent = pair[1]
	end
end

local function prompt(parent, action, text, object)
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText = text
	pr.ObjectText = object
	pr.HoldDuration = 0
	pr.MaxActivationDistance = 10
	pr.RequiresLineOfSight = false
	pr:SetAttribute("Action", action)
	pr.Parent = parent
	return pr
end

local function standing(model, cf, height, diameter, color, material, name)
	local c = p(model, cf * CFrame.new(0, height / 2, 0) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(height, diameter, diameter), color, material, "Cylinder")
	c.Name = name or c.Name
	return c
end

local belts = require(script.Parent.PiecesBelts)(builders, p)
local sensor = belts.sensor
require(script.Parent.PiecesFactory)(builders, p, belts)

-- Your trader: a market stall with a striped awning, the trader behind the counter, and a
-- big woven basket in front where you dump your hay (the basket's prompt sells it).
local function stall(model, cf)
	-- the owner's stall model (Config.TraderModel) when it loads, else a built market stall
	local def = Config.TraderModel
	local custom = def and def.id ~= 0 and Assets.place(def.id, cf * CFrame.new(0, 0, 1) * CFrame.Angles(0, math.rad(def.turn or 0), 0), def.width, model, true)
	if custom then
		return
	end
	p(model, cf * CFrame.new(0, 1.5, 1), Vector3.new(10, 3, 3), WOOD)
	p(model, cf * CFrame.new(0, 3.1, 1), Vector3.new(10.4, 0.3, 3.4), DARK, "Wood")
	for _, c in ipairs({ { -4.8, -0.2 }, { 4.8, -0.2 }, { -4.8, 3.6 }, { 4.8, 3.6 } }) do
		p(model, cf * CFrame.new(c[1], 4.5, c[2]), Vector3.new(0.5, 9, 0.5), DARK, "Wood")
	end
	for i = 0, 5 do -- the striped awning, tipped towards the front
		local colour = if i % 2 == 0 then { 196, 72, 56 } else { 246, 232, 200 }
		p(model, cf * CFrame.new(-4.2 + i * 1.68, 9.3, 1.4) * CFrame.Angles(math.rad(-12), 0, 0), Vector3.new(1.68, 0.3, 5.6), colour, "Fabric")
	end
	local sign = p(model, cf * CFrame.new(0, 10.8, -0.6), Vector3.new(6, 1.6, 0.3), WOOD)
	Build.text(sign, Enum.NormalId.Front, "TRADER")
end

function builders.trader(model, cf)
	stall(model, cf)
	-- the trader: boots, overalls, a checked shirt, a friendly face and a wide straw hat
	local body = cf * CFrame.new(0, 0, 3.2) -- facing the front, where customers come
	for _, x in ipairs({ -0.5, 0.5 }) do
		p(model, body * CFrame.new(x, 1, 0), Vector3.new(0.9, 2, 0.9), { 64, 82, 130 }, "Fabric")
	end
	p(model, body * CFrame.new(0, 3.1, 0), Vector3.new(2.2, 2.2, 1.1), { 196, 72, 56 }, "Fabric")
	p(model, body * CFrame.new(0, 2.6, -0.05), Vector3.new(1.6, 1.4, 1.15), { 64, 82, 130 }, "Fabric")
	p(model, body * CFrame.new(0, 4.8, 0), Vector3.new(1.3, 1.3, 1.3), { 232, 188, 150 }, "SmoothPlastic")
	for _, x in ipairs({ -0.3, 0.3 }) do
		p(model, body * CFrame.new(x, 4.95, -0.66), Vector3.new(0.18, 0.18, 0.05), { 40, 30, 24 }, "SmoothPlastic")
	end
	standing(model, body * CFrame.new(0, 5.45, 0), 0.15, 3.2, { 226, 196, 110 }, "Fabric")
	standing(model, body * CFrame.new(0, 5.5, 0), 0.8, 1.5, { 226, 196, 110 }, "Fabric")
	-- the basket: woven sides, a band, and the hay inside (shown on each player's screen)
	local basket = standing(model, cf * CFrame.new(0, 0, -3.6), 2.6, 4.4, { 150, 104, 58 }, "Fabric", "Basket")
	standing(model, cf * CFrame.new(0, 2.3, -3.6), 0.35, 4.6, DARK, "Wood")
	local fill = standing(model, cf * CFrame.new(0, 2.5, -3.6), 0.3, 4, { 222, 186, 92 }, "Grass", "BasketFill")
	fill.Transparency = 1
	fill.CanCollide = false
	prompt(basket, "sell", "Dump hay", "Your trader")
	sensor(model, cf * CFrame.new(0, 1.9, -3.6), Vector3.new(6, 3.8, 6), "BasketSensor") -- hay off a belt or a carried bale
end

-- A teleporter pad: step on, press E and pick another of your pads.
function builders.teleporter(model, cf)
	standing(model, cf, 0.6, 8, { 70, 72, 84 }, "DiamondPlate", "Pad")
	local ring = standing(model, cf * CFrame.new(0, 0.6, 0), 0.15, 6.4, { 120, 200, 255 }, "Neon", "Ring")
	ring.CanCollide = false
	prompt(ring, "teleport", "Teleport", "Teleporter Pad")
end

-- Machines and generators: a body, a roof light that glows when running, a name plate.
local function engine(model, cf, def, kind)
	local size = Vector3.new(def.size[1], def.size[2], def.size[3])
	local body = p(model, cf * CFrame.new(0, size.Y / 2, 0), size, def.color, if kind == "generator" then "Metal" else "DiamondPlate")
	body.Name = "Body"
	local lamp = p(model, cf * CFrame.new(0, size.Y + 0.4, 0), Vector3.new(1, 0.8, 1), { 90, 90, 90 }, "Neon")
	lamp.Name = "Lamp"
	if kind == "machine" then
		local fan = p(model, cf * CFrame.new(0, size.Y * 0.6, -size.Z / 2 - 0.2), Vector3.new(0.4, size.Y * 0.6, size.Y * 0.6), METAL, "Metal", "Cylinder")
		fan.CFrame = fan.CFrame * CFrame.Angles(0, math.rad(90), 0)
		fan.Name = "Fan"
	end
	local plate = Instance.new("BillboardGui")
	plate.Size = UDim2.fromScale(8, 1.6)
	plate.StudsOffset = Vector3.new(0, size.Y / 2 + 2, 0)
	plate.MaxDistance = 60
	plate.Parent = body
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.4
	label.Text = def.name .. (if kind == "generator" then "  +" .. def.power .. " power" else "  " .. def.rate .. "/s, uses " .. def.draw)
	label.Parent = plate
end

function Pieces.make(id, cf)
	local item = Economy.item(id)
	if not item then
		return nil
	end
	local model = Instance.new("Model")
	model.Name = id
	model:SetAttribute("Item", id)
	if builders[id] then
		builders[id](model, cf)
	else
		engine(model, cf, item.def, item.kind)
	end
	model.WorldPivot = cf
	return model
end

-- Lights a machine or generator's lamp: green when running, red when short of power.
function Pieces.light(model, running)
	local lamp = model:FindFirstChild("Lamp")
	if lamp then
		lamp.Color = if running then Color3.fromRGB(90, 255, 120) else Color3.fromRGB(255, 70, 60)
	end
end

return Pieces

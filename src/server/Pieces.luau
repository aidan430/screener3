-- What each buildable item looks like, built from parts around `cf`: the base centre on the
-- ground, facing -Z (stairs and escalators climb towards -Z). Returns the Model.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))(Config)

local Build = require(script.Parent.Build)

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

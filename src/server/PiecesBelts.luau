-- Conveyor belts, the conveyor down off a platform, and the bale maker. Belts move anything
-- on them (dropped hay, bales, players) towards their arrows (-Z), Config.ConveyorSpeed.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local BELT, RAIL, ARROW = { 64, 66, 72 }, { 150, 154, 160 }, { 245, 200, 66 }

return function(builders, p)
	local function sensor(model, cf, size, name)
		local part = p(model, cf, size, { 255, 255, 255 }, "SmoothPlastic")
		part.Name = name
		part.Transparency = 1
		part.CanCollide, part.CanQuery, part.CanTouch = false, false, true
		return part
	end

	local function belt(model, slope, length)
		local part = p(model, slope, Vector3.new(5.6, 0.6, length), BELT, "Fabric")
		part.Name = "Belt"
		part.AssemblyLinearVelocity = slope.LookVector * Config.ConveyorSpeed
		part:SetAttribute("Conveyor", true)
		for _, x in ipairs({ -3, 3 }) do
			p(model, slope * CFrame.new(x, 0.6, 0), Vector3.new(0.4, 1.8, length), RAIL, "Metal")
		end
		for z = -length / 2 + 2, length / 2 - 2, 4 do -- arrows pointing the way it runs
			local a = p(model, slope * CFrame.new(0, 0.31, z), Vector3.new(1.6, 0.05, 0.5), ARROW, "Neon")
			a.CanCollide = false
		end
		return part
	end

	function builders.conveyor(model, cf)
		belt(model, cf * CFrame.new(0, 0.5, 0), 12)
	end

	function builders.chute(model, cf)
		local angle = math.atan2(10, 12)
		local length = math.sqrt(10 ^ 2 + 12 ^ 2)
		belt(model, cf * CFrame.new(0, 5.3, 0) * CFrame.Angles(-angle, 0, 0), length)
		for _, x in ipairs({ -2.6, 2.6 }) do -- legs under the high end
			p(model, cf * CFrame.new(x, 5, 5.4), Vector3.new(0.6, 10, 0.6), RAIL, "Metal")
			p(model, cf * CFrame.new(x, 2.5, 0), Vector3.new(0.6, 5, 0.6), RAIL, "Metal")
		end
	end

	-- Hay goes in the hopper at the back (+Z); bales come out of the front (-Z).
	function builders.baler(model, cf)
		local body = p(model, cf * CFrame.new(0, 3, 0), Vector3.new(8, 6, 7), { 200, 70, 50 }, "Metal")
		body.Name = "Body"
		p(model, cf * CFrame.new(0, 6.3, 0), Vector3.new(8.4, 0.6, 7.4), { 60, 62, 70 }, "Metal")
		p(model, cf * CFrame.new(0, 2.4, 4.4), Vector3.new(6, 0.4, 2), { 60, 62, 70 }, "Metal") -- the hopper lip
		p(model, cf * CFrame.new(0, 1.2, -4.3), Vector3.new(6.4, 0.4, 2.6), { 60, 62, 70 }, "DiamondPlate") -- the chute out
		sensor(model, cf * CFrame.new(0, 2.2, 4.6), Vector3.new(6.4, 4.4, 2.6), "BalerIntake")
		local out = sensor(model, cf * CFrame.new(0, 2.2, -7.5) * CFrame.Angles(0, 0, 0), Vector3.new(1, 1, 1), "BaleOut")
		out.CanTouch = false
		for _, x in ipairs({ -2.5, 2.5 }) do
			local wheel = p(model, cf * CFrame.new(x * 1.7, 1.2, 2), Vector3.new(0.8, 2.4, 2.4), { 30, 30, 32 }, "SmoothPlastic", "Cylinder")
			wheel.CanCollide = false
		end
		local lamp = p(model, cf * CFrame.new(2.8, 7, -2.6), Vector3.new(0.8, 0.8, 0.8), { 90, 255, 120 }, "Neon")
		lamp.Name = "Light"
	end

	return sensor
end

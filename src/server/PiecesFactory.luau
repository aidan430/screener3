-- The factory line's pieces: belt corners and splitters, Hay Arms and Hay Throwers that feed
-- the belts from your heap, the Hay Burner that makes power from hay, and the Bale Wrapper and
-- Pellet Press. Fronts face -Z like every piece; intakes are at the back (+Z), outputs at the
-- front. Points named "Out" / "BaleOut" are where products leave; "Lamp" glows when powered.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local METAL, DARK, ARROW = { 140, 144, 150 }, { 60, 62, 70 }, { 245, 200, 66 }

return function(builders, p, belts)
	local sensor = belts.sensor

	local function lamp(model, cf)
		local l = p(model, cf, Vector3.new(0.8, 0.8, 0.8), { 90, 90, 90 }, "Neon")
		l.Name = "Lamp"
		l.CanCollide = false
	end

	local function point(model, cf, name)
		local o = sensor(model, cf, Vector3.new(1, 1, 1), name)
		o.CanTouch = false
		return o
	end

	-- a square belt that pushes hay sideways (towards -X): rotate it to turn left or right
	function builders.corner(model, cf)
		local pad = p(model, cf * CFrame.new(0, 0.5, 0), Vector3.new(6, 0.6, 6), { 64, 66, 72 }, "Fabric")
		pad.Name = "Belt"
		pad.AssemblyLinearVelocity = -cf.RightVector * Config.ConveyorSpeed
		pad:SetAttribute("Conveyor", true)
		pad:SetAttribute("Dir", -cf.RightVector)
		p(model, cf * CFrame.new(3, 1.1, 0), Vector3.new(0.4, 1.8, 6), METAL, "Metal") -- the outside wall
		p(model, cf * CFrame.new(0, 1.1, -3), Vector3.new(6, 1.8, 0.4), METAL, "Metal")
		for _, x in ipairs({ 1.5, -1.5 }) do
			local a = p(model, cf * CFrame.new(x, 0.81, 0) * CFrame.Angles(0, math.rad(90), 0), Vector3.new(1.6, 0.05, 0.5), ARROW, "Neon")
			a.CanCollide = false
		end
	end

	-- straight on, but each new item is pushed left, then right, then left
	function builders.splitter(model, cf)
		local pad = p(model, cf * CFrame.new(0, 0.5, 0), Vector3.new(6, 0.6, 6), { 64, 66, 72 }, "Fabric")
		pad.Name = "SplitterBelt"
		pad.AssemblyLinearVelocity = cf.LookVector * Config.ConveyorSpeed
		pad:SetAttribute("Conveyor", true)
		pad:SetAttribute("Dir", cf.LookVector)
		pad.CanTouch = true
		p(model, cf * CFrame.new(0, 1.1, 2.8), Vector3.new(1, 1.8, 0.4), { 245, 200, 66 }, "Metal") -- the divider post
		p(model, cf * CFrame.new(0, 1.6, 0), Vector3.new(0.3, 0.3, 5.4), DARK, "Metal")
	end

	-- a jointed arm on a turntable that scoops hay from your heap behind it onto a belt in front
	function builders.arm(model, cf)
		p(model, cf * CFrame.new(0, 0.5, 0), Vector3.new(4, 1, 4), DARK, "DiamondPlate")
		p(model, cf * CFrame.new(0, 1.5, 0), Vector3.new(2.4, 1, 2.4), { 245, 160, 40 }, "Metal", "Cylinder").CFrame = cf * CFrame.new(0, 1.5, 0) * CFrame.Angles(0, 0, math.rad(90))
		p(model, cf * CFrame.new(0, 3.8, 0.6) * CFrame.Angles(math.rad(-20), 0, 0), Vector3.new(0.8, 4, 0.8), { 245, 160, 40 }, "Metal")
		p(model, cf * CFrame.new(0, 6, -1.4) * CFrame.Angles(math.rad(60), 0, 0), Vector3.new(0.7, 4, 0.7), { 245, 160, 40 }, "Metal")
		p(model, cf * CFrame.new(0, 5.2, -3.4), Vector3.new(2, 0.4, 1.6), METAL, "Metal") -- the scoop
		lamp(model, cf * CFrame.new(1.4, 1.2, 1.4))
		point(model, cf * CFrame.new(0, 3, -5.5), "Out")
	end

	-- a sprung paddle that flings a bundle a long way forward onto a belt
	function builders.thrower(model, cf)
		p(model, cf * CFrame.new(0, 1, 0), Vector3.new(5, 2, 6), { 110, 76, 46 }, "WoodPlanks")
		p(model, cf * CFrame.new(0, 2.5, 1) * CFrame.Angles(math.rad(35), 0, 0), Vector3.new(3.6, 0.4, 3.6), METAL, "Metal") -- the paddle
		p(model, cf * CFrame.new(0, 3.2, 2.6), Vector3.new(4.6, 0.6, 0.6), DARK, "Metal")
		lamp(model, cf * CFrame.new(2, 2.4, -2.4))
		local o = point(model, cf * CFrame.new(0, 4.5, -3.5), "Out")
		o:SetAttribute("Throw", true)
	end

	-- a stove with a hopper at the back: feed it hay and it makes power while it burns
	function builders.burner(model, cf)
		local body = p(model, cf * CFrame.new(0, 2.5, 0), Vector3.new(5, 5, 5), { 150, 80, 50 }, "Brick")
		body.Name = "Body"
		p(model, cf * CFrame.new(0, 5.5, -1.2), Vector3.new(1.2, 3, 1.2), DARK, "Metal") -- the chimney
		p(model, cf * CFrame.new(0, 2, -2.6), Vector3.new(2.4, 1.6, 0.3), { 255, 140, 60 }, "Neon").Name = "Glow"
		p(model, cf * CFrame.new(0, 1.2, 3.3), Vector3.new(4.4, 0.4, 1.6), DARK, "Metal") -- the hopper lip
		sensor(model, cf * CFrame.new(0, 1.9, 3.4), Vector3.new(5, 3.8, 2.4), "BurnerIntake")
		lamp(model, cf * CFrame.new(1.8, 5.3, 1.8))
	end

	local function processor(model, cf, colour, intake)
		local body = p(model, cf * CFrame.new(0, 3, 0), Vector3.new(8, 6, 7), colour, "Metal")
		body.Name = "Body"
		p(model, cf * CFrame.new(0, 6.3, 0), Vector3.new(8.4, 0.6, 7.4), DARK, "Metal")
		p(model, cf * CFrame.new(0, 2.4, 4.4), Vector3.new(6, 0.4, 2), DARK, "Metal")
		p(model, cf * CFrame.new(0, 1.2, -4.3), Vector3.new(6.4, 0.4, 2.6), DARK, "DiamondPlate")
		sensor(model, cf * CFrame.new(0, 2.2, 4.6), Vector3.new(6.4, 4.4, 2.6), intake)
		point(model, cf * CFrame.new(0, 2.2, -7.5), "BaleOut")
	end

	function builders.wrapper(model, cf)
		processor(model, cf, { 70, 130, 90 }, "WrapperIntake")
		local ring = p(model, cf * CFrame.new(0, 7, 0), Vector3.new(0.4, 5, 5), { 236, 240, 232 }, "SmoothPlastic", "Cylinder")
		ring.Name = "Fan" -- spins on screens like the machines' fans
	end

	function builders.press(model, cf)
		processor(model, cf, { 90, 110, 170 }, "PressIntake")
		p(model, cf * CFrame.new(0, 8.5, 0), Vector3.new(2, 4, 2), METAL, "Metal") -- the ram
	end
end

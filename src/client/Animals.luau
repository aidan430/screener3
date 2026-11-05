-- Brings the farm's animals to life on this screen only: each one ambles to a new spot in its
-- pen every few seconds with slow eased tweens, chickens and ducks peck, cows and sheep graze,
-- tails swish, and the windmill's sails turn. The server's copies never move. Gentle and calm.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Animals = {}
local rng = Random.new()

-- speed (studs/s), pause between walks, how far one walk goes, the head motion and its angle
local KINDS = {
	Cow = { speed = 2.2, pause = { 5, 12 }, walk = { 5, 14 }, nod = 0.5 },
	Sheep = { speed = 2, pause = { 4, 10 }, walk = { 4, 10 }, nod = 0.45 },
	Pig = { speed = 2.4, pause = { 4, 9 }, walk = { 4, 10 }, nod = 0.3 },
	Chicken = { speed = 3, pause = { 2, 6 }, walk = { 2, 7 }, nod = 0.8, pecks = 3 },
	Duck = { speed = 1.5, pause = { 3, 8 }, walk = { 3, 9 }, nod = 0.7, pecks = 1 },
}
local SAIL_SPEED = 0.45 -- radians per second

local function bits(model, name)
	local found = {}
	for _, child in ipairs(model:GetChildren()) do
		if child:IsA("BasePart") and child.Name == name then
			table.insert(found, child)
		end
	end
	return found
end

-- Eases the whole model to `goal` (its pivot) over `time` seconds, then returns.
local function glide(model, goal, time)
	local value = Instance.new("CFrameValue")
	value.Value = model:GetPivot()
	local changed = value.Changed:Connect(function(cf)
		if model.Parent then
			model:PivotTo(cf)
		end
	end)
	local tween = TweenService:Create(value, TweenInfo.new(time, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Value = goal })
	tween:Play()
	tween.Completed:Wait()
	changed:Disconnect()
	value:Destroy()
end

-- Turns the parts called `name` about the model's hinge point `hingeAttr`: `turn(a)` gives the
-- rotation for a going 0..1, and it runs `times` times, back to exactly where it started.
local function swing(model, name, hingeAttr, turn, time, times)
	local hingeAt = model:GetAttribute(hingeAttr)
	local parts = bits(model, name)
	if typeof(hingeAt) ~= "Vector3" or #parts == 0 then
		return
	end
	local hinge = model:GetPivot() * CFrame.new(hingeAt)
	local rest = {}
	for i, p in ipairs(parts) do
		rest[i] = hinge:ToObjectSpace(p.CFrame)
	end
	local alpha = Instance.new("NumberValue")
	local changed = alpha.Changed:Connect(function(a)
		local moved = hinge * turn(a)
		for i, p in ipairs(parts) do
			p.CFrame = moved * rest[i]
		end
	end)
	local tween = TweenService:Create(alpha, TweenInfo.new(time, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, times - 1), { Value = 1 })
	tween:Play()
	tween.Completed:Wait()
	changed:Disconnect()
	alpha:Destroy()
	for i, p in ipairs(parts) do
		p.CFrame = hinge * rest[i]
	end
end

local function nod(model, kind)
	local angle = kind.nod
	local pecks = kind.pecks or 1
	local time = if pecks > 1 then 0.45 else rng:NextNumber(2.5, 4)
	swing(model, "Head", "HeadHinge", function(a)
		return CFrame.Angles(-math.sin(a * math.pi) * angle, 0, 0)
	end, time, pecks)
end

local function swish(model)
	swing(model, "Tail", "TailHinge", function(a)
		return CFrame.Angles(0, 0, math.sin(a * math.pi * 2) * 0.35)
	end, 1.4, rng:NextInteger(1, 3))
end

-- One animal's quiet life: rest (graze, peck or swish), then amble somewhere in its pen.
local function live(model)
	local kind = KINDS[model:GetAttribute("Kind")]
	local min, max = model:GetAttribute("PenMin"), model:GetAttribute("PenMax")
	if not kind or typeof(min) ~= "Vector3" or typeof(max) ~= "Vector3" then
		return
	end
	task.wait(rng:NextNumber(0, 6))
	while model.Parent do
		local roll = rng:NextNumber()
		if roll < 0.55 then
			nod(model, kind)
		elseif roll < 0.85 then
			swish(model)
		end
		task.wait(rng:NextNumber(kind.pause[1], kind.pause[2]))
		local here = model:GetPivot().Position
		local a = rng:NextNumber(0, math.pi * 2)
		local d = rng:NextNumber(kind.walk[1], kind.walk[2])
		local target = Vector3.new(math.clamp(here.X + math.cos(a) * d, min.X, max.X), here.Y, math.clamp(here.Z + math.sin(a) * d, min.Z, max.Z))
		local step = target - here
		if step.Magnitude > 1 then
			local face = CFrame.lookAt(here, target)
			glide(model, face, 1.2)
			glide(model, face + step, step.Magnitude / kind.speed)
		end
	end
end

-- The windmill's sails turn slowly about their hub's own Z axis.
local function turnSails(scenery)
	local mill = scenery:WaitForChild("Windmill", 30)
	local sails = mill and mill:WaitForChild("Sails", 30)
	if sails then
		sails:WaitForChild("Hub", 10)
	end
	if not sails or not sails.PrimaryPart then
		return
	end
	local start = sails:GetPivot()
	local angle, since = 0, 0
	RunService.RenderStepped:Connect(function(dt)
		since += dt
		if since < 1 / 30 then
			return
		end
		angle = (angle + since * SAIL_SPEED) % (math.pi * 2)
		since = 0
		if sails.Parent then
			sails:PivotTo(start * CFrame.Angles(0, 0, angle))
		end
	end)
end

function Animals.start()
	task.spawn(function()
		local scenery = workspace:WaitForChild("Scenery", 60)
		if not scenery then
			return
		end
		task.spawn(turnSails, scenery)
		local herd = scenery:WaitForChild("Animals", 30)
		if not herd then
			return
		end
		local started = {}
		local function begin(model)
			if model:IsA("Model") and not started[model] then
				started[model] = true
				task.spawn(live, model)
			end
		end
		task.wait(1) -- let the animals finish arriving
		for _, model in ipairs(herd:GetChildren()) do
			begin(model)
		end
		herd.ChildAdded:Connect(function(model)
			task.wait(0.5)
			begin(model)
		end)
	end)
end

return Animals

-- The hay you can see moving: every harvest lifts a lump off the heap onto your tool, and
-- dumping sends your load flying into your trader's basket, which fills and is carted away.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Ui = require(script.Parent.Ui)
local Juice = require(script.Parent.Juice)

local HayFx = {}
local HAY = Color3.fromRGB(Config.HeapColour[1], Config.HeapColour[2], Config.HeapColour[3])
local GOLD = Color3.fromRGB(255, 214, 90)

local function lump(position, size, golden)
	local folder = workspace:FindFirstChild("MyEffects") or workspace
	return Ui.make("Part", {
		Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false,
		Shape = Enum.PartType.Ball, Material = Enum.Material.Grass, Color = if golden then GOLD else HAY,
		Size = Vector3.new(size, size * 0.75, size), CFrame = CFrame.new(position), Parent = folder,
	})
end

-- Where your tool's hay sits on screen: low and to the right, in front of you.
local function toolPoint()
	local camera = workspace.CurrentCamera
	return camera and (camera.CFrame * CFrame.new(1.3, -1.3, -2.6)).Position
end

-- A lump of hay pulled off the heap at `from`, flying onto your tool.
function HayFx.lift(from, golden)
	local to = toolPoint()
	if not to then
		return
	end
	local ball = lump(from, 1.6, golden)
	local mid = (from + to) / 2 + Vector3.new(0, 1.5, 0)
	Juice.ease(ball, 0.14, { CFrame = CFrame.new(mid), Size = Vector3.new(1.2, 0.9, 1.2) }, Enum.EasingStyle.Sine)
	task.delay(0.14, function()
		local target = toolPoint() or to
		Juice.ease(ball, 0.14, { CFrame = CFrame.new(target), Size = Vector3.new(0.5, 0.4, 0.5) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end)
	Debris:AddItem(ball, 0.3)
end

-- Dumping: lumps fly from you into the basket, the hay in it rises, then the trader carts it off.
function HayFx.dump(basket, straws)
	if typeof(basket) ~= "Instance" or not basket:IsA("BasePart") then
		return
	end
	local from = toolPoint()
	local top = basket.Position + Vector3.new(0, basket.Size.X / 2, 0)
	local count = math.clamp(math.floor(math.log10(math.max(straws, 1)) * 2), 3, 10)
	for i = 1, count do
		task.delay((i - 1) * 0.06, function()
			if not from then
				return
			end
			local ball = lump(from, 1.1, false)
			local arc = (from + top) / 2 + Vector3.new(math.random(-10, 10) / 10, 3, math.random(-10, 10) / 10)
			Juice.ease(ball, 0.2, { CFrame = CFrame.new(arc) }, Enum.EasingStyle.Sine)
			task.delay(0.2, function()
				Juice.ease(ball, 0.2, { CFrame = CFrame.new(top), Size = Vector3.new(0.6, 0.45, 0.6) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			end)
			Debris:AddItem(ball, 0.42)
		end)
	end
	local fill = basket.Parent and basket.Parent:FindFirstChild("BasketFill")
	if not fill then
		return
	end
	local bottom = basket.CFrame * CFrame.new(-basket.Size.X / 2 + 0.3, 0, 0) -- the cylinder's axis is X
	local rim = basket.CFrame * CFrame.new(basket.Size.X / 2 - 0.1, 0, 0)
	fill.CFrame = bottom
	fill.Transparency = 0
	task.delay(count * 0.06 + 0.3, function()
		Juice.ease(fill, 0.5, { CFrame = rim }, Enum.EasingStyle.Back)
		Juice.burst(top, 18, false)
		task.delay(0.6 + Config.BasketDrainSeconds * 0.25, function()
			Juice.ease(fill, Config.BasketDrainSeconds, { CFrame = bottom }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			task.delay(Config.BasketDrainSeconds, function()
				fill.Transparency = 1
			end)
		end)
	end)
end

return HayFx

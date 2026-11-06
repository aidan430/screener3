-- The hay you can see moving: every harvest lifts a lump off the heap onto your tool, and
-- dumping sends your load flying into your trader's basket, which fills and is carted away.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local HayLook = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("HayLook"))(Config)
local Juice = require(script.Parent.Juice)

local HayFx = {}

local function lump(position, size, golden)
	local part = HayLook.lump(size, golden)
	if game:GetService("Players").LocalPlayer:GetAttribute("PassRainbowHay") then
		part.Color = Color3.fromHSV(math.random(), 0.45, 1) -- the Rainbow Hay pass
	end
	part.Anchored = true
	part.CFrame = CFrame.new(position) * CFrame.Angles(0, math.random() * 6.28, 0)
	part.Parent = workspace:FindFirstChild("MyEffects") or workspace
	return part
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
	Juice.ease(ball, 0.14, { CFrame = CFrame.new(mid) }, Enum.EasingStyle.Sine)
	task.delay(0.14, function()
		local target = toolPoint() or to
		Juice.ease(ball, 0.14, { CFrame = CFrame.new(target) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end)
	Debris:AddItem(ball, 0.3)
end

-- Dumping: lumps fly from you into the basket, the hay in it rises, then the trader carts it off.
function HayFx.dump(basket, straws, fromYou)
	if typeof(basket) ~= "Instance" or not basket:IsA("BasePart") then
		return
	end
	local from = if fromYou == false then nil else toolPoint() -- belts and bales just fill the basket
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
				Juice.ease(ball, 0.2, { CFrame = CFrame.new(top) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
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
	local token = (fill:GetAttribute("FxToken") or 0) + 1
	fill:SetAttribute("FxToken", token) -- a newer dump takes over the animation
	fill.CFrame = bottom
	fill.Transparency = 0
	task.delay(count * 0.06 + 0.3, function()
		Juice.ease(fill, 0.5, { CFrame = rim }, Enum.EasingStyle.Back)
		Juice.burst(top, 18, false)
		task.delay(0.6 + Config.BasketDrainSeconds * 0.25, function()
			if fill:GetAttribute("FxToken") ~= token then
				return
			end
			Juice.ease(fill, Config.BasketDrainSeconds, { CFrame = bottom }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			task.delay(Config.BasketDrainSeconds, function()
				if fill:GetAttribute("FxToken") ~= token then
					return
				end
				fill.Transparency = 1
			end)
		end)
	end)
end

return HayFx

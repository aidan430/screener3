-- World effects on your screen: the glowing needle clump (Wheel jackpot), the wheel turning
-- when you spin, your machines' fans spinning, and a marker over your own farm.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Ui = require(script.Parent.Ui)
local Juice = require(script.Parent.Juice)

local player = Players.LocalPlayer
local WorldFx = {}

local function myPlot()
	local index = player:GetAttribute("Plot")
	local plots = workspace:FindFirstChild("Plots")
	return index and plots and plots:FindFirstChild("Plot" .. index)
end

-- The Wheel's NEEDLE REVEAL: the needle's clump glows through everything.
function WorldFx.reveal(clump)
	task.spawn(function()
		local plot = myPlot()
		local pile = plot and plot:WaitForChild("Pile", 30)
		local part = pile and pile:WaitForChild(tostring(clump), 30)
		if not part then
			return
		end
		local glow = Instance.new("Highlight")
		glow.FillColor = Color3.fromRGB(255, 214, 90)
		glow.OutlineColor = Color3.fromRGB(255, 255, 255)
		glow.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		glow.Adornee = part
		glow.Parent = part
		local board = Ui.make("BillboardGui", { Adornee = part, Size = UDim2.fromOffset(220, 40), StudsOffset = Vector3.new(0, 5, 0), AlwaysOnTop = true, LightInfluence = 0, Parent = part })
		Ui.label({ Text = "THE NEEDLE IS HERE", Size = UDim2.fromScale(1, 1), TextColor3 = Ui.colors.hay, Parent = board }, 30)
		TweenService:Create(glow, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { FillTransparency = 0.8 }):Play()
	end)
end

-- Turns the wheel a few times and eases it to a stop on the prize's slice.
function WorldFx.spin(index, slices)
	local farm = workspace:FindFirstChild("Farm")
	local disc = farm and farm:FindFirstChild("WheelDisc")
	if not disc then
		return
	end
	Juice.sound("spin")
	local start = disc.CFrame
	local turns = math.pi * 2 * 5 + (index - 0.5) / slices * math.pi * 2
	local angle = Instance.new("NumberValue")
	angle.Changed:Connect(function(a)
		disc.CFrame = start * CFrame.Angles(a, 0, 0)
	end)
	TweenService:Create(angle, TweenInfo.new(4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Value = turns }):Play()
	task.delay(4.2, function()
		angle:Destroy()
	end)
end

local function spinFans()
	local spinning = 0
	RunService.RenderStepped:Connect(function(dt)
		spinning += dt
		if spinning < 1 / 30 then
			return
		end
		local step = spinning * 6
		spinning = 0
		local plot = myPlot()
		local built = plot and plot:FindFirstChild("Built")
		if not built then
			return
		end
		for _, model in ipairs(built:GetChildren()) do
			local fan = model:FindFirstChild("Fan")
			local lamp = model:FindFirstChild("Lamp")
			if fan and lamp and lamp.Color.G > lamp.Color.R then -- green lamp: powered
				fan.CFrame = fan.CFrame * CFrame.Angles(step, 0, 0)
			end
		end
	end)
end

local function markFarm()
	local plot = myPlot()
	local sign = plot and plot:WaitForChild("PlotSign", 30)
	if sign then
		local board = Ui.make("BillboardGui", { Adornee = sign, Size = UDim2.fromScale(16, 3), StudsOffset = Vector3.new(0, 6, 0), LightInfluence = 0, MaxDistance = 600, Parent = player:WaitForChild("PlayerGui") })
		Ui.label({ Text = "YOUR FARM", Size = UDim2.fromScale(1, 1), TextColor3 = Ui.colors.hay, Parent = board }, 48)
	end
end

function WorldFx.start()
	task.spawn(spinFans)
	task.spawn(function()
		while not player:GetAttribute("Plot") do
			player:GetAttributeChangedSignal("Plot"):Wait()
		end
		markFarm()
	end)
end

return WorldFx

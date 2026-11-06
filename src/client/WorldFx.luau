-- World effects on your screen: the glowing needle clump (Wheel jackpot), the wheel turning
-- when you spin, your machines' fans spinning, and a marker over your own farm.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Layout = require(Shared:WaitForChild("Layout"))(Config)
local Economy = require(Shared:WaitForChild("Economy"))(Config)
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
	local plot = player:GetAttribute("Plot")
	local centre = plot and Config.PlotCentres[plot]
	local offset = Layout[clump]
	if not centre or not offset then
		return
	end
	local x, z = Layout.origin(centre[1], centre[2])
	-- a soft golden glow inside the heap where the needle's clump is, seen through the straw
	local part = Ui.make("Part", { Name = "NeedleGlow", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Shape = Enum.PartType.Ball, Size = Vector3.new(3, 3, 3), Position = Vector3.new(x + offset[1], offset[2], z + offset[3]), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 214, 90), Transparency = 0.2, Parent = workspace })
	local glow = Instance.new("Highlight")
	glow.FillColor = Color3.fromRGB(255, 214, 90)
	glow.OutlineColor = Color3.fromRGB(255, 255, 255)
	glow.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	glow.Adornee = part
	glow.Parent = part
	local board = Ui.make("BillboardGui", { Adornee = part, Size = UDim2.fromOffset(220, 40), StudsOffset = Vector3.new(0, 5, 0), AlwaysOnTop = true, LightInfluence = 0, Parent = part })
	Ui.label({ Text = "THE NEEDLE IS HERE", Size = UDim2.fromScale(1, 1), TextColor3 = Ui.colors.hay, Parent = board }, 30)
	TweenService:Create(glow, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { FillTransparency = 0.8 }):Play()
	-- gone once the needle's found (the clump count jumps back to full)
	player:GetAttributeChangedSignal("Needles"):Connect(function()
		part:Destroy()
	end)
end

-- Turns the wheel a few times and eases it to a stop on the prize's slice.
function WorldFx.spin(index)
	local farm = workspace:FindFirstChild("Farm")
	local disc = farm and farm:FindFirstChild("WheelDisc")
	if not disc then
		return
	end
	Juice.sound("spin")
	-- always measured from where the wheel stood at first, so every spin lands on its prize
	local rest = disc:GetAttribute("RestCFrame")
	if typeof(rest) ~= "CFrame" then
		rest = disc.CFrame
		disc:SetAttribute("RestCFrame", rest)
	end
	local start, size = Economy.wheelSlice(index) -- stop somewhere inside the winning slice
	local stop = (start + size * (0.2 + 0.6 * math.random())) * math.pi * 2
	local angle = Instance.new("NumberValue")
	angle.Value = disc:GetAttribute("RestAngle") or 0
	disc:SetAttribute("RestAngle", stop)
	local turns = math.pi * 2 * 5 + stop
	angle.Changed:Connect(function(a)
		disc.CFrame = rest * CFrame.Angles(a, 0, 0)
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
		local tool = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChildOfClass("Tool")
		for _, weld in ipairs(tool and tool:GetDescendants() or {}) do -- the Twin Turbines' fans
			if weld.Name == "Spin" and weld:IsA("Weld") then
				weld.C0 = weld:GetAttribute("Base") * CFrame.Angles((os.clock() * Config.ToolFanSpin) % (math.pi * 2), 0, 0)
			end
		end
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

function WorldFx.start()
	task.spawn(spinFans)
end

return WorldFx

-- The Wheel of Fortune's face, drawn on the disc's flat side (a SurfaceGui): one pie slice per
-- prize, sized by its chance (Economy.wheelSlice), filled in by a fan of thin spokes, white lines
-- between the slices, and each prize's name and exact odds written along its slice. The spin
-- (client/WorldFx.spin) stops inside the winning slice. The 1-in-10,000 needle reveal is a thin
-- gold line, named on the sign under the wheel.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Economy = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Economy"))(Config)

local WheelFace = {}
local RIM, HUB = 0.47, 0.07 -- the slices' outer and inner edge, as a share of the disc's width
local SPOKE_DEGREES = 2 -- one spoke per this many degrees: enough to look like a smooth slice
local NEEDLE = Color3.fromRGB(255, 236, 120) -- the needle reveal's hairline: bright gold

-- A full-size frame turned `angle` degrees clockwise about the disc's centre; anything placed at
-- its top centre points out from the middle at that angle.
local function turned(gui, angle)
	local holder = Instance.new("Frame")
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.5)
	holder.Size = UDim2.fromScale(1, 1)
	holder.BackgroundTransparency = 1
	holder.Rotation = angle
	holder.Parent = gui
	return holder
end

-- A thin bar from the hub to the rim at `angle`.
local function spoke(gui, angle, colour, width, z)
	local bar = Instance.new("Frame")
	bar.AnchorPoint = Vector2.new(0.5, 0)
	bar.Position = UDim2.fromScale(0.5, 0.5 - RIM)
	bar.Size = UDim2.fromScale(width, RIM - HUB)
	bar.BackgroundColor3 = colour
	bar.BorderSizePixel = 0
	bar.ZIndex = z
	bar.Parent = turned(gui, angle)
end

function WheelFace.draw(disc)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "WheelFace"
	gui.Face = Enum.NormalId.Right -- the flat face turned towards the haystack
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0.4
	gui.Parent = disc
	local total = 0
	for _, prize in ipairs(Config.Wheel) do
		total += prize.weight
	end
	for i, prize in ipairs(Config.Wheel) do
		local turn, size = Economy.wheelSlice(i)
		local start, share = turn * 360, size * 360
		local count = math.max(1, math.ceil(share / SPOKE_DEGREES))
		local step = share / count
		local width = 2 * RIM * math.sin(math.rad(step) / 2) * 1.25 -- a little overlap, so no gaps
		local colour = if prize.reveal then NEEDLE else Color3.fromRGB(prize.head[1], prize.head[2], prize.head[3])
		for s = 0, count - 1 do
			spoke(gui, start + (s + 0.5) * step, colour, width, 1)
		end
		if share >= 3 then
			spoke(gui, start, Color3.new(1, 1, 1), 0.008, 2) -- the line between this slice and the last
		end
		local chance = prize.weight / total * 100
		local odds = (if chance < 1 then string.format("%.2f", chance) else string.format("%.0f", chance)) .. "%"
		local name = prize.name:gsub(" skin", "")
		if share >= 6 then -- the needle reveal's hairline has no room: the sign under the wheel names it
			local middle = start + share / 2
			local wide = share >= 25
			local label = Instance.new("TextLabel")
			label.AnchorPoint = Vector2.new(0.5, 0.5)
			label.Position = UDim2.fromScale(0.5, 0.5 - (RIM + HUB) / 2 - 0.01)
			label.Size = UDim2.fromScale(RIM - HUB - 0.05, math.min(0.2, (RIM + HUB) * math.sin(math.rad(share) / 2) * 0.8))
			label.Rotation = if middle > 180 then 90 else -90 -- along the slice, never upside down
			label.BackgroundTransparency = 1
			label.TextScaled = true
			label.Font = Enum.Font.FredokaOne
			label.TextColor3 = Color3.new(1, 1, 1)
			label.TextStrokeTransparency = 0.3
			label.ZIndex = 3
			label.Text = name .. (if wide then "\n" else " ") .. odds
			label.Parent = turned(gui, middle)
		end
	end
	local hub = Instance.new("Frame")
	hub.AnchorPoint = Vector2.new(0.5, 0.5)
	hub.Position = UDim2.fromScale(0.5, 0.5)
	hub.Size = UDim2.fromScale(HUB * 2 + 0.01, HUB * 2 + 0.01)
	hub.BackgroundColor3 = Color3.fromRGB(245, 200, 66)
	hub.ZIndex = 4
	hub.Parent = gui
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = hub
end

return WheelFace

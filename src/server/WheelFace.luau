-- The Wheel of Fortune's face, drawn on the disc's flat side (a SurfaceGui): one pie slice per
-- prize, filled in by a fan of thin spokes, white lines between the slices, and each prize's name
-- and exact odds written along its slice. Prize i is centred (i - 0.5) / n * 360 degrees
-- clockwise from the top, where the spin (client/WorldFx.spin) stops it under the pointer. The
-- slices are all the same size; the odds printed on each say how likely it is.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local WheelFace = {}
local RIM, HUB = 0.47, 0.07 -- the slices' outer and inner edge, as a share of the disc's width
local SPOKE_DEGREES = 2 -- one spoke per this many degrees: enough to look like a smooth slice
local NEEDLE = Color3.fromRGB(46, 42, 74) -- the needle reveal's slice: dark, so it stands apart from the gold disc

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
	local total, n = 0, #Config.Wheel
	for _, prize in ipairs(Config.Wheel) do
		total += prize.weight
	end
	local share = 360 / n
	local count = math.ceil(share / SPOKE_DEGREES)
	local step = share / count
	local width = 2 * RIM * math.sin(math.rad(step) / 2) * 1.25 -- a little overlap, so no gaps
	for i, prize in ipairs(Config.Wheel) do
		local start = (i - 1) * share
		local colour = if prize.reveal then NEEDLE else Color3.fromRGB(prize.head[1], prize.head[2], prize.head[3])
		for s = 0, count - 1 do
			spoke(gui, start + (s + 0.5) * step, colour, width, 1)
		end
		spoke(gui, start, Color3.new(1, 1, 1), 0.008, 2) -- the line between this slice and the last
		local chance = prize.weight / total * 100
		local label = Instance.new("TextLabel")
		label.AnchorPoint = Vector2.new(0.5, 0.5)
		label.Position = UDim2.fromScale(0.5, 0.5 - (RIM + HUB) / 2 - 0.01)
		label.Size = UDim2.fromScale(RIM - HUB - 0.05, 2 * (RIM + HUB) / 2 * math.sin(math.rad(share) / 2) * 0.8)
		local middle = start + share / 2
		label.Rotation = if middle > 180 then 90 else -90 -- along the slice, never upside down
		label.BackgroundTransparency = 1
		label.TextScaled = true
		label.Font = Enum.Font.FredokaOne
		label.TextColor3 = if prize.reveal then Color3.fromRGB(255, 214, 90) else Color3.new(1, 1, 1)
		label.TextStrokeTransparency = 0.3
		label.ZIndex = 3
		local odds = if chance < 1 then string.format("%.2f", chance) else string.format("%.0f", chance)
		label.Text = prize.name:gsub(" skin", ""):gsub("NEEDLE REVEAL", "Needle reveal") .. "\n" .. odds .. "%"
		label.Parent = turned(gui, middle)
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

-- The box opening on your screen: a strip of needle cards slides along under a gold marker,
-- slows and stops on the needle the server already chose, then the needle turns in 3D with its
-- rarity, value and whether it's new. The other cards are picked by the same odds (shared/Boxes)
-- and nothing is arranged to look like a near miss. Reduce effects in Settings makes it shorter.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Needles = require(Shared:WaitForChild("Needles"))
local Boxes = require(Shared:WaitForChild("Boxes"))
local Rules = require(Shared:WaitForChild("Rules"))
local UiKit = require(script.Parent.UiKit)
local Effects = require(script.Parent.Effects)
local NeedleView = require(script.Parent.NeedleView)

local BoxReel = {}
local CARD, GAP, COUNT, LAND = 132, 10, 46, 40 -- card width, gap, cards on the strip, the winning card
local rng = Random.new()

local function rgb(c)
	return Color3.fromRGB(c[1], c[2], c[3])
end

-- A card: the needle's colours as a little needle, its name, and a bar in its rarity colour.
local function card(parent, i, typeId, skinId)
	local skin = Needles.skin(skinId)
	local rarity = Needles.rarity(skin.rarity)
	local c = UiKit.make("Frame", { Position = UDim2.fromOffset((i - 1) * (CARD + GAP), 0), Size = UDim2.fromOffset(CARD, 150), BackgroundColor3 = UiKit.colors.card, ZIndex = 62, Parent = parent }, { UiKit.corner(10), UiKit.stroke(rgb(rarity.colour), 2) })
	local glow = UiKit.make("Frame", { Size = UDim2.new(1, 0, 0, 96), BackgroundColor3 = rgb(rarity.colour), BackgroundTransparency = 0.8, ZIndex = 62, Parent = c }, { UiKit.corner(10) })
	local shaft = UiKit.make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(92, 9), Rotation = -30, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 63, Parent = glow }, { UiKit.corner(4) })
	local a, b = rgb(skin.colours[1]), rgb(skin.colours[2] or skin.colours[1])
	UiKit.make("UIGradient", { Color = if skin.pattern == "rainbow" then ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 0.6, 1)), ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.4, 0.6, 1)), ColorSequenceKeypoint.new(1, Color3.fromHSV(0.8, 0.6, 1)) }) else ColorSequence.new(a, b), Parent = shaft })
	UiKit.label({ Text = skin.name, Font = UiKit.bold, Size = UDim2.new(1, -10, 0, 22), Position = UDim2.fromOffset(5, 98), ZIndex = 63, Parent = c }, 18)
	UiKit.label({ Text = Needles.type(typeId).name, Size = UDim2.new(1, -10, 0, 18), Position = UDim2.fromOffset(5, 120), TextColor3 = UiKit.colors.soft, ZIndex = 63, Parent = c }, 14)
	UiKit.make("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 6), BackgroundColor3 = rgb(rarity.colour), ZIndex = 64, Parent = c }, { UiKit.corner(3) })
	return c
end

-- The reveal under the reel: the needle in 3D, what it is and what it's worth.
local function reveal(panel, result, again, close)
	local rarity = Needles.rarity(result.rarityId)
	local box = UiKit.make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 236), Size = UDim2.fromOffset(560, 250), BackgroundColor3 = UiKit.colors.panel, ZIndex = 62, Parent = panel }, { UiKit.corner(16), UiKit.stroke(rgb(rarity.colour), 3) })
	NeedleView.make(box, result.type, result.skin, { Size = UDim2.fromOffset(220, 200), Position = UDim2.fromOffset(10, 24), ZIndex = 63 }, true)
	UiKit.label({ Text = rarity.name:upper() .. (if result.new then "  ·  NEW!" else ""), Font = UiKit.bold, TextColor3 = rgb(rarity.colour), Size = UDim2.new(1, -250, 0, 30), Position = UDim2.fromOffset(240, 26), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 63, Parent = box }, 26)
	UiKit.label({ Text = result.name, Font = UiKit.bold, Size = UDim2.new(1, -250, 0, 56), Position = UDim2.fromOffset(240, 60), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 63, Parent = box }, 26)
	UiKit.label({ Text = "Worth " .. Rules.commas(result.value) .. (if result.new then "" else "  ·  you have more than one now: trade it!"), Size = UDim2.new(1, -250, 0, 40), Position = UDim2.fromOffset(240, 118), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UiKit.colors.soft, ZIndex = 63, Parent = box }, 18)
	local more = UiKit.button("Open another", UiKit.colors.green, { Position = UDim2.fromOffset(240, 178), Size = UDim2.fromOffset(150, 46), ZIndex = 63, Parent = box })
	local done = UiKit.button("Done", UiKit.colors.card, { Position = UDim2.fromOffset(400, 178), Size = UDim2.fromOffset(140, 46), ZIndex = 63, Parent = box })
	more.Activated:Connect(again)
	done.Activated:Connect(close)
	UiKit.pop(box, 0.8)
	Effects.sound("found", if rarity.mult >= 40 then 1.25 else 1)
end

-- Plays the opening for `result` (from the server) in `parent` (the Boxes window). again() opens
-- another of the same box; close() returns to the boxes.
function BoxReel.play(parent, result, again, close)
	local box = Boxes.get(result.box) or Boxes.get("hay")
	local panel = UiKit.make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = UiKit.colors.panel, ZIndex = 60, Parent = parent }, { UiKit.corner(18) })
	UiKit.label({ Text = "Opening the " .. box.name .. "...", Font = UiKit.bold, Size = UDim2.new(1, -40, 0, 36), Position = UDim2.fromOffset(20, 18), TextColor3 = rgb(box.colour), ZIndex = 61, Parent = panel }, 28)
	local window = UiKit.make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 70), Size = UDim2.new(1, -40, 0, 150), BackgroundColor3 = Color3.fromRGB(70, 52, 34), ClipsDescendants = true, ZIndex = 61, Parent = panel }, { UiKit.corner(12), UiKit.stroke(Color3.fromRGB(150, 110, 64), 3) })
	local strip = UiKit.make("Frame", { Size = UDim2.fromOffset(COUNT * (CARD + GAP), 150), BackgroundTransparency = 1, ZIndex = 61, Parent = window })
	for i = 1, COUNT do
		if i == LAND then
			card(strip, i, result.type, result.skin)
		else
			card(strip, i, Boxes.filler(box, rng))
		end
	end
	UiKit.make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.new(0, 4, 1, 0), BackgroundColor3 = UiKit.colors.gold, ZIndex = 70, Parent = window }) -- the marker
	local width = window.AbsoluteSize.X
	local stopAt = (LAND - 1) * (CARD + GAP) + CARD / 2 + rng:NextNumber(-CARD * 0.35, CARD * 0.35) -- somewhere on the card, never its edge
	local seconds = if Effects.settings.reduceEffects then 2 else 5.5
	strip.Position = UDim2.fromOffset(width / 2 - CARD / 2, 0)
	local tween = UiKit.ease(strip, seconds, { Position = UDim2.fromOffset(width / 2 - stopAt, 0) }, Enum.EasingStyle.Quint)
	local last = 0
	local conn = RunService.RenderStepped:Connect(function() -- a soft tick as each card passes the marker
		local passed = math.floor((width / 2 - strip.Position.X.Offset) / (CARD + GAP))
		if passed ~= last then
			last = passed
			Effects.sound("click", 1.4)
		end
	end)
	tween.Completed:Wait()
	conn:Disconnect()
	if panel.Parent then
		reveal(panel, result, function()
			panel:Destroy()
			again()
		end, function()
			panel:Destroy()
			close()
		end)
	end
end

return BoxReel

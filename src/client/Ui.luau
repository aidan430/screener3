-- A small UI kit in the "farm journal" style: cream paper cards, ink-brown text, serif headings,
-- flat muted buttons and windows that scale with the screen, and helpers for touch screens.
local Ui = {}

Ui.colors = {
	wood = Color3.fromRGB(116, 88, 60), -- warm brown: plain buttons
	woodDark = Color3.fromRGB(59, 42, 26), -- ink: lines, dark buttons
	hay = Color3.fromRGB(206, 152, 46), -- mustard: highlights, bars
	cream = Color3.fromRGB(246, 237, 218), -- the paper
	paper = Color3.fromRGB(234, 220, 190), -- the paper's darker edge, tab rails
	red = Color3.fromRGB(176, 84, 60), -- rust
	green = Color3.fromRGB(96, 128, 74), -- sage
	blue = Color3.fromRGB(76, 106, 130), -- slate
	purple = Color3.fromRGB(122, 90, 128), -- plum
	grey = Color3.fromRGB(140, 122, 100), -- soft brown-grey
	soft = Color3.fromRGB(122, 98, 72), -- secondary text on paper
	ink = Color3.fromRGB(59, 42, 26),
	white = Color3.fromRGB(255, 250, 238),
}
Ui.font = Enum.Font.Merriweather -- headings (shown in its bold weight, below)
Ui.body = Enum.Font.BuilderSans
Ui.bold = Enum.Font.BuilderSansBold
local HEADING = Font.new("rbxasset://fonts/families/Merriweather.json", Enum.FontWeight.Bold)

-- Headings in the bold serif: anything set in Ui.font.
local function serif(instance)
	if instance.Font == Ui.font then
		instance.FontFace = HEADING
	end
	return instance
end
Ui.serif = serif

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local camera = workspace.CurrentCamera or workspace:WaitForChild("Camera")
local scales, layouts = {}, {}

-- A touch screen in use: a phone or tablet (no keyboard), or a touch laptop last touched.
function Ui.touch()
	if not UserInputService.TouchEnabled then
		return false
	end
	return not UserInputService.KeyboardEnabled or UserInputService:GetLastInputType() == Enum.UserInputType.Touch
end

-- Phones get a smaller UI, big monitors a larger one; touch screens never so small that text
-- can't be read or buttons can't be tapped.
local function screenScale()
	return math.clamp(camera.ViewportSize.Y / 760, if Ui.touch() then Config.Touch.minScale else 0.55, 1.15)
end

-- The height of Roblox's own top bar (its menu and chat buttons), in pixels.
function Ui.topInset()
	local ok, inset = pcall(GuiService.GetGuiInset, GuiService)
	return if ok and typeof(inset) == "Vector2" then inset.Y else 36
end

-- Runs fn now and again whenever the screen changes size (a phone turning) or the player
-- switches between touch and mouse.
function Ui.onLayout(fn)
	table.insert(layouts, fn)
	task.spawn(fn)
end

local function relayout()
	for _, scale in ipairs(scales) do
		scale.Scale = screenScale()
	end
	for _, fn in ipairs(layouts) do
		task.spawn(fn)
	end
end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(relayout)
local wasTouch = Ui.touch()
UserInputService.LastInputTypeChanged:Connect(function()
	if Ui.touch() ~= wasTouch then
		wasTouch = Ui.touch()
		relayout()
	end
end)

-- Instance.new with properties and children; Parent is set last.
function Ui.make(className, props, children)
	local instance = Instance.new(className)
	for name, value in pairs(props) do
		if name ~= "Parent" then
			instance[name] = value
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = instance
	end
	if props.Parent then
		instance.Parent = props.Parent
	end
	return instance
end

function Ui.corner(radius)
	return Ui.make("UICorner", { CornerRadius = UDim.new(0, radius or 12) })
end

-- A fine pencil line round a card (thick wooden borders belong to another style).
function Ui.stroke(color, thickness)
	return Ui.make("UIStroke", { Color = color or Ui.colors.woodDark, Thickness = math.min(thickness or 1, 1.5), Transparency = 0.78, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

function Ui.maxText(size)
	return Ui.make("UITextSizeConstraint", { MaxTextSize = size })
end

-- Scales `frame` (around its AnchorPoint) with the screen height.
Ui.screenScale = function()
	return screenScale()
end

function Ui.autoScale(frame)
	local scale = Ui.make("UIScale", { Scale = screenScale(), Parent = frame })
	table.insert(scales, scale)
	return scale
end

-- Sizes a scaled window to width x height, shrunk to fit the screen under Roblox's top bar
-- (on a phone the window fills most of the screen; its body scrolls).
local fitted = setmetatable({}, { __mode = "k" })
function Ui.fit(frame, width, height)
	frame:SetAttribute("FitW", width)
	frame:SetAttribute("FitH", height)
	if fitted[frame] then
		fitted[frame]() -- a new size for a window already fitted (the shop is bigger)
		return
	end
	fitted[frame] = function()
		local s, view, inset = screenScale(), camera.ViewportSize, Ui.topInset()
		local w = math.min(frame:GetAttribute("FitW") + (frame:GetAttribute("Rail") or 0), (view.X - 24) / s)
		local h = math.min(frame:GetAttribute("FitH"), (view.Y - inset - 16) / s)
		frame.Size = UDim2.fromOffset(w, h)
		frame.Position = UDim2.new(0.5, 0, 0.5, inset / 2)
	end
	Ui.onLayout(fitted[frame])
end

-- A text label. `maxSize` caps the scaled text size.
function Ui.label(props, maxSize)
	local defaults = {
		BackgroundTransparency = 1,
		Font = Ui.font,
		Text = "",
		TextColor3 = Ui.colors.white,
		TextScaled = true,
		TextWrapped = true,
		TextStrokeColor3 = Ui.colors.woodDark,
		TextStrokeTransparency = 0.7, -- a soft shadow, readable over the world; none on paper (set 1)
	}
	for name, value in pairs(props) do
		defaults[name] = value
	end
	return serif(Ui.make("TextLabel", defaults, { Ui.maxText(maxSize or 40) }))
end

function Ui.button(text, color, props)
	local defaults = {
		Text = text,
		Font = Ui.bold,
		TextScaled = true,
		TextColor3 = Ui.colors.white,
		TextStrokeTransparency = 1,
		BackgroundColor3 = color,
		AutoButtonColor = true,
	}
	for name, value in pairs(props or {}) do
		defaults[name] = value
	end
	return Ui.make("TextButton", defaults, {
		Ui.corner(5),
		Ui.maxText(20),
		Ui.make("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }),
	})
end

-- Paragraph text that grows to fit, for lists inside windows.
function Ui.paragraph(text, props)
	local defaults = {
		Text = text,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = Ui.body,
		TextSize = 19,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Ui.colors.ink,
	}
	for name, value in pairs(props or {}) do
		defaults[name] = value
	end
	return serif(Ui.make("TextLabel", defaults))
end

require(script.Parent.UiJournal)(Ui) -- paper cards, pins, stamps and the journal windows

return Ui

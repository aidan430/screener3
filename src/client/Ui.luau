-- A small UI kit: the farm colours, rounded wooden buttons and windows that scale with
-- the screen, and helpers for touch screens.
local Ui = {}

Ui.colors = {
	wood = Color3.fromRGB(110, 70, 40),
	woodDark = Color3.fromRGB(62, 38, 22),
	hay = Color3.fromRGB(242, 196, 82),
	cream = Color3.fromRGB(255, 244, 222),
	paper = Color3.fromRGB(246, 232, 200),
	red = Color3.fromRGB(200, 64, 48),
	green = Color3.fromRGB(84, 166, 70),
	blue = Color3.fromRGB(64, 136, 206),
	purple = Color3.fromRGB(136, 92, 196),
	grey = Color3.fromRGB(128, 120, 112),
	ink = Color3.fromRGB(56, 36, 20),
	white = Color3.new(1, 1, 1),
}
Ui.font = Enum.Font.FredokaOne
Ui.body = Enum.Font.GothamMedium

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

function Ui.stroke(color, thickness)
	return Ui.make("UIStroke", { Color = color or Ui.colors.woodDark, Thickness = thickness or 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
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
		local w = math.min(frame:GetAttribute("FitW"), (view.X - 24) / s)
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
		TextStrokeTransparency = 0.35,
	}
	for name, value in pairs(props) do
		defaults[name] = value
	end
	return Ui.make("TextLabel", defaults, { Ui.maxText(maxSize or 40) })
end

function Ui.button(text, color, props)
	local defaults = {
		Text = text,
		Font = Ui.font,
		TextScaled = true,
		TextColor3 = Ui.colors.white,
		TextStrokeColor3 = Ui.colors.woodDark,
		TextStrokeTransparency = 0.4,
		BackgroundColor3 = color,
		AutoButtonColor = true,
	}
	for name, value in pairs(props or {}) do
		defaults[name] = value
	end
	return Ui.make("TextButton", defaults, {
		Ui.corner(10),
		Ui.stroke(Ui.colors.woodDark, 3),
		Ui.maxText(28),
		Ui.make("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }),
	})
end

-- A centred window with a title and a close button. Returns frame, body (a scrolling list).
function Ui.window(parent, title, onClose)
	local frame = Ui.make("Frame", {
		Name = title,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(540, 480),
		BackgroundColor3 = Ui.colors.cream,
		Visible = false,
		Parent = parent,
	}, { Ui.corner(18), Ui.stroke(Ui.colors.wood, 5) })
	Ui.autoScale(frame)
	Ui.fit(frame, 540, 480)
	Ui.make("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, 58), BackgroundColor3 = Ui.colors.wood, Parent = frame }, { Ui.corner(16) })
	Ui.label({ Text = title, Size = UDim2.new(1, -120, 0, 46), Position = UDim2.fromOffset(20, 6), TextXAlignment = Enum.TextXAlignment.Left, Parent = frame }, 34)
	local close = Ui.button("X", Ui.colors.red, { Size = UDim2.fromOffset(46, 42), Position = UDim2.new(1, -56, 0, 8), Parent = frame })
	close.Activated:Connect(function()
		frame.Visible = false
		if onClose then
			onClose()
		end
	end)
	local body = Ui.make("ScrollingFrame", {
		Name = "Body",
		Size = UDim2.new(1, -24, 1, -76),
		Position = UDim2.fromOffset(12, 68),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = Ui.colors.wood,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = frame,
	}, {
		Ui.make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
		Ui.make("UIPadding", { PaddingRight = UDim.new(0, 10) }),
	})
	return frame, body
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
	return Ui.make("TextLabel", defaults)
end

return Ui

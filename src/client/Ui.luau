-- A small UI kit: the farm colours, rounded wooden buttons and windows that scale with
-- the screen (phones get a smaller UI, big monitors a larger one).
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

local camera = workspace.CurrentCamera or workspace:WaitForChild("Camera")
local scales = {}

local function screenScale()
	return math.clamp(camera.ViewportSize.Y / 760, 0.55, 1.15)
end

camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	for _, scale in ipairs(scales) do
		scale.Scale = screenScale()
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
function Ui.autoScale(frame)
	local scale = Ui.make("UIScale", { Scale = screenScale(), Parent = frame })
	table.insert(scales, scale)
	return scale
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

-- The UI's look in one place: a clean, modern dark-glass style with warm gold accents, big
-- readable text and large touch targets. Every screen builds from these helpers.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local UiKit = {}

UiKit.colors = {
	panel = Color3.fromRGB(24, 28, 38), -- window backgrounds (slightly see-through)
	card = Color3.fromRGB(38, 44, 58),
	line = Color3.fromRGB(70, 78, 96),
	text = Color3.fromRGB(240, 242, 248),
	soft = Color3.fromRGB(168, 176, 196),
	gold = Color3.fromRGB(255, 200, 70),
	green = Color3.fromRGB(80, 190, 120),
	red = Color3.fromRGB(230, 90, 80),
	blue = Color3.fromRGB(90, 150, 240),
	purple = Color3.fromRGB(160, 120, 240),
}
UiKit.font = Enum.Font.BuilderSans
UiKit.bold = Enum.Font.BuilderSansBold

function UiKit.make(class, props, children)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then
			o[k] = v
		end
	end
	for _, c in ipairs(children or {}) do
		c.Parent = o
	end
	if props and props.Parent then
		o.Parent = props.Parent
	end
	return o
end

function UiKit.corner(r)
	return UiKit.make("UICorner", { CornerRadius = UDim.new(0, r or 12) })
end

function UiKit.stroke(colour, thickness)
	return UiKit.make("UIStroke", { Color = colour or UiKit.colors.line, Thickness = thickness or 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

function UiKit.pad(px)
	return UiKit.make("UIPadding", { PaddingTop = UDim.new(0, px), PaddingBottom = UDim.new(0, px), PaddingLeft = UDim.new(0, px), PaddingRight = UDim.new(0, px) })
end

function UiKit.label(props, maxSize)
	local defaults = { BackgroundTransparency = 1, Font = UiKit.font, TextColor3 = UiKit.colors.text, TextScaled = true, TextWrapped = true, Text = "" }
	for k, v in pairs(props) do
		defaults[k] = v
	end
	return UiKit.make("TextLabel", defaults, { UiKit.make("UITextSizeConstraint", { MaxTextSize = maxSize or 28 }) })
end

function UiKit.button(text, colour, props)
	local defaults = { Text = text, Font = UiKit.bold, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), BackgroundColor3 = colour or UiKit.colors.blue, AutoButtonColor = true, Size = UDim2.fromOffset(140, 44) }
	for k, v in pairs(props or {}) do
		defaults[k] = v
	end
	local b = UiKit.make("TextButton", defaults, { UiKit.corner(10), UiKit.make("UITextSizeConstraint", { MaxTextSize = 22 }), UiKit.make("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }) })
	b.Activated:Connect(function()
		UiKit.pop(b, 0.92)
	end)
	return b
end

-- A soft spring: scales from `from` back to 1.
function UiKit.pop(obj, from)
	local s = obj:FindFirstChildOfClass("UIScale") or UiKit.make("UIScale", { Parent = obj })
	s.Scale = from
	TweenService:Create(s, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

function UiKit.ease(obj, seconds, goal, style)
	local t = TweenService:Create(obj, TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal)
	t:Play()
	return t
end

-- True on phones and tablets (no mouse): screens use bigger targets there.
function UiKit.touch()
	return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

-- Keeps a frame readable on every screen: scales it with the viewport (0.65x on a small phone,
-- up to 1.15x on a big monitor).
function UiKit.autoScale(frame)
	local scale = frame:FindFirstChild("AutoScale") or UiKit.make("UIScale", { Name = "AutoScale", Parent = frame })
	local function fit()
		local v = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
		scale.Scale = math.clamp(math.min(v.X / 1280, v.Y / 720), 0.65, 1.15)
	end
	fit()
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	return scale
end

-- A centred window (a little below the middle, clear of the round banner) with a title and a
-- close button. Returns the window and its body.
function UiKit.window(gui, title, w, h)
	local win = UiKit.make("Frame", { Name = title, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.57), Size = UDim2.fromOffset(w or 620, h or 460), BackgroundColor3 = UiKit.colors.panel, BackgroundTransparency = 0.06, Visible = false, ZIndex = 10, Parent = gui }, { UiKit.corner(18), UiKit.stroke() })
	UiKit.autoScale(win)
	UiKit.label({ Text = title, Font = UiKit.bold, Size = UDim2.new(1, -100, 0, 40), Position = UDim2.fromOffset(22, 14), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 11, Parent = win }, 30)
	local close = UiKit.button("X", UiKit.colors.card, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 14), Size = UDim2.fromOffset(44, 40), ZIndex = 11, Parent = win })
	close.Activated:Connect(function()
		win.Visible = false
	end)
	local body = UiKit.make("ScrollingFrame", { Size = UDim2.new(1, -36, 1, -78), Position = UDim2.fromOffset(18, 64), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 6, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ZIndex = 11, Parent = win }, {
		UiKit.make("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	return win, body
end

-- A rounded progress bar; returns the bar and its fill.
function UiKit.bar(parent, props, colour)
	local back = UiKit.make("Frame", props, { UiKit.corner(6) })
	back.BackgroundColor3 = UiKit.colors.line
	back.Parent = parent
	local fill = UiKit.make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = colour or UiKit.colors.gold, ZIndex = back.ZIndex + 1, Parent = back }, { UiKit.corner(6) })
	return back, fill
end

UiKit.player = Players.LocalPlayer
return UiKit

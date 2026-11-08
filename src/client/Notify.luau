-- Messages: small toasts under the haystack counter, and a big banner for case news.
local Ui = require(script.Parent.Ui)

local Notify = {}
local stack, banner, bannerTitle, bannerBody
local order = 0
local bannerToken = 0

function Notify.mount(gui)
	stack = Ui.make("Frame", {
		Name = "Toasts",
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromOffset(460, 220),
		BackgroundTransparency = 1,
		Parent = gui,
	}, { Ui.make("UIListLayout", { Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) })
	Ui.autoScale(stack)
	Ui.onLayout(function()
		stack.Position = UDim2.new(0.5, 0, 0, 10 + 70 * Ui.screenScale()) -- just under the heap's progress
	end)

	banner = Ui.make("Frame", {
		Name = "Banner",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.36),
		Size = UDim2.fromOffset(560, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Ui.colors.cream,
		Visible = false,
		Active = true, -- a tap that dismisses it doesn't also harvest
		Parent = gui,
	}, {
		Ui.corner(8),
		Ui.stroke(),
		Ui.make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
		Ui.make("UIPadding", { PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 16), PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18) }),
	})
	Ui.autoScale(banner)
	bannerTitle = Ui.paragraph("", { LayoutOrder = 1, Font = Ui.font, TextSize = 30, TextColor3 = Ui.colors.ink, TextXAlignment = Enum.TextXAlignment.Center, Parent = banner })
	bannerBody = Ui.paragraph("", { LayoutOrder = 2, TextSize = 18, TextColor3 = Ui.colors.soft, TextXAlignment = Enum.TextXAlignment.Center, Parent = banner })
	banner.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			banner.Visible = false
		end
	end)
end

function Notify.toast(text, colour)
	if not stack then
		return
	end
	order += 1
	local card = Ui.make("Frame", {
		LayoutOrder = order,
		Size = UDim2.fromOffset(440, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Ui.colors.cream, -- paper, with the message's colour as a stripe on its left
		Parent = stack,
	}, {
		Ui.corner(6),
		Ui.stroke(),
		Ui.make("UIPadding", { PaddingTop = UDim.new(0, 9), PaddingBottom = UDim.new(0, 9), PaddingLeft = UDim.new(0, 20), PaddingRight = UDim.new(0, 14) }),
	})
	Ui.make("Frame", { Size = UDim2.new(0, 4, 1, 18), Position = UDim2.fromOffset(-20, -9), BackgroundColor3 = colour or Ui.colors.wood, BorderSizePixel = 0, Parent = card }, { Ui.corner(2) })
	Ui.paragraph(text, { TextSize = 17, TextColor3 = Ui.colors.ink, Parent = card })
	local cards = {}
	for _, child in ipairs(stack:GetChildren()) do
		if child:IsA("Frame") then
			table.insert(cards, child)
		end
	end
	if #cards > 4 then
		table.sort(cards, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		cards[1]:Destroy()
	end
	task.delay(4, function()
		if card.Parent then
			card:Destroy()
		end
	end)
end

function Notify.banner(title, body, seconds)
	if not banner then
		return
	end
	bannerToken += 1
	local token = bannerToken
	bannerTitle.Text = title
	bannerBody.Text = body
	banner.Visible = true
	task.delay(seconds or 6, function()
		if token == bannerToken then
			banner.Visible = false
		end
	end)
end

return Notify

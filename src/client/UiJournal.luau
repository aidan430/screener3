-- The farm journal's own pieces for the UI kit: paper cards, pins, thin bars, round stamp
-- buttons and the journal windows with their tab rail. Usage (from Ui.luau): require(this)(Ui).
return function(Ui)
	-- A paper card: cream, softly rounded, a fine line round it.
	function Ui.card(props)
		local defaults = { BackgroundColor3 = Ui.colors.cream, BorderSizePixel = 0 }
		for name, value in pairs(props) do
			defaults[name] = value
		end
		return Ui.make("Frame", defaults, { Ui.corner(6), Ui.stroke() })
	end

	-- A pin at the top of a note card, in `colour`.
	function Ui.pin(card, colour)
		return Ui.make("Frame", { Name = "Pin", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = colour or Ui.colors.red, ZIndex = 3, Parent = card }, { Ui.corner(6) })
	end

	-- A thin progress line: returns the track and its fill (scale X = share).
	function Ui.bar(parent, props, colour)
		local defaults = { Size = UDim2.new(1, 0, 0, 5), BackgroundColor3 = Ui.colors.woodDark, BackgroundTransparency = 0.84, BorderSizePixel = 0, Parent = parent }
		for name, value in pairs(props or {}) do
			defaults[name] = value
		end
		local track = Ui.make("Frame", defaults, { Ui.corner(3) })
		local fill = Ui.make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = colour or Ui.colors.hay, BorderSizePixel = 0, Parent = track }, { Ui.corner(3) })
		return track, fill
	end

	-- A round paper stamp button: a word in the serif and a small caption (its key) under it.
	function Ui.stamp(text, caption, props)
		local defaults = { Text = "", AutoButtonColor = true, BackgroundColor3 = Ui.colors.cream, Size = UDim2.fromOffset(64, 64) }
		for name, value in pairs(props or {}) do
			defaults[name] = value
		end
		local stamp = Ui.make("TextButton", defaults, { Ui.corner(32), Ui.stroke() })
		local word = Ui.serif(Ui.make("TextLabel", { Name = "Word", Text = text, BackgroundTransparency = 1, Font = Ui.font, TextColor3 = Ui.colors.ink, TextScaled = true, Size = UDim2.new(0.8, 0, 0, 20), Position = UDim2.new(0.1, 0, 0.5, -16), Parent = stamp }, { Ui.maxText(16) }))
		Ui.make("TextLabel", { Name = "Caption", Text = caption or "", BackgroundTransparency = 1, Font = Ui.bold, TextColor3 = Ui.colors.soft, TextScaled = true, Size = UDim2.new(0.7, 0, 0, 12), Position = UDim2.new(0.15, 0, 0.5, 6), Parent = stamp }, { Ui.maxText(11) })
		return stamp, word
	end

	-- The farm journal's pages, in the order of the tab rail down the left of each journal window.
	-- Ui.journalOpen (set by Panels) opens a page by its key.
	Ui.JOURNAL = { { "Shop", "Shop" }, { "Achievements", "Achievements" }, { "Finds", "Skins & finds" }, { "Wheel", "Wheel" } }
	Ui.journalOpen = nil
	local RAIL = 160

	-- A centred paper window with a serif title and a quiet Close. With `page` (a key in
	-- Ui.JOURNAL) it is a page of the farm journal: a tab rail down its left opens the others.
	-- Returns frame, body (a scrolling list).
	function Ui.window(parent, title, onClose, page)
		local rail = if page then RAIL else 0
		local frame = Ui.make("Frame", {
			Name = title,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(540 + rail, 480),
			BackgroundColor3 = Ui.colors.cream,
			Visible = false,
			Parent = parent,
		}, { Ui.corner(8), Ui.stroke() })
		frame:SetAttribute("Rail", rail)
		Ui.autoScale(frame)
		Ui.fit(frame, 540, 480)
		if page then
			local side = Ui.make("Frame", { Name = "Rail", Size = UDim2.new(0, rail, 1, 0), BackgroundColor3 = Ui.colors.paper, BorderSizePixel = 0, Parent = frame }, { Ui.corner(8) })
			Ui.make("Frame", { Size = UDim2.new(0, 10, 1, 0), Position = UDim2.new(1, -10, 0, 0), BackgroundColor3 = Ui.colors.paper, BorderSizePixel = 0, Parent = side }) -- square inner edge
			Ui.label({ Text = "Farm journal", Size = UDim2.new(1, -28, 0, 26), Position = UDim2.fromOffset(18, 22), TextColor3 = Ui.colors.ink, TextStrokeTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Parent = side }, 20)
			for i, entry in ipairs(Ui.JOURNAL) do
				local here = entry[1] == page
				local tab = Ui.make("TextButton", {
					Text = entry[2], Font = if here then Ui.bold else Ui.body, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left,
					TextColor3 = if here then Ui.colors.ink else Ui.colors.soft, AutoButtonColor = not here,
					BackgroundColor3 = Ui.colors.cream, BackgroundTransparency = if here then 0 else 1, BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 38), Position = UDim2.fromOffset(0, 62 + (i - 1) * 40), Parent = side,
				}, { Ui.make("UIPadding", { PaddingLeft = UDim.new(0, 20) }) })
				if here then
					Ui.make("Frame", { Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = Ui.colors.red, BorderSizePixel = 0, Parent = tab })
				else
					tab.Activated:Connect(function()
						if Ui.journalOpen then
							Ui.journalOpen(entry[1])
						end
					end)
				end
			end
		end
		Ui.label({ Text = title, Size = UDim2.new(1, -rail - 150, 0, 34), Position = UDim2.fromOffset(rail + 24, 18), TextColor3 = Ui.colors.ink, TextStrokeTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Parent = frame }, 28)
		local close = Ui.make("TextButton", { Text = "Close", Font = Ui.body, TextSize = 15, TextColor3 = Ui.colors.soft, BackgroundTransparency = 1, Size = UDim2.fromOffset(70, 30), Position = UDim2.new(1, -84, 0, 16), Parent = frame })
		close.Activated:Connect(function()
			frame.Visible = false
			if onClose then
				onClose()
			end
		end)
		local body = Ui.make("ScrollingFrame", {
			Name = "Body",
			Size = UDim2.new(1, -rail - 40, 1, -84),
			Position = UDim2.fromOffset(rail + 24, 66),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = Ui.colors.grey,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),
			Parent = frame,
		}, {
			Ui.make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
			Ui.make("UIPadding", { PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 8) }),
		})
		return frame, body
	end
end

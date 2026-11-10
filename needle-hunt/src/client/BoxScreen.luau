-- The Boxes screen: each box with its price (coins; the dearer ones also Robux), a key button
-- (keys come from chests in rounds: a free open), and below them
-- the exact odds of every rarity and the skins inside each box, always on show, and how many opens until
-- the Rare-or-better guarantee. Opening asks the server (Remotes.Box), which decides; Robux opens
-- come back through Remotes.BoxResult. Where paid random items are restricted, the screen says
-- boxes aren't available and shows nothing to buy.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Boxes = require(Shared:WaitForChild("Boxes"))
local Needles = require(Shared:WaitForChild("Needles"))
local Rules = require(Shared:WaitForChild("Rules"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UiKit = require(script.Parent.UiKit)
local Hud = require(script.Parent.Hud)
local BoxReel = require(script.Parent.BoxReel)

local player = Players.LocalPlayer
local BoxScreen = {}
local win, body
local prices = {}
local hasKey = {} -- boxes that chests hold keys for
for _, k in ipairs(Config.Chests.keys) do
	hasKey[k.id] = true
end

local function rgb(c)
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function clear()
	for _, c in ipairs(body:GetChildren()) do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
end

local function robuxPrice(id, button)
	if prices[id] then
		button.Text = prices[id]
		return
	end
	task.spawn(function()
		local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, id, Enum.InfoType.Product)
		if ok and info and info.PriceInRobux then
			prices[id] = "R$ " .. info.PriceInRobux
			if button.Parent then
				button.Text = prices[id]
			end
		end
	end)
end

local function open(box, withKey)
	local ok, result = Remotes.Box:InvokeServer(if withKey then "key" else "open", box.id)
	if not ok then
		Hud.toast(tostring(result), "bad")
		return
	end
	BoxReel.play(win, result, function()
		open(box, withKey)
	end, BoxScreen.refresh)
end

-- A line of the odds: a name and its chance, a bar, and what it can be underneath.
local function oddsLine(panel, i, title, percent, colour, detail)
	local line = UiKit.make("Frame", { LayoutOrder = i, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = panel })
	UiKit.label({ Text = string.format("%s  %g%%", title, percent), Font = UiKit.bold, TextColor3 = colour, Size = UDim2.new(0, 260, 0, 22), TextXAlignment = Enum.TextXAlignment.Left, Parent = line }, 18)
	local _, fill = UiKit.bar(line, { Size = UDim2.new(1, -270, 0, 8), Position = UDim2.fromOffset(270, 8) }, colour)
	fill.Size = UDim2.fromScale(math.max(percent / 100, 0.01), 1)
	UiKit.label({ Text = detail, TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 18), Position = UDim2.fromOffset(0, 24), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UiKit.colors.soft, Parent = line }, 14)
end

-- The Heirloom Box's odds: each tier, every Heirloom and Exotic shape's own chance, the skin odds.
local function tiered(panel, box)
	for i, row in ipairs(Boxes.tiers(box)) do
		local look = row.grade or row.rarity
		local names = {}
		for _, sh in ipairs(row.shapes) do
			table.insert(names, string.format("%s %.2f%%", sh.type.name, sh.percent))
		end
		if row.rarity then
			for _, s in ipairs(Boxes.skins(box, row.rarity.id)) do
				table.insert(names, s.name)
			end
		end
		local detail = if row.grade then table.concat(names, ", ") else "A " .. row.rarity.name .. " skin (" .. table.concat(names, ", ") .. ") on any shape, by the usual shape odds"
		oddsLine(panel, i, (if row.grade then row.grade.name .. " shape" else row.rarity.name .. " skin"), row.percent, rgb(look.colour), detail)
	end
	local skins = {}
	for _, row in ipairs(Boxes.odds(box)) do
		table.insert(skins, string.format("%s %.0f%%", row.rarity.name, row.percent))
	end
	UiKit.label({ LayoutOrder = 99, Text = "A shape tier's skin: " .. table.concat(skins, "  ·  ") .. ". A needle you already have still counts: keep it or trade it.", TextWrapped = true, Size = UDim2.new(1, 0, 0, 40), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UiKit.colors.soft, Parent = panel }, 15)
end

-- What's inside: each rarity's chance, and the skins it can be.
local function contents(order, box)
	local panel = UiKit.make("Frame", { LayoutOrder = order, Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = UiKit.colors.card, Parent = body }, {
		UiKit.corner(12), UiKit.pad(12), UiKit.make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	UiKit.label({ Text = "Inside the " .. box.name .. " (exact odds)", Font = UiKit.bold, Size = UDim2.new(1, 0, 0, 26), TextXAlignment = Enum.TextXAlignment.Left, Parent = panel }, 22)
	if box.tiers then
		return tiered(panel, box)
	end
	for i, row in ipairs(Boxes.odds(box)) do
		local names = {}
		for _, s in ipairs(Boxes.skins(box, row.rarity.id)) do
			table.insert(names, s.name)
		end
		local line = UiKit.make("Frame", { LayoutOrder = i, Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, Parent = panel })
		UiKit.label({ Text = string.format("%s  %.1f%%", row.rarity.name, row.percent), Font = UiKit.bold, TextColor3 = rgb(row.rarity.colour), Size = UDim2.new(0, 200, 0, 22), TextXAlignment = Enum.TextXAlignment.Left, Parent = line }, 18)
		local _, fill = UiKit.bar(line, { Size = UDim2.new(1, -210, 0, 8), Position = UDim2.fromOffset(210, 8) }, rgb(row.rarity.colour))
		fill.Size = UDim2.fromScale(math.max(row.percent / 100, 0.01), 1)
		UiKit.label({ Text = table.concat(names, ", "), Size = UDim2.new(1, 0, 0, 18), Position = UDim2.fromOffset(0, 24), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UiKit.colors.soft, Parent = line }, 14)
	end
	local shapes = {}
	for _, row in ipairs(Needles.gradeOdds()) do -- the shape's grade: the same in every box
		table.insert(shapes, string.format("%s %.1f%%", row.grade.name, row.percent))
	end
	UiKit.label({ LayoutOrder = 99, Text = "Shape: " .. table.concat(shapes, "  ·  ") .. " (Classic needles, or the Firework, Jackhammer, Swordfish and Shooting Star). A needle you already have still counts: keep it or trade it.", Size = UDim2.new(1, 0, 0, 40), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UiKit.colors.soft, Parent = panel }, 15)
end

function BoxScreen.refresh()
	if not win or not win.Visible then
		return
	end
	clear()
	local info = Remotes.Box:InvokeServer("info") or {}
	if not info.allowed then
		UiKit.label({ Text = "Boxes aren't available where you are. Every needle can still be found in rounds!", Size = UDim2.new(1, -8, 0, 60), Parent = body }, 22)
		return
	end
	local left = info.pityAt - info.pity
	UiKit.label({ LayoutOrder = 1, Text = "Rare or better guaranteed within " .. left .. (if left == 1 then " open" else " opens") .. ".  You have ● " .. Rules.commas(info.coins), Size = UDim2.new(1, -8, 0, 26), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UiKit.colors.gold, Parent = body }, 20)
	local row = UiKit.make("Frame", { LayoutOrder = 2, Size = UDim2.new(1, -8, 0, 252), BackgroundTransparency = 1, Parent = body }, {
		UiKit.make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	for i, box in ipairs(Config.Boxes.list) do
		local colour = rgb(box.colour)
		local c = UiKit.make("Frame", { LayoutOrder = i, Size = UDim2.new(1 / #Config.Boxes.list, -8, 1, 0), BackgroundColor3 = UiKit.colors.card, Parent = row }, { UiKit.corner(14), UiKit.stroke(colour, 2) })
		local crate = UiKit.make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 12), Size = UDim2.fromOffset(96, 72), BackgroundColor3 = colour, Parent = c }, { UiKit.corner(8), UiKit.stroke(Color3.fromRGB(90, 62, 36), 3) })
		UiKit.make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 22), Size = UDim2.new(1, 8, 0, 8), BackgroundColor3 = Color3.fromRGB(90, 62, 36), Parent = crate }) -- the lid's band
		UiKit.label({ Text = box.name, Font = UiKit.bold, Size = UDim2.new(1, -12, 0, 28), Position = UDim2.fromOffset(6, 92), Parent = c }, 22)
		local coinsButton = UiKit.button("● " .. Rules.commas(box.coins), if info.coins >= box.coins then UiKit.colors.green else UiKit.colors.line, { Position = UDim2.new(0, 10, 0, 128), Size = UDim2.new(1, -20, 0, 40), Parent = c })
		coinsButton.Activated:Connect(function()
			open(box)
		end)
		local keys = (info.keys or {})[box.id] or 0 -- keys from chests in rounds
		local keyButton = if not hasKey[box.id] then nil else UiKit.button("🗝 Use a key (" .. keys .. ")", if keys > 0 then colour else UiKit.colors.line, { Position = UDim2.new(0, 10, 0, 172), Size = UDim2.new(1, -20, 0, 32), Parent = c })
		if keyButton then
			keyButton.Activated:Connect(function()
				if keys > 0 then
					open(box, true)
				else
					Hud.toast("No " .. box.name .. " keys yet: chests in rounds hold them!", "bad")
				end
			end)
		end
		local productId = box.product and Config.Products[box.product] or 0
		if productId ~= 0 then
			local r = UiKit.button("R$", UiKit.colors.blue, { Position = UDim2.new(0, 10, 0, 210), Size = UDim2.new(1, -20, 0, 32), Parent = c })
			robuxPrice(productId, r)
			r.Activated:Connect(function()
				MarketplaceService:PromptProductPurchase(player, productId)
			end)
		end
	end
	for i, box in ipairs(Config.Boxes.list) do -- every box's odds, always on show below
		contents(2 + i, box)
	end
end

function BoxScreen.mount(gui)
	win, body = UiKit.window(gui, "Boxes", 820, 580)
	Remotes.BoxResult.OnClientEvent:Connect(function(result) -- a box opened with Robux
		win.Visible = true
		BoxReel.play(win, result, BoxScreen.refresh, BoxScreen.refresh)
	end)
	return { Boxes = win }, { Boxes = BoxScreen.refresh }
end

return BoxScreen

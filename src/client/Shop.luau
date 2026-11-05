-- The Shop window: tabs for Tools, Bags, Machines, Perks (coins) and Robux.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))(Config)
local Format = require(Shared:WaitForChild("Format"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Ui = require(script.Parent.Ui)

local player = Players.LocalPlayer

local ROBUX = {
	{ kind = "product", key = "SpeedBoost", title = "2x Speed (1 hour)", text = "Every search takes twice the straws." },
	{ kind = "product", key = "CoinBoost", title = "2x Coins (1 hour)", text = "The merchant pays double." },
	{ kind = "product", key = "LuckyCharm", title = "Lucky Charm (1 hour)", text = "5x the chance of a lucky find." },
	{ kind = "product", key = "StrawBlast", title = "Straw Blast", text = "Search 100,000 straws at once." },
	{ kind = "product", key = "MerchantWhistle", title = "Merchant's Whistle x10", text = "Sell your bag anywhere, ten times." },
	{ kind = "pass", key = "AutoSell", title = "Auto Sell", text = "Your bag sells itself when it fills up." },
	{ kind = "pass", key = "DoubleMachines", title = "Double Machines", text = "Every machine works twice as fast." },
	{ kind = "pass", key = "VIP", title = "VIP", text = "+25% coins, and machines keep working for an hour after you leave." },
}

local Shop = {}

local function ask(remote, ...)
	local ok, success, message = pcall(remote.InvokeServer, remote, ...)
	if not ok then
		return false, "The farm didn't answer. Try again."
	end
	return success, message
end

-- One line in the shop: a name, a description and a button.
local function row(parent, order, name, text, colour)
	local frame = Ui.make("Frame", { LayoutOrder = order, Size = UDim2.new(1, 0, 0, 66), BackgroundColor3 = colour or Ui.colors.paper, Parent = parent }, { Ui.corner(10) })
	Ui.label({ Text = name, Size = UDim2.new(0.6, -12, 0, 30), Position = UDim2.fromOffset(12, 5), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Ui.colors.ink, TextStrokeTransparency = 1, Parent = frame }, 24)
	local sub = Ui.label({ Text = text, Size = UDim2.new(0.6, -12, 0, 24), Position = UDim2.fromOffset(12, 37), Font = Ui.body, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Ui.colors.grey, TextStrokeTransparency = 1, Parent = frame }, 15)
	local button = Ui.button("", Ui.colors.green, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0.37, 0, 0, 48), Parent = frame })
	return button, sub
end

local function priceButton(button, price, owned, next_)
	local coins = player:GetAttribute("Coins") or 0
	if owned then
		button.Text, button.BackgroundColor3 = "OWNED", Ui.colors.grey
	elseif not next_ then
		button.Text, button.BackgroundColor3 = "LOCKED", Ui.colors.grey
	else
		button.Text = "BUY " .. Format.short(price)
		button.BackgroundColor3 = if coins >= price then Ui.colors.green else Ui.colors.red
	end
end

function Shop.mount(gui, notify)
	local frame, body = Ui.window(gui, "Shop")
	frame.Size = UDim2.fromOffset(600, 520)
	local tabs = Ui.make("Frame", { Size = UDim2.new(1, -24, 0, 40), Position = UDim2.fromOffset(12, 64), BackgroundTransparency = 1, Parent = frame }, { Ui.make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })
	body.Position = UDim2.fromOffset(12, 110)
	body.Size = UDim2.new(1, -24, 1, -118)
	local pages, refreshers, buttons = {}, {}, {}

	local function buy(kind, index)
		local ok, message = ask(Remotes.Buy, kind, index)
		notify.toast(message, ok and Ui.colors.green or Ui.colors.red)
		Shop.refresh()
	end

	local function page(name, colour, build)
		local list = Ui.make("Frame", { Name = name, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false, Parent = body }, { Ui.make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })
		pages[name] = list
		refreshers[name] = build(list)
		local tab = Ui.button(name, colour, { LayoutOrder = #buttons + 1, Size = UDim2.new(0.19, 0, 1, 0), Parent = tabs })
		table.insert(buttons, tab)
		tab.Activated:Connect(function()
			for key, p in pairs(pages) do
				p.Visible = key == name
			end
			Shop.refresh()
		end)
	end

	page("Tools", Ui.colors.green, function(list)
		local rows = {}
		for level, tool in ipairs(Config.Tools) do
			rows[level] = row(list, level, tool.name, tool.power .. " straws a search")
			rows[level].Activated:Connect(function()
				buy("tool", level)
			end)
		end
		return function()
			local owned = player:GetAttribute("Tool") or 1
			for level, button in ipairs(rows) do
				priceButton(button, Config.Tools[level].price, level <= owned, level == owned + 1)
			end
		end
	end)

	page("Bags", Ui.colors.blue, function(list)
		local rows = {}
		for level, bag in ipairs(Config.Bags) do
			rows[level] = row(list, level, bag.name, "holds " .. Format.commas(bag.size) .. " straws")
			rows[level].Activated:Connect(function()
				buy("bag", level)
			end)
		end
		return function()
			local owned = player:GetAttribute("Bag") or 1
			for level, button in ipairs(rows) do
				priceButton(button, Config.Bags[level].price, level <= owned, level == owned + 1)
			end
		end
	end)

	page("Machines", Ui.colors.wood, function(list)
		local rows, subs = {}, {}
		for i, m in ipairs(Config.Machines) do
			rows[i], subs[i] = row(list, i, m.name, "")
			rows[i].Activated:Connect(function()
				buy("machine", i)
			end)
		end
		return function()
			for i, m in ipairs(Config.Machines) do
				local owned = player:GetAttribute("Machine_" .. i) or 0
				subs[i].Text = "+" .. m.rate .. " straws a second each. You own " .. owned .. " of " .. m.max .. "."
				priceButton(rows[i], Economy.machinePrice(i, owned), owned >= m.max, owned < m.max)
				if owned >= m.max then
					rows[i].Text = "MAXED"
				end
			end
		end
	end)

	page("Perks", Ui.colors.purple, function(list)
		local rows, subs = {}, {}
		for i, perk in ipairs(Config.Perks) do
			rows[i], subs[i] = row(list, i, perk.name, perk.text)
			rows[i].Activated:Connect(function()
				buy("perk", i)
			end)
		end
		local note = Ui.paragraph("Perks belong to the tool you hold. A new tool starts with none.", { LayoutOrder = 9, TextColor3 = Ui.colors.grey, Parent = list })
		return function()
			local d = { tool = player:GetAttribute("Tool") or 1, perks = {} }
			for _, perk in ipairs(Config.Perks) do
				d.perks[perk.id] = player:GetAttribute("Perk_" .. perk.id) or 0
			end
			for i, perk in ipairs(Config.Perks) do
				local level = d.perks[perk.id]
				subs[i].Text = perk.text .. ". Level " .. level .. "/" .. perk.levels .. " on your " .. Economy.tool(d.tool).name .. "."
				priceButton(rows[i], Economy.perkPrice(d, i), level >= perk.levels, level < perk.levels)
				if level >= perk.levels then
					rows[i].Text = "MAXED"
				end
			end
			note.Visible = true
		end
	end)

	page("Robux", Ui.colors.red, function(list)
		local any = false
		for order, item in ipairs(ROBUX) do
			local id = if item.kind == "pass" then Config.GamePasses[item.key] else Config.Products[item.key]
			if id and id ~= 0 then
				any = true
				local button = row(list, order, item.title, item.text, Color3.fromRGB(226, 236, 250))
				button.Text, button.BackgroundColor3 = "ROBUX", Ui.colors.blue
				button.Activated:Connect(function()
					if item.kind == "pass" then
						MarketplaceService:PromptGamePassPurchase(player, id)
					else
						MarketplaceService:PromptProductPurchase(player, id)
					end
				end)
			end
		end
		if not any then
			Ui.paragraph("Robux items appear here once the game is published and the items are created.", { TextColor3 = Ui.colors.grey, Parent = list })
		end
		return function() end
	end)

	pages.Tools.Visible = true

	function Shop.refresh()
		if not frame.Visible then
			return
		end
		for name, p in pairs(pages) do
			if p.Visible then
				refreshers[name]()
			end
		end
	end
	player.AttributeChanged:Connect(Shop.refresh)
	return frame
end

return Shop

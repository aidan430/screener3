-- The Shop and Inventory screens. The Shop sells cosmetics for Haystack Coins (needle skins,
-- trails, found effects) and shows the optional Robux items (shared/Robux) when they're on sale; the Inventory
-- lists what you own to wear. Every buy and equip is asked of the server (Remotes.Shop), which
-- decides.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Cosmetics = require(Shared:WaitForChild("Cosmetics"))
local Robux = require(Shared:WaitForChild("Robux"))
local Rules = require(Shared:WaitForChild("Rules"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UiKit = require(script.Parent.UiKit)
local Hud = require(script.Parent.Hud)
local Effects = require(script.Parent.Effects)

local player = Players.LocalPlayer
local Screens = {}
local shop, shopBody, inv, invBody
local getProfile = function()
	return {}
end

-- An item's Robux price as Roblox has it ("R$ 99"), looked up once; "Buy" until it's known.
local prices = {}
local function priceOf(id, pass, button)
	if prices[id] then
		button.Text = prices[id]
		return
	end
	button.Text = "Buy"
	task.spawn(function()
		local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, id, if pass then Enum.InfoType.GamePass else Enum.InfoType.Product)
		if ok and info and info.PriceInRobux then
			prices[id] = "R$ " .. info.PriceInRobux
			if button.Parent then
				button.Text = prices[id]
			end
		end
	end)
end

local function rgb(c)
	return Color3.fromRGB(c[1], c[2], c[3])
end

-- A small picture of an item: a needle, a trail streak, a title tag or a burst of colour.
local function swatch(parent, item)
	local box = UiKit.make("Frame", { Size = UDim2.fromOffset(64, 64), BackgroundColor3 = UiKit.colors.panel, Parent = parent }, { UiKit.corner(10) })
	local a, b = rgb(item.colours[1]), rgb(item.colours[2] or item.colours[1])
	if item.kind == "needle" then
		local shaft = UiKit.make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(52, 7), Rotation = -35, BackgroundColor3 = a, Parent = box }, { UiKit.corner(4) })
		UiKit.make("Frame", { Size = UDim2.fromOffset(12, 9), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), BackgroundColor3 = b, Parent = shaft }, { UiKit.corner(4) })
	elseif item.kind == "trail" then
		UiKit.make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(50, 14), BackgroundColor3 = Color3.new(1, 1, 1), Parent = box }, {
			UiKit.corner(7), UiKit.make("UIGradient", { Color = ColorSequence.new(a, b), Transparency = NumberSequence.new(0, 0.8) }),
		})
	else
		UiKit.label({ Text = if item.kind == "title" then "Aa" else "✦", Font = UiKit.bold, Size = UDim2.fromScale(1, 1), TextColor3 = a, Parent = box }, 34)
	end
	return box
end

local function card(parent, order, item, buttonText, buttonColour, onPress)
	local c = UiKit.make("Frame", { LayoutOrder = order, Size = UDim2.new(1, -8, 0, 80), BackgroundColor3 = UiKit.colors.card, Parent = parent }, { UiKit.corner(12) })
	local s = swatch(c, item)
	s.Position = UDim2.fromOffset(8, 8)
	UiKit.label({ Font = UiKit.bold, Text = item.name, Size = UDim2.new(0.5, -80, 0, 30), Position = UDim2.fromOffset(84, 10), TextXAlignment = Enum.TextXAlignment.Left, Parent = c }, 22)
	UiKit.label({ Text = Cosmetics.kindNames[item.kind], Size = UDim2.new(0.5, -80, 0, 22), Position = UDim2.fromOffset(84, 44), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UiKit.colors.soft, Parent = c }, 16)
	local b = UiKit.button(buttonText, buttonColour, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(160, 50), Parent = c })
	b.Activated:Connect(onPress)
end

local function ask(action, id)
	Effects.sound("click")
	local ok, message = Remotes.Shop:InvokeServer(action, id)
	if message then
		Hud.toast(message, if ok then "good" else "bad")
	end
end

local function heading(parent, order, text)
	UiKit.label({ LayoutOrder = order, Font = UiKit.bold, Text = text, Size = UDim2.new(1, 0, 0, 30), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UiKit.colors.gold, Parent = parent }, 22)
end

local function clear(body)
	for _, c in ipairs(body:GetChildren()) do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
end

function Screens.refresh()
	local profile = getProfile()
	local owned, equipped = profile.owned or {}, profile.equipped or {}
	local coins = player:GetAttribute("Coins") or 0
	if shop.Visible then
		clear(shopBody)
		local order = 0
		for _, kind in ipairs(Cosmetics.kinds) do
			local any = false
			for _, item in ipairs(Cosmetics.items) do
				if item.kind == kind and item.price > 0 then
					if not any then
						order += 1
						heading(shopBody, order, Cosmetics.kindNames[kind])
						any = true
					end
					order += 1
					if owned[item.id] then
						card(shopBody, order, item, if equipped[kind] == item.id then "Equipped" else "Equip", UiKit.colors.purple, function()
							ask("equip", item.id)
						end)
					else
						card(shopBody, order, item, "● " .. Rules.commas(item.price), if coins >= item.price then UiKit.colors.green else UiKit.colors.red, function()
							ask("buy", item.id)
						end)
					end
				end
			end
		end
		-- optional Robux items (only those that are on sale), each saying exactly what it gives
		for _, r in ipairs(Robux.items) do
			local id = Robux.id(r)
			local have = r.pass and player:GetAttribute("Pass_" .. r.key) == true
			if id ~= 0 and not (r.once and getProfile().starterBought) then
				if order < 100 then
					order = 100
					heading(shopBody, order, "Support the game (Robux)")
				end
				order += 1
				local c = UiKit.make("Frame", { LayoutOrder = order, Size = UDim2.new(1, -8, 0, 70), BackgroundColor3 = UiKit.colors.card, Parent = shopBody }, { UiKit.corner(12) })
				UiKit.label({ Font = UiKit.bold, Text = r.name .. (if r.pass then "  (pass)" else ""), Size = UDim2.new(1, -160, 0, 28), Position = UDim2.fromOffset(14, 8), TextXAlignment = Enum.TextXAlignment.Left, Parent = c }, 20)
				UiKit.label({ Text = r.text, Size = UDim2.new(1, -160, 0, 24), Position = UDim2.fromOffset(14, 38), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UiKit.colors.soft, Parent = c }, 16)
				local b = UiKit.button("Owned", if have then UiKit.colors.panel else UiKit.colors.green, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(130, 46), Parent = c })
				if not have then
					priceOf(id, r.pass, b)
				end
				b.Activated:Connect(function()
					if have then
						return
					elseif r.pass then
						MarketplaceService:PromptGamePassPurchase(player, id)
					else
						MarketplaceService:PromptProductPurchase(player, id)
					end
				end)
			end
		end
	end
	if inv.Visible then
		clear(invBody)
		local order = 0
		for _, kind in ipairs(Cosmetics.kinds) do
			order += 1
			heading(invBody, order, Cosmetics.kindNames[kind])
			for _, item in ipairs(Cosmetics.items) do
				if item.kind == kind and owned[item.id] then
					order += 1
					local on = equipped[kind] == item.id
					card(invBody, order, item, if on then "Equipped ✓" else "Equip", if on then UiKit.colors.green else UiKit.colors.purple, function()
						ask("equip", item.id)
					end)
				end
			end
		end
	end
end

function Screens.mount(gui, profileGetter)
	getProfile = profileGetter
	shop, shopBody = UiKit.window(gui, "Shop", 620, 500)
	inv, invBody = UiKit.window(gui, "Inventory", 620, 500)
	player:GetAttributeChangedSignal("Coins"):Connect(function()
		if shop.Visible then
			Screens.refresh()
		end
	end)
	return { Shop = shop, Inventory = inv }
end

return Screens

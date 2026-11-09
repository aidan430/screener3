-- The windows: Shop, secret Achievements, Finds & Skins, and the Wheel of Fortune (odds first).
-- Opening one frees the mouse; closing them all locks it again for first person.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))(Config)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Ui = require(script.Parent.Ui)
local Shop = require(script.Parent.Shop)
local Cursor = require(script.Parent.Cursor)
local Juice = require(script.Parent.Juice)
local Dialogue = require(script.Parent.Dialogue)
local StoryData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Story"))

local player = Players.LocalPlayer
local Panels = {}

local function pct(chance)
	local text = string.format("%.4f", chance * 100)
	text = string.gsub(text, "0+$", "")
	text = string.gsub(text, "%.$", "")
	return text .. "%"
end

function Panels.mount(gui, notify, actions)
	local windows, refreshers = {}, {}
	windows.Shop = Shop.mount(gui, notify)
	refreshers.Shop = Shop.refresh

	-- Achievements: secret until earned
	local achievements, achievementsBody = Ui.window(gui, "Achievements", nil, "Achievements")
	windows.Achievements = achievements
	refreshers.Achievements = function()
		task.spawn(function()
			local ok, list = pcall(function()
				return Remotes.GetAchievements:InvokeServer()
			end)
			if not ok or type(list) ~= "table" then
				return
			end
			for _, child in ipairs(achievementsBody:GetChildren()) do
				if child:IsA("GuiObject") then
					child:Destroy()
				end
			end
			local done = 0
			for i, a in ipairs(list) do
				done += if a.done then 1 else 0
				local f = Ui.make("Frame", { LayoutOrder = i, Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = if a.done then Color3.fromRGB(226, 244, 220) else Color3.fromRGB(220, 214, 204), Parent = achievementsBody }, { Ui.corner(10) })
				Ui.label({ Text = if a.done then a.name else "???", Size = UDim2.new(1, -24, 0, 26), Position = UDim2.fromOffset(12, 4), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Ui.colors.ink, TextStrokeTransparency = 1, Parent = f }, 22)
				Ui.label({ Text = if a.done then a.text else "A secret achievement. Keep playing to discover it.", Size = UDim2.new(1, -24, 0, 20), Position = UDim2.fromOffset(12, 31), Font = Ui.body, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Ui.colors.grey, TextStrokeTransparency = 1, Parent = f }, 14)
			end
			Ui.paragraph(done .. " of " .. #list .. " discovered. Some say all ten open a golden door...", { LayoutOrder = 0, Font = Ui.font, TextSize = 20, Parent = achievementsBody })
		end)
	end

	-- Finds & Skins
	local finds, findsBody = Ui.window(gui, "Skins & finds", nil, "Finds")
	windows.Finds = finds
	local found, count = {}, 0
	local HEADER = "Tool skins: win one free on the wheel each day, or buy the one you want. Looks only."
	local skinsHeader = Ui.paragraph(HEADER, { LayoutOrder = 1, TextSize = 16, TextColor3 = Ui.colors.soft, Parent = findsBody })
	local skinButtons, prices = {}, {}
	local function wear(id)
		local ok, _, message = pcall(Remotes.EquipSkin.InvokeServer, Remotes.EquipSkin, id)
		notify.toast(if ok then tostring(message) else "Try again.", Ui.colors.purple)
	end
	local plain = Ui.button("Use the plain tool", Ui.colors.wood, { LayoutOrder = 3, Size = UDim2.new(0, 200, 0, 32), Parent = findsBody })
	plain.Activated:Connect(function()
		wear("")
	end)
	local grid = Ui.make("Frame", { LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = findsBody }, {
		Ui.make("UIGridLayout", { CellSize = UDim2.new(1 / 3, -8, 0, 168), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	for i, prize in ipairs(Config.Wheel) do
		if not prize.reveal then
			-- a card: a swatch in the skin's colours, its name and what it does, and its button
			local card = Ui.card({ LayoutOrder = i, BackgroundColor3 = Ui.colors.white, Parent = grid })
			local swatch = Ui.make("Frame", { Size = UDim2.new(1, -16, 0, 62), Position = UDim2.fromOffset(8, 8), BackgroundColor3 = Color3.new(1, 1, 1), Parent = card }, { Ui.corner(4) })
			Ui.make("UIGradient", { Rotation = 25, Color = ColorSequence.new(Color3.fromRGB(prize.shaft[1], prize.shaft[2], prize.shaft[3]), Color3.fromRGB(prize.head[1], prize.head[2], prize.head[3])), Parent = swatch })
			Ui.label({ Text = prize.name:gsub(" skin", ""), Size = UDim2.new(1, -16, 0, 22), Position = UDim2.fromOffset(8, 76), TextColor3 = Ui.colors.ink, TextStrokeTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Parent = card }, 17)
			Ui.label({ Text = prize.about or "", Font = Ui.body, Size = UDim2.new(1, -16, 0, 16), Position = UDim2.fromOffset(8, 99), TextColor3 = Ui.colors.soft, TextStrokeTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Parent = card }, 13)
			local b = Ui.button(prize.name, Ui.colors.grey, { Size = UDim2.new(1, -16, 0, 34), Position = UDim2.new(0, 8, 1, -42), Parent = card })
			b.Activated:Connect(function()
				if player:GetAttribute("Skin_" .. prize.id) then
					wear(prize.id)
				elseif prize.pass and prize.pass ~= 0 then -- buy it directly: Roblox shows the price before anything is paid
					MarketplaceService:PromptGamePassPurchase(player, prize.pass)
				end
			end)
			skinButtons[prize.id] = b
			if prize.pass and prize.pass ~= 0 then
				task.spawn(function() -- the price as set on the Creator Dashboard
					local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, prize.pass, Enum.InfoType.GamePass)
					prices[prize.id] = ok and info and info.PriceInRobux or nil
				end)
			end
			player:GetAttributeChangedSignal("Skin_" .. prize.id):Connect(function()
				if finds.Visible then
					refreshers.Finds()
				end
			end)
		end
	end
	-- the story so far: every beat you've seen, to play again
	local taleHeader = Ui.paragraph("The story so far", { LayoutOrder = 40, Font = Ui.font, TextSize = 18, Parent = findsBody })
	local tale = Ui.make("Frame", { LayoutOrder = 41, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = findsBody }, { Ui.make("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }) })
	local function refreshTale()
		local seen = {}
		for id in string.gmatch(player:GetAttribute("StorySeen") or "", "[^,]+") do
			seen[id] = true
		end
		for _, child in ipairs(tale:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		for i, beat in ipairs(StoryData.beats) do
			if seen[beat.id] then
				Ui.button(beat.title .. "  ·  play again", Ui.colors.paper, { LayoutOrder = i, TextColor3 = Ui.colors.ink, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 30), Parent = tale }).Activated:Connect(function()
					Dialogue.play(beat.id)
				end)
			end
		end
		taleHeader.Visible = next(seen) ~= nil
	end
	player:GetAttributeChangedSignal("StorySeen"):Connect(refreshTale)
	task.defer(refreshTale)
	local storyHeader = Ui.paragraph("Lucky finds: odd things in the hay, and what they tell you.", { LayoutOrder = 50, Font = Ui.font, TextSize = 20, Parent = findsBody })
	refreshers.Finds = function()
		for _, prize in ipairs(Config.Wheel) do
			local b = skinButtons[prize.id]
			if b then
				local owned = player:GetAttribute("Skin_" .. prize.id) == true
				local forSale = prize.pass ~= nil and prize.pass ~= 0
				b.Parent.Visible = owned or forSale -- the whole card
				local wearing = player:GetAttribute("Skin") == prize.id
				if owned then
					b.Text = if wearing then "Wearing" else "Wear"
					b.BackgroundColor3 = if wearing then Ui.colors.ink else Ui.colors.green
					b.TextColor3 = Ui.colors.white
				else
					local price = prices[prize.id]
					b.Text = "Buy" .. (if price then " · R$ " .. price else " with Robux")
					b.BackgroundColor3 = Ui.colors.hay
					b.TextColor3 = Ui.colors.ink
				end
			end
		end
		skinsHeader.Text = HEADER
		storyHeader.Text = if count == 0 then "Lucky finds: nothing yet. Keep harvesting!" else "Lucky finds:"
	end

	-- Wheel of Fortune: the odds are always on screen before you can spin
	local wheel, wheelBody = Ui.window(gui, "Wheel of Fortune", nil, "Wheel")
	windows.Wheel = wheel
	local restricted = true
	task.spawn(function()
		local ok, info = pcall(function()
			return PolicyService:GetPolicyInfoForPlayerAsync(player)
		end)
		restricted = not ok or info.ArePaidRandomItemsRestricted == true
	end)
	refreshers.Wheel = function()
		for _, child in ipairs(wheelBody:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		Ui.paragraph("Every spin wins a prize. These are the exact odds of each:", { LayoutOrder = 1, Font = Ui.font, TextSize = 20, Parent = wheelBody })
		local odds = Economy.wheelOdds()
		for i, prize in ipairs(Config.Wheel) do
			Ui.paragraph(prize.name .. ":  " .. pct(odds[i]) .. (if prize.reveal then "  (shows the clump the needle is in)" else ""), { LayoutOrder = 1 + i, TextColor3 = if prize.reveal then Ui.colors.red else Ui.colors.ink, Parent = wheelBody })
		end
		Ui.paragraph("A skin you already have pays coins instead.", { LayoutOrder = 50, TextColor3 = Ui.colors.grey, Parent = wheelBody })
		-- one free spin a day; after that, more spins are Robux (never where that's restricted)
		local now = workspace:GetServerTimeNow()
		if (player:GetAttribute("FreeSpinDay") or 0) < math.floor(now / 86400) then
			Ui.button("FREE SPIN (1 a day)", Ui.colors.green, { LayoutOrder = 60, Size = UDim2.new(1, 0, 0, 52), Parent = wheelBody }).Activated:Connect(function()
				Remotes.FreeSpin:FireServer()
			end)
			return
		end
		local left = 86400 - now % 86400
		Ui.paragraph(string.format("Today's free spin is used. The next one comes in %dh %02dm.", left // 3600, left % 3600 // 60), { LayoutOrder = 55, TextColor3 = Ui.colors.grey, Parent = wheelBody })
		local id = Config.Products.WheelSpin
		if restricted then
			Ui.paragraph("Extra spins can't be bought where you live.", { LayoutOrder = 60, TextColor3 = Ui.colors.grey, Parent = wheelBody })
		elseif id and id ~= 0 then
			Ui.button("SPIN AGAIN (Robux)", Ui.colors.blue, { LayoutOrder = 60, Size = UDim2.new(1, 0, 0, 52), Parent = wheelBody }).Activated:Connect(function()
				MarketplaceService:PromptProductPurchase(player, id)
			end)
		end
	end
	player:GetAttributeChangedSignal("FreeSpinDay"):Connect(function()
		if wheel.Visible then
			refreshers.Wheel()
		end
	end)

	-- Menu: on touch screens the HUD's side buttons fold away; the pad's MENU opens these
	local menu, menuBody = Ui.window(gui, "Menu")
	windows.Menu = menu
	Ui.fit(menu, 420, 330)
	local open, whistleButton
	for i, b in ipairs({ { "Achievements", "Achievements", Ui.colors.blue }, { "Skins & finds", "Finds", Ui.colors.purple }, { "Whistle: sell here", "Whistle", Ui.colors.red } }) do
		local button = Ui.button(b[1], b[3], { LayoutOrder = i, Size = UDim2.new(1, 0, 0, 56), Parent = menuBody })
		button.Activated:Connect(function()
			open(b[2])
		end)
		whistleButton = button
	end
	refreshers.Menu = function()
		whistleButton.Visible = (player:GetAttribute("Whistles") or 0) > 0
	end

	local function anyOpen()
		for _, frame in pairs(windows) do
			if frame.Visible then
				return true
			end
		end
		return false
	end

	open = function(name)
		if name == "Build" or name == "Whistle" then
			for _, frame in pairs(windows) do
				frame.Visible = false
			end
			Cursor.need("window", false)
			actions[name]()
			return
		end
		for key, frame in pairs(windows) do
			if key == name then
				frame.Visible = not frame.Visible
				if frame.Visible then
					local scale = frame:FindFirstChildOfClass("UIScale")
					local full = Ui.screenScale() -- not scale.Scale: that may be mid-tween
					if scale then
						scale.Scale = full * 0.9
						Juice.ease(scale, 0.25, { Scale = full }, Enum.EasingStyle.Back)
					end
					refreshers[key]()
				end
			else
				frame.Visible = false
			end
		end
		Cursor.need("window", anyOpen())
	end
	for _, frame in pairs(windows) do
		frame:GetPropertyChangedSignal("Visible"):Connect(function()
			Cursor.need("window", anyOpen())
		end)
	end

	Ui.journalOpen = open -- the journal's tab rail
	local panels = { open = open }
	function panels.addFind(name, story)
		if found[name] then
			return
		end
		found[name], count = true, count + 1
		Ui.paragraph("You found " .. name .. ". " .. story, { LayoutOrder = 50 + count, TextColor3 = Ui.colors.blue, Parent = findsBody })
		refreshers.Finds()
	end
	return panels
end

return Panels

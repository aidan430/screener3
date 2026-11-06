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
	local achievements, achievementsBody = Ui.window(gui, "Achievements")
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
	local finds, findsBody = Ui.window(gui, "Finds")
	windows.Finds = finds
	local found, count = {}, 0
	local skinsHeader = Ui.paragraph("Tool skins (win them on the Wheel of Fortune):", { LayoutOrder = 1, Font = Ui.font, TextSize = 20, Parent = findsBody })
	local skinButtons = {}
	local function wear(id)
		local ok, _, message = pcall(Remotes.EquipSkin.InvokeServer, Remotes.EquipSkin, id)
		notify.toast(if ok then tostring(message) else "Try again.", Ui.colors.purple)
	end
	local plain = Ui.button("Plain tool", Ui.colors.wood, { LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 40), Parent = findsBody })
	plain.Activated:Connect(function()
		wear("")
	end)
	for i, prize in ipairs(Config.Wheel) do
		if not prize.reveal then
			local b = Ui.button(prize.name, Ui.colors.grey, { LayoutOrder = 2 + i, Size = UDim2.new(1, 0, 0, 40), Parent = findsBody })
			b.Activated:Connect(function()
				wear(prize.id)
			end)
			skinButtons[prize.id] = b
		end
	end
	local storyHeader = Ui.paragraph("Lucky finds: odd things in the hay, and what they tell you.", { LayoutOrder = 50, Font = Ui.font, TextSize = 20, Parent = findsBody })
	refreshers.Finds = function()
		for id, b in pairs(skinButtons) do
			local owned = player:GetAttribute("Skin_" .. id) == true
			b.Visible = owned
			b.BackgroundColor3 = if player:GetAttribute("Skin") == id then Ui.colors.green else Ui.colors.purple
		end
		skinsHeader.Text = "Tool skins (win them on the Wheel of Fortune):"
		storyHeader.Text = if count == 0 then "Lucky finds: nothing yet. Keep harvesting!" else "Lucky finds:"
	end

	-- Wheel of Fortune: the odds are always on screen before you can spin
	local wheel, wheelBody = Ui.window(gui, "Wheel of Fortune")
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
		if restricted then
			Ui.paragraph("The Wheel of Fortune isn't available where you live.", { Parent = wheelBody })
			return
		end
		Ui.paragraph("Every spin wins a prize. These are the exact odds of each:", { LayoutOrder = 1, Font = Ui.font, TextSize = 20, Parent = wheelBody })
		local odds = Economy.wheelOdds()
		for i, prize in ipairs(Config.Wheel) do
			Ui.paragraph(prize.name .. ":  " .. pct(odds[i]) .. (if prize.reveal then "  (shows the clump the needle is in)" else ""), { LayoutOrder = 1 + i, TextColor3 = if prize.reveal then Ui.colors.red else Ui.colors.ink, Parent = wheelBody })
		end
		Ui.paragraph("A skin you already have pays coins instead.", { LayoutOrder = 50, TextColor3 = Ui.colors.grey, Parent = wheelBody })
		local id = Config.Products.WheelSpin
		if id and id ~= 0 then
			Ui.button("SPIN (Robux)", Ui.colors.blue, { LayoutOrder = 60, Size = UDim2.new(1, 0, 0, 52), Parent = wheelBody }).Activated:Connect(function()
				MarketplaceService:PromptProductPurchase(player, id)
			end)
		else
			Ui.paragraph("Spins open once the game is published and the WheelSpin product is created.", { LayoutOrder = 60, TextColor3 = Ui.colors.grey, Parent = wheelBody })
		end
	end

	-- Menu: on touch screens the HUD's side buttons fold away; the pad's MENU opens these
	local menu, menuBody = Ui.window(gui, "Menu")
	windows.Menu = menu
	Ui.fit(menu, 420, 330)
	local open, whistleButton
	for i, b in ipairs({ { "ACHIEVEMENTS", "Achievements", Ui.colors.blue }, { "FINDS & SKINS", "Finds", Ui.colors.purple }, { "WHISTLE: SELL HERE", "Whistle", Ui.colors.red } }) do
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

-- The Shop window: Tools, Perks, Fitness (stamina, the metal detector), Storage (buckets and
-- silos), Build (stairs, lifts...), Machines, Power, Trucks and Robux.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))(Config)
local Format = require(Shared:WaitForChild("Format"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Ui = require(script.Parent.Ui)
local Juice = require(script.Parent.Juice)

local player = Players.LocalPlayer

local ROBUX = require(script.Parent.RobuxItems) -- every Robux item, with exactly what it gives

local Shop = {}
local frame = nil

local function ask(remote, ...)
	local ok, success, message = pcall(remote.InvokeServer, remote, ...)
	if not ok then
		return false, "The farm didn't answer. Try again."
	end
	return success, message
end

local function row(parent, order, name, text, colour)
	local f = Ui.make("Frame", { LayoutOrder = order, Size = UDim2.new(1, 0, 0, 64), BackgroundColor3 = colour or Ui.colors.white, Parent = parent }, { Ui.corner(6), Ui.stroke() })
	Ui.label({ Text = name, Size = UDim2.new(0.6, -12, 0, 28), Position = UDim2.fromOffset(12, 5), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Ui.colors.ink, TextStrokeTransparency = 1, Parent = f }, 22)
	local sub = Ui.label({ Text = text, Size = UDim2.new(0.6, -12, 0, 24), Position = UDim2.fromOffset(12, 35), Font = Ui.body, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Ui.colors.grey, TextStrokeTransparency = 1, Parent = f }, 14)
	local button = Ui.button("", Ui.colors.green, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0.36, 0, 0, 46), Parent = f })
	return button, sub
end

local function price(button, cost, done, available, doneText)
	if done then
		button.Text, button.BackgroundColor3 = doneText or "Owned", Ui.colors.grey
	elseif not available then
		button.Text, button.BackgroundColor3 = "Locked", Ui.colors.grey
	else
		button.Text = "Buy · " .. Format.short(cost)
		button.BackgroundColor3 = if (player:GetAttribute("Coins") or 0) >= cost then Ui.colors.green else Ui.colors.red
	end
end

function Shop.mount(gui, notify)
	local body
	frame, body = Ui.window(gui, "Shop", nil, "Shop")
	Ui.fit(frame, 640, 540)
	-- tabs share the width with a mouse; on touch screens they stay tappable and scroll sideways
	local rail = frame:GetAttribute("Rail") or 0 -- the journal's tab rail down the left
	local tabs = Ui.make("ScrollingFrame", { Size = UDim2.new(1, -rail - 40, 0, 36), Position = UDim2.fromOffset(rail + 24, 64), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollingDirection = Enum.ScrollingDirection.X, ScrollBarThickness = 0, CanvasSize = UDim2.new(), Parent = frame }, { Ui.make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }) })
	local tabButtons = {}
	Ui.onLayout(function()
		local touch = Ui.touch()
		tabs.AutomaticCanvasSize, tabs.CanvasSize = if touch then Enum.AutomaticSize.X else Enum.AutomaticSize.None, UDim2.new()
		for _, b in ipairs(tabButtons) do
			b.Size = if touch then UDim2.fromOffset(104, 40) else UDim2.new(1 / 9, -4, 1, 0)
		end
	end)
	body.Position, body.Size = UDim2.fromOffset(rail + 24, 110), UDim2.new(1, -rail - 40, 1, -118)
	local pages, refreshers, order = {}, {}, 0
	Shop.refreshers = refreshers

	local function buy(kind, key, button)
		local ok, message = ask(Remotes.Buy, kind, key)
		notify.toast(message, if ok then Ui.colors.green else Ui.colors.red)
		if ok and button then
			local scale = button:FindFirstChildOfClass("UIScale") or Ui.make("UIScale", { Parent = button })
			scale.Scale = 1.15
			Juice.ease(scale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
			Juice.sound("coins", 1.2)
		end
		Shop.refresh()
	end

	local function page(name, colour, build)
		order += 1
		local list = Ui.make("Frame", { Name = name, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false, Parent = body }, { Ui.make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })
		pages[name], refreshers[name] = list, build(list)
		local _ = colour -- quiet tabs: the open one in ink, the rest plain paper
		local tab = Ui.button(name, Ui.colors.paper, { LayoutOrder = order, TextColor3 = Ui.colors.soft, Size = if Ui.touch() then UDim2.fromOffset(104, 40) else UDim2.new(1 / 9, -4, 1, 0), Parent = tabs })
		table.insert(tabButtons, tab)
		tab.Activated:Connect(function()
			for key, p in pairs(pages) do
				p.Visible = key == name
			end
			for _, other in ipairs(tabButtons) do
				other.BackgroundColor3, other.TextColor3 = Ui.colors.paper, Ui.colors.soft
			end
			tab.BackgroundColor3, tab.TextColor3 = Ui.colors.ink, Ui.colors.white
			Shop.refresh()
		end)
	end

	page("Tools", Ui.colors.green, function(list)
		local rows = {}
		for level, tool in ipairs(Config.Tools) do
			rows[level] = row(list, level, tool.name, tool.power .. " a click, carries " .. Format.commas(tool.capacity))
			rows[level].Activated:Connect(function()
				buy("tool", level, rows[level])
			end)
		end
		return function()
			local owned = player:GetAttribute("Tool") or 1
			for level, button in ipairs(rows) do
				price(button, Config.Tools[level].price, level <= owned, level == owned + 1)
			end
		end
	end)

	page("Perks", Ui.colors.purple, function(list)
		local rows, subs = {}, {}
		for i, perk in ipairs(Config.Perks) do
			rows[i], subs[i] = row(list, i, perk.name, perk.text)
			rows[i].Activated:Connect(function()
				buy("perk", i, rows[i])
			end)
		end
		return function()
			local d = { tool = player:GetAttribute("Tool") or 1, perks = {} }
			for _, perk in ipairs(Config.Perks) do
				d.perks[perk.id] = player:GetAttribute("Perk_" .. perk.id) or 0
			end
			for i, perk in ipairs(Config.Perks) do
				local level = d.perks[perk.id]
				subs[i].Text = perk.text .. ". " .. level .. "/" .. perk.levels .. " on this tool."
				price(rows[i], Economy.perkPrice(d, i), level >= perk.levels, true, "All done")
			end
		end
	end)

	-- fitness levels (yours whatever tool you hold) and the metal detector, bought once
	page("Fitness", Color3.fromRGB(70, 150, 140), function(list)
		local rows, subs = {}, {}
		for i, f in ipairs(Config.Fitness) do
			rows[i], subs[i] = row(list, i, f.name, f.text)
			rows[i].Activated:Connect(function()
				buy("fitness", i, rows[i])
			end)
		end
		local detector = row(list, 50, "Metal Detector", "Hold " .. Config.MetalDetector.key .. " (or DETECT) near your heap: it beeps faster the closer the needle is (within " .. Config.MetalDetector.range .. " studs).")
		detector.Activated:Connect(function()
			buy("detector", 1, detector)
		end)
		return function()
			for i, f in ipairs(Config.Fitness) do
				local level = player:GetAttribute("Fitness_" .. f.id) or 0
				subs[i].Text = f.text .. ". " .. level .. "/" .. f.levels .. "."
				price(rows[i], math.floor(f.price * f.growth ^ level), level >= f.levels, true, "All done")
			end
			price(detector, Config.MetalDetector.price, player:GetAttribute("Detector") == true, true)
		end
	end)

	-- buckets (carry more on foot) and silos (hold what your machines harvest)
	page("Storage", Ui.colors.blue, function(list)
		local buckets, rows = {}, {}
		for level = 2, #Config.Buckets do
			local bucket = Config.Buckets[level]
			buckets[level] = row(list, level, bucket.name, "hangs at your hip: carries " .. Format.commas(bucket.capacity) .. " more straws")
			buckets[level].Activated:Connect(function()
				buy("bucket", level, buckets[level])
			end)
		end
		for level, silo in ipairs(Config.Silos) do
			rows[level] = row(list, 100 + level, silo.name, "holds " .. Format.commas(silo.size) .. " straws from your machines")
			rows[level].Activated:Connect(function()
				buy("silo", level, rows[level])
			end)
		end
		return function()
			local bucket = player:GetAttribute("Bucket") or 1
			for level, button in pairs(buckets) do
				price(button, Config.Buckets[level].price, level <= bucket, level == bucket + 1)
			end
			local owned = player:GetAttribute("Silo") or 1
			for level, button in ipairs(rows) do
				price(button, Config.Silos[level].price, level <= owned, level == owned + 1)
			end
		end
	end)

	local function itemPage(name, colour, list_, describe)
		page(name, colour, function(list)
			local rows, subs = {}, {}
			for i, def in ipairs(list_) do
				rows[i], subs[i] = row(list, i, def.name, "")
				rows[i].Activated:Connect(function()
					buy("item", def.id, rows[i])
				end)
			end
			return function()
				for i, def in ipairs(list_) do
					local own, inv = player:GetAttribute("Own_" .. def.id) or 0, player:GetAttribute("Inv_" .. def.id) or 0
					subs[i].Text = describe(def) .. "  You have " .. own .. (if def.max then "/" .. def.max else "") .. (if inv > 0 then " (" .. inv .. " to build)" else "")
					price(rows[i], def.price, def.max ~= nil and own >= def.max, true, "All done")
				end
			end
		end)
	end
	itemPage("Build", Ui.colors.wood, Config.Pieces, function(def)
		return def.text
	end)
	-- machines fill your silo; feeders (arms, throwers) put bundles on your belts
	local machines = {}
	for _, machine in ipairs(Config.Machines) do
		if not machine.robux then -- the Hay Tornado comes with its Robux pass, not for coins
			table.insert(machines, machine)
		end
	end
	for _, feeder in ipairs(Config.Feeders) do
		table.insert(machines, feeder)
	end
	itemPage("Machines", Ui.colors.red, machines, function(def)
		if def.amount then
			return Format.commas(def.amount) .. " straws onto a belt every " .. def.every .. " s, uses " .. def.draw .. " power."
		end
		return def.rate .. " straws/s, uses " .. def.draw .. " power."
	end)
	itemPage("Power", Color3.fromRGB(200, 160, 40), Config.Generators, function(def)
		return "Makes " .. def.power .. " power" .. (if def.burner then " while it has hay to burn (feed it bundles)." else ".")
	end)

	-- trucks call at your trader and haul from the basket; belt motors speed up every belt
	page("Logistics", Color3.fromRGB(120, 90, 60), function(list)
		local rows, subs = {}, {}
		for i, truck in ipairs(Config.Trucks) do
			rows[i], subs[i] = row(list, i, truck.name, "")
			rows[i].Activated:Connect(function()
				buy("truck", i, rows[i])
			end)
		end
		local belts = {}
		for level = 2, #Config.BeltSpeeds do
			belts[level] = row(list, 50 + level, "Belt Motors " .. level, "every belt you own runs at " .. Config.BeltSpeeds[level].speed .. " studs a second")
			belts[level].Activated:Connect(function()
				buy("belt", level, belts[level])
			end)
		end
		Ui.paragraph("Your trader sells " .. Config.TraderRate .. " straws a second from the basket by himself. Trucks add to that. Bales count " .. Config.BaleCompaction .. "x.", { LayoutOrder = 99, TextSize = 16, TextColor3 = Ui.colors.grey, Parent = list })
		return function()
			for i, truck in ipairs(Config.Trucks) do
				local own = player:GetAttribute("Truck_" .. truck.id) or 0
				subs[i].Text = "Hauls " .. Format.commas(truck.rate) .. " straws a second. You have " .. own .. "/" .. truck.max .. "."
				price(rows[i], truck.price, own >= truck.max, true, "All done")
			end
			local belt = player:GetAttribute("BeltLevel") or 1
			for level, button in pairs(belts) do
				price(button, Config.BeltSpeeds[level].price, level <= belt, level == belt + 1)
			end
		end
	end)

	page("Robux", Color3.fromRGB(80, 160, 90), function(list)
		local any = false
		for i, item in ipairs(ROBUX) do
			local id = if item.kind == "pass" then Config.GamePasses[item.key] else Config.Products[item.key]
			if id and id ~= 0 then
				any = true
				local button = row(list, i, item.title, item.text, Color3.fromRGB(226, 236, 250))
				button.Text, button.BackgroundColor3 = "Robux", Ui.colors.blue
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
	tabButtons[1].BackgroundColor3, tabButtons[1].TextColor3 = Ui.colors.ink, Ui.colors.white
	player.AttributeChanged:Connect(Shop.refresh)
	return frame
end

function Shop.refresh()
	if not frame or not frame.Visible then
		return
	end
	for _, list in ipairs(frame.Body:GetChildren()) do
		if list:IsA("Frame") and list.Visible and Shop.refreshers then
			Shop.refreshers[list.Name]()
		end
	end
end

return Shop

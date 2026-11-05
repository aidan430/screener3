-- The always-on screen: your haystack progress at the top, your bag, coins and rates on the
-- left, the buttons for the shop and achievements, and the active boosts.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))(Config)
local Format = require(Shared:WaitForChild("Format"))
local Ui = require(script.Parent.Ui)

local player = Players.LocalPlayer

local Hud = {}
Hud.state = { inLoft = false, warmth = nil } -- set by Main.client; never Player attributes

function Hud.mount(gui, open)
	local top = Ui.make("Frame", {
		Name = "Haystack",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 6),
		Size = UDim2.fromOffset(470, 86),
		BackgroundColor3 = Ui.colors.wood,
		Parent = gui,
	}, { Ui.corner(14), Ui.stroke(Ui.colors.woodDark, 3) })
	Ui.autoScale(top)
	local title = Ui.label({ Size = UDim2.new(1, -20, 0, 22), Position = UDim2.fromOffset(10, 4), TextColor3 = Ui.colors.hay, Parent = top }, 20)
	local countLabel = Ui.label({ Size = UDim2.new(1, -20, 0, 24), Position = UDim2.fromOffset(10, 27), Parent = top }, 22)
	local bar = Ui.make("Frame", { Size = UDim2.new(1, -24, 0, 14), Position = UDim2.fromOffset(12, 55), BackgroundColor3 = Ui.colors.woodDark, Parent = top }, { Ui.corner(7) })
	local fill = Ui.make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Ui.colors.hay, Parent = bar }, { Ui.corner(7) })
	local warmth = Ui.label({ Size = UDim2.new(1, -20, 0, 14), Position = UDim2.fromOffset(10, 70), TextColor3 = Ui.colors.cream, Parent = top }, 13)

	local left = Ui.make("Frame", {
		Name = "Left",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.fromOffset(210, 420),
		BackgroundTransparency = 1,
		Parent = gui,
	}, { Ui.make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })
	Ui.autoScale(left)
	local stats = Ui.make("Frame", { LayoutOrder = 1, Size = UDim2.fromOffset(210, 150), BackgroundColor3 = Ui.colors.wood, Parent = left }, { Ui.corner(12), Ui.stroke(Ui.colors.woodDark, 3) })
	local coinsLabel = Ui.label({ Size = UDim2.new(1, -16, 0, 38), Position = UDim2.fromOffset(8, 6), TextColor3 = Ui.colors.hay, Parent = stats }, 34)
	local bagLabel = Ui.label({ Size = UDim2.new(1, -16, 0, 22), Position = UDim2.fromOffset(8, 46), Parent = stats }, 18)
	local bagBar = Ui.make("Frame", { Size = UDim2.new(1, -16, 0, 10), Position = UDim2.fromOffset(8, 70), BackgroundColor3 = Ui.colors.woodDark, Parent = stats }, { Ui.corner(5) })
	local bagFill = Ui.make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Ui.colors.green, Parent = bagBar }, { Ui.corner(5) })
	local powerLabel = Ui.label({ Size = UDim2.new(1, -16, 0, 20), Position = UDim2.fromOffset(8, 84), Parent = stats }, 16)
	local machineLabel = Ui.label({ Size = UDim2.new(1, -16, 0, 20), Position = UDim2.fromOffset(8, 104), Parent = stats }, 16)
	local bonusLabel = Ui.label({ Size = UDim2.new(1, -16, 0, 20), Position = UDim2.fromOffset(8, 124), Parent = stats }, 16)

	local function button(order, text, colour, onClick)
		local b = Ui.button(text, colour, { LayoutOrder = order, Size = UDim2.fromOffset(210, 48), Parent = left })
		b.Activated:Connect(onClick)
		return b
	end
	button(2, "SHOP", Ui.colors.green, function()
		open("Shop")
	end)
	local achievementsButton = button(3, "ACHIEVEMENTS", Ui.colors.blue, function()
		open("Achievements")
	end)
	button(4, "FINDS", Ui.colors.purple, function()
		open("Finds")
	end)
	local boosts = Ui.label({ LayoutOrder = 5, Size = UDim2.fromOffset(210, 60), TextColor3 = Ui.colors.hay, TextYAlignment = Enum.TextYAlignment.Top, Parent = left }, 15)

	local function refresh()
		local searched, total = player:GetAttribute("Searched") or 0, Config.TotalStraws
		local inLoft = Hud.state.inLoft
		if inLoft then
			searched, total = player:GetAttribute("LoftSearched") or 0, Config.Loft.straws
			title.Text = "THE GOLDEN LOFT: " .. (player:GetAttribute("GoldenNeedles") or 0) .. " golden needle(s) found"
		else
			title.Text = "YOUR HAYSTACK: " .. (player:GetAttribute("Needles") or 0) .. " needle(s) found"
		end
		countLabel.Text = Format.commas(total - searched) .. " straws left. 1 needle."
		fill.Size = UDim2.fromScale(math.clamp(searched / total, 0, 1), 1)
		local w = Hud.state.warmth
		warmth.Text = if (player:GetAttribute("Tool") or 1) >= Config.DetectorLevel and w then
			"Needle Detector: " .. (if w >= 0.99 then "IT'S IN THE NEXT HANDFUL!" elseif w > 0.7 then "HOT" elseif w > 0.3 then "warm" else "cold")
		else ""
		coinsLabel.Text = Format.short(player:GetAttribute("Coins") or 0) .. " coins"
		local size = Economy.bag(player:GetAttribute("Bag") or 1).size
		local carried = (player:GetAttribute("BagStraw") or 0) + (player:GetAttribute("BagGolden") or 0)
		bagLabel.Text = "Bag: " .. Format.commas(carried) .. " / " .. Format.commas(size) .. (if carried >= size then " FULL!" else "")
		bagFill.Size = UDim2.fromScale(math.clamp(carried / size, 0, 1), 1)
		bagFill.BackgroundColor3 = if carried >= size then Ui.colors.red else Ui.colors.green
		powerLabel.Text = (player:GetAttribute("Power") or 1) .. " straws a search"
		machineLabel.Text = "Machines: " .. string.format("%.2g", player:GetAttribute("MachineRate") or 0) .. " a second"
		bonusLabel.Text = "Coin bonus: x" .. string.format("%.2f", player:GetAttribute("Multiplier") or 1)
		achievementsButton.Text = "ACHIEVEMENTS " .. (player:GetAttribute("Achievements") or 0) .. "/" .. #Config.Achievements
		local lines, now = {}, os.time()
		for name, label in pairs({ SpeedBoost = "2x speed", CoinBoost = "2x coins", LuckyCharm = "Lucky charm" }) do
			local until_ = player:GetAttribute("Boost_" .. name) or 0
			if until_ > now then
				table.insert(lines, label .. ": " .. math.ceil((until_ - now) / 60) .. " min left")
			end
		end
		local whistles = player:GetAttribute("Whistles") or 0
		if whistles > 0 then
			table.insert(lines, "Merchant's Whistles: " .. whistles)
		end
		boosts.Text = table.concat(lines, "\n")
	end

	player.AttributeChanged:Connect(refresh)
	task.spawn(function()
		while true do
			refresh()
			task.wait(5) -- the boost timers count down
		end
	end)
	Hud.refresh = refresh
	return { refresh = refresh }
end

return Hud

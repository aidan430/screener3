-- The always-on screen: a crosshair, your pile's progress at the top, and on the left your
-- coins (they count up smoothly), what you carry, your silo, power and the menu buttons.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))(Config)
local Format = require(Shared:WaitForChild("Format"))
local Ui = require(script.Parent.Ui)
local Juice = require(script.Parent.Juice)

local player = Players.LocalPlayer

local Hud = {}
Hud.state = { inLoft = false, warmth = nil, targeting = false }

local function bar(parent, y, colour)
	local back = Ui.make("Frame", { Size = UDim2.new(1, -16, 0, 10), Position = UDim2.fromOffset(8, y), BackgroundColor3 = Ui.colors.woodDark, Parent = parent }, { Ui.corner(5) })
	return Ui.make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = colour, Parent = back }, { Ui.corner(5) })
end

local function fillTo(fill, share)
	Juice.ease(fill, 0.25, { Size = UDim2.fromScale(math.clamp(share, 0, 1), 1) })
end

function Hud.mount(gui, open)
	local crosshair = Ui.make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = Ui.colors.white, BackgroundTransparency = 0.2, Parent = gui }, { Ui.corner(3), Ui.stroke(Ui.colors.woodDark, 1) })

	local top = Ui.make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.fromOffset(470, 84), BackgroundColor3 = Ui.colors.wood, BackgroundTransparency = 0.1, Parent = gui }, { Ui.corner(14), Ui.stroke(Ui.colors.woodDark, 3) })
	Ui.autoScale(top)
	local title = Ui.label({ Size = UDim2.new(1, -20, 0, 22), Position = UDim2.fromOffset(10, 4), TextColor3 = Ui.colors.hay, Parent = top }, 20)
	local countLabel = Ui.label({ Size = UDim2.new(1, -20, 0, 22), Position = UDim2.fromOffset(10, 27), Parent = top }, 20)
	local pileFill = bar(top, 54, Ui.colors.hay)
	local warmth = Ui.label({ Size = UDim2.new(1, -20, 0, 14), Position = UDim2.fromOffset(10, 67), TextColor3 = Ui.colors.cream, Parent = top }, 13)

	local left = Ui.make("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(220, 470), BackgroundTransparency = 1, Parent = gui }, { Ui.make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })
	Ui.autoScale(left)
	local stats = Ui.make("Frame", { LayoutOrder = 1, Size = UDim2.fromOffset(220, 176), BackgroundColor3 = Ui.colors.wood, BackgroundTransparency = 0.1, Parent = left }, { Ui.corner(12), Ui.stroke(Ui.colors.woodDark, 3) })
	local coinsLabel = Ui.label({ Size = UDim2.new(1, -16, 0, 36), Position = UDim2.fromOffset(8, 4), TextColor3 = Ui.colors.hay, Parent = stats }, 32)
	local carryLabel = Ui.label({ Size = UDim2.new(1, -16, 0, 18), Position = UDim2.fromOffset(8, 42), Parent = stats }, 16)
	local carryFill = bar(stats, 62, Ui.colors.green)
	local siloLabel = Ui.label({ Size = UDim2.new(1, -16, 0, 18), Position = UDim2.fromOffset(8, 76), Parent = stats }, 16)
	local siloFill = bar(stats, 96, Ui.colors.blue)
	local powerLabel = Ui.label({ Size = UDim2.new(1, -16, 0, 18), Position = UDim2.fromOffset(8, 110), Parent = stats }, 15)
	local rateLabel = Ui.label({ Size = UDim2.new(1, -16, 0, 18), Position = UDim2.fromOffset(8, 130), Parent = stats }, 15)
	local bonusLabel = Ui.label({ Size = UDim2.new(1, -16, 0, 18), Position = UDim2.fromOffset(8, 150), Parent = stats }, 15)
	local coinValue = Instance.new("NumberValue")

	local function button(order, text, colour, onClick)
		local b = Ui.button(text, colour, { LayoutOrder = order, Size = UDim2.fromOffset(220, 40), Parent = left })
		b.Activated:Connect(onClick)
		return b
	end
	button(2, "SHOP  (Q)", Ui.colors.green, function()
		open("Shop")
	end)
	button(3, "BUILD  (B)", Ui.colors.wood, function()
		open("Build")
	end)
	local achievementsButton = button(4, "ACHIEVEMENTS", Ui.colors.blue, function()
		open("Achievements")
	end)
	button(5, "FINDS & SKINS", Ui.colors.purple, function()
		open("Finds")
	end)
	local whistle = button(6, "WHISTLE: SELL HERE", Ui.colors.red, function()
		open("Whistle")
	end)
	local boosts = Ui.label({ LayoutOrder = 7, Size = UDim2.fromOffset(220, 50), TextColor3 = Ui.colors.hay, TextYAlignment = Enum.TextYAlignment.Top, Parent = left }, 14)
	Ui.label({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -4), Size = UDim2.fromOffset(560, 18), Text = "M: mouse & menus   Q: shop   B: build   E: use   " .. Config.DropKey .. ": drop hay   " .. Config.HomeKey .. ": home", TextTransparency = 0.3, Parent = gui }, 15)

	local function refresh()
		local needles = player:GetAttribute("Needles") or 0
		if Hud.state.inLoft then
			local searched = player:GetAttribute("LoftSearched") or 0
			title.Text = "THE GOLDEN LOFT: " .. (player:GetAttribute("GoldenNeedles") or 0) .. " golden needle(s) found"
			countLabel.Text = Format.commas(Config.Loft.straws - searched) .. " golden straws left. 1 golden needle."
			fillTo(pileFill, 1 - searched / Config.Loft.straws)
		else
			local clumps = player:GetAttribute("ClumpsLeft") or Config.Clumps
			title.Text = "YOUR PILE: " .. needles .. " needle(s) found"
			countLabel.Text = Format.commas(clumps) .. " of " .. Format.commas(Config.Clumps) .. " clumps left. 1 needle inside."
			fillTo(pileFill, clumps / Config.Clumps)
		end
		local w = Hud.state.warmth
		warmth.Text = if (player:GetAttribute("Tool") or 1) >= Config.DetectorLevel and w then "Needle Detector: " .. w else ""
		Juice.countTo(coinsLabel, coinValue, player:GetAttribute("Coins") or 0, function(v)
			return Format.short(math.floor(v + 0.5)) .. " coins"
		end)
		local carried, capacity = player:GetAttribute("Carried") or 0, player:GetAttribute("Capacity") or 1
		carryLabel.Text = "Carrying " .. Format.commas(carried) .. " / " .. Format.commas(capacity) .. (if carried >= capacity then "  FULL!" else "")
		fillTo(carryFill, carried / capacity)
		carryFill.BackgroundColor3 = if carried >= capacity then Ui.colors.red else Ui.colors.green
		local siloSize = Economy.silo(player:GetAttribute("Silo") or 1).size
		local silo = player:GetAttribute("SiloStraw") or 0
		siloLabel.Text = "Silo " .. Format.commas(silo) .. " / " .. Format.commas(siloSize)
		fillTo(siloFill, silo / siloSize)
		local made, draw = player:GetAttribute("PowerMade") or 0, player:GetAttribute("PowerDraw") or 0
		powerLabel.Text = "Power " .. made .. " made / " .. draw .. " used" .. (if draw > made then "  LOW!" else "")
		powerLabel.TextColor3 = if draw > made then Color3.fromRGB(255, 130, 110) else Ui.colors.white
		rateLabel.Text = (player:GetAttribute("Power") or 1) .. " a click, machines " .. string.format("%.1f", player:GetAttribute("MachineRate") or 0) .. "/s"
		-- what waits in your trader's basket, and how fast the trader and your trucks sell it
		local waiting = (player:GetAttribute("BasketStraw") or 0) + (player:GetAttribute("BaledStraw") or 0)
		bonusLabel.Text = "Basket " .. Format.short(waiting) .. ", sells " .. Format.short(player:GetAttribute("HaulRate") or Config.TraderRate) .. "/s"
		rateLabel.Text ..= "  x" .. string.format("%.2f", player:GetAttribute("Multiplier") or 1)
		achievementsButton.Text = "ACHIEVEMENTS " .. (player:GetAttribute("Achievements") or 0) .. "/" .. #Config.Achievements
		whistle.Visible = (player:GetAttribute("Whistles") or 0) > 0
		local lines, now = {}, os.time()
		for name, label in pairs({ SpeedBoost = "2x speed", CoinBoost = "2x coins", LuckyCharm = "Lucky charm" }) do
			local until_ = player:GetAttribute("Boost_" .. name) or 0
			if until_ > now then
				table.insert(lines, label .. ": " .. math.ceil((until_ - now) / 60) .. " min")
			end
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
	task.spawn(function()
		while true do
			crosshair.BackgroundColor3 = if Hud.state.targeting then Ui.colors.hay else Ui.colors.white
			task.wait(0.1)
		end
	end)
	Hud.refresh = refresh
	return { refresh = refresh, coins = coinsLabel, crosshair = crosshair }
end

return Hud

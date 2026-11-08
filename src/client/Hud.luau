-- The always-on screen, in the farm journal style: a ring crosshair; your heap's progress
-- written across the sky at the top; a paper tag at the top left with your coins (they count up
-- smoothly), what you carry, your silo and your farm's numbers; round paper stamps at the bottom
-- left for the journal's pages; and a "?" stamp that shows the keys.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))(Config)
local Format = require(Shared:WaitForChild("Format"))
local Ui = require(script.Parent.Ui)
local Juice = require(script.Parent.Juice)
local Notify = require(script.Parent.Notify)
local CameraView = require(script.Parent.CameraView)
local Farmers = require(script.Parent.Farmers)

local player = Players.LocalPlayer

local Hud = {}
Hud.state = { inLoft = false, warmth = nil, targeting = false }

local function fillTo(fill, share)
	Juice.ease(fill, 0.25, { Size = UDim2.fromScale(math.clamp(share, 0, 1), 1) })
end

-- Small text on paper: soft brown, no shadow.
local function note(parent, y, size, props)
	local defaults = { Font = Ui.body, Size = UDim2.new(1, -28, 0, size + 2), Position = UDim2.fromOffset(14, y), TextColor3 = Ui.colors.soft, TextStrokeTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Parent = parent }
	for k, v in pairs(props or {}) do
		defaults[k] = v
	end
	return Ui.label(defaults, size)
end

function Hud.mount(gui, open)
	local crosshair = Ui.make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1, Parent = gui }, { Ui.corner(7) })
	local ring = Ui.make("UIStroke", { Color = Ui.colors.white, Thickness = 2, Transparency = 0.1, Parent = crosshair })

	-- the heap's progress, written across the sky: no box, a soft shadow and a thin line
	local top = Ui.make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.fromOffset(460, 64), BackgroundTransparency = 1, Parent = gui })
	Ui.autoScale(top)
	local title = Ui.label({ Size = UDim2.new(1, 0, 0, 22), TextColor3 = Ui.colors.white, Parent = top }, 18)
	local _, pileFill = Ui.bar(top, { Size = UDim2.new(0.74, 0, 0, 3), Position = UDim2.new(0.13, 0, 0, 28), BackgroundColor3 = Ui.colors.white, BackgroundTransparency = 0.6 }, Ui.colors.white)
	local warmth = Ui.label({ Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 38), Font = Ui.body, TextColor3 = Ui.colors.white, Parent = top }, 14)

	-- the paper tag, top left
	local tag = Ui.card({ Position = UDim2.fromOffset(16, 0), Size = UDim2.fromOffset(250, 210), Parent = gui })
	Ui.autoScale(tag)
	Ui.make("Frame", { Size = UDim2.fromOffset(28, 28), Position = UDim2.fromOffset(14, 14), BackgroundColor3 = Ui.colors.hay, Parent = tag }, { Ui.corner(14), Ui.make("UIStroke", { Color = Color3.fromRGB(150, 104, 26), Thickness = 1.5 }) })
	local coinsLabel = Ui.label({ Size = UDim2.new(1, -66, 0, 30), Position = UDim2.fromOffset(52, 8), TextColor3 = Ui.colors.ink, TextStrokeTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Parent = tag }, 28)
	local earnLabel = note(tag, 38, 12, { Position = UDim2.fromOffset(52, 38), Size = UDim2.new(1, -66, 0, 14) }) -- coins a minute (client Goals.luau)
	local carryLabel = note(tag, 64, 12)
	local _, carryFill = Ui.bar(tag, { Size = UDim2.new(1, -28, 0, 5), Position = UDim2.fromOffset(14, 82) })
	local siloLabel = note(tag, 94, 12)
	local _, siloFill = Ui.bar(tag, { Size = UDim2.new(1, -28, 0, 5), Position = UDim2.fromOffset(14, 112) }, Ui.colors.blue)
	local powerLabel = note(tag, 126, 12)
	local rateLabel = note(tag, 144, 12)
	local bonusLabel = note(tag, 162, 12)
	local boosts = note(tag, 182, 12, { TextColor3 = Ui.colors.green, Size = UDim2.new(1, -28, 0, 22), TextYAlignment = Enum.TextYAlignment.Top })
	local coinValue = Instance.new("NumberValue")

	-- the stamps, bottom left: the journal's pages
	local stamps = Ui.make("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 16, 1, -16), Size = UDim2.fromOffset(400, 64), BackgroundTransparency = 1, Parent = gui }, {
		Ui.make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	Ui.autoScale(stamps)
	local function stamp(order, word, caption, page)
		local s, label = Ui.stamp(word, caption, { LayoutOrder = order, Parent = stamps })
		s.Activated:Connect(function()
			open(page)
		end)
		return s, label
	end
	local shopButton = stamp(1, "Shop", "Q", "Shop")
	local buildButton = stamp(2, "Build", "B", "Build")
	local achievementsButton, achievementsWord = stamp(3, "0/0", "FEATS", "Achievements")
	local findsButton = stamp(4, "Skins", "& FINDS", "Finds")
	local whistle = stamp(5, "Whistle", "SELL HERE", "Whistle")

	-- "?": the keys, on a paper slip that opens and closes
	local help = Ui.stamp("?", "KEYS", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16), Size = UDim2.fromOffset(48, 48), Parent = gui })
	Ui.autoScale(help)
	local keys = Ui.card({ AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -74), Size = UDim2.fromOffset(250, 150), Visible = false, Parent = gui })
	Ui.autoScale(keys)
	Ui.paragraph(table.concat({ "M  mouse and menus", "Q  shop", "B  build", "E  use", Config.DropKey .. "  drop hay", Config.HomeKey .. "  home", "Shift  sprint" }, "\n"), { Size = UDim2.new(1, -24, 1, -16), Position = UDim2.fromOffset(12, 8), AutomaticSize = Enum.AutomaticSize.None, TextSize = 15, Parent = keys })
	help.Activated:Connect(function()
		keys.Visible = not keys.Visible
	end)

	local function refresh()
		tag.Position = UDim2.fromOffset(16, Ui.topInset() + 10)
		local needles = player:GetAttribute("Needles") or 0
		if Hud.state.inLoft then
			local searched = player:GetAttribute("LoftSearched") or 0
			title.Text = Format.commas(Config.Loft.straws - searched) .. " golden straws left · " .. (player:GetAttribute("GoldenNeedles") or 0) .. " golden needles found"
			fillTo(pileFill, 1 - searched / Config.Loft.straws)
		else
			local clumps = player:GetAttribute("ClumpsLeft") or Config.Clumps
			local done = (1 - clumps / Config.Clumps) * 100 -- two decimals, so every few clumps it visibly moves
			title.Text = string.format("%.2f%% harvested", done) .. " · " .. Format.commas(clumps) .. " clumps left · 1 needle inside" .. (if needles > 0 then " · " .. needles .. " found" else "")
			fillTo(pileFill, clumps / Config.Clumps)
		end
		local w = Hud.state.warmth
		warmth.Text = if (player:GetAttribute("Tool") or 1) >= Config.DetectorLevel and w then "Needle Detector: " .. w else ""
		Juice.countTo(coinsLabel, coinValue, player:GetAttribute("Coins") or 0, function(v)
			return Format.short(math.floor(v + 0.5)) .. " coins"
		end)
		local carried, capacity = player:GetAttribute("Carried") or 0, player:GetAttribute("Capacity") or 1
		carryLabel.Text = "Carrying " .. Format.commas(carried) .. " of " .. Format.commas(capacity) .. (if carried >= capacity then " · full" else "")
		fillTo(carryFill, carried / capacity)
		carryFill.BackgroundColor3 = if carried >= capacity then Ui.colors.red else Ui.colors.hay
		local siloSize = Economy.silo(player:GetAttribute("Silo") or 1).size
		local silo = player:GetAttribute("SiloStraw") or 0
		siloLabel.Text = "Silo " .. Format.commas(silo) .. " of " .. Format.commas(siloSize)
		fillTo(siloFill, silo / siloSize)
		local made, draw = player:GetAttribute("PowerMade") or 0, player:GetAttribute("PowerDraw") or 0
		powerLabel.Text = "Power " .. made .. " made, " .. draw .. " used" .. (if draw > made then " · low" else "")
		powerLabel.TextColor3 = if draw > made then Ui.colors.red else Ui.colors.soft
		rateLabel.Text = (player:GetAttribute("Power") or 1) .. " a click · machines " .. string.format("%.1f", player:GetAttribute("MachineRate") or 0) .. "/s · x" .. string.format("%.2f", player:GetAttribute("Multiplier") or 1)
		-- what waits in your trader's basket, and how fast the trader and your trucks sell it
		local waiting = (player:GetAttribute("BasketStraw") or 0) + (player:GetAttribute("BaledStraw") or 0)
		local haul = player:GetAttribute("HaulRate") or Config.TraderRate
		local backed = waiting > haul * 30 -- more than half a minute of selling waiting: the trader can't keep up
		bonusLabel.Text = "Basket " .. Format.short(waiting) .. " · sells " .. Format.short(haul) .. "/s" .. (if backed then " · piling up" else "")
		bonusLabel.TextColor3 = if backed then Ui.colors.red else Ui.colors.soft
		if backed and os.clock() - (Hud.warned or -1e9) > 600 then -- a gentle hint, at most every 10 minutes
			Hud.warned = os.clock()
			Notify.toast("Your trader sells " .. Format.short(haul) .. " straws a second and your basket is piling up. A Farm Van (Shop > Trucks) sells faster.", Ui.colors.hay)
		end
		achievementsWord.Text = (player:GetAttribute("Achievements") or 0) .. "/" .. #Config.Achievements
		-- touch screens: the stamps and keys fold away (the action pad and its MENU have them),
		-- so nothing sits over the thumbstick
		local touch = Ui.touch()
		for _, b in ipairs({ shopButton, buildButton, achievementsButton, findsButton }) do
			b.Visible = not touch
		end
		help.Visible = not touch
		keys.Visible = keys.Visible and not touch
		whistle.Visible = not touch and (player:GetAttribute("Whistles") or 0) > 0
		local lines, now = {}, os.time()
		for name, label in pairs({ SpeedBoost = "2x speed", CoinBoost = "2x coins", LuckyCharm = "Lucky charm" }) do
			local until_ = player:GetAttribute("Boost_" .. name) or 0
			if until_ > now then
				table.insert(lines, label .. " " .. math.ceil((until_ - now) / 60) .. " min")
			end
		end
		local early = player:GetAttribute("EarlyLeft") or 0
		if early > 0 then
			table.insert(lines, 1, "Beginner's boost x" .. Config.EarlyBoost.factor .. " · " .. Format.short(early) .. " straws left")
		end
		boosts.Text = table.concat(lines, " · ")
		tag.Size = UDim2.fromOffset(250, if #lines > 0 then 210 else 186)
	end

	player.AttributeChanged:Connect(refresh)
	Ui.onLayout(refresh)
	task.spawn(function()
		while true do
			refresh()
			task.wait(5) -- the boost timers count down
		end
	end)
	task.spawn(function()
		while true do
			ring.Color = if Hud.state.targeting then Ui.colors.hay else Ui.colors.white
			task.wait(0.1)
		end
	end)
	Hud.refresh = refresh
	CameraView.start(gui)
	Farmers.start(gui)
	return { refresh = refresh, coins = coinsLabel, earn = earnLabel, crosshair = crosshair }
end

return Hud

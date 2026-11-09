-- Farmer Level on screen (server/Levels): a wide bar at the bottom that fills a little with every
-- lift, LEVEL UP! in big warm letters with what you gained, "x2 XP!" by the crosshair on a Lucky
-- Lift, and the AUTO button (Config.AutoKey): your tool keeps lifting what you aim at, at its own
-- speed, until you're full, out of breath, or press it again. Every move eases; nothing flashes.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Ui = require(script.Parent.Ui)
local Juice = require(script.Parent.Juice)
local Notify = require(script.Parent.Notify)
local Harvest = require(script.Parent.Harvest)

local player = Players.LocalPlayer
local LevelBar = {}
local OUTLINE = Color3.fromRGB(59, 36, 14)
local bar, fill, levelText, xpText, big, sub, luckyText, autoButton
local auto = false

local function pop(label, from)
	local scale = label:FindFirstChildOfClass("UIScale") or Ui.make("UIScale", { Parent = label })
	scale.Scale = from
	Juice.ease(scale, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
end

-- Big outlined words over the world: warm gold with a dark brown edge, readable on hay and sky.
local function shout(props, size)
	local label = Ui.label(props, size)
	label.Font, label.TextColor3, label.TextStrokeTransparency = Ui.bold, Color3.fromRGB(255, 214, 92), 1
	Ui.make("UIStroke", { Color = OUTLINE, Thickness = 3, Parent = label })
	return label
end

local function setFill()
	local xp, need = player:GetAttribute("Xp") or 0, player:GetAttribute("XpNeed") or 1
	levelText.Text = "Level " .. (player:GetAttribute("Level") or 1)
	xpText.Text = Format.commas(xp) .. " / " .. Format.commas(need) .. " XP"
	Juice.ease(fill, 0.2, { Size = UDim2.fromScale(math.clamp(xp / need, 0, 1), 1) })
end

local lastLevel = nil
local function levelChanged()
	local level = player:GetAttribute("Level")
	if level == nil then
		return -- your save hasn't loaded yet; its level arriving isn't a level-up
	end
	if lastLevel and level > lastLevel then
		local gained = level - lastLevel
		big.Text = if level % Config.Levels.bigEvery == 0 then "LEVEL " .. level .. "!" else "LEVEL UP!"
		local more = math.min(Config.Levels.carryMax, Config.Levels.carryPerLevel * (level - 1))
		sub.Text = "Strength " .. (level - 1) .. " (+" .. gained .. ") · you carry " .. string.format("%.1f", more * 100) .. "% more" .. (if more >= Config.Levels.carryMax then " (the most)" else "")
		for _, label in ipairs({ big, sub }) do
			label.TextTransparency = 0
			label:FindFirstChildOfClass("UIStroke").Transparency = 0
		end
		pop(big, 0.4)
		fill.Size = UDim2.fromScale(1, 1) -- the bar tops up, then starts again
		Juice.ease(bar, 0.5, { BackgroundColor3 = Color3.fromRGB(255, 226, 140) }, Enum.EasingStyle.Sine)
		task.delay(0.5, function()
			Juice.ease(bar, 0.6, { BackgroundColor3 = Ui.colors.woodDark }, Enum.EasingStyle.Sine)
		end)
		Juice.sound("cheer", 1.1)
		if level % Config.Levels.bigEvery == 0 then
			Juice.confetti()
		end
		local token = level
		task.delay(1.6, function()
			if (player:GetAttribute("Level") or 1) ~= token then
				return -- a newer level is showing
			end
			for _, label in ipairs({ big, sub }) do
				Juice.ease(label, 0.5, { TextTransparency = 1 })
				Juice.ease(label:FindFirstChildOfClass("UIStroke"), 0.5, { Transparency = 1 })
			end
		end)
	end
	lastLevel = level
	setFill()
end

-- A Lucky Lift: "x2 XP!" springs up beside the crosshair and drifts away.
function LevelBar.lucky()
	luckyText.Position = UDim2.new(0.5, 70, 0.5, -40)
	luckyText.Rotation = math.random(-12, 12)
	luckyText.TextTransparency = 0
	luckyText:FindFirstChildOfClass("UIStroke").Transparency = 0
	pop(luckyText, 0.3)
	Juice.ease(luckyText, 0.9, { Position = UDim2.new(0.5, 80, 0.5, -90), TextTransparency = 1 }, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
	Juice.ease(luckyText:FindFirstChildOfClass("UIStroke"), 0.9, { Transparency = 1 }, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
	Juice.sound("pop", 1.4)
end

local function setAuto(on, why)
	auto = on
	autoButton.Text = if on then "STOP  " .. Config.AutoKey else "AUTO  " .. Config.AutoKey
	autoButton.BackgroundColor3 = if on then Ui.colors.red else Ui.colors.green
	pop(autoButton, 1.15)
	if why then
		Notify.toast(why, Ui.colors.wood)
	end
end

local function autoLoop()
	while true do
		task.wait(Config.SearchCooldown * 0.5)
		if auto then
			local full = (player:GetAttribute("Carried") or 0) >= (player:GetAttribute("Capacity") or 1)
			local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
			if full and not player:GetAttribute("PassAutoSell") then
				setAuto(false, "You're full, so auto stopped. Dump your hay in your trader's basket.")
			elseif not tool then
				setAuto(false, "Hold your tool first (press 1), then turn auto on.")
			else
				Harvest.use(true) -- only lifts if the crosshair is on your hay and the tool is ready
			end
		end
	end
end

function LevelBar.mount(gui)
	local holder = Ui.make("Frame", { Name = "LevelBar", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -14), Size = UDim2.fromOffset(380, 58), BackgroundTransparency = 1, Parent = gui })
	Ui.autoScale(holder)
	bar = Ui.make("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, -96, 0, 24), BackgroundColor3 = Ui.colors.woodDark, BackgroundTransparency = 0.15, Parent = holder }, { Ui.corner(12), Ui.stroke(Ui.colors.cream, 2) })
	fill = Ui.make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Ui.colors.hay, Parent = bar }, { Ui.corner(12) })
	levelText = Ui.label({ Font = Ui.bold, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0.5, 0, 1, 0), TextColor3 = Ui.colors.white, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3, Parent = bar }, 16)
	xpText = Ui.label({ Font = Ui.body, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 0), Size = UDim2.new(0.5, 0, 1, 0), TextColor3 = Ui.colors.white, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 3, Parent = bar }, 14)
	autoButton = Ui.button("AUTO  " .. Config.AutoKey, Ui.colors.green, { AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1), Size = UDim2.fromOffset(86, 30), Parent = holder })
	big = shout({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.26), Size = UDim2.fromOffset(520, 70), TextTransparency = 1, ZIndex = 30, Parent = gui }, 64)
	sub = shout({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.26, 38), Size = UDim2.fromOffset(520, 30), TextTransparency = 1, ZIndex = 30, Parent = gui }, 24)
	luckyText = shout({ Text = "x2 XP!", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(170, 52), TextTransparency = 1, ZIndex = 30, Parent = gui }, 46)
	for _, label in ipairs({ big, sub, luckyText }) do
		label:FindFirstChildOfClass("UIStroke").Transparency = 1
	end
	autoButton.Activated:Connect(function()
		setAuto(not auto)
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or input.KeyCode ~= Enum.KeyCode[Config.AutoKey] or (Harvest.isBuilding and Harvest.isBuilding()) then
			return
		end
		setAuto(not auto)
	end)
	for _, name in ipairs({ "Level", "Xp", "XpNeed" }) do
		player:GetAttributeChangedSignal(name):Connect(if name == "Level" then levelChanged else setFill)
	end
	levelChanged()
	task.spawn(autoLoop)
	ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("SearchFx").OnClientEvent:Connect(function(message)
		if message.kind == "harvest" and message.lucky then
			LevelBar.lucky()
		end
	end)
end

return LevelBar

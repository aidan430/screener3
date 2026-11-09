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
local bar, fill, levelText, xpText, big, sub, luckyText, luckyHolder, autoButton, spinBadge
local openPanel = function(_) end -- opens a journal page (Main passes panels.open)
local auto = false

local function pop(label, from)
	local scale = label:FindFirstChildOfClass("UIScale") or Ui.make("UIScale", { Parent = label })
	scale.Scale = from
	Juice.ease(scale, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
end

-- Big outlined words over the world: warm gold with a dark brown edge, on a soft dark shadow
-- (an oval whose edges fade out, Config.LevelShadow) so gold reads even over golden hay. Returns
-- the words and their holder (move or turn the holder; the shadow goes with it).
local shadows = {}
local function shout(props, size, shadowPad)
	local holder = Ui.make("Frame", { AnchorPoint = props.AnchorPoint, Position = props.Position or UDim2.new(), Size = props.Size, BackgroundTransparency = 1, ZIndex = props.ZIndex, Parent = props.Parent })
	local shadow = Ui.make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, shadowPad.X, 1, shadowPad.Y), Visible = shadowPad.Magnitude > 0, BackgroundColor3 = Color3.fromRGB(28, 18, 8), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = props.ZIndex, Parent = holder }, {
		Ui.make("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
		Ui.make("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.25, Config.LevelShadow), NumberSequenceKeypoint.new(0.75, Config.LevelShadow), NumberSequenceKeypoint.new(1, 1) }) }),
	})
	props.AnchorPoint, props.Position, props.Size, props.Parent = Vector2.zero, UDim2.new(), UDim2.fromScale(1, 1), holder
	local label = Ui.label(props, size)
	label.Font, label.TextColor3, label.TextStrokeTransparency = Ui.bold, Color3.fromRGB(255, 214, 92), 1
	Ui.make("UIStroke", { Color = OUTLINE, Thickness = 3, Parent = label })
	shadows[label] = shadow
	return label, holder
end

-- Shows (at once) or fades (over `seconds`) the words, their outline and their shadow together.
local function reveal(label, on, seconds, style, direction)
	local goal = if on then 0 else 1
	if seconds then
		Juice.ease(label, seconds, { TextTransparency = goal }, style, direction)
		Juice.ease(label:FindFirstChildOfClass("UIStroke"), seconds, { Transparency = goal }, style, direction)
		Juice.ease(shadows[label], seconds, { BackgroundTransparency = goal }, style, direction)
	else
		label.TextTransparency, label:FindFirstChildOfClass("UIStroke").Transparency, shadows[label].BackgroundTransparency = goal, goal, goal
	end
end

-- A solid cream border (Ui.stroke is a faint pencil line, too soft over grass and hay).
local function creamEdge(frame)
	Ui.make("UIStroke", { Color = Ui.colors.cream, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = frame })
end

local holdUntil = 0 -- after a level-up the bar stays full and glowing until then
local function setFill()
	local xp, need = player:GetAttribute("Xp") or 0, player:GetAttribute("XpNeed") or 1
	if os.clock() < holdUntil then
		return -- setFill runs again when the hold ends
	end
	levelText.Text = "Level " .. (player:GetAttribute("Level") or 1)
	xpText.Text = Format.commas(xp) .. " / " .. Format.commas(need) .. " XP"
	levelText.TextColor3, xpText.TextColor3 = Ui.colors.white, Ui.colors.white
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
		local spins = level // Config.Levels.spinEvery - lastLevel // Config.Levels.spinEvery -- free spins this level-up gave
		if spins > 0 then
			sub.Text = "+" .. spins .. " free wheel spin" .. (if spins > 1 then "s" else "") .. "! · Strength " .. (level - 1) .. " (+" .. gained .. ")"
			task.delay(2.2, function() -- once LEVEL UP! has faded, so the note never covers it
				Notify.toast("Your free wheel spin is saved. Click the gold spin badge, or press Q and pick Wheel.", Ui.colors.hay)
			end)
		end
		reveal(big, true)
		reveal(sub, true)
		pop(big, 0.4)
		Juice.ease(fill, 0.15, { Size = UDim2.fromScale(1, 1) }) -- the bar tops up, glows, then starts again
		levelText.Text, xpText.Text = "Level " .. level, "LEVEL UP!"
		levelText.TextColor3, xpText.TextColor3 = Ui.colors.ink, Ui.colors.ink -- dark on the light glow
		holdUntil = os.clock() + 0.6
		task.delay(0.65, setFill)
		-- the full bar glows light gold, then settles (the fill covers the bar, so the fill glows)
		Juice.ease(fill, 0.4, { BackgroundColor3 = Color3.fromRGB(255, 226, 140) }, Enum.EasingStyle.Sine)
		task.delay(0.5, function()
			Juice.ease(fill, 0.6, { BackgroundColor3 = Ui.colors.hay }, Enum.EasingStyle.Sine)
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
			reveal(big, false, 0.5)
			reveal(sub, false, 0.5)
		end)
	end
	lastLevel = level
	setFill()
end

-- A Lucky Lift: "x2 XP!" springs up beside the crosshair and drifts away.
function LevelBar.lucky()
	luckyHolder.Position = UDim2.new(0.5, 70, 0.5, -40)
	luckyHolder.Rotation = math.random(-12, 12)
	reveal(luckyText, true)
	pop(luckyHolder, 0.3)
	Juice.ease(luckyHolder, 0.9, { Position = UDim2.new(0.5, 80, 0.5, -90) }, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
	reveal(luckyText, false, 0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
	Juice.sound("pop", 1.4)
end

-- The spin badge above the level bar: shows while you have saved free spins; click or tap it to
-- open the Wheel of Fortune (its odds come first, as always).
local function setBadge()
	local bank = player:GetAttribute("SpinBank") or 0
	local was = spinBadge.Visible
	spinBadge.Visible = bank > 0
	spinBadge.Text = bank .. " free spin" .. (if bank > 1 then "s" else "")
	if spinBadge.Visible and not was then
		pop(spinBadge, 0.5)
	end
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

function LevelBar.mount(gui, open)
	openPanel = open or openPanel
	local holder = Ui.make("Frame", { Name = "LevelBar", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -14), Size = UDim2.fromOffset(380, 58), BackgroundTransparency = 1, Parent = gui })
	Ui.autoScale(holder)
	bar = Ui.make("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, -96, 0, 24), BackgroundColor3 = Ui.colors.woodDark, BackgroundTransparency = 0.15, Parent = holder }, { Ui.corner(12) })
	creamEdge(bar)
	fill = Ui.make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Ui.colors.hay, Parent = bar }, { Ui.corner(12) })
	levelText = Ui.label({ Font = Ui.bold, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0.5, 0, 1, 0), TextColor3 = Ui.colors.white, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3, Parent = bar }, 16)
	xpText = Ui.label({ Font = Ui.body, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 0), Size = UDim2.new(0.5, 0, 1, 0), TextColor3 = Ui.colors.white, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 3, Parent = bar }, 14)
	autoButton = Ui.button("AUTO  " .. Config.AutoKey, Ui.colors.green, { AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1), Size = UDim2.fromOffset(86, 30), Parent = holder })
	creamEdge(autoButton) -- so the green button stands out against the grass
	spinBadge = Ui.button("1 free spin", Ui.colors.hay, { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, -30), Size = UDim2.fromOffset(112, 24), Visible = false, Parent = holder })
	creamEdge(spinBadge)
	spinBadge.Activated:Connect(function()
		openPanel("Wheel")
	end)
	player:GetAttributeChangedSignal("SpinBank"):Connect(setBadge)
	setBadge()
	big = shout({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.26), Size = UDim2.fromOffset(520, 70), ZIndex = 30, Parent = gui }, 64, Vector2.new(220, 90)) -- one shadow behind both lines
	sub = shout({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.26, 38), Size = UDim2.fromOffset(520, 30), ZIndex = 30, Parent = gui }, 24, Vector2.zero)
	luckyText, luckyHolder = shout({ Text = "x2 XP!", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(170, 52), ZIndex = 30, Parent = gui }, 46, Vector2.new(80, 26))
	for _, label in ipairs({ big, sub, luckyText }) do
		reveal(label, false)
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

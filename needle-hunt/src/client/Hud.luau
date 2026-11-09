-- The always-on screen: your coins and level (with an XP bar) at the top left; the round's
-- banner at the top centre (what's happening, the timer, the map, difficulty and modifiers);
-- the menu buttons down the right; the Hint button during a round; and toasts.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Rules = require(Shared:WaitForChild("Rules"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UiKit = require(script.Parent.UiKit)
local Effects = require(script.Parent.Effects)

local player = Players.LocalPlayer
local Hud = {}
local toasts = nil

local TONES = { good = UiKit.colors.green, bad = UiKit.colors.red, level = UiKit.colors.gold }

function Hud.toast(text, tone)
	if not toasts then
		return
	end
	local card = UiKit.make("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = UiKit.colors.panel, BackgroundTransparency = 0.1, Parent = toasts }, {
		UiKit.corner(10), UiKit.stroke(TONES[tone] or UiKit.colors.line, 2), UiKit.pad(10),
	})
	UiKit.make("TextLabel", { Text = text, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Font = UiKit.font, TextSize = 18, TextWrapped = true, TextColor3 = UiKit.colors.text, TextXAlignment = Enum.TextXAlignment.Left, Parent = card })
	UiKit.pop(card, 0.85)
	task.delay(5, function()
		card:Destroy()
	end)
	local n = 0
	for _, c in ipairs(toasts:GetChildren()) do
		if c:IsA("Frame") then
			n += 1
		end
	end
	if n > 4 then
		for _, c in ipairs(toasts:GetChildren()) do
			if c:IsA("Frame") then
				c:Destroy()
				break
			end
		end
	end
end

function Hud.mount(gui, open)
	-- coins and level, top left
	local chip = UiKit.make("Frame", { Position = UDim2.fromOffset(16, 16), Size = UDim2.fromOffset(250, 84), BackgroundColor3 = UiKit.colors.panel, BackgroundTransparency = 0.15, Parent = gui }, { UiKit.corner(14), UiKit.stroke() })
	UiKit.autoScale(chip)
	local coins = UiKit.label({ Font = UiKit.bold, Size = UDim2.new(1, -24, 0, 30), Position = UDim2.fromOffset(14, 8), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UiKit.colors.gold, Parent = chip }, 26)
	local level = UiKit.label({ Size = UDim2.new(1, -24, 0, 20), Position = UDim2.fromOffset(14, 40), TextXAlignment = Enum.TextXAlignment.Left, Parent = chip }, 18)
	local _, xpFill = UiKit.bar(chip, { Size = UDim2.new(1, -28, 0, 8), Position = UDim2.fromOffset(14, 66) }, UiKit.colors.gold)
	local function stats()
		coins.Text = "● " .. Rules.commas(player:GetAttribute("Coins") or 0) .. " Haystack Coins"
		local xp, need = player:GetAttribute("XP") or 0, player:GetAttribute("XPNeed") or 1
		level.Text = "Level " .. (player:GetAttribute("Level") or 1) .. "  ·  " .. Rules.commas(xp) .. " / " .. Rules.commas(need) .. " XP"
		UiKit.ease(xpFill, 0.3, { Size = UDim2.fromScale(math.clamp(xp / need, 0, 1), 1) })
	end
	player.AttributeChanged:Connect(stats)
	stats()
	-- the round banner, top centre
	local banner = UiKit.make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 14), Size = UDim2.fromOffset(460, 104), BackgroundColor3 = UiKit.colors.panel, BackgroundTransparency = 0.15, Parent = gui }, { UiKit.corner(16), UiKit.stroke() })
	UiKit.autoScale(banner)
	local headline = UiKit.label({ Font = UiKit.bold, Size = UDim2.new(1, -20, 0, 34), Position = UDim2.fromOffset(10, 6), Parent = banner }, 30)
	local timer = UiKit.label({ Font = UiKit.bold, Size = UDim2.new(1, -20, 0, 30), Position = UDim2.fromOffset(10, 40), TextColor3 = UiKit.colors.gold, Parent = banner }, 28)
	local info = UiKit.label({ Size = UDim2.new(1, -20, 0, 22), Position = UDim2.fromOffset(10, 74), TextColor3 = UiKit.colors.soft, Parent = banner }, 18)
	-- the menu, down the right
	local menu = UiKit.make("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(150, 394), BackgroundTransparency = 1, Parent = gui }, {
		UiKit.make("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right }),
	})
	UiKit.autoScale(menu)
	for i, item in ipairs({ { "Collection", Color3.fromRGB(230, 120, 170) }, { "Shop", UiKit.colors.gold }, { "Inventory", UiKit.colors.purple }, { "Quests", UiKit.colors.green }, { "Leaderboard", UiKit.colors.blue }, { "Settings", UiKit.colors.card } }) do
		local b = UiKit.button(item[1], item[2], { LayoutOrder = i, Size = UDim2.fromOffset(150, 54), Parent = menu })
		b.Activated:Connect(function()
			Effects.sound("click")
			open(item[1])
		end)
	end
	-- the hint button, bottom centre, only while you're searching
	local hint = UiKit.button("💡 Hint", UiKit.colors.purple, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -20), Size = UDim2.fromOffset(170, 54), Visible = false, Parent = gui })
	UiKit.autoScale(hint)
	hint.Activated:Connect(function()
		local text, why = Remotes.Hint:InvokeServer()
		Hud.toast(text or why or "No hint.", if text then "good" else "bad")
	end)
	-- toasts, under the banner
	toasts = UiKit.make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 130), Size = UDim2.fromOffset(440, 260), BackgroundTransparency = 1, Parent = gui }, {
		UiKit.make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	UiKit.autoScale(toasts)
	-- keep the banner up to date
	task.spawn(function()
		while true do
			local phase = ReplicatedStorage:GetAttribute("Phase") or "lobby"
			local left = (ReplicatedStorage:GetAttribute("EndsAt") or 0) - workspace:GetServerTimeNow()
			local mods = ReplicatedStorage:GetAttribute("Modifiers") or ""
			local golden = ReplicatedStorage:GetAttribute("Golden")
			local inRound = player.Character and player.Character.PrimaryPart and (player.Character.PrimaryPart.Position - Config.ArenaCentre).Magnitude < 200
			if phase == "lobby" then
				headline.Text, timer.Text = "Next round in", Rules.clock(left)
				info.Text = if #game:GetService("Players"):GetPlayers() == 1 then "Practice round: invite friends to race!" else "Get ready to search!"
			elseif phase == "loading" or phase == "countdown" then
				headline.Text, timer.Text = ReplicatedStorage:GetAttribute("MapName") or "Loading...", if phase == "countdown" then tostring(math.max(1, math.ceil(left))) else "..."
				info.Text = (ReplicatedStorage:GetAttribute("Difficulty") or "") .. (if mods ~= "" then "  ·  " .. mods else "") .. (if golden then "  ·  ✦ GOLDEN NEEDLE ✦" else "")
			elseif phase == "search" then
				local count = ReplicatedStorage:GetAttribute("NeedleCount") or 1
				headline.Text = if count > 1 then "Find both needles!" else "Find the needle!"
				timer.Text = Rules.clock(left)
				timer.TextColor3 = if left < 15 then UiKit.colors.red else UiKit.colors.gold
				info.Text = (ReplicatedStorage:GetAttribute("MapName") or "") .. "  ·  " .. (ReplicatedStorage:GetAttribute("Difficulty") or "") .. (if mods ~= "" then "  ·  " .. mods else "") .. (if golden then "  ·  ✦ GOLDEN ✦" else "")
			else
				headline.Text, timer.Text, info.Text = "Round over", Rules.clock(left), "Back to the lobby soon"
			end
			hint.Visible = phase == "search" and inRound == true
			task.wait(0.2)
		end
	end)
	Remotes.Notify.OnClientEvent:Connect(function(message)
		Hud.toast(message.text, message.tone)
		if message.tone == "level" then
			Effects.sound("found", 1.3)
			Effects.confetti()
		end
	end)
end

return Hud

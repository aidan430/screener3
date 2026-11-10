-- Tag-outs and streaks on your screen (server/Combat decides them; Config.Streak):
--   you tag someone out: a callout at the top (TAGGED OUT!, DOUBLE TAG!, TRIPLE TAG!...), who it
--   was, the coins, and your multiplier once you're on a streak; it eases in and out (no flashing);
--   your streak beside your hearts while it's 2 or more, with its multiplier;
--   you're tagged out: who did it, and the streak you lost (the TAGGED OUT panel is client/CombatFx).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UiKit = require(script.Parent.UiKit)
local Hud = require(script.Parent.Hud)
local Effects = require(script.Parent.Effects)

local player = Players.LocalPlayer
local StreakFx = {}
local S = Config.Streak
local GOLD, HOT = Color3.fromRGB(255, 205, 70), Color3.fromRGB(255, 120, 60)

local function multText(mult)
	return (if mult % 1 == 0 then string.format("x%d", mult) else string.format("x%.1f", mult)) .. " COINS & XP"
end

function StreakFx.start(gui)
	local callout = UiKit.make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 130), Size = UDim2.fromOffset(460, 118), BackgroundColor3 = UiKit.colors.panel, BackgroundTransparency = 0.08, Visible = false, ZIndex = 30, Parent = gui }, { UiKit.corner(16) })
	UiKit.autoScale(callout)
	local edge = UiKit.stroke(GOLD, 3)
	edge.Parent = callout
	local title = UiKit.label({ Text = "", Font = UiKit.bold, Size = UDim2.new(1, -20, 0, 46), Position = UDim2.fromOffset(10, 8), TextColor3 = GOLD, ZIndex = 31, Parent = callout }, 40)
	local line = UiKit.label({ Text = "", Size = UDim2.new(1, -20, 0, 26), Position = UDim2.fromOffset(10, 54), ZIndex = 31, Parent = callout }, 20)
	local badge = UiKit.label({ Text = "", Font = UiKit.bold, Size = UDim2.new(1, -20, 0, 24), Position = UDim2.fromOffset(10, 84), TextColor3 = HOT, ZIndex = 31, Parent = callout }, 20)
	local shownAt = 0

	local chip = UiKit.make("Frame", { Position = UDim2.fromOffset(186, 106), Size = UDim2.fromOffset(190, 36), BackgroundColor3 = UiKit.colors.panel, BackgroundTransparency = 0.15, Visible = false, Parent = gui }, { UiKit.corner(10), UiKit.stroke(HOT, 2) })
	UiKit.autoScale(chip)
	local chipText = UiKit.label({ Text = "", Font = UiKit.bold, Size = UDim2.fromScale(1, 1), TextColor3 = HOT, Parent = chip }, 18)
	local function showChip()
		local streak = player:GetAttribute("Streak") or 0
		chip.Visible = streak >= 2 and player:GetAttribute("InRound") == true
		chipText.Text = string.format("STREAK %d  ·  %s", streak, (multText(math.min(S.max, 1 + S.step * (streak - 1))):gsub(" COINS & XP", "")))
		if chip.Visible then
			UiKit.pop(chip, 0.8)
		end
	end
	player:GetAttributeChangedSignal("Streak"):Connect(showChip)
	player:GetAttributeChangedSignal("InRound"):Connect(showChip)

	Remotes.TagOut.OnClientEvent:Connect(function(m)
		if m.by then -- you were tagged out
			Hud.toast(m.by .. " tagged you out!" .. (if (m.ended or 0) >= 2 then " Your streak of " .. m.ended .. " ended." else ""), "bad")
			return
		end
		local streak = m.streak or 1
		title.Text = S.names[math.min(streak, #S.names)]
		line.Text = "You tagged out " .. (m.target or "a player") .. "   ·   +" .. (m.coins or 0) .. " coins"
		badge.Text = if (m.mult or 1) > 1 then "STREAK " .. streak .. "   ·   " .. multText(m.mult) else ""
		title.TextColor3 = if streak >= 3 then HOT else GOLD
		edge.Color = title.TextColor3
		callout.Size = UDim2.fromOffset(460, if badge.Text ~= "" then 118 else 90)
		callout.Visible, callout.BackgroundTransparency = true, 0.08
		UiKit.pop(callout, 0.7)
		Effects.sound("found", 1 + math.min(streak - 1, 4) * 0.08) -- a little higher each time in a row
		local at = os.clock()
		shownAt = at
		task.delay(2.4, function()
			if shownAt == at then
				callout.Visible = false
			end
		end)
	end)
end

return StreakFx

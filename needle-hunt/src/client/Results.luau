-- The round's big moments on screen: the 3, 2, 1; CHEST OPENED! when you open one (coins, or a
-- key in its box's colour); a note telling everyone what someone else got; and the results
-- (places by chests, tag-outs and coins, and your match XP).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Rules = require(Shared:WaitForChild("Rules"))
local Cosmetics = require(Shared:WaitForChild("Cosmetics"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UiKit = require(script.Parent.UiKit)
local Effects = require(script.Parent.Effects)
local Hud = require(script.Parent.Hud)
local NeedleView = require(script.Parent.NeedleView)

local player = Players.LocalPlayer
local Results = {}
local PLACES = { "1st", "2nd", "3rd" }
local keyColour

local function rgb(c)
	return Color3.fromRGB(c[1], c[2], c[3])
end

-- A key's colour: its box's colour.
keyColour = function(id)
	for _, box in ipairs(Config.Boxes.list) do
		if box.id == id then
			return rgb(box.colour)
		end
	end
	return UiKit.colors.gold
end

local function placeName(n)
	return PLACES[n] or (n .. "th")
end

function Results.mount(gui, getProfile)
	-- the 3, 2, 1
	local count = UiKit.label({ Font = UiKit.bold, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(300, 200), TextColor3 = UiKit.colors.gold, TextStrokeTransparency = 0.4, Visible = false, ZIndex = 30, Parent = gui }, 180)
	-- the NEEDLE FOUND! popup
	local popup = UiKit.make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromOffset(560, 300), BackgroundColor3 = UiKit.colors.panel, BackgroundTransparency = 0.05, Visible = false, ZIndex = 30, Parent = gui }, { UiKit.corner(22), UiKit.stroke(UiKit.colors.gold, 3) })
	UiKit.autoScale(popup)
	local art = UiKit.make("Frame", { Size = UDim2.new(1, 0, 0, 110), BackgroundTransparency = 1, ZIndex = 31, Parent = popup })
	local big = UiKit.label({ Font = UiKit.bold, Text = "NEEDLE FOUND!", Size = UDim2.new(1, -30, 0, 56), Position = UDim2.fromOffset(15, 108), TextColor3 = UiKit.colors.gold, ZIndex = 31, Parent = popup }, 54)
	local kept = UiKit.label({ Font = UiKit.bold, Size = UDim2.new(1, -30, 0, 34), Position = UDim2.fromOffset(15, 166), ZIndex = 31, Parent = popup }, 26)
	local line = UiKit.label({ Size = UDim2.new(1, -30, 0, 40), Position = UDim2.fromOffset(15, 206), ZIndex = 31, Parent = popup }, 22)
	local keep = UiKit.label({ Size = UDim2.new(1, -30, 0, 26), Position = UDim2.fromOffset(15, 252), TextColor3 = UiKit.colors.soft, ZIndex = 31, Parent = popup }, 18)
	-- the results screen
	local results, body = UiKit.window(gui, "Round results", 560, 440)
	results.ZIndex = 25

	-- a chest opened: yours gets the popup; anyone else's, a note
	Remotes.Found.OnClientEvent:Connect(function(m)
		local got = m.got or {}
		local what = if got.oneOfOne then "THE 1 OF 1, the " .. got.name elseif got.key then "a " .. got.name else Rules.commas(got.coins or 0) .. " coins"
		if m.userId ~= player.UserId then
			Hud.toast(m.name .. " opened a " .. (if m.golden then "Golden Chest" else "chest") .. ": " .. what .. "!  (" .. m.left .. " left)", if got.key then "level" else "good")
			return
		end
		local profile = getProfile() or {}
		local effect = Cosmetics.get((profile.equipped or {}).effect or "e_confetti") or Cosmetics.get("e_confetti")
		for _, c in ipairs(art:GetChildren()) do
			c:Destroy()
		end
		if got.oneOfOne then -- the needle itself, turning (it's nearly invisible: look closely)
			NeedleView.make(art, got.type, got.skin, { Size = UDim2.new(1, -40, 1, 0), Position = UDim2.fromOffset(20, 0), ZIndex = 32 }, true)
		else
			local icon = UiKit.label({ Font = UiKit.bold, Text = if got.key then "🗝" else "●", TextColor3 = if got.key then keyColour(got.key) else UiKit.colors.gold, Size = UDim2.new(1, 0, 1, 0), ZIndex = 32, Parent = art }, 96)
			UiKit.pop(icon, 0.4)
		end
		big.Text = if got.oneOfOne then "THE 1 OF 1!" elseif m.golden then "GOLDEN CHEST!" else "CHEST OPENED!"
		kept.Text = if got.oneOfOne then got.name .. ": the only one there is" elseif got.key then got.name .. "!" else "+" .. what
		kept.TextColor3 = if got.oneOfOne then Color3.fromRGB(225, 240, 255) elseif got.key then keyColour(got.key) else UiKit.colors.gold
		line.Text = if got.oneOfOne then "Put it on show to carry it: one throw tags anyone out." elseif got.key then "Open a box with it in the lobby (Boxes)." else "Coins buy trails, titles, effects and boxes."
		keep.Text = m.left .. (if m.left == 1 then " chest left" else " chests left") .. " on this map  ·  XP at the end"
		popup.Visible = true
		UiKit.pop(popup, 0.5)
		Effects.sound("found")
		Effects.burst(m.position + Vector3.new(0, 2, 0), { rgb(effect.colours[1]), rgb(effect.colours[2] or effect.colours[1]) }, if m.golden then 90 else 50)
		if got.key or got.oneOfOne then
			Effects.confetti()
		end
		task.delay(if got.oneOfOne then 8 else 3.5, function()
			popup.Visible = false
		end)
	end)

	Remotes.RoundState.OnClientEvent:Connect(function(state)
		if state.phase == "countdown" then
			count.Visible = true
			for n = Config.Round.loadCountdown, 1, -1 do
				count.Text = tostring(n)
				UiKit.pop(count, 1.6)
				Effects.sound("countdown")
				task.wait(1)
			end
			count.Text = "GO!"
			UiKit.pop(count, 1.6)
			task.delay(0.8, function()
				count.Visible = false
			end)
		elseif state.phase == "results" then
			for _, c in ipairs(body:GetChildren()) do
				if c:IsA("GuiObject") then
					c:Destroy()
				end
			end
			local extra = state.extra or {}
			local rows = extra.rows or {}
			UiKit.label({ LayoutOrder = 0, Text = (extra.map or "") .. (if extra.golden then "  ·  Golden Chest round" else ""), Size = UDim2.new(1, 0, 0, 26), TextColor3 = UiKit.colors.soft, Parent = body }, 20)
			if #rows == 0 then
				UiKit.label({ LayoutOrder = 1, Text = "Nobody opened a chest this time. The hay wins!", Size = UDim2.new(1, 0, 0, 40), Parent = body }, 24)
			end
			for i, r in ipairs(rows) do
				local card = UiKit.make("Frame", { LayoutOrder = i, Size = UDim2.new(1, -8, 0, 52), BackgroundColor3 = if r.userId == player.UserId then UiKit.colors.line else UiKit.colors.card, Parent = body }, { UiKit.corner(10) })
				local medal = if r.place == 1 then UiKit.colors.gold elseif r.place == 2 then Color3.fromRGB(200, 206, 216) elseif r.place == 3 then Color3.fromRGB(205, 140, 90) else UiKit.colors.soft
				UiKit.label({ Font = UiKit.bold, Text = placeName(r.place), Size = UDim2.new(0, 70, 1, 0), TextColor3 = medal, Parent = card }, 24)
				UiKit.label({ Text = r.name, Size = UDim2.new(0.45, 0, 1, 0), Position = UDim2.fromOffset(76, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = card }, 22)
				UiKit.label({ Text = string.format("%d chests  ·  %d tagged out  ·  +%s coins", r.chests or 0, r.elims or 0, Rules.commas(r.coins or 0)), Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.new(0.5, -10, 0, 0), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = UiKit.colors.soft, Parent = card }, 18)
			end
			local mine = (extra.xp or {})[tostring(player.UserId)] -- your match XP and where it came from
			if mine then
				local box = UiKit.make("Frame", { LayoutOrder = 100, Size = UDim2.new(1, -8, 0, 76), BackgroundColor3 = UiKit.colors.card, Parent = body }, { UiKit.corner(10), UiKit.stroke(UiKit.colors.gold, 2) })
				UiKit.label({ Font = UiKit.bold, Text = "MATCH XP  +" .. Rules.commas(mine.total), TextColor3 = UiKit.colors.gold, Size = UDim2.new(1, -20, 0, 30), Position = UDim2.fromOffset(10, 6), TextXAlignment = Enum.TextXAlignment.Left, Parent = box }, 24)
				local parts = {
					(if mine.place then placeName(mine.place) else "Played") .. " +" .. mine.placeXp,
					mine.coins .. " coins +" .. mine.coinXp,
					mine.chests .. (if mine.chests == 1 then " chest +" else " chests +") .. mine.chestXp,
					mine.elims .. " tagged out +" .. mine.elimXp,
				}
				UiKit.label({ Text = table.concat(parts, "   ·   "), TextColor3 = UiKit.colors.soft, Size = UDim2.new(1, -20, 0, 26), Position = UDim2.fromOffset(10, 40), TextXAlignment = Enum.TextXAlignment.Left, Parent = box }, 18)
			end
			results.Visible = true
			UiKit.pop(results, 0.8)
		elseif state.phase == "lobby" then
			results.Visible = false
		end
	end)
end

return Results

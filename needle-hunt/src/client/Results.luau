-- The round's big moments on screen: the 3, 2, 1 before searching; NEEDLE FOUND! when you find it
-- (the needle you get to keep turning in 3D, its rarity and value, your place, time and rewards,
-- your found effect where it was); a note telling everyone what someone found; and the results.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Rules = require(Shared:WaitForChild("Rules"))
local Cosmetics = require(Shared:WaitForChild("Cosmetics"))
local Needles = require(Shared:WaitForChild("Needles"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UiKit = require(script.Parent.UiKit)
local Effects = require(script.Parent.Effects)
local Hud = require(script.Parent.Hud)
local NeedleView = require(script.Parent.NeedleView)

local player = Players.LocalPlayer
local Results = {}
local PLACES = { "1st", "2nd", "3rd" }

local function rgb(c)
	return Color3.fromRGB(c[1], c[2], c[3])
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

	Remotes.Found.OnClientEvent:Connect(function(m)
		local mine = m.userId == player.UserId
		local k = m.kept
		if not mine then
			local what = if k then " found a " .. k.rarity .. " " .. k.name .. "!" else " found it!"
			Hud.toast(m.name .. what .. " (" .. placeName(m.place) .. ")" .. (if m.place == 1 then "  " .. Config.Round.grace .. " seconds left for everyone else!" else ""), "level")
			Effects.sound("whoosh")
			return
		end
		local profile = getProfile() or {}
		local equipped = profile.equipped or {}
		local effect = Cosmetics.get(equipped.effect or "e_confetti") or Cosmetics.get("e_confetti")
		for _, c in ipairs(art:GetChildren()) do
			c:Destroy()
		end
		if k then
			NeedleView.make(art, k.type, k.skin, { Size = UDim2.new(1, -40, 1, 0), Position = UDim2.fromOffset(20, 0), ZIndex = 32 }, true)
			local rarity = Needles.rarity(k.rarityId)
			kept.Text = (if k.new then "NEW!  " else "") .. k.rarity .. " " .. k.name
			kept.TextColor3 = Color3.fromRGB(rarity.colour[1], rarity.colour[2], rarity.colour[3])
			keep.Text = "It's yours to keep: worth " .. Rules.commas(k.value) .. " in your Collection."
		end
		big.Text = if m.golden then "GOLDEN NEEDLE!" else "NEEDLE FOUND!"
		line.Text = placeName(m.place) .. "  ·  " .. string.format("%.1f s", m.seconds) .. "  ·  +" .. Rules.commas(m.coins) .. " coins  ·  XP at the end"
		popup.Visible = true
		UiKit.pop(popup, 0.5)
		Effects.sound("found")
		Effects.flash()
		Effects.burst(m.position, { rgb(effect.colours[1]), rgb(effect.colours[2] or effect.colours[1]) }, if m.golden then 90 else 50)
		Effects.confetti()
		task.delay(4.5, function()
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
			UiKit.label({ LayoutOrder = 0, Text = (extra.map or "") .. (if extra.golden then "  ·  Golden Needle round" else ""), Size = UDim2.new(1, 0, 0, 26), TextColor3 = UiKit.colors.soft, Parent = body }, 20)
			if #rows == 0 then
				UiKit.label({ LayoutOrder = 1, Text = "Nobody found it this time. The hay wins!", Size = UDim2.new(1, 0, 0, 40), Parent = body }, 24)
			end
			for i, r in ipairs(rows) do
				local card = UiKit.make("Frame", { LayoutOrder = i, Size = UDim2.new(1, -8, 0, 52), BackgroundColor3 = if r.userId == player.UserId then UiKit.colors.line else UiKit.colors.card, Parent = body }, { UiKit.corner(10) })
				local medal = if r.place == 1 then UiKit.colors.gold elseif r.place == 2 then Color3.fromRGB(200, 206, 216) elseif r.place == 3 then Color3.fromRGB(205, 140, 90) else UiKit.colors.soft
				UiKit.label({ Font = UiKit.bold, Text = placeName(r.place), Size = UDim2.new(0, 70, 1, 0), TextColor3 = medal, Parent = card }, 24)
				UiKit.label({ Text = r.name, Size = UDim2.new(0.45, 0, 1, 0), Position = UDim2.fromOffset(76, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = card }, 22)
				UiKit.label({ Text = string.format("%.1f s  ·  +%d coins", r.seconds or 0, r.coins or 0), Size = UDim2.new(0.42, 0, 0.5, 0), Position = UDim2.new(0.58, -10, 0, 2), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = UiKit.colors.soft, Parent = card }, 18)
				if r.kept then -- the needle they keep, in its rarity colour
					local rarity = Needles.rarity(r.kept.rarityId)
					UiKit.label({ Text = r.kept.rarity .. " " .. r.kept.name, Size = UDim2.new(0.62, 0, 0.5, 0), Position = UDim2.new(0.38, -10, 0.5, -2), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = Color3.fromRGB(rarity.colour[1], rarity.colour[2], rarity.colour[3]), Parent = card }, 16)
				end
			end
			local mine = (extra.xp or {})[tostring(player.UserId)] -- your match XP and where it came from
			if mine then
				local box = UiKit.make("Frame", { LayoutOrder = 100, Size = UDim2.new(1, -8, 0, 76), BackgroundColor3 = UiKit.colors.card, Parent = body }, { UiKit.corner(10), UiKit.stroke(UiKit.colors.gold, 2) })
				UiKit.label({ Font = UiKit.bold, Text = "MATCH XP  +" .. Rules.commas(mine.total), TextColor3 = UiKit.colors.gold, Size = UDim2.new(1, -20, 0, 30), Position = UDim2.fromOffset(10, 6), TextXAlignment = Enum.TextXAlignment.Left, Parent = box }, 24)
				local parts = {
					(if mine.place then placeName(mine.place) else "Played") .. " +" .. mine.placeXp,
					mine.coins .. " coins +" .. mine.coinXp,
					mine.needles .. (if mine.needles == 1 then " needle +" else " needles +") .. mine.needleXp,
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

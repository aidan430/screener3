-- The Trade screen (server/TradeManager decides everything). Not trading: everyone in the server
-- with an "Ask to trade" button. Asked: a card with Accept / No thanks. Trading: your offer and
-- theirs side by side with each needle's rarity and value and both totals, your needles to add
-- from, and Ready. Any change un-readies you both; when both are ready a countdown runs, and you
-- can still cancel until it ends.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Needles = require(Shared:WaitForChild("Needles"))
local Rules = require(Shared:WaitForChild("Rules"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UiKit = require(script.Parent.UiKit)
local Hud = require(script.Parent.Hud)

local player = Players.LocalPlayer
local TradeScreen = {}
local win, body, getProfile
local state = nil -- the trade in progress (Remotes.TradeState), or nil

local function rgb(c)
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function clear()
	for _, c in ipairs(body:GetChildren()) do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
end

local function ask(...)
	local ok, why = Remotes.Trade:InvokeServer(...)
	if why then
		Hud.toast(why, if ok then "good" else "bad")
	end
	return ok
end

-- One needle line: rarity colour, name, value, how many; a button if `action` is given.
local function needleRow(parent, order, key, n, label, action)
	local t, s = Needles.split(key)
	if not t then
		return 0
	end
	local skin, value = Needles.skin(s), Needles.value(t, s)
	local rarity = Needles.rarity(skin.rarity)
	local r = UiKit.make("Frame", { LayoutOrder = order, Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = UiKit.colors.card, Parent = parent }, { UiKit.corner(8) })
	UiKit.make("Frame", { Size = UDim2.new(0, 6, 1, 0), BackgroundColor3 = rgb(rarity.colour), Parent = r }, { UiKit.corner(3) })
	UiKit.label({ Text = Needles.name(t, s) .. (if n > 1 then "  ×" .. n else ""), Size = UDim2.new(1, -150, 0, 22), Position = UDim2.fromOffset(14, 2), TextXAlignment = Enum.TextXAlignment.Left, Parent = r }, 17)
	UiKit.label({ Text = rarity.name .. "  ·  " .. Rules.commas(value), TextColor3 = rgb(rarity.colour), Size = UDim2.new(1, -150, 0, 16), Position = UDim2.fromOffset(14, 22), TextXAlignment = Enum.TextXAlignment.Left, Parent = r }, 14)
	if action then
		local b = UiKit.button(label, UiKit.colors.blue, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(110, 32), Parent = r })
		b.Activated:Connect(action)
	end
	return value * n
end

local function column(x, title)
	local col = UiKit.make("Frame", { Position = UDim2.new(x, 0, 0, 0), Size = UDim2.new(0.5, -6, 1, 0), BackgroundTransparency = 1 })
	UiKit.make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = col })
	UiKit.label({ LayoutOrder = 0, Text = title, Font = UiKit.bold, Size = UDim2.new(1, 0, 0, 26), TextXAlignment = Enum.TextXAlignment.Left, Parent = col }, 20)
	return col
end

local function drawTrade()
	local top = UiKit.make("Frame", { LayoutOrder = 1, Size = UDim2.new(1, -8, 0, 300), BackgroundTransparency = 1, Parent = body })
	local yours, theirs = column(0, "You give"), column(0.5, state.them.name .. " gives")
	yours.Parent, theirs.Parent = top, top
	local give, get = 0, 0
	for i, e in ipairs(state.you.offer) do
		give += needleRow(yours, i, e.key, e.count, "Take back", function()
			ask("offer", e.key, false)
		end)
	end
	for i, e in ipairs(state.them.offer) do
		get += needleRow(theirs, i, e.key, e.count)
	end
	UiKit.label({ LayoutOrder = 98, Text = "Value " .. Rules.commas(give) .. (if state.you.ready then "  ·  READY" else ""), Font = UiKit.bold, TextColor3 = UiKit.colors.gold, Size = UDim2.new(1, 0, 0, 24), TextXAlignment = Enum.TextXAlignment.Left, Parent = yours }, 18)
	UiKit.label({ LayoutOrder = 98, Text = "Value " .. Rules.commas(get) .. (if state.them.ready then "  ·  READY" else ""), Font = UiKit.bold, TextColor3 = UiKit.colors.gold, Size = UDim2.new(1, 0, 0, 24), TextXAlignment = Enum.TextXAlignment.Left, Parent = theirs }, 18)
	local bar = UiKit.make("Frame", { LayoutOrder = 2, Size = UDim2.new(1, -8, 0, 50), BackgroundTransparency = 1, Parent = body })
	local ready = UiKit.button(if state.you.ready then "Not ready" else "Ready", if state.you.ready then UiKit.colors.line else UiKit.colors.green, { Size = UDim2.fromOffset(160, 46), Parent = bar })
	ready.Activated:Connect(function()
		ask("ready", not state.you.ready)
	end)
	local cancel = UiKit.button("Cancel trade", UiKit.colors.red, { Position = UDim2.fromOffset(170, 0), Size = UDim2.fromOffset(160, 46), Parent = bar })
	cancel.Activated:Connect(function()
		ask("cancel")
	end)
	local note = UiKit.label({ Text = "Check both sides before you press Ready.", TextColor3 = UiKit.colors.soft, Position = UDim2.fromOffset(340, 0), Size = UDim2.new(1, -340, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = bar }, 18)
	if state.countdownEnds then
		task.spawn(function()
			while note.Parent and state and state.countdownEnds do
				note.Text = "Trading in " .. math.max(0, math.ceil(state.countdownEnds - workspace:GetServerTimeNow())) .. "...  (cancel to stop it)"
				note.TextColor3 = UiKit.colors.gold
				task.wait(0.2)
			end
		end)
	end
	UiKit.label({ LayoutOrder = 3, Text = "Your needles (up to " .. Config.Trading.maxItems .. " in a trade)", Font = UiKit.bold, Size = UDim2.new(1, -8, 0, 26), TextXAlignment = Enum.TextXAlignment.Left, Parent = body }, 20)
	local offered = {}
	for _, e in ipairs(state.you.offer) do
		offered[e.key] = e.count
	end
	local order = 4
	for key, n in pairs(getProfile().collection or {}) do
		local left = n - (offered[key] or 0)
		if left > 0 then
			order += 1
			needleRow(body, order, key, left, "Add", function()
				ask("offer", key, true)
			end)
		end
	end
end

local function drawPlayers()
	UiKit.label({ LayoutOrder = 0, Text = "Swap needles with anyone in this server, in the lobby between rounds.", TextColor3 = UiKit.colors.soft, Size = UDim2.new(1, -8, 0, 24), TextXAlignment = Enum.TextXAlignment.Left, Parent = body }, 18)
	for i, p in ipairs(Remotes.Collection:InvokeServer("list") or {}) do
		if p.userId ~= player.UserId then
			local r = UiKit.make("Frame", { LayoutOrder = i, Size = UDim2.new(1, -8, 0, 50), BackgroundColor3 = UiKit.colors.card, Parent = body }, { UiKit.corner(10) })
			UiKit.label({ Text = p.name .. "  ·  collection " .. Rules.commas(p.value), Size = UDim2.new(1, -200, 1, 0), Position = UDim2.fromOffset(14, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = r }, 20)
			local b = UiKit.button("Ask to trade", UiKit.colors.blue, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(170, 40), Parent = r })
			b.Activated:Connect(function()
				ask("request", p.userId)
			end)
		end
	end
end

function TradeScreen.refresh()
	if not win or not win.Visible then
		return
	end
	clear()
	if state then
		drawTrade()
	else
		drawPlayers()
	end
end

-- Someone asked: a card under the banner with Accept / No thanks, gone after 30 seconds.
local function invite(gui, m)
	local card = UiKit.make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 140), Size = UDim2.fromOffset(420, 110), BackgroundColor3 = UiKit.colors.panel, ZIndex = 30, Parent = gui }, { UiKit.corner(14), UiKit.stroke(UiKit.colors.blue, 2) })
	UiKit.autoScale(card)
	UiKit.label({ Text = m.name .. " wants to trade needles", Font = UiKit.bold, Size = UDim2.new(1, -20, 0, 30), Position = UDim2.fromOffset(10, 10), ZIndex = 31, Parent = card }, 22)
	local yes = UiKit.button("Accept", UiKit.colors.green, { Position = UDim2.fromOffset(20, 54), Size = UDim2.fromOffset(180, 44), ZIndex = 31, Parent = card })
	local no = UiKit.button("No thanks", UiKit.colors.card, { Position = UDim2.fromOffset(220, 54), Size = UDim2.fromOffset(180, 44), ZIndex = 31, Parent = card })
	yes.Activated:Connect(function()
		card:Destroy()
		if ask("respond", m.from, true) then
			win.Visible = true
		end
	end)
	no.Activated:Connect(function()
		card:Destroy()
		ask("respond", m.from, false)
	end)
	UiKit.pop(card, 0.8)
	task.delay(30, function()
		if card.Parent then
			card:Destroy()
		end
	end)
end

function TradeScreen.mount(gui, profileFn)
	getProfile = profileFn
	win, body = UiKit.window(gui, "Trade", 820, 600)
	Remotes.TradeState.OnClientEvent:Connect(function(m)
		if m.kind == "invite" then
			invite(gui, m)
		elseif m.kind == "trade" then
			state = m
			win.Visible = true
			TradeScreen.refresh()
		elseif m.kind == "closed" then
			state = nil
			Hud.toast(m.text or "Trade closed.", "good")
			TradeScreen.refresh()
		end
	end)
	return { Trade = win }, { Trade = TradeScreen.refresh }
end

return TradeScreen

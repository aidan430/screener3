-- The guided goal card (top left) and the coins-a-minute line under the coins counter.
-- The server decides when a goal is done (server/Goals.luau); this only shows the
-- attributes Goal, GoalProgress and GoalShare, and celebrates softly when Goal moves on.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Ui = require(script.Parent.Ui)
local Juice = require(script.Parent.Juice)

local player = Players.LocalPlayer
local Goals = {}

local earned = {} -- { time, coins } for each rise in Coins (goal rewards taken back out)

local function card(gui)
	-- a note pinned at the top right, a little askew
	local frame = Ui.card({ Name = "GoalCard", AnchorPoint = Vector2.new(1, 0), Size = UDim2.fromOffset(280, 86), Rotation = -1, Visible = false, Parent = gui })
	Ui.autoScale(frame)
	Ui.onLayout(function()
		frame.Position = UDim2.new(1, -16, 0, Ui.topInset() + 14)
	end)
	Ui.pin(frame, Ui.colors.red)
	local heading = Ui.label({ Size = UDim2.new(1, -28, 0, 20), Position = UDim2.fromOffset(14, 12), TextColor3 = Ui.colors.ink, TextStrokeTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Parent = frame }, 16)
	local text = Ui.label({ Size = UDim2.new(1, -28, 0, 30), Position = UDim2.fromOffset(14, 34), TextColor3 = Ui.colors.soft, TextStrokeTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Font = Ui.body, Parent = frame }, 14)
	local _, fill = Ui.bar(frame, { Size = UDim2.new(1, -28, 0, 5), Position = UDim2.fromOffset(14, 70) }, Ui.colors.green)
	return frame, heading, text, fill
end

local function goalLine(index)
	local goal = Config.Goals[index]
	return goal and (goal.text .. " (" .. tostring(player:GetAttribute("GoalProgress") or "") .. ")") or ""
end

-- Celebrates the goals between `from` and `to - 1` that the server just marked done.
local function celebrate(Notify, frame, from, to)
	local reward, last = 0, nil
	for i = from, to - 1 do
		local goal = Config.Goals[i]
		if goal then
			reward += goal.reward
			last = goal
		end
	end
	if not last then
		return
	end
	table.insert(earned, { time = os.clock(), coins = -reward }) -- a gift, not earnings
	Notify.toast("Goal done: " .. last.text .. "!  +" .. Format.short(reward) .. " coins", Ui.colors.green)
	Juice.coins(reward)
	-- confetti only now and then (every fifth goal and the last), a soft glow every time
	if to > #Config.Goals or (to - 1) % 5 == 0 then
		Juice.confetti()
	end
	frame.BackgroundColor3 = Color3.fromRGB(226, 236, 210) -- a soft green flush, fading back to paper
	Juice.ease(frame, 1.2, { BackgroundColor3 = Ui.colors.cream })
end

local function startCard(gui, Notify)
	local frame, heading, text, fill = card(gui)
	local shown = nil -- the goal on the card
	local function refresh()
		local index = player:GetAttribute("Goal")
		if type(index) ~= "number" then
			return
		end
		if shown and index > shown then
			celebrate(Notify, frame, shown, index)
		end
		if index > #Config.Goals then
			if shown and shown <= #Config.Goals then -- just finished the last one: say so, then fade away
				heading.Text = "All " .. #Config.Goals .. " goals done!"
				text.Text = "Now find the needle hidden in your heap."
				Juice.ease(fill, 0.4, { Size = UDim2.fromScale(1, 1) })
				task.delay(10, function()
					frame.Visible = false
				end)
			else
				frame.Visible = false
			end
			shown = index
			return
		end
		frame.Visible = true
		heading.Text = "Goal " .. index .. " of " .. #Config.Goals .. " · " .. Format.short(Config.Goals[index].reward) .. " coins"
		text.Text = goalLine(index)
		local share = player:GetAttribute("GoalShare") or 0
		if shown ~= index then
			fill.Size = UDim2.fromScale(0, 1) -- a new goal's bar starts empty
		end
		Juice.ease(fill, 0.5, { Size = UDim2.fromScale(math.clamp(share, 0, 1), 1) })
		shown = index
	end
	for _, name in ipairs({ "Goal", "GoalProgress", "GoalShare" }) do
		player:GetAttributeChangedSignal(name):Connect(refresh)
	end
	refresh()
end

-- Coins a minute: every rise in Coins over the last Config.RateWindowSeconds (spending ignored).
local function startRate(label)
	local holder = Instance.new("NumberValue")
	local last = player:GetAttribute("Coins")
	player:GetAttributeChangedSignal("Coins"):Connect(function()
		local now = player:GetAttribute("Coins")
		if type(now) == "number" and type(last) == "number" and now > last then
			table.insert(earned, { time = os.clock(), coins = now - last })
		end
		last = now
	end)
	task.spawn(function()
		while label.Parent do
			local window, total, cutoff = Config.RateWindowSeconds, 0, os.clock() - Config.RateWindowSeconds
			while earned[1] and earned[1].time < cutoff do
				table.remove(earned, 1)
			end
			for _, e in ipairs(earned) do
				total += e.coins
			end
			local perMinute = math.max(0, total) * 60 / window
			Juice.countTo(label, holder, perMinute, function(v)
				return "+" .. Format.short(math.floor(v + 0.5)) .. " a minute"
			end)
			task.wait(1)
		end
	end)
end

function Goals.start(gui, hud, Notify)
	if hud and hud.earn then
		startRate(hud.earn)
	end
	startCard(gui, Notify)
end

return Goals

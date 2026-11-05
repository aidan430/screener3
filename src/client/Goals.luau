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
	local frame = Ui.make("Frame", { Name = "GoalCard", Position = UDim2.fromOffset(10, 60), Size = UDim2.fromOffset(290, 66), BackgroundColor3 = Ui.colors.wood, BackgroundTransparency = 0.15, Visible = false, Parent = gui }, { Ui.corner(12), Ui.stroke(Ui.colors.woodDark, 3) })
	Ui.autoScale(frame)
	local heading = Ui.label({ Size = UDim2.new(1, -16, 0, 16), Position = UDim2.fromOffset(8, 4), TextColor3 = Ui.colors.hay, TextXAlignment = Enum.TextXAlignment.Left, Parent = frame }, 15)
	local text = Ui.label({ Size = UDim2.new(1, -16, 0, 30), Position = UDim2.fromOffset(8, 20), TextColor3 = Ui.colors.cream, TextXAlignment = Enum.TextXAlignment.Left, Font = Ui.body, Parent = frame }, 15)
	local back = Ui.make("Frame", { Size = UDim2.new(1, -16, 0, 8), Position = UDim2.fromOffset(8, 53), BackgroundColor3 = Ui.colors.woodDark, Parent = frame }, { Ui.corner(4) })
	local fill = Ui.make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Ui.colors.green, Parent = back }, { Ui.corner(4) })
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
	frame.BackgroundColor3 = Ui.colors.green
	Juice.ease(frame, 1.2, { BackgroundColor3 = Ui.colors.wood })
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
		heading.Text = "Goal " .. index .. " of " .. #Config.Goals .. "  (+" .. Format.short(Config.Goals[index].reward) .. " coins)"
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
				return "+" .. Format.short(math.floor(v + 0.5)) .. " coins/min"
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

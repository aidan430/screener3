-- The Time Trial on your screen (server/Practice decides everything): the Practice window (your
-- best, the fastest five, Start), then in the yard a 3-2-1 countdown, the clock counting down,
-- dummies and chests left, a pop on every hit, and the result: your time and whether it's a new
-- best, or how far you got. Leave any time. Soft, eased effects only: nothing flashes.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UiKit = require(script.Parent.UiKit)
local Hud = require(script.Parent.Hud)
local Effects = require(script.Parent.Effects)

local player = Players.LocalPlayer
local PracticeFx = {}
local win, body, hud, clock, counts, big, result
local state = { phase = "off" }
local RED = Color3.fromRGB(200, 30, 30)

local function stamp(seconds) -- 1:42.3
	seconds = math.max(0, seconds)
	return string.format("%d:%04.1f", seconds // 60, seconds % 60)
end

local function clear()
	for _, c in ipairs(body:GetChildren()) do
		if not c:IsA("UIListLayout") then
			c:Destroy()
		end
	end
end

local function start()
	win.Visible = false
	local ok, why = Remotes.Practice:InvokeServer("start")
	if not ok then
		Hud.toast(why or "Couldn't start the Time Trial.", "bad")
	end
end

function PracticeFx.refresh()
	if not win or not win.Visible then
		return
	end
	clear()
	local info = Remotes.Practice:InvokeServer("info") or {}
	local P = Config.Practice
	UiKit.label({ LayoutOrder = 1, Text = string.format("Your own yard: tag out all %d dummies and open all %d chests in %s. Practice only (no coins or keys), but a full clear goes on the Fastest Time Trial board.", P.dummies, P.chests, stamp(P.seconds):sub(1, -3)), TextWrapped = true, Size = UDim2.new(1, -8, 0, 64), TextXAlignment = Enum.TextXAlignment.Left, Parent = body }, 19)
	UiKit.label({ LayoutOrder = 2, Text = if (info.best or 0) > 0 then "Your best: " .. stamp(info.best) .. "   ·   runs: " .. (info.runs or 0) else "No clear yet. Runs: " .. (info.runs or 0), Font = UiKit.bold, Size = UDim2.new(1, -8, 0, 28), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UiKit.colors.gold, Parent = body }, 22)
	UiKit.label({ LayoutOrder = 3, Text = "Fastest Time Trial", Font = UiKit.bold, Size = UDim2.new(1, -8, 0, 26), TextXAlignment = Enum.TextXAlignment.Left, Parent = body }, 20)
	for i, row in ipairs(info.top or {}) do
		UiKit.label({ LayoutOrder = 3 + i, Text = string.format("%d.  %s   %s", i, row.name, stamp(row.value)), Size = UDim2.new(1, -8, 0, 22), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UiKit.colors.soft, Parent = body }, 18)
	end
	if #(info.top or {}) == 0 then
		UiKit.label({ LayoutOrder = 4, Text = "Nobody on the board yet: be the first.", Size = UDim2.new(1, -8, 0, 22), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UiKit.colors.soft, Parent = body }, 18)
	end
	local go = UiKit.button(if info.running then "Leave the yard" else "Start the Time Trial", if info.running then UiKit.colors.card else RED, { LayoutOrder = 20, Size = UDim2.new(1, -8, 0, 54), Parent = body })
	go.Activated:Connect(function()
		if info.running then
			win.Visible = false
			Remotes.Practice:InvokeServer("leave")
		else
			start()
		end
	end)
end

local function showResult(m)
	result.Visible = true
	result.Title.Text = if m.cleared then "CLEARED IN " .. stamp(m.time) .. "!" else "TIME'S UP"
	result.Line.Text = if m.cleared
		then (if m.newBest then "A new best! It's on the Fastest Time Trial board." else "Your best: " .. stamp(m.best))
		else string.format("Dummies %d / %d   ·   Chests %d / %d. Clear them all to get on the board.", m.tagged, m.dummies, m.opened, m.chests)
	UiKit.pop(result, 0.9)
	if m.cleared then
		Effects.confetti()
	end
end

local function onState(m)
	if m.event == "hit" then
		Effects.burst(m.position, { RED, Color3.new(1, 1, 1) }, if m.hearts == 0 then 30 else 14)
		Effects.sound(if m.hearts == 0 then "found" else "click", if m.hearts == 0 then 0.9 else 1.3)
		return
	elseif m.event == "chest" then
		Effects.burst(m.position + Vector3.new(0, 2, 0), { Color3.fromRGB(255, 214, 90), Color3.new(1, 1, 1) }, 30)
		Effects.sound("found", 1.1)
		return
	end
	state = m
	hud.Visible = m.phase ~= "off"
	result.Visible = false
	if m.phase == "done" then
		showResult(m)
	end
	if m.phase ~= "off" then
		counts.Text = string.format("Dummies  %d / %d      Chests  %d / %d", m.tagged, m.dummies, m.opened, m.chests)
	end
end

function PracticeFx.mount(gui)
	win, body = UiKit.window(gui, "Practice", 560, 470)
	hud = UiKit.make("Frame", { Name = "TimeTrial", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = gui })
	local top = UiKit.make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 12), Size = UDim2.fromOffset(420, 96), BackgroundColor3 = UiKit.colors.panel, BackgroundTransparency = 0.1, Parent = hud }, { UiKit.corner(14), UiKit.stroke(RED, 2) })
	UiKit.autoScale(top)
	UiKit.label({ Text = "TIME TRIAL", Font = UiKit.bold, Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 6), TextColor3 = Color3.fromRGB(255, 120, 110), Parent = top }, 16)
	clock = UiKit.label({ Text = "3:00.0", Font = UiKit.bold, Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromOffset(0, 24), Parent = top }, 38)
	counts = UiKit.label({ Text = "", Size = UDim2.new(1, 0, 0, 22), Position = UDim2.fromOffset(0, 68), TextColor3 = UiKit.colors.soft, Parent = top }, 17)
	big = UiKit.label({ Text = "", Font = UiKit.bold, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromOffset(400, 160), TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0.5, Parent = hud }, 140)
	result = UiKit.make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(520, 220), BackgroundColor3 = UiKit.colors.panel, BackgroundTransparency = 0.05, Visible = false, Parent = hud }, { UiKit.corner(18), UiKit.stroke(RED, 3) })
	UiKit.autoScale(result)
	UiKit.label({ Name = "Title", Text = "", Font = UiKit.bold, Size = UDim2.new(1, -24, 0, 56), Position = UDim2.fromOffset(12, 18), TextColor3 = UiKit.colors.gold, Parent = result }, 40)
	UiKit.label({ Name = "Line", Text = "", TextWrapped = true, Size = UDim2.new(1, -40, 0, 56), Position = UDim2.fromOffset(20, 78), Parent = result }, 20)
	local again = UiKit.button("Go again", RED, { Position = UDim2.new(0, 20, 1, -66), Size = UDim2.new(0.5, -26, 0, 48), Parent = result })
	local back = UiKit.button("Back to the lobby", UiKit.colors.card, { Position = UDim2.new(0.5, 6, 1, -66), Size = UDim2.new(0.5, -26, 0, 48), Parent = result })
	again.Activated:Connect(function()
		Remotes.Practice:InvokeServer("leave")
		task.wait(0.4)
		start()
	end)
	back.Activated:Connect(function()
		Remotes.Practice:InvokeServer("leave")
	end)
	local leave = UiKit.button("Leave", UiKit.colors.card, { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 16, 1, -16), Size = UDim2.fromOffset(120, 46), Parent = hud })
	UiKit.autoScale(leave)
	leave.Activated:Connect(function()
		Remotes.Practice:InvokeServer("leave")
	end)
	Remotes.PracticeState.OnClientEvent:Connect(onState)
	local shown = nil
	RunService.RenderStepped:Connect(function()
		if state.phase == "off" or not state.startAt then
			return
		end
		local t = workspace:GetServerTimeNow()
		if state.phase == "countdown" or (state.phase == "running" and t - state.startAt < 0.8) then
			local n = math.ceil(state.startAt - t)
			local text = if n > 0 then tostring(n) else "GO!"
			if text ~= shown then -- each number pops in, then eases away
				shown, big.Text, big.TextTransparency = text, text, 0
				UiKit.pop(big, 0.6)
				UiKit.ease(big, 0.9, { TextTransparency = 1 })
				Effects.sound("countdown", if n > 0 then 1 else 1.5)
			end
		end
		if state.phase == "running" then
			clock.Text = stamp(state.endsAt - t)
			clock.TextColor3 = if state.endsAt - t < 30 then Color3.fromRGB(255, 120, 110) else Color3.new(1, 1, 1)
		elseif state.phase == "countdown" then
			clock.Text = stamp(Config.Practice.seconds)
		end
	end)
	return { Practice = win }, { Practice = PracticeFx.refresh }
end

return PracticeFx

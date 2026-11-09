-- The story's dialogue box: a paper card at the bottom of the screen, the speaker's round
-- portrait and name in their colour, their words typing out, and Next (click, E or Enter) or the
-- player's choice of reply. "Found" items show first. Beats arrive from the server
-- (Remotes.Story) and queue up; Skip closes the one showing. Dialogue.play(id) replays a beat
-- (the journal's "The story so far").
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local StoryData = require(Shared:WaitForChild("Story"))
local Ui = require(script.Parent.Ui)
local Cursor = require(script.Parent.Cursor)
local Juice = require(script.Parent.Juice)

local Dialogue = {}
local queue, playing = {}, false
local box, portrait, initial, nameLabel, textLabel, foundLabel, nextButton, skipButton, choiceRow
local advance = nil -- what Next does right now
local LETTERS_PER_SECOND = 45

local byId = {}
for _, beat in ipairs(StoryData.beats) do
	byId[beat.id] = beat
end

local function colourOf(who)
	local c = StoryData.cast[who] and StoryData.cast[who].colour or { 120, 100, 80 }
	return Color3.fromRGB(c[1], c[2], c[3])
end

-- Types `text` out; resolves early if the player presses Next. Returns when it's all shown.
local function typeOut(text)
	textLabel.Text = text
	textLabel.MaxVisibleGraphemes = 0
	local shown, done = 0, false
	advance = function()
		done = true
	end
	while not done and shown < #text do
		shown += math.max(1, math.floor(LETTERS_PER_SECOND * task.wait()))
		textLabel.MaxVisibleGraphemes = shown
	end
	textLabel.MaxVisibleGraphemes = -1
end

-- Waits for Next (or a choice). Returns the chosen choice, if the line had any.
local function waitNext(choices)
	local picked, waiting = nil, true
	for _, child in ipairs(choiceRow:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	choiceRow.Visible = choices ~= nil
	nextButton.Visible = choices == nil
	for i, choice in ipairs(choices or {}) do
		local b = Ui.button(choice[1], if i == 1 then Ui.colors.ink else Ui.colors.wood, { LayoutOrder = i, Size = UDim2.new(0.5, -5, 1, 0), Parent = choiceRow })
		b.Activated:Connect(function()
			picked, waiting = choice, false
		end)
	end
	advance = if choices then nil else function()
		waiting = false
	end
	while waiting and playing do
		task.wait()
	end
	choiceRow.Visible, nextButton.Visible = false, true
	return picked
end

local function speak(who, text, choices)
	local c = colourOf(who)
	portrait.BackgroundColor3 = c
	initial.Text = string.sub((StoryData.cast[who] or { name = "?" }).name, 1, 1)
	nameLabel.Text = (StoryData.cast[who] or { name = who }).name
	nameLabel.TextColor3 = c
	typeOut(text)
	if not playing then
		return
	end
	local picked = waitNext(choices)
	if picked and playing then
		nameLabel.Text, nameLabel.TextColor3, portrait.BackgroundColor3, initial.Text = "You", Ui.colors.ink, Ui.colors.soft, "Y"
		typeOut(picked[1])
		task.wait(0.6)
		portrait.BackgroundColor3, initial.Text, nameLabel.Text, nameLabel.TextColor3 = c, string.sub(StoryData.cast[who].name, 1, 1), StoryData.cast[who].name, c
		typeOut(picked[2])
		waitNext(nil)
	end
end

local function playBeat(beat)
	playing = true
	box.Visible = true
	Cursor.need("story", true)
	box.Position = UDim2.new(0.5, 0, 1, 20)
	Juice.ease(box, 0.35, { Position = UDim2.new(0.5, 0, 1, -96) }, Enum.EasingStyle.Back)
	foundLabel.Visible = beat.found ~= nil
	foundLabel.Text = if beat.found then "Found in the hay: " .. beat.found else ""
	if beat.found then
		Juice.sound("coins", 0.9)
	end
	for _, line in ipairs(beat.lines) do
		if not playing then
			break
		end
		speak(line.who, line.text, line.choices)
		foundLabel.Visible = false
	end
	playing = false
	box.Visible = false
	Cursor.need("story", false)
end

local function pump()
	if box.Visible then
		return
	end
	task.spawn(function()
		while #queue > 0 do
			playBeat(table.remove(queue, 1))
		end
	end)
end

function Dialogue.play(id)
	local beat = byId[id]
	if beat then
		table.insert(queue, beat)
		pump()
	end
end

function Dialogue.mount(gui, Remotes, notify)
	box = Ui.card({ Name = "Dialogue", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -96), Size = UDim2.fromOffset(640, 168), Visible = false, ZIndex = 20, Parent = gui })
	Ui.autoScale(box)
	portrait = Ui.make("Frame", { Size = UDim2.fromOffset(64, 64), Position = UDim2.fromOffset(18, 30), ZIndex = 21, Parent = box }, { Ui.corner(32) })
	initial = Ui.label({ Size = UDim2.fromScale(1, 1), TextColor3 = Ui.colors.white, TextStrokeTransparency = 1, ZIndex = 22, Parent = portrait }, 30)
	foundLabel = Ui.label({ Font = Ui.bold, Size = UDim2.new(1, -120, 0, 16), Position = UDim2.fromOffset(100, 6), TextColor3 = Ui.colors.hay, TextStrokeTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 21, Parent = box }, 13)
	nameLabel = Ui.label({ Size = UDim2.new(1, -240, 0, 22), Position = UDim2.fromOffset(100, 22), TextStrokeTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 21, Parent = box }, 18)
	textLabel = Ui.label({ Font = Ui.body, Size = UDim2.new(1, -124, 0, 70), Position = UDim2.fromOffset(100, 48), TextColor3 = Ui.colors.ink, TextStrokeTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 21, Parent = box }, 17)
	nextButton = Ui.button("Next", Ui.colors.ink, { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -12), Size = UDim2.fromOffset(96, 32), ZIndex = 21, Parent = box })
	skipButton = Ui.make("TextButton", { Text = "Skip", Font = Ui.body, TextSize = 14, TextColor3 = Ui.colors.soft, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 8), Size = UDim2.fromOffset(50, 22), ZIndex = 21, Parent = box })
	choiceRow = Ui.make("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 100, 1, -12), Size = UDim2.new(1, -116, 0, 32), BackgroundTransparency = 1, Visible = false, ZIndex = 21, Parent = box }, {
		Ui.make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	nextButton.Activated:Connect(function()
		if advance then
			advance()
		end
	end)
	skipButton.Activated:Connect(function()
		playing = false -- this beat closes; the next in the queue (if any) follows
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if box.Visible and not processed and (input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.Return) and advance then
			advance()
		end
	end)
	Remotes.Story.OnClientEvent:Connect(function(message)
		local beat = byId[message.id]
		if beat then
			if (beat.reward or 0) > 0 and notify then
				notify.toast(beat.title .. ": +" .. beat.reward .. " coins", Ui.colors.hay)
			end
			table.insert(queue, beat)
			pump()
		end
	end)
end

return Dialogue

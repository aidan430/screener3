-- The Quests, Leaderboard and Settings screens.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Quests = require(Shared:WaitForChild("Quests"))
local Cosmetics = require(Shared:WaitForChild("Cosmetics"))
local Rules = require(Shared:WaitForChild("Rules"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UiKit = require(script.Parent.UiKit)
local Effects = require(script.Parent.Effects)

local Screens2 = {}
local quests, questBody, boards, boardBody, settings, settingsBody
local getProfile = function()
	return {}
end
local boardId, scope = "needles", "global"

local function clear(body)
	for _, c in ipairs(body:GetChildren()) do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
end

local function questsPage()
	clear(questBody)
	local profile = getProfile()
	local q = profile.quests or {}
	local today = Quests.today()
	local progress = if q.day == today then q.progress or {} else {}
	local done = if q.day == today then q.done or {} else {}
	local left = 86400 - os.time() % 86400
	UiKit.label({ LayoutOrder = 0, Text = string.format("New quests in %dh %02dm", left // 3600, left % 3600 // 60), Size = UDim2.new(1, 0, 0, 24), TextColor3 = UiKit.colors.soft, Parent = questBody }, 18)
	for i, quest in ipairs(Quests.forDay(today)) do
		local have = math.min(quest.n, progress[quest.id] or 0)
		local c = UiKit.make("Frame", { LayoutOrder = i, Size = UDim2.new(1, -8, 0, 96), BackgroundColor3 = UiKit.colors.card, Parent = questBody }, { UiKit.corner(12) })
		UiKit.label({ Font = UiKit.bold, Text = (if done[quest.id] then "✓ " else "") .. quest.text, Size = UDim2.new(1, -24, 0, 30), Position = UDim2.fromOffset(14, 8), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = if done[quest.id] then UiKit.colors.green else UiKit.colors.text, Parent = c }, 22)
		local reward = "+" .. quest.coins .. " coins · +" .. quest.xp .. " XP" .. (if quest.cosmetic and Cosmetics.get(quest.cosmetic) then " · " .. Cosmetics.get(quest.cosmetic).name else "")
		UiKit.label({ Text = reward, Size = UDim2.new(1, -24, 0, 22), Position = UDim2.fromOffset(14, 38), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UiKit.colors.gold, Parent = c }, 18)
		local _, fill = UiKit.bar(c, { Size = UDim2.new(1, -110, 0, 12), Position = UDim2.fromOffset(14, 70) }, UiKit.colors.green)
		fill.Size = UDim2.fromScale(have / quest.n, 1)
		UiKit.label({ Text = have .. " / " .. quest.n, Size = UDim2.fromOffset(80, 22), Position = UDim2.new(1, -90, 0, 64), Parent = c }, 18)
	end
end

local function boardsPage()
	clear(boardBody)
	local tabs = UiKit.make("Frame", { LayoutOrder = 0, Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, Parent = boardBody }, {
		UiKit.make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }),
	})
	for _, b in ipairs(Config.Boards) do
		local t = UiKit.button(b.name, if b.id == boardId then UiKit.colors.gold else UiKit.colors.card, { Size = UDim2.new(1 / #Config.Boards, -6, 1, 0), Parent = tabs })
		t.Activated:Connect(function()
			boardId = b.id
			boardsPage()
		end)
	end
	local scopes = UiKit.make("Frame", { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Parent = boardBody }, {
		UiKit.make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }),
	})
	for _, s in ipairs({ { "global", "Everyone" }, { "server", "This server (friends)" } }) do
		local b = UiKit.button(s[2], if scope == s[1] then UiKit.colors.blue else UiKit.colors.card, { Size = UDim2.new(0.5, -6, 1, 0), Parent = scopes })
		b.Activated:Connect(function()
			scope = s[1]
			boardsPage()
		end)
	end
	local data = Remotes.Boards:InvokeServer(boardId) or {}
	local rows = data[scope] or {}
	local seconds = false
	for _, b in ipairs(Config.Boards) do
		if b.id == boardId then
			seconds = b.seconds == true
		end
	end
	if #rows == 0 then
		UiKit.label({ LayoutOrder = 2, Text = "No one here yet. Be the first!", Size = UDim2.new(1, 0, 0, 40), TextColor3 = UiKit.colors.soft, Parent = boardBody }, 20)
	end
	for i, r in ipairs(rows) do
		local c = UiKit.make("Frame", { LayoutOrder = 1 + i, Size = UDim2.new(1, -8, 0, 40), BackgroundColor3 = UiKit.colors.card, Parent = boardBody }, { UiKit.corner(8) })
		UiKit.label({ Font = UiKit.bold, Text = i .. ".", Size = UDim2.fromOffset(50, 40), TextColor3 = if i <= 3 then UiKit.colors.gold else UiKit.colors.soft, Parent = c }, 20)
		UiKit.label({ Text = r.name, Size = UDim2.new(0.6, -50, 1, 0), Position = UDim2.fromOffset(54, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = c }, 20)
		UiKit.label({ Text = if seconds then string.format("%.1f s", r.value) else Rules.commas(r.value), Size = UDim2.new(0.35, 0, 1, 0), Position = UDim2.new(0.62, 0, 0, 0), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = UiKit.colors.gold, Parent = c }, 20)
	end
end

local LABELS = { { "music", "Music" }, { "sfx", "Sound effects" }, { "reduceEffects", "Reduce effects (no flash or shake)" }, { "autoJoin", "Join rounds automatically" } }

local function settingsPage()
	clear(settingsBody)
	local current = getProfile().settings or {}
	for i, row in ipairs(LABELS) do
		local key = row[1]
		local on = current[key] == true
		local c = UiKit.make("Frame", { LayoutOrder = i, Size = UDim2.new(1, -8, 0, 64), BackgroundColor3 = UiKit.colors.card, Parent = settingsBody }, { UiKit.corner(12) })
		UiKit.label({ Text = row[2], Size = UDim2.new(1, -150, 1, 0), Position = UDim2.fromOffset(16, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = c }, 22)
		local b = UiKit.button(if on then "On" else "Off", if on then UiKit.colors.green else UiKit.colors.line, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(110, 46), Parent = c })
		b.Activated:Connect(function()
			Effects.sound("click")
			current[key] = not on
			Remotes.SaveSettings:FireServer({ [key] = not on })
			Effects.settings[key] = not on
			settingsPage()
		end)
	end
end

function Screens2.refresh()
	if quests.Visible then
		questsPage()
	end
	if settings.Visible then
		settingsPage()
	end
end

function Screens2.mount(gui, profileGetter)
	getProfile = profileGetter
	quests, questBody = UiKit.window(gui, "Daily Quests", 560, 440)
	boards, boardBody = UiKit.window(gui, "Leaderboard", 680, 520)
	settings, settingsBody = UiKit.window(gui, "Settings", 520, 400)
	return { Quests = quests, Leaderboard = boards, Settings = settings }, { Leaderboard = boardsPage }
end

return Screens2

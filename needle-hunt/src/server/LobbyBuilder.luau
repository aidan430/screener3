-- The lobby, built once at Config.LobbyCentre: a wooden plaza in a field, the animated title sign
-- (a giant needle turns above it), the glowing Play pad with the next round's countdown, a
-- leaderboard that cycles through every board, the Daily Challenge board, a Shop stall and a
-- Wardrobe (their prompts open those screens on the player's own UI), and haystacks round the edge.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Quests = require(Shared:WaitForChild("Quests"))
local Rules = require(Shared:WaitForChild("Rules"))
local MapKit = require(script.Parent.MapKit)
local LeaderboardManager = require(script.Parent.LeaderboardManager)

local LobbyBuilder = {}
local ctx = nil

-- A board at map-local (x, y, z) facing the plaza, with a SurfaceGui on its front (a part's
-- Front face looks down its LookVector); returns the frame to write on.
local function board(name, x, y, z, w, h)
	local pos = MapKit.at(ctx, x, y, z)
	local cf = CFrame.lookAt(pos, MapKit.at(ctx, 0, y, 10))
	local p = MapKit.part(ctx, { Name = name, Size = Vector3.new(w, h, 0.6), CFrame = cf, Color = { 120, 84, 50 }, Material = "WoodPlanks" })
	for _, dx in ipairs({ -w / 2 + 0.6, w / 2 - 0.6 }) do
		MapKit.part(ctx, { Name = "Post", Size = Vector3.new(0.8, h + cf.Position.Y, 0.8), CFrame = cf * CFrame.new(dx, -(cf.Position.Y) / 2, 0.5), Color = { 96, 66, 40 }, Material = "Wood" })
	end
	local gui = Instance.new("SurfaceGui")
	gui.Face, gui.SizingMode, gui.PixelsPerStud, gui.LightInfluence = Enum.NormalId.Front, Enum.SurfaceGuiSizingMode.PixelsPerStud, 30, 0.1
	gui.Parent = p
	local paper = Instance.new("Frame")
	paper.Size, paper.Position, paper.BackgroundColor3 = UDim2.new(1, -24, 1, -24), UDim2.fromOffset(12, 12), Color3.fromRGB(30, 34, 44)
	Instance.new("UICorner", paper).CornerRadius = UDim.new(0, 18)
	paper.Parent = gui
	return paper
end

local function text(parent, props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency, l.Font, l.TextScaled, l.TextColor3 = 1, Enum.Font.BuilderSansBold, true, Color3.new(1, 1, 1)
	for k, v in pairs(props) do
		l[k] = v
	end
	l.Parent = parent
	return l
end

local function stall(name, x, z, opens, colour)
	local base = MapKit.at(ctx, x, 0, z)
	MapKit.part(ctx, { Name = name, Size = Vector3.new(10, 3, 5), CFrame = CFrame.new(base + Vector3.new(0, 1.5, 0)), Color = { 150, 106, 64 }, Material = "WoodPlanks" })
	for _, dx in ipairs({ -4.6, 4.6 }) do
		MapKit.part(ctx, { Name = "Post", Size = Vector3.new(0.6, 8, 0.6), CFrame = CFrame.new(base + Vector3.new(dx, 4, -2)), Color = { 96, 66, 40 }, Material = "Wood" })
	end
	local roof = MapKit.part(ctx, { Name = "Awning", Size = Vector3.new(11, 0.5, 6), CFrame = CFrame.new(base + Vector3.new(0, 8.2, -0.5)) * CFrame.Angles(math.rad(-12), 0, 0), Color = colour, Material = "Fabric" })
	local sign = Instance.new("SurfaceGui")
	sign.Face, sign.PixelsPerStud, sign.SizingMode = Enum.NormalId.Top, 20, Enum.SurfaceGuiSizingMode.PixelsPerStud
	sign.Parent = roof
	text(sign, { Size = UDim2.fromScale(1, 1), Text = opens:upper() })
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText, prompt.ObjectText, prompt.HoldDuration, prompt.MaxActivationDistance = "Open", opens, 0, 12
	prompt:SetAttribute("Opens", opens)
	prompt.Parent = ctx.model:FindFirstChild(name)
end

function LobbyBuilder.spawnPoint(i)
	local a = (i or 1) * 2.399 -- spread out round the pad
	return CFrame.new(MapKit.at(ctx, math.cos(a) * 10, 3, 18 + math.sin(a) * 6))
end

function LobbyBuilder.build()
	local model = Instance.new("Model")
	model.Name = "Lobby"
	model.Parent = workspace
	ctx = { model = model, rng = Random.new(7), centre = Config.LobbyCentre, def = { straw = { 226, 188, 92 } }, spots = {}, spawns = {}, floorY = 0 }
	MapKit.ground(ctx, 260, 260, { 104, 160, 76 }, "Grass")
	MapKit.part(ctx, { Name = "Plaza", Size = Vector3.new(90, 0.4, 90), CFrame = CFrame.new(MapKit.at(ctx, 0, 0.2, 0)), Color = { 170, 128, 86 }, Material = "WoodPlanks" })
	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored, spawn.Size, spawn.Duration, spawn.Neutral = true, Vector3.new(12, 1, 12), 0, true
	spawn.CFrame, spawn.Color, spawn.Material = CFrame.new(MapKit.at(ctx, 0, 0.5, 30)), Color3.fromRGB(196, 150, 92), Enum.Material.WoodPlanks
	spawn.Parent = model
	for _, edge in ipairs({ { -45, -45, 45, -45 }, { 45, -45, 45, 45 }, { -45, -45, -45, 45 } }) do
		MapKit.fence(ctx, edge[1], edge[2], edge[3], edge[4])
	end
	-- the title sign and its turning needle
	local title = board("TitleSign", 0, 12, -38, 40, 9)
	text(title, { Size = UDim2.new(1, -40, 0.62, 0), Position = UDim2.new(0, 20, 0.06, 0), Text = "A NEEDLE IN A HAYSTACK", TextColor3 = Color3.fromRGB(255, 214, 90) })
	text(title, { Size = UDim2.new(1, -40, 0.26, 0), Position = UDim2.new(0, 20, 0.68, 0), Text = "Find it first. Win the round.", TextColor3 = Color3.fromRGB(220, 226, 240) })
	local needle = MapKit.part(ctx, { Name = "BigNeedle", Shape = "Cylinder", Size = Vector3.new(16, 0.6, 0.6), CFrame = CFrame.new(MapKit.at(ctx, 0, 21, -38)), Color = { 210, 214, 224 }, Material = "Metal", CanCollide = false })
	TweenService:Create(needle, TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), { CFrame = needle.CFrame * CFrame.Angles(math.pi, 0, 0) }):Play()
	TweenService:Create(needle, TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Position = needle.Position + Vector3.new(0, 1.2, 0) }):Play()
	-- the Play pad
	local pad = MapKit.part(ctx, { Name = "PlayPad", Shape = "Cylinder", Size = Vector3.new(0.4, 18, 18), CFrame = CFrame.new(MapKit.at(ctx, 0, 0.6, 6)) * CFrame.Angles(0, 0, math.rad(90)), Color = { 255, 206, 80 }, Material = "Neon", CanCollide = false })
	local above = Instance.new("BillboardGui")
	above.Size, above.StudsOffset, above.AlwaysOnTop = UDim2.fromOffset(420, 120), Vector3.new(0, 8, 0), false
	above.Parent = pad
	local status = text(above, { Size = UDim2.fromScale(1, 1), TextStrokeTransparency = 0.3, Text = "" })
	task.spawn(function()
		while true do
			local phase = ReplicatedStorage:GetAttribute("Phase")
			local left = (ReplicatedStorage:GetAttribute("EndsAt") or 0) - workspace:GetServerTimeNow()
			status.Text = if phase == "lobby" then "NEXT ROUND IN " .. Rules.clock(left) elseif phase == "search" then "ROUND IN PLAY: " .. Rules.clock(left) else "GET READY..."
			task.wait(0.5)
		end
	end)
	-- the leaderboard: cycles through every board
	local lb = board("Leaderboard", -34, 9, -8, 18, 16)
	local lbTitle = text(lb, { Size = UDim2.new(1, -30, 0.11, 0), Position = UDim2.new(0, 15, 0.02, 0), TextColor3 = Color3.fromRGB(255, 214, 90) })
	local lbRows = {}
	for i = 1, Config.BoardRows do
		lbRows[i] = text(lb, { Size = UDim2.new(1, -40, 0.075, 0), Position = UDim2.new(0, 20, 0.14 + (i - 1) * 0.084, 0), TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.BuilderSans })
	end
	task.spawn(function()
		local i = 0
		while true do
			i = i % #Config.Boards + 1
			local b = Config.Boards[i]
			local rows = LeaderboardManager.cache()[b.id]
			if not rows or #rows == 0 then
				rows = LeaderboardManager.serverRows(b.id)
			end
			lbTitle.Text = b.name
			for r = 1, Config.BoardRows do
				local row = rows[r]
				lbRows[r].Text = if row then r .. ".  " .. row.name .. "  ·  " .. (if b.seconds then string.format("%.1fs", row.value) else Rules.commas(row.value)) else ""
			end
			task.wait(8)
		end
	end)
	-- the daily challenge board
	local dc = board("DailyChallenge", 34, 9, -8, 18, 12)
	text(dc, { Size = UDim2.new(1, -30, 0.16, 0), Position = UDim2.new(0, 15, 0.03, 0), Text = "DAILY CHALLENGE", TextColor3 = Color3.fromRGB(255, 214, 90) })
	local dcRows = {}
	for i = 1, Quests.perDay do
		dcRows[i] = text(dc, { Size = UDim2.new(1, -40, 0.18, 0), Position = UDim2.new(0, 20, 0.22 + (i - 1) * 0.25, 0), TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.BuilderSans })
	end
	task.spawn(function()
		while true do
			for i, q in ipairs(Quests.forDay(Quests.today())) do
				dcRows[i].Text = "• " .. q.text .. "  (+" .. q.coins .. " coins)"
			end
			task.wait(60)
		end
	end)
	stall("ShopStall", -18, 30, "Shop", { 196, 64, 50 })
	stall("Wardrobe", 18, 30, "Inventory", { 76, 106, 170 })
	-- the countryside
	for _, h in ipairs({ { -70, -60 }, { 70, -64 }, { -80, 40 }, { 82, 50 }, { 0, -90 }, { -50, 90 }, { 56, 96 } }) do
		MapKit.haystack(ctx, h[1], h[2], 7, 12)
	end
	for _, b in ipairs({ { -30, 0, -30 }, { 30, 0, -32 }, { -40, 0, 36 }, { 40, 0, 38 } }) do
		MapKit.bale(ctx, b[1], b[2], b[3], ctx.rng:NextNumber() * 3)
	end
	Players.PlayerAdded:Connect(function(player)
		player.RespawnLocation = spawn
	end)
end

return LobbyBuilder

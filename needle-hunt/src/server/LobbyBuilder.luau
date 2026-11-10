-- The lobby, built once at Config.LobbyCentre: a wooden plaza in a field, the animated title sign
-- (a giant needle turns above it), the 4 game platforms (server/PadPortal), a
-- leaderboard that cycles through every board, the Daily Challenge board, a Shop stall and a
-- Wardrobe (their prompts open those screens on the player's own UI), and haystacks round the edge.
-- Paths, fountains, flowers, lamps, trees and the hay yard are in LobbyDecor.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Quests = require(Shared:WaitForChild("Quests"))
local Rules = require(Shared:WaitForChild("Rules"))
local MapKit = require(script.Parent.MapKit)
local PadPortal = require(script.Parent.PadPortal)
local LeaderboardManager = require(script.Parent.LeaderboardManager)
local DataManager = require(script.Parent.DataManager)
local Needles = require(Shared:WaitForChild("Needles"))
local NeedleLook = require(Shared:WaitForChild("NeedleLook"))

local LobbyBuilder = {}
local ctx = nil
local pads = {} -- the game platforms: { part, name, count, status (labels), position }

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

-- The Hall of Needles: three pedestals in front of the title sign showing the most valuable
-- collections in this server, each with its owner's showcase needle turning slowly above it.
function LobbyBuilder.showcase()
	local slots = {}
	local sign = board("HallSign", 0, 4.4, -31, 16, 2.6) -- a banner behind the pedestals, under the title sign
	text(sign, { Size = UDim2.new(1, -30, 1, -14), Position = UDim2.fromOffset(15, 7), Text = "HALL OF NEEDLES", TextColor3 = Color3.fromRGB(255, 214, 90) })
	local rims = { { 200, 206, 216 }, { 255, 200, 70 }, { 205, 140, 90 } } -- 2nd (left), 1st (middle), 3rd (right)
	for i, x in ipairs({ -13, 0, 13 }) do
		local base = MapKit.at(ctx, x, 0, -24)
		local h = if i == 2 then 4.2 else 3.2
		local pedestal = MapKit.part(ctx, { Name = "Pedestal", Shape = "Cylinder", Size = Vector3.new(h, 6, 6), CFrame = CFrame.new(base + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = { 236, 230, 214 }, Material = "Marble" })
		MapKit.part(ctx, { Name = "Rim", Shape = "Cylinder", Size = Vector3.new(0.35, 6.4, 6.4), CFrame = CFrame.new(base + Vector3.new(0, h - 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = rims[i], Material = "Metal" })
		local tag = Instance.new("BillboardGui")
		tag.Size, tag.StudsOffset, tag.MaxDistance = UDim2.fromOffset(240, 70), Vector3.new(0, h / 2 + 5.4, 0), 80
		tag.Parent = pedestal
		local label = text(tag, { Size = UDim2.fromScale(1, 1), TextStrokeTransparency = 0.3, Text = "" })
		slots[i] = { top = base + Vector3.new(0, h + 2.6, 0), label = label, model = nil, key = nil }
	end
	local order = { 2, 1, 3 } -- the best in the middle, on the tallest
	task.spawn(function()
		local spin = 0
		while true do
			local ranked = {}
			for _, p in ipairs(Players:GetPlayers()) do
				local d = DataManager.get(p)
				if d and d.showcase ~= "" then
					table.insert(ranked, { player = p, value = Needles.total(d.collection), key = d.showcase })
				end
			end
			table.sort(ranked, function(a, b)
				return a.value > b.value
			end)
			for rank, slotIndex in ipairs(order) do
				local slot, entry = slots[slotIndex], ranked[rank]
				local key = entry and (entry.player.UserId .. entry.key)
				if key ~= slot.key then
					if slot.model then
						slot.model:Destroy()
						slot.model = nil
					end
					slot.key = key
					if entry then
						local t, s = Needles.split(entry.key)
						slot.model = NeedleLook.build(t, s, 1.5, 2) -- the longest (knitting) is about 4.5 studs: it fits the 6-stud top
						slot.model.Parent = ctx.model
					end
				end
				slot.label.Text = if entry then entry.player.DisplayName .. "\n" .. Rules.commas(entry.value) .. " collection value" else ""
			end
			for _ = 1, 50 do -- turn the needles slowly for 5 seconds, then look again
				spin += 0.04
				for _, slot in ipairs(slots) do
					if slot.model then
						slot.model:PivotTo(CFrame.new(slot.top) * CFrame.Angles(0, spin, math.rad(20)))
					end
				end
				task.wait(0.1)
			end
		end
	end)
end

function LobbyBuilder.pads()
	return pads
end

function LobbyBuilder.spawnPoint(i)
	local a = (i or 1) * 2.399 -- spread out round the pad
	return CFrame.new(MapKit.at(ctx, math.cos(a) * 10, 3, 25 + math.sin(a) * 3)) -- just behind the game platforms
end

function LobbyBuilder.build()
	local model = Instance.new("Model")
	model.Name = "Lobby"
	model.Parent = workspace
	ctx = { model = model, rng = Random.new(7), centre = Config.LobbyCentre, def = { straw = { 226, 188, 92 } }, spots = {}, spawns = {}, floorY = 0 }
	MapKit.ground(ctx, 260, 260, { 104, 160, 76 }, "Grass")
	MapKit.edges(ctx, 90, 90, { 104, 160, 76 }) -- a hedge all the way round: nobody wanders off
	MapKit.part(ctx, { Name = "Plaza", Size = Vector3.new(170, 0.4, 170), CFrame = CFrame.new(MapKit.at(ctx, 0, 0.2, 0)), Color = { 116, 172, 82 }, Material = "Grass" }) -- a lawn (LobbyDecor lays the paths)
	-- you arrive at the front, facing the Champion's Needle (server/LobbySocial) and the Play pad
	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored, spawn.Size, spawn.Duration, spawn.Neutral = true, Vector3.new(12, 1, 12), 0, true
	spawn.CFrame, spawn.Color, spawn.Material = CFrame.new(MapKit.at(ctx, 0, 0.5, 72)), Color3.fromRGB(196, 150, 92), Enum.Material.WoodPlanks
	spawn.Parent = model
	for _, b in ipairs({ { -30, 56, 0 }, { 30, 56, 0 }, { -38, -6, 90 }, { 38, -6, 90 } }) do -- benches to sit and chat
		local seat = Instance.new("Seat")
		seat.Anchored, seat.Size, seat.Color, seat.Material = true, Vector3.new(8, 1, 2.4), Color3.fromRGB(140, 98, 58), Enum.Material.WoodPlanks
		seat.CFrame = CFrame.new(MapKit.at(ctx, b[1], 1.5, b[2])) * CFrame.Angles(0, math.rad(b[3]), 0)
		seat.Parent = model
		MapKit.part(ctx, { Name = "BenchBack", Size = Vector3.new(8, 2.4, 0.4), CFrame = seat.CFrame * CFrame.new(0, 1.4, 1.1), Color = { 120, 84, 50 }, Material = "WoodPlanks" })
	end
	-- the title sign and its turning needle
	local title = board("TitleSign", 0, 14, -54, 40, 9) -- well behind the Hall, so its needles stand clear
	text(title, { Size = UDim2.new(1, -40, 0.62, 0), Position = UDim2.new(0, 20, 0.06, 0), Text = "A NEEDLE IN A HAYSTACK", TextColor3 = Color3.fromRGB(255, 214, 90) })
	text(title, { Size = UDim2.new(1, -40, 0.26, 0), Position = UDim2.new(0, 20, 0.68, 0), Text = "Open the chests. Win the round.", TextColor3 = Color3.fromRGB(220, 226, 240) })
	local needle = MapKit.part(ctx, { Name = "BigNeedle", Shape = "Cylinder", Size = Vector3.new(16, 0.6, 0.6), CFrame = CFrame.new(MapKit.at(ctx, 0, 23, -54)), Color = { 210, 214, 224 }, Material = "Metal", CanCollide = false })
	TweenService:Create(needle, TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), { CFrame = needle.CFrame * CFrame.Angles(math.pi, 0, 0) }):Play()
	TweenService:Create(needle, TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Position = needle.Position + Vector3.new(0, 1.2, 0) }):Play()
	-- the game platforms (server/GamePads runs them): stand on one to join its game
	for i = 1, Config.Pads.count do
		pads[i] = PadPortal.build(ctx, i, (i - (Config.Pads.count + 1) / 2) * Config.Pads.spacing, Config.Pads.z, text)
	end
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
	LobbyBuilder.showcase()
	stall("ShopStall", -18, 30, "Shop", { 196, 64, 50 })
	stall("Wardrobe", 18, 30, "Inventory", { 76, 106, 170 })
	stall("BoxStall", -34, 30, "Boxes", { 230, 120, 50 })
	stall("PracticeStall", 34, 30, "Practice", { 150, 20, 20 }) -- the Time Trial (server/Practice)
	require(script.Parent.LobbySocial).build(ctx, text)
	require(script.Parent.LobbyDecor).build(ctx)
	-- the countryside beyond the hedge, and a few bales on the plaza
	for _, h in ipairs({ { -110, -80 }, { 110, -84 }, { -120, 40 }, { 122, 50 }, { 0, -120 }, { -70, 115 }, { 76, 118 } }) do
		MapKit.haystack(ctx, h[1], h[2], 7, 12)
	end
	for _, b in ipairs({ { -30, 0, -30 }, { 30, 0, -32 }, { -44, 0, 30 }, { 44, 0, 32 } }) do
		MapKit.bale(ctx, b[1], b[2], b[3], ctx.rng:NextNumber() * 3)
	end
	Players.PlayerAdded:Connect(function(player)
		player.RespawnLocation = spawn
	end)
end

return LobbyBuilder

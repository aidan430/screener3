-- The lobby's social side: showing off collections.
--   The Champion's Needle: a tall podium right in front of where you arrive, with the single most
--     valuable needle anyone in the server owns, big and glowing, and whose it is.
--   Booths: down both sides of the plaza, every player gets a booth (claimed on join) with their
--     three most valuable needles on show; its prompt opens their Collection for anyone.
--   Tags: over each player's head, their best needle in its rarity colour; the champion gets a
--     crown line. Hidden while a round is being searched, so they never get in the way.
--   Show off: see server/LobbyShowOff.
-- Remotes.LobbyInfo "best" tells a joining player who has the most valuable needle.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Needles = require(Shared:WaitForChild("Needles"))
local NeedleLook = require(Shared:WaitForChild("NeedleLook"))
local Rules = require(Shared:WaitForChild("Rules"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local MapKit = require(script.Parent.MapKit)
local DataManager = require(script.Parent.DataManager)

local LobbySocial = {}
local ctx, text
local booths = {} -- { player, models, title, line, prompt }
local champion = nil -- { player, key, value }

local function rgb(c)
	return Color3.fromRGB(c[1], c[2], c[3])
end

-- A player's needles, most valuable first: { key, type, skin, value }.
function LobbySocial.ranked(d)
	local list = {}
	for key in pairs(d.collection) do
		local t, s = Needles.split(key)
		if t then
			table.insert(list, { key = key, type = t, skin = s, value = Needles.value(t, s) })
		end
	end
	table.sort(list, function(a, b)
		return a.value > b.value
	end)
	return list
end

function LobbySocial.describe(entry)
	local skin = Needles.skin(entry.skin)
	return Needles.rarity(skin.rarity).name .. " " .. Needles.name(entry.type, entry.skin), rgb(Needles.rarity(skin.rarity).colour)
end

-- Who has the most valuable needle in the server right now.
function LobbySocial.best()
	local top = nil
	for _, p in ipairs(Players:GetPlayers()) do
		local d = DataManager.get(p)
		local list = d and LobbySocial.ranked(d)
		if list and list[1] and (not top or list[1].value > top.entry.value) then
			top = { player = p, entry = list[1] }
		end
	end
	return top
end

local function tag(player, d, isChampion, visible)
	local head = player.Character and player.Character:FindFirstChild("Head")
	if not head then
		return
	end
	local gui = head:FindFirstChild("LobbyTag")
	if not gui then
		gui = Instance.new("BillboardGui")
		gui.Name, gui.Size, gui.StudsOffset, gui.MaxDistance = "LobbyTag", UDim2.fromOffset(260, 64), Vector3.new(0, 4.2, 0), 70
		gui.Parent = head
		local layout = Instance.new("UIListLayout")
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.Parent = gui
		for i, name in ipairs({ "Crown", "Best" }) do
			local l = Instance.new("TextLabel")
			l.Name, l.LayoutOrder, l.BackgroundTransparency, l.Size = name, i, 1, UDim2.new(1, 0, 0, if i == 1 then 26 else 22)
			l.Font, l.TextScaled, l.TextStrokeTransparency = Enum.Font.BuilderSansBold, true, 0.35
			l.Parent = gui
		end
	end
	gui.Enabled = visible
	local best = LobbySocial.ranked(d)[1]
	gui.Crown.Text, gui.Crown.TextColor3, gui.Crown.Visible = "♛ MOST VALUABLE NEEDLE", Color3.fromRGB(255, 205, 70), isChampion
	if best then
		local words, colour = LobbySocial.describe(best)
		gui.Best.Text, gui.Best.TextColor3 = "Best: " .. words .. " · " .. Rules.commas(best.value), colour
	else
		gui.Best.Text, gui.Best.TextColor3 = "No needles yet", Color3.fromRGB(200, 205, 215)
	end
end

local function clearModels(list)
	for _, m in ipairs(list) do
		m:Destroy()
	end
	table.clear(list)
end

local function buildBooth(i, x, z)
	local pos = MapKit.at(ctx, x, 0, z)
	local face = CFrame.lookAt(pos, MapKit.at(ctx, 0, 0, z)) -- facing the middle of the plaza
	MapKit.part(ctx, { Name = "BoothCounter", Size = Vector3.new(10, 3, 3), CFrame = face * CFrame.new(0, 1.5, -1), Color = { 150, 106, 64 }, Material = "WoodPlanks" })
	MapKit.part(ctx, { Name = "BoothBack", Size = Vector3.new(11, 9, 0.6), CFrame = face * CFrame.new(0, 4.5, 2.2), Color = { 120, 84, 50 }, Material = "WoodPlanks" })
	local glass = MapKit.part(ctx, { Name = "BoothShelf", Size = Vector3.new(9.4, 0.3, 2.4), CFrame = face * CFrame.new(0, 3.15, -1), Color = { 236, 230, 214 }, Material = "Marble" })
	local plate = MapKit.part(ctx, { Name = "BoothSign", Size = Vector3.new(11, 2.6, 0.6), CFrame = face * CFrame.new(0, 10.3, 2.2), Color = { 96, 66, 40 }, Material = "Wood" })
	local surface = Instance.new("SurfaceGui")
	surface.Face, surface.SizingMode, surface.PixelsPerStud, surface.LightInfluence = Enum.NormalId.Front, Enum.SurfaceGuiSizingMode.PixelsPerStud, 30, 0.1
	surface.Parent = plate
	local sign = Instance.new("Frame")
	sign.Size, sign.Position, sign.BackgroundColor3 = UDim2.new(1, -12, 1, -12), UDim2.fromOffset(6, 6), Color3.fromRGB(30, 34, 44)
	sign.Parent = surface
	local title = text(sign, { Size = UDim2.new(1, -20, 0.6, 0), Position = UDim2.fromOffset(10, 4), Text = "Free booth", TextColor3 = Color3.fromRGB(255, 214, 90) })
	local line = text(sign, { Size = UDim2.new(1, -20, 0.36, 0), Position = UDim2.new(0, 10, 0.62, 0), Text = "Join and it's yours", Font = Enum.Font.BuilderSans })
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText, prompt.ObjectText, prompt.HoldDuration, prompt.MaxActivationDistance, prompt.Enabled = "View collection", "", 0, 12, false
	prompt.Parent = glass
	booths[i] = { player = nil, models = {}, keys = "", title = title, line = line, prompt = prompt, face = face }
end

local function fillBooth(b)
	local d = b.player and DataManager.get(b.player)
	if not d then
		clearModels(b.models)
		b.keys = ""
		b.title.Text, b.line.Text, b.prompt.Enabled = "Free booth", "Join and it's yours", false
		return
	end
	local list = LobbySocial.ranked(d)
	local keys = (list[1] and list[1].key or "") .. (list[2] and list[2].key or "") .. (list[3] and list[3].key or "")
	b.title.Text = b.player.DisplayName .. "'s collection"
	b.line.Text = Rules.commas(Needles.total(d.collection)) .. " value  ·  press E to look"
	b.prompt.ObjectText, b.prompt.Enabled = b.player.DisplayName, true
	b.prompt:SetAttribute("ViewUser", b.player.UserId)
	if keys == b.keys then
		return -- the same three needles: leave them be
	end
	b.keys = keys
	clearModels(b.models)
	for slot, entry in ipairs(list) do
		if slot > 3 then
			break
		end
		local m = NeedleLook.build(entry.type, entry.skin, 1.35, 2)
		m:PivotTo(b.face * CFrame.new((slot - 2) * 3.1, 4.4, -1) * CFrame.Angles(0, math.pi / 2, math.rad(50)))
		m.Parent = ctx.model
		table.insert(b.models, m)
	end
end

local function buildChampion()
	local base = MapKit.at(ctx, 0, 0, 48)
	MapKit.part(ctx, { Name = "ChampionPodium", Shape = "Cylinder", Size = Vector3.new(6, 8, 8), CFrame = CFrame.new(base + Vector3.new(0, 3, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = { 236, 230, 214 }, Material = "Marble" })
	MapKit.part(ctx, { Name = "ChampionRim", Shape = "Cylinder", Size = Vector3.new(0.4, 8.5, 8.5), CFrame = CFrame.new(base + Vector3.new(0, 5.9, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = { 255, 200, 70 }, Material = "Metal" })
	local anchor = MapKit.part(ctx, { Name = "ChampionLabel", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(base + Vector3.new(0, 13.5, 0)), Transparency = 1, CanCollide = false })
	local gui = Instance.new("BillboardGui")
	gui.Size, gui.MaxDistance = UDim2.fromOffset(420, 120), 140
	gui.Parent = anchor
	local lines = {}
	for i, size in ipairs({ 36, 30, 26 }) do
		lines[i] = text(gui, { Size = UDim2.new(1, 0, 0, size), Position = UDim2.fromOffset(0, (i - 1) * 38), TextStrokeTransparency = 0.3 })
	end
	lines[1].Text, lines[1].TextColor3 = "MOST VALUABLE NEEDLE HERE", Color3.fromRGB(255, 205, 70)
	local light = Instance.new("PointLight")
	light.Range, light.Brightness = 16, 1.5
	light.Parent = anchor
	return base + Vector3.new(0, 9.5, 0), lines, light
end

local function refresh(top, lines, light, state)
	local key = top and (top.player.UserId .. top.entry.key)
	if key ~= state.key then
		if state.model then
			state.model:Destroy()
			state.model = nil
		end
		state.key = key
		if top then
			state.model = NeedleLook.build(top.entry.type, top.entry.skin, 3, 2)
			state.model.Parent = ctx.model
		end
	end
	if top then
		local words, colour = LobbySocial.describe(top.entry)
		lines[2].Text, lines[2].TextColor3 = words, colour
		lines[3].Text = "owned by " .. top.player.DisplayName .. "  ·  worth " .. Rules.commas(top.entry.value)
		light.Color = colour
	else
		lines[2].Text, lines[3].Text = "Nobody's found one yet", "Win a round and it could be yours"
	end
end

function LobbySocial.build(lobbyCtx, textFn)
	ctx, text = lobbyCtx, textFn
	local i = 0
	for _, x in ipairs({ -66, 66 }) do
		for _, z in ipairs({ -50, -30, -10, 10, 30, 50 }) do
			i += 1
			buildBooth(i, x, z)
		end
	end
	local top, lines, light = buildChampion()
	local state = { key = nil, model = nil }
	local function assign(player)
		for _, b in ipairs(booths) do
			if b.player == player then
				return
			end
		end
		for _, b in ipairs(booths) do
			if not b.player then
				b.player = player
				return
			end
		end
	end
	DataManager.onLoaded(assign)
	Players.PlayerRemoving:Connect(function(player)
		for _, b in ipairs(booths) do
			if b.player == player then
				b.player = nil
				fillBooth(b)
			end
		end
	end)
	Remotes.LobbyInfo.OnServerInvoke = function(_player, action)
		if action == "best" then
			local best = LobbySocial.best()
			if best then
				local words = LobbySocial.describe(best.entry)
				return { name = best.player.DisplayName, userId = best.player.UserId, needle = words, type = best.entry.type, skin = best.entry.skin, value = best.entry.value }
			end
		end
		return nil
	end
	task.spawn(function() -- every 3 seconds: booths, tags and the champion
		local spin = 0
		while true do
			local best = LobbySocial.best()
			refresh(best, lines, light, state)
			local phase = ReplicatedStorage:GetAttribute("Phase")
			local tagsOn = phase ~= "search" and phase ~= "countdown"
			for _, b in ipairs(booths) do
				fillBooth(b)
			end
			for _, p in ipairs(Players:GetPlayers()) do
				local d = DataManager.get(p)
				if d then
					tag(p, d, best ~= nil and best.player == p, tagsOn)
				end
			end
			for _ = 1, 30 do -- turn the champion's needle
				spin += 0.03
				if state.model then
					state.model:PivotTo(CFrame.new(top + Vector3.new(0, math.sin(spin * 2) * 0.4, 0)) * CFrame.Angles(0, spin, math.rad(25)))
				end
				task.wait(0.1)
			end
		end
	end)
end

return LobbySocial

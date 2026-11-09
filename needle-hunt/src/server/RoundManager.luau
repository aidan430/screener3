-- The round loop, all on the server:
--   lobby (Config.Round.lobbyCountdown) -> loading: pick a map, difficulty, modifier and maybe a
--   Golden Needle, build the map, hide the needle(s), move everyone in -> countdown (3, 2, 1;
--   nobody moves) -> search (the timer runs; a player "finishes" when they've found every
--   needle; after the first finish, everyone else has Config.Round.grace seconds) -> results ->
--   back to the lobby. A lone player still gets rounds (practice).
-- The phase is published as attributes on ReplicatedStorage (Phase, EndsAt, MapName,
-- Difficulty, Modifiers, Golden, NeedleCount) and announced with Remotes.RoundState.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Rules = require(Shared:WaitForChild("Rules"))
local Maps = require(Shared:WaitForChild("Maps"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local DataManager = require(script.Parent.DataManager)
local NeedleSpawner = require(script.Parent.NeedleSpawner)
local RewardManager = require(script.Parent.RewardManager)
local CollectionManager = require(script.Parent.CollectionManager)
local AntiCheat = require(script.Parent.AntiCheat)
local MapKit = require(script.Parent.MapKit)
local LobbyBuilder = require(script.Parent.LobbyBuilder)
local builders = require(script.Parent.MapsA)
for name, fn in pairs(require(script.Parent.MapsB)) do
	builders[name] = fn
end

local RoundManager = {}
local rng = Random.new()
local round = nil -- the round in play: { participants, finished, foundBy, needles, started, duration, diff, golden, ... }
local lastMap = nil

local function now()
	return workspace:GetServerTimeNow()
end

local function phase(name, seconds, extra)
	ReplicatedStorage:SetAttribute("Phase", name)
	ReplicatedStorage:SetAttribute("EndsAt", now() + (seconds or 0))
	Remotes.RoundState:FireAllClients({ phase = name, endsAt = now() + (seconds or 0), extra = extra })
end

local function light(spec, dim)
	for key, value in pairs(spec) do
		Lighting[key] = if type(value) == "table" then Color3.fromRGB(value[1], value[2], value[3]) else value
	end
	if dim and dim > 0 then
		Lighting.Brightness *= 1 - dim
		Lighting.Ambient = Lighting.Ambient:Lerp(Color3.new(0, 0, 0), dim)
		Lighting.OutdoorAmbient = Lighting.OutdoorAmbient:Lerp(Color3.new(0, 0, 0), dim)
	end
end

local function humanoid(player)
	local c = player.Character
	return c and c:FindFirstChildOfClass("Humanoid"), c
end

local function freeze(player, on)
	local h = humanoid(player)
	if h then
		h.WalkSpeed = if on then 0 else 16
		h.JumpHeight = if on then 0 else 7.2
	end
end

local function move(player, cf)
	local h, c = humanoid(player)
	if h and c and h.Health > 0 then
		AntiCheat.allow(player, 3)
		c:PivotTo(cf)
	end
end

-- Players who'll play this round: loaded, alive, and not sitting out (Settings: Auto-join).
local function players()
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local d = DataManager.get(p)
		local h = humanoid(p)
		if d and d.settings.autoJoin and h and h.Health > 0 then
			table.insert(list, p)
		end
	end
	return list
end

-- A claim on needle `n` by `player` (already checked by NeedleSpawner).
local function onClaim(player, n)
	local r = round
	if not r or not r.participants[player] or r.finished[player] then
		return
	end
	r.foundBy[n.index] = r.foundBy[n.index] or {}
	if r.foundBy[n.index][player] then
		return
	end
	r.foundBy[n.index][player] = true
	local elapsed = now() - r.started
	RewardManager.found(player, elapsed, n.golden)
	local count = 0
	for i = 1, #r.needles do
		if r.foundBy[i] and r.foundBy[i][player] then
			count += 1
		end
	end
	player:SetAttribute("Found", count)
	if count < #r.needles then
		Remotes.Notify:FireClient(player, { text = "One down! " .. (#r.needles - count) .. " to go.", tone = "good" })
		return
	end
	table.insert(r.order, player)
	r.finished[player] = elapsed
	local place = #r.order
	local coins, xp = RewardManager.placed(player, place, elapsed, r.duration, r.diff, r.golden, r.count)
	local kept = CollectionManager.award(player, place, r.diff, r.golden)
	r.rewards[player] = { coins = coins, xp = xp, kept = kept }
	Remotes.Found:FireAllClients({ userId = player.UserId, name = player.DisplayName, place = place, seconds = elapsed, golden = r.golden, position = n.position, coins = coins, xp = xp, kept = kept })
	if place == 1 then
		r.graceEnds = now() + Config.Round.grace
		ReplicatedStorage:SetAttribute("EndsAt", math.min(r.ends, r.graceEnds))
	end
end

local function pickModifiers()
	local mods = {}
	if rng:NextNumber() < Config.ModifierChance then
		mods[Rules.pick(Config.Modifiers, rng).id] = true
	end
	return mods
end

local function playRound()
	-- choose and build
	local options = {}
	for _, m in ipairs(Maps.list) do
		if m.id ~= lastMap or #Maps.list == 1 then
			table.insert(options, m)
		end
	end
	local def = Rules.pick(options, rng)
	lastMap = def.id
	local diff = Rules.pick(Config.Difficulty, rng)
	local mods = pickModifiers()
	local golden = rng:NextNumber() < Config.GoldenChance
	local old = workspace:FindFirstChild("Arena")
	if old then
		old:Destroy()
	end
	MapKit.clearTerrain(Config.ArenaCentre) -- the last map's haystacks
	local model = Instance.new("Model")
	model.Name = "Arena"
	model.Parent = workspace
	local ctx = { model = model, rng = Random.new(rng:NextInteger(1, 2 ^ 30)), centre = Config.ArenaCentre, def = def, spots = {}, spawns = {}, floorY = 0, diff = diff }
	local modNames = {}
	for _, m in ipairs(Config.Modifiers) do
		if mods[m.id] then
			table.insert(modNames, m.name)
		end
	end
	ReplicatedStorage:SetAttribute("MapName", def.name)
	ReplicatedStorage:SetAttribute("Difficulty", diff.name)
	ReplicatedStorage:SetAttribute("Modifiers", table.concat(modNames, ", "))
	ReplicatedStorage:SetAttribute("Golden", golden)
	phase("loading", 3)
	builders[def.builder](ctx)
	local needles = NeedleSpawner.spawn(ctx, diff, { modifiers = mods, golden = golden })
	ReplicatedStorage:SetAttribute("NeedleCount", #needles)
	light(def.lighting, diff.dim + (if mods.lowlight then 0.45 else 0))
	-- move everyone in
	local list = players()
	if #list == 0 or #needles == 0 then
		light(Maps.lobbyLighting)
		model:Destroy()
		MapKit.clearTerrain(Config.ArenaCentre)
		return
	end
	local duration = if mods.speed then Config.Round.speedDuration else Config.Round.duration
	round = { participants = {}, finished = {}, foundBy = {}, order = {}, rewards = {}, needles = needles, diff = diff, golden = golden, duration = duration, count = #list, spawns = ctx.spawns }
	for i, p in ipairs(list) do
		round.participants[p] = true
		p:SetAttribute("Found", 0)
		move(p, ctx.spawns[(i - 1) % #ctx.spawns + 1])
		freeze(p, true)
	end
	phase("countdown", Config.Round.loadCountdown)
	task.wait(Config.Round.loadCountdown)
	for p in pairs(round.participants) do
		freeze(p, false)
	end
	round.started = now()
	round.ends = round.started + duration
	phase("search", duration)
	-- search until time is up, the grace window closes or everyone has finished
	while true do
		task.wait(0.25)
		local remaining = 0
		for p in pairs(round.participants) do
			if p.Parent and not round.finished[p] then
				remaining += 1
			end
		end
		local t = now()
		if t >= round.ends or (round.graceEnds and t >= round.graceEnds) or remaining == 0 then
			break
		end
	end
	-- results and rewards for playing
	local rows = {}
	for place, p in ipairs(round.order) do
		local r = round.rewards[p] or { coins = 0, xp = 0 }
		table.insert(rows, { name = p.DisplayName, userId = p.UserId, place = place, seconds = round.finished[p], coins = r.coins, xp = r.xp, kept = r.kept })
	end
	for p in pairs(round.participants) do
		if p.Parent then
			RewardManager.played(p, diff, round.order[1] == p)
		end
	end
	phase("results", Config.Round.results, { rows = rows, map = def.name, golden = golden })
	NeedleSpawner.clear()
	task.wait(Config.Round.results)
	for i, p in ipairs(Players:GetPlayers()) do
		if round.participants[p] then
			move(p, LobbyBuilder.spawnPoint(i))
		end
	end
	round = nil
	model:Destroy()
	MapKit.clearTerrain(Config.ArenaCentre)
	light(Maps.lobbyLighting)
end

-- The round in play (nil between rounds), for server/Requests.
function RoundManager.current()
	return round
end

function RoundManager.start()
	NeedleSpawner.onClaim = onClaim
	NeedleSpawner.canClaim = function(player)
		return round ~= nil and round.participants[player] == true and ReplicatedStorage:GetAttribute("Phase") == "search"
	end
	Players.PlayerRemoving:Connect(function(player)
		if round then
			round.participants[player] = nil
		end
	end)
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.3) -- a participant who respawns goes back into the round's map
			if round and round.participants[player] and round.spawns and #round.spawns > 0 then
				move(player, round.spawns[rng:NextInteger(1, #round.spawns)])
			end
		end)
	end)
	light(Maps.lobbyLighting)
	task.spawn(function()
		while true do
			phase("lobby", Config.Round.lobbyCountdown)
			task.wait(Config.Round.lobbyCountdown)
			if #players() >= Config.Round.minPlayers then
				local ok, err = pcall(playRound)
				if not ok then
					warn("[Round] " .. tostring(err))
					for i, p in ipairs(Players:GetPlayers()) do -- nobody is left in a broken map
						freeze(p, false)
						move(p, LobbyBuilder.spawnPoint(i))
					end
					round = nil
					NeedleSpawner.clear()
					light(Maps.lobbyLighting)
				end
			end
		end
	end)
end

return RoundManager

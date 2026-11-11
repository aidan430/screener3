-- A round, all on the server, for a group of players (RoundManager.play: a game platform's
-- players, server/GamePads, or everyone on a game's own server, server/GameServer):
--   loading: pick a map, difficulty, modifier and maybe a Golden Chest, build the map, place the
--   chests (server/ChestSpawner), move the players in -> countdown (3, 2, 1; nobody moves) -> the
--   round (the timer runs; open chests for coins and power-ups, poke and throw needles; once the
--   last chest is open, everyone has Config.Round.grace seconds) -> results (places by chests,
--   tag-outs, coins) -> the lobby.
-- The phase is published as attributes on ReplicatedStorage (Phase, EndsAt, MapName,
-- Difficulty, Modifiers, Golden, ChestsLeft, ChestCount) and announced with Remotes.RoundState.
-- The search phase is still called "search" (the name other scripts check).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Rules = require(Shared:WaitForChild("Rules"))
local Maps = require(Shared:WaitForChild("Maps"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local DataManager = require(script.Parent.DataManager)
local ChestSpawner = require(script.Parent.ChestSpawner)
local Powerups = require(script.Parent.Powerups) -- a chest's power-up is used at once
local RewardManager = require(script.Parent.RewardManager)
local AntiCheat = require(script.Parent.AntiCheat)
local MapKit = require(script.Parent.MapKit)
local Look = require(script.Parent.Look)
local RoundExtras = require(script.Parent.RoundExtras)
local LobbyBuilder = require(script.Parent.LobbyBuilder)
local builders = require(script.Parent.MapsA)
for name, fn in pairs(require(script.Parent.MapsB)) do
	builders[name] = fn
end
for name, fn in pairs(require(script.Parent.MapsC)) do -- the maps from the Gemini sheets
	builders[name] = fn
end
for name, fn in pairs(require(script.Parent.MapsD)) do
	builders[name] = fn
end
for name, fn in pairs(require(script.Parent.MapsBig)) do -- Hayfield Farm
	builders[name] = fn
end

local RoundManager = {}
local rng = Random.new()
local round = nil -- the round in play: { participants, chests, chestsLeft, started, ends, duration, diff, modifiers, golden, ... }
local lastMap = nil
local playing = false -- a round is being built or played (RoundManager.play)

local function now()
	return workspace:GetServerTimeNow()
end

local function phase(name, seconds, extra)
	ReplicatedStorage:SetAttribute("Phase", name)
	ReplicatedStorage:SetAttribute("EndsAt", now() + (seconds or 0))
	Remotes.RoundState:FireAllClients({ phase = name, endsAt = now() + (seconds or 0), extra = extra })
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

-- Of a group, the players who can play: still here, loaded, alive and not in the Practice Yard, up
-- to Config.Round.maxPlayers.
local function players(group)
	local list = {}
	for _, p in ipairs(group) do
		local h = humanoid(p)
		if p.Parent and DataManager.get(p) and h and h.Health > 0 and not p:GetAttribute("Practicing") and #list < Config.Round.maxPlayers then
			table.insert(list, p)
		end
	end
	return list
end

-- A chest opened by `player` (already checked by ChestSpawner): give what was inside, tell
-- everyone, and when it was the last one start the closing countdown.
local function onOpen(player, chest, reward)
	local r = round
	if not r or not r.participants[player] then
		return
	end
	local got = RewardManager.chest(player, reward) -- coins and/or a power-up: chests never hold a needle
	if reward.powerup then
		Powerups.give(player, reward.powerup)
	end
	r.chestsLeft -= 1
	ReplicatedStorage:SetAttribute("ChestsLeft", r.chestsLeft)
	Remotes.Found:FireAllClients({ userId = player.UserId, name = player.DisplayName, golden = chest.golden, position = chest.position, got = got, left = r.chestsLeft })
	if r.chestsLeft <= 0 and not r.graceEnds then
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

local function playRound(group)
	-- choose and build
	local options = {}
	for _, m in ipairs(Maps.list) do
		if m.id ~= lastMap or #Maps.list == 1 then
			table.insert(options, m)
		end
	end
	local def = if Config.Round.onlyMap then Maps.get(Config.Round.onlyMap) else Rules.pick(options, rng)
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
	local list = players(group)
	local full = def.duration or Config.Round.duration -- a big map has longer
	local duration = if mods.speed then math.floor(full / 2) else full
	round = { participants = {}, order = {}, diff = diff, modifiers = mods, golden = golden, duration = duration, count = #list, spawns = ctx.spawns }
	local chests = ChestSpawner.spawn(ctx, round)
	round.chests, round.chestsLeft = chests, #chests
	ReplicatedStorage:SetAttribute("ChestCount", #chests)
	ReplicatedStorage:SetAttribute("ChestsLeft", #chests)
	Look.apply(def.look, diff.dim + (if mods.lowlight then 0.45 else 0))
	-- move everyone in
	if #list == 0 or #chests == 0 then
		round = nil
		ChestSpawner.clear()
		Look.apply(Maps.lobbyLook)
		model:Destroy()
		MapKit.clearTerrain(Config.ArenaCentre)
		return
	end
	for i, p in ipairs(list) do
		round.participants[p] = true
		p:SetAttribute("InRound", true)
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
	RoundExtras.start(ctx, round)
	-- play until time is up, the closing countdown after the last chest ends, or nobody's left
	while true do
		task.wait(0.25)
		local t = now()
		if t >= round.ends or (round.graceEnds and t >= round.graceEnds) or next(round.participants) == nil then
			break
		end
	end
	-- places, coins and XP, then the results
	local rows, xp = RoundExtras.finish(round)
	for p in pairs(round.participants) do
		if p.Parent then
			RewardManager.played(p, diff, round.order[1] == p)
		end
	end
	phase("results", Config.Round.results, { rows = rows, map = def.name, golden = golden, xp = xp })
	ChestSpawner.clear()
	RoundExtras.stop()
	task.wait(Config.Round.results)
	for i, p in ipairs(Players:GetPlayers()) do
		if round.participants[p] then
			p:SetAttribute("InRound", false)
			move(p, LobbyBuilder.spawnPoint(i))
		end
	end
	round = nil
	model:Destroy()
	MapKit.clearTerrain(Config.ArenaCentre)
	Look.apply(Maps.lobbyLook)
end

-- The round in play (nil between rounds), for server/Requests.
function RoundManager.current()
	return round
end

function RoundManager.start()
	ChestSpawner.onOpen = onOpen
	ChestSpawner.canOpen = function(player)
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
	Look.apply(Maps.lobbyLook)
	phase("waiting", 0)
end

-- Is a round being played on this server?
function RoundManager.busy()
	return round ~= nil or playing
end

-- Plays one round for `group` (a list of players) and returns when it's over. A round that breaks
-- puts everyone back in the lobby.
function RoundManager.play(group)
	if RoundManager.busy() then
		return false
	end
	playing = true
	local ok, err = pcall(playRound, group)
	if not ok then
		warn("[Round] " .. tostring(err))
		for i, p in ipairs(group) do -- nobody is left in a broken map
			if p.Parent then
				p:SetAttribute("InRound", false)
				freeze(p, false)
				move(p, LobbyBuilder.spawnPoint(i))
			end
		end
		round = nil
		ChestSpawner.clear()
		RoundExtras.stop()
		Look.apply(Maps.lobbyLook)
	end
	playing = false
	phase("waiting", 0)
	return true
end

return RoundManager

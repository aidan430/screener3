-- The lobby, Sky Meadow (Config.Lobby): where everyone arrives on joining. Five walk-in arches
-- in a semicircle lead to your farm (free) and the four worlds (opened once with coins:
-- Worlds.open). Walking into any arch tagged "WalkPortal" (here, the one on the farm, and each
-- world's way back) travels: the server checks and moves you, your screen fades softly. A
-- locked world's arch doesn't move you: your screen offers to open it (client/Lobby.luau) and
-- eases you back out; Open asks the server, which checks and takes the coins.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local PlayerData = require(script.Parent.PlayerData)
local Kit = require(script.Parent.WorldsKit)
local Island = require(script.Parent.LobbyIsland)
local Worlds = require(script.Parent.Worlds)

local Lobby = {}
local away = {} -- [player] = true once they've left the lobby (they then respawn on the farm)
local lastTrip, lastAsk = {}, {} -- [player] = os.clock() of their last trip / open request
local archFront = {} -- [arch id] = where you land coming back through that arch's world
local lobbySpawn = nil
local toFarm = nil -- Main's toPlot: to your farm's entrance

local function centre()
	local l = Config.Lobby
	return Vector3.new(l.x, l.floor, l.z)
end

-- Where you arrive on joining: south of the fountain, facing the arches.
local function arrivalSpot()
	local a = Config.LobbyArrival
	local here = centre() + Vector3.new(a[1], 4, a[2])
	return CFrame.lookAt(here, here + Vector3.new(0, 0, -1))
end

local function rootOf(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function notice(player, text)
	Remotes.Announce:FireClient(player, { kind = "notice", text = text })
end

function Lobby.inLobby(position, reach)
	local c = centre()
	return Vector3.new(position.X - c.X, 0, position.Z - c.Z).Magnitude < (reach or Config.LobbyInside)
end

-- Left the lobby (or back in it): respawns go to the farm's spawn (or the lobby's).
local function setAway(player, isAway)
	away[player] = isAway or nil
	local farmSpawn = workspace:FindFirstChild("Spawn")
	local spot = if isAway then farmSpawn else lobbySpawn
	if spot and spot:IsA("SpawnLocation") then
		player.RespawnLocation = spot
	end
end

function Lobby.isIn(player)
	return not away[player]
end

function Lobby.leave(player)
	setAway(player, true)
end

-- Moves the player (to a CFrame, or by calling `go`) behind a soft fade on their screen.
local function travel(player, go, quiet)
	if not quiet then
		Remotes.Portal:FireClient(player, { kind = "whoosh" })
	end
	task.delay(if quiet then 0 else Config.LobbyFade.into, function()
		if not player.Parent then
			return
		end
		if type(go) == "function" then
			return go()
		end
		local root = rootOf(player)
		if root then
			root.CFrame = go
			root.AssemblyLinearVelocity = Vector3.zero
		end
	end)
end

-- To the lobby: in front of the arch you came back through (`from`), or where you arrive.
function Lobby.arrive(player, from, quiet)
	setAway(player, false)
	travel(player, archFront[from] or arrivalSpot(), quiet)
end

local function walkIn(player, part)
	local to, from = part:GetAttribute("To"), part:GetAttribute("From")
	local w = Worlds.byId(to)
	if to == "lobby" then
		Lobby.arrive(player, from)
	elseif to == "farm" then
		if not PlayerData.get(player) then
			return notice(player, "Still loading your farm...")
		end
		setAway(player, true)
		travel(player, function()
			if toFarm then
				toFarm(player)
			end
		end)
	elseif w and Worlds.isOpen(player, w.id) then
		setAway(player, true)
		travel(player, Worlds.arrival(w.id))
	elseif w then
		-- locked: stay here; your screen asks, and eases you back out of the arch
		local root = rootOf(player)
		local look = part.CFrame.LookVector
		local side = if root and (root.Position - part.Position):Dot(look) < 0 then -1 else 1
		Remotes.Portal:FireClient(player, { kind = "offer", world = w.id, name = w.name, price = w.price, away = look * side })
	end
end

local function hook(part)
	if not part:IsA("BasePart") then
		return
	end
	part.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not player or not humanoid or humanoid.Health <= 0 then
			return
		end
		if os.clock() - (lastTrip[player] or 0) < Config.LobbyPortalCooldown then
			return
		end
		lastTrip[player] = os.clock()
		walkIn(player, part)
	end)
end

local function spawnPad(folder)
	local a = Config.LobbyArrival
	local pad = Instance.new("SpawnLocation")
	pad.Name = "LobbySpawn"
	pad.Anchored = true
	pad.Size = Vector3.new(8, 0.4, 8)
	pad.CFrame = CFrame.new(centre() + Vector3.new(a[1], 0.1, a[2])) -- facing north, like you
	pad.Color = Color3.fromRGB(226, 190, 98)
	pad.Material = Enum.Material.Fabric
	pad.Duration = 0
	pad.Neutral = true
	pad.Parent = folder
	return pad
end

-- The arch on the farm back to the lobby: beside where you arrive, just past the south edge of
-- the build area, facing the haystack (Config.LobbyFarmPortal).
local function farmArch(folder)
	local f, e = Config.LobbyFarmPortal, Config.FarmEntrance
	local z = math.max(Config.PlotSize / 2 + f.past, e[3] + f.behind)
	local base = Vector3.new(f.x, 0, z)
	local membrane = Kit.arch(CFrame.lookAt(base, Vector3.new(f.x, 0, 0)), Config.LobbyFarmColour, folder, Config.LobbyName, "Every portal is here")
	membrane.Parent.Name = "LobbyPortal"
	Kit.trigger(membrane, "lobby", "farm")
end

function Lobby.build()
	local folder = Kit.folder("Lobby", workspace)
	local c = Island.build(folder).Position
	local portals = Kit.folder("Portals", folder)
	for _, p in ipairs(Config.LobbyPortals) do
		local at = c + Vector3.new(p.at[1], 0, p.at[2])
		local cf = CFrame.lookAt(at, Vector3.new(c.X, at.Y, c.Z))
		local w = Worlds.byId(p.id)
		local colour = if w then Config.WorldHay[w.id][1] else Config.LobbyFarmColour
		local subtitle = if w then "Opens for " .. Format.short(w.price) .. " coins" else "Free: always open"
		local membrane = Kit.arch(cf, colour, portals, if w then w.name else Config.FarmName, subtitle)
		membrane.Parent:SetAttribute("World", p.id)
		Kit.trigger(membrane, p.id, "lobby")
		local front = at + cf.LookVector * 10 + Vector3.new(0, 4, 0)
		archFront[p.id] = CFrame.lookAt(front, Vector3.new(c.X, front.Y, c.Z))
	end
	lobbySpawn = spawnPad(folder)
	local ok, err = pcall(farmArch, folder)
	if not ok then
		warn("[Lobby] The farm's arch failed to build: " .. tostring(err))
	end
end

-- toPlot: Main's function that takes a player to their farm's entrance.
function Lobby.init(toPlot)
	toFarm = toPlot
	for _, part in ipairs(CollectionService:GetTagged("WalkPortal")) do
		hook(part)
	end
	CollectionService:GetInstanceAddedSignal("WalkPortal"):Connect(hook)
	Remotes.Portal.OnServerEvent:Connect(function(player, action, id)
		if action ~= "open" or type(id) ~= "string" or not Worlds.byId(id) then
			return
		end
		if os.clock() - (lastAsk[player] or 0) < 1 then
			return
		end
		lastAsk[player] = os.clock()
		local root = rootOf(player)
		if Worlds.open(player, id) and root and Lobby.inLobby(root.Position) then
			lastTrip[player] = os.clock()
			setAway(player, true)
			travel(player, Worlds.arrival(id))
		end
	end)
	-- new players arrive (and respawn) in the lobby until they leave it
	local function joined(player)
		setAway(player, false)
	end
	Players.PlayerAdded:Connect(joined)
	for _, player in ipairs(Players:GetPlayers()) do
		joined(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		away[player], lastTrip[player], lastAsk[player] = nil, nil, nil
	end)
	-- anyone who drifts off the island (a jetpack, a big jump) is set gently back on it
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in ipairs(Players:GetPlayers()) do
				local root = rootOf(player)
				if root and root.Position.Y < Config.Lobby.floor + Config.LobbyFallBelow and Lobby.inLobby(root.Position, Config.LobbyInside * 2) then
					travel(player, arrivalSpot(), true)
				end
			end
		end
	end)
end

return Lobby

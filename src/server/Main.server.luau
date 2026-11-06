-- Starts the game. The ground and spawn point are built first, so nobody spawns into the void.
-- Strictly first person. Each player gets a plot, and their pile and buildings are rebuilt there.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local World = require(script.Parent.World)
World.ground()
StarterPlayer.CameraMode = Enum.CameraMode.LockFirstPerson

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

-- While testing in Studio, server errors also show on the players' screens.
if RunService:IsStudio() then
	game:GetService("ScriptContext").Error:Connect(function(message, trace)
		Remotes.Announce:FireAllClients({ kind = "error", text = "SERVER ERROR: " .. tostring(message) .. "\n" .. string.sub(tostring(trace), 1, 200) })
	end)
end

local Haystack = require(script.Parent.Haystack)
local PlayerData = require(script.Parent.PlayerData)
local Plots = require(script.Parent.Plots)
local Piles = require(script.Parent.Piles)
local Structures = require(script.Parent.Structures)
local Tools = require(script.Parent.Tools)
local Achievements = require(script.Parent.Achievements)
local Search = require(script.Parent.Search)
local Machines = require(script.Parent.Machines)
local Shop = require(script.Parent.Shop)
local Loft = require(script.Parent.Loft)
local Wheel = require(script.Parent.Wheel)
local Monetization = require(script.Parent.Monetization)
local Carry = require(script.Parent.Carry)
local Hauling = require(script.Parent.Hauling)
local LooseHay = require(script.Parent.LooseHay)
local Processing = require(script.Parent.Processing)
local Factory = require(script.Parent.Factory)
local Orders = require(script.Parent.Orders)
local Goals = require(script.Parent.Goals)
local Stamina = require(script.Parent.Stamina)
local Detector = require(script.Parent.Detector)
local Worlds = require(script.Parent.Worlds)
local RobuxPads = require(script.Parent.RobuxPads)
local Lobby = require(script.Parent.Lobby)

StarterPlayer.CharacterMaxSlopeAngle = Config.MaxSlopeAngle -- the steep heap needs building to climb
local Scenery = require(script.Parent.Scenery)

-- the owner's imported hay model, shared with every client before anything uses it
local Assets = require(script.Parent.Assets)
local assetsOk, assetsError = pcall(Assets.shareHay)
if not assetsOk then
	warn("[Start] The hay model failed to load: " .. tostring(assetsError))
end

World.build()
Plots.build()
Plots.onRelease = Piles.clear
Haystack.build()
-- the countryside is decoration: if any of it fails, warn and carry on
local sceneryOk, sceneryError = pcall(Scenery.build)
if not sceneryOk then
	warn("[Start] Scenery failed to build: " .. tostring(sceneryError))
end
-- the four worlds far beyond the farm, and the lobby with their arches (where you arrive)
local worldsOk, worldsError = pcall(Worlds.build)
if not worldsOk then
	warn("[Start] Worlds failed to build: " .. tostring(worldsError))
end
local lobbyOk, lobbyError = pcall(Lobby.build)
if not lobbyOk then
	warn("[Start] The lobby failed to build: " .. tostring(lobbyError))
end
-- the Robux corner: a pad per Robux item in the lobby (only offers; nothing is sold here)
local padsOk, padsError = pcall(RobuxPads.build)
if not padsOk then
	warn("[Start] Robux pads failed to build: " .. tostring(padsError))
end

local function toPlot(player)
	Lobby.leave(player) -- (respawns now go to the farm too)
	local plotIndex = Plots.of(player)
	local root = player.Character and player.Character:WaitForChild("HumanoidRootPart", 10)
	if plotIndex and root then
		root.CFrame = CFrame.lookAt(Plots.entrance(plotIndex), Plots.centre(plotIndex) + Vector3.new(0, 4, 0))
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CameraMode = Enum.CameraMode.LockFirstPerson
end)

-- T: back to your own farm, from anywhere (not more than once every few seconds)
local lastHome = {}
Remotes.GoHome.OnServerEvent:Connect(function(player)
	if os.clock() - (lastHome[player] or 0) >= Config.HomeCooldown then
		lastHome[player] = os.clock()
		toPlot(player)
	end
end)
Players.PlayerRemoving:Connect(function(player)
	lastHome[player] = nil
end)
for _, player in ipairs(Players:GetPlayers()) do
	player.CameraMode = Enum.CameraMode.LockFirstPerson
end

PlayerData.onLoaded(function(player, saveable)
	local data = PlayerData.get(player)
	PlayerData.update(player, LooseHay.restore) -- hay left lying last time waits in the basket
	local plotIndex = Plots.claim(player)
	if not plotIndex then
		player:Kick("This farm is full (four plots). Please join another server.")
		return
	end
	player:SetAttribute("Plot", plotIndex)
	Piles.build(plotIndex, data)
	Structures.build(plotIndex, data)
	Tools.give(player, data.tool, data.skin)
	Carry.show(player)
	Orders.publish(player)
	Wheel.remind(player)
	Lobby.arrive(player, nil, true) -- everyone arrives in the lobby
	-- after every spawn: back where you were (the lobby, or your farm's entrance), and make sure
	-- the tool arrived (it comes from StarterGear)
	player.CharacterAdded:Connect(function()
		task.wait(1)
		if Lobby.isIn(player) then
			Lobby.arrive(player, nil, true)
		else
			toPlot(player)
		end
		local current = PlayerData.get(player)
		if current and player.Parent and not Tools.has(player) then
			Tools.give(player, current.tool, current.skin)
		end
	end)
	if not saveable and not RunService:IsStudio() then
		task.wait(6) -- give the player's screen time to start listening
		Remotes.Announce:FireClient(player, { kind = "notice", text = "Saving isn't working right now, so progress in this server won't be kept." })
	end
end)

-- Each part starts on its own: if one breaks, its error shows in Output and the rest still run.
local parts = {
	{ "Search", Search.init }, -- harvesting first: it matters most
	{ "Piles", Piles.init }, -- each screen asks for its own haystack
	{ "Stamina", Stamina.init }, -- before PlayerData, so it hears every player load
	{ "Detector", Detector.init },
	{ "Plots", Plots.init },
	{ "Monetization", Monetization.init }, -- before PlayerData, so early players get their passes checked
	{ "Worlds", Worlds.init }, -- before PlayerData, so it hears every player load
	{ "Lobby", function() Lobby.init(toPlot) end },
	{ "PlayerData", PlayerData.init },
	{ "Achievements", Achievements.init },
	{ "Structures", Structures.init },
	{ "Machines", Machines.init },
	{ "Shop", Shop.init },
	{ "Loft", Loft.init },
	{ "Carry", Carry.init },
	{ "Hauling", Hauling.init },
	{ "LooseHay", LooseHay.init },
	{ "Processing", Processing.init },
	{ "Factory", Factory.init },
	{ "Goals", Goals.init },
}
for _, part in ipairs(parts) do
	local ok, err = pcall(part[2])
	if not ok then
		warn("[Start] " .. part[1] .. " failed to start: " .. tostring(err))
	end
end

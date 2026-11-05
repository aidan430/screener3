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

World.build()
Plots.build()
Haystack.build()

local function toPlot(player)
	local plotIndex = Plots.of(player)
	local root = player.Character and player.Character:WaitForChild("HumanoidRootPart", 10)
	if plotIndex and root then
		root.CFrame = CFrame.lookAt(Plots.entrance(plotIndex), Plots.centre(plotIndex) + Vector3.new(0, 4, 0))
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CameraMode = Enum.CameraMode.LockFirstPerson
end)
for _, player in ipairs(Players:GetPlayers()) do
	player.CameraMode = Enum.CameraMode.LockFirstPerson
end

PlayerData.onLoaded(function(player, saveable)
	local data = PlayerData.get(player)
	local plotIndex = Plots.claim(player)
	if not plotIndex then
		player:Kick("This farm is full (four plots). Please join another server.")
		return
	end
	player:SetAttribute("Plot", plotIndex)
	Piles.build(plotIndex, data)
	Structures.build(plotIndex, data)
	Tools.give(player, data.tool, data.skin)
	Wheel.remind(player)
	toPlot(player)
	-- after every spawn: back to your plot, and make sure the tool arrived (it comes from StarterGear)
	player.CharacterAdded:Connect(function()
		task.wait(1)
		toPlot(player)
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

Plots.init()
Monetization.init() -- before PlayerData.init, so early players get their passes checked
PlayerData.init()
Achievements.init()
Structures.init()
Search.init()
Machines.init()
Shop.init()
Loft.init()

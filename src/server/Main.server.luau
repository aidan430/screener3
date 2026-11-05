-- Starts the game. The ground and spawn point are built first, so nobody spawns into the void.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local World = require(script.Parent.World)
World.ground()

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Haystack = require(script.Parent.Haystack)
local PlayerData = require(script.Parent.PlayerData)
local Tools = require(script.Parent.Tools)
local Achievements = require(script.Parent.Achievements)
local Search = require(script.Parent.Search)
local Shop = require(script.Parent.Shop)
local Loft = require(script.Parent.Loft)
local Monetization = require(script.Parent.Monetization)

World.build()
Haystack.build()

PlayerData.onLoaded(function(player, saveable)
	local data = PlayerData.get(player)
	if data then
		Tools.give(player, data.tool)
	end
	-- a backstop: after every spawn, make sure the fork arrived (it comes from StarterGear)
	player.CharacterAdded:Connect(function()
		task.wait(1)
		local current = PlayerData.get(player)
		if current and player.Parent and not Tools.has(player) then
			Tools.give(player, current.tool)
		end
	end)
	if not saveable and not RunService:IsStudio() then
		task.wait(6) -- give the player's screen time to start listening
		Remotes.Announce:FireClient(player, {
			kind = "notice",
			text = "Saving isn't working right now, so progress in this server won't be kept.",
		})
	end
end)

PlayerData.init()
Monetization.init()
Achievements.init()
Search.init()
Shop.init()
Loft.init()

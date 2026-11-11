-- Starts A Needle in a Haystack on the server. Systems that react to a player's save loading are
-- started before DataManager, so none of them misses the first players. Each starts in a pcall:
-- one failing is reported in the Output window instead of stopping the rest.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LobbyBuilder = require(script.Parent.LobbyBuilder)
local DataManager = require(script.Parent.DataManager)
local QuestManager = require(script.Parent.QuestManager)
local RewardManager = require(script.Parent.RewardManager)
local ShopManager = require(script.Parent.ShopManager)
local LeaderboardManager = require(script.Parent.LeaderboardManager)
local AntiCheat = require(script.Parent.AntiCheat)
local Requests = require(script.Parent.Requests)
local CollectionManager = require(script.Parent.CollectionManager)
local HaystackModel = require(script.Parent.HaystackModel)
local LobbyShowOff = require(script.Parent.LobbyShowOff)
local RoundManager = require(script.Parent.RoundManager)
local BoxManager = require(script.Parent.BoxManager)
local Combat = require(script.Parent.Combat)
local CombatThrow = require(script.Parent.CombatThrow)
local Dash = require(script.Parent.Dash)
local Stance = require(script.Parent.Stance)
local OneOfOne = require(script.Parent.OneOfOne)
local TradeManager = require(script.Parent.TradeManager)
local Practice = require(script.Parent.Practice)
local GamePads = require(script.Parent.GamePads)
local GameServer = require(script.Parent.GameServer)

-- While testing in Studio, server errors also show on screen.
if RunService:IsStudio() then
	game:GetService("ScriptContext").Error:Connect(function(message)
		ReplicatedStorage.Remotes.Notify:FireAllClients({ text = "SERVER ERROR: " .. tostring(message), tone = "bad" })
	end)
end

for _, step in ipairs({
	{ "HaystackModel", HaystackModel.load }, -- before the lobby, so its haystacks can use it
	{ "Look", require(script.Parent.Look).init },
	{ "Lobby", LobbyBuilder.build },
	{ "AntiCheat", AntiCheat.init },
	{ "Quests", QuestManager.init },
	{ "Rewards", RewardManager.init },
	{ "Shop", ShopManager.init },
	{ "Leaderboards", LeaderboardManager.init },
	{ "Requests", Requests.init },
	{ "Collection", CollectionManager.init },
	{ "ShowOff", LobbyShowOff.init },
	{ "Boxes", BoxManager.init },
	{ "Combat", Combat.init },
	{ "Throw", CombatThrow.init },
	{ "Dash", Dash.init },
	{ "Stance", Stance.init },
	{ "OneOfOne", OneOfOne.init },
	{ "Trading", TradeManager.init },
	{ "Practice", Practice.init },
	{ "Data", DataManager.init },
	{ "Rounds", RoundManager.start },
	{ "Games", function() -- a game's own server plays its round; the lobby runs the game platforms
		if GameServer.isGameServer() then
			task.spawn(GameServer.run)
		else
			GamePads.init()
		end
	end },
}) do
	-- each in its own thread: one that errors is reported, and one that waits on the network (in
	-- Studio a DataStore or MessagingService call can) doesn't hold up the rest for more than 5 s
	local done = false
	task.spawn(function()
		local ok, err = pcall(step[2])
		done = true
		if not ok then
			warn("[Start] " .. step[1] .. " failed: " .. tostring(err))
		end
	end)
	local waited = 0
	while not done and waited < 5 do
		waited += task.wait(0.1)
	end
	if not done then
		warn("[Start] " .. step[1] .. " is still starting after 5 s; starting the rest anyway")
	end
end

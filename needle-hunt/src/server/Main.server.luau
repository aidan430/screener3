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
local NeedleModel = require(script.Parent.NeedleModel)
local HaystackModel = require(script.Parent.HaystackModel)
local LobbyShowOff = require(script.Parent.LobbyShowOff)
local RoundManager = require(script.Parent.RoundManager)
local BoxManager = require(script.Parent.BoxManager)
local Combat = require(script.Parent.Combat)

-- While testing in Studio, server errors also show on screen.
if RunService:IsStudio() then
	game:GetService("ScriptContext").Error:Connect(function(message)
		ReplicatedStorage.Remotes.Notify:FireAllClients({ text = "SERVER ERROR: " .. tostring(message), tone = "bad" })
	end)
end

for _, step in ipairs({
	{ "HaystackModel", HaystackModel.load }, -- before the lobby, so its haystacks can use it
	{ "Lobby", LobbyBuilder.build },
	{ "NeedleModel", NeedleModel.load },
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
	{ "Data", DataManager.init },
	{ "Rounds", RoundManager.start },
}) do
	local ok, err = pcall(step[2])
	if not ok then
		warn("[Start] " .. step[1] .. " failed: " .. tostring(err))
	end
end

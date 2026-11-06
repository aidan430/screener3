-- Draws your own haystack on your screen. Every player's haystack stands in the same place in
-- the middle of the farm, so each screen draws only its owner's, from what the server sends:
-- the whole heap when you join (or a new needle grows a fresh one), then each changed clump.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local HeapTerrain = require(Shared:WaitForChild("HeapTerrain"))(Config)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local player = Players.LocalPlayer
local PileView = {}

local function origin()
	local plot = player:GetAttribute("Plot")
	local centre = plot and Config.PlotCentres[plot]
	return centre and HeapTerrain.origin(centre[1], centre[2])
end

function PileView.start()
	local terrain = workspace.Terrain
	-- the heap is drawn here on your screen, so its straw colour is set here too (the server's
	-- setting may never reach your screen's terrain)
	local c = if Config.HayTexture ~= "" then Config.HayTint else Config.HeapColour
	pcall(function()
		terrain:SetMaterialColor(HeapTerrain.MATERIAL, Color3.fromRGB(c[1], c[2], c[3]))
		terrain.Decoration = true
	end)
	Remotes.PileSync.OnClientEvent:Connect(function(message)
		local o = origin()
		if not o then
			return
		end
		if message.kind == "full" then
			HeapTerrain.draw(terrain, o, message.removed, message.partial or {})
		elseif message.kind == "cell" then
			-- never fuller than it looks now: your dents stay until the clump is really gone
			HeapTerrain.cell(terrain, o, message.index, message.left, HeapTerrain.occupancy(terrain, o, message.index))
		end
	end)
	-- ask for the heap once we know our plot (the server's first send may have come too early)
	local function ask()
		if player:GetAttribute("Plot") then
			Remotes.PileSync:FireServer()
		end
	end
	player:GetAttributeChangedSignal("Plot"):Connect(ask)
	ask()
end

return PileView

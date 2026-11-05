-- Buying the next search tool with coins, and rebirth (start again for more coins a search).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))(Config)
local Format = require(Shared:WaitForChild("Format"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local PlayerData = require(script.Parent.PlayerData)
local Tools = require(script.Parent.Tools)

local Shop = {}

local function buyTool(player, level)
	local data = PlayerData.get(player)
	if not data then
		return false, "Still loading your progress..."
	end
	if type(level) ~= "number" or level ~= data.tool + 1 then
		return false, "Buy the tools in order."
	end
	local tool = Config.Tools[level]
	if not tool then
		return false, "You already have the best tool!"
	end
	if data.coins < tool.price then
		return false, "You need " .. Format.short(tool.price - data.coins) .. " more coins."
	end
	PlayerData.update(player, function(d)
		d.coins -= tool.price
		d.tool = level
	end)
	Tools.give(player, level)
	return true, "You got the " .. tool.name .. "! " .. Format.commas(tool.power) .. " straws a search."
end

local function rebirth(player)
	local data = PlayerData.get(player)
	if not data then
		return false, "Still loading your progress..."
	end
	local cost = Economy.rebirthCost(data.rebirths)
	if data.coins < cost then
		return false, "Rebirth needs " .. Format.short(cost) .. " coins."
	end
	PlayerData.update(player, function(d)
		d.coins = 0
		d.tool = 1
		d.rebirths += 1
	end)
	Tools.give(player, 1)
	local bonus = math.floor(Config.RebirthCoinBonus * (data.rebirths) * 100 + 0.5)
	return true, "Rebirth! Every search now earns +" .. bonus .. "% coins."
end

function Shop.init()
	Remotes.BuyTool.OnServerInvoke = buyTool
	Remotes.Rebirth.OnServerInvoke = rebirth
end

return Shop

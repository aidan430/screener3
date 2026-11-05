-- Buying with coins: tools (in order), bags, machines and perks. One remote: Buy(kind, index).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))(Config)
local Format = require(Shared:WaitForChild("Format"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local PlayerData = require(script.Parent.PlayerData)
local Tools = require(script.Parent.Tools)
local Achievements = require(script.Parent.Achievements)

local Shop = {}

local function pay(player, d, price)
	if d.coins < price then
		return false, "You need " .. Format.short(price - d.coins) .. " more coins."
	end
	return true
end

local buyers = {}

function buyers.tool(player, d, level)
	if level ~= d.tool + 1 then
		return false, "Buy the tools in order."
	end
	local tool = Config.Tools[level]
	if not tool then
		return false, "You already have the best tool!"
	end
	local ok, message = pay(player, d, tool.price)
	if not ok then
		return false, message
	end
	PlayerData.update(player, function(data)
		data.coins -= tool.price
		data.tool = level
		for _, perk in ipairs(Config.Perks) do
			data.perks[perk.id] = 0 -- perks belong to the tool
		end
	end)
	Tools.give(player, level)
	return true, "You got the " .. tool.name .. ": " .. tool.power .. " straws a search. Perks start again on a new tool."
end

function buyers.bag(player, d, level)
	if level ~= d.bag + 1 then
		return false, "Buy the bags in order."
	end
	local bag = Config.Bags[level]
	if not bag then
		return false, "You already have the biggest bag!"
	end
	local ok, message = pay(player, d, bag.price)
	if not ok then
		return false, message
	end
	PlayerData.update(player, function(data)
		data.coins -= bag.price
		data.bag = level
	end)
	return true, "You got the " .. bag.name .. ": it holds " .. Format.commas(bag.size) .. " straws."
end

function buyers.machine(player, d, index)
	local m = Config.Machines[index]
	if not m then
		return false, "No such machine."
	end
	local owned = d.machines[index]
	if owned >= m.max then
		return false, "You own the most " .. m.name .. "s allowed (" .. m.max .. ")."
	end
	local price = Economy.machinePrice(index, owned)
	local ok, message = pay(player, d, price)
	if not ok then
		return false, message
	end
	PlayerData.update(player, function(data)
		data.coins -= price
		data.machines[index] = owned + 1
	end)
	return true, "A " .. m.name .. " joins your yard: +" .. m.rate .. " straws a second, even while you're not clicking."
end

function buyers.perk(player, d, index)
	local perk = Config.Perks[index]
	if not perk then
		return false, "No such perk."
	end
	if d.perks[perk.id] >= perk.levels then
		return false, perk.name .. " is already maxed on this tool."
	end
	local price = Economy.perkPrice(d, index)
	local ok, message = pay(player, d, price)
	if not ok then
		return false, message
	end
	PlayerData.update(player, function(data)
		data.coins -= price
		data.perks[perk.id] += 1
		if Economy.perksMaxed(data) then
			data.stats.perks_maxed += 1
		end
	end)
	return true, perk.name .. " " .. d.perks[perk.id] .. "/" .. perk.levels .. " on your " .. Economy.tool(d.tool).name .. "."
end

function Shop.init()
	Remotes.Buy.OnServerInvoke = function(player, kind, index)
		local d = PlayerData.get(player)
		if not d then
			return false, "Still loading your progress..."
		end
		local buyer = type(kind) == "string" and buyers[kind]
		if not buyer or type(index) ~= "number" or index ~= math.floor(index) then
			return false, "Nothing to buy there."
		end
		local ok, message = buyer(player, d, index)
		if ok then
			Achievements.check(player)
		end
		return ok, message
	end
end

return Shop

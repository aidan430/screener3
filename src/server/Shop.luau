-- Buying with coins: tools and silos (in order), perks for the tool you hold, and
-- buildable items (pieces, machines, generators) that go into your inventory to place.
-- One remote: Buy(kind, key).
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
local buyers = {}

local function short(d, price)
	if d.coins < price then
		return "You need " .. Format.short(price - d.coins) .. " more coins."
	end
	return nil
end

function buyers.tool(player, d, level)
	local tool = Config.Tools[level]
	if level ~= d.tool + 1 or not tool then
		return false, if tool then "Buy the tools in order." else "You already have the best tool!"
	end
	local missing = short(d, tool.price)
	if missing then
		return false, missing
	end
	PlayerData.update(player, function(data)
		data.coins -= tool.price
		data.tool = level
		for _, perk in ipairs(Config.Perks) do
			data.perks[perk.id] = 0 -- perks belong to the tool
		end
	end)
	Tools.give(player, level, d.skin)
	return true, "You got the " .. tool.name .. ": " .. tool.power .. " straws a click, carries " .. Format.commas(tool.capacity) .. "."
end

function buyers.bucket(player, d, level)
	local bucket = Config.Buckets[level]
	if level ~= d.bucket + 1 or not bucket then
		return false, if bucket then "Buy the buckets in order." else "You already have the biggest bucket!"
	end
	local missing = short(d, bucket.price)
	if missing then
		return false, missing
	end
	PlayerData.update(player, function(data)
		data.coins -= bucket.price
		data.bucket = level
	end)
	return true, "Your " .. bucket.name .. " carries " .. Format.commas(bucket.capacity) .. " more straws."
end

function buyers.truck(player, d, index)
	local truck = Config.Trucks[index]
	if not truck then
		return false, "There's no such truck."
	end
	if (d.trucks[truck.id] or 0) >= truck.max then
		return false, "You have the most " .. truck.name .. "s allowed (" .. truck.max .. ")."
	end
	local missing = short(d, truck.price)
	if missing then
		return false, missing
	end
	PlayerData.update(player, function(data)
		data.coins -= truck.price
		data.trucks[truck.id] = (data.trucks[truck.id] or 0) + 1
	end)
	return true, "Your " .. truck.name .. " will call at your trader and haul " .. Format.commas(truck.rate) .. " straws a second."
end

function buyers.silo(player, d, level)
	local silo = Config.Silos[level]
	if level ~= d.silo + 1 or not silo then
		return false, if silo then "Upgrade the silo in order." else "You already have the biggest silo!"
	end
	local missing = short(d, silo.price)
	if missing then
		return false, missing
	end
	PlayerData.update(player, function(data)
		data.coins -= silo.price
		data.silo = level
	end)
	return true, "Your " .. silo.name .. " holds " .. Format.commas(silo.size) .. " straws from your machines."
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
	local missing = short(d, price)
	if missing then
		return false, missing
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

function buyers.item(player, d, id)
	local item = Economy.item(id)
	if not item then
		return false, "No such thing to buy."
	end
	if item.def.max and Economy.owned(d, id) >= item.def.max then
		return false, "You own the most " .. item.def.name .. "s allowed (" .. item.def.max .. ")."
	end
	local missing = short(d, item.def.price)
	if missing then
		return false, missing
	end
	PlayerData.update(player, function(data)
		data.coins -= item.def.price
		data.inventory[id] = (data.inventory[id] or 0) + 1
	end)
	return true, item.def.name .. " bought. Press B to build it on your plot."
end

function Shop.init()
	Remotes.Buy.OnServerInvoke = function(player, kind, key)
		local d = PlayerData.get(player)
		if not d then
			return false, "Still loading your progress..."
		end
		local buyer = type(kind) == "string" and buyers[kind]
		local validKey = if kind == "item" then type(key) == "string" else type(key) == "number" and key == math.floor(key)
		if not buyer or not validKey then
			return false, "Nothing to buy there."
		end
		local ok, message = buyer(player, d, key)
		if ok then
			Achievements.check(player)
		end
		return ok, message
	end
	Remotes.EquipSkin.OnServerInvoke = function(player, id)
		local d = PlayerData.get(player)
		if not d or type(id) ~= "string" or (id ~= "" and not d.skins[id]) then
			return false, "You don't have that skin."
		end
		PlayerData.update(player, function(data)
			data.skin = id
		end)
		Tools.give(player, d.tool, id)
		return true, if id == "" then "Back to the plain tool." else "Skin on!"
	end
end

return Shop

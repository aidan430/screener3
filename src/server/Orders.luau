-- Delivery orders: one at a time, a truck driver asks for straws of one kind (bundles, bales,
-- wrapped bales, pellet sacks). Everything of that kind that reaches your basket counts by its
-- straws; when it's complete you're paid the reward and the next order comes in. Orders go
-- round Config.Orders, each full round asking for and paying Config.OrderGrowth times more.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local PlayerData = require(script.Parent.PlayerData)

local Orders = {}
local NAMES = { bundle = "as loose bundles", bale = "as hay bales", wrapped = "as wrapped bales", pellet = "as pellet sacks" }

-- The order with number `n` (1, 2, 3...): which kind, how many straws, and the reward.
function Orders.at(n)
	local list = Config.Orders
	local def = list[(n - 1) % #list + 1]
	local grow = Config.OrderGrowth ^ ((n - 1) // #list)
	return def.kind, math.floor(def.straws * grow), math.floor(def.reward * grow)
end

function Orders.publish(player)
	local d = PlayerData.get(player)
	if not d then
		return
	end
	local kind, count, reward = Orders.at(d.order)
	player:SetAttribute("OrderText", "Deliver " .. Format.commas(count) .. " straws " .. NAMES[kind] .. " to your basket")
	player:SetAttribute("OrderDone", math.min(d.orderDone, count))
	player:SetAttribute("OrderCount", count)
	player:SetAttribute("OrderReward", reward)
end

-- `straws` of `kind` reached the player's basket.
function Orders.delivered(player, kind, straws)
	local d = PlayerData.get(player)
	if not d then
		return
	end
	local want, count, reward = Orders.at(d.order)
	if kind ~= want then
		return
	end
	if d.orderDone + straws >= count then
		PlayerData.update(player, function(data)
			data.coins += reward
			data.order += 1
			data.orderDone = 0
		end)
		Remotes.SearchFx:FireClient(player, { kind = "order", coins = reward, text = "Order complete! The driver pays " .. Format.short(reward) .. " coins." })
	else
		PlayerData.update(player, function(data)
			data.orderDone += straws
		end)
	end
	Orders.publish(player)
end

return Orders

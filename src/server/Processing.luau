-- What happens when loose hay touches a machine's sensor on its owner's plot: the trader's
-- basket buys it, a bale maker bales bundles, a wrapper wraps bales, a pellet press turns
-- bundles into pellet sacks, a Hay Burner burns it for power, and a splitter sends it left
-- and right in turn. Only the item owner's own machines take it.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local PlayerData = require(script.Parent.PlayerData)
local Plots = require(script.Parent.Plots)
local Hauling = require(script.Parent.Hauling)
local HayItems = require(script.Parent.HayItems)
local Orders = require(script.Parent.Orders)

local Processing = {}

-- Out of a machine's front, gently pushed away from it.
local function out(machine, name)
	local point = machine:FindFirstChild(name)
	return point and point.CFrame, point and point.CFrame.LookVector * 8
end

-- Keeps turning a stored amount into products while there's enough, the machine still stands
-- and there's room on the plot. What's left stays stored (saved) for next time.
local function produce(player, machine, store, size, kind, outName)
	while true do
		local d = PlayerData.get(player)
		local cf, push = out(machine, outName)
		if not d or d[store] < size or not machine.Parent or not cf then
			return
		end
		if not HayItems.spawn(player, kind, size, cf, push) then
			return -- too much loose hay about: it waits in the store
		end
		PlayerData.update(player, function(data)
			data[store] -= size
		end)
		task.wait(0.6)
	end
end

local handlers = {}

function handlers.BasketSensor(player, item, hit, kind)
	local straws = HayItems.resolve(item, player)
	Hauling.add(player, straws, kind)
	Orders.delivered(player, kind)
	Remotes.SearchFx:FireClient(player, { kind = "dumped", straws = straws, coins = 0, reason = if kind == "bundle" then "belt" else "bale", basket = hit.Parent:FindFirstChild("Basket") })
end

function handlers.BalerIntake(player, item, hit, kind)
	if kind ~= "bundle" then
		return
	end
	local straws = HayItems.resolve(item, player)
	PlayerData.update(player, function(data)
		data.baleStore += straws
	end)
	produce(player, hit.Parent, "baleStore", Config.BaleStraws, "bale", "BaleOut")
end

function handlers.PressIntake(player, item, hit, kind)
	if kind ~= "bundle" then
		return
	end
	local straws = HayItems.resolve(item, player)
	PlayerData.update(player, function(data)
		data.pressStore += straws
	end)
	produce(player, hit.Parent, "pressStore", Config.Processing.pellet.straws, "pellet", "BaleOut")
end

function handlers.WrapperIntake(player, item, hit, kind)
	local cf, push = out(hit.Parent, "BaleOut")
	if kind ~= "bale" or not cf then
		return
	end
	local straws = item:GetAttribute("Straws") or 0
	HayItems.resolve(item, player)
	task.wait(1.2) -- the wrapper spins it round
	if not HayItems.spawn(player, "wrapped", straws, cf, push) then
		Hauling.add(player, straws, "wrapped") -- no room for it: it goes straight to the basket
	end
end

function handlers.BurnerIntake(player, item, hit)
	local straws = HayItems.resolve(item, player)
	local burner = hit.Parent
	burner:SetAttribute("Fuel", (burner:GetAttribute("Fuel") or 0) + straws * Config.BurnerSecondsPerStraw)
end

function handlers.SplitterBelt(_, item, hit)
	local model = hit.Parent
	local tag = "Split" .. tostring(model:GetAttribute("Slot") or 0)
	if item:GetAttribute(tag) then
		return -- already sent one way by this splitter
	end
	item:SetAttribute(tag, true)
	local side = if model:GetAttribute("Side") == 1 then -1 else 1
	model:SetAttribute("Side", side)
	item.AssemblyLinearVelocity = hit.CFrame.RightVector * side * (hit:GetAttribute("Speed") or Config.ConveyorSpeed) + hit.CFrame.LookVector * 2
end

function Processing.touch(item, hit)
	local handler = handlers[hit.Name]
	if not handler then
		return
	end
	local player = HayItems.ownerOf(item)
	local plotIndex = player and Plots.of(player)
	if not plotIndex or (item:GetAttribute("Straws") or 0) <= 0 or not hit:IsDescendantOf(Plots.folder(plotIndex)) then
		return
	end
	handler(player, item, hit, item:GetAttribute("Kind"))
end

function Processing.init()
	HayItems.onTouch = Processing.touch
end

return Processing

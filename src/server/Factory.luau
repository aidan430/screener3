-- The factory line, ticking: Hay Arms and Throwers take hay from your heap and put bundles on
-- your belts (when you have the power), Hay Burners use up their hay (and make power only while
-- they have some), and every belt runs at your belt level's speed.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))(Config)

local PlayerData = require(script.Parent.PlayerData)
local Plots = require(script.Parent.Plots)
local Machines = require(script.Parent.Machines)
local HayItems = require(script.Parent.HayItems)

local Factory = {}
local TICK = 0.5

local function built(plotIndex)
	return Plots.folder(plotIndex):FindFirstChild("Built")
end

-- Sets every belt on the plot to the player's belt speed (only when it changed).
function Factory.applySpeed(player)
	local d, plotIndex = PlayerData.get(player), Plots.of(player)
	local folder = plotIndex and built(plotIndex)
	if not d or not folder then
		return
	end
	local speed = Config.BeltSpeeds[d.beltLevel].speed
	for _, model in ipairs(folder:GetChildren()) do
		if model:GetAttribute("Speed") ~= speed then
			model:SetAttribute("Speed", speed)
			for _, part in ipairs(model:GetDescendants()) do
				local dir = part:IsA("BasePart") and part:GetAttribute("Dir")
				if dir then
					part.AssemblyLinearVelocity = dir * speed
					part:SetAttribute("Speed", speed)
				end
			end
		end
	end
end

local function feed(player, d, model, def, share)
	local now = os.clock()
	if now < (model:GetAttribute("Next") or 0) then
		return
	end
	model:SetAttribute("Next", now + (if share > 0 then def.every / share else 1)) -- unpowered: look again soon
	local out = model:FindFirstChild("Out")
	local plotIndex = Plots.of(player)
	if share <= 0 or not out or HayItems.full(plotIndex) then
		return
	end
	local centre = Plots.centre(plotIndex)
	local base = model:GetPivot().Position
	if (Vector3.new(base.X, 0, base.Z) - centre).Magnitude > Config.PileRadiusBottom + Config.FeederReach then
		return -- too far from the heap to reach it
	end
	local taken = Machines.take(player, d, def.amount)
	if taken <= 0 then
		return
	end
	local velocity = if out:GetAttribute("Throw") then out.CFrame.LookVector * def.throw * 0.75 + Vector3.new(0, def.throw * 0.45, 0) else Vector3.zero
	if not HayItems.spawn(player, "bundle", taken, out.CFrame, velocity) then
		PlayerData.update(player, function(data)
			data.basket += taken -- nowhere to put it: straight to the basket rather than lost
		end)
	end
end

local function tick(player)
	local d, plotIndex = PlayerData.get(player), Plots.of(player)
	local folder = plotIndex and built(plotIndex)
	if not d or not folder then
		return
	end
	-- burners: all of them burn from your one saved pool of fuel while it lasts
	local burners = {}
	for _, model in ipairs(folder:GetChildren()) do
		if model:GetAttribute("Item") == "burner" then
			table.insert(burners, model)
		end
	end
	local fueled = if d.fuel > 0 then #burners else 0
	if fueled > 0 then
		d.fuel = math.max(0, d.fuel - fueled * TICK)
	end
	for _, model in ipairs(burners) do
		local glow = model:FindFirstChild("Glow")
		if glow then
			glow.Transparency = if fueled > 0 then 0 else 0.8
		end
	end
	if player:GetAttribute("BurnersFueled") ~= fueled then
		player:SetAttribute("BurnersFueled", fueled)
		PlayerData.update(player, function() end) -- the HUD's power numbers change with it
	end
	local share = Economy.plot(d.placed, PlayerData.flags(player).doubleMachines, fueled).share
	for _, model in ipairs(folder:GetChildren()) do
		local item = Economy.item(model:GetAttribute("Item") or "")
		if item and item.kind == "feeder" then
			feed(player, d, model, item.def, share)
		end
	end
end

function Factory.init()
	task.spawn(function()
		local beat = 0
		while true do
			task.wait(TICK)
			beat += 1
			for _, player in ipairs(Players:GetPlayers()) do
				tick(player)
				if beat % 4 == 0 then
					Factory.applySpeed(player) -- new belts pick up your speed within 2 seconds
				end
			end
		end
	end)
end

return Factory

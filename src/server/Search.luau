-- The loop: click the clump you're looking at to harvest it onto your tool, sell at the
-- merchant, and let powered machines harvest the top of your pile into your silo.
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))(Config)
local Finds = require(Shared:WaitForChild("Finds"))
local Format = require(Shared:WaitForChild("Format"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local PlayerData = require(script.Parent.PlayerData)
local Plots = require(script.Parent.Plots)
local Piles = require(script.Parent.Piles)
local Achievements = require(script.Parent.Achievements)
local Hauling = require(script.Parent.Hauling)
local Tools = require(script.Parent.Tools)
local Stamina = require(script.Parent.Stamina)

local Search = {}
local lastHarvest = {}
local rng = Random.new()

local function character(player)
	local c = player.Character
	local humanoid = c and c:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return c
end

-- The search tool, wherever it is. If it's in the backpack, the server equips it, so a click
-- never fails just because equipping didn't reach the server.
local function searchTool(player, c)
	for _, container in ipairs({ c, player:FindFirstChildOfClass("Backpack") }) do
		for _, item in ipairs(container and container:GetChildren() or {}) do
			if item:IsA("Tool") and item:GetAttribute("Level") ~= nil then
				if container ~= c then
					local humanoid = c:FindFirstChildOfClass("Humanoid")
					if humanoid then
						humanoid:EquipTool(item)
					end
				end
				return item
			end
		end
	end
	return nil
end

local function room(d)
	return Economy.capacity(d) - d.carried - d.carriedGolden
end

-- Dumps what the player carries and their silo into their trader's basket (see Hauling).
-- Returns the straws dumped.
function Search.sell(player, reason, basket)
	return (Hauling.dump(player, reason, basket))
end

local function luckyFind(player, d, flags, position)
	local find = Finds[rng:NextInteger(1, #Finds)]
	local worth = Economy.coinsFor(Economy.power(d, false) * Config.LuckyValueSearches, false, Economy.coinMultiplier(flags, d.needles)) * (find.bonus or 1)
	PlayerData.update(player, function(data)
		data.coins += worth
		data.stats.lucky_finds += 1
	end)
	Remotes.SearchFx:FireClient(player, { kind = "find", name = find.name, story = find.story, coins = worth, position = position })
end

function Search.needleFound(player, golden, position)
	local d = PlayerData.get(player)
	local prize = Economy.coinsFor(Economy.power(d, false) * 5000, golden, Economy.coinMultiplier(PlayerData.flags(player), d.needles))
	local plotIndex = Plots.of(player)
	PlayerData.update(player, function(data)
		data.coins += prize
		if golden then
			data.loft.needles += 1
			data.loft.searched = 0
			data.loft.needleAt = Economy.needleAt(Config.Loft.straws, Config.Loft.needleEarliest, rng)
		else
			data.needles += 1
			Piles.resetData(data)
		end
	end)
	task.spawn(PlayerData.save, player) -- saved at once, so leaving now can't lose the new needle
	Remotes.Announce:FireAllClients({ kind = "needle", finder = player.DisplayName, finderId = player.UserId, golden = golden, prize = prize, position = position })
	if not golden and plotIndex then -- a fresh heap with a new needle grows back straight away
		Piles.rebuild(plotIndex, PlayerData.get(player))
	end
	Achievements.check(player)
end

-- The golden haystack in the loft still counts straws, like the old haystack.
local function goldenHarvest(player, d, amount)
	local left = Config.Loft.straws - d.loft.searched
	amount = math.min(amount, room(d), left)
	if amount <= 0 then
		return 0, false
	end
	local hit = d.loft.searched < d.loft.needleAt and d.loft.searched + amount >= d.loft.needleAt
	PlayerData.update(player, function(data)
		data.loft.searched += amount
		data.carriedGolden += amount
	end)
	return amount, hit
end

-- Every click's result goes on the player as HarvestStatus (shown under the crosshair), and
-- the reason a click didn't harvest is also sent as a message (at most every 1.5 seconds).
local lastNope = {}
local function status(player, text)
	player:SetAttribute("HarvestStatus", text)
	player:SetAttribute("HarvestTick", (player:GetAttribute("HarvestTick") or 0) + 1)
end
local function nope(player, reason)
	status(player, reason)
	if time() - (lastNope[player] or 0) > 1.5 then
		lastNope[player] = time()
		Remotes.SearchFx:FireClient(player, { kind = "nope", reason = reason })
	end
end

local function harvest(player, target)
	local d, c = PlayerData.get(player), character(player)
	local now = time()
	if RunService:IsStudio() then
		print("[Harvest] click from", player.Name, "on", if typeof(target) == "Instance" then target:GetFullName() else tostring(target))
	end
	if not d then
		return nope(player, "Still loading your farm...")
	elseif not c then
		return nope(player, "Your character is respawning. Try again in a moment.")
	end
	if not searchTool(player, c) then
		Tools.give(player, d.tool, d.skin) -- lost somehow: hand a new one over and carry on
		if not searchTool(player, c) then
			return nope(player, "Your fork is on its way. Try again in a moment.")
		end
	end
	if now - (lastHarvest[player] or 0) < Economy.cooldown(d) * 0.9 then
		return status(player, player:GetAttribute("HarvestStatus") or "") -- faster than the tool swings: ignored
	end
	-- the heap is terrain: the client sends the point it aimed at (just inside the surface);
	-- the golden haystack in the loft is still parts, so that's the part itself
	local isPart = typeof(target) == "Instance" and target:IsA("BasePart")
	if not isPart and typeof(target) ~= "Vector3" then
		return nope(player, "That isn't hay.")
	end
	local point = if isPart then target.Position else target
	local head = c:FindFirstChild("Head")
	if not head or (head.Position - point).Magnitude > Config.Reach + 6 then
		return nope(player, "Too far away. Step closer to the hay.")
	end
	lastHarvest[player] = now
	local flags = PlayerData.flags(player)
	if room(d) <= 0 then
		if flags.autoSell then
			Search.sell(player, "auto")
		else
			status(player, "You're full. Dump your hay in your trader's basket.")
			Remotes.SearchFx:FireClient(player, { kind = "full" })
			return
		end
	end
	if not Stamina.spend(player, Config.Stamina.perHarvest) then
		return status(player, "Catching your breath...") -- a short rest, then carry on
	end
	local power = math.min(Economy.power(d, flags.speedBoost), room(d))
	local taken, hit, golden, gone = 0, false, false, false
	local loft = workspace:FindFirstChild("Loft")
	if isPart then
		if not (loft and target:IsDescendantOf(loft) and player:GetAttribute("LoftOpen")) then
			return nope(player, "That isn't your hay.")
		end
		golden = true
		taken, hit = goldenHarvest(player, d, power)
	else
		local plotIndex = Plots.of(player)
		if not plotIndex then
			return nope(player, "You don't have a farm yet (all four plots may be taken).")
		end
		local clump = Plots.contains(plotIndex, point, 0) and Piles.clumpAt(plotIndex, d, point)
		if not clump then
			return nope(player, "That's not your heap. Yours is on the farm marked YOUR FARM.")
		elseif (head.Position - Piles.position(plotIndex, clump)).Magnitude > Config.Reach + 6 then
			return nope(player, "Too far away. Step closer to the hay.")
		end
		taken, gone = Piles.take(plotIndex, d, clump, power)
		hit = gone and clump == d.needleClump
		PlayerData.update(player, function(data)
			data.carried += taken
			data.stats.total_searched += taken
		end)
	end
	if taken <= 0 then
		return nope(player, "Nothing left in that clump.")
	end
	PlayerData.update(player, function(data)
		data.stats.searches += 1
		if room(data) <= 0 then
			data.stats.loads_filled += 1
		end
	end)
	status(player, "+" .. Format.commas(taken) .. " straw (carrying " .. Format.commas(d.carried + d.carriedGolden) .. " / " .. Format.commas(Economy.capacity(d)) .. ")")
	local warmth = nil
	local plotIndex = Plots.of(player)
	if not golden and d.tool >= Config.DetectorLevel and plotIndex then
		warmth = Economy.warmth((head.Position - Piles.position(plotIndex, d.needleClump)).Magnitude)
	end
	Remotes.SearchFx:FireClient(player, { kind = "harvest", golden = golden, gone = gone, straws = taken, position = point, warmth = warmth, full = room(d) <= 0 })
	if hit then
		Search.needleFound(player, golden, point)
	elseif rng:NextNumber() < Economy.luckyChance(d, flags.luckyCharm) then
		luckyFind(player, d, flags, point)
	end
	Achievements.check(player)
end

function Search.init()
	Remotes.Harvest.OnServerEvent:Connect(harvest)
	Remotes.Whistle.OnServerInvoke = function(player)
		local d = PlayerData.get(player)
		if not d or d.whistles <= 0 then
			return false, "No Merchant's Whistles left."
		end
		if d.carried + d.carriedGolden + d.siloStraw <= 0 then
			return false, "You have nothing to sell."
		end
		PlayerData.update(player, function(data)
			data.whistles -= 1
		end)
		return true, "The merchant comes running and takes " .. Format.commas(Search.sell(player, "whistle")) .. " straws to your trader's basket."
	end
	ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		if prompt:GetAttribute("Action") ~= "sell" then
			return
		end
		-- a trader's basket on a plot only takes its owner's hay; the hub merchant takes anyone's
		local plotIndex = Plots.of(player)
		local stall = prompt:FindFirstAncestorOfClass("Model")
		local isStall = stall ~= nil and stall:GetAttribute("Item") == "trader"
		if isStall and not (plotIndex and stall:IsDescendantOf(Plots.folder(plotIndex))) then
			Remotes.Announce:FireClient(player, { kind = "notice", text = "That's someone else's trader. Yours is on your own farm." })
		elseif Search.sell(player, if isStall then "trader" else "merchant", prompt.Parent) <= 0 then
			Remotes.Announce:FireClient(player, { kind = "notice", text = "You have nothing to dump yet. Harvest some hay!" })
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastHarvest[player], lastNope[player] = nil, nil
	end)
end

return Search

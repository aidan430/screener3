-- The loop: click the clump you're looking at to harvest it onto your tool, sell at the
-- merchant, and let powered machines harvest the top of your pile into your silo.
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

local function holdingTool(c)
	local tool = c:FindFirstChildOfClass("Tool")
	return tool ~= nil and tool:GetAttribute("Level") ~= nil
end

local function room(d)
	return Economy.capacity(d) - d.carried - d.carriedGolden
end

-- Sells what the player carries and their silo. Returns coins paid.
function Search.sell(player, reason)
	local d = PlayerData.get(player)
	if not d or (d.carried + d.carriedGolden + d.siloStraw) <= 0 then
		return 0
	end
	local mult = Economy.coinMultiplier(PlayerData.flags(player), d.needles)
	local straws = d.carried + d.carriedGolden + d.siloStraw
	local coins = Economy.coinsFor(d.carried + d.siloStraw, false, mult) + Economy.coinsFor(d.carriedGolden, true, mult)
	PlayerData.update(player, function(data)
		data.coins += coins
		data.stats.straws_sold += straws
		data.carried, data.carriedGolden, data.siloStraw = 0, 0, 0
	end)
	Remotes.SearchFx:FireClient(player, { kind = "sold", coins = coins, straws = straws, reason = reason })
	Achievements.check(player)
	return coins
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
			Piles.resetData(data) -- saved at once, so leaving now can't lose the new needle
		end
	end)
	Remotes.Announce:FireAllClients({ kind = "needle", finder = player.DisplayName, finderId = player.UserId, golden = golden, prize = prize, position = position })
	if not golden and plotIndex then
		task.delay(6, function() -- let the celebration play, then a fresh pile with a new needle
			local current = PlayerData.get(player)
			if current and Plots.of(player) == plotIndex then
				Piles.rebuild(plotIndex, current)
			end
		end)
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

-- Tells the player why a click didn't harvest (at most every 1.5 seconds).
local lastNope = {}
local function nope(player, reason)
	if os.clock() - (lastNope[player] or 0) > 1.5 then
		lastNope[player] = os.clock()
		Remotes.SearchFx:FireClient(player, { kind = "nope", reason = reason })
	end
end

local function harvest(player, target)
	local d, c = PlayerData.get(player), character(player)
	local now = os.clock()
	if not d then
		return nope(player, "Still loading your farm...")
	elseif not c then
		return
	elseif not holdingTool(c) then
		return nope(player, "Hold your fork to harvest (press 1).")
	elseif now - (lastHarvest[player] or 0) < Economy.cooldown(d) * 0.9 then
		return -- clicking faster than the tool swings: just ignored
	end
	if typeof(target) ~= "Instance" or not target:IsA("BasePart") then
		return nope(player, "That isn't a clump of hay.")
	end
	local head = c:FindFirstChild("Head")
	if not head or (head.Position - target.Position).Magnitude > Config.Reach + 6 then
		return nope(player, "Too far away. Step closer to the clump.")
	end
	lastHarvest[player] = now
	local flags = PlayerData.flags(player)
	if room(d) <= 0 then
		if flags.autoSell then
			Search.sell(player, "auto")
		else
			Remotes.SearchFx:FireClient(player, { kind = "full" })
			return
		end
	end
	local power = math.min(Economy.power(d, flags.speedBoost), room(d))
	local taken, hit, golden, gone = 0, false, false, false
	local loft = workspace:FindFirstChild("Loft")
	if loft and target:IsDescendantOf(loft) and player:GetAttribute("LoftOpen") then
		golden = true
		taken, hit = goldenHarvest(player, d, power)
	else
		local plotIndex = Plots.of(player)
		local clump = target:GetAttribute("Clump")
		if not plotIndex then
			return nope(player, "You don't have a farm yet (all four plots may be taken).")
		elseif not clump or not target:IsDescendantOf(Plots.folder(plotIndex)) then
			return nope(player, "That's not your pile. Yours is on the farm marked YOUR FARM.")
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
	local warmth = nil
	local plotIndex = Plots.of(player)
	if not golden and d.tool >= Config.DetectorLevel and plotIndex then
		warmth = Economy.warmth((head.Position - Piles.position(plotIndex, d.needleClump)).Magnitude)
	end
	Remotes.SearchFx:FireClient(player, { kind = "harvest", golden = golden, gone = gone, straws = taken, position = target.Position, warmth = warmth, full = room(d) <= 0 })
	if hit then
		Search.needleFound(player, golden, target.Position)
	elseif rng:NextNumber() < Economy.luckyChance(d, flags.luckyCharm) then
		luckyFind(player, d, flags, target.Position)
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
		return true, "The merchant comes running! Sold for " .. Format.short(Search.sell(player, "whistle")) .. " coins."
	end
	ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		if prompt:GetAttribute("Action") == "sell" and Search.sell(player, "merchant") <= 0 then
			Remotes.Announce:FireClient(player, { kind = "notice", text = "You have nothing to sell yet. Harvest some straw!" })
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastHarvest[player], lastNope[player] = nil, nil
	end)
end

return Search

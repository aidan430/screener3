-- The loop: search the haystack (straw goes in your bag), machines add straw by themselves,
-- sell the bag to the merchant for coins. Lucky finds and the needle hide in the straw.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))(Config)
local Finds = require(Shared:WaitForChild("Finds"))
local Format = require(Shared:WaitForChild("Format"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Haystack = require(script.Parent.Haystack)
local PlayerData = require(script.Parent.PlayerData)
local Achievements = require(script.Parent.Achievements)
local World = require(script.Parent.World)

local Search = {}
local lastSearch = {}
local carry = {} -- [player] = machine straws not yet whole
local rng = Random.new()

local function root(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

local function holdingTool(player)
	local character = player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	return tool ~= nil and tool:GetAttribute("Level") ~= nil
end

local function bagRoom(d)
	return Economy.bag(d.bag).size - d.bagStraw - d.bagGolden
end

-- Sells the bag. Returns coins paid (0 if the bag was empty).
function Search.sell(player, reason)
	local d = PlayerData.get(player)
	if not d or (d.bagStraw <= 0 and d.bagGolden <= 0) then
		return 0
	end
	local flags = PlayerData.flags(player)
	local mult = Economy.coinMultiplier(flags) * (1 + 0.2 * d.needles)
	local coins = Economy.coinsFor(d.bagStraw, false, mult) + Economy.coinsFor(d.bagGolden, true, mult)
	local straws = d.bagStraw + d.bagGolden
	PlayerData.update(player, function(data)
		data.coins += coins
		data.stats.straws_sold += straws
		data.bagStraw, data.bagGolden = 0, 0
	end)
	Remotes.SearchFx:FireClient(player, { kind = "sold", coins = coins, straws = straws, reason = reason })
	Achievements.check(player)
	return coins
end

local function luckyFind(player, d, flags)
	local find = Finds[rng:NextInteger(1, #Finds)]
	local worth = Economy.coinsFor(Economy.power(d, false) * Config.LuckyValueSearches, false, Economy.coinMultiplier(flags)) * (find.bonus or 1)
	PlayerData.update(player, function(data)
		data.coins += worth
		data.stats.lucky_finds += 1
	end)
	Remotes.SearchFx:FireClient(player, { kind = "find", name = find.name, story = find.story, coins = worth })
end

local function needleFound(player, golden)
	local d = PlayerData.get(player)
	local prize = Economy.coinsFor(Economy.power(d, false) * 5000, golden, Economy.coinMultiplier(PlayerData.flags(player)))
	PlayerData.update(player, function(data)
		data.coins += prize
		if golden then
			data.loft.needles += 1
			data.loft.searched = 0
			data.loft.needleAt = Economy.needleAt(Config.Loft.straws, Config.Loft.needleEarliest, rng)
		else
			data.needles += 1
			data.searched = 0 -- a fresh haystack, a new needle, and +20% coins for good
			data.needleAt = Economy.needleAt(Config.TotalStraws, Config.NeedleEarliest, rng)
		end
	end)
	Remotes.Announce:FireAllClients({ kind = "needle", finder = player.DisplayName, finderId = player.UserId, golden = golden, prize = prize })
	Achievements.check(player)
end

-- Takes `amount` straws from the player's haystack (or the loft's) into the bag.
-- Returns straws actually taken; fires nothing itself.
local function dig(player, d, where, amount)
	local golden = where == "gold"
	local progress = if golden then d.loft else d
	local total = if golden then Config.Loft.straws else Config.TotalStraws
	amount = math.floor(math.min(amount, bagRoom(d), total - progress.searched))
	if amount <= 0 then
		return 0, false
	end
	local hit = progress.searched < progress.needleAt and progress.searched + amount >= progress.needleAt
	PlayerData.update(player, function(data)
		local p = if golden then data.loft else data
		p.searched += amount
		if golden then
			data.bagGolden += amount
		else
			data.bagStraw += amount
			data.stats.total_searched += amount
		end
	end)
	return amount, hit
end

function Search.perform(player)
	local d, part = PlayerData.get(player), root(player)
	if not d or not part then
		return
	end
	local where = Haystack.at(part.Position, Config.SearchRange)
	if not where or (where == "gold" and not player:GetAttribute("LoftOpen")) then
		return
	end
	local flags = PlayerData.flags(player)
	if bagRoom(d) <= 0 then
		if flags.autoSell then
			Search.sell(player, "auto")
		else
			Remotes.SearchFx:FireClient(player, { kind = "full" })
			return
		end
	end
	local amount, hit = dig(player, d, where, Economy.power(d, flags.speedBoost))
	if amount <= 0 then
		return
	end
	PlayerData.update(player, function(data)
		data.stats.searches += 1
		if bagRoom(data) <= 0 then
			data.stats.bags_filled += 1
		end
	end)
	local warmth = if d.tool >= Config.DetectorLevel and where == "hay" then Economy.warmth(d.searched, d.needleAt, Config.TotalStraws) else nil
	Remotes.SearchFx:FireClient(player, { kind = "search", where = where, straws = amount, warmth = warmth, full = bagRoom(d) <= 0 })
	if hit then
		needleFound(player, where == "gold")
	elseif rng:NextNumber() < Economy.luckyChance(d, flags.luckyCharm) then
		luckyFind(player, d, flags)
	end
	Achievements.check(player)
end

function Search.request(player)
	local d = PlayerData.get(player)
	local now = os.clock()
	if not d or now - (lastSearch[player] or 0) < Economy.cooldown(d) * 0.9 then
		return
	end
	lastSearch[player] = now
	if holdingTool(player) then
		Search.perform(player)
	end
end

-- Machines add straw to the bag every second while the player is in the game.
local function tickMachines()
	for _, player in ipairs(Players:GetPlayers()) do
		local d = PlayerData.get(player)
		if d then
			local flags = PlayerData.flags(player)
			local rate = Economy.machineRate(d, flags.doubleMachines) + (carry[player] or 0)
			carry[player] = rate - math.floor(rate)
			if rate >= 1 and bagRoom(d) > 0 then
				local amount, hit = dig(player, d, "hay", rate)
				if hit then
					needleFound(player, false)
				elseif amount > 0 and bagRoom(d) <= 0 and flags.autoSell then
					Search.sell(player, "auto")
				end
			end
		end
	end
end

-- The Straw Blast product: `amount` straws searched at once, needle and finds included.
function Search.blast(player, amount)
	local d = PlayerData.get(player)
	if not d then
		return
	end
	local flags = PlayerData.flags(player)
	local total = 0
	while amount > 0 do -- a blast sells the bag on the spot as often as it fills
		if bagRoom(d) <= 0 then
			Search.sell(player, "auto")
		end
		local taken, hit = dig(player, d, "hay", amount)
		if taken <= 0 then
			break
		end
		amount -= taken
		total += taken
		if hit then
			Search.sell(player, "auto")
			needleFound(player, false)
		end
	end
	Search.sell(player, "auto")
	if total > 0 and rng:NextNumber() < Economy.luckyChance(d, flags.luckyCharm) * 10 then
		luckyFind(player, d, flags)
	end
	return total
end

-- VIP: machines kept working for up to an hour after the player left.
function Search.offline(player)
	local d = PlayerData.get(player)
	if not d or d.lastSeen <= 0 or not PlayerData.flags(player).vip then
		return
	end
	local seconds = math.clamp(os.time() - d.lastSeen, 0, Config.VipOfflineSeconds)
	local amount = dig(player, d, "hay", math.floor(Economy.machineRate(d, PlayerData.flags(player).doubleMachines) * seconds))
	if amount > 0 then
		task.delay(6, function()
			Remotes.Announce:FireClient(player, { kind = "notice", text = "Your machines gathered " .. Format.commas(amount) .. " straws while you were away (VIP)." })
		end)
	end
end

local function nearMerchant(player)
	local part = root(player)
	return part ~= nil and (Vector3.new(part.Position.X, 0, part.Position.Z) - Vector3.new(World.MERCHANT.X, 0, World.MERCHANT.Z)).Magnitude <= Config.MerchantRange
end

function Search.init()
	Remotes.Search.OnServerEvent:Connect(Search.request)
	Remotes.Sell.OnServerInvoke = function(player)
		if not nearMerchant(player) then
			return false, "Walk to the merchant's stall to sell."
		end
		local coins = Search.sell(player, "merchant")
		return coins > 0, if coins > 0 then "Sold for " .. Format.short(coins) .. " coins." else "Your bag is empty."
	end
	Remotes.Whistle.OnServerInvoke = function(player)
		local d = PlayerData.get(player)
		if not d or d.whistles <= 0 then
			return false, "No Merchant's Whistles left."
		end
		if d.bagStraw <= 0 and d.bagGolden <= 0 then
			return false, "Your bag is empty."
		end
		PlayerData.update(player, function(data)
			data.whistles -= 1
		end)
		local coins = Search.sell(player, "whistle")
		return true, "The merchant comes running! Sold for " .. Format.short(coins) .. " coins."
	end
	Players.PlayerRemoving:Connect(function(player)
		lastSearch[player] = nil
		carry[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			tickMachines()
		end
	end)
end

return Search

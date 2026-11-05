-- Each player's saved progress and the leaderboard. If the DataStore can't be read (Studio
-- before publishing, or an outage), the player plays with fresh progress that is not saved,
-- so a failed read never overwrites good data.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))(Config)

local Profile = require(script.Parent.Profile)

local PlayerData = {}
local profiles = {} -- [player] = { data, saveable, dirty, joined }
local passes = {} -- [player] = { VIP = true, ... } (checked each visit, not saved)
local loadedCallbacks = {}

local MAX_RECEIPTS = 50

local store = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStoreName)
	end)
	if ok then
		store = result
	else
		warn("[PlayerData] saving is off: " .. tostring(result))
	end
end

local function key(player)
	return "player_" .. player.UserId
end

local function load(player)
	if not store then
		return Profile.fresh(nil), false
	end
	local tries = if RunService:IsStudio() then 1 else 3
	for attempt = 1, tries do
		local ok, saved = pcall(function()
			return store:GetAsync(key(player))
		end)
		if ok then
			return Profile.fresh(saved), true
		end
		warn("[PlayerData] could not load " .. player.Name .. ": " .. tostring(saved))
		if attempt < tries then
			task.wait(attempt * 2)
		end
	end
	return Profile.fresh(nil), false
end

-- Everything the client shows comes from these attributes (and leaderstats).
local function publish(player, profile)
	local d = profile.data
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Coins.Value = d.coins
		stats.Needles.Value = d.needles
	end
	local flags = PlayerData.flags(player)
	local plot = Economy.plot(d.placed, flags.doubleMachines)
	player:SetAttribute("Coins", d.coins)
	player:SetAttribute("Tool", d.tool)
	player:SetAttribute("Silo", d.silo)
	player:SetAttribute("Bucket", d.bucket)
	player:SetAttribute("Carried", d.carried + d.carriedGolden)
	player:SetAttribute("Capacity", Economy.capacity(d))
	player:SetAttribute("SiloStraw", d.siloStraw)
	player:SetAttribute("ClumpsLeft", Profile.clumpsLeft(d))
	player:SetAttribute("LoftSearched", d.loft.searched)
	player:SetAttribute("Needles", d.needles)
	player:SetAttribute("GoldenNeedles", d.loft.needles)
	player:SetAttribute("Power", Economy.power(d, flags.speedBoost))
	player:SetAttribute("MachineRate", plot.rate)
	player:SetAttribute("PowerMade", plot.made)
	player:SetAttribute("PowerDraw", plot.draw)
	player:SetAttribute("Multiplier", Economy.coinMultiplier(flags, d.needles))
	player:SetAttribute("Whistles", d.whistles)
	player:SetAttribute("Skin", d.skin)
	for _, prize in ipairs(Config.Wheel) do
		if not prize.reveal then
			player:SetAttribute("Skin_" .. prize.id, d.skins[prize.id] == true)
		end
	end
	for _, perk in ipairs(Config.Perks) do
		player:SetAttribute("Perk_" .. perk.id, d.perks[perk.id])
	end
	for _, list in ipairs({ Config.Pieces, Config.Machines, Config.Generators }) do
		for _, def in ipairs(list) do
			player:SetAttribute("Inv_" .. def.id, d.inventory[def.id] or 0)
			player:SetAttribute("Own_" .. def.id, Economy.owned(d, def.id))
		end
	end
	for name, until_ in pairs(d.boosts) do
		player:SetAttribute("Boost_" .. name, until_)
	end
	local done = 0
	for _, a in ipairs(Config.Achievements) do
		if d.achievements[a.id] then
			done += 1
		end
	end
	player:SetAttribute("Achievements", done)
	player:SetAttribute("LoftOpen", done >= #Config.Achievements)
end

function PlayerData.get(player)
	local profile = profiles[player]
	return profile and profile.data
end

function PlayerData.sessionSeconds(player)
	local profile = profiles[player]
	return if profile then os.time() - profile.joined else 0
end

-- Passes and active boosts, as the rest of the game sees them.
function PlayerData.flags(player)
	local d = PlayerData.get(player)
	local own = passes[player] or {}
	local now = os.time()
	local function boost(name)
		return d ~= nil and (d.boosts[name] or 0) > now
	end
	return {
		vip = own.VIP == true,
		autoSell = own.AutoSell == true,
		doubleMachines = own.DoubleMachines == true,
		speedBoost = boost("SpeedBoost"),
		coinBoost = boost("CoinBoost"),
		luckyCharm = boost("LuckyCharm"),
	}
end

-- Change a player's data and show the change everywhere. Returns false if not loaded yet.
function PlayerData.update(player, change)
	local profile = profiles[player]
	if not profile then
		return false
	end
	change(profile.data)
	profile.dirty = true
	publish(player, profile)
	return true
end

function PlayerData.setPass(player, name, owned)
	passes[player] = passes[player] or {}
	passes[player][name] = owned
	player:SetAttribute("Pass" .. name, owned)
	local profile = profiles[player]
	if profile then
		publish(player, profile)
	end
end

-- Waits up to `timeout` seconds for a player's data. Returns it, or nil.
function PlayerData.waitFor(player, timeout)
	local waited = 0
	while not profiles[player] and player.Parent and waited < timeout do
		waited += task.wait(0.25)
	end
	return PlayerData.get(player)
end

function PlayerData.hasReceipt(player, purchaseId)
	local d = PlayerData.get(player)
	return d ~= nil and table.find(d.receipts, purchaseId) ~= nil
end

function PlayerData.addReceipt(player, purchaseId)
	PlayerData.update(player, function(d)
		table.insert(d.receipts, purchaseId)
		while #d.receipts > MAX_RECEIPTS do
			table.remove(d.receipts, 1)
		end
	end)
end

function PlayerData.save(player)
	local profile = profiles[player]
	if not profile or not profile.saveable or not store then
		return false
	end
	local data = profile.data
	data.lastSeen = os.time()
	local ok, err = pcall(function()
		store:UpdateAsync(key(player), function()
			return data
		end)
	end)
	if ok then
		profile.dirty = false
	else
		warn("[PlayerData] could not save " .. player.Name .. ": " .. tostring(err))
	end
	return ok
end

-- callback(player, saveable) runs once a player's data has loaded.
function PlayerData.onLoaded(callback)
	table.insert(loadedCallbacks, callback)
end

local function added(player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	for _, name in ipairs({ "Coins", "Needles" }) do
		local value = Instance.new("IntValue")
		value.Name = name
		value.Parent = stats
	end
	stats.Parent = player
	local data, saveable = load(player)
	if player.Parent == nil then
		return -- left while loading
	end
	local profile = { data = data, saveable = saveable, dirty = false, joined = os.time() }
	profiles[player] = profile
	publish(player, profile)
	for _, callback in ipairs(loadedCallbacks) do
		task.spawn(callback, player, saveable)
	end
end

function PlayerData.init()
	Players.PlayerAdded:Connect(added)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(added, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		PlayerData.save(player)
		profiles[player] = nil
		passes[player] = nil
	end)
	game:BindToClose(function()
		local pending = 0
		for player in pairs(profiles) do
			pending += 1
			task.spawn(function()
				PlayerData.save(player)
				pending -= 1
			end)
		end
		local waited = 0
		while pending > 0 and waited < 25 do
			waited += task.wait(0.5)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(Config.AutosaveSeconds)
			for player, profile in pairs(profiles) do
				if profile.dirty then
					task.spawn(PlayerData.save, player)
				end
			end
		end
	end)
end

return PlayerData

-- Each player's saved progress (coins, tool, rebirths, needles found) and the leaderboard.
-- If the DataStore can't be read (Studio before publishing, or an outage), the player plays
-- with fresh progress that is not saved, so a failed read never overwrites good data.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))(Config)

local PlayerData = {}
local profiles = {} -- [player] = { data, saveable, dirty }
local passes = {} -- [player] = { DoubleCoins = true, ... } (checked each visit, not saved)
local loadedCallbacks = {}

local DEFAULTS = { coins = 0, tool = 1, rebirths = 0, needles = 0, solved = 0, clues = 0, straws = 0 }
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

local function fresh(saved)
	local data = { receipts = {} }
	for name, value in pairs(DEFAULTS) do
		data[name] = value
		if type(saved) == "table" and type(saved[name]) == type(value) then
			data[name] = saved[name]
		end
	end
	if type(saved) == "table" and type(saved.receipts) == "table" then
		for _, id in ipairs(saved.receipts) do
			if type(id) == "string" then
				table.insert(data.receipts, id)
			end
		end
	end
	data.tool = math.clamp(math.floor(data.tool), 1, #Config.Tools)
	return data
end

local function load(player)
	if not store then
		return fresh(nil), false
	end
	local tries = if RunService:IsStudio() then 1 else 3
	for attempt = 1, tries do
		local ok, saved = pcall(function()
			return store:GetAsync(key(player))
		end)
		if ok then
			return fresh(saved), true
		end
		warn("[PlayerData] could not load " .. player.Name .. ": " .. tostring(saved))
		if attempt < tries then
			task.wait(attempt * 2)
		end
	end
	return fresh(nil), false
end

local function publish(player, profile)
	local d = profile.data
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Coins.Value = d.coins
		stats.Needles.Value = d.needles
	end
	player:SetAttribute("Coins", d.coins)
	player:SetAttribute("Tool", d.tool)
	player:SetAttribute("Power", Economy.power(d.tool))
	player:SetAttribute("Rebirths", d.rebirths)
	player:SetAttribute("Needles", d.needles)
	player:SetAttribute("Multiplier", PlayerData.multiplier(player))
end

function PlayerData.get(player)
	local profile = profiles[player]
	return profile and profile.data
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

function PlayerData.addCoins(player, amount)
	return PlayerData.update(player, function(d)
		d.coins += amount
	end)
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

function PlayerData.hasPass(player, name)
	return passes[player] ~= nil and passes[player][name] == true
end

function PlayerData.multiplier(player)
	local d = PlayerData.get(player)
	return Economy.multiplier(d and d.rebirths or 0, PlayerData.hasPass(player, "DoubleCoins"))
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
	local profile = { data = data, saveable = saveable, dirty = false }
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

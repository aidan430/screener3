-- Player data: loaded on join, cached for the session, saved with UpdateAsync on an autosave
-- timer, on leave and on shutdown. A save that can't be loaded (DataStores down) plays unsaved,
-- so it can never overwrite the real one. Every other module changes data only through
-- DataManager.update, which marks it to save and shows it to the player (attributes, leaderstats
-- and the Profile remote for the UI).
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Rules = require(Shared:WaitForChild("Rules"))
local Cosmetics = require(Shared:WaitForChild("Cosmetics"))
local Needles = require(Shared:WaitForChild("Needles"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local DataManager = {}
local store = nil
local sessions = {} -- [player] = { data, dirty, unsaved }
local loadedCallbacks = {}

-- A fresh save, or an old one with anything missing or the wrong type put right.
local function number(t, key, default)
	local v = type(t) == "table" and t[key]
	return if type(v) == "number" and v == v then v else default
end

function DataManager.fresh(saved)
	saved = if type(saved) == "table" then saved else {}
	local d = {
		coins = number(saved, "coins", 0), coinsEarned = number(saved, "coinsEarned", 0),
		level = math.max(1, math.floor(number(saved, "level", 1))), xp = number(saved, "xp", 0),
		needles = number(saved, "needles", 0), bestTime = number(saved, "bestTime", 0),
		rounds = number(saved, "rounds", 0), wins = number(saved, "wins", 0), winStreak = number(saved, "winStreak", 0),
		lastDay = number(saved, "lastDay", 0), loginStreak = number(saved, "loginStreak", 0),
		hintsDay = number(saved, "hintsDay", 0), hintsUsed = number(saved, "hintsUsed", 0),
		weekly = { week = 0, wins = 0 }, quests = { day = 0, progress = {}, done = {} },
		owned = {}, equipped = {}, receipts = {},
		collection = {}, showcase = "", -- needles kept: ["type:skin"] = how many; the one on show
		settings = { music = true, sfx = true, reduceEffects = false, autoJoin = true },
	}
	if type(saved.weekly) == "table" then
		d.weekly = { week = number(saved.weekly, "week", 0), wins = number(saved.weekly, "wins", 0) }
	end
	if type(saved.quests) == "table" then
		d.quests.day = number(saved.quests, "day", 0)
		for key, list in pairs({ progress = saved.quests.progress, done = saved.quests.done }) do
			if type(list) == "table" then
				for id, v in pairs(list) do
					if type(id) == "string" and (type(v) == "number" or v == true) then
						d.quests[key][id] = v
					end
				end
			end
		end
	end
	for _, id in ipairs(Cosmetics.starting) do
		d.owned[id] = true
	end
	if type(saved.owned) == "table" then
		for id, v in pairs(saved.owned) do
			if v == true and Cosmetics.get(id) then
				d.owned[id] = true
			end
		end
	end
	for kind, id in pairs(Cosmetics.defaults) do
		d.equipped[kind] = id
	end
	if type(saved.equipped) == "table" then
		for kind, id in pairs(saved.equipped) do
			local item = Cosmetics.get(id)
			if item and item.kind == kind and d.owned[id] then
				d.equipped[kind] = id
			end
		end
	end
	if type(saved.settings) == "table" then
		for key, default in pairs(d.settings) do
			local v = saved.settings[key]
			d.settings[key] = if type(v) == "boolean" then v else default
		end
	end
	if type(saved.collection) == "table" then
		for key, count in pairs(saved.collection) do
			if type(count) == "number" and count > 0 and Needles.split(key) then
				d.collection[key] = math.floor(count)
			end
		end
	end
	if type(saved.showcase) == "string" and d.collection[saved.showcase] then
		d.showcase = saved.showcase
	end
	if type(saved.receipts) == "table" then
		for _, id in ipairs(saved.receipts) do
			if type(id) == "string" then
				table.insert(d.receipts, id)
			end
		end
	end
	return d
end

local function key(player)
	return "u_" .. player.UserId
end

local function load(player)
	if not store then
		return DataManager.fresh(nil), false
	end
	for attempt = 1, Config.LoadRetries do
		local ok, saved = pcall(store.GetAsync, store, key(player))
		if ok then
			return DataManager.fresh(saved), true
		end
		warn("[Data] load failed for " .. player.Name .. " (try " .. attempt .. "): " .. tostring(saved))
		task.wait(2 ^ attempt)
	end
	return DataManager.fresh(nil), false
end

-- Shows the data to the player: attributes for the HUD, leaderstats, and the Profile remote.
local function publish(player, d)
	player:SetAttribute("Coins", d.coins)
	player:SetAttribute("Level", d.level)
	player:SetAttribute("XP", d.xp)
	player:SetAttribute("XPNeed", Rules.xpNeed(d.level))
	player:SetAttribute("Needles", d.needles)
	player:SetAttribute("Wins", d.wins)
	player:SetAttribute("BestTime", d.bestTime)
	player:SetAttribute("LoginStreak", d.loginStreak)
	local kinds = 0
	for _ in pairs(d.collection) do
		kinds += 1
	end
	player:SetAttribute("CollectionValue", Needles.total(d.collection))
	player:SetAttribute("CollectionCount", kinds)
	player:SetAttribute("HintsUsed", if d.hintsDay == math.floor(os.time() / 86400) then d.hintsUsed else 0) -- hints reset each day (UTC)
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Level.Value, stats.Needles.Value, stats.Collection.Value = d.level, d.needles, Needles.total(d.collection)
	end
	Remotes.Profile:FireClient(player, { owned = d.owned, equipped = d.equipped, quests = d.quests, settings = d.settings, collection = d.collection, showcase = d.showcase })
end

function DataManager.get(player)
	local s = sessions[player]
	return s and s.data
end

function DataManager.unsaved(player)
	local s = sessions[player]
	return s ~= nil and s.unsaved
end

-- Changes a player's data: change(data) edits it in place.
function DataManager.update(player, change)
	local s = sessions[player]
	if not s then
		return false
	end
	change(s.data)
	s.dirty = true
	publish(player, s.data)
	return true
end

-- Saves now (UpdateAsync, so a newer save on another server is never lost to an older one).
function DataManager.save(player)
	local s = sessions[player]
	if not s or s.unsaved or not store then
		return false
	end
	local data = s.data
	local ok, err = pcall(store.UpdateAsync, store, key(player), function()
		return data
	end)
	if ok then
		s.dirty = false
	else
		warn("[Data] save failed for " .. player.Name .. ": " .. tostring(err))
	end
	return ok
end

function DataManager.onLoaded(callback)
	table.insert(loadedCallbacks, callback)
end

local function added(player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	for _, name in ipairs({ "Level", "Needles", "Collection" }) do
		Instance.new("IntValue", stats).Name = name
	end
	stats.Parent = player
	local data, ok = load(player)
	if player.Parent == nil then
		return
	end
	sessions[player] = { data = data, dirty = false, unsaved = not ok }
	publish(player, data)
	if not ok then
		Remotes.Notify:FireClient(player, { text = "We couldn't load your save, so this visit won't be saved. Try rejoining later.", tone = "bad" })
	end
	for _, callback in ipairs(loadedCallbacks) do
		task.spawn(callback, player, data)
	end
end

function DataManager.init()
	local ok, result = pcall(DataStoreService.GetDataStore, DataStoreService, Config.DataStoreName)
	store = if ok then result else nil
	if not store then
		warn("[Data] DataStores unavailable (in Studio: Game Settings > Security > Enable Studio Access to API Services)")
	end
	Players.PlayerAdded:Connect(added)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(added, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		DataManager.save(player)
		sessions[player] = nil
	end)
	game:BindToClose(function()
		local pending = 0
		for player in pairs(sessions) do
			pending += 1
			task.spawn(function()
				DataManager.save(player)
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
			for player, s in pairs(sessions) do
				if s.dirty then
					task.spawn(DataManager.save, player)
				end
			end
		end
	end)
end

return DataManager

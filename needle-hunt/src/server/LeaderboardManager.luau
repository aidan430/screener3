-- Global leaderboards (Config.Boards), each an OrderedDataStore: most chests, most tag-outs,
-- highest level, most coins earned and this week's winners. Writes are batched: a player is
-- marked when a stat changes and written every Config.BoardFlushSeconds (and when they leave),
-- never more than the DataStore budget allows. Each board is read every Config.BoardReadSeconds
-- into a cache that the lobby boards and the Leaderboard screen show; clients never read stores.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Rules = require(Shared:WaitForChild("Rules"))
local Needles = require(Shared:WaitForChild("Needles"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local DataManager = require(script.Parent.DataManager)

local LeaderboardManager = {}
local dirty = {} -- [player] = true
local cache = {} -- [board id] = { { name, value } }
local names = {} -- [userId] = name
local listeners = {}

local function storeFor(board)
	local name = board.store .. (if board.weekly then tostring(Rules.week()) else "")
	local ok, store = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, name)
	return if ok then store else nil
end

-- The value a player has on a board (nil = nothing to write).
local function valueFor(board, d)
	if board.id == "chests" then
		return if d.chests > 0 then d.chests else nil
	elseif board.id == "tagouts" then
		return if d.eliminations > 0 then d.eliminations else nil
	elseif board.id == "level" then
		return d.level
	elseif board.id == "coins" then
		return d.coinsEarned
	elseif board.id == "collection" then
		return if next(d.collection) then Needles.total(d.collection) else nil
	elseif board.id == "trial" then
		return if d.trialBest > 0 then d.trialBest else nil -- tenths of a second, lowest first
	elseif board.id == "weekly" then
		return if d.weekly.week == Rules.week() and d.weekly.wins > 0 then d.weekly.wins else nil
	end
	return nil
end

function LeaderboardManager.mark(player)
	dirty[player] = true
end

local function budget()
	return DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.SetIncrementSortedAsync)
end

local function write(player)
	local d = DataManager.get(player)
	if not d or DataManager.unsaved(player) then
		return
	end
	for _, board in ipairs(Config.Boards) do
		local value = valueFor(board, d)
		local store = value and budget() > 2 and storeFor(board)
		if store then
			pcall(store.SetAsync, store, tostring(player.UserId), value)
		end
	end
	dirty[player] = nil
end

local function nameOf(userId)
	if not names[userId] then
		local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
		names[userId] = if ok then name else "Player"
	end
	return names[userId]
end

local function read()
	for _, board in ipairs(Config.Boards) do
		local store = storeFor(board)
		local ok, pages = false, nil
		if store then
			ok, pages = pcall(store.GetSortedAsync, store, board.ascending, Config.BoardRows)
		end
		if ok and pages then
			local rows = {}
			for _, entry in ipairs(pages:GetCurrentPage()) do
				local value = if board.seconds then entry.value / 10 else entry.value
				table.insert(rows, { name = nameOf(tonumber(entry.key)), value = value })
			end
			cache[board.id] = rows
		end
	end
	for _, listener in ipairs(listeners) do
		task.spawn(listener, cache)
	end
end

-- This server's players on a board (shown when the global store can't be reached, and on the
-- "This server" tab, where friends you play with appear).
function LeaderboardManager.serverRows(boardId)
	local board
	for _, b in ipairs(Config.Boards) do
		if b.id == boardId then
			board = b
		end
	end
	local rows = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local d = DataManager.get(p)
		local v = board and d and valueFor(board, d)
		if v then
			table.insert(rows, { name = p.DisplayName, value = if board.seconds then v / 10 else v })
		end
	end
	table.sort(rows, function(a, b)
		if board.ascending then
			return a.value < b.value
		end
		return a.value > b.value
	end)
	return rows
end

function LeaderboardManager.cache()
	return cache
end

-- callback(cache) runs after each read (the lobby boards).
function LeaderboardManager.onUpdate(callback)
	table.insert(listeners, callback)
end

function LeaderboardManager.init()
	Remotes.Boards.OnServerInvoke = function(_player, boardId)
		if type(boardId) ~= "string" then
			return nil
		end
		return { global = cache[boardId] or {}, server = LeaderboardManager.serverRows(boardId) }
	end
	Players.PlayerRemoving:Connect(function(player)
		if dirty[player] then
			write(player)
		end
		dirty[player] = nil
	end)
	task.spawn(function()
		while true do
			read()
			task.wait(Config.BoardReadSeconds)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(Config.BoardFlushSeconds)
			for player in pairs(dirty) do
				if player.Parent then
					write(player)
				end
			end
		end
	end)
end

return LeaderboardManager

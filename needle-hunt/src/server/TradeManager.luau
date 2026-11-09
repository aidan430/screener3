-- Trading needles between two players in the lobby (Config.Trading). Remotes.Trade asks; the
-- server keeps every trade and sends each side its state (Remotes.TradeState). Protections:
--   only in the lobby (never during a round), one trade at a time, a cooldown on asking;
--   any change to either offer un-readies both, and stops the countdown;
--   once both press Ready, a countdown runs before anything moves, and either can still cancel;
--   at the end the server checks both still own everything offered, then swaps and saves both.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Needles = require(Shared:WaitForChild("Needles"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local DataManager = require(script.Parent.DataManager)
local LeaderboardManager = require(script.Parent.LeaderboardManager)
local RoundManager = require(script.Parent.RoundManager)

local TradeManager = {}
local TR = Config.Trading
local trades = {} -- player -> the trade they're in
local invites = {} -- target -> { [from] = os.clock() }
local lastAsk = {}

local function other(t, p)
	return if t.a == p then t.b else t.a
end

local function count(offer)
	local n = 0
	for _, c in pairs(offer) do
		n += c
	end
	return n
end

local function list(offer)
	local out = {}
	for key, c in pairs(offer) do
		table.insert(out, { key = key, count = c })
	end
	return out
end

local function send(t)
	for _, p in ipairs({ t.a, t.b }) do
		local o = other(t, p)
		Remotes.TradeState:FireClient(p, {
			kind = "trade", countdownEnds = t.countdownEnds,
			you = { offer = list(t.offer[p]), ready = t.ready[p] == true },
			them = { userId = o.UserId, name = o.DisplayName, offer = list(t.offer[o]), ready = t.ready[o] == true },
		})
	end
end

local function finish(t, text)
	trades[t.a], trades[t.b] = nil, nil
	t.over = true
	for _, p in ipairs({ t.a, t.b }) do
		if p.Parent then
			Remotes.TradeState:FireClient(p, { kind = "closed", text = text })
		end
	end
end

local function inLobby(player) -- not playing in the round going on (if one is)
	local round = RoundManager.current()
	return not (round and round.participants[player])
end

-- Both still own what they offered? Then swap, fix showcases, and save both.
local function execute(t)
	local da, db = DataManager.get(t.a), DataManager.get(t.b)
	if not da or not db or DataManager.unsaved(t.a) or DataManager.unsaved(t.b) then
		return finish(t, "Trade cancelled: a save isn't working right now.")
	end
	for _, side in ipairs({ { t.a, da }, { t.b, db } }) do
		for key, c in pairs(t.offer[side[1]]) do
			if (side[2].collection[key] or 0) < c then
				return finish(t, "Trade cancelled: something offered isn't there any more.")
			end
		end
	end
	local function move(from, to)
		DataManager.update(from, function(data)
			for key, c in pairs(t.offer[from]) do
				data.collection[key] -= c
				if data.collection[key] <= 0 then
					data.collection[key] = nil
					if data.showcase == key then
						data.showcase = ""
					end
				end
			end
		end)
		DataManager.update(to, function(data)
			for key, c in pairs(t.offer[from]) do
				data.collection[key] = (data.collection[key] or 0) + c
			end
		end)
	end
	move(t.a, t.b)
	move(t.b, t.a)
	for _, pair in ipairs({ { t.a, t.b }, { t.b, t.a } }) do -- the 1 of 1's record follows it
		for _, e in ipairs(Config.OneOfOne.list) do
			if t.offer[pair[1]][e.key] then
				require(script.Parent.OneOfOne).transfer(e.key, pair[2])
			end
		end
	end
	for _, p in ipairs({ t.a, t.b }) do
		DataManager.update(p, function(data) -- nothing on show? Your best needle goes up
			if data.showcase == "" then
				local best, value = "", -1
				for key in pairs(data.collection) do
					local ty, sk = Needles.split(key)
					if ty and Needles.value(ty, sk) > value then
						best, value = key, Needles.value(ty, sk)
					end
				end
				data.showcase = best
			end
		end)
		DataManager.save(p)
		LeaderboardManager.mark(p)
	end
	print(string.format("[Trade] %s <-> %s: %d for %d needles", t.a.Name, t.b.Name, count(t.offer[t.a]), count(t.offer[t.b])))
	finish(t, "Trade done! Enjoy your new needles.")
end

local function unready(t)
	t.ready, t.countdownEnds, t.token = {}, nil, (t.token or 0) + 1
end

local actions = {}

function actions.request(player, userId)
	local target = type(userId) == "number" and Players:GetPlayerByUserId(userId)
	if not target or target == player then
		return false, "They aren't here."
	elseif not inLobby(player) or not inLobby(target) then
		return false, "Trades happen in the lobby, between rounds."
	elseif trades[player] or trades[target] then
		return false, "One of you is already trading."
	elseif os.clock() - (lastAsk[player] or 0) < TR.requestCooldown then
		return false, "Wait a moment before asking again."
	end
	lastAsk[player] = os.clock()
	invites[target] = invites[target] or {}
	invites[target][player] = os.clock()
	Remotes.TradeState:FireClient(target, { kind = "invite", from = player.UserId, name = player.DisplayName })
	return true, "Asked " .. target.DisplayName .. " to trade."
end

function actions.respond(player, userId, accept)
	local from = type(userId) == "number" and Players:GetPlayerByUserId(userId)
	local asked = from and invites[player] and invites[player][from]
	if invites[player] and from then
		invites[player][from] = nil
	end
	if not asked or os.clock() - asked > 30 then
		return false, "That invite has run out."
	elseif not accept then
		Remotes.Notify:FireClient(from, { text = player.DisplayName .. " said no thanks to a trade.", tone = "bad" })
		return true, nil
	elseif trades[player] or trades[from] or not inLobby(player) or not inLobby(from) then
		return false, "That trade can't start right now."
	end
	local t = { a = from, b = player, offer = { [from] = {}, [player] = {} }, ready = {} }
	trades[from], trades[player] = t, t
	send(t)
	return true, nil
end

function actions.offer(player, key, add)
	local t = trades[player]
	local d = DataManager.get(player)
	if not t or not d or type(key) ~= "string" or not Needles.split(key) then
		return false, "?"
	end
	local mine = t.offer[player]
	if add then
		if (mine[key] or 0) >= (d.collection[key] or 0) then
			return false, "You don't have another of those."
		elseif count(mine) >= TR.maxItems then
			return false, "Up to " .. TR.maxItems .. " needles a trade."
		end
		mine[key] = (mine[key] or 0) + 1
	elseif mine[key] then
		mine[key] = if mine[key] > 1 then mine[key] - 1 else nil
	end
	unready(t) -- any change: both have to look again
	send(t)
	return true, nil
end

function actions.ready(player, on)
	local t = trades[player]
	if not t then
		return false, "?"
	end
	t.ready[player] = on == true
	if t.ready[t.a] and t.ready[t.b] then
		if count(t.offer[t.a]) + count(t.offer[t.b]) == 0 then
			t.ready = {}
			send(t)
			return false, "Put something in the trade first."
		end
		t.token = (t.token or 0) + 1
		local token = t.token
		t.countdownEnds = workspace:GetServerTimeNow() + TR.countdown
		task.delay(TR.countdown, function()
			if not t.over and t.token == token and t.ready[t.a] and t.ready[t.b] then
				execute(t)
			end
		end)
	else
		t.countdownEnds, t.token = nil, (t.token or 0) + 1
	end
	send(t)
	return true, nil
end

function actions.cancel(player)
	local t = trades[player]
	if t then
		finish(t, player.DisplayName .. " cancelled the trade.")
	end
	return true, nil
end

function TradeManager.init()
	Remotes.Trade.OnServerInvoke = function(player, action, a, b)
		local fn = type(action) == "string" and actions[action]
		if not fn then
			return false, "?"
		end
		return fn(player, a, b)
	end
	Players.PlayerRemoving:Connect(function(player)
		local t = trades[player]
		if t then
			finish(t, player.DisplayName .. " left, so the trade was cancelled.")
		end
		invites[player], lastAsk[player] = nil, nil
	end)
	ReplicatedStorage:GetAttributeChangedSignal("Phase"):Connect(function()
		if ReplicatedStorage:GetAttribute("Phase") == "countdown" then -- a round is starting
			local seen = {}
			for _, t in pairs(trades) do
				if not seen[t] then
					seen[t] = true
					finish(t, "A round is starting, so the trade was cancelled. Nothing moved.")
				end
			end
		end
	end)
end

return TradeManager

-- Daily quests: three a day, the same for everyone (shared/Quests.forDay). Progress is saved;
-- a new day (UTC) starts fresh. When a quest is done its reward is paid straight away (coins,
-- XP and sometimes a cosmetic) and the player is told.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Quests = require(Shared:WaitForChild("Quests"))
local Cosmetics = require(Shared:WaitForChild("Cosmetics"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local DataManager = require(script.Parent.DataManager)

local QuestManager = {}
QuestManager.grant = function(_player, _coins, _xp, _why) end -- RewardManager sets this (no circular require)

-- Starts a new day's quests if the saved ones are from an earlier day.
local function fresh(d)
	local today = Quests.today()
	if d.quests.day ~= today then
		d.quests = { day = today, progress = {}, done = {} }
	end
end

-- Records progress of `kind` (see shared/Quests) for today's quests.
function QuestManager.record(player, kind, amount)
	local d = DataManager.get(player)
	if not d then
		return
	end
	local finished = {}
	DataManager.update(player, function(data)
		fresh(data)
		for _, q in ipairs(Quests.forDay(data.quests.day)) do
			local counts = q.kind == kind and not data.quests.done[q.id]
			if counts then
				local now = math.min(q.n, (data.quests.progress[q.id] or 0) + amount)
				data.quests.progress[q.id] = now
				if now >= q.n then
					data.quests.done[q.id] = true
					table.insert(finished, q)
					if q.cosmetic and Cosmetics.get(q.cosmetic) then
						data.owned[q.cosmetic] = true
					end
				end
			end
		end
	end)
	for _, q in ipairs(finished) do
		QuestManager.grant(player, q.coins, q.xp, "Quest done: " .. q.text)
		if q.cosmetic and Cosmetics.get(q.cosmetic) then
			Remotes.Notify:FireClient(player, { text = "New cosmetic: " .. Cosmetics.get(q.cosmetic).name .. "! Equip it in your Inventory.", tone = "good" })
		end
	end
end

function QuestManager.init()
	DataManager.onLoaded(function(player)
		DataManager.update(player, fresh)
	end)
end

return QuestManager

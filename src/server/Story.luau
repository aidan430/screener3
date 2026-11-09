-- The story (shared/Story): every couple of seconds, plays the next beat whose trigger the player
-- has reached, pays its coins and tells their screen to show it (Remotes.Story; client/Dialogue).
-- The main beats play in order; beats about the worlds play whenever you first open that world.
-- Once you've found a needle, any heap beats you raced past are skipped quietly. Seen beats are
-- saved by id (d.storySeen) and shown to the client as the StorySeen attribute (ids, commas).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local StoryData = require(Shared:WaitForChild("Story"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local PlayerData = require(script.Parent.PlayerData)
local Goals = require(script.Parent.Goals)

local Story = {}

local function reached(d, trigger)
	local kind = trigger.kind
	if kind == "start" then
		return true
	elseif kind == "needles" then
		return d.needles >= trigger.n
	elseif kind == "world" then
		local w = d.worlds[trigger.key]
		return w ~= nil and w.unlocked == true
	end
	return Goals.value(d, trigger) >= trigger.n
end

local function publish(player, d)
	local ids = {}
	for id in pairs(d.storySeen) do
		table.insert(ids, id)
	end
	table.sort(ids)
	local text = table.concat(ids, ",")
	if player:GetAttribute("StorySeen") ~= text then
		player:SetAttribute("StorySeen", text)
	end
end

-- The next beat to play now, or nil. Heap beats you've raced past (a needle already found) are
-- marked seen without playing.
local function nextBeat(d)
	for _, beat in ipairs(StoryData.beats) do
		if not d.storySeen[beat.id] then
			local side = beat.trigger.kind == "world"
			if reached(d, beat.trigger) then
				return beat
			elseif not side then
				if beat.trigger.kind == "clumps" and d.needles > 0 then
					d.storySeen[beat.id] = true -- skipped: the needle came first
				else
					-- the main story waits here; only world beats may still play
					for _, other in ipairs(StoryData.beats) do
						if other.trigger.kind == "world" and not d.storySeen[other.id] and reached(d, other.trigger) then
							return other
						end
					end
					return nil
				end
			end
		end
	end
	return nil
end

function Story.check(player)
	local d = PlayerData.get(player)
	if not d then
		return
	end
	local beat = nextBeat(d)
	if beat then
		PlayerData.update(player, function(data)
			data.storySeen[beat.id] = true
			data.coins += beat.reward or 0
		end)
		Remotes.Story:FireClient(player, { id = beat.id })
	end
	publish(player, d)
end

function Story.init()
	task.spawn(function()
		while true do
			task.wait(Config.GoalCheckSeconds)
			for _, player in ipairs(Players:GetPlayers()) do
				local ok, err = pcall(Story.check, player)
				if not ok then
					warn("[Story] " .. tostring(err))
				end
			end
		end
	end)
end

return Story

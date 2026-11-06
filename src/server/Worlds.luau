-- The portal worlds: four arches in the lobby (server/Lobby.luau) lead to the Moon, the Ember
-- Lands, Bubble City and Haystack Stadium (Config.Worlds). A portal is opened once with coins
-- (saved in d.worlds[id].unlocked; Worlds.open); travelling is free after. Each world's
-- haystack pays coins at once for every click, at that world's multiplier, and hides its own
-- needle at a straw index.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))(Config)
local Format = require(Shared:WaitForChild("Format"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local PlayerData = require(script.Parent.PlayerData)
local Kit = require(script.Parent.WorldsKit)

local BUILDERS = {
	moon = require(script.Parent.WorldsMoon),
	lava = require(script.Parent.WorldsLava),
	atlantis = require(script.Parent.WorldsAtlantis),
	field = require(script.Parent.WorldsField),
}

local Worlds = {}
local byId = {}
for _, w in ipairs(Config.Worlds) do
	byId[w.id] = w
end
local rng = Random.new()

-- What the client shows: which portals are open, and each world's score.
function Worlds.publish(player)
	local d = PlayerData.get(player)
	if not d then
		return
	end
	for _, w in ipairs(Config.Worlds) do
		local state = d.worlds[w.id]
		player:SetAttribute("World_" .. w.id, state.unlocked)
		player:SetAttribute("WorldStraws_" .. w.id, state.searched)
		player:SetAttribute("WorldNeedles_" .. w.id, state.needles)
	end
end

local function notice(player, text)
	Remotes.Announce:FireClient(player, { kind = "notice", text = text })
end

function Worlds.byId(id)
	return byId[id]
end

-- Where you arrive in world `id`.
function Worlds.arrival(id)
	return byId[id] and Kit.arrival(byId[id])
end

-- Opens world `id`'s portal for its price in coins, once (the server checks the coins).
-- Returns true if the portal is open (already, or now).
function Worlds.open(player, id)
	local w, d = byId[id], PlayerData.get(player)
	if not w then
		return false
	end
	if not d then
		notice(player, "Still loading your farm...")
		return false
	end
	if d.worlds[w.id].unlocked then
		return true
	end
	if d.coins < w.price then
		notice(player, "The portal to " .. w.name .. " opens for " .. Format.commas(w.price) .. " coins. You have " .. Format.commas(math.floor(d.coins)) .. ".")
		return false
	end
	PlayerData.update(player, function(data)
		data.coins -= w.price
		data.worlds[w.id].unlocked = true
	end)
	Worlds.publish(player)
	task.spawn(PlayerData.save, player)
	notice(player, "You opened the portal to " .. w.name .. "! Travelling there is free from now on.")
	return true
end

function Worlds.isOpen(player, id)
	local d = PlayerData.get(player)
	return d ~= nil and byId[id] ~= nil and d.worlds[id].unlocked == true
end

-- A click on a world's haystack (called by Search after its reach, cooldown and stamina
-- checks). Returns the line shown under the crosshair.
function Worlds.harvest(player, d, part, power)
	local w = byId[part:GetAttribute("World")]
	local root = workspace:FindFirstChild("Worlds")
	local home = w and root and root:FindFirstChild(w.id)
	if not home or not part:IsDescendantOf(home) then
		return "That isn't hay."
	end
	local state = d.worlds[w.id]
	if not state.unlocked then
		return "Open this world's portal in the lobby first."
	end
	if state.searched >= w.straws then -- (only if the haystack was made smaller since)
		PlayerData.update(player, function(data)
			data.worlds[w.id].searched = 0
			data.worlds[w.id].needleAt = Economy.needleAt(w.straws, Config.WorldNeedleEarliest, rng)
		end)
	end
	local amount = math.min(power, w.straws - state.searched)
	local multiplier = Economy.coinMultiplier(PlayerData.flags(player), d.needles)
	local coins = Economy.coinsFor(amount, false, multiplier) * w.multiplier
	local hit = state.searched < state.needleAt and state.searched + amount >= state.needleAt
	PlayerData.update(player, function(data)
		data.coins += coins
		data.worlds[w.id].searched += amount
		data.stats.searches += 1
	end)
	local head = player.Character and player.Character:FindFirstChild("Head")
	local towards = if head then (head.Position - part.Position).Unit else Vector3.yAxis
	local point = part.Position + towards * part.Size.X * 0.45
	Remotes.SearchFx:FireClient(player, { kind = "harvest", golden = false, gone = false, straws = amount, position = point, full = false })
	Remotes.SearchFx:FireClient(player, { kind = "paid", coins = coins })
	if hit then
		local prize = Economy.coinsFor(Economy.power(d, false) * Config.WorldNeedleSearches, false, multiplier) * w.multiplier
		PlayerData.update(player, function(data)
			local s = data.worlds[w.id]
			data.coins += prize
			s.needles += 1
			s.searched = 0
			s.needleAt = Economy.needleAt(w.straws, Config.WorldNeedleEarliest, rng)
		end)
		task.spawn(PlayerData.save, player)
		Remotes.Announce:FireAllClients({ kind = "worldneedle", world = w.id, name = w.name, finder = player.DisplayName, finderId = player.UserId, prize = prize, position = point })
	end
	Worlds.publish(player)
	return "+" .. Format.commas(amount) .. " straw: +" .. Format.commas(coins) .. " coins (" .. w.multiplier .. "x on " .. w.name .. ")"
end

function Worlds.build()
	local root = Kit.folder("Worlds", workspace)
	for _, w in ipairs(Config.Worlds) do
		local folder = Kit.folder(w.id, root)
		local centre = Vector3.new(w.x, 0, w.z)
		-- each world is decoration around its haystack: if a build fails, warn and carry on
		local ok, err = pcall(BUILDERS[w.id].build, w, centre, folder)
		if not ok then
			warn("[Worlds] " .. w.name .. " failed to build: " .. tostring(err))
		end
		Kit.haystack(w.id, centre, folder)
		Kit.returnPortal(w, folder)
	end
end

function Worlds.init()
	PlayerData.onLoaded(Worlds.publish)
end

return Worlds

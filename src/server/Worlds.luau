-- The portal worlds: four arches on the hub's west road lead to the Moon, the Ember Lands,
-- Bubble City and Haystack Stadium (Config.Worlds). A portal is opened once with coins (saved
-- in d.worlds[id].unlocked); travelling is free after. Each world's haystack pays coins at
-- once for every click, at that world's multiplier, and hides its own needle at a straw index.
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
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
local byId, indexOf = {}, {}
for i, w in ipairs(Config.Worlds) do
	byId[w.id], indexOf[w.id] = w, i
end
local rng = Random.new()
local lastPortal = {}

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

local function hubSpot(w)
	local x = Config.WorldPortals.xs[indexOf[w.id]]
	return CFrame.lookAt(Vector3.new(x, 4, 0), Vector3.new(0, 4, 0))
end

local function teleport(player, cf)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		root.CFrame = cf
		root.AssemblyLinearVelocity = Vector3.zero
	end
end

local function notice(player, text)
	Remotes.Announce:FireClient(player, { kind = "notice", text = text })
end

local function usePortal(player, w)
	local d = PlayerData.get(player)
	if not d then
		return notice(player, "Still loading your farm...")
	end
	if not d.worlds[w.id].unlocked then
		if d.coins < w.price then
			return notice(player, "The portal to " .. w.name .. " opens for " .. Format.commas(w.price) .. " coins. You have " .. Format.commas(math.floor(d.coins)) .. ".")
		end
		PlayerData.update(player, function(data)
			data.coins -= w.price
			data.worlds[w.id].unlocked = true
		end)
		Worlds.publish(player)
		task.spawn(PlayerData.save, player)
		notice(player, "You opened the portal to " .. w.name .. "! Travelling there is free from now on.")
	end
	teleport(player, Kit.arrival(w))
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
		return "Open this world's portal in the hub first."
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
	local portals = Kit.folder("Portals", root)
	for i, w in ipairs(Config.Worlds) do
		local x = Config.WorldPortals.xs[i]
		local cf = CFrame.lookAt(Vector3.new(x, 0, Config.WorldPortals.z), Vector3.new(x, 0, 0))
		local membrane = Kit.arch(cf, Config.WorldHay[w.id][1], portals, w.name, "Open: " .. Format.short(w.price) .. " coins")
		Kit.prompt(membrane, "portal", "Travel", w.name, w.id, Config.WorldPortals.holdSeconds)
	end
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
	ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		local action = prompt:GetAttribute("Action")
		local w = byId[prompt:GetAttribute("World")]
		if (action ~= "portal" and action ~= "portal_home") or not w then
			return
		end
		if os.clock() - (lastPortal[player] or 0) < Config.WorldPortals.cooldown then
			return
		end
		lastPortal[player] = os.clock()
		if action == "portal_home" then
			teleport(player, hubSpot(w))
		else
			usePortal(player, w)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastPortal[player] = nil
	end)
end

return Worlds

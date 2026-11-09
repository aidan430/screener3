-- The Wheel of Fortune: every player gets one free spin a day (a new day starts at midnight UTC);
-- more spins are the WheelSpin Robux product. One spin = one prize, picked here on the server by
-- weight; every spin wins something. Where paid random items are restricted only the free spin
-- is offered, and a paid spin that slips through is replaced by a fixed prize.
local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))(Config)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local PlayerData = require(script.Parent.PlayerData)

local Wheel = {}
local rng = Random.new()

function Wheel.restricted(player)
	local ok, info = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(player)
	end)
	return not ok or info.ArePaidRandomItemsRestricted == true -- unknown counts as restricted
end

-- Today, as whole days since 1970 (UTC): the free spin comes back when this goes up.
local function today()
	return math.floor(os.time() / 86400)
end

-- Grants one spin (`free` for the daily one, which no region restricts: nothing is paid).
-- Returns a message for the player.
function Wheel.spin(player, free)
	local d = PlayerData.get(player)
	if not d then
		return "Your farm is still loading."
	end
	local coins = Economy.coinsFor(Economy.power(d, false) * Config.WheelDuplicateSearches, false, 1)
	PlayerData.update(player, function(data)
		data.stats.spins = (data.stats.spins or 0) + 1
	end)
	if not free and Wheel.restricted(player) then
		PlayerData.update(player, function(data)
			data.coins += coins
		end)
		return "The wheel isn't available where you live, so you got " .. coins .. " coins instead."
	end
	local index, prize = Economy.spin(rng)
	local message
	if prize.reveal then
		PlayerData.update(player, function(data)
			data.revealed = true
		end)
		Remotes.Announce:FireClient(player, { kind = "reveal", clump = d.needleClump })
		Remotes.Announce:FireAllClients({ kind = "notice", text = player.DisplayName .. " won the NEEDLE REVEAL on the Wheel of Fortune!" })
		message = "JACKPOT! The needle's clump is glowing on your pile."
	elseif d.skins[prize.id] then
		PlayerData.update(player, function(data)
			data.coins += coins
		end)
		message = "You already have the " .. prize.name .. ", so you got " .. coins .. " coins."
	else
		PlayerData.update(player, function(data)
			data.skins[prize.id] = true
		end)
		message = "You won the " .. prize.name .. "! Wear it from the Skins menu."
	end
	Remotes.Announce:FireClient(player, { kind = "wheel", index = index, name = prize.name, text = message })
	return message
end

-- A free spin: a banked one first (won from milestones), else the daily one if it's unused.
local function freeSpin(player)
	local d = PlayerData.get(player)
	if not d then
		return
	end
	if d.spinBank > 0 then
		PlayerData.update(player, function(data)
			data.spinBank -= 1
		end)
		Wheel.spin(player, true)
		return
	end
	if d.freeSpinDay >= today() then
		return
	end
	PlayerData.update(player, function(data)
		data.freeSpinDay = today()
	end)
	Wheel.spin(player, true)
end

-- On joining: where their needle is, if they won the reveal for this pile, and a quiet note
-- when today's free spin is waiting.
function Wheel.remind(player)
	local d = PlayerData.get(player)
	if d and d.revealed then
		task.delay(10, function()
			Remotes.Announce:FireClient(player, { kind = "reveal", clump = d.needleClump })
		end)
	end
	if d and d.freeSpinDay < today() then
		task.delay(14, function()
			if player.Parent == Players then
				Remotes.Announce:FireClient(player, { kind = "notice", text = "Your free spin on the Wheel of Fortune is ready." })
			end
		end)
	end
end

function Wheel.init()
	Remotes.FreeSpin.OnServerEvent:Connect(freeSpin)
end

return Wheel

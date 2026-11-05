-- The Wheel of Fortune: one Robux spin (the WheelSpin product) = one prize, picked here on the
-- server by weight. Every spin wins something. Where paid random items are restricted the
-- wheel is hidden on the client, and a spin that slips through is replaced by a fixed prize.
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

-- Grants one spin. Returns a message for the player.
function Wheel.spin(player)
	local d = PlayerData.get(player)
	local coins = Economy.coinsFor(Economy.power(d, false) * Config.WheelDuplicateSearches, false, 1)
	if Wheel.restricted(player) then
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

-- Tells a player on joining where their needle is, if they won the reveal for this pile.
function Wheel.remind(player)
	local d = PlayerData.get(player)
	if d and d.revealed then
		task.delay(10, function()
			Remotes.Announce:FireClient(player, { kind = "reveal", clump = d.needleClump })
		end)
	end
end

return Wheel

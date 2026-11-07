-- Robux items. Every ID in Config.GamePasses and Config.Products starts at 0 (switched off);
-- create the item on the Creator Dashboard after publishing, then paste its ID into Config.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local PlayerData = require(script.Parent.PlayerData)
local Machines = require(script.Parent.Machines)
local Wheel = require(script.Parent.Wheel)

local Monetization = {}

local function nameOf(table_, id)
	for name, itemId in pairs(table_) do
		if itemId ~= 0 and itemId == id then
			return name
		end
	end
	return nil
end

-- A skin bought directly (its game pass, Config.Wheel[n].pass): yours for good, on every visit.
local function skinPass(id)
	for _, prize in ipairs(Config.Wheel) do
		if prize.pass and prize.pass ~= 0 and prize.pass == id then
			return prize
		end
	end
	return nil
end

local function grantSkin(player, prize)
	PlayerData.update(player, function(d)
		d.skins[prize.id] = true
	end)
end

local function checkPasses(player)
	for _, prize in ipairs(Config.Wheel) do
		if prize.pass and prize.pass ~= 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, prize.pass)
			end)
			if ok and owns then
				grantSkin(player, prize)
			end
		end
	end
	for name, id in pairs(Config.GamePasses) do
		if id ~= 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, id)
			end)
			if ok and owns then
				PlayerData.setPass(player, name, true)
			end
		end
	end
	Machines.offline(player)
end

local grants = {}

local function boost(name, title)
	return function(player)
		PlayerData.update(player, function(d)
			d.boosts[name] = math.max(d.boosts[name] or 0, os.time()) + Config.BoostSeconds
		end)
		return "Thank you! " .. title .. " is on for an hour (buying again adds another hour)."
	end
end
grants.SpeedBoost = boost("SpeedBoost", "2x Speed")
grants.CoinBoost = boost("CoinBoost", "2x Coins")
grants.LuckyCharm = boost("LuckyCharm", "Your Lucky Charm")

function grants.MerchantWhistle(player)
	PlayerData.update(player, function(d)
		d.whistles += Config.WhistleUses
	end)
	return "Thank you! " .. Config.WhistleUses .. " more Merchant's Whistles: send your load to your basket from anywhere."
end

function grants.StrawBlast(player)
	local blasted = Machines.blast(player, Config.StrawBlastAmount) or 0
	return "Straw Blast! " .. Format.commas(blasted) .. " straws went off your haystack into your basket."
end

function grants.WheelSpin(player)
	return Wheel.spin(player)
end

-- Roblox calls this for every developer product purchase, retrying until we say granted.
local function processReceipt(info)
	local player = Players:GetPlayerByUserId(info.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if not PlayerData.waitFor(player, 15) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if PlayerData.hasReceipt(player, info.PurchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted -- already given
	end
	local name = nameOf(Config.Products, info.ProductId)
	local grant = name and grants[name]
	if not grant then
		warn("[Monetization] unknown product " .. tostring(info.ProductId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local ok, message = pcall(grant, player)
	if not ok then
		warn("[Monetization] couldn't grant " .. name .. ", Roblox will retry: " .. tostring(message))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	PlayerData.addReceipt(player, info.PurchaseId)
	PlayerData.save(player)
	Remotes.Announce:FireClient(player, { kind = "notice", text = message })
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function Monetization.init()
	PlayerData.onLoaded(checkPasses)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		local skin = purchased and skinPass(passId)
		if skin then
			grantSkin(player, skin)
			Remotes.Announce:FireClient(player, { kind = "notice", text = "Thank you! The " .. skin.name .. " is yours. Wear it from Finds & Skins." })
			return
		end
		local name = nameOf(Config.GamePasses, passId)
		if purchased and name then
			PlayerData.setPass(player, name, true)
			Remotes.Announce:FireClient(player, { kind = "notice", text = "Thank you! Your " .. name .. " pass is active." })
		end
	end)
	MarketplaceService.ProcessReceipt = processReceipt
end

return Monetization

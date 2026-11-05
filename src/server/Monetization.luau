-- Robux items. Every ID in Config.GamePasses and Config.Products starts at 0 (switched off);
-- create the item on the Creator Dashboard after publishing, then paste its ID into Config.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))(Config)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local PlayerData = require(script.Parent.PlayerData)
local Rounds = require(script.Parent.Rounds)

local Monetization = {}

local function passName(id)
	for name, passId in pairs(Config.GamePasses) do
		if passId ~= 0 and passId == id then
			return name
		end
	end
	return nil
end

local function productName(id)
	for name, productId in pairs(Config.Products) do
		if productId ~= 0 and productId == id then
			return name
		end
	end
	return nil
end

local function checkPasses(player)
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
end

-- Roblox calls this for every developer product purchase, retrying until we say granted.
local function processReceipt(info)
	local player = Players:GetPlayerByUserId(info.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local data = PlayerData.waitFor(player, 15)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if PlayerData.hasReceipt(player, info.PurchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted -- already given
	end
	local name = productName(info.ProductId)
	if name == "ClueHint" then
		if not Rounds.giveClue(player) then
			-- no clue left to give (all found, or between cases): pay coins instead
			PlayerData.addCoins(player, Economy.coinsFor(Economy.power(data.tool) * 100, PlayerData.multiplier(player)))
			Remotes.Announce:FireClient(player, { kind = "notice", text = "No clue left in this case, so you got coins instead." })
		end
	else
		warn("[Monetization] unknown product " .. tostring(info.ProductId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	PlayerData.addReceipt(player, info.PurchaseId)
	PlayerData.save(player)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function Monetization.init()
	Players.PlayerAdded:Connect(checkPasses)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(checkPasses, player)
	end
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		local name = passName(passId)
		if purchased and name then
			PlayerData.setPass(player, name, true)
			Remotes.Announce:FireClient(player, { kind = "notice", text = "Thank you! Your pass is active." })
		end
	end)
	MarketplaceService.ProcessReceipt = processReceipt
end

return Monetization

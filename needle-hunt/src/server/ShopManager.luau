-- Cosmetics and purchases. With Haystack Coins: buy a cosmetic (Remotes.Shop "buy"), and wear
-- what you own ("equip"); the server checks the price, your coins and that you own it. With
-- Robux (MarketplaceService): game passes (2x Coins, Extra Hint, Supporter) are checked on join
-- and after a purchase; the Starter Bundle product goes through ProcessReceipt, which records
-- each receipt in the save so a repeated receipt is never paid twice, and only reports success
-- once the save has been written. What you wear shows on your character: a trail and a title.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Cosmetics = require(Shared:WaitForChild("Cosmetics"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local DataManager = require(script.Parent.DataManager)

local ShopManager = {}

local function rgb(c)
	return Color3.fromRGB(c[1], c[2], c[3])
end

-- Puts on (or takes off) the trail and title a player wears.
function ShopManager.dress(player)
	local d = DataManager.get(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local head = character and character:FindFirstChild("Head")
	if not d or not root or not head then
		return
	end
	for _, name in ipairs({ "CosmeticTrail", "CosmeticA0", "CosmeticA1" }) do
		local old = root:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end
	local trail = Cosmetics.get(d.equipped.trail or "")
	if trail then
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Name, a1.Name = "CosmeticA0", "CosmeticA1"
		a0.Position, a1.Position = Vector3.new(0, 0.8, 0.4), Vector3.new(0, -0.8, 0.4)
		a0.Parent, a1.Parent = root, root
		local t = Instance.new("Trail")
		t.Name = "CosmeticTrail"
		t.Attachment0, t.Attachment1 = a0, a1
		t.Color = ColorSequence.new(rgb(trail.colours[1]), rgb(trail.colours[2]))
		t.Transparency = NumberSequence.new(0.3, 1)
		t.Lifetime, t.LightEmission = 0.6, 0.4
		t.Parent = root
	end
	local old = head:FindFirstChild("CosmeticTitle")
	if old then
		old:Destroy()
	end
	local title = Cosmetics.get(d.equipped.title or "")
	if title then
		local board = Instance.new("BillboardGui")
		board.Name = "CosmeticTitle"
		board.Size, board.StudsOffset, board.MaxDistance = UDim2.fromOffset(200, 30), Vector3.new(0, 2.4, 0), 60
		local label = Instance.new("TextLabel")
		label.Size, label.BackgroundTransparency = UDim2.fromScale(1, 1), 1
		label.Font, label.TextScaled, label.Text = Enum.Font.BuilderSansBold, true, title.name
		label.TextColor3, label.TextStrokeTransparency = rgb(title.colours[1]), 0.4
		label.Parent = board
		board.Parent = head
	end
end

local function buy(player, id)
	local item = Cosmetics.get(id)
	local d = DataManager.get(player)
	if not item or not d then
		return false, "That isn't for sale."
	elseif d.owned[id] then
		return false, "You already own " .. item.name .. "."
	elseif item.price <= 0 then
		return false, item.name .. " comes from " .. (item.source or "somewhere else") .. "."
	elseif d.coins < item.price then
		return false, "You need " .. (item.price - d.coins) .. " more coins."
	end
	DataManager.update(player, function(data)
		data.coins -= item.price
		data.owned[id] = true
		data.equipped[item.kind] = id
	end)
	ShopManager.dress(player)
	return true, "You bought " .. item.name .. "!"
end

local function equip(player, id)
	local item = Cosmetics.get(id)
	local d = DataManager.get(player)
	if not item or not d or not d.owned[id] then
		return false, "You don't own that."
	end
	DataManager.update(player, function(data)
		data.equipped[item.kind] = if data.equipped[item.kind] == id and not Cosmetics.defaults[item.kind] then nil else id
	end)
	ShopManager.dress(player)
	return true, nil
end

-- Game passes: owned ones become attributes (Pass_DoubleCoins...) the rest of the game reads.
local function passOwned(player, name, owned)
	player:SetAttribute("Pass_" .. name, owned)
	if owned and name == "Supporter" then
		DataManager.update(player, function(d)
			d.owned.t_supporter, d.owned.ti_supporter = true, true
		end)
	end
end

local function checkPasses(player)
	for name, id in pairs(Config.GamePasses) do
		if id ~= 0 then
			local ok, owned = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, id)
			passOwned(player, name, ok and owned)
		end
	end
end

-- Robux products: grant once per receipt, then save before telling Roblox it's done.
local function processReceipt(receipt)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local d = player and DataManager.get(player)
	if not d then
		return Enum.ProductPurchaseDecision.NotProcessedYet -- tried again when they're back
	end
	if table.find(d.receipts, receipt.PurchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted -- already given
	end
	if receipt.ProductId ~= Config.Products.StarterBundle or Config.Products.StarterBundle == 0 then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local bundle = Config.StarterBundle
	DataManager.update(player, function(data)
		data.coins += bundle.coins
		data.coinsEarned += bundle.coins
		if Cosmetics.get(bundle.cosmetic) then
			data.owned[bundle.cosmetic] = true
		end
		table.insert(data.receipts, receipt.PurchaseId)
		while #data.receipts > 50 do
			table.remove(data.receipts, 1)
		end
	end)
	-- not saved (or a session that can't save): Roblox offers the receipt again later, and the
	-- receipt list above stops it paying twice in this session
	if DataManager.unsaved(player) or not DataManager.save(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	Remotes.Notify:FireClient(player, { text = "Starter Bundle: +" .. bundle.coins .. " coins and a new needle skin. Thank you!", tone = "good" })
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function ShopManager.init()
	Remotes.Shop.OnServerInvoke = function(player, action, id)
		if type(action) ~= "string" or type(id) ~= "string" then
			return false, "?"
		end
		if action == "buy" then
			return buy(player, id)
		elseif action == "equip" then
			return equip(player, id)
		end
		return false, "?"
	end
	MarketplaceService.ProcessReceipt = processReceipt
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, bought)
		for name, id in pairs(Config.GamePasses) do
			if bought and id == passId then
				passOwned(player, name, true)
				Remotes.Notify:FireClient(player, { text = "Thank you! Your pass is active.", tone = "good" })
			end
		end
	end)
	DataManager.onLoaded(function(player)
		checkPasses(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.5)
			ShopManager.dress(player)
		end)
		if player.Character then
			ShopManager.dress(player)
		end
	end)
end

return ShopManager

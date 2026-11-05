-- Loose hay you can push around: press G to drop what you carry as a bundle; conveyors move
-- bundles; your trader's basket takes bundles and bales; bale makers turn bundles into bales
-- you can pick up (E), carry and drop (G). Straws lying loose are saved as `d.loose`, so
-- leaving never loses them: they go to your basket.
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local HayLook = require(Shared:WaitForChild("HayLook"))(Config)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local PlayerData = require(script.Parent.PlayerData)
local Plots = require(script.Parent.Plots)
local Hauling = require(script.Parent.Hauling)
local Build = require(script.Parent.Build)

local LooseHay = {}
local carrying = {} -- [player] = the bale they hold

local function looseFolder(plotIndex)
	local plot = Plots.folder(plotIndex)
	local folder = plot:FindFirstChild("Loose")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Loose"
		folder.Parent = plot
	end
	return folder
end

local function ownerOf(item)
	return Players:GetPlayerByUserId(item:GetAttribute("Owner") or 0)
end

-- The item's straws leave the loose count and go wherever `to` says ("basket" or "baler").
local function resolve(item, player)
	local straws = item:GetAttribute("Straws") or 0
	item:SetAttribute("Straws", 0) -- so a second touch in the same moment counts nothing
	item:Destroy()
	if player and straws > 0 then
		PlayerData.update(player, function(data)
			data.loose = math.max(0, data.loose - straws)
		end)
	end
	return straws
end

local function spawnBale(player, baler)
	local out = baler:FindFirstChild("BaleOut")
	local plotIndex = Plots.of(player)
	if not out or not plotIndex then
		return
	end
	local bale = Build.part({ name = "Bale", size = Vector3.new(6, 3, 4), cframe = out.CFrame, color = Config.HeapColour, material = "Grass", parent = nil })
	for _, x in ipairs({ -1.6, 1.6 }) do -- the two strings round the bale
		local twine = Build.part({ size = Vector3.new(0.15, 3.05, 4.05), cframe = out.CFrame * CFrame.new(x, 0, 0), color = { 120, 60, 40 }, material = "Fabric", collide = false })
		twine.Anchored = false
		local weld = Instance.new("WeldConstraint")
		weld.Part0, weld.Part1 = bale, twine
		weld.Parent = twine
		twine.Parent = bale
	end
	bale.Anchored = false
	bale:SetAttribute("Kind", "bale")
	bale:SetAttribute("Owner", player.UserId)
	bale:SetAttribute("Straws", Config.BaleStraws)
	bale:SetAttribute("Born", os.time())
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Pick up"
	prompt.ObjectText = "Hay bale"
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 9
	prompt:SetAttribute("Action", "pickup")
	prompt.Parent = bale
	bale.Parent = looseFolder(plotIndex)
	bale:SetNetworkOwner(nil)
	bale.AssemblyLinearVelocity = out.CFrame.LookVector * 8
	LooseHay.watch(bale)
	PlayerData.update(player, function(data)
		data.loose += Config.BaleStraws
		data.stats.bales_made += 1
	end)
end

-- What happens when a bundle or bale touches something.
function LooseHay.watch(item)
	item.Touched:Connect(function(hit)
		local player = ownerOf(item)
		local plotIndex = player and Plots.of(player)
		if not plotIndex or (item:GetAttribute("Straws") or 0) <= 0 or not hit:IsDescendantOf(Plots.folder(plotIndex)) then
			return
		end
		if hit.Name == "BasketSensor" then
			local baled = item:GetAttribute("Kind") == "bale"
			if carrying[player] == item then
				carrying[player] = nil
			end
			local straws = resolve(item, player)
			Hauling.add(player, straws, baled)
			Remotes.SearchFx:FireClient(player, { kind = "dumped", straws = straws, coins = 0, reason = if baled then "bale" else "belt", basket = hit.Parent:FindFirstChild("Basket") })
		elseif hit.Name == "BalerIntake" and item:GetAttribute("Kind") == "bundle" then
			local straws = resolve(item, player)
			local baler = hit.Parent
			PlayerData.update(player, function(data)
				data.baleStore += straws
			end)
			while true do
				local d = PlayerData.get(player)
				if not d or d.baleStore < Config.BaleStraws or not baler.Parent or not baler:FindFirstChild("BaleOut") then
					break -- what's left stays in baleStore (saved) for the next bundle
				end
				PlayerData.update(player, function(data)
					data.baleStore -= Config.BaleStraws
				end)
				spawnBale(player, baler)
				task.wait(0.6)
			end
		end
	end)
end

local function dropBale(player, bale)
	carrying[player] = nil
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	for _, w in ipairs(bale:GetChildren()) do
		if w:IsA("WeldConstraint") and w.Name == "Hold" then
			w:Destroy()
		end
	end
	if root then
		bale.CFrame = root.CFrame * CFrame.new(0, 0, -5)
	end
	bale.CanCollide, bale.Massless = true, false
	bale:SetNetworkOwner(nil)
end

local function drop(player)
	local bale = carrying[player]
	if bale and bale.Parent then
		return dropBale(player, bale)
	end
	local d, plotIndex = PlayerData.get(player), Plots.of(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not d or not plotIndex or not root or d.carried <= 0 then
		return
	end
	if not Plots.contains(plotIndex, root.Position, 0) then
		return Remotes.Announce:FireClient(player, { kind = "notice", text = "Drop hay on your own farm." })
	end
	if #looseFolder(plotIndex):GetChildren() >= Config.MaxLooseHay then
		return Remotes.Announce:FireClient(player, { kind = "notice", text = "Lots of loose hay lying about already. Get some to your basket first." })
	end
	local straws = d.carried
	local bundle = HayLook.lump(math.clamp(1.6 + straws / 1500, 1.6, 4), false)
	bundle.Name = "Bundle"
	bundle.CanCollide, bundle.CanTouch, bundle.CanQuery = true, true, true
	bundle.CFrame = root.CFrame * CFrame.new(0, 0.5, -3.5)
	bundle:SetAttribute("Kind", "bundle")
	bundle:SetAttribute("Owner", player.UserId)
	bundle:SetAttribute("Straws", straws)
	bundle:SetAttribute("Born", os.time())
	bundle.Parent = looseFolder(plotIndex)
	bundle:SetNetworkOwner(nil)
	PlayerData.update(player, function(data)
		data.carried -= straws
		data.loose += straws
		data.stats.drops += 1
	end)
	LooseHay.watch(bundle)
end

local function pickUp(player, bale)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or bale:GetAttribute("Owner") ~= player.UserId or (carrying[player] and carrying[player].Parent) then
		return
	end
	carrying[player] = bale
	bale.CanCollide, bale.Massless = false, true
	bale.CFrame = root.CFrame * CFrame.new(0, 1.5, -3.5)
	local hold = Instance.new("WeldConstraint")
	hold.Name = "Hold"
	hold.Part0, hold.Part1 = root, bale
	hold.Parent = bale
end

function LooseHay.init()
	Remotes.DropHay.OnServerEvent:Connect(drop)
	ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		if prompt:GetAttribute("Action") == "pickup" and prompt.Parent and prompt.Parent:GetAttribute("Kind") == "bale" then
			pickUp(player, prompt.Parent)
		end
	end)
	-- hay left lying (or fallen off the world) goes to its owner's basket by itself
	task.spawn(function()
		while true do
			task.wait(20)
			for _, player in ipairs(Players:GetPlayers()) do
				local plotIndex = Plots.of(player)
				for _, item in ipairs(plotIndex and looseFolder(plotIndex):GetChildren() or {}) do
					local old = os.time() - (item:GetAttribute("Born") or 0) > Config.LooseHayMinutes * 60
					if ownerOf(item) ~= player then
						item:Destroy() -- left behind by someone else; their straws are saved as theirs
					elseif (old and carrying[player] ~= item) or item.Position.Y < -20 then
						local baled = item:GetAttribute("Kind") == "bale"
						Hauling.add(player, resolve(item, player), baled)
					end
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		carrying[player] = nil
		local plotIndex = Plots.of(player)
		if plotIndex then
			looseFolder(plotIndex):ClearAllChildren() -- their straws are saved in d.loose
		end
	end)
end

-- On joining: hay that was lying loose last time is waiting in the basket.
function LooseHay.restore(d)
	d.basket += d.loose
	d.loose = 0
end

return LooseHay

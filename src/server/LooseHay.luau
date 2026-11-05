-- You and loose hay: press G to drop what you carry as a bundle; E picks up a bale, wrapped
-- bale or pellet sack, and G puts it down again. Hay left lying too long (or that falls off the
-- world) goes to its owner's basket by itself. The items themselves are in HayItems.luau and
-- what machines do with them in Processing.luau.
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local PlayerData = require(script.Parent.PlayerData)
local Plots = require(script.Parent.Plots)
local Hauling = require(script.Parent.Hauling)
local HayItems = require(script.Parent.HayItems)

local LooseHay = {}
local carrying = {} -- [player] = the item they hold

local function putDown(player, item)
	carrying[player] = nil
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	for _, w in ipairs(item:GetChildren()) do
		if w:IsA("WeldConstraint") and w.Name == "Hold" then
			w:Destroy()
		end
	end
	if root then
		item.CFrame = root.CFrame * CFrame.new(0, 0, -5)
	end
	item.CanCollide, item.Massless = true, false
	item:SetNetworkOwner(nil)
end

local function drop(player)
	local held = carrying[player]
	if held and held.Parent then
		return putDown(player, held)
	end
	local d, plotIndex = PlayerData.get(player), Plots.of(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not d or not plotIndex or not root or d.carried <= 0 then
		return
	end
	if not Plots.contains(plotIndex, root.Position, 0) then
		return Remotes.Announce:FireClient(player, { kind = "notice", text = "Drop hay on your own farm." })
	end
	local straws = d.carried
	if not HayItems.spawn(player, "bundle", straws, root.CFrame * CFrame.new(0, 0.5, -3.5)) then
		return Remotes.Announce:FireClient(player, { kind = "notice", text = "Lots of loose hay lying about already. Get some to your basket first." })
	end
	PlayerData.update(player, function(data)
		data.carried -= straws
	end)
end

local function pickUp(player, item)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or item:GetAttribute("Owner") ~= player.UserId or (carrying[player] and carrying[player].Parent) then
		return
	end
	carrying[player] = item
	item.CanCollide, item.Massless = false, true
	item.CFrame = root.CFrame * CFrame.new(0, 1.5, -3.5)
	local hold = Instance.new("WeldConstraint")
	hold.Name = "Hold"
	hold.Part0, hold.Part1 = root, item
	hold.Parent = item
end

function LooseHay.init()
	Remotes.DropHay.OnServerEvent:Connect(drop)
	ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		local item = prompt.Parent
		if prompt:GetAttribute("Action") == "pickup" and item and item:GetAttribute("Kind") then
			pickUp(player, item)
		end
	end)
	-- hay left lying (or fallen off the world) goes to its owner's basket by itself
	task.spawn(function()
		while true do
			task.wait(20)
			for _, player in ipairs(Players:GetPlayers()) do
				local plotIndex = Plots.of(player)
				for _, item in ipairs(plotIndex and HayItems.folder(plotIndex):GetChildren() or {}) do
					local old = os.time() - (item:GetAttribute("Born") or 0) > Config.LooseHayMinutes * 60
					if HayItems.ownerOf(item) ~= player then
						item:Destroy() -- left behind by someone else; their straws are saved as theirs
					elseif (old and carrying[player] ~= item) or item.Position.Y < -20 then
						local kind = item:GetAttribute("Kind")
						Hauling.add(player, HayItems.resolve(item, player), kind)
					end
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		carrying[player] = nil
		local plotIndex = Plots.of(player)
		if plotIndex then
			HayItems.folder(plotIndex):ClearAllChildren() -- their straws are saved in d.loose
		end
	end)
end

-- On joining: hay that was lying loose last time is waiting in the basket.
function LooseHay.restore(d)
	d.basket += d.loose
	d.loose = 0
end

return LooseHay

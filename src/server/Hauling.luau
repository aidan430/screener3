-- Hauling: everything you dump waits in your trader's basket. Every second the trader buys
-- Config.TraderRate straws and each truck you own takes its rate too (baled hay packs
-- BaleCompaction times tighter), paying you as it goes. Trucks visibly drive up to your stall.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))(Config)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local PlayerData = require(script.Parent.PlayerData)
local Plots = require(script.Parent.Plots)
local Achievements = require(script.Parent.Achievements)
local Build = require(script.Parent.Build)

local Hauling = {}
local earned = {} -- [player] = coins paid since the last coin shower on their screen
local trucks = Instance.new("Folder")
trucks.Name = "Trucks"
trucks.Parent = workspace

-- Puts what the player carries (and their silo) in their basket. Golden straw from the loft
-- is paid for at once. Returns straws moved and golden coins paid.
function Hauling.dump(player, reason, basket)
	local d = PlayerData.get(player)
	if not d or (d.carried + d.carriedGolden + d.siloStraw) <= 0 then
		return 0, 0
	end
	local mult = Economy.coinMultiplier(PlayerData.flags(player), d.needles)
	local straws = d.carried + d.siloStraw
	local golden = Economy.coinsFor(d.carriedGolden, true, mult)
	local total = straws + d.carriedGolden
	PlayerData.update(player, function(data)
		data.basket += straws
		data.coins += golden
		data.stats.straws_sold += data.carriedGolden
		data.stats.dumps += 1
		data.carried, data.carriedGolden, data.siloStraw = 0, 0, 0
	end)
	Remotes.SearchFx:FireClient(player, { kind = "dumped", straws = total, coins = golden, reason = reason, basket = basket })
	return total, golden
end

-- Loose hay or a bale that reached the basket by itself (conveyor, carried bale, timeout).
function Hauling.add(player, straws, baled)
	PlayerData.update(player, function(data)
		if baled then
			data.baled += straws
		else
			data.basket += straws
		end
	end)
end

local function sell(player)
	local d = PlayerData.get(player)
	if not d or (d.basket <= 0 and d.baled <= 0) then
		return
	end
	local room = Economy.haulRate(d) -- loose straws' worth this second
	local bales = math.min(d.baled, room * Config.BaleCompaction)
	room -= bales / Config.BaleCompaction
	local loose = math.min(d.basket, room)
	local coins = Economy.coinsFor(bales + loose, false, Economy.coinMultiplier(PlayerData.flags(player), d.needles))
	PlayerData.update(player, function(data)
		data.baled -= bales
		data.basket -= loose
		data.coins += coins
		data.stats.straws_sold += bales + loose
	end)
	earned[player] = (earned[player] or 0) + coins
end

-- A truck model: cab, box and wheels, welded to an anchored base so one tween moves it.
local function makeTruck(def)
	local model = Instance.new("Model")
	model.Name = def.name
	local w, h, l = def.size[1], def.size[2], def.size[3]
	local base = Build.part({ name = "Base", size = Vector3.new(w, 1, l), cframe = CFrame.new(), color = { 50, 50, 54 }, material = "Metal", collide = false, parent = model })
	local function add(size, offset, color, material, shape)
		local part = Build.part({ size = size, cframe = offset, color = color, material = material, shape = shape, collide = false, parent = model })
		part.Anchored = false
		local weld = Instance.new("WeldConstraint")
		weld.Part0, weld.Part1 = base, part
		weld.Parent = part
		return part
	end
	local cab = math.min(5, l * 0.3)
	add(Vector3.new(w, h * 0.7, cab), CFrame.new(0, h * 0.35 + 0.5, -l / 2 + cab / 2), def.color, "SmoothPlastic")
	add(Vector3.new(w * 0.9, h * 0.25, 0.2), CFrame.new(0, h * 0.5 + 0.5, -l / 2 - 0.05), { 150, 200, 230 }, "Glass")
	add(Vector3.new(w, h - 1, l - cab - 0.5), CFrame.new(0, h / 2, cab / 2 + 0.25), { 150, 104, 58 }, "WoodPlanks")
	for _, z in ipairs({ -l / 2 + 1.6, l / 2 - 1.6 }) do
		for _, x in ipairs({ -w / 2, w / 2 }) do
			add(Vector3.new(0.8, 2.2, 2.2), CFrame.new(x, 0.6, z), { 30, 30, 32 }, "SmoothPlastic", "Cylinder")
		end
	end
	model.PrimaryPart = base
	return model
end

-- The player's Trader's Stall model, if it's placed.
local function stallOf(player)
	local plotIndex = Plots.of(player)
	local built = plotIndex and Plots.folder(plotIndex):FindFirstChild("Built")
	for _, model in ipairs(built and built:GetChildren() or {}) do
		if model:GetAttribute("Item") == "trader" then
			return model
		end
	end
	return nil
end
Hauling.stallOf = stallOf

-- Walking up to your own basket with hay on you dumps it, no button needed.
local function autoDump(player)
	local d = PlayerData.get(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local stall = d and root and (d.carried + d.carriedGolden + d.siloStraw) > 0 and stallOf(player)
	local basket = stall and stall:FindFirstChild("Basket")
	if basket and (basket.Position - root.Position).Magnitude <= Config.AutoDumpRange then
		Hauling.dump(player, "trader", basket)
	end
end

-- A truck comes from the road to the ground in front of the player's stall, waits, and goes.
local function visit(player, def)
	local plotIndex = Plots.of(player)
	local stall = stallOf(player)
	if not stall then
		return
	end
	local pivot = stall:GetPivot()
	local stop = Vector3.new(pivot.Position.X, 1.2, pivot.Position.Z) + pivot.LookVector * Vector3.new(1, 0, 1) * 14
	local outward = Plots.centre(plotIndex).Unit
	local entrance = Plots.entrance(plotIndex)
	local road = Vector3.new(entrance.X, 1.2, entrance.Z) - outward * 26
	local truck = makeTruck(def)
	truck.PrimaryPart.CFrame = CFrame.lookAt(road, stop)
	truck.Parent = trucks
	local seconds = math.clamp((stop - road).Magnitude / 16, 2, 8)
	local arrive = TweenService:Create(truck.PrimaryPart, TweenInfo.new(seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { CFrame = CFrame.lookAt(stop, stop + (stop - road)) })
	arrive:Play()
	task.delay(seconds + 4, function()
		if truck.Parent then
			TweenService:Create(truck.PrimaryPart, TweenInfo.new(seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.In), { CFrame = CFrame.lookAt(road, road - (stop - road)) }):Play()
			task.delay(seconds + 0.2, function()
				truck:Destroy()
			end)
		end
	end)
end

function Hauling.init()
	task.spawn(function()
		local beat = 0
		while true do
			task.wait(1)
			beat += 1
			for _, player in ipairs(Players:GetPlayers()) do
				autoDump(player)
				sell(player)
				local d = PlayerData.get(player)
				if d and (d.basket > 0 or d.baled > 0) then -- each truck you own calls in turn
					for i, def in ipairs(Config.Trucks) do
						local count = d.trucks[def.id] or 0
						for n = 1, count do
							if (beat + i * 7 + n * 13) % Config.TruckTripSeconds == 0 then
								task.spawn(visit, player, def)
							end
						end
					end
				end
				if beat % 8 == 0 and (earned[player] or 0) > 0 then
					Remotes.SearchFx:FireClient(player, { kind = "paid", coins = earned[player] })
					earned[player] = 0
					Achievements.check(player)
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		earned[player] = nil
	end)
end

return Hauling

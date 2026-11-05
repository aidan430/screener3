-- Machines harvest the top of your pile into your silo every second, if your generators make
-- enough power. Also: the Straw Blast product, VIP offline harvesting, and height records.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))(Config)
local Format = require(Shared:WaitForChild("Format"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local PlayerData = require(script.Parent.PlayerData)
local Plots = require(script.Parent.Plots)
local Piles = require(script.Parent.Piles)
local Structures = require(script.Parent.Structures)
local Achievements = require(script.Parent.Achievements)
local Search = require(script.Parent.Search)

local Machines = {}
local carry = {} -- [player] = machine straws not yet whole
local running = {} -- [player] = were the machines fully powered last tick

local function character(player)
	local c = player.Character
	local humanoid = c and c:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return c
end

-- Takes `amount` straws from the outside of the heap inwards (machines, Straw Blast). Returns straws taken.
local function fromTop(player, d, amount)
	local plotIndex = Plots.of(player)
	local taken = 0
	while plotIndex and amount > 0 do
		local top = Piles.next(d)
		if not top then
			break
		end
		local got, gone = Piles.take(plotIndex, d, top, amount)
		if got <= 0 then
			break
		end
		taken += got
		amount -= got
		if gone and top == d.needleClump then
			Search.needleFound(player, false, Piles.position(plotIndex, top))
			break
		end
	end
	d.stats.total_searched += taken
	return taken
end

function Machines.blast(player, amount)
	local d = PlayerData.get(player)
	if not d then
		return 0
	end
	local taken = fromTop(player, d, amount)
	PlayerData.update(player, function(data)
		data.carried += taken -- sold straight away below
	end)
	Search.sell(player, "auto")
	return taken
end

local function tickMachines()
	for _, player in ipairs(Players:GetPlayers()) do
		local d = PlayerData.get(player)
		if d and Plots.of(player) then
			local flags = PlayerData.flags(player)
			local plot = Economy.plot(d.placed, flags.doubleMachines)
			local powered = plot.machines > 0 and plot.share >= 1
			if running[player] ~= powered then
				running[player] = powered
				Structures.light(player, powered)
			end
			local space = Economy.silo(d.silo).size - d.siloStraw
			local rate = plot.rate + (carry[player] or 0)
			carry[player] = rate - math.floor(rate)
			local amount = math.min(math.floor(rate), space)
			if amount > 0 then
				local taken = fromTop(player, d, amount)
				PlayerData.update(player, function(data)
					data.siloStraw += taken
				end)
				if flags.autoSell and Economy.silo(d.silo).size - d.siloStraw <= 0 then
					Search.sell(player, "auto")
				end
			end
		end
	end
end

-- Records how high each player has stood on their own plot (the Sky High achievement).
local function tickHeights()
	for _, player in ipairs(Players:GetPlayers()) do
		local d, plotIndex, c = PlayerData.get(player), Plots.of(player), character(player)
		local root = c and c:FindFirstChild("HumanoidRootPart")
		if d and plotIndex and root and Plots.contains(plotIndex, root.Position, 0) and root.Position.Y - 3 > d.stats.best_height then
			PlayerData.update(player, function(data)
				data.stats.best_height = math.floor(root.Position.Y - 3)
			end)
			Achievements.check(player)
		end
	end
end

-- VIP: machines kept working for up to an hour after the player left (call before building the pile).
function Machines.offline(player)
	local d = PlayerData.get(player)
	if not d or d.lastSeen <= 0 or not PlayerData.flags(player).vip then
		return
	end
	local seconds = math.clamp(os.time() - d.lastSeen, 0, Config.VipOfflineSeconds)
	local plot = Economy.plot(d.placed, PlayerData.flags(player).doubleMachines)
	local amount = math.min(math.floor(plot.rate * seconds), Economy.silo(d.silo).size - d.siloStraw)
	if amount > 0 then
		local taken = fromTop(player, d, amount)
		PlayerData.update(player, function(data)
			data.siloStraw += taken
		end)
		task.delay(8, function()
			Remotes.Announce:FireClient(player, { kind = "notice", text = "Your machines harvested " .. Format.commas(taken) .. " straws while you were away (VIP)." })
		end)
	end
end

function Machines.init()
	Players.PlayerRemoving:Connect(function(player)
		carry[player], running[player] = nil, nil
	end)
	task.spawn(function()
		local beat = 0
		while true do
			task.wait(1)
			beat += 1
			tickMachines()
			if beat % 2 == 0 then
				tickHeights()
			end
		end
	end)
end

return Machines

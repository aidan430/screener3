-- Stamina: each harvest click spends some (Config.Stamina) and it refills all the time. Out of
-- breath, you rest a moment until it's back to `recover`: never a punishment, just a breather.
-- Fitness upgrades (d.fitness, bought in the shop) raise the bar, the refill and walking speed.
-- Shown to the client as the attributes Stamina, StaminaMax and Winded.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local PlayerData = require(script.Parent.PlayerData)

local Stamina = {}
local state = {} -- [player] = { value, winded, windedAt }
local TICK = 0.2

-- The total bonus of the fitness upgrades with this stat ("max", "regen" or "walk").
local function bonus(d, stat)
	local total = 0
	for _, f in ipairs(Config.Fitness) do
		if f.stat == stat then
			total += f.per_level * ((d and d.fitness and d.fitness[f.id]) or 0)
		end
	end
	return total
end

function Stamina.max(d)
	return Config.Stamina.max + bonus(d, "max")
end

function Stamina.regen(d)
	return Config.Stamina.regenPerSecond + bonus(d, "regen")
end

function Stamina.walkSpeed(d)
	return Config.Stamina.walkSpeed + bonus(d, "walk")
end

-- What fitness level `level` (1 = the first) costs.
function Stamina.price(f, level)
	return math.floor(f.price * f.growth ^ (level - 1))
end

local function publish(player, s, d)
	player:SetAttribute("Stamina", math.floor(s.value + 0.5))
	player:SetAttribute("StaminaMax", Stamina.max(d))
	player:SetAttribute("Winded", s.winded)
end

local function get(player, d)
	local s = state[player]
	if not s then
		s = { value = Stamina.max(d), winded = false, windedAt = 0 }
		state[player] = s
		publish(player, s, d)
	end
	return s
end

-- Spends `amount` if the player has breath for it. Returns true if they did.
function Stamina.spend(player, amount)
	local d = PlayerData.get(player)
	if not d then
		return false
	end
	local s = get(player, d)
	if s.winded then
		return false
	end
	s.value = math.max(0, s.value - amount)
	if s.value <= 0 then
		s.winded, s.windedAt = true, os.clock()
	end
	publish(player, s, d)
	return true
end

-- Light Boots: the server sets the walking speed on spawn and after a purchase.
function Stamina.applyWalk(player)
	local d = PlayerData.get(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if d and humanoid then
		humanoid.WalkSpeed = Stamina.walkSpeed(d)
	end
	if d then
		publish(player, get(player, d), d) -- a new StaminaMax shows at once
	end
end

local function watch(player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid", 10)
		Stamina.applyWalk(player)
	end)
end

function Stamina.init()
	Players.PlayerAdded:Connect(watch)
	for _, player in ipairs(Players:GetPlayers()) do
		watch(player)
	end
	PlayerData.onLoaded(function(player)
		Stamina.applyWalk(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		state[player] = nil
	end)
	task.spawn(function()
		while true do
			local dt = task.wait(TICK)
			for player, s in pairs(state) do
				local d = PlayerData.get(player)
				local top = Stamina.max(d)
				local resting = s.winded and os.clock() - s.windedAt < Config.Stamina.regenDelay
				if d and not resting and s.value < top then
					local before = math.floor(s.value + 0.5)
					s.value = math.min(top, s.value + Stamina.regen(d) * dt)
					local back = s.winded and s.value >= math.min(Config.Stamina.recover, top)
					if back then
						s.winded = false
					end
					if back or math.floor(s.value + 0.5) ~= before then
						publish(player, s, d)
					end
				end
			end
		end
	end)
end

return Stamina

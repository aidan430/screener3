-- Pokes, the Power Poke and the Thimble (Config.Combo, Power, Guard, HitCheck). The client only
-- ever says what it wants (Remotes.Poke: who it aimed at, and whether it let a full charge go;
-- Remotes.Charge and Remotes.Guard: holding or not); every time, distance, wall and heart is the
-- server's:
--   a poke lands if the target was within reach (plus the lunge) at some moment in the last
--   fraction of a second (server/Rewind: what the attacker saw), roughly in front, no wall between;
--   a landed poke makes the next one quicker (a ONE-TWO), a blocked one slower;
--   a Power Poke needs a full charge the server timed itself, takes 2 hearts and pops a Thimble;
--   a Thimble blocks pokes and throws from any side while it's up (server/Combat.damage asks here).
-- Attributes others read: Guarding, Charging, PokeAt and GuardAt (server times they're ready again).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Combat = require(script.Parent.Combat)
local Rewind = require(script.Parent.Rewind)

local CombatPoke = {}
local C, K, P, G, L, H = Config.Combat, Config.Combo, Config.Power, Config.Guard, Config.Lunge, Config.HitCheck
local states = {}

local function state(player)
	local s = states[player]
	if not s then
		s = { ready = 0, guardReady = 0, rate = {} }
		states[player] = s
	end
	return s
end

local function allow(player, name) -- a few messages a second each; the rest are dropped
	local r, now = state(player).rate, os.clock()
	local w = r[name]
	if not w or now - w[1] >= 1 then
		w = { now, 0 }
		r[name] = w
	end
	w[2] += 1
	return w[2] <= Config.Rate[name]
end

local function alive(player)
	local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	return h ~= nil and h.Health > 0 and Combat.toolOf(player) ~= nil
end

local function endCharge(player)
	local s = state(player)
	if s.chargeFrom then
		s.chargeFrom = nil
		player:SetAttribute("Charging", nil)
	end
end

local function dropGuard(player, popped)
	local s = state(player)
	if s.guardSince then
		s.guardSince = nil
		local wait = if popped then G.popped else G.cooldown
		s.guardReady = os.clock() + wait
		player:SetAttribute("Guarding", nil)
		player:SetAttribute("GuardAt", workspace:GetServerTimeNow() + wait)
	end
end

local function setReady(player, seconds)
	state(player).ready = os.clock() + seconds
	player:SetAttribute("PokeAt", workspace:GetServerTimeNow() + seconds)
end

-- Could `attacker` have reached `target` just now? Their flat direction if so.
local function reaches(attacker, target, lunge)
	local a = attacker.Character and attacker.Character:FindFirstChild("HumanoidRootPart")
	if not a or not (target.Character and target.Character:FindFirstChild("HumanoidRootPart")) then
		return nil
	end
	local range = C.reach + lunge + H.pad
	local params = RaycastParams.new()
	params.FilterType, params.RespectCanCollide = Enum.RaycastFilterType.Exclude, true
	local characters = {}
	for _, p in ipairs(Players:GetPlayers()) do
		table.insert(characters, p.Character)
	end
	params.FilterDescendantsInstances = characters
	for _, sample in ipairs(Rewind.samples(target, Rewind.window(attacker))) do
		local offset = sample.p - a.Position
		local flat = Vector3.new(offset.X, 0, offset.Z)
		if flat.Magnitude <= range and math.abs(offset.Y) <= H.up then
			local facing = flat.Magnitude < 2
			for _, mine in ipairs(Rewind.samples(attacker, 0.25)) do
				facing = facing or (mine.look.Magnitude > 0 and mine.look.Unit:Dot(flat.Unit) >= 0)
			end
			local from = a.Position + Vector3.new(0, 1.5, 0)
			if facing and not workspace:Raycast(from, sample.p + Vector3.new(0, 0.5, 0) - from, params) then
				return if flat.Magnitude > 0.1 then flat.Unit else a.CFrame.LookVector
			end
		end
	end
	return nil
end

local function poke(attacker, targetId, power)
	if not allow(attacker, "Poke") or not alive(attacker) or attacker:GetAttribute("NeedleAway") or attacker:GetAttribute("Guarding") then
		return
	end
	local s, now = state(attacker), os.clock()
	power = power == true
	if power then
		local full = s.chargeFrom and now - s.chargeFrom >= P.charge - H.forgive
		endCharge(attacker)
		if not full then
			return -- not charged: nothing happens (the press already poked)
		end
	elseif now < s.ready - H.forgive then
		return
	end
	Combat.jab(attacker)
	local amount = if power then P.damage else 1
	local kind = if power then "power" else "poke"
	local result = nil
	local combo = if not power and s.chain and now - s.chain <= K.window then 2 else 1
	if type(targetId) == "string" and #targetId <= 8 then -- a Practice Yard dummy (server/Practice checks it)
		result = Combat.onDummy and Combat.onDummy(attacker, targetId, amount, false) and "hit"
	elseif type(targetId) == "number" and Combat.inRound(attacker) then
		local target = Players:GetPlayerByUserId(targetId)
		if target and target ~= attacker and Combat.inRound(target) then
			local dir = reaches(attacker, target, if power then L.powerRange else L.range)
			if dir then
				result = Combat.damage(attacker, target, amount, { kind = kind, combo = combo, dir = dir })
			end
		end
	end
	if power then
		s.chain = nil
		setReady(attacker, P.cooldown)
	elseif result == "blocked" then
		s.chain = nil
		setReady(attacker, K.blocked)
	elseif result and combo == 1 then
		s.chain = now
		setReady(attacker, K.first)
	elseif result then
		s.chain = nil
		setReady(attacker, K.second)
	else
		s.chain = nil
		setReady(attacker, C.cooldown)
	end
end

function CombatPoke.init()
	Rewind.init()
	Remotes.Poke.OnServerEvent:Connect(poke)
	Remotes.Charge.OnServerEvent:Connect(function(player, on)
		if not allow(player, "Charge") then
			return
		elseif on == true and alive(player) and not player:GetAttribute("NeedleAway") and not player:GetAttribute("Guarding") then
			local s = state(player)
			s.chargeFrom = math.max(os.clock(), s.ready) -- never counts from before the poke is ready
			player:SetAttribute("Charging", true)
		else
			endCharge(player)
		end
	end)
	Remotes.Guard.OnServerEvent:Connect(function(player, on)
		if not allow(player, "Guard") then
			return
		end
		local s = state(player)
		if on == true and alive(player) and not s.guardSince and os.clock() >= s.guardReady - H.forgive then
			endCharge(player)
			s.guardSince = os.clock()
			player:SetAttribute("Guarding", true)
		elseif on ~= true then
			dropGuard(player, false)
		end
	end)
	Combat.guard = function(target, kind) -- asked by Combat.damage: does a Thimble stop this?
		if not state(target).guardSince then
			return nil
		elseif kind == "power" then
			dropGuard(target, true)
			return "broken"
		end
		return "blocked"
	end
	Combat.onHurt = endCharge -- losing a heart ends a charge
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)
	task.spawn(function() -- a Thimble comes down by itself; nobody charges for ever, or while tagged out
		while true do
			task.wait(0.1)
			local now = os.clock()
			for player, s in pairs(states) do
				local ok = alive(player)
				if s.guardSince and (not ok or now - s.guardSince >= G.max) then
					dropGuard(player, false)
				end
				if s.chargeFrom and (not ok or now - s.chargeFrom >= P.charge + P.auto + 0.5) then
					endCharge(player)
				end
			end
		end
	end)
end

return CombatPoke

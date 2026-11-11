-- Throwing your needle (Config.Throw). The client sends where it's aiming (Remotes.Throw); the
-- server checks you're in the round's search, holding your needle, off cooldown, and that the aim
-- is a real direction, then traces the flight from your head: a sphere the needle's width along
-- the aim, up to its range, stopped by the first wall or player. Everyone's screen draws the
-- flight (Remotes.Thrown); a player hit loses Config.Throw.damage hearts when it arrives
-- (server/Combat.damage, with the same safe-time rules as a poke). The needle is out of your hand
-- until it comes back, so you can't poke in the meantime.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Needles = require(Shared:WaitForChild("Needles"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local DataManager = require(script.Parent.DataManager)
local Combat = require(script.Parent.Combat)

local CombatThrow = {}
local T = Config.Throw
local lastThrow = {}
local backAt = {} -- [player] = when their thrown needle is back (os.clock)

local function setAway(player, tool, away)
	player:SetAttribute("NeedleAway", away or nil)
	for _, part in ipairs(tool:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "Handle" then
			if away then
				part:SetAttribute("Was", part.Transparency)
				part.Transparency = 1
			else
				part.Transparency = part:GetAttribute("Was") or 0
			end
		end
	end
end

local function throw(player, aim)
	local now = os.clock()
	local tool = Combat.toolOf(player)
	local head = player.Character and player.Character:FindFirstChild("Head")
	if typeof(aim) ~= "Vector3" or aim.Magnitude < 0.5 or aim.Magnitude > 2 or aim ~= aim then
		return -- not a direction (or not a number)
	elseif not tool or not head or not (Combat.inRound(player) or player:GetAttribute("Practicing")) or player:GetAttribute("NeedleAway") or player:GetAttribute("Guarding") then
		return -- (no throwing from behind a Thimble)
	elseif now - (lastThrow[player] or 0) < T.cooldown then
		return
	end
	lastThrow[player] = now
	backAt[player] = now + T.back -- for a catch (Config.Catch): one try a throw
	local dir = aim.Unit
	local params = RaycastParams.new()
	params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, { player.Character }
	local origin = head.Position + dir * 1.5
	local skip = { player.Character }
	local hit = nil
	for _ = 1, 4 do -- a throw passes over anyone sliding, unless it's aimed down at them
		hit = workspace:Spherecast(origin, T.radius, dir * T.range, params)
		local struck = hit and Players:GetPlayerFromCharacter(hit.Instance:FindFirstAncestorOfClass("Model"))
		local root = struck and struck.Character:FindFirstChild("HumanoidRootPart")
		if not (root and struck:GetAttribute("Stance") == "slide" and hit.Position.Y > root.Position.Y - 0.4) then
			break
		end
		table.insert(skip, struck.Character)
		params.FilterDescendantsInstances = skip
	end
	local finish = if hit then hit.Position else origin + dir * T.range
	local target = hit and Players:GetPlayerFromCharacter(hit.Instance:FindFirstAncestorOfClass("Model"))
	local dummy = hit and hit.Instance:FindFirstAncestorOfClass("Model") -- a Practice Yard dummy?
	local dummyId = dummy and dummy:GetAttribute("DummyOwner") == player.UserId and dummy:GetAttribute("DummyId")
	local seconds = (finish - origin).Magnitude / T.speed
	local d = DataManager.get(player)
	Remotes.Thrown:FireAllClients({ from = player.UserId, key = d and d.showcase or "", origin = origin, finish = finish, seconds = seconds, hitPlayer = target ~= nil or dummyId ~= nil })
	setAway(player, tool, true)
	task.delay(seconds, function()
		if dummyId and Combat.onDummy then
			Combat.onDummy(player, dummyId, T.damage, true)
		elseif target then
			local d2 = DataManager.get(player)
			local _, skinId = Needles.split(d2 and d2.showcase or "")
			local oneOfOne = skinId ~= nil and Needles.skin(skinId).rarity == "unique" -- a 1 of 1 in hand: one throw tags out
			Combat.damage(player, target, if oneOfOne then Config.OneOfOne.throwDamage else T.damage)
		end
	end)
	task.delay(T.back, function() -- the needle comes back to your hand
		if tool.Parent then
			setAway(player, tool, false)
		else
			player:SetAttribute("NeedleAway", nil)
		end
	end)
end

function CombatThrow.init()
	Remotes.Throw.OnServerEvent:Connect(throw)
	Remotes.Catch.OnServerEvent:Connect(function(player)
		local at = backAt[player]
		backAt[player] = nil -- the try is spent, caught or not
		local now = os.clock()
		if at and now >= at - Config.Catch.early and now <= at + Config.Catch.late then
			lastThrow[player] = (lastThrow[player] or 0) - Config.Catch.gain
			player:SetAttribute("CaughtAt", workspace:GetServerTimeNow())
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastThrow[player], backAt[player] = nil, nil
	end)
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			player:SetAttribute("NeedleAway", nil) -- a fresh needle after a respawn
		end)
	end)
end

return CombatThrow

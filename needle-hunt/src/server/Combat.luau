-- Needle combat. Everyone carries their showcase needle as a tool (the "Needle", rebuilt when the
-- showcase changes) and can inspect it anywhere (Remotes.Inspect: the needle lifts and turns in
-- the hand, and everyone sees it). During a round's search, a poke (Remotes.Poke, with the player
-- aimed at) takes one heart if the server agrees it can land: both in the round, close enough
-- (Config.Combat.reach), roughly in front, off cooldown, and the target not just back in. Three
-- hearts gone and you're tagged out: you pop back at a maze start after Config.Combat.respawn
-- seconds (server/RoundManager puts respawning players back in the maze), safe for a moment.
-- Every needle pokes the same: skins are looks only.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Needles = require(Shared:WaitForChild("Needles"))
local NeedleLook = require(Shared:WaitForChild("NeedleLook"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local DataManager = require(script.Parent.DataManager)
local RewardManager = require(script.Parent.RewardManager)

local Combat = {}
local C, T = Config.Combat, Config.NeedleTool
local round = nil
local lastPoke, lastHit, moving = {}, {}, {}

local function baseGrip()
	return CFrame.Angles(math.rad(T.grip[1]), math.rad(T.grip[2]), math.rad(T.grip[3]))
end

local function toolOf(player)
	local character = player.Character
	return character and character:FindFirstChild("Needle")
end

-- Builds (or rebuilds) a player's Needle tool from their showcase needle.
function Combat.giveTool(player)
	local d = DataManager.get(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return
	end
	local key = if d and d.showcase ~= "" then d.showcase else "sewing:steel"
	local typeId, skinId = Needles.split(key)
	typeId, skinId = typeId or "sewing", skinId or "steel"
	for _, holder in ipairs({ backpack, player.Character }) do
		local old = holder and holder:FindFirstChild("Needle")
		if old then
			old:Destroy()
		end
	end
	local model = NeedleLook.build(typeId, skinId, T.scale, 2)
	local cf, size = model:GetBoundingBox()
	local tool = Instance.new("Tool")
	tool.Name, tool.ToolTip, tool.CanBeDropped, tool.Grip = "Needle", Needles.name(typeId, skinId), false, baseGrip()
	local handle = Instance.new("Part")
	handle.Name, handle.Size, handle.Transparency, handle.CanCollide, handle.Massless = "Handle", Vector3.one * 0.4, 1, false, true
	handle.CFrame = CFrame.new(cf.Position.X - size.X / 2 + 0.5, 0, 0) -- held near the eye end, point outwards
	handle.Parent = tool
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored, part.Massless = false, true
			local weld = Instance.new("WeldConstraint")
			weld.Part0, weld.Part1 = handle, part
			weld.Parent = part
			part.Parent = tool
		end
	end
	model:Destroy()
	tool.Parent = backpack
end

-- The tool's little moves, done here so everyone sees them: a jab, and the inspect.
local function play(player, steps)
	local tool = toolOf(player)
	if not tool or moving[player] then
		return
	end
	moving[player] = true
	for _, step in ipairs(steps) do
		local tween = TweenService:Create(tool, TweenInfo.new(step[2], Enum.EasingStyle.Sine), { Grip = step[1] })
		tween:Play()
		tween.Completed:Wait()
	end
	moving[player] = nil
end

local function jab(player)
	local g = baseGrip()
	task.spawn(play, player, { { CFrame.new(0, 0, -1.2) * g, 0.08 }, { g, 0.16 } })
end

local function inspect(player)
	local g, up = baseGrip(), CFrame.new(0, 0.8, -0.4) * CFrame.Angles(math.rad(-55), 0, 0)
	local third = T.inspect / 6
	task.spawn(play, player, {
		{ up * g, third }, -- lifts it to look at
		{ up * g * CFrame.Angles(math.rad(120), 0, 0), third }, -- and turns it round its length
		{ up * g * CFrame.Angles(math.rad(240), 0, 0), third },
		{ up * g * CFrame.Angles(math.rad(360), 0, 0), third },
		{ up * CFrame.Angles(0, 0, math.rad(25)) * g, third }, -- a last tilt to catch the light
		{ g, third },
	})
end

local function inRound(player)
	return round ~= nil and round.participants[player] == true and ReplicatedStorage:GetAttribute("Phase") == "search"
end
Combat.inRound = inRound

local function tagOut(attacker, target, humanoid)
	DataManager.update(attacker, function(d)
		d.eliminations += 1
	end)
	RewardManager.track(attacker, "elims", 1)
	local coins = C.eliminationCoins * (if RewardManager.hasPass(attacker, "DoubleCoins") then 2 else 1)
	RewardManager.grant(attacker, coins, 0, nil)
	Remotes.Notify:FireClient(attacker, { text = "You tagged out " .. target.DisplayName .. "! +" .. coins .. " coins", tone = "good" })
	Remotes.Notify:FireClient(target, { text = attacker.DisplayName .. " tagged you out! Back in " .. C.respawn .. "...", tone = "bad" })
	humanoid.BreakJointsOnDeath = false -- a soft pop, not falling apart
	humanoid.Health = 0
end

local function poke(attacker, targetId)
	local now = os.clock()
	if now - (lastPoke[attacker] or 0) < C.cooldown then
		return
	end
	lastPoke[attacker] = now
	if attacker:GetAttribute("NeedleAway") then
		return -- it's flying: nothing in your hand to poke with
	end
	jab(attacker)
	if not inRound(attacker) or type(targetId) ~= "number" then
		return
	end
	local target = Players:GetPlayerByUserId(targetId)
	local a = attacker.Character and attacker.Character:FindFirstChild("HumanoidRootPart")
	local b = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
	local humanoid = b and target.Character:FindFirstChildOfClass("Humanoid")
	if not toolOf(attacker) or not humanoid or humanoid.Health <= 0 or not inRound(target) or target == attacker then
		return
	end
	local offset = b.Position - a.Position
	local flat = Vector3.new(offset.X, 0, offset.Z)
	if offset.Magnitude > C.reach + 1 or (flat.Magnitude > 0.5 and a.CFrame.LookVector:Dot(flat.Unit) < 0.2) then
		return -- too far, or behind you
	end
	Combat.damage(attacker, target, 1)
end

-- Takes `amount` hearts from `target` (a poke 1, a thrown needle Config.Combat.throwDamage), if
-- both are in the round, the target is alive and isn't in their safe time. Returns true if it hit.
function Combat.damage(attacker, target, amount)
	local root = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
	local humanoid = root and target.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or target == attacker or not inRound(attacker) or not inRound(target) then
		return false
	elseif (target:GetAttribute("SafeUntil") or 0) > workspace:GetServerTimeNow() then
		return false
	end
	attacker:SetAttribute("SafeUntil", 0) -- attacking ends your own safe time
	local hearts = math.max(0, (target:GetAttribute("Hearts") or C.hearts) - amount)
	target:SetAttribute("Hearts", hearts)
	lastHit[target] = os.clock()
	Remotes.Hit:FireAllClients({ from = attacker.UserId, to = target.UserId, hearts = hearts, position = root.Position, amount = amount })
	if hearts == 0 then
		tagOut(attacker, target, humanoid)
	end
	return true
end

Combat.toolOf = toolOf

function Combat.start(r)
	round = r
	for p in pairs(r.participants) do
		p:SetAttribute("Hearts", C.hearts)
	end
end

function Combat.stop()
	round = nil
end

function Combat.init()
	Players.RespawnTime = C.respawn
	Remotes.Poke.OnServerEvent:Connect(poke)
	Remotes.Inspect.OnServerEvent:Connect(function(player)
		if toolOf(player) then
			inspect(player)
		end
	end)
	local function joined(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.5)
			player:SetAttribute("Hearts", C.hearts)
			player:SetAttribute("SafeUntil", workspace:GetServerTimeNow() + C.safe)
			Combat.giveTool(player)
		end)
		player:GetAttributeChangedSignal("Showcase"):Connect(function()
			Combat.giveTool(player)
		end)
	end
	Players.PlayerAdded:Connect(joined)
	for _, p in ipairs(Players:GetPlayers()) do
		joined(p)
	end
	Players.PlayerRemoving:Connect(function(player)
		lastPoke[player], lastHit[player], moving[player] = nil, nil, nil
	end)
	task.spawn(function() -- hearts come back, one every Config.Combat.regen seconds without a hit
		while true do
			task.wait(1)
			for _, p in ipairs(Players:GetPlayers()) do
				local hearts = p:GetAttribute("Hearts") or C.hearts
				if hearts > 0 and hearts < C.hearts and os.clock() - (lastHit[p] or 0) >= C.regen then
					p:SetAttribute("Hearts", hearts + 1)
					lastHit[p] = os.clock()
				end
			end
		end
	end)
end

return Combat

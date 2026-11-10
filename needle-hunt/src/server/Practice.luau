-- The Time Trial in the Practice Yard (Config.Practice). From the lobby (the Practice stall, or
-- Practice in the menu) you get your own yard (server/PracticeYard): a countdown, then
-- Config.Practice.seconds to tag out every dummy and open every chest. Practice only: no coins,
-- XP, keys or needles. A full clear's time goes on the Fastest Time Trial board (your best, in
-- tenths, server/LeaderboardManager). The server times the run and checks every hit and chest.
-- Remotes.Practice (ask): "info" | "start" | "leave". Remotes.PracticeState (tell the player):
--   { phase = "countdown" | "running" | "done" | "off", ... } and { event = "hit" | "chest", ... }.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local DataManager = require(script.Parent.DataManager)
local AntiCheat = require(script.Parent.AntiCheat)
local Combat = require(script.Parent.Combat)
local LeaderboardManager = require(script.Parent.LeaderboardManager)
local LobbyBuilder = require(script.Parent.LobbyBuilder)
local PracticeYard = require(script.Parent.PracticeYard)

local Practice = {}
local P = Config.Practice
local runs = {} -- [player] = { slot, yard, phase, startAt, endsAt, tagged, opened, token }
local slots = {} -- [slot] = player

local function now()
	return workspace:GetServerTimeNow()
end

local function hold(player, on) -- still during the countdown
	local character = player.Character
	local h = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if h then
		h.WalkSpeed, h.JumpHeight = if on then 0 else 16, if on then 0 else 7.2
	end
	if root then
		root.Anchored = on
	end
end

local function move(player, cf)
	local character = player.Character
	if character then
		AntiCheat.allow(player, 3)
		character:PivotTo(cf)
	end
end

local function tell(player, run, extra)
	local msg = { phase = run.phase, startAt = run.startAt, endsAt = run.endsAt, tagged = run.tagged, opened = run.opened, dummies = #run.yard.dummies, chests = #run.yard.chests }
	for k, v in pairs(extra or {}) do
		msg[k] = v
	end
	Remotes.PracticeState:FireClient(player, msg)
end

function Practice.leave(player)
	local run = runs[player]
	if not run then
		return
	end
	runs[player] = nil
	slots[run.slot] = nil
	hold(player, false)
	player:SetAttribute("Practicing", nil)
	if player.Parent then
		move(player, LobbyBuilder.spawnPoint(math.random(1, 10)))
		Remotes.PracticeState:FireClient(player, { phase = "off" })
	end
	run.yard.model:Destroy()
end

local function finish(player, run, cleared)
	if run.phase ~= "running" then
		return
	end
	run.phase = "done"
	local time = now() - run.startAt
	local tenths = math.max(1, math.floor(time * 10 + 0.5))
	local best, newBest = 0, false
	DataManager.update(player, function(d)
		d.trialRuns += 1
		if cleared and (d.trialBest == 0 or tenths < d.trialBest) then
			d.trialBest, newBest = tenths, true
		end
		best = d.trialBest
	end)
	if newBest then
		LeaderboardManager.mark(player)
	end
	tell(player, run, { cleared = cleared, time = if cleared then tenths / 10 else nil, best = best / 10, newBest = newBest })
	local token = run.token
	task.delay(P.backAfter, function()
		if runs[player] and runs[player].token == token then
			Practice.leave(player)
		end
	end)
end

local function checkDone(player, run)
	if run.tagged >= #run.yard.dummies and run.opened >= #run.yard.chests then
		finish(player, run, true)
	end
end

-- A hit on one of your dummies (a poke takes 1 heart, a throw more). thrown = the server already
-- traced it, so no reach check.
function Practice.hitDummy(player, id, amount, thrown)
	local run = runs[player]
	if not run or run.phase ~= "running" or type(id) ~= "string" then
		return false
	end
	local target
	for _, d in ipairs(run.yard.dummies) do
		if d.id == id and not d.out then
			target = d
		end
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not target or not root then
		return false
	end
	if not thrown then
		local offset = target.root.Position - root.Position
		local flat = Vector3.new(offset.X, 0, offset.Z)
		if flat.Magnitude > Config.Combat.reach + 2.5 or math.abs(offset.Y) > 7 or (flat.Magnitude > 0.5 and root.CFrame.LookVector:Dot(flat.Unit) < 0.2) then
			return false -- too far, or behind you
		end
	end
	target.hearts = math.max(0, target.hearts - amount)
	target.label.Text = PracticeYard.heartsText(target.hearts)
	Remotes.PracticeState:FireClient(player, { event = "hit", position = target.root.Position + Vector3.new(0, 4, 0), hearts = target.hearts, amount = amount })
	if target.hearts == 0 then
		target.out = true
		target.model:SetAttribute("Out", true)
		run.tagged += 1
		for _, p in ipairs(target.model:GetDescendants()) do -- it tips over and fades away
			if p:IsA("BasePart") then
				TweenService:Create(p, TweenInfo.new(0.8, Enum.EasingStyle.Sine), { Transparency = 1 }):Play()
			end
		end
		target.label.Parent.Enabled = false
		tell(player, run)
		checkDone(player, run)
	end
	return true
end

local function openChest(player, run, c)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if run.phase ~= "running" or c.opened or not root or AntiCheat.flagged(player) then
		return
	elseif (root.Position - c.position).Magnitude > Config.Chests.reach + 3 then
		return
	elseif root.Position.Y < c.top + 1.5 then -- as in a round: climb up to it
		Remotes.Notify:FireClient(player, { text = "Climb up to it first!", tone = "bad" })
		return
	end
	c.opened, c.prompt.Enabled = true, false
	run.opened += 1
	local swing = c.hinge * CFrame.Angles(math.rad(-105), 0, 0) * CFrame.new(0, 0.3, -1.15)
	TweenService:Create(c.lid, TweenInfo.new(0.5, Enum.EasingStyle.Back), { CFrame = swing }):Play()
	Remotes.PracticeState:FireClient(player, { event = "chest", position = c.position })
	tell(player, run)
	checkDone(player, run)
end

function Practice.start(player)
	local d = DataManager.get(player)
	if runs[player] or not d or not player.Character or player:GetAttribute("InRound") then
		return false, "You can practise from the lobby."
	end
	local slot
	for i = 1, 20 do
		if not slots[i] then
			slot = i
			break
		end
	end
	if not slot then
		return false, "The Practice Yard is full: try again in a moment."
	end
	slots[slot] = player
	local yard = PracticeYard.build(player, slot)
	local run = { slot = slot, yard = yard, phase = "countdown", tagged = 0, opened = 0, token = {} }
	runs[player] = run
	player:SetAttribute("Practicing", true)
	for _, c in ipairs(yard.chests) do
		c.prompt.Triggered:Connect(function(who)
			if who == player then
				openChest(player, run, c)
			end
		end)
	end
	move(player, yard.start)
	hold(player, true)
	run.startAt = now() + P.countdown
	run.endsAt = run.startAt + P.seconds
	tell(player, run)
	task.delay(P.countdown, function()
		if runs[player] ~= run then
			return
		end
		hold(player, false)
		run.phase = "running"
		tell(player, run)
		task.delay(P.seconds, function()
			if runs[player] == run then
				finish(player, run, false) -- time's up
			end
		end)
	end)
	return true
end

function Practice.init()
	Combat.onDummy = Practice.hitDummy
	Remotes.Practice.OnServerInvoke = function(player, action)
		if action == "start" then
			return Practice.start(player)
		elseif action == "leave" then
			Practice.leave(player)
			return true
		elseif action == "info" then
			local d = DataManager.get(player)
			local rows = LeaderboardManager.cache().trial or {}
			return { best = d and d.trialBest / 10 or 0, runs = d and d.trialRuns or 0, top = { table.unpack(rows, 1, 5) }, running = runs[player] ~= nil }
		end
		return nil
	end
	Players.PlayerRemoving:Connect(Practice.leave)
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.3)
			local run = runs[player]
			if run then -- a fall: back to the start, the clock still running
				move(player, run.yard.start)
				if run.phase == "countdown" then
					hold(player, true)
				end
			end
		end)
	end)
end

return Practice

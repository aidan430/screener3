-- Show off (Remotes.ShowOff): hold your showcase needle (or your best) up over your head for a
-- few seconds, and everyone in the server is told what it is. Lobby only, with a cooldown.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Needles = require(Shared:WaitForChild("Needles"))
local NeedleLook = require(Shared:WaitForChild("NeedleLook"))
local Rules = require(Shared:WaitForChild("Rules"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local DataManager = require(script.Parent.DataManager)
local LobbySocial = require(script.Parent.LobbySocial)

local LobbyShowOff = {}
local lastShow = {}
local SHOW_COOLDOWN, SHOW_SECONDS = 15, 6

local function showOff(player)
	local d = DataManager.get(player)
	local head = player.Character and player.Character:FindFirstChild("Head")
	local phase = ReplicatedStorage:GetAttribute("Phase")
	if not d or not head or phase == "search" or phase == "countdown" or (lastShow[player] or 0) > os.clock() - SHOW_COOLDOWN then
		return
	end
	local entry = nil
	local t, s = Needles.split(d.showcase)
	if t then
		entry = { type = t, skin = s, value = Needles.value(t, s) }
	else
		entry = LobbySocial.ranked(d)[1]
	end
	if not entry then
		Remotes.Notify:FireClient(player, { text = "Find a needle first, then you'll have something to show off!", tone = "bad" })
		return
	end
	lastShow[player] = os.clock()
	local m = NeedleLook.build(entry.type, entry.skin, 1.6, 2)
	m:PivotTo(head.CFrame * CFrame.new(0, 3, 0) * CFrame.Angles(0, 0, math.rad(80)))
	for _, part in ipairs(m:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored, part.Massless = false, true
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = head, part
			w.Parent = part
		end
	end
	m.Parent = player.Character
	task.delay(SHOW_SECONDS, function()
		m:Destroy()
	end)
	local words = LobbySocial.describe(entry)
	Remotes.Notify:FireAllClients({ text = player.DisplayName .. " is showing off their " .. words .. " (worth " .. Rules.commas(entry.value) .. ")!", tone = "level" })
end

function LobbyShowOff.init()
	Remotes.ShowOff.OnServerEvent:Connect(showOff)
	Players.PlayerRemoving:Connect(function(player)
		lastShow[player] = nil
	end)
end

return LobbyShowOff

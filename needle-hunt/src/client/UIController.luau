-- Puts the whole UI together: one ScreenGui with the HUD, the round moments (Results), and the
-- Shop, Inventory, Quests, Leaderboard and Settings windows. It keeps your latest profile (sent
-- by the server on every change), opens one window at a time from the menu or a lobby stall's
-- prompt, and applies your settings (sound, effects, music).
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UiKit = require(script.Parent.UiKit)
local Effects = require(script.Parent.Effects)
local Hud = require(script.Parent.Hud)
local Results = require(script.Parent.Results)
local Screens = require(script.Parent.Screens)
local Screens2 = require(script.Parent.Screens2)
local Screens3 = require(script.Parent.Screens3)
local LobbyUi = require(script.Parent.LobbyUi)
local PowerupFx = require(script.Parent.PowerupFx)
local BoxScreen = require(script.Parent.BoxScreen)
local CombatFx = require(script.Parent.CombatFx)
local ThrowFx = require(script.Parent.ThrowFx)
local DashFx = require(script.Parent.DashFx)
local CooldownBars = require(script.Parent.CooldownBars)
local TradeScreen = require(script.Parent.TradeScreen)
local ViewModel = require(script.Parent.ViewModel)
local PracticeFx = require(script.Parent.PracticeFx)
local Aim = require(script.Parent.Aim)
local StreakFx = require(script.Parent.StreakFx)
local FeedFx = require(script.Parent.FeedFx)
local KeyHints = require(script.Parent.KeyHints)

local player = Players.LocalPlayer
local UIController = {}
local profile = {}
local windows, openers = {}, {}
local music = nil

local function getProfile()
	return profile
end

function UIController.open(name)
	for n, w in pairs(windows) do
		if n ~= name then
			w.Visible = false
		end
	end
	local w = windows[name]
	if not w then
		return
	end
	w.Visible = not w.Visible
	if w.Visible then
		UiKit.pop(w, 0.9)
		if openers[name] then
			task.spawn(openers[name])
		end
		Screens.refresh()
		Screens2.refresh()
	end
end

-- Closes whatever window is open (X, Backspace, or B on a controller). Returns whether one was.
function UIController.closeAll()
	local any = false
	for _, w in pairs(windows) do
		any = any or w.Visible
		w.Visible = false
	end
	return any
end

local function applySettings()
	local s = profile.settings or {}
	Effects.settings.sfx = s.sfx ~= false
	Effects.settings.reduceEffects = s.reduceEffects == true
	Effects.settings.music = s.music ~= false
	Aim.apply(s) -- sensitivity, field of view, reticle
	if music then
		music.Volume = if Effects.settings.music then 0.3 else 0
	end
end

function UIController.start()
	local gui = UiKit.make("ScreenGui", { Name = "NeedleUi", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = player:WaitForChild("PlayerGui") })
	Effects.mount(gui)
	Aim.mount(gui)
	Hud.mount(gui, UIController.open)
	Results.mount(gui, getProfile)
	for name, w in pairs(Screens.mount(gui, getProfile)) do
		windows[name] = w
	end
	local more, extra = Screens2.mount(gui, getProfile)
	for name, w in pairs(more) do
		windows[name] = w
	end
	for name, fn in pairs(extra) do
		openers[name] = fn
	end
	local col, colOpen = Screens3.mount(gui)
	for name, w in pairs(col) do
		windows[name] = w
	end
	for name, fn in pairs(colOpen) do
		openers[name] = fn
	end
	for _, screen in ipairs({ BoxScreen, TradeScreen, PracticeFx }) do
		local w, opener = screen.mount(gui, getProfile)
		for name, frame in pairs(w) do
			windows[name], openers[name] = frame, opener[name]
		end
	end
	PowerupFx.start(gui)
	CombatFx.start(gui)
	ThrowFx.start(gui)
	DashFx.start(gui)
	CooldownBars.start(gui)
	ViewModel.start()
	StreakFx.start(gui)
	FeedFx.start(gui)
	KeyHints.start(gui, UIController.closeAll) -- what each key does; X or Backspace closes menus
	LobbyUi.start(gui, function(userId) -- a booth's prompt: that player's collection
		Screens3.view(userId)
		if windows.Collection.Visible then
			Screens3.refresh()
		else
			UIController.open("Collection")
		end
	end)
	Remotes.Profile.OnClientEvent:Connect(function(p)
		profile = p
		applySettings()
		Screens.refresh()
		Screens2.refresh()
		TradeScreen.refresh()
	end)
	-- the lobby's Shop stall and Wardrobe open their screens
	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		local opens = prompt:GetAttribute("Opens")
		if opens and windows[opens] and not windows[opens].Visible then
			UIController.open(opens)
		end
	end)
	if Config.Music ~= "" then
		music = UiKit.make("Sound", { SoundId = Config.Music, Looped = true, Volume = 0.3, Parent = SoundService })
		music:Play()
	end
	applySettings()
end

return UIController

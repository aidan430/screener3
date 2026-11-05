-- Soft background music: the Config.Music playlist in a loop, low and relaxing, fading gently
-- from one track to the next. A small button (top right) turns it on and off for the session.
-- A track that won't load (a missing or private asset) is skipped quietly.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Ui = require(script.Parent.Ui)

local Music = {}
local on = true
local current = nil -- the Sound playing now
local button = nil

local function volume()
	return Config.MusicVolume or 0.25
end

local function fade(sound, goal, seconds)
	local tween = TweenService:Create(sound, TweenInfo.new(seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Volume = goal })
	tween:Play()
	return tween
end

-- Waits for a track to load. Returns the Sound, or nil (and cleans up) if it never does.
local function load(track)
	if type(track) ~= "table" or type(track.id) ~= "string" or track.id == "" then
		return nil
	end
	local ok, sound = pcall(function()
		local s = Instance.new("Sound")
		s.Name = "Music"
		s.SoundId = track.id
		s.Volume = 0
		s.Looped = false
		s.Parent = SoundService
		return s
	end)
	if not ok or not sound then
		return nil
	end
	local deadline = time() + (Config.MusicLoadSeconds or 10)
	while not sound.IsLoaded and time() < deadline do
		task.wait(0.25)
	end
	if not sound.IsLoaded or sound.TimeLength <= 0 then
		sound:Destroy()
		return nil
	end
	return sound
end

local function play(sound)
	local fadeTime = Config.MusicFadeSeconds or 3
	current = sound
	pcall(function()
		sound:Play()
	end)
	if not on then
		sound:Pause()
	else
		fade(sound, volume(), fadeTime)
	end
	-- wait until near the end (paused time doesn't count), then fade out
	while sound.Parent and sound.TimeLength - sound.TimePosition > fadeTime do
		task.wait(0.5)
		if on and not sound.IsPlaying and sound.TimePosition < 0.1 and sound.TimeLength > 0 then
			break -- it stopped by itself (it ended early or failed mid-way)
		end
	end
	if sound.Parent then
		fade(sound, 0, fadeTime)
		task.wait(fadeTime)
		sound:Destroy()
	end
end

local function loop()
	local tracks = Config.Music or {}
	local index = 0
	local failsInARow = 0
	while true do
		index = index % #tracks + 1
		local sound = load(tracks[index])
		if sound then
			failsInARow = 0
			play(sound)
		else
			failsInARow += 1
			if failsInARow >= #tracks then
				task.wait(120) -- nothing loads: try again much later, quietly
				failsInARow = 0
			end
		end
		task.wait(0.5)
	end
end

local function show()
	if button then
		button.Text = if on then "♪ On" else "♪ Off"
		button.BackgroundColor3 = if on then Ui.colors.wood else Ui.colors.grey
	end
end

function Music.toggle()
	on = not on
	show()
	local sound = current
	if sound and sound.Parent then
		if on then
			sound:Resume()
			fade(sound, volume(), 1)
		else
			fade(sound, 0, 0.8).Completed:Connect(function()
				if not on and sound.Parent then
					sound:Pause()
				end
			end)
		end
	end
end

function Music.start(gui)
	if type(Config.Music) ~= "table" or #Config.Music == 0 then
		return -- no music set up: no button either
	end
	button = Ui.button("", Ui.colors.wood, { Name = "MusicToggle", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), Size = UDim2.fromOffset(92, 40), Parent = gui })
	Ui.autoScale(button)
	button.Activated:Connect(Music.toggle)
	show()
	task.spawn(loop)
end

return Music

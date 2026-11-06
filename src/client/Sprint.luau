-- Sprinting on every device: hold Shift on a keyboard, press the left stick (L3) on a controller
-- to toggle, or tap RUN on a touch screen to toggle. You run Config.Sprint.multiplier times
-- your walking speed (Light Boots included); letting go or tapping again walks.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Ui = require(script.Parent.Ui)
local TouchPad = require(script.Parent.TouchPad)

local player = Players.LocalPlayer
local Sprint = {}
local running, base, humanoid = false, nil, nil

local function apply()
	if humanoid and base then
		humanoid.WalkSpeed = if running then base * Config.Sprint.multiplier else base
	end
end

local function set(on)
	if running ~= on then
		running = on
		apply()
	end
end

local function track(character)
	humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then
		return
	end
	base = humanoid.WalkSpeed
	-- the server sets the walking speed (Light Boots): remember it whenever we aren't sprinting
	humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
		local speed = humanoid.WalkSpeed
		if not running then
			base = speed
		elseif base and math.abs(speed - base * Config.Sprint.multiplier) > 0.01 then
			base = speed -- the server changed it mid-run: take that as the new walking speed
			apply()
		end
	end)
	apply()
end

function Sprint.start()
	player.CharacterAdded:Connect(function(character)
		running = false
		track(character)
	end)
	if player.Character then
		task.spawn(track, player.Character)
	end
	UserInputService.InputBegan:Connect(function(input, processed)
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			set(true) -- even if a text box isn't focused, Shift is never typed on its own
		elseif not processed and input.KeyCode == Enum.KeyCode.ButtonL3 then
			set(not running)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			set(false)
		end
	end)
	local button
	button = TouchPad.add({ order = 0, text = "RUN", colour = Ui.colors.green, tap = function()
		set(not running)
		if button then
			button.Text = if running then "WALK" else "RUN"
		end
	end })
end

return Sprint

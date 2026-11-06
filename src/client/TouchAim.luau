-- Harvesting on touch screens. In first person a finger dragged across the screen turns the
-- camera, so only a touch that stays put counts: lift it quickly for one swing at the
-- crosshair, or hold it still to keep harvesting (like holding the mouse button). Touches on
-- buttons (the game's, the jump button, prompts) and on the thumbstick never harvest, and
-- neither do taps while a menu is open or in build mode (that has its own PLACE button).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Harvest = require(script.Parent.Harvest)
local Cursor = require(script.Parent.Cursor)
local TouchPad = require(script.Parent.TouchPad)

local cfg = Config.Touch
local TouchAim = {}
local touches = {} -- [InputObject] = { start = Vector2, at = time(), moved = bool }

local function blocked()
	return Cursor.isFree() or TouchPad.isBuilding()
end

function TouchAim.start()
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local start = Vector2.new(input.Position.X, input.Position.Y)
		if TouchPad.onStick(start) then
			return
		end
		touches[input] = { start = start, at = time(), moved = false }
	end)
	UserInputService.InputChanged:Connect(function(input)
		local t = touches[input]
		if t and not t.moved and (Vector2.new(input.Position.X, input.Position.Y) - t.start).Magnitude > cfg.dragPixels then
			t.moved = true -- looking around from now on
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		local t = touches[input]
		touches[input] = nil
		if t and not t.moved and time() - t.at < cfg.holdSeconds and not blocked() then
			Harvest.use(false) -- a tap
		end
	end)
	RunService.RenderStepped:Connect(function()
		for input, t in pairs(touches) do
			local state = input.UserInputState
			if state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
				touches[input] = nil -- an end we missed
			elseif not t.moved and time() - t.at >= cfg.holdSeconds and not blocked() then
				Harvest.use(true) -- held still: keep harvesting (the tool's cooldown paces it)
			end
		end
	end)
end

return TouchAim

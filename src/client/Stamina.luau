-- A slim stamina bar under the crosshair (the server owns stamina: attributes Stamina,
-- StaminaMax, Winded). It eases in when you've used some, eases out when it's full again,
-- and says "catching your breath" softly while you rest. No flashing.
local Players = game:GetService("Players")

local Ui = require(script.Parent.Ui)
local Juice = require(script.Parent.Juice)

local player = Players.LocalPlayer
local StaminaBar = {}

local CALM = Color3.fromRGB(120, 200, 150)
local RESTING = Color3.fromRGB(240, 180, 90)

function StaminaBar.mount(gui)
	local back = Ui.make("Frame", { Name = "Stamina", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.5, 56), Size = UDim2.fromOffset(140, 6), BackgroundColor3 = Ui.colors.woodDark, BackgroundTransparency = 1, BorderSizePixel = 0, Parent = gui }, { Ui.corner(3) })
	local fill = Ui.make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = CALM, BackgroundTransparency = 1, BorderSizePixel = 0, Parent = back }, { Ui.corner(3) })
	local note = Ui.label({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 4), Size = UDim2.fromOffset(240, 18), Text = "Catching your breath...", TextColor3 = Ui.colors.cream, TextTransparency = 1, TextStrokeTransparency = 1, Parent = back }, 15)
	local shown = false

	local function refresh()
		local value, top = player:GetAttribute("Stamina"), player:GetAttribute("StaminaMax")
		if type(value) ~= "number" or type(top) ~= "number" or top <= 0 then
			return
		end
		local winded = player:GetAttribute("Winded") == true
		Juice.ease(fill, 0.25, { Size = UDim2.fromScale(math.clamp(value / top, 0, 1), 1), BackgroundColor3 = if winded then RESTING else CALM })
		local show = value < top
		if show ~= shown then
			shown = show
			Juice.ease(back, 0.4, { BackgroundTransparency = if show then 0.45 else 1 })
			Juice.ease(fill, 0.4, { BackgroundTransparency = if show then 0.1 else 1 })
		end
		Juice.ease(note, 0.4, { TextTransparency = if winded then 0.1 else 1, TextStrokeTransparency = if winded then 0.5 else 1 })
	end
	for _, name in ipairs({ "Stamina", "StaminaMax", "Winded" }) do
		player:GetAttributeChangedSignal(name):Connect(refresh)
	end
	refresh()
end

return StaminaBar

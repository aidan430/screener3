-- POKE and THROW bars, top left under the DASH bar (client/DashFx), in the same style: each empties
-- when you use it and refills over its cooldown (Config.Combat.cooldown, Config.Throw.cooldown);
-- full and bright means ready. While your needle is flying (Config.Throw.back) you can't poke, so
-- POKE waits for it too. They show during a round you're in, when you can fight.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local UiKit = require(script.Parent.UiKit)
local MovesFx = require(script.Parent.MovesFx)
local ThrowFx = require(script.Parent.ThrowFx)

local player = Players.LocalPlayer
local CooldownBars = {}

local function bar(gui, label, y, colour)
	local holder = UiKit.make("Frame", { Position = UDim2.fromOffset(16, y), Size = UDim2.fromOffset(170, 26), BackgroundTransparency = 1, Visible = false, Parent = gui })
	UiKit.autoScale(holder)
	local tag = UiKit.label({ Text = label, Font = UiKit.bold, Size = UDim2.fromOffset(60, 26), TextXAlignment = Enum.TextXAlignment.Left, TextStrokeTransparency = 0.5, Parent = holder }, 16)
	local back, fill = UiKit.bar(holder, { Size = UDim2.fromOffset(104, 12), Position = UDim2.fromOffset(62, 7) }, colour)
	local edge = UiKit.stroke(Color3.fromRGB(240, 236, 220), 1.5)
	edge.Parent = back
	return function(charge, show)
		holder.Visible = show
		fill.Size = UDim2.fromScale(charge, 1)
		local ready = charge >= 1
		fill.BackgroundColor3 = if ready then colour else colour:Lerp(Color3.fromRGB(90, 96, 110), 0.5)
		tag.TextColor3 = if ready then UiKit.colors.text else UiKit.colors.soft
		edge.Transparency = if ready then 0.1 else 0.6
	end
end

function CooldownBars.start(gui)
	local poke = bar(gui, "POKE", 182, Color3.fromRGB(255, 120, 150))
	local throw = bar(gui, "THROW", 214, Color3.fromRGB(230, 120, 50))
	RunService.RenderStepped:Connect(function()
		local now = os.clock()
		local show = ReplicatedStorage:GetAttribute("Phase") == "search" and player:GetAttribute("InRound") == true
		local thrown = (now - ThrowFx.lastThrow()) / Config.Throw.back
		poke(math.clamp(math.min((now - MovesFx.lastPoke) / Config.Combat.cooldown, thrown), 0, 1), show)
		throw(math.clamp((now - ThrowFx.lastThrow()) / Config.Throw.cooldown, 0, 1), show)
	end)
end

return CooldownBars

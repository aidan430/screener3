-- The shortcuts: Q shop, T home, G drop hay (or put down a bale), and on touch screens the
-- same as buttons on the action pad (client/TouchPad.luau), plus BUILD, MENU (achievements,
-- finds, the whistle) and TOOL (the 1 key: take out your fork). Tap anywhere else to harvest
-- (client/TouchAim.luau).
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Ui = require(script.Parent.Ui)
local TouchPad = require(script.Parent.TouchPad)
local BuildMode = require(script.Parent.BuildMode)
local Teleport = require(script.Parent.Teleport)

local player = Players.LocalPlayer
local Controls = {}

local function holdingTool()
	local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
	return tool ~= nil and tool:GetAttribute("Level") ~= nil
end

-- Take out your harvesting tool (leaving build mode does that by itself).
local function equip()
	if BuildMode.active() then
		BuildMode.toggle(false)
		return
	end
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local backpack = player:FindFirstChildOfClass("Backpack")
	for _, tool in ipairs(backpack and backpack:GetChildren() or {}) do
		if humanoid and tool:IsA("Tool") and tool:GetAttribute("Level") ~= nil then
			humanoid:EquipTool(tool)
			return
		end
	end
end

function Controls.start(open)
	local function home()
		Remotes.GoHome:FireServer() -- back to the entrance of your own farm
	end
	local function drop()
		Remotes.DropHay:FireServer() -- drop your load as a bundle (or put down a bale)
	end
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		elseif input.KeyCode == Enum.KeyCode.Q then
			open("Shop")
		elseif input.KeyCode == Enum.KeyCode[Config.HomeKey] then
			home()
		elseif input.KeyCode == Enum.KeyCode[Config.DropKey] then
			drop()
		end
	end)
	-- prompts (E, or tap the prompt's button on a touch screen) that open a menu here
	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		if prompt:GetAttribute("Action") == "wheel" then
			open("Wheel")
		elseif prompt:GetAttribute("Action") == "teleport" then
			Teleport.open(prompt:FindFirstAncestorOfClass("Model"))
		end
	end)
	TouchPad.add({ order = 4, text = "Drop", tap = drop })
	TouchPad.add({ order = 5, text = "Home", tap = home })
	TouchPad.add({ order = 6, text = "Tool", colour = Ui.colors.green, tap = equip, show = function()
		return not holdingTool()
	end })
	TouchPad.add({ order = 7, text = "Shop", colour = Ui.colors.green, tap = function()
		open("Shop")
	end })
	TouchPad.add({ order = 8, text = "Build", tap = function()
		open("Build")
	end })
	TouchPad.add({ order = 9, text = "Journal", colour = Ui.colors.purple, tap = function()
		open("Menu")
	end })
end

return Controls

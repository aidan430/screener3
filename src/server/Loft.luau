-- The Golden Loft: the secret level above the hub, open only to players with ten
-- achievements. The golden door's prompt sends them up; the loft pad brings them down.
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local World = require(script.Parent.World)

local Loft = {}

local function teleport(player, position)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		root.CFrame = CFrame.new(position)
		root.AssemblyLinearVelocity = Vector3.zero
	end
end

function Loft.init()
	ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		local action = prompt:GetAttribute("Action")
		if action == "loft" then
			if player:GetAttribute("LoftOpen") then
				teleport(player, World.LOFT + Vector3.new(0, 4, 30))
				Remotes.Announce:FireClient(player, { kind = "notice", text = "Welcome to the Golden Loft. Golden straw pays 20x!" })
			else
				Remotes.Announce:FireClient(player, { kind = "notice", text = "The golden door won't budge. Some say ten secret deeds open it..." })
			end
		elseif action == "down" then
			teleport(player, World.DOOR + Vector3.new(-8, 4, 0))
		end
	end)
end

return Loft

-- The Golden Loft: the secret level above the barn, open only to players with all ten
-- achievements. The server moves the player up and down so nobody can walk in uninvited.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local World = require(script.Parent.World)

local Loft = {}

local function teleport(player, position)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		root.CFrame = CFrame.new(position)
		root.AssemblyLinearVelocity = Vector3.zero
	end
end

function Loft.init()
	Remotes.Loft.OnServerInvoke = function(player, direction)
		if direction == "up" then
			if not player:GetAttribute("LoftOpen") then
				return false, "The Golden Loft opens when all ten achievements are done."
			end
			teleport(player, World.LOFT + Vector3.new(0, 4, 30))
			return true, "Welcome to the Golden Loft. Golden straw pays 20x!"
		end
		teleport(player, World.BARN + Vector3.new(0, 4, -18))
		return true, "Back down on the farm."
	end
end

return Loft

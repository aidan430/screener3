-- Aiming in first person: the clump under the crosshair (within reach, on your own pile or the
-- golden haystack) gets a soft outline, and clicking with your tool harvests it.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Juice = require(script.Parent.Juice)

local player = Players.LocalPlayer
local Harvest = {}
local target = nil
local lastSwing = 0
local hooked = setmetatable({}, { __mode = "k" })

local outline = Instance.new("SelectionBox")
outline.Color3 = Color3.fromRGB(255, 236, 170)
outline.LineThickness = 0.06
outline.SurfaceTransparency = 0.85
outline.SurfaceColor3 = Color3.fromRGB(255, 236, 170)
outline.Parent = player:WaitForChild("PlayerGui")

local function harvestable(part)
	if not part then
		return false
	end
	local loft = workspace:FindFirstChild("Loft")
	if loft and part:IsDescendantOf(loft) and string.sub(part.Name, 1, 6) == "Golden" then
		return player:GetAttribute("LoftOpen") == true
	end
	local plot = player:GetAttribute("Plot")
	local plots = workspace:FindFirstChild("Plots")
	local mine = plot and plots and plots:FindFirstChild("Plot" .. plot)
	return mine ~= nil and part:GetAttribute("Clump") ~= nil and part:IsDescendantOf(mine)
end

local function aim()
	local camera = workspace.CurrentCamera
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not camera or not head then
		return nil, nil
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character, workspace:FindFirstChild("MyEffects") }
	local result = workspace:Raycast(camera.CFrame.Position, camera.CFrame.LookVector * (Config.Reach + 4), params)
	if result and harvestable(result.Instance) and (result.Position - head.Position).Magnitude <= Config.Reach then
		return result.Instance, result.Position
	end
	return nil, nil
end

function Harvest.target()
	return target
end

local function cooldown()
	return Config.SearchCooldown * (1 - Config.Perks[2].per_level * (player:GetAttribute("Perk_swift") or 0))
end

local function hookTool(tool)
	if hooked[tool] or not tool:IsA("Tool") or tool:GetAttribute("Level") == nil then
		return
	end
	hooked[tool] = true
	tool.Activated:Connect(function()
		local part, point = aim()
		if not part or os.clock() - lastSwing < cooldown() then
			return
		end
		lastSwing = os.clock()
		Remotes.Harvest:FireServer(part)
		-- instant feel: a puff where you hit, a tiny camera push and the combo
		Juice.burst(point, 6, part.Name:sub(1, 6) == "Golden")
		Juice.punch(1.2)
		Juice.hit()
		local swing = Instance.new("StringValue") -- the default Animate script plays a swing for this
		swing.Name = "toolanim"
		swing.Value = "Slash"
		swing.Parent = tool
		task.delay(0.5, function()
			swing:Destroy()
		end)
	end)
end

function Harvest.start()
	RunService.RenderStepped:Connect(function()
		local part = aim()
		target = part
		outline.Adornee = part
	end)
	local backpackConnection = nil
	local function onCharacter(character)
		local humanoid = character:WaitForChild("Humanoid")
		local backpack = player:WaitForChild("Backpack")
		local equipped = false
		local function arrive(tool)
			hookTool(tool)
			if not equipped and tool:IsA("Tool") and tool:GetAttribute("Level") ~= nil then
				equipped = true
				task.defer(function()
					if humanoid.Parent and tool.Parent == backpack then
						humanoid:EquipTool(tool)
					end
				end)
			end
		end
		if backpackConnection then
			backpackConnection:Disconnect()
		end
		backpackConnection = backpack.ChildAdded:Connect(arrive)
		for _, tool in ipairs(backpack:GetChildren()) do
			arrive(tool)
		end
		character.ChildAdded:Connect(hookTool)
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end

return Harvest

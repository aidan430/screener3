-- Aiming in first person: the clump under the crosshair (within reach, on your own pile or the
-- golden haystack) gets a soft outline, and clicking with your tool harvests it.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

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

-- A click that hit no harvestable clump: say what the crosshair is on (at most every 2 s).
local lastMiss = 0
Harvest.onMiss = nil
function Harvest.miss()
	if os.clock() - lastMiss < 2 or not Harvest.onMiss then
		return
	end
	lastMiss = os.clock()
	local camera, character = workspace.CurrentCamera, player.Character
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local result = camera and workspace:Raycast(camera.CFrame.Position, camera.CFrame.LookVector * 300, params)
	local plot = player:GetAttribute("Plot")
	if not plot then
		Harvest.onMiss("Your farm isn't ready yet. Wait a moment.")
	elseif not result then
		Harvest.onMiss("Aim the dot in the middle of the screen at a clump of your pile.")
	elseif result.Instance:GetAttribute("Clump") then
		local head = character and character:FindFirstChild("Head")
		local far = head and (result.Position - head.Position).Magnitude or 0
		if far > Config.Reach then
			Harvest.onMiss("Too far: " .. math.floor(far) .. " studs. Get within " .. Config.Reach .. ".")
		else
			Harvest.onMiss("That's not your pile. Yours is on the farm marked YOUR FARM.")
		end
	else
		Harvest.onMiss("That's " .. result.Instance.Name .. ", not hay. Aim the dot at a clump of your pile.")
	end
end

local function cooldown()
	return Config.SearchCooldown * (1 - Config.Perks[2].per_level * (player:GetAttribute("Perk_swift") or 0))
end

-- One swing: harvest the clump under the crosshair (shared by the tool and the mouse button).
local function swing(tool)
	local part, point = aim()
	if not part then
		Harvest.miss()
		return
	end
	if os.clock() - lastSwing < cooldown() then
		return
	end
	lastSwing = os.clock()
	Remotes.Harvest:FireServer(part)
	-- instant feel: a puff where you hit, a tiny camera push and the combo
	Juice.burst(point, 6, part.Name:sub(1, 6) == "Golden")
	Juice.punch(1.2)
	Juice.hit()
	local anim = Instance.new("StringValue") -- the default Animate script plays a swing for this
	anim.Name = "toolanim"
	anim.Value = "Slash"
	anim.Parent = tool
	task.delay(0.5, function()
		anim:Destroy()
	end)
end

local function heldTool()
	local character = player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	return if tool and tool:GetAttribute("Level") ~= nil then tool else nil
end

local function hookTool(tool)
	if hooked[tool] or not tool:IsA("Tool") or tool:GetAttribute("Level") == nil then
		return
	end
	hooked[tool] = true
	tool.Activated:Connect(function()
		swing(tool)
	end)
end

function Harvest.start()
	-- the mouse button too, in case the tool's own click doesn't come through in first person
	UserInputService.InputBegan:Connect(function(input, processed)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		-- with the mouse locked to the crosshair, a click can't be meant for a menu
		local locked = UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter
		if processed and not locked then
			return
		end
		local tool = heldTool()
		if tool then
			swing(tool)
		elseif Harvest.onMiss and player.Character then
			Harvest.onMiss("Hold your fork to harvest: press 1.")
		end
	end)
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
		for _, tool in ipairs(character:GetChildren()) do
			hookTool(tool) -- already held when this script started
		end
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end

return Harvest

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

local Layout = require(Shared:WaitForChild("Layout"))(Config)
local HEAP = Enum.Material.Grass

-- The heap is terrain, so a see-through box marks the clump you're aiming at.
local marker = Instance.new("Part")
marker.Name = "AimMarker"
marker.Anchored, marker.CanCollide, marker.CanQuery, marker.CanTouch = true, false, false, false
marker.Transparency = 1
marker.Size = Vector3.new(1, 1, 1) * (Config.ClumpSize + 0.2)
local outline = Instance.new("SelectionBox")
outline.Color3 = Color3.fromRGB(255, 236, 170)
outline.LineThickness = 0.05
outline.SurfaceTransparency = 0.88
outline.SurfaceColor3 = Color3.fromRGB(255, 236, 170)
outline.Parent = player:WaitForChild("PlayerGui")

local function myOrigin()
	local plot = player:GetAttribute("Plot")
	local centre = plot and Config.PlotCentres[plot]
	if not centre then
		return nil
	end
	local x, z = Layout.origin(centre[1], centre[2])
	return Vector3.new(x, 0, z), Vector3.new(centre[1], 0, centre[2])
end

-- Where on your own heap a ray hit: the point just inside the surface and its clump's centre.
local function onMyHeap(result)
	if not result or result.Instance ~= workspace.Terrain or result.Material ~= HEAP then
		return nil
	end
	local origin, centre = myOrigin()
	if not origin then
		return nil
	end
	local inside = result.Position - result.Normal * 1.5
	local half = Config.PlotSize / 2
	if math.abs(inside.X - centre.X) > half or math.abs(inside.Z - centre.Z) > half then
		return nil
	end
	local s = Config.ClumpSize
	local gx, layer, gz = math.floor((inside.X - origin.X) / s + 0.5), math.floor(inside.Y / s), math.floor((inside.Z - origin.Z) / s + 0.5)
	return inside, origin + Vector3.new(gx * s, layer * s + s / 2, gz * s)
end

local function harvestable(part)
	if part ~= nil and part:GetAttribute("World") ~= nil then
		return true -- a portal world's haystack (the server checks the portal is yours)
	end
	local loft = workspace:FindFirstChild("Loft")
	return part ~= nil and loft ~= nil and part:IsDescendantOf(loft) and string.sub(part.Name, 1, 6) == "Golden" and player:GetAttribute("LoftOpen") == true
end

local function cast(distance, ignoreEffects)
	local camera = workspace.CurrentCamera
	local character = player.Character
	if not camera or not character then
		return nil
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	if player:GetAttribute("Plot") then -- pass through other players' hidden buildings and hay
		params.CollisionGroup = "Plot" .. player:GetAttribute("Plot")
	end
	params.FilterDescendantsInstances = if ignoreEffects then { character, workspace:FindFirstChild("MyEffects") } else { character }
	return workspace:Raycast(camera.CFrame.Position, camera.CFrame.LookVector * distance, params)
end

-- What a click would harvest: (what to send the server, where it is, the marker's centre)
local function aim()
	local head = player.Character and player.Character:FindFirstChild("Head")
	local result = head and cast(Config.Reach + 4, true)
	if not result or (result.Position - head.Position).Magnitude > Config.Reach then
		return nil
	end
	local inside, cell = onMyHeap(result)
	if inside then
		return inside, result.Position, cell
	elseif harvestable(result.Instance) then
		return result.Instance, result.Position, nil
	end
	return nil
end

function Harvest.target()
	return target
end

-- A click that hit nothing to harvest: say what the crosshair is on (at most every 2 s).
local lastMiss = 0
Harvest.onMiss = nil
Harvest.lastFired = 0
function Harvest.miss()
	if time() - lastMiss < 2 or not Harvest.onMiss then
		return
	end
	lastMiss = time()
	local result = cast(300, false)
	local head = player.Character and player.Character:FindFirstChild("Head")
	if not player:GetAttribute("Plot") then
		Harvest.onMiss("Your farm isn't ready yet. Wait a moment.")
	elseif not result then
		Harvest.onMiss("Aim the dot in the middle of the screen at your hay heap.")
	elseif result.Instance == workspace.Terrain and result.Material == HEAP then
		local far = head and (result.Position - head.Position).Magnitude or 0
		if onMyHeap(result) and far > Config.Reach then
			Harvest.onMiss("Too far: " .. math.floor(far) .. " studs. Get within " .. Config.Reach .. ".")
		elseif not onMyHeap(result) then
			Harvest.onMiss("That isn't part of your haystack. Aim at the hay in the middle of the farm.")
		end
	else
		Harvest.onMiss("That's " .. (if result.Instance == workspace.Terrain then "the ground" else result.Instance.Name) .. ", not hay. Aim the dot at your heap.")
	end
end

local function cooldown()
	return Config.SearchCooldown * (1 - Config.Perks[2].per_level * (player:GetAttribute("Perk_swift") or 0))
end

-- One swing: harvest the clump under the crosshair (shared by the tool and the mouse button).
local function swing(tool)
	local part, point = aim()
	if part == nil then
		Harvest.miss()
		return
	end
	if time() - lastSwing < cooldown() then
		return
	end
	lastSwing = time()
	Harvest.lastFired = time()
	Remotes.Harvest:FireServer(part)
	-- instant feel: a puff where you hit and a tiny camera push (the combo waits for the server)
	Juice.burst(point, 6, typeof(part) == "Instance")
	Juice.punch(1.2)
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
		-- on touch screens Harvest.use (client/TouchAim.luau) handles taps, so a drag to look
		-- around can never swing
		if UserInputService:GetLastInputType() ~= Enum.UserInputType.Touch then
			swing(tool)
		end
	end)
end

-- A click or tap: swing the tool you hold, or say how to get it out. `held`: the button or
-- finger is still down (keep harvesting quietly; no hints).
function Harvest.use(held)
	local tool = heldTool()
	if tool then
		if not held or aim() ~= nil then
			swing(tool)
		end
	elseif not held and Harvest.onMiss and player.Character and not (Harvest.isBuilding and Harvest.isBuilding()) then
		Harvest.onMiss(if UserInputService:GetLastInputType() == Enum.UserInputType.Touch then "Hold your tool to harvest: tap TOOL." else "Hold your tool to harvest: press 1.")
	end
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
		Harvest.use(false)
	end)
	RunService.RenderStepped:Connect(function()
		local part, _, cell = aim()
		target = part
		-- hold the button to keep harvesting (the swing waits for the tool's cooldown itself)
		local mouse = UserInputService:GetLastInputType() ~= Enum.UserInputType.Touch
		if part ~= nil and mouse and UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
			local tool = heldTool()
			if tool then
				swing(tool)
			end
		end
		if cell then
			marker.Position = cell
			marker.Parent = workspace:FindFirstChild("MyEffects") or workspace
			outline.Adornee = marker
		else
			outline.Adornee = if typeof(part) == "Instance" then part else nil
		end
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

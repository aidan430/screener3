-- Every player's farm shares the middle of the map, so on your screen other players' buildings,
-- loose hay, trucks and buckets are hidden (they can't touch you either: their plot's collision
-- group doesn't collide with yours). Other players themselves stay visible, farming their own.
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local OnlyMine = {}

local function hide(inst)
	if inst:IsA("BasePart") then
		inst.LocalTransparencyModifier = 1
	elseif inst:IsA("ProximityPrompt") or inst:IsA("BillboardGui") or inst:IsA("SurfaceGui") or inst:IsA("ParticleEmitter") or inst:IsA("Beam") or inst:IsA("Light") or inst:IsA("Decal") then
		pcall(function()
			inst.Enabled = false
		end)
		if inst:IsA("Decal") then
			inst.Transparency = 1
		end
	end
end

-- Hides everything under `root` now and whatever is added later.
local function hideAll(root)
	hide(root)
	for _, inst in ipairs(root:GetDescendants()) do
		hide(inst)
	end
	root.DescendantAdded:Connect(hide)
end

local function notMine(inst)
	local owner = inst:GetAttribute("Owner")
	return owner ~= nil and owner ~= player.UserId
end

function OnlyMine.start()
	local hidden = setmetatable({}, { __mode = "k" })
	local function once(root)
		if not hidden[root] then
			hidden[root] = true
			hideAll(root)
		end
	end
	local function plots()
		local mine = player:GetAttribute("Plot")
		local folder = workspace:FindFirstChild("Plots")
		for _, plot in ipairs(folder and folder:GetChildren() or {}) do
			if mine and plot:GetAttribute("Index") ~= mine then
				once(plot)
			end
		end
	end
	player:GetAttributeChangedSignal("Plot"):Connect(plots)
	task.spawn(function()
		local folder = workspace:WaitForChild("Plots", 30)
		if folder then
			folder.ChildAdded:Connect(plots)
		end
		plots()
	end)
	-- trucks and buckets live outside the plots: hide the ones that aren't yours
	for _, name in ipairs({ "Trucks", "Gear" }) do
		task.spawn(function()
			local folder = workspace:WaitForChild(name, 30)
			if not folder then
				return
			end
			local function check(child)
				task.defer(function() -- the Owner attribute arrives with the model
					if notMine(child) then
						once(child)
					end
				end)
			end
			folder.ChildAdded:Connect(check)
			for _, child in ipairs(folder:GetChildren()) do
				check(child)
			end
		end)
	end
end

return OnlyMine

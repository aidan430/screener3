-- What you carry, where everyone can see it: the hay on your tool grows with every harvest,
-- and once the tool is full your bucket (at your hip) fills up too. Dumping empties both.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))(Config)
local HayLook = require(Shared:WaitForChild("HayLook"))(Config)

local PlayerData = require(script.Parent.PlayerData)
local Plots = require(script.Parent.Plots)
local Build = require(script.Parent.Build)

local Carry = {}
local HAY, GOLD = { 222, 186, 92 }, { 255, 214, 90 }
local gear = Instance.new("Folder") -- outside the character, so first person doesn't hide it
gear.Name = "Gear"
gear.Parent = workspace

local function weld(a, b)
	local w = Instance.new("WeldConstraint")
	w.Part0, w.Part1 = a, b
	w.Parent = b
end

-- A bucket at the hip: the pail, its rim and handle, and a mound of hay that grows inside.
local function makeBucket(player, root, level)
	local def = Economy.bucket(level)
	local model = Instance.new("Model")
	model.Name = player.Name
	model:SetAttribute("Level", level)
	local size = def.size
	local base = root.CFrame * CFrame.new(1.4, -0.9, 0.2)
	local parts = {
		Build.part({ name = "Pail", size = Vector3.new(size, size * 0.9, size * 0.9), cframe = base * CFrame.Angles(0, 0, math.rad(90)), color = { 150, 104, 58 }, material = "Fabric", shape = "Cylinder", collide = false, parent = model }),
		Build.part({ size = Vector3.new(0.15, size * 1.0, size * 1.0), cframe = base * CFrame.new(0, size / 2, 0) * CFrame.Angles(0, 0, math.rad(90)), color = { 110, 76, 46 }, material = "Wood", shape = "Cylinder", collide = false, parent = model }),
		Build.part({ size = Vector3.new(0.12, size * 0.9, 0.12), cframe = base * CFrame.new(0, size * 0.7, 0) * CFrame.Angles(0, 0, math.rad(90)), color = { 120, 120, 128 }, material = "Metal", collide = false, parent = model }),
	}
	local hay = HayLook.lump(0.1, false)
	hay.CFrame = base * CFrame.new(0, size / 2, 0)
	hay.Transparency = 1
	hay.Parent = model
	table.insert(parts, hay)
	for _, part in ipairs(parts) do
		part.Anchored = false
		part.Massless = true
		weld(root, part)
	end
	model:SetAttribute("Owner", player.UserId)
	if Plots.of(player) then
		Plots.tag(model, Plots.of(player))
	end
	model.Parent = gear
	return model
end

local function bucketOf(player)
	return gear:FindFirstChild(player.Name)
end

-- Grows a hay mound to show how full something is (0..1), keeping its bottom where it sits.
local function mound(part, share, width, golden, rainbow)
	if share <= 0 then
		part.Transparency = 1
		return
	end
	part.Transparency = 0
	part.Color = if rainbow then Color3.fromHSV((os.clock() / 8) % 1, 0.45, 1) else Build.rgb(if golden then GOLD else HAY)
	HayLook.resize(part, width * (0.45 + 0.55 * math.sqrt(math.min(share, 1))))
end

-- Shows the player's load on their tool and bucket. Cheap: call it whenever the load changes.
function Carry.show(player)
	local d = PlayerData.get(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not d or not root then
		return
	end
	local load = d.carried + d.carriedGolden
	local golden = d.carriedGolden > d.carried
	local toolCap = Economy.tool(d.tool).capacity
	local onTool = math.min(load, toolCap) / toolCap
	for _, container in ipairs({ character, player:FindFirstChildOfClass("Backpack") }) do
		for _, tool in ipairs(container and container:GetChildren() or {}) do
			local hay = tool:IsA("Tool") and tool:FindFirstChild("Load")
			if hay then
				mound(hay, onTool, hay:GetAttribute("MaxSize") or Config.LoadSize, golden, player:GetAttribute("PassRainbowHay"))
				Carry.glow(tool, player:GetAttribute("PassSuperTool") == true)
				-- keep the hay's bottom on the blade (or tines) as it grows, never through it
				local weld, seat = hay:FindFirstChild("LoadWeld"), hay:GetAttribute("Seat")
				if weld and seat then
					weld.C0 = seat * CFrame.new(0, hay.Size.Y / 2, 0)
				end
			end
		end
	end
	local bucket = bucketOf(player)
	if d.bucket <= 1 then
		if bucket then
			bucket:Destroy()
		end
		return
	end
	if bucket and bucket:GetAttribute("Level") ~= d.bucket then
		bucket:Destroy()
		bucket = nil
	end
	if bucket then -- still welded to this character?
		local pail = bucket:FindFirstChild("Pail")
		local w = pail and pail:FindFirstChildOfClass("WeldConstraint")
		if not w or w.Part0 ~= root then
			bucket:Destroy()
			bucket = nil
		end
	end
	bucket = bucket or makeBucket(player, root, d.bucket)
	local def = Economy.bucket(d.bucket)
	local hay = bucket:FindFirstChild("Hay")
	if hay then
		mound(hay, math.max(0, load - toolCap) / math.max(def.capacity, 1), def.size * 0.95, golden, player:GetAttribute("PassRainbowHay"))
	end
end

-- Super Tool (game pass): a soft golden glow and sparkle on the tool's handle.
function Carry.glow(tool, on)
	local handle = tool:FindFirstChild("Handle")
	local glow = handle and handle:FindFirstChild("SuperGlow")
	if handle and on and not glow then
		local light = Instance.new("PointLight")
		light.Name = "SuperGlow"
		light.Color, light.Range, light.Brightness = Color3.fromRGB(255, 214, 110), 8, 1.2
		light.Parent = handle
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Name = "SuperSparkle"
		sparkle.Color = ColorSequence.new(Color3.fromRGB(255, 226, 140))
		sparkle.Rate, sparkle.Lifetime, sparkle.Speed = 6, NumberRange.new(0.6, 1), NumberRange.new(0.5, 1.5)
		sparkle.Size = NumberSequence.new(0.15, 0)
		sparkle.LightEmission = 0.8
		sparkle.Parent = handle
	elseif glow and not on then
		glow:Destroy()
		local sparkle = handle:FindFirstChild("SuperSparkle")
		if sparkle then
			sparkle:Destroy()
		end
	end
end

-- Sparkle Trail (game pass): a soft golden trail behind you as you move.
local function trail(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or not player:GetAttribute("PassSparkleTrail") or root:FindFirstChild("SparkleTrail") then
		return
	end
	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	a0.Position, a1.Position = Vector3.new(0, 1.2, 0.4), Vector3.new(0, -1.6, 0.4)
	a0.Parent, a1.Parent = root, root
	local t = Instance.new("Trail")
	t.Name = "SparkleTrail"
	t.Attachment0, t.Attachment1 = a0, a1
	t.Color = ColorSequence.new(Color3.fromRGB(255, 226, 140), Color3.fromRGB(255, 170, 220))
	t.Transparency = NumberSequence.new(0.3, 1)
	t.Lifetime, t.LightEmission, t.FaceCamera = 0.7, 0.6, true
	t.Parent = root
end

function Carry.init()
	local function watch(player)
		for _, name in ipairs({ "Carried", "Capacity", "Bucket", "Tool", "PassSuperTool", "PassRainbowHay" }) do
			player:GetAttributeChangedSignal(name):Connect(function()
				Carry.show(player)
			end)
		end
		player:GetAttributeChangedSignal("PassSparkleTrail"):Connect(function()
			trail(player)
		end)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("HumanoidRootPart", 10)
			trail(player)
		end)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("HumanoidRootPart", 10)
			task.wait(1.5) -- the tool arrives from StarterGear
			Carry.show(player)
		end)
		local backpack = player:WaitForChild("Backpack", 10)
		if backpack then
			backpack.ChildAdded:Connect(function()
				task.defer(Carry.show, player)
			end)
		end
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(watch, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		local bucket = bucketOf(player)
		if bucket then
			bucket:Destroy()
		end
	end)
end

return Carry

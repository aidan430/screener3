-- What players wear (Config.Cosmetics), built on their character so everyone on the server sees
-- it: a title above the head, a hat, a trail and an aura. Remotes.Wear(kind, id) puts on one you
-- own ("" takes it off); it's put back on after every respawn.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local PlayerData = require(script.Parent.PlayerData)
local Build = require(script.Parent.Build)

local Cosmetics = {}
local byId = {}
for _, c in ipairs(Config.Cosmetics) do
	byId[c.id] = c
end

local function colour(c, i)
	local v = c.colours[i] or c.colours[1]
	return if type(v) == "table" then Build.rgb(v) else Color3.fromRGB(255, 255, 255)
end

local function sequence(c)
	if c.colours[1] == "rainbow" then
		local keys = {}
		for i = 0, 6 do
			table.insert(keys, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 0.55, 1)))
		end
		return ColorSequence.new(keys)
	end
	return ColorSequence.new(colour(c, 1), colour(c, 2))
end

local function weld(a, b)
	local w = Instance.new("WeldConstraint")
	w.Part0, w.Part1 = a, b
	w.Parent = b
end

local HATS = {} -- shape -> function(head, c, folder)
function HATS.strawhat(head, c, folder)
	local top = head.CFrame * CFrame.new(0, head.Size.Y / 2, 0)
	local parts = {
		Build.part({ size = Vector3.new(0.12, 2.6, 2.6), shape = "Cylinder", cframe = top * CFrame.new(0, 0.06, 0) * CFrame.Angles(0, 0, math.rad(90)), color = colour(c, 1), material = "Fabric", collide = false, parent = folder }),
		Build.part({ size = Vector3.new(0.7, 1.4, 1.4), shape = "Cylinder", cframe = top * CFrame.new(0, 0.4, 0) * CFrame.Angles(0, 0, math.rad(90)), color = colour(c, 1), material = "Fabric", collide = false, parent = folder }),
		Build.part({ size = Vector3.new(0.18, 1.44, 1.44), shape = "Cylinder", cframe = top * CFrame.new(0, 0.18, 0) * CFrame.Angles(0, 0, math.rad(90)), color = colour(c, 2), material = "Fabric", collide = false, parent = folder }),
	}
	return parts
end
function HATS.bandana(head, c, folder)
	local top = head.CFrame * CFrame.new(0, head.Size.Y * 0.32, 0)
	return {
		Build.part({ size = Vector3.new(0.5, 1.28, 1.28), shape = "Cylinder", cframe = top * CFrame.Angles(0, 0, math.rad(90)), color = colour(c, 1), material = "Fabric", collide = false, parent = folder }),
		Build.part({ size = Vector3.new(0.5, 0.5, 0.2), cframe = head.CFrame * CFrame.new(0, head.Size.Y * 0.25, 0.68) * CFrame.Angles(math.rad(20), 0, 0), color = colour(c, 1), material = "Fabric", collide = false, parent = folder }),
	}
end
function HATS.crown(head, c, folder)
	local top = head.CFrame * CFrame.new(0, head.Size.Y / 2 + 0.2, 0)
	local parts = { Build.part({ size = Vector3.new(0.4, 1.3, 1.3), shape = "Cylinder", cframe = top * CFrame.Angles(0, 0, math.rad(90)), color = colour(c, 1), material = "Neon", collide = false, parent = folder }) }
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		table.insert(parts, Build.part({ size = Vector3.new(0.18, 0.5, 0.18), cframe = top * CFrame.new(math.cos(a) * 0.58, 0.4, math.sin(a) * 0.58), color = colour(c, 2), material = "Neon", collide = false, parent = folder }))
	end
	return parts
end
function HATS.halo(head, c, folder)
	local centre = head.CFrame * CFrame.new(0, head.Size.Y / 2 + 0.8, 0)
	local parts = {}
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		table.insert(parts, Build.part({ size = Vector3.new(0.18, 0.12, 0.42), cframe = centre * CFrame.new(math.cos(a) * 0.8, 0, math.sin(a) * 0.8) * CFrame.Angles(0, -a, 0), color = colour(c, 1), material = "Neon", collide = false, parent = folder }))
	end
	return parts
end

-- Puts everything the player wears on their character (replacing what was there).
function Cosmetics.dress(player)
	local d = PlayerData.get(player)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not d or not head or not root then
		return
	end
	local old = character:FindFirstChild("Cosmetics")
	if old then
		old:Destroy()
	end
	for _, name in ipairs({ "CosmeticTitle", "CosmeticTrail", "CosmeticAura", "CosmeticA0", "CosmeticA1" }) do
		local thing = head:FindFirstChild(name) or root:FindFirstChild(name)
		if thing then
			thing:Destroy()
		end
	end
	local folder = Instance.new("Model")
	folder.Name = "Cosmetics"
	folder.Parent = character
	local title, hat, trail, aura = byId[d.wearing.title or ""], byId[d.wearing.hat or ""], byId[d.wearing.trail or ""], byId[d.wearing.aura or ""]
	if title then
		local gui = Instance.new("BillboardGui")
		gui.Name = "CosmeticTitle"
		gui.Size, gui.StudsOffset, gui.AlwaysOnTop, gui.MaxDistance = UDim2.fromOffset(220, 28), Vector3.new(0, 2.6, 0), false, 90
		gui.Parent = head
		local label = Instance.new("TextLabel")
		label.Size, label.BackgroundTransparency, label.TextScaled = UDim2.fromScale(1, 1), 1, true
		label.FontFace = Font.new("rbxasset://fonts/families/Merriweather.json", Enum.FontWeight.Bold)
		label.Text, label.TextColor3, label.TextStrokeTransparency = title.name, Color3.new(1, 1, 1), 0.4
		label.Parent = gui
		local g = Instance.new("UIGradient")
		g.Color = sequence(title)
		g.Parent = label
	end
	if hat and HATS[hat.shape] then
		for _, part in ipairs(HATS[hat.shape](head, hat, folder)) do
			part.Anchored, part.Massless, part.CanQuery, part.CanTouch = false, true, false, false
			weld(head, part)
		end
	end
	if trail then
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Name, a1.Name = "CosmeticA0", "CosmeticA1"
		a0.Position, a1.Position = Vector3.new(0, 1.1, 0.5), Vector3.new(0, -1.5, 0.5)
		a0.Parent, a1.Parent = root, root
		local t = Instance.new("Trail")
		t.Name, t.Attachment0, t.Attachment1 = "CosmeticTrail", a0, a1
		t.Color, t.Transparency, t.Lifetime, t.LightEmission = sequence(trail), NumberSequence.new(0.2, 1), 0.8, 0.5
		t.Parent = root
	end
	if aura then
		local p = Instance.new("ParticleEmitter")
		p.Name, p.Color, p.LightEmission = "CosmeticAura", sequence(aura), 0.7
		p.Rate, p.Lifetime, p.Speed = 10, NumberRange.new(1, 1.6), NumberRange.new(0.3, 0.8)
		p.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.35), NumberSequenceKeypoint.new(1, 0) })
		p.Transparency = NumberSequence.new(0.3, 1)
		p.SpreadAngle, p.Acceleration = Vector2.new(180, 180), Vector3.new(0, 1.2, 0)
		p.Parent = root
	end
end

function Cosmetics.init()
	Remotes.Wear.OnServerEvent:Connect(function(player, kind, id)
		local d = PlayerData.get(player)
		if not d or type(kind) ~= "string" or type(id) ~= "string" then
			return
		end
		local c = byId[id]
		if id ~= "" and not (c and c.kind == kind and d.cosmetics[id]) then
			return -- not yours, or not that kind
		end
		PlayerData.update(player, function(data)
			data.wearing[kind] = if id == "" then nil else id
		end)
		Cosmetics.dress(player)
	end)
	local function watch(player)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("HumanoidRootPart", 10)
			task.wait(0.5)
			Cosmetics.dress(player)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in ipairs(Players:GetPlayers()) do
		watch(player)
	end
	PlayerData.onLoaded(Cosmetics.dress)
end

return Cosmetics

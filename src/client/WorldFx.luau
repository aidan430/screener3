-- What you see in the world: labels over the haystacks and the merchant, straw bursts and
-- floating text when you search, your own machines in the yard, and the loft hatch.
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Ui = require(script.Parent.Ui)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local WorldFx = {}
local mounds = {} -- "hay" | "gold" -> { core, attachment, emitter }
local yard = nil

local function billboard(adornee, size, offset, lines)
	local gui = Ui.make("BillboardGui", { Adornee = adornee, Size = size, StudsOffset = offset, MaxDistance = 400, LightInfluence = 0, ResetOnSpawn = false, Parent = playerGui })
	local out = {}
	local y = 0
	for _, line in ipairs(lines) do
		out[line.key] = Ui.label({ Text = line.text or "", Size = UDim2.fromScale(1, line.h), Position = UDim2.fromScale(0, y), TextColor3 = line.color or Ui.colors.white, Parent = gui }, line.max or 60)
		y += line.h
	end
	return gui, out
end

local function tagMound(model, key, title)
	local core = model:WaitForChild("Core")
	local attachment = Ui.make("Attachment", { Name = "StrawFx", Position = Vector3.new(0, core.Size.Y * 0.4, 0), Parent = core })
	local emitter = Ui.make("ParticleEmitter", {
		Rate = 0,
		Lifetime = NumberRange.new(0.6, 1.2),
		Speed = NumberRange.new(16, 30),
		SpreadAngle = Vector2.new(70, 70),
		Acceleration = Vector3.new(0, -40, 0),
		Size = NumberSequence.new(0.8, 0.2),
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-200, 200),
		Color = ColorSequence.new(if key == "gold" then Color3.fromRGB(255, 220, 90) else Color3.fromRGB(242, 212, 120)),
		LightEmission = if key == "gold" then 0.6 else 0.15,
		EmissionDirection = Enum.NormalId.Top,
		Parent = attachment,
	})
	billboard(core, UDim2.fromScale(22, 5), Vector3.new(0, core.Size.Y * 0.5 + 10, 0), {
		{ key = "title", text = title, h = 0.5, color = if key == "gold" then Ui.colors.hay else Ui.colors.white },
		{ key = "sub", text = "Hold your fork and click to search", h = 0.5, color = Ui.colors.cream, max = 44 },
	})
	mounds[key] = { core = core, attachment = attachment, emitter = emitter }
end

local function floatText(core, text, colour)
	local gui = Ui.make("BillboardGui", { Adornee = core, Size = UDim2.fromScale(12, 2.5), StudsOffset = Vector3.new(math.random(-6, 6), core.Size.Y * 0.5 + 2, 0), LightInfluence = 0, AlwaysOnTop = true, ResetOnSpawn = false, Parent = playerGui })
	local label = Ui.label({ Text = text, Size = UDim2.fromScale(1, 1), TextColor3 = colour, Parent = gui }, 60)
	TweenService:Create(gui, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { StudsOffset = gui.StudsOffset + Vector3.new(0, 5, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(1), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(gui, 1.1)
end

function WorldFx.searched(message)
	local m = mounds[message.where or "hay"]
	if not m then
		return
	end
	m.emitter:Emit(math.clamp(4 + math.floor(message.straws / 2), 4, 24))
	floatText(m.core, "+" .. Format.commas(message.straws) .. (if message.where == "gold" then " golden straw" else " straw"), Ui.colors.hay)
end

function WorldFx.celebrate(golden)
	local m = mounds[if golden then "gold" else "hay"]
	if m then
		m.emitter:Emit(120)
		floatText(m.core, if golden then "GOLDEN NEEDLE!" else "NEEDLE FOUND!", Color3.fromRGB(140, 255, 140))
	end
end

-- Your machines, shown in the yard: one small model per machine you own (only you see them).
local function refreshYard()
	if not yard then
		return
	end
	yard:ClearAllChildren()
	local origin = workspace:FindFirstChild("Farm") and workspace.Farm:FindFirstChild("YardSign")
	local base = if origin then origin.Position - Vector3.new(0, 7, -17) + Vector3.new(0, 0, 4) else nil
	if not base then
		return
	end
	local n = 0
	for i, m in ipairs(Config.Machines) do
		for _ = 1, player:GetAttribute("Machine_" .. i) or 0 do
			local col, rowi = n % 8, math.floor(n / 8)
			local cf = CFrame.new(base + Vector3.new(-17.5 + col * 5, 0, 2 + rowi * 6))
			local body = Ui.make("Part", { Anchored = true, CanCollide = false, CanQuery = false, Size = Vector3.new(3, 2.4 + i * 0.4, 3), CFrame = cf * CFrame.new(0, 1.2 + i * 0.2, 0), Color = Color3.fromRGB(m.color[1], m.color[2], m.color[3]), Material = Enum.Material.Metal, Parent = yard })
			local wheel = Ui.make("Part", { Anchored = true, CanCollide = false, CanQuery = false, Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 2.2, 2.2), CFrame = cf * CFrame.new(0, 2.6 + i * 0.4, -1.6) * CFrame.Angles(0, math.rad(90), 0), Color = Color3.fromRGB(80, 70, 60), Material = Enum.Material.Wood, Parent = yard })
			Ui.make("UIScale", { Parent = body }) -- harmless marker so the model reads as "machine"
			TweenService:Create(wheel, TweenInfo.new(2 - i * 0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), { CFrame = wheel.CFrame * CFrame.Angles(math.rad(180), 0, 0) }):Play()
			if n == 0 then
				billboard(body, UDim2.fromScale(14, 3), Vector3.new(0, 5, 0), { { key = "t", text = "Your machines", h = 1, color = Ui.colors.hay } })
			end
			n += 1
		end
	end
end

local function tagMerchant()
	local farm = workspace:WaitForChild("Farm", 60)
	local head = farm and farm:WaitForChild("MerchantHead", 30)
	if head then
		billboard(head, UDim2.fromScale(16, 4), Vector3.new(0, 4, 0), {
			{ key = "t", text = "Hay Merchant", h = 0.5, color = Ui.colors.hay },
			{ key = "s", text = "Walk up and press SELL", h = 0.5, color = Ui.colors.cream, max = 44 },
		})
	end
end

local function tagHatch()
	local farm = workspace:WaitForChild("Farm", 60)
	local hatch = farm and farm:WaitForChild("LoftHatch", 30)
	if hatch then
		local _, labels = billboard(hatch, UDim2.fromScale(16, 4), Vector3.new(0, 5, 0), {
			{ key = "t", text = "The Golden Loft", h = 0.5, color = Ui.colors.hay },
			{ key = "s", text = "", h = 0.5, color = Ui.colors.cream, max = 44 },
		})
		local function refresh()
			labels.s.Text = if player:GetAttribute("LoftOpen") then "Walk up to climb in" else "Locked: finish all 10 achievements"
		end
		player:GetAttributeChangedSignal("LoftOpen"):Connect(refresh)
		refresh()
	end
end

function WorldFx.start()
	task.spawn(function()
		local folder = workspace:WaitForChild("Haystacks", 60)
		if folder then
			tagMound(folder:WaitForChild("Haystack", 30), "hay", "THE HAYSTACK: " .. Format.commas(Config.TotalStraws) .. " straws, 1 needle")
			tagMound(folder:WaitForChild("GoldenHaystack", 30), "gold", "THE GOLDEN HAYSTACK: golden straw pays 20x")
		end
	end)
	task.spawn(tagMerchant)
	task.spawn(tagHatch)
	yard = Instance.new("Folder")
	yard.Name = "MyMachines"
	yard.Parent = workspace
	task.spawn(function()
		workspace:WaitForChild("Farm", 60)
		task.wait(1)
		refreshYard()
		for i in ipairs(Config.Machines) do
			player:GetAttributeChangedSignal("Machine_" .. i):Connect(refreshYard)
		end
	end)
end

return WorldFx

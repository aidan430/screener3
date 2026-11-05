-- What you see in the world: a label over each haystack (name, straws left, what your clues
-- say), straw bursts and floating coins when you search, and the windmill's turning sails.
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Format = require(Shared:WaitForChild("Format"))
local Ui = require(script.Parent.Ui)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local WorldFx = {}
local tags = {} -- [pile id] = { model, core, count, fill, status, attachment, emitter }
local possible = nil -- pile ids your latest clue still allows (nil before your first clue)
local solved = false

local function refreshTag(tag)
	local remaining = tag.model:GetAttribute("Remaining") or 0
	local total = tag.model:GetAttribute("Total") or 1
	tag.count.Text = Format.commas(remaining) .. " straws"
	tag.fill.Size = UDim2.fromScale(math.clamp(remaining / total, 0, 1), 1)
	local id = tag.model.Name
	if remaining <= 0 then
		tag.status.Text, tag.status.TextColor3 = "SEARCHED OUT", Ui.colors.grey
	elseif possible and not possible.set[id] then
		tag.status.Text, tag.status.TextColor3 = "RULED OUT", Color3.fromRGB(255, 120, 100)
	elseif possible and possible.count == 1 and not solved then
		tag.status.Text, tag.status.TextColor3 = "THE NEEDLE IS HERE!", Color3.fromRGB(140, 255, 140)
	else
		tag.status.Text = ""
	end
end

local function makeTag(model)
	local core = model:WaitForChild("Core")
	local gui = Ui.make("BillboardGui", {
		Name = "PileTag_" .. model.Name,
		Adornee = core,
		Size = UDim2.fromScale(16, 6),
		StudsOffset = Vector3.new(0, 17, 0),
		MaxDistance = 350,
		LightInfluence = 0,
		ResetOnSpawn = false,
		Parent = playerGui,
	})
	Ui.label({ Text = (model:GetAttribute("DisplayName") or model.Name) .. " haystack", Size = UDim2.fromScale(1, 0.32), Parent = gui }, 60)
	local count = Ui.label({ Size = UDim2.fromScale(1, 0.22), Position = UDim2.fromScale(0, 0.32), TextColor3 = Ui.colors.hay, Parent = gui }, 44)
	local bar = Ui.make("Frame", { Size = UDim2.fromScale(0.8, 0.1), Position = UDim2.fromScale(0.1, 0.57), BackgroundColor3 = Ui.colors.woodDark, Parent = gui }, { Ui.corner(6) })
	local fill = Ui.make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Ui.colors.hay, Parent = bar }, { Ui.corner(6) })
	local status = Ui.label({ Size = UDim2.fromScale(1, 0.26), Position = UDim2.fromScale(0, 0.72), Parent = gui }, 44)
	local attachment = Ui.make("Attachment", { Name = "StrawFx", Parent = core })
	local emitter = Ui.make("ParticleEmitter", {
		Rate = 0,
		Lifetime = NumberRange.new(0.6, 1.1),
		Speed = NumberRange.new(14, 26),
		SpreadAngle = Vector2.new(65, 65),
		Acceleration = Vector3.new(0, -40, 0),
		Size = NumberSequence.new(0.7, 0.2),
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-200, 200),
		Color = ColorSequence.new(Color3.fromRGB(242, 212, 120)),
		LightEmission = 0.15,
		EmissionDirection = Enum.NormalId.Top,
		Parent = attachment,
	})
	local tag = { model = model, core = core, count = count, fill = fill, status = status, attachment = attachment, emitter = emitter }
	tags[model.Name] = tag
	model:GetAttributeChangedSignal("Remaining"):Connect(function()
		refreshTag(tag)
	end)
	refreshTag(tag)
end

local function floatText(tag, text, colour)
	local gui = Ui.make("BillboardGui", {
		Adornee = tag.core,
		Size = UDim2.fromScale(10, 2.5),
		StudsOffset = Vector3.new(math.random(-4, 4), tag.core.Size.Y * 0.5 + 2, 0),
		LightInfluence = 0,
		AlwaysOnTop = true,
		ResetOnSpawn = false,
		Parent = playerGui,
	})
	local label = Ui.label({ Text = text, Size = UDim2.fromScale(1, 1), TextColor3 = colour, Parent = gui }, 60)
	TweenService:Create(gui, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { StudsOffset = gui.StudsOffset + Vector3.new(0, 4, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(1), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(gui, 1.1)
end

local function burst(tag, count)
	tag.attachment.Position = Vector3.new(0, tag.core.Size.Y * 0.42, 0)
	tag.emitter:Emit(count)
end

function WorldFx.searched(message)
	local tag = tags[message.pile]
	if not tag then
		return
	end
	if message.empty then
		floatText(tag, "Nothing left here!", Ui.colors.grey)
		return
	end
	burst(tag, math.clamp(math.floor(message.straws / 500) + 6, 6, 24))
	floatText(tag, "+" .. Format.short(message.coins) .. " coins", Ui.colors.hay)
end

function WorldFx.celebrate(pileId)
	local tag = tags[pileId]
	if tag then
		burst(tag, 80)
		floatText(tag, "NEEDLE FOUND!", Color3.fromRGB(140, 255, 140))
	end
end

-- clues: your clues this case, in order. The latest one says which haystacks are still possible.
function WorldFx.setClues(clues, isSolved)
	solved = isSolved == true
	local latest = clues[#clues]
	if latest then
		possible = { set = {}, count = #latest.possible }
		for _, id in ipairs(latest.possible) do
			possible.set[id] = true
		end
	else
		possible = nil
	end
	for _, tag in pairs(tags) do
		refreshTag(tag)
	end
end

local function spinWindmill()
	local landmarks = workspace:WaitForChild("Landmarks", 60)
	local windmill = landmarks and landmarks:WaitForChild("windmill", 30)
	local blades = windmill and windmill:WaitForChild("Blades", 30)
	if not blades then
		return
	end
	RunService.RenderStepped:Connect(function(dt)
		blades:PivotTo(blades:GetPivot() * CFrame.Angles(0, 0, dt * 0.5))
	end)
end

function WorldFx.start()
	task.spawn(function()
		local folder = workspace:WaitForChild("Haystacks", 60)
		if not folder then
			return
		end
		for _, model in ipairs(folder:GetChildren()) do
			task.spawn(makeTag, model)
		end
		folder.ChildAdded:Connect(makeTag)
	end)
	task.spawn(spinWindmill)
end

return WorldFx

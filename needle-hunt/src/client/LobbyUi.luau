-- The lobby and finding, on your screen:
--   Hover: when your mouse is over a needle (or a decoy) within reach, it lights up with a white
--     outline and "Click to grab!" follows the cursor, so you know you've found it.
--   Found: the needle you found vanishes from your screen (it's in your Collection now; others
--     still see theirs).
--   Join banner: a few seconds after you arrive, who in this lobby has the most valuable needle,
--     shown in 3D.
--   Show off: a button in the lobby that holds your showcase needle up for everyone to see.
--   Booths: a booth's "View collection" prompt opens that player's Collection.
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Rules = require(Shared:WaitForChild("Rules"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UiKit = require(script.Parent.UiKit)
local NeedleView = require(script.Parent.NeedleView)
local Effects = require(script.Parent.Effects)

local player = Players.LocalPlayer
local LobbyUi = {}

local function hover(gui)
	local mouse = player:GetMouse()
	local glow = Instance.new("Highlight")
	glow.FillColor, glow.FillTransparency, glow.OutlineColor = Color3.new(1, 1, 1), 0.5, Color3.new(1, 1, 1)
	glow.DepthMode, glow.Enabled = Enum.HighlightDepthMode.Occluded, false
	glow.Parent = gui
	local hint = UiKit.label({ Font = UiKit.bold, Text = "Click to grab!", Size = UDim2.fromOffset(170, 30), TextColor3 = UiKit.colors.gold, TextStrokeTransparency = 0.3, Visible = false, ZIndex = 40, Parent = gui }, 24)
	RunService.RenderStepped:Connect(function()
		local target = mouse.Target
		local model = target and target.Name == "Hitbox" and target.Parent
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local near = model and root and (target.Position - root.Position).Magnitude <= Config.Find.reach
		if near and (model.Name == "Needle" or model.Name == "Decoy") and ReplicatedStorage:GetAttribute("Phase") == "search" then
			glow.Adornee, glow.Enabled = model, true
			hint.Visible = true
			hint.Position = UDim2.fromOffset(mouse.X + 18, mouse.Y + 8)
		else
			glow.Enabled, hint.Visible = false, false
		end
	end)
end

-- The needle at `position` disappears from your screen once you've found it.
local function hideFound(position)
	local arena = workspace:FindFirstChild("Arena")
	local folder = arena and arena:FindFirstChild("Needles")
	for _, model in ipairs(folder and folder:GetChildren() or {}) do
		local hitbox = model:FindFirstChild("Hitbox")
		if hitbox and (hitbox.Position - position).Magnitude < 1 then
			for _, part in ipairs(model:GetDescendants()) do
				if part:IsA("BasePart") then
					part.LocalTransparencyModifier = 1
					part.Transparency = 1
				elseif part:IsA("ParticleEmitter") then
					part.Enabled = false
				end
			end
		end
	end
end

local function joinBanner(gui)
	task.wait(4) -- once you've had a moment to look round
	local best = Remotes.LobbyInfo:InvokeServer("best")
	local card = UiKit.make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 132), Size = UDim2.fromOffset(520, 150), BackgroundColor3 = UiKit.colors.panel, BackgroundTransparency = 0.05, ZIndex = 20, Parent = gui }, { UiKit.corner(16), UiKit.stroke(UiKit.colors.gold, 2) })
	UiKit.autoScale(card)
	if best then
		NeedleView.make(card, best.type, best.skin, { Size = UDim2.fromOffset(170, 130), Position = UDim2.fromOffset(10, 10), ZIndex = 21 }, true)
		UiKit.label({ Font = UiKit.bold, Text = "MOST VALUABLE NEEDLE IN THIS LOBBY", Size = UDim2.new(1, -200, 0, 24), Position = UDim2.fromOffset(186, 16), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UiKit.colors.gold, ZIndex = 21, Parent = card }, 20)
		UiKit.label({ Font = UiKit.bold, Text = best.needle, Size = UDim2.new(1, -200, 0, 50), Position = UDim2.fromOffset(186, 44), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 21, Parent = card }, 22)
		UiKit.label({ Text = (if best.userId == player.UserId then "That's yours!" else "owned by " .. best.name) .. "  ·  worth " .. Rules.commas(best.value), Size = UDim2.new(1, -200, 0, 22), Position = UDim2.fromOffset(186, 100), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UiKit.colors.soft, ZIndex = 21, Parent = card }, 18)
	else
		UiKit.label({ Font = UiKit.bold, Text = "Nobody here has found a needle yet. Win a round and the Champion's Needle podium is yours!", Size = UDim2.new(1, -40, 1, -30), Position = UDim2.fromOffset(20, 15), ZIndex = 21, Parent = card }, 22)
	end
	UiKit.pop(card, 0.6)
	Effects.sound("whoosh")
	task.wait(8)
	UiKit.ease(card, 0.4, { BackgroundTransparency = 1 })
	task.wait(0.4)
	card:Destroy()
end

function LobbyUi.start(gui, openCollection)
	hover(gui)
	Remotes.Found.OnClientEvent:Connect(function(m)
		if m.userId == player.UserId then
			hideFound(m.position)
		end
	end)
	task.spawn(joinBanner, gui)
	local show = UiKit.button("Show off!", Color3.fromRGB(230, 120, 170), { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 16, 1, -20), Size = UDim2.fromOffset(170, 54), Parent = gui })
	UiKit.autoScale(show)
	show.Activated:Connect(function()
		Remotes.ShowOff:FireServer()
	end)
	task.spawn(function()
		while true do
			local phase = ReplicatedStorage:GetAttribute("Phase")
			show.Visible = phase ~= "search" and phase ~= "countdown"
			task.wait(0.5)
		end
	end)
	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		local userId = prompt:GetAttribute("ViewUser")
		if userId then
			openCollection(userId)
		end
	end)
end

return LobbyUi

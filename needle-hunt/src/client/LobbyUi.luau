-- The lobby, on your screen:
--   Join banner: a few seconds after you arrive, who in this lobby has the most valuable needle,
--     shown in 3D.
--   Announcements: when anyone in the server opens a very rare needle from a box.
--   Show off: a button in the lobby that holds your showcase needle up for everyone to see.
--   Booths: a booth's "View collection" prompt opens that player's Collection.
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Rules = require(Shared:WaitForChild("Rules"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UiKit = require(script.Parent.UiKit)
local NeedleView = require(script.Parent.NeedleView)
local Effects = require(script.Parent.Effects)

local player = Players.LocalPlayer
local LobbyUi = {}

-- A very rare box opening in this server, or the 1 of 1 found on any server (Remotes.Announce):
-- a banner across the
-- top for everyone, the needle turning in it, and a line in the chat. It eases in and out.
local function announce(gui, m)
	local colour = Color3.fromRGB(m.colour[1], m.colour[2], m.colour[3])
	local card = UiKit.make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 130), Size = UDim2.fromOffset(640, 110), BackgroundColor3 = UiKit.colors.panel, BackgroundTransparency = 0.05, ZIndex = 45, Parent = gui }, { UiKit.corner(16), UiKit.stroke(colour, 3) })
	UiKit.autoScale(card)
	NeedleView.make(card, m.type, m.skin, { Size = UDim2.fromOffset(150, 100), Position = UDim2.fromOffset(8, 5), ZIndex = 46 }, true)
	UiKit.label({ Font = UiKit.bold, Text = string.upper(m.rarity) .. " FROM A " .. string.upper(m.box) .. "!", TextColor3 = colour, Size = UDim2.new(1, -180, 0, 32), Position = UDim2.fromOffset(170, 12), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 46, Parent = card }, 26)
	UiKit.label({ Text = m.name .. " got the " .. m.needle .. (if m.odds then "  (" .. m.odds .. ")" else string.format("  (a %.1f%% chance)", m.percent)), Size = UDim2.new(1, -180, 0, 50), Position = UDim2.fromOffset(170, 48), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 46, Parent = card }, 20)
	UiKit.pop(card, 0.8)
	Effects.sound("found", 1.2)
	pcall(function() -- and a line in the chat
		local channel = game:GetService("TextChatService"):FindFirstChild("RBXGeneral", true)
		if channel then
			channel:DisplaySystemMessage("✦ " .. m.name .. " opened a " .. m.box .. " and got a " .. m.rarity .. " " .. m.needle .. "!")
		end
	end)
	task.delay(7, function()
		UiKit.ease(card, 0.5, { BackgroundTransparency = 1 })
		task.wait(0.5)
		card:Destroy()
	end)
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
		UiKit.label({ Font = UiKit.bold, Text = "Nobody here has a needle yet. Open a box and the Champion's Needle podium could be yours!", Size = UDim2.new(1, -40, 1, -30), Position = UDim2.fromOffset(20, 15), ZIndex = 21, Parent = card }, 22)
	end
	UiKit.pop(card, 0.6)
	Effects.sound("whoosh")
	task.wait(8)
	UiKit.ease(card, 0.4, { BackgroundTransparency = 1 })
	task.wait(0.4)
	card:Destroy()
end

function LobbyUi.start(gui, openCollection)
	Remotes.Announce.OnClientEvent:Connect(function(m)
		announce(gui, m)
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

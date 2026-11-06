-- The lobby on your screen: a soft fade round every trip through an arch, the gentle card a
-- locked world's arch shows ("Open the Moon for 250,000 coins? [Open] [Not now]") while it
-- eases you back out, and the arches' signs saying which worlds you've opened. The server
-- decides every trip and takes the coins (server/Lobby.luau, server/Worlds.luau); the lobby's
-- light and name are eased in by client/Worlds.luau.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Ui = require(script.Parent.Ui)
local Juice = require(script.Parent.Juice)
local Cursor = require(script.Parent.Cursor)

local player = Players.LocalPlayer
local Lobby = {}
local byId = {}
for _, w in ipairs(Config.Worlds) do
	byId[w.id] = w
end

-- Each arch's sign: the world's name, and its price until you've opened it.
local function signs(folder)
	for _, model in ipairs(folder:GetChildren()) do
		local w = byId[model:GetAttribute("World") or ""]
		local sign = w and model:FindFirstChild("Sign")
		local surface = sign and sign:FindFirstChildOfClass("SurfaceGui")
		local label = surface and surface:FindFirstChildOfClass("TextLabel")
		if label then
			label.Text = w.name .. "\n" .. (if player:GetAttribute("World_" .. w.id) then "Open: walk in!" else "Opens for " .. Format.short(w.price) .. " coins")
		end
	end
end

-- A soft sky-coloured veil eases over the screen, the server moves you, and it eases away.
local function veil(gui)
	local frame = Ui.make("Frame", { Name = "PortalVeil", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(236, 242, 255), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 50, Parent = gui })
	local token = 0
	return function()
		token += 1
		local mine = token
		local f = Config.LobbyFade
		Juice.ease(frame, f.into, { BackgroundTransparency = 0 }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		task.delay(f.into + f.hold, function()
			if mine == token then
				Juice.ease(frame, f.out, { BackgroundTransparency = 1 }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			end
		end)
	end
end

local card = nil
local function closeCard()
	if card then
		card:Destroy()
		card = nil
	end
	Cursor.need("portal", false)
end

local function offer(gui, message)
	local w = byId[message.world]
	if card or not w then
		return
	end
	card = Ui.make("Frame", {
		Name = "PortalOffer",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.58),
		Size = UDim2.fromOffset(420, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Ui.colors.cream,
		Parent = gui,
	}, {
		Ui.corner(18),
		Ui.stroke(Ui.colors.wood, 4),
		Ui.make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
		Ui.make("UIPadding", { PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 16), PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }),
	})
	local scale = Ui.autoScale(card)
	local full = scale.Scale
	local coins = player:GetAttribute("Coins") or 0
	Ui.paragraph("Open " .. w.name .. " for " .. Format.commas(w.price) .. " coins?", { LayoutOrder = 1, Font = Ui.font, TextSize = 26, TextXAlignment = Enum.TextXAlignment.Center, Parent = card })
	Ui.paragraph("Hay there pays " .. w.multiplier .. "x, and travelling is free once it's open. You have " .. Format.commas(math.floor(coins)) .. " coins.", { LayoutOrder = 2, TextSize = 17, TextColor3 = Ui.colors.grey, TextXAlignment = Enum.TextXAlignment.Center, Parent = card })
	local id = w.id
	local open = Ui.button("Open", Ui.colors.green, { LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 50), Parent = card })
	open.Activated:Connect(function()
		closeCard()
		Remotes.Portal:FireServer("open", id)
	end)
	Ui.button("Not now", Ui.colors.wood, { LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 50), Parent = card }).Activated:Connect(closeCard)
	Cursor.need("portal", true)
	scale.Scale = full * 0.9 -- ease in softly
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = full }):Play()
end

-- A locked arch eases you back out the way you came in.
local function nudge(away)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root and typeof(away) == "Vector3" then
		local flat = Vector3.new(away.X, 0, away.Z)
		flat = if flat.Magnitude > 0.01 then flat.Unit else Vector3.zero
		root.CFrame += flat * 2.5 -- a step back out of the glow
		root.AssemblyLinearVelocity = flat * Config.LobbyNudge.back + Vector3.new(0, Config.LobbyNudge.up, 0)
	end
end

function Lobby.start(gui)
	local whoosh = veil(gui)
	Remotes.Portal.OnClientEvent:Connect(function(message)
		if type(message) ~= "table" then
			return
		end
		if message.kind == "whoosh" then
			closeCard()
			whoosh()
		elseif message.kind == "offer" then
			nudge(message.away)
			offer(gui, message)
		end
	end)
	task.spawn(function() -- (never hold up the rest of the screen while waiting)
		local lobby = workspace:WaitForChild("Lobby", 60)
		local folder = lobby and lobby:WaitForChild("Portals", 30)
		if not folder then
			return
		end
		signs(folder)
		for _, w in ipairs(Config.Worlds) do
			player:GetAttributeChangedSignal("World_" .. w.id):Connect(function()
				signs(folder)
			end)
		end
	end)
end

return Lobby

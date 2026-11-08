-- The Robux corner on your screen: each pad server/RobuxPads.luau built gets a floating
-- hologram (the item's icon, name, price and exactly what it gives), a ring whose colour drifts
-- slowly round soft rainbow hues, and a gentle bob. Stepping on a pad (or E at it) only offers
-- the item: Roblox's own purchase prompt, which costs nothing to close. Once per pad until you
-- step off, and never more than one offer every Config.RobuxPadCooldown seconds. The Wheel
-- of Fortune pad opens the wheel's odds instead (odds always come before buying), and is
-- removed from your screen where paid random items are restricted.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Ui = require(script.Parent.Ui)

local player = Players.LocalPlayer
local RobuxPads = {}

-- What each item gives: the same words as the shop's Robux tab (client/RobuxItems.luau).
local ITEMS = {
	WheelSpin = { "Wheel of Fortune Spin", "Your first spin each day is free. Step on to see the exact odds." },
}
for _, item in ipairs(require(script.Parent.RobuxItems)) do
	ITEMS[item.key] = { item.title, item.text }
end

local pads = {} -- model -> { ring, glow, armed, phase }
local lastOffer = -math.huge
local openPanel, screen = nil, nil
local wheelRestricted = nil -- nil until PolicyService answers

local function owned(model)
	return model:GetAttribute("Kind") == "pass" and player:GetAttribute("Pass" .. tostring(model:GetAttribute("Key"))) == true
end

local function priceText(model)
	if owned(model) then
		return "Owned"
	end
	local price = model:GetAttribute("Price")
	return if type(price) == "number" then price .. " Robux" else "Robux"
end

local function offer(model)
	local key, id = model:GetAttribute("Key"), model:GetAttribute("ItemId")
	if os.clock() - lastOffer < Config.RobuxPadCooldown or type(id) ~= "number" or id == 0 then
		return false
	end
	if key == "WheelSpin" then
		lastOffer = os.clock()
		local window = screen and screen:FindFirstChild("Wheel of Fortune")
		if openPanel and not (window and window.Visible) then -- open it, never toggle it shut
			openPanel("Wheel")
		end
		return true
	elseif owned(model) then
		return true -- yours already: nothing to offer
	end
	lastOffer = os.clock()
	pcall(function()
		if model:GetAttribute("Kind") == "pass" then
			MarketplaceService:PromptGamePassPurchase(player, id)
		else
			MarketplaceService:PromptProductPurchase(player, id)
		end
	end)
	return true
end

local function text(parent, props, size)
	local label = Ui.make("TextLabel", {
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(240, 248, 255),
		TextStrokeTransparency = 0.7,
		TextScaled = true,
		TextWrapped = true,
		Font = Enum.Font.GothamBold,
		Parent = parent,
	})
	for k, v in pairs(props) do
		label[k] = v
	end
	Ui.make("UITextSizeConstraint", { MaxTextSize = size, Parent = label })
	return label
end

-- The floating hologram: a see-through panel with the icon, name, price and description.
local function hologram(model, info)
	local anchor = model:WaitForChild("Panel", 10)
	if not anchor then
		return
	end
	local board = Instance.new("BillboardGui")
	board.Name = "Hologram"
	board.Adornee = anchor
	board.Size = UDim2.fromScale(7, 7.5) -- studs
	board.LightInfluence = 0
	board.MaxDistance = 140
	local panel = Ui.make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(40, 70, 120), BackgroundTransparency = 0.55, Parent = board }, { Ui.corner(16) })
	Ui.make("UIStroke", { Color = Color3.fromRGB(190, 225, 255), Thickness = 2, Transparency = 0.35, Parent = panel })
	-- a soft halo behind the icon that turns slowly
	local halo = Ui.make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.04), Size = UDim2.fromScale(0.5, 0.44), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.55, Parent = panel }, { Ui.corner(200), Ui.make("UIAspectRatioConstraint", { AspectRatio = 1 }) })
	local shimmer = Ui.make("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(150, 210, 255), Color3.fromRGB(240, 190, 255)), Parent = halo })
	local icon = Ui.make("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.86, 0.86), BackgroundTransparency = 1, ImageTransparency = 0.12, ScaleType = Enum.ScaleType.Fit, Image = "", Parent = halo }, { Ui.corner(200) })
	local name = text(panel, { Position = UDim2.fromScale(0.05, 0.5), Size = UDim2.fromScale(0.9, 0.14), Text = info[1] }, 30)
	local price = text(panel, { Position = UDim2.fromScale(0.05, 0.64), Size = UDim2.fromScale(0.9, 0.1), TextColor3 = Color3.fromRGB(150, 255, 190) }, 24)
	text(panel, { Position = UDim2.fromScale(0.05, 0.75), Size = UDim2.fromScale(0.9, 0.22), Font = Enum.Font.Gotham, Text = info[2] }, 18)
	board.Parent = anchor

	local prompt = model:FindFirstChild("ProximityPrompt", true)
	local function refresh()
		local image = model:GetAttribute("Icon")
		icon.Image = if type(image) == "string" then image else ""
		name.Text = info[1]
		price.Text = priceText(model)
		if prompt then
			prompt.ObjectText = info[1]
			prompt.Enabled = not owned(model)
		end
	end
	refresh()
	model:GetAttributeChangedSignal("Icon"):Connect(refresh)
	model:GetAttributeChangedSignal("Price"):Connect(refresh)
	player:GetAttributeChangedSignal("Pass" .. tostring(model:GetAttribute("Key"))):Connect(refresh)

	-- the gentle motions: a slow bob and a slowly turning shimmer (both eased, never flashing)
	board.StudsOffset = Vector3.new(0, -Config.RobuxPadBob, 0)
	TweenService:Create(board, TweenInfo.new(Config.RobuxPadBobSeconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { StudsOffset = Vector3.new(0, Config.RobuxPadBob, 0) }):Play()
	TweenService:Create(shimmer, TweenInfo.new(Config.RobuxPadSpinSeconds, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), { Rotation = 360 }):Play()
end

local function setUp(model)
	if not model:IsA("Model") or pads[model] then
		return
	end
	local key = model:GetAttribute("Key")
	local info = ITEMS[key]
	if not info then
		return
	end
	if key == "WheelSpin" then
		while wheelRestricted == nil do
			task.wait(0.5)
		end
		if wheelRestricted then
			model:Destroy() -- only from your screen: the wheel isn't offered where you live
			return
		end
	end
	local top = model:WaitForChild("Top", 10)
	if not top then
		return
	end
	local pad = { ring = model:FindFirstChild("Ring"), glow = model:FindFirstChild("Glow"), armed = true, top = top, phase = (#model.Name % 10) / 10 }
	pads[model] = pad
	hologram(model, info)
	top.Touched:Connect(function(hit)
		local character = player.Character
		if pad.armed and character and hit:IsDescendantOf(character) and offer(model) then
			pad.armed = false -- not again until you step off
		end
	end)
	model.Destroying:Connect(function()
		pads[model] = nil
	end)
end

function RobuxPads.start(gui, open)
	screen, openPanel = gui, open
	task.spawn(function()
		local ok, info = pcall(function()
			return PolicyService:GetPolicyInfoForPlayerAsync(player)
		end)
		wheelRestricted = not ok or info.ArePaidRandomItemsRestricted == true -- unknown counts as restricted
	end)
	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		if prompt:GetAttribute("Action") == "robuxpad" then
			local model = prompt:FindFirstAncestorOfClass("Model")
			if model and pads[model] then
				offer(model)
			end
		end
	end)
	-- the ring's hue drifts round soft rainbow colours; each pad a little ahead of the next
	local checked = 0
	RunService.Heartbeat:Connect(function()
		local t = os.clock() / Config.RobuxPadHueSeconds
		for _, pad in pairs(pads) do
			local hue = (t + pad.phase) % 1
			if pad.ring then
				pad.ring.Color = Color3.fromHSV(hue, 0.4, 1)
			end
			if pad.glow then
				pad.glow.Color = Color3.fromHSV(hue, 0.25, 1)
			end
		end
		if os.clock() - checked < 0.25 then
			return
		end
		checked = os.clock()
		-- a pad offers again only once you've stepped off it
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		for model, pad in pairs(pads) do
			if not pad.armed then
				local radius = (model:GetAttribute("Radius") or 3.5) + Config.RobuxPadLeave
				local flat = root and (root.Position - pad.top.Position) * Vector3.new(1, 0, 1)
				if not flat or flat.Magnitude > radius then
					pad.armed = true
				end
			end
		end
	end)
	task.spawn(function()
		local folder = workspace:WaitForChild("RobuxPads", 60)
		if not folder then
			return
		end
		folder.ChildAdded:Connect(function(child)
			task.spawn(setUp, child)
		end)
		for _, child in ipairs(folder:GetChildren()) do
			task.spawn(setUp, child)
		end
	end)
end

return RobuxPads

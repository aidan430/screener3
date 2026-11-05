-- One gentle Robux suggestion per session: after Config.OfferAfterClumps clumps harvested since
-- you joined, a small card asks "Enjoying the harvest?" and lists the Robux items that are set
-- up (ID not 0), each saying exactly what it gives, next to an equally big "No thanks".
-- No timers, no "limited", no flashing; it never comes back this session. Buying goes through
-- Roblox's own purchase prompt (which shows the price and can be cancelled), like the shop.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Ui = require(script.Parent.Ui)
local Cursor = require(script.Parent.Cursor)

local Offer = {}
local player = Players.LocalPlayer
local OPTIONS = {
	{ kind = "product", key = "SpeedBoost", title = "Speed Boost", text = "2x straws a click for 1 hour" },
	{ kind = "pass", key = "Jetpack", title = "Jetpack", text = "Fly up and hover over your pile, for good" },
}

local function available()
	local list = {}
	for _, option in ipairs(OPTIONS) do
		local id = if option.kind == "pass" then Config.GamePasses[option.key] else Config.Products[option.key]
		local alreadyOwned = option.kind == "pass" and player:GetAttribute("Pass" .. option.key) == true
		if type(id) == "number" and id ~= 0 and not alreadyOwned then
			table.insert(list, { option = option, id = id })
		end
	end
	return list
end

local function show(gui, list)
	local card = Ui.make("Frame", {
		Name = "Offer",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.6),
		Size = UDim2.fromOffset(440, 0),
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
	Ui.paragraph("Enjoying the harvest?", { LayoutOrder = 1, Font = Ui.font, TextSize = 28, TextXAlignment = Enum.TextXAlignment.Center, Parent = card })
	Ui.paragraph("If you'd like a hand, these are here. Totally optional.", { LayoutOrder = 2, TextSize = 17, TextColor3 = Ui.colors.grey, TextXAlignment = Enum.TextXAlignment.Center, Parent = card })

	Cursor.need("offer", true)
	local function close()
		Cursor.need("offer", false)
		card:Destroy()
	end
	for i, entry in ipairs(list) do
		local option, id = entry.option, entry.id
		local button = Ui.button(option.title .. ": " .. option.text .. " (Robux)", Ui.colors.blue, { LayoutOrder = 2 + i, Size = UDim2.new(1, 0, 0, 52), Parent = card })
		button.Activated:Connect(function()
			close()
			if option.kind == "pass" then
				MarketplaceService:PromptGamePassPurchase(player, id)
			else
				MarketplaceService:PromptProductPurchase(player, id)
			end
		end)
	end
	Ui.button("No thanks", Ui.colors.wood, { LayoutOrder = 10, Size = UDim2.new(1, 0, 0, 52), Parent = card }).Activated:Connect(close)

	-- ease in softly
	scale.Scale = full * 0.9
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = full }):Play()
end

function Offer.start(gui)
	local goal = Config.OfferAfterClumps or 25
	local harvested, shown = 0, false
	local last = player:GetAttribute("ClumpsLeft")
	player:GetAttributeChangedSignal("ClumpsLeft"):Connect(function()
		local now = player:GetAttribute("ClumpsLeft")
		if type(now) == "number" and type(last) == "number" and now < last and now >= last - 5 then
			harvested += last - now -- small drops only: a fresh pile or a Straw Blast don't count
		end
		last = now
		if shown or harvested < goal then
			return
		end
		shown = true -- once per session, whatever happens next
		local list = available()
		if #list > 0 then
			task.delay(1.5, show, gui, list) -- a moment after the click, not in the middle of it
		end
	end)
end

return Offer

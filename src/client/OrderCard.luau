-- The current delivery order, on the right of the screen: what the driver wants, how many
-- you've delivered, and the reward. The bar eases as your deliveries arrive.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))
local Ui = require(script.Parent.Ui)
local Juice = require(script.Parent.Juice)

local player = Players.LocalPlayer
local OrderCard = {}

function OrderCard.mount(gui)
	-- a second note pinned under the goal, askew the other way (clear of the touch action pad)
	local card = Ui.card({ AnchorPoint = Vector2.new(0, 0), Size = UDim2.fromOffset(250, 92), Rotation = 1.2, Visible = false, Parent = gui })
	Ui.autoScale(card)
	Ui.onLayout(function()
		card.Position = UDim2.new(0, 16, 0, Ui.topInset() + 10 + 330 * Ui.screenScale())
	end)
	Ui.pin(card, Ui.colors.green)
	local title = Ui.label({ Text = "Delivery order", Size = UDim2.new(1, -28, 0, 20), Position = UDim2.fromOffset(14, 12), TextColor3 = Ui.colors.ink, TextStrokeTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Parent = card }, 16)
	local text = Ui.label({ Font = Ui.body, Size = UDim2.new(1, -28, 0, 32), Position = UDim2.fromOffset(14, 34), TextWrapped = true, TextColor3 = Ui.colors.soft, TextStrokeTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Parent = card }, 14)
	local _, fill = Ui.bar(card, { Size = UDim2.new(1, -28, 0, 5), Position = UDim2.fromOffset(14, 74) })
	local function refresh()
		local wanted = player:GetAttribute("OrderText")
		local done, count = player:GetAttribute("OrderDone") or 0, player:GetAttribute("OrderCount") or 1
		card.Visible = wanted ~= nil
		text.Text = (wanted or "") .. ": " .. Format.short(done) .. "/" .. Format.short(count)
		title.Text = "Delivery order · " .. Format.short(player:GetAttribute("OrderReward") or 0) .. " coins"
		Juice.ease(fill, 0.4, { Size = UDim2.fromScale(math.clamp(done / count, 0, 1), 1) })
	end
	for _, name in ipairs({ "OrderText", "OrderDone", "OrderCount", "OrderReward" }) do
		player:GetAttributeChangedSignal(name):Connect(refresh)
	end
	refresh()
	task.spawn(function()
		while true do
			task.wait(0.5)
			local hide = OrderCard.hidden and OrderCard.hidden()
			card.Visible = player:GetAttribute("OrderText") ~= nil and not hide
		end
	end)
end

return OrderCard

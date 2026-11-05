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
	local card = Ui.make("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.38, 0), Size = UDim2.fromOffset(230, 86), BackgroundColor3 = Ui.colors.wood, BackgroundTransparency = 0.1, Visible = false, Parent = gui }, { Ui.corner(12), Ui.stroke(Ui.colors.woodDark, 3) })
	Ui.autoScale(card)
	local title = Ui.label({ Text = "DELIVERY ORDER", Size = UDim2.new(1, -16, 0, 20), Position = UDim2.fromOffset(8, 4), TextColor3 = Ui.colors.hay, Parent = card }, 16)
	local text = Ui.label({ Size = UDim2.new(1, -16, 0, 34), Position = UDim2.fromOffset(8, 24), TextWrapped = true, Parent = card }, 14)
	local track = Ui.make("Frame", { Size = UDim2.new(1, -16, 0, 10), Position = UDim2.fromOffset(8, 66), BackgroundColor3 = Ui.colors.woodDark, Parent = card }, { Ui.corner(5) })
	local fill = Ui.make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Ui.colors.hay, Parent = track }, { Ui.corner(5) })
	local function refresh()
		local wanted = player:GetAttribute("OrderText")
		local done, count = player:GetAttribute("OrderDone") or 0, player:GetAttribute("OrderCount") or 1
		card.Visible = wanted ~= nil
		text.Text = (wanted or "") .. ": " .. Format.short(done) .. "/" .. Format.short(count)
		title.Text = "DELIVERY ORDER  +" .. Format.short(player:GetAttribute("OrderReward") or 0)
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

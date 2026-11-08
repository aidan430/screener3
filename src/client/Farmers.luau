-- "Farmers here": a small paper card at the bottom right listing everyone on this server with how
-- much of their haystack they've harvested and their needles, so you can see each other's
-- progress even though each of you sees only your own farm. From each player's attributes
-- (ClumpsLeft, Needles), which every screen can read.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Ui = require(script.Parent.Ui)

local Farmers = {}

function Farmers.start(gui)
	local card = Ui.card({ AnchorPoint = Vector2.new(1, 1), Size = UDim2.fromOffset(230, 40), AutomaticSize = Enum.AutomaticSize.Y, Parent = gui }, {})
	Ui.autoScale(card)
	Ui.make("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = card })
	Ui.make("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = card })
	Ui.label({ LayoutOrder = 0, Text = "Farmers here", Size = UDim2.new(1, 0, 0, 20), TextColor3 = Ui.colors.ink, TextStrokeTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Parent = card }, 16)
	local rows = {}
	local function row(i)
		if not rows[i] then
			rows[i] = Ui.label({ LayoutOrder = i, Font = Ui.body, Size = UDim2.new(1, 0, 0, 17), TextColor3 = Ui.colors.soft, TextStrokeTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Parent = card }, 13)
		end
		return rows[i]
	end
	local function refresh()
		card.Position = UDim2.new(1, -16, 1, -16 - 62 * Ui.screenScale())
		local list = Players:GetPlayers()
		card.Visible = #list > 1 and not Ui.touch() -- alone, or on a phone, it isn't worth the space
		table.sort(list, function(a, b)
			return (a:GetAttribute("ClumpsLeft") or Config.Clumps) < (b:GetAttribute("ClumpsLeft") or Config.Clumps)
		end)
		for i, p in ipairs(list) do
			local left = p:GetAttribute("ClumpsLeft") or Config.Clumps
			local share = (1 - left / Config.Clumps) * 100
			local needles = p:GetAttribute("Needles") or 0
			local label = row(i)
			label.Visible = true
			label.Text = p.DisplayName .. "  ·  " .. string.format("%.1f%%", share) .. (if needles > 0 then "  ·  " .. needles .. " needle" .. (if needles == 1 then "" else "s") else "")
			label.TextColor3 = if p == Players.LocalPlayer then Ui.colors.ink else Ui.colors.soft
		end
		for i = #list + 1, #rows do
			rows[i].Visible = false
		end
	end
	Ui.onLayout(refresh)
	Players.PlayerAdded:Connect(refresh)
	Players.PlayerRemoving:Connect(function()
		task.defer(refresh)
	end)
	task.spawn(function()
		while true do
			task.wait(3)
			refresh()
		end
	end)
end

return Farmers

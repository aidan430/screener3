-- The always-on screen: the great haystack counter at the top, your coins and search power
-- on the left, and the buttons for the shop, the clue book, rebirth and auto search.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Ui = require(script.Parent.Ui)

local player = Players.LocalPlayer
local gameState = ReplicatedStorage:WaitForChild("GameState")

local Hud = {}

function Hud.mount(gui, open)
	local top = Ui.make("Frame", {
		Name = "Haystack",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 6),
		Size = UDim2.fromOffset(470, 80),
		BackgroundColor3 = Ui.colors.wood,
		Parent = gui,
	}, { Ui.corner(14), Ui.stroke(Ui.colors.woodDark, 3) })
	Ui.autoScale(top)
	local caseLabel = Ui.label({ Size = UDim2.new(1, -20, 0, 22), Position = UDim2.fromOffset(10, 4), TextColor3 = Ui.colors.hay, Parent = top }, 20)
	local countLabel = Ui.label({ Size = UDim2.new(1, -20, 0, 26), Position = UDim2.fromOffset(10, 27), Parent = top }, 26)
	local bar = Ui.make("Frame", { Size = UDim2.new(1, -24, 0, 14), Position = UDim2.fromOffset(12, 58), BackgroundColor3 = Ui.colors.woodDark, Parent = top }, { Ui.corner(7) })
	local fill = Ui.make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Ui.colors.hay, Parent = bar }, { Ui.corner(7) })

	local left = Ui.make("Frame", {
		Name = "Left",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.fromOffset(200, 380),
		BackgroundTransparency = 1,
		Parent = gui,
	}, { Ui.make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })
	Ui.autoScale(left)
	local stats = Ui.make("Frame", { LayoutOrder = 1, Size = UDim2.fromOffset(200, 106), BackgroundColor3 = Ui.colors.wood, Parent = left }, { Ui.corner(12), Ui.stroke(Ui.colors.woodDark, 3) })
	local coinsLabel = Ui.label({ Size = UDim2.new(1, -16, 0, 40), Position = UDim2.fromOffset(8, 6), TextColor3 = Ui.colors.hay, Parent = stats }, 36)
	local powerLabel = Ui.label({ Size = UDim2.new(1, -16, 0, 22), Position = UDim2.fromOffset(8, 50), Parent = stats }, 20)
	local bonusLabel = Ui.label({ Size = UDim2.new(1, -16, 0, 22), Position = UDim2.fromOffset(8, 76), Parent = stats }, 18)

	local function button(order, text, colour, onClick)
		local b = Ui.button(text, colour, { LayoutOrder = order, Size = UDim2.fromOffset(200, 50), Parent = left })
		b.Activated:Connect(onClick)
		return b
	end
	button(2, "SHOP", Ui.colors.green, function()
		open("Shop")
	end)
	local cluesButton = button(3, "CLUE BOOK", Ui.colors.blue, function()
		open("Clue Book")
	end)
	button(4, "REBIRTH", Ui.colors.purple, function()
		open("Rebirth")
	end)
	local autoButton = button(5, "AUTO: OFF", Ui.colors.grey, function()
		Remotes.ToggleAuto:FireServer(not player:GetAttribute("AutoOn"))
	end)

	local function refreshHaystack()
		local total = gameState:GetAttribute("TotalStraws") or Config.TotalStraws
		local remaining = gameState:GetAttribute("Remaining") or total
		caseLabel.Text = "CASE #" .. (gameState:GetAttribute("Case") or 1) .. ": " .. (gameState:GetAttribute("CaseTitle") or "")
		if gameState:GetAttribute("Phase") == "solved" then
			countLabel.Text = "NEEDLE FOUND! The next case starts soon..."
		else
			countLabel.Text = Format.commas(remaining) .. " straws left. 1 needle."
		end
		fill.Size = UDim2.fromScale(math.clamp(remaining / total, 0, 1), 1)
	end

	local function refreshPlayer()
		coinsLabel.Text = Format.short(player:GetAttribute("Coins") or 0) .. " coins"
		powerLabel.Text = Format.short(player:GetAttribute("Power") or 0) .. " straws a search"
		bonusLabel.Text = "Coin bonus: x" .. string.format("%.1f", player:GetAttribute("Multiplier") or 1)
		autoButton.Visible = player:GetAttribute("PassAutoSearch") == true
		local on = player:GetAttribute("AutoOn") == true
		autoButton.Text = on and "AUTO: ON" or "AUTO: OFF"
		autoButton.BackgroundColor3 = on and Ui.colors.green or Ui.colors.grey
	end

	gameState.AttributeChanged:Connect(refreshHaystack)
	player.AttributeChanged:Connect(refreshPlayer)
	refreshHaystack()
	refreshPlayer()

	local hud = {}
	function hud.setClues(found, count)
		cluesButton.Text = if count > 0 then "CLUE BOOK " .. found .. "/" .. count else "CLUE BOOK"
	end
	return hud
end

return Hud

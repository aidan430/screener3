-- The windows: the Shop (tools for coins, extras for Robux), the Clue Book and Rebirth.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))(Config)
local Format = require(Shared:WaitForChild("Format"))
local Piles = require(Shared:WaitForChild("Piles"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Ui = require(script.Parent.Ui)

local player = Players.LocalPlayer
local gameState = ReplicatedStorage:WaitForChild("GameState")

local ROBUX = {
	{ kind = "pass", key = "DoubleCoins", title = "2x Coins", text = "Every search earns double coins, forever." },
	{ kind = "pass", key = "AutoSearch", title = "Auto Search", text = "Searches by itself while you hold your tool by a haystack." },
	{ kind = "product", key = "ClueHint", title = "Clue Hint", text = "Get your next clue right now." },
}

local Panels = {}

local function ask(remote, ...)
	local ok, success, message = pcall(remote.InvokeServer, remote, ...)
	if not ok then
		return false, "The farm didn't answer. Try again."
	end
	return success, message
end

function Panels.mount(gui, state, notify)
	local windows = {}
	local refreshers = {}

	local function open(name)
		for key, frame in pairs(windows) do
			if key == name then
				frame.Visible = not frame.Visible
				if frame.Visible and refreshers[key] then
					refreshers[key]()
				end
			else
				frame.Visible = false
			end
		end
	end

	-- Shop
	local shop, shopBody = Ui.window(gui, "Shop")
	windows.Shop = shop
	local buyButtons = {}
	for level, tool in ipairs(Config.Tools) do
		local row = Ui.make("Frame", { LayoutOrder = level, Size = UDim2.new(1, 0, 0, 66), BackgroundColor3 = Ui.colors.paper, Parent = shopBody }, { Ui.corner(10) })
		Ui.label({ Text = tool.name, Size = UDim2.new(0.58, -12, 0, 30), Position = UDim2.fromOffset(12, 5), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Ui.colors.ink, TextStrokeTransparency = 1, Parent = row }, 26)
		Ui.label({ Text = Format.commas(tool.power) .. " straws a search", Size = UDim2.new(0.58, -12, 0, 22), Position = UDim2.fromOffset(12, 38), Font = Ui.body, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Ui.colors.grey, TextStrokeTransparency = 1, Parent = row }, 18)
		local buy = Ui.button("", Ui.colors.green, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0.4, 0, 0, 48), Parent = row })
		buy.Activated:Connect(function()
			local ok, message = ask(Remotes.BuyTool, level)
			notify.toast(message, ok and Ui.colors.green or Ui.colors.red)
			if refreshers.Shop then
				refreshers.Shop()
			end
		end)
		buyButtons[level] = buy
	end
	local order = #Config.Tools
	for _, item in ipairs(ROBUX) do
		local id = if item.kind == "pass" then Config.GamePasses[item.key] else Config.Products[item.key]
		if id and id ~= 0 then
			order += 1
			local row = Ui.make("Frame", { LayoutOrder = order, Size = UDim2.new(1, 0, 0, 66), BackgroundColor3 = Color3.fromRGB(226, 236, 250), Parent = shopBody }, { Ui.corner(10) })
			Ui.label({ Text = item.title, Size = UDim2.new(0.62, -12, 0, 30), Position = UDim2.fromOffset(12, 5), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Ui.colors.ink, TextStrokeTransparency = 1, Parent = row }, 26)
			Ui.label({ Text = item.text, Size = UDim2.new(0.62, -12, 0, 24), Position = UDim2.fromOffset(12, 37), Font = Ui.body, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Ui.colors.grey, TextStrokeTransparency = 1, Parent = row }, 16)
			local buy = Ui.button("ROBUX", Ui.colors.blue, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0.34, 0, 0, 48), Parent = row })
			buy.Activated:Connect(function()
				if item.kind == "pass" then
					MarketplaceService:PromptGamePassPurchase(player, id)
				else
					MarketplaceService:PromptProductPurchase(player, id)
				end
			end)
		end
	end
	refreshers.Shop = function()
		local coins, owned = player:GetAttribute("Coins") or 0, player:GetAttribute("Tool") or 1
		for level, button in pairs(buyButtons) do
			local tool = Config.Tools[level]
			if level <= owned then
				button.Text, button.BackgroundColor3 = "OWNED", Ui.colors.grey
			elseif level == owned + 1 then
				button.Text = "BUY " .. Format.short(tool.price)
				button.BackgroundColor3 = if coins >= tool.price then Ui.colors.green else Ui.colors.red
			else
				button.Text, button.BackgroundColor3 = "LOCKED", Ui.colors.grey
			end
		end
	end

	-- Clue Book
	local book, bookBody = Ui.window(gui, "Clue Book")
	windows["Clue Book"] = book
	refreshers["Clue Book"] = function()
		for _, child in ipairs(bookBody:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		local n = 0
		local function line(text, props)
			n += 1
			props = props or {}
			props.LayoutOrder = n
			props.Parent = bookBody
			return Ui.paragraph(text, props)
		end
		line("CASE #" .. (gameState:GetAttribute("Case") or 1) .. ": " .. (gameState:GetAttribute("CaseTitle") or ""), { Font = Ui.font, TextSize = 26 })
		line(gameState:GetAttribute("CaseIntro") or "", { TextColor3 = Ui.colors.grey })
		local count = gameState:GetAttribute("ClueCount") or 0
		line("Clues found: " .. #state.clues .. " of " .. count, { Font = Ui.font, TextSize = 22 })
		if #state.clues == 0 then
			line("None yet. Every search of any haystack can turn up a clue.")
		end
		for i, clue in ipairs(state.clues) do
			line(i .. ". " .. clue.text, { TextColor3 = Ui.colors.blue })
		end
		local latest = state.clues[#state.clues]
		local possible = {}
		for _, id in ipairs(latest and latest.possible or {}) do
			possible[id] = true
		end
		line("The haystacks:", { Font = Ui.font, TextSize = 22 })
		for _, pile in ipairs(Piles) do
			local out = latest ~= nil and not possible[pile.id]
			local text = pile.name .. " (" .. pile.side .. ")" .. (if out then ": ruled out" elseif latest and #latest.possible == 1 then ": THE NEEDLE IS HERE!" else "")
			line(text, { TextColor3 = if out then Ui.colors.grey else Ui.colors.ink })
		end
	end

	-- Rebirth
	local rebirth, rebirthBody = Ui.window(gui, "Rebirth")
	windows.Rebirth = rebirth
	local info = Ui.paragraph("", { LayoutOrder = 1, Parent = rebirthBody })
	local go = Ui.button("REBIRTH", Ui.colors.purple, { LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 56), Parent = rebirthBody })
	go.Activated:Connect(function()
		local ok, message = ask(Remotes.Rebirth)
		notify.toast(message, ok and Ui.colors.purple or Ui.colors.red)
		if ok then
			rebirth.Visible = false
		end
	end)
	refreshers.Rebirth = function()
		local rebirths = player:GetAttribute("Rebirths") or 0
		local cost = Economy.rebirthCost(rebirths)
		info.Text = "Start again with 0 coins and the " .. Config.Tools[1].name .. ", and earn +"
			.. math.floor(Config.RebirthCoinBonus * 100) .. "% coins on every search, forever.\n\n"
			.. "Rebirths so far: " .. rebirths .. ".\nThis one costs " .. Format.short(cost) .. " coins. You have "
			.. Format.short(player:GetAttribute("Coins") or 0) .. "."
	end

	player.AttributeChanged:Connect(function()
		for key, frame in pairs(windows) do
			if frame.Visible and key ~= "Clue Book" and refreshers[key] then
				refreshers[key]()
			end
		end
	end)

	local panels = {}
	panels.open = open
	function panels.refresh()
		if book.Visible then
			refreshers["Clue Book"]()
		end
	end
	return panels
end

return Panels

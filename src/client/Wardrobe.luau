-- The Wardrobe, a page of the farm journal: every milestone cosmetic (titles, hats, trails,
-- auras) as a card with its rarity, how to unlock it, and Wear / Take off once it's yours.
-- Everyone on the server sees what you wear (server/Cosmetics).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Ui = require(script.Parent.Ui)

local player = Players.LocalPlayer
local Wardrobe = {}
local KINDS = { title = "Title", hat = "Hat", trail = "Trail", aura = "Aura" }

-- Which milestone unlocks each cosmetic, for the card's "how to get it" line.
local how = {}
for _, a in ipairs(Config.Achievements) do
	for _, id in ipairs(a.cosmetics or {}) do
		how[id] = a.text
	end
end

local function rgb(c)
	local v = c.colours[1]
	return if type(v) == "table" then Color3.fromRGB(v[1], v[2], v[3]) else Color3.fromHSV(0.12, 0.5, 1)
end

function Wardrobe.mount(gui)
	local frame, body = Ui.window(gui, "Wardrobe", nil, "Wardrobe")
	Ui.fit(frame, 640, 520)
	local hours = Ui.paragraph("", { LayoutOrder = 0, TextSize = 15, TextColor3 = Ui.colors.soft, Parent = body })
	local grid = Ui.make("Frame", { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = body }, {
		Ui.make("UIGridLayout", { CellSize = UDim2.new(1 / 3, -8, 0, 150), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local cards = {}
	for i, c in ipairs(Config.Cosmetics) do
		local card = Ui.card({ LayoutOrder = i, BackgroundColor3 = Ui.colors.white, Parent = grid })
		local swatch = Ui.make("Frame", { Size = UDim2.new(1, -16, 0, 34), Position = UDim2.fromOffset(8, 8), BackgroundColor3 = rgb(c), Parent = card }, { Ui.corner(4) })
		if type(c.colours[2]) == "table" or c.colours[1] == "rainbow" then
			local g = Instance.new("UIGradient")
			if c.colours[1] == "rainbow" then
				swatch.BackgroundColor3 = Color3.new(1, 1, 1)
				g.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 0.5, 1)), ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 0.5, 1)), ColorSequenceKeypoint.new(1, Color3.fromHSV(0.85, 0.5, 1)) })
			else
				swatch.BackgroundColor3 = Color3.new(1, 1, 1)
				g.Color = ColorSequence.new(rgb(c), Color3.fromRGB(c.colours[2][1], c.colours[2][2], c.colours[2][3]))
			end
			g.Parent = swatch
		end
		Ui.label({ Text = KINDS[c.kind] .. " · " .. c.rarity, Font = Ui.bold, Size = UDim2.new(1, -16, 0, 14), Position = UDim2.fromOffset(8, 46), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Ui.colors.hay, TextStrokeTransparency = 1, Parent = card }, 11)
		Ui.label({ Text = c.name, Size = UDim2.new(1, -16, 0, 20), Position = UDim2.fromOffset(8, 61), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Ui.colors.ink, TextStrokeTransparency = 1, Parent = card }, 15)
		local note = Ui.label({ Text = how[c.id] or "", Font = Ui.body, Size = UDim2.new(1, -16, 0, 26), Position = UDim2.fromOffset(8, 82), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = Ui.colors.soft, TextStrokeTransparency = 1, Parent = card }, 11)
		local button = Ui.button("Locked", Ui.colors.paper, { Size = UDim2.new(1, -16, 0, 28), Position = UDim2.new(0, 8, 1, -36), Parent = card })
		button.Activated:Connect(function()
			local owned = string.find("," .. (player:GetAttribute("Cosmetics") or "") .. ",", "," .. c.id .. ",", 1, true)
			if not owned then
				return
			end
			local wearing = player:GetAttribute("Wearing_" .. c.kind) == c.id
			Remotes.Wear:FireServer(c.kind, if wearing then "" else c.id)
		end)
		cards[c.id] = { button = button, note = note, c = c }
	end
	local function refresh()
		hours.Text = "You've played " .. (player:GetAttribute("PlayHours") or 0) .. " hours. Unlock these by reaching milestones in Achievements. Everyone on your server sees what you wear."
		local owned = "," .. (player:GetAttribute("Cosmetics") or "") .. ","
		for id, k in pairs(cards) do
			local mine = string.find(owned, "," .. id .. ",", 1, true) ~= nil
			local wearing = player:GetAttribute("Wearing_" .. k.c.kind) == id
			k.button.Text = if not mine then "Locked" elseif wearing then "Take off" else "Wear"
			k.button.BackgroundColor3 = if not mine then Ui.colors.paper elseif wearing then Ui.colors.ink else Ui.colors.green
			k.button.TextColor3 = if mine then Ui.colors.white else Ui.colors.soft
		end
	end
	player.AttributeChanged:Connect(function(name)
		if name == "Cosmetics" or name == "PlayHours" or string.sub(name, 1, 8) == "Wearing_" then
			refresh()
		end
	end)
	refresh()
	return frame, refresh
end

return Wardrobe

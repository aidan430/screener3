-- The Collection screen: every needle you've found, by type, shown in 3D with its rarity, value
-- and how many you have; ones you haven't found yet are "???" outlined in their rarity colour.
-- Look at anyone else's collection in the server with the buttons along the top. On your own,
-- click a needle to put it on show (your showcase: on the lobby's pedestals and next to your name).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Needles = require(Shared:WaitForChild("Needles"))
local Rules = require(Shared:WaitForChild("Rules"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UiKit = require(script.Parent.UiKit)
local NeedleView = require(script.Parent.NeedleView)
local Hud = require(script.Parent.Hud)

local player = Players.LocalPlayer
local Screens3 = {}
local win, body
local viewing = nil -- userId whose collection is open (nil = yours)
local typeId = "sewing"

local function rgb(c)
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function clear()
	for _, c in ipairs(body:GetChildren()) do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
end

local function row(order, height)
	return UiKit.make("Frame", { LayoutOrder = order, Size = UDim2.new(1, -8, 0, height), BackgroundTransparency = 1, Parent = body }, {
		UiKit.make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
end

function Screens3.refresh()
	if not win or not win.Visible then
		return
	end
	clear()
	local data = Remotes.Collection:InvokeServer("get", viewing)
	if not data then
		UiKit.label({ LayoutOrder = 1, Text = "That collection isn't available right now.", Size = UDim2.new(1, 0, 0, 40), Parent = body }, 22)
		return
	end
	local mine = data.userId == player.UserId
	-- whose collection: you, or anyone else here
	local people = row(1, 40)
	for i, p in ipairs(Remotes.Collection:InvokeServer("list") or {}) do
		local b = UiKit.button((if p.userId == player.UserId then "You" else p.name) .. " · " .. Rules.commas(p.value), if p.userId == data.userId then UiKit.colors.gold else UiKit.colors.card, { LayoutOrder = i, Size = UDim2.fromOffset(170, 40), Parent = people })
		b.Activated:Connect(function()
			viewing = if p.userId == player.UserId then nil else p.userId
			Screens3.refresh()
		end)
	end
	local found, total = 0, Needles.count()
	for _ in pairs(data.entries) do
		found += 1
	end
	local st, ss = Needles.split(data.showcase)
	UiKit.label({ LayoutOrder = 2, Font = UiKit.bold, Text = (if mine then "Your collection" else data.name .. "'s collection") .. ":  " .. Rules.commas(data.value) .. " value  ·  " .. found .. " / " .. total .. " needles", Size = UDim2.new(1, -8, 0, 30), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UiKit.colors.gold, Parent = body }, 22)
	UiKit.label({ LayoutOrder = 3, Text = if st then "On show: " .. Needles.name(st, ss) .. (if mine then "  (click any needle you own to show it instead)" else "") else "Nothing on show yet.", Size = UDim2.new(1, -8, 0, 22), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UiKit.colors.soft, Parent = body }, 17)
	-- the types, as tabs
	local tabs = UiKit.make("ScrollingFrame", { LayoutOrder = 4, Size = UDim2.new(1, -8, 0, 46), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollingDirection = Enum.ScrollingDirection.X, ScrollBarThickness = 4, AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new(), Parent = body }, {
		UiKit.make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	for i, t in ipairs(Needles.types) do
		local have = 0
		for _, s in ipairs(Needles.skinsFor(t.id)) do
			if data.entries[Needles.key(t.id, s.id)] then
				have += 1
			end
		end
		local b = UiKit.button(t.name .. "  " .. have .. "/" .. #Needles.skinsFor(t.id), if t.id == typeId then UiKit.colors.blue else UiKit.colors.card, { LayoutOrder = i, Size = UDim2.fromOffset(220, 40), Parent = tabs })
		b.Activated:Connect(function()
			typeId = t.id
			Screens3.refresh()
		end)
	end
	-- every skin of this type
	local grid = UiKit.make("Frame", { LayoutOrder = 5, Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = body }, {
		UiKit.make("UIGridLayout", { CellSize = UDim2.fromOffset(132, 150), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	for i, s in ipairs(Needles.skinsFor(typeId)) do
		local key = Needles.key(typeId, s.id)
		local count = data.entries[key] or 0
		local rarity = Needles.rarity(s.rarity)
		local cell = UiKit.make("TextButton", { LayoutOrder = i, Text = "", AutoButtonColor = count > 0 and mine, BackgroundColor3 = UiKit.colors.card, Parent = grid }, {
			UiKit.corner(10), UiKit.stroke(rgb(rarity.colour), if key == data.showcase then 3 else 1.5),
		})
		if count > 0 then
			NeedleView.make(cell, typeId, s.id, { Size = UDim2.new(1, -8, 0, 84), Position = UDim2.fromOffset(4, 4) })
			UiKit.label({ Font = UiKit.bold, Text = s.name .. (if count > 1 then "  x" .. count else ""), Size = UDim2.new(1, -8, 0, 22), Position = UDim2.fromOffset(4, 88), Parent = cell }, 16)
			UiKit.label({ Text = rarity.name .. " · " .. Rules.commas(Needles.value(typeId, s.id)), Size = UDim2.new(1, -8, 0, 18), Position = UDim2.fromOffset(4, 112), TextColor3 = rgb(rarity.colour), Parent = cell }, 14)
			if key == data.showcase then
				UiKit.label({ Text = "ON SHOW", Font = UiKit.bold, Size = UDim2.new(1, -8, 0, 14), Position = UDim2.fromOffset(4, 132), TextColor3 = UiKit.colors.gold, Parent = cell }, 12)
			end
			if mine then
				cell.Activated:Connect(function()
					if Remotes.Collection:InvokeServer("showcase", key) then
						Hud.toast(Needles.name(typeId, s.id) .. " is on show.", "good")
						Screens3.refresh()
					end
				end)
			end
		else
			UiKit.label({ Font = UiKit.bold, Text = "???", Size = UDim2.new(1, 0, 0, 70), Position = UDim2.fromOffset(0, 14), TextColor3 = UiKit.colors.line, Parent = cell }, 34)
			UiKit.label({ Text = rarity.name, Size = UDim2.new(1, -8, 0, 18), Position = UDim2.fromOffset(4, 112), TextColor3 = rgb(rarity.colour), Parent = cell }, 14)
		end
	end
end

-- Opens on a given player's collection next time it refreshes (nil = yours).
function Screens3.view(userId)
	viewing = if userId == player.UserId then nil else userId
end

function Screens3.mount(gui)
	win, body = UiKit.window(gui, "Collection", 760, 560)
	return { Collection = win }, { Collection = Screens3.refresh }
end

return Screens3

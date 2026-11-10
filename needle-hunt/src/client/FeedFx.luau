-- The tag-out feed, top right beside the menu (server/Streaks sends every tag-out to everyone; Config.Streak.feed):
-- "Sam  →  Riley", THROW for a thrown needle, the tagger's streak from 2, MARKED when they are,
-- and a line when someone ends a Marked player's streak. Your own name is in gold. Each line eases
-- in and fades out after a few seconds.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UiKit = require(script.Parent.UiKit)

local player = Players.LocalPlayer
local FeedFx = {}
local F = Config.Streak.feed
local RED, HOT, GOLD = Color3.fromRGB(255, 70, 70), Color3.fromRGB(255, 140, 70), UiKit.colors.gold

local function esc(s)
	return (tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function name(text, id, colour)
	local c = if id == player.UserId then GOLD else colour
	return string.format('<font color="#%s"><b>%s</b></font>', c:ToHex(), esc(text))
end

function FeedFx.start(gui)
	local list = UiKit.make("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -180, 0, 12), Size = UDim2.fromOffset(360, F.lines * 38), BackgroundTransparency = 1, Parent = gui }, {
		UiKit.make("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right }),
	})
	UiKit.autoScale(list)
	local order = 0
	Remotes.Feed.OnClientEvent:Connect(function(m)
		order -= 1 -- newest on top
		local tags = {}
		if m.how == "throw" then
			table.insert(tags, '<font color="#ffb45a">THROW</font>')
		end
		if m.marked then
			table.insert(tags, '<font color="#ff4646"><b>MARKED</b></font>')
		elseif (m.streak or 0) >= 2 then
			table.insert(tags, string.format('<font color="#ff8c46">x%d</font>', m.streak))
		end
		local text = name(m.by, m.byId, Color3.new(1, 1, 1)) .. "  →  " .. name(m.target, m.targetId, Color3.fromRGB(200, 205, 220))
		if #tags > 0 then
			text ..= "   " .. table.concat(tags, " ")
		end
		if m.endedMarked then
			text ..= '   <font color="#ff4646">ended a Marked streak!</font>'
		end
		local row = UiKit.make("Frame", { LayoutOrder = order, Size = UDim2.fromOffset(360, 34), BackgroundColor3 = UiKit.colors.panel, BackgroundTransparency = 0.25, Parent = list }, {
			UiKit.corner(8), UiKit.stroke(if m.marked or m.endedMarked then RED elseif (m.streak or 0) >= 3 then HOT else UiKit.colors.line, 1.5),
		})
		local label = UiKit.label({ Text = text, RichText = true, Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(8, 0), TextXAlignment = Enum.TextXAlignment.Right, Parent = row }, 16)
		UiKit.pop(row, 0.9)
		local rows = {}
		for _, r in ipairs(list:GetChildren()) do
			if r:IsA("Frame") then
				table.insert(rows, r)
			end
		end
		table.sort(rows, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		for i = F.lines + 1, #rows do -- only the newest few
			rows[i]:Destroy()
		end
		task.delay(F.seconds, function()
			if row.Parent then
				UiKit.ease(row, 0.6, { BackgroundTransparency = 1 })
				UiKit.ease(label, 0.6, { TextTransparency = 1 })
				task.wait(0.65)
				row:Destroy()
			end
		end)
	end)
end

return FeedFx

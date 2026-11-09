-- The Achievements page's list: open milestones first (name, what to do, a progress bar, and
-- what they unlock), then the secret ones (??? until earned). From Remotes.GetAchievements.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Ui = require(script.Parent.Ui)

local Milestones = {}
local names = {}
for _, c in ipairs(Config.Cosmetics) do
	names[c.id] = c.name
end

local function amount(a)
	if a.goal and a.id and string.sub(a.id, 1, 4) == "play" then
		local h = math.floor((a.have or 0) * 10) / 10
		return h .. " of " .. a.goal .. " hours"
	end
	return Format.short(math.floor(a.have or 0)) .. " of " .. Format.short(a.goal or 0)
end

local function prizes(a)
	local out = {}
	for _, id in ipairs(a.cosmetics or {}) do
		table.insert(out, names[id] or id)
	end
	if (a.spins or 0) > 0 then
		table.insert(out, a.spins .. " free spin" .. (if a.spins == 1 then "" else "s"))
	end
	return table.concat(out, " · ")
end

function Milestones.render(body, list)
	for _, child in ipairs(body:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local done, secretDone, secrets = 0, 0, 0
	for _, a in ipairs(list) do
		done += if a.done then 1 else 0
	end
	Ui.paragraph(done .. " of " .. #list .. " done. Any " .. Config.LoftAchievements .. " open a golden door...", { LayoutOrder = 0, Font = Ui.font, TextSize = 18, Parent = body })
	for i, a in ipairs(list) do
		local open = a.open == true
		local order = if open then 100 + i else 1000 + i
		local card = Ui.card({ LayoutOrder = order, Size = UDim2.new(1, 0, 0, if open then 86 else 56), BackgroundColor3 = if a.done then Color3.fromRGB(226, 238, 214) else Ui.colors.white, Parent = body })
		Ui.label({ Text = if a.done or open then a.name else "???", Size = UDim2.new(0.62, -14, 0, 22), Position = UDim2.fromOffset(14, 8), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Ui.colors.ink, TextStrokeTransparency = 1, Parent = card }, 17)
		Ui.label({ Text = if a.done or open then a.text else "A secret achievement. Keep playing to discover it.", Font = Ui.body, Size = UDim2.new(1, -28, 0, 18), Position = UDim2.fromOffset(14, 31), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Ui.colors.soft, TextStrokeTransparency = 1, Parent = card }, 13)
		if open then
			local _, fill = Ui.bar(card, { Size = UDim2.new(0.55, 0, 0, 6), Position = UDim2.new(0, 14, 1, -20) }, if a.done then Ui.colors.green else Ui.colors.hay)
			fill.Size = UDim2.fromScale(math.clamp((a.have or 0) / math.max(a.goal or 1, 1), 0, 1), 1)
			Ui.label({ Text = if a.done then "Unlocked" else amount(a), Font = Ui.body, AnchorPoint = Vector2.new(0, 1), Size = UDim2.new(0.4, -20, 0, 16), Position = UDim2.new(0.6, 0, 1, -14), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Ui.colors.soft, TextStrokeTransparency = 1, Parent = card }, 13)
			local p = prizes(a)
			if p ~= "" then
				Ui.label({ Text = p, Font = Ui.bold, AnchorPoint = Vector2.new(1, 0), Size = UDim2.new(0.38, -14, 0, 20), Position = UDim2.new(1, -14, 0, 9), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = Ui.colors.hay, TextStrokeTransparency = 1, Parent = card }, 13)
			end
		else
			secrets += 1
			secretDone += if a.done then 1 else 0
		end
	end
	Ui.paragraph("Secret achievements: " .. secretDone .. " of " .. secrets .. " found", { LayoutOrder = 999, Font = Ui.font, TextSize = 16, Parent = body })
end

return Milestones

-- The Achievements window and the Finds notebook (the story bits your lucky finds revealed).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Ui = require(script.Parent.Ui)
local Shop = require(script.Parent.Shop)

local Panels = {}

function Panels.mount(gui, notify)
	local windows, refreshers = {}, {}
	windows.Shop = Shop.mount(gui, notify)
	refreshers.Shop = Shop.refresh

	-- Achievements
	local achievements, achievementsBody = Ui.window(gui, "Achievements")
	windows.Achievements = achievements
	local header = Ui.paragraph("", { LayoutOrder = 0, Font = Ui.font, TextSize = 22, Parent = achievementsBody })
	local rows = {}
	for i, a in ipairs(Config.Achievements) do
		local frame = Ui.make("Frame", { LayoutOrder = i, Size = UDim2.new(1, 0, 0, 62), BackgroundColor3 = Ui.colors.paper, Parent = achievementsBody }, { Ui.corner(10) })
		local name = Ui.label({ Text = a.name, Size = UDim2.new(0.68, -12, 0, 28), Position = UDim2.fromOffset(12, 4), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Ui.colors.ink, TextStrokeTransparency = 1, Parent = frame }, 22)
		Ui.label({ Text = a.text, Size = UDim2.new(0.68, -12, 0, 24), Position = UDim2.fromOffset(12, 34), Font = Ui.body, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Ui.colors.grey, TextStrokeTransparency = 1, Parent = frame }, 15)
		local state = Ui.label({ Size = UDim2.new(0.3, -12, 1, -12), Position = UDim2.new(0.7, 0, 0, 6), TextColor3 = Ui.colors.grey, TextStrokeTransparency = 1, Parent = frame }, 18)
		rows[a.id] = { frame = frame, name = name, state = state }
	end
	Ui.paragraph("Complete all ten to open the Golden Loft above the barn.", { LayoutOrder = 99, TextColor3 = Ui.colors.purple, Font = Ui.font, TextSize = 20, Parent = achievementsBody })
	refreshers.Achievements = function()
		task.spawn(function()
			local ok, list = pcall(function()
				return Remotes.GetAchievements:InvokeServer()
			end)
			if not ok or type(list) ~= "table" then
				return
			end
			local done = 0
			for _, a in ipairs(list) do
				local r = rows[a.id]
				if r then
					if a.done then
						done += 1
						r.state.Text, r.state.TextColor3 = "DONE", Ui.colors.green
						r.frame.BackgroundColor3 = Color3.fromRGB(226, 244, 220)
					else
						r.state.Text = Format.short(math.min(a.value, a.goal)) .. " / " .. Format.short(a.goal)
						r.state.TextColor3 = Ui.colors.grey
					end
				end
			end
			header.Text = done .. " of " .. #list .. " achievements done"
		end)
	end

	-- Finds notebook
	local finds, findsBody = Ui.window(gui, "Finds")
	windows.Finds = finds
	local found = {}
	Ui.paragraph("Odd things turn up in the hay. The merchant pays for them, and each one tells a bit of the story.", { LayoutOrder = 0, TextColor3 = Ui.colors.grey, Parent = findsBody })
	local empty = Ui.paragraph("Nothing found yet. Keep searching!", { LayoutOrder = 1, Parent = findsBody })
	refreshers.Finds = function() end

	local function open(name)
		for key, frame in pairs(windows) do
			if key == name then
				frame.Visible = not frame.Visible
				if frame.Visible then
					refreshers[key]()
				end
			else
				frame.Visible = false
			end
		end
	end

	local panels = { open = open }
	function panels.addFind(name, story)
		if found[name] then
			return
		end
		found[name] = true
		empty.Visible = false
		local n = 0
		for _ in pairs(found) do
			n += 1
		end
		Ui.paragraph("You found " .. name .. ". " .. story, { LayoutOrder = n + 1, TextColor3 = Ui.colors.blue, Parent = findsBody })
	end
	return panels
end

return Panels

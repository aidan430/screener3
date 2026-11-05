-- The teleporter menu: standing on one of your pads, pick any of your other pads (listed by
-- how high up they are). The server checks you're on a pad and moves you.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Ui = require(script.Parent.Ui)
local Cursor = require(script.Parent.Cursor)

local player = Players.LocalPlayer
local Teleport = {}
local window, body

local function close()
	if window then
		window.Visible = false
	end
	Cursor.need("teleport", false)
end

function Teleport.mount(gui)
	window, body = Ui.window(gui, "Teleport", function()
		Cursor.need("teleport", false)
	end)
	window.Size = UDim2.fromOffset(420, 420)
end

-- Opens the menu for the pad `from` (a Model on your plot).
function Teleport.open(from)
	if not window then
		return
	end
	for _, child in ipairs(body:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local plot = player:GetAttribute("Plot")
	local plots = workspace:FindFirstChild("Plots")
	local built = plot and plots and plots:FindFirstChild("Plot" .. plot) and plots["Plot" .. plot]:FindFirstChild("Built")
	local pads = {}
	for _, model in ipairs(built and built:GetChildren() or {}) do
		if model:IsA("Model") and model:GetAttribute("Item") == "teleporter" and model ~= from then
			table.insert(pads, model)
		end
	end
	table.sort(pads, function(a, b)
		return a:GetPivot().Position.Y < b:GetPivot().Position.Y
	end)
	if #pads == 0 then
		Ui.paragraph("This is your only pad. Buy another Teleporter Pad (Q, Build) and put it somewhere else, like high up on a platform.", { LayoutOrder = 1, Parent = body })
	end
	for i, pad in ipairs(pads) do
		local height = math.floor(pad:GetPivot().Position.Y + 0.5)
		local name = if height <= 3 then "On the ground" else height .. " studs up"
		Ui.button("Pad " .. i .. ":  " .. name, Ui.colors.blue, { LayoutOrder = i, Size = UDim2.new(1, 0, 0, 48), Parent = body }).Activated:Connect(function()
			Remotes.Teleport:FireServer(pad)
			close()
		end)
	end
	window.Visible = true
	Cursor.need("teleport", true)
end

return Teleport

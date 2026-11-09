-- A picture of each tool on its Shop row, cut from the owner's tool sheet (Config.ToolSheet): the
-- whole sheet sits inside a small clipped square, moved and sized so only that tool shows. It
-- works whatever size Roblox stores the image at, because it's all in shares of the sheet.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Ui = require(script.Parent.Ui)

local ToolPics = {}

-- Adds the picture for tool `level` to the left of a Shop row, nudging the row's words right.
function ToolPics.add(row, level)
	local sheet = Config.ToolSheet
	local cell = sheet and sheet.image ~= "" and sheet.cells[level]
	if not cell then
		return
	end
	for _, child in ipairs(row:GetChildren()) do
		if child:IsA("TextLabel") then
			child.Position += UDim2.fromOffset(62, 0)
			child.Size -= UDim2.fromOffset(62, 0)
		end
	end
	local clip = Ui.make("Frame", { Size = UDim2.fromOffset(56, 56), Position = UDim2.fromOffset(6, 4), BackgroundColor3 = Color3.fromRGB(236, 236, 238), ClipsDescendants = true, Parent = row }, { Ui.corner(6) })
	Ui.make("ImageLabel", {
		Image = sheet.image,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1 / cell[3], 1 / cell[4]),
		Position = UDim2.fromScale(-cell[1] / cell[3], -cell[2] / cell[4]),
		Parent = clip,
	})
end

return ToolPics

-- First person locks the mouse to the centre of the screen. Menus need a pointer, so a
-- hidden "modal" button frees the mouse while a menu is open or while you hold M.
local UserInputService = game:GetService("UserInputService")

local Ui = require(script.Parent.Ui)

local Cursor = {}
local modal = nil
local reasons = {}

local function apply()
	local free = false
	for _, on in pairs(reasons) do
		free = free or on
	end
	if modal then
		modal.Visible = free
	end
	UserInputService.MouseIconEnabled = free
end

function Cursor.mount(gui)
	modal = Ui.make("TextButton", { Name = "FreeMouse", Text = "", BackgroundTransparency = 1, Size = UDim2.fromOffset(1, 1), Modal = true, Visible = false, Parent = gui })
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.M then
			reasons.key = not reasons.key
			apply()
		end
	end)
	apply()
end

-- Something (a window, build mode) wants the mouse free (true) or no longer needs it (false).
function Cursor.need(reason, on)
	reasons[reason] = on
	apply()
end

function Cursor.isFree()
	return modal ~= nil and modal.Visible
end

return Cursor

-- First person locks the mouse to the centre of the screen. Menus need a pointer, so a
-- hidden "modal" button frees the mouse while a menu is open or while you hold M. Touch
-- screens have no mouse to free (taps reach buttons anyway), so there it stays hidden.
local UserInputService = game:GetService("UserInputService")

local Ui = require(script.Parent.Ui)

local Cursor = {}
local modal = nil
local reasons = {}
local free = false

local function apply()
	free = false
	for _, on in pairs(reasons) do
		free = free or on
	end
	local touch = Ui.touch()
	if modal then
		modal.Visible = free and not touch
	end
	UserInputService.MouseIconEnabled = free and not touch
end

function Cursor.mount(gui)
	modal = Ui.make("TextButton", { Name = "FreeMouse", Text = "", BackgroundTransparency = 1, Size = UDim2.fromOffset(1, 1), Modal = true, Visible = false, Parent = gui })
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.M then
			reasons.key = not reasons.key
			apply()
		end
	end)
	Ui.onLayout(apply) -- switching between touch and mouse
end

-- Something (a window, build mode) wants the mouse free (true) or no longer needs it (false).
function Cursor.need(reason, on)
	reasons[reason] = on
	apply()
end

function Cursor.isFree()
	return free
end

return Cursor

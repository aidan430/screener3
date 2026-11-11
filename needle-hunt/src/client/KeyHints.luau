-- What each key does, for players on a keyboard: a small guide low on the left, above the Show off
-- and Leave buttons (H hides or shows it), and X or Backspace closes any open window
-- (client/UIController.closeAll).
-- Phones and controllers don't get the guide: they have on-screen buttons.
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local UiKit = require(script.Parent.UiKit)

local KeyHints = {}

local KEYS = {
	{ "Click", "Poke with your needle" },
	{ "Hold click", "Power Poke (2 hearts)" },
	{ "Hold R", "Thimble: block" },
	{ "Q", "Throw; Q again to catch it" },
	{ "C", "Dash" },
	{ "Ctrl or V", "Crouch; slide if running" },
	{ "Hold E", "Open a chest" },
	{ "F", "Inspect your needle" },
	{ "Space", "Jump" },
	{ "Mouse wheel", "Zoom in and out" },
	{ "X", "Close a menu" },
	{ "H", "Hide this guide" },
}

function KeyHints.start(gui, closeAll)
	ContextActionService:BindAction("CloseMenus", function(_, state)
		if state == Enum.UserInputState.Begin and closeAll() then
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.X, Enum.KeyCode.Backspace)
	if not UserInputService.KeyboardEnabled or UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
		return
	end
	local panel = UiKit.make("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 14, 1, -88), Size = UDim2.fromOffset(250, 14 + #KEYS * 24), BackgroundColor3 = UiKit.colors.panel, BackgroundTransparency = 0.3, Parent = gui }, {
		UiKit.corner(10), UiKit.pad(8), UiKit.make("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	UiKit.autoScale(panel)
	for i, row in ipairs(KEYS) do
		local line = UiKit.make("Frame", { LayoutOrder = i, Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Parent = panel })
		UiKit.label({ Text = row[1], Font = UiKit.bold, Size = UDim2.fromOffset(92, 22), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UiKit.colors.gold, Parent = line }, 15)
		UiKit.label({ Text = row[2], Size = UDim2.new(1, -96, 0, 22), Position = UDim2.fromOffset(96, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = line }, 15)
	end
	ContextActionService:BindAction("ToggleKeyHints", function(_, state)
		if state == Enum.UserInputState.Begin then
			panel.Visible = not panel.Visible
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.H)
end

return KeyHints

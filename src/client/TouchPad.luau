-- The action pad on touch screens: the keyboard's shortcuts (shop, build, drop, home, tool,
-- detector, jetpack) as big buttons in a tidy grid on the right, just above Roblox's jump
-- button, clear of the thumbstick (bottom left). Only shown while a touch screen is in use.
-- Hidden while a menu is open. Other parts add their own buttons with TouchPad.add; build
-- mode shows its own set.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Ui = require(script.Parent.Ui)
local Cursor = require(script.Parent.Cursor)

local player = Players.LocalPlayer
local cfg = Config.Touch
local TouchPad = {}
TouchPad.isBuilding = function()
	return false
end

local pad, scale, screen = nil, nil, nil
local entries = {} -- { button, show, build }
local camera = workspace.CurrentCamera

-- The jump button's top and right edges, in pixels inside our ScreenGui: Roblox's TouchGui
-- when it's there (measured against our ScreenGui, so the top bar and a phone's notch don't
-- matter), else where the default touch controls put it.
local function jumpEdges()
	local size = screen.AbsoluteSize
	local small = math.min(size.X, size.Y) <= 500
	local top, right = size.Y - (if small then 90 else 210), size.X - (if small then 25 else 50)
	local touchGui = player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("TouchGui")
	local frame = touchGui and touchGui:FindFirstChild("TouchControlFrame")
	local jump = frame and frame:FindFirstChild("JumpButton")
	if jump and jump:IsA("GuiObject") and jump.Visible and jump.AbsoluteSize.Y > 0 then
		local origin = screen.AbsolutePosition
		top = jump.AbsolutePosition.Y - origin.Y
		right = jump.AbsolutePosition.X + jump.AbsoluteSize.X - origin.X
	end
	return top, right
end

-- True if a touch at `position` (an InputObject's Position, below Roblox's top bar) started
-- where the thumbstick lives: the bottom-left of the screen.
function TouchPad.onStick(position)
	local view = camera.ViewportSize
	local y = position.Y + Ui.topInset()
	return position.X < view.X * cfg.stickArea[1] and y > view.Y * cfg.stickArea[2]
end

local function place()
	if not pad then
		return
	end
	local top, right = jumpEdges()
	local w, h, rows = cfg.padButton[1], cfg.padButton[2], 3
	local fullW = cfg.padColumns * w + (cfg.padColumns - 1) * cfg.padGap
	local fullH = rows * h + (rows - 1) * cfg.padGap
	-- the room between the order card (top right, under the music button) and the jump button
	local room = top - 8 - (56 + 86 * Ui.screenScale() + 10)
	scale.Scale = math.clamp(room / fullH, 0.6, 1.2)
	pad.Size = UDim2.fromOffset(fullW, fullH)
	pad.Position = UDim2.fromOffset(right, top - 8)
end

-- The pad's width on screen in pixels (build mode keeps its item bar clear of it).
function TouchPad.width()
	return if pad and scale then pad.Size.X.Offset * scale.Scale else 0
end

function TouchPad.mount(gui)
	screen = gui
	pad = Ui.make("Frame", { Name = "TouchPad", AnchorPoint = Vector2.new(1, 1), BackgroundTransparency = 1, Visible = false, Parent = gui }, {
		Ui.make("UIGridLayout", {
			CellSize = UDim2.fromOffset(cfg.padButton[1], cfg.padButton[2]),
			CellPadding = UDim2.fromOffset(cfg.padGap, cfg.padGap),
			StartCorner = Enum.StartCorner.BottomRight,
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	scale = Ui.make("UIScale", { Parent = pad })
	Ui.onLayout(place)
	task.spawn(function()
		while true do
			local touch = Ui.touch()
			pad.Visible = touch and not Cursor.isFree() -- a menu open has the screen to itself
			if touch then
				place() -- the jump button can move (or appear late)
				local building = TouchPad.isBuilding()
				for _, e in ipairs(entries) do
					e.button.Visible = (e.build == building) and (e.show == nil or e.show())
				end
			end
			task.wait(0.25)
		end
	end)
end

-- Adds a button. spec: order (1 sits next to the thumb, bottom right), text, colour, and
-- either tap() or down()/up() for a button you hold; show() decides when it appears;
-- build = true puts it in build mode's set instead of the normal one.
function TouchPad.add(spec)
	if not pad then
		return nil
	end
	local button = Ui.button(spec.text, spec.colour or Ui.colors.wood, { Name = spec.text, LayoutOrder = spec.order, Visible = false, Parent = pad })
	if spec.tap then
		button.Activated:Connect(spec.tap)
	end
	if spec.down then
		-- held: follow this one touch until it lifts, even if the finger slides off the button
		local holding = nil
		local function release(input)
			if holding and input == holding then
				holding = nil
				spec.up()
			end
		end
		button.InputBegan:Connect(function(input)
			if holding == nil and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
				holding = input
				spec.down()
			end
		end)
		button.InputEnded:Connect(release)
		UserInputService.InputEnded:Connect(release)
		button:GetPropertyChangedSignal("Visible"):Connect(function()
			if not button.Visible and holding then
				holding = nil
				spec.up()
			end
		end)
	end
	table.insert(entries, { button = button, show = spec.show, build = spec.build == true })
	return button
end

return TouchPad

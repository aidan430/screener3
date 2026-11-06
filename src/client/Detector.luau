-- The metal detector: hold Config.MetalDetector.key to sweep. The client only says "I'm
-- detecting" (Remotes.Detect); the server answers a coarse signal, 0 to `levels`. Higher
-- signal: faster, higher beeps, more meter bars lit and a soft pulse. Calm, no flashing.
-- Touch screens hold the DETECT button on the action pad instead.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Ui = require(script.Parent.Ui)
local Juice = require(script.Parent.Juice)
local TouchPad = require(script.Parent.TouchPad)

local player = Players.LocalPlayer
local Detector = {}
local cfg = Config.MetalDetector

local LIT = Color3.fromRGB(120, 220, 160)
local DIM = Color3.fromRGB(60, 70, 66)

function Detector.start(gui, notify)
	local holding, signal, lastHint = false, 0, -10
	local meter = Ui.make("Frame", { Name = "Detector", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -110), Size = UDim2.fromOffset(200, 54), BackgroundColor3 = Ui.colors.woodDark, BackgroundTransparency = 1, Parent = gui }, { Ui.corner(10) })
	local title = Ui.label({ Text = "METAL DETECTOR", Size = UDim2.new(1, 0, 0, 18), Position = UDim2.fromOffset(0, 4), TextTransparency = 1, TextStrokeTransparency = 1, Parent = meter }, 14)
	local scale = Ui.make("UIScale", { Parent = meter })
	local bars = {}
	for i = 1, cfg.levels do
		local width = 1 / cfg.levels
		bars[i] = Ui.make("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new((i - 1) * width, 6, 1, -6), Size = UDim2.new(width, -8, 0, 8 + i * 3), BackgroundColor3 = DIM, BackgroundTransparency = 1, BorderSizePixel = 0, Parent = meter }, { Ui.corner(3) })
	end

	local function show(on)
		Juice.ease(meter, 0.3, { BackgroundTransparency = if on then 0.35 else 1 })
		Juice.ease(title, 0.3, { TextTransparency = if on then 0 else 1, TextStrokeTransparency = if on then 0.5 else 1 })
		for _, bar in ipairs(bars) do
			Juice.ease(bar, 0.3, { BackgroundTransparency = if on then 0.1 else 1 })
		end
	end

	local function paint()
		for i, bar in ipairs(bars) do
			Juice.ease(bar, 0.2, { BackgroundColor3 = if i <= signal then LIT else DIM })
		end
	end

	-- ask the server while the key is held (about 4 times a second)
	local sweeping = 0
	local function sweep()
		sweeping += 1
		local mine = sweeping -- a quick release and press again starts a new sweep; the old one stops
		while holding and mine == sweeping do
			local ok, answer = pcall(Remotes.Detect.InvokeServer, Remotes.Detect)
			if ok and type(answer) == "number" then
				signal = math.clamp(math.floor(answer), 0, cfg.levels)
				paint()
			end
			task.wait(cfg.pollSeconds)
		end
		signal = 0
		paint()
	end

	-- beep: faster and higher the stronger the signal; silent at 0
	task.spawn(function()
		while true do
			if holding and signal > 0 then
				Juice.sound("detector", 0.8 + signal * 0.15)
				scale.Scale = 1.06
				Juice.ease(scale, 0.25, { Scale = 1 })
				task.wait(cfg.beep[signal] or 1)
			else
				task.wait(0.1)
			end
		end
	end)

	local function begin()
		if holding then
			return
		end
		if player:GetAttribute("Detector") ~= true then
			if time() - lastHint > 4 and notify then
				lastHint = time()
				notify.toast("A metal detector beeps near the needle. Find it in the shop, under Fitness.", Ui.colors.wood)
			end
			return
		end
		holding = true
		show(true)
		task.spawn(sweep)
	end
	local function finish()
		if holding then
			holding = false
			show(false)
		end
	end

	local key = Enum.KeyCode[cfg.key]
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == key then
			begin()
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == key then
			finish()
		end
	end)
	TouchPad.add({ order = 3, text = "DETECT", colour = Color3.fromRGB(70, 150, 140), down = begin, up = finish, show = function()
		return player:GetAttribute("Detector") == true
	end })
end

return Detector

-- The player's side of the game: first-person harvesting, building, the menus, and all the
-- feedback that makes it feel good. The server decides everything that matters.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Ui = require(script.Parent:WaitForChild("Ui"))
local Notify = require(script.Parent:WaitForChild("Notify"))
local Cursor = require(script.Parent:WaitForChild("Cursor"))
local Juice = require(script.Parent:WaitForChild("Juice"))
local Hud = require(script.Parent:WaitForChild("Hud"))
local Panels = require(script.Parent:WaitForChild("Panels"))
local Harvest = require(script.Parent:WaitForChild("Harvest"))
local BuildMode = require(script.Parent:WaitForChild("BuildMode"))
local WorldFx = require(script.Parent:WaitForChild("WorldFx"))
local HayFx = require(script.Parent:WaitForChild("HayFx"))
local Teleport = require(script.Parent:WaitForChild("Teleport"))
local Guide = require(script.Parent:WaitForChild("Guide"))
local OrderCard = require(script.Parent:WaitForChild("OrderCard"))
local Music = require(script.Parent:WaitForChild("Music"))
local Jetpack = require(script.Parent:WaitForChild("Jetpack"))
local Offer = require(script.Parent:WaitForChild("Offer"))
local Animals = require(script.Parent:WaitForChild("Animals"))
local Goals = require(script.Parent:WaitForChild("Goals"))
local StaminaBar = require(script.Parent:WaitForChild("Stamina"))
local Detector = require(script.Parent:WaitForChild("Detector"))
local TouchPad = require(script.Parent:WaitForChild("TouchPad"))
local TouchAim = require(script.Parent:WaitForChild("TouchAim"))
local Controls = require(script.Parent:WaitForChild("Controls"))

local player = Players.LocalPlayer
local gui = Ui.make("ScreenGui", { Name = "HaystackUi", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = player:WaitForChild("PlayerGui") })
pcall(function() -- under the top bar like before, but clear of a phone's notch and rounded corners
	gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
end)

-- Errors show on screen (red, top right) so a broken part can be reported without the
-- Output window. Each part starts on its own, so one failing can't stop harvesting.
local errorBox = Ui.label({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 60), Size = UDim2.fromOffset(420, 160), TextColor3 = Color3.fromRGB(255, 90, 80), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Font = Enum.Font.Code, Parent = gui }, 14)
local function report(text)
	errorBox.Text = string.sub(errorBox.Text .. "\n" .. text, -900)
end
game:GetService("ScriptContext").Error:Connect(function(message, trace)
	report("ERROR: " .. tostring(message) .. "\n" .. string.sub(tostring(trace), 1, 200))
end)
local function step(name, fn)
	local ok, err = pcall(fn)
	if not ok then
		report("ERROR starting " .. name .. ": " .. tostring(err))
	end
end

local panels, hud
step("messages", function()
	Notify.mount(gui)
end)
step("touch pad", function()
	TouchPad.mount(gui) -- before the parts that add buttons to it
end)
step("your haystack", function() require(script.Parent:WaitForChild("PileView")).start(); require(script.Parent:WaitForChild("OnlyMine")).start() end)
step("harvesting", function()
	Harvest.onMiss = function(text)
		Notify.toast(text, Ui.colors.wood)
	end
	Harvest.start()
end)
step("mouse", function()
	Cursor.mount(gui)
end)
step("HUD", function()
	hud = Hud.mount(gui, function(name)
		if panels then
			panels.open(name)
		end
	end)
end)
step("effects", function()
	Juice.mount(gui, hud and hud.coins)
end)
step("building", function()
	BuildMode.mount(gui, Notify)
	Harvest.isBuilding = BuildMode.active
	TouchPad.isBuilding = BuildMode.active
end)
step("menus", function()
	panels = Panels.mount(gui, Notify, {
		Build = function()
			BuildMode.toggle()
		end,
		Whistle = function()
			local ok, success, message = pcall(Remotes.Whistle.InvokeServer, Remotes.Whistle)
			Notify.toast(if ok then tostring(message) else "Try again.", if ok and success then Ui.colors.green else Ui.colors.red)
		end,
	})
end)
step("world effects", function()
	WorldFx.start()
end)
step("guide", function()
	Guide.start()
end)
step("orders", function()
	OrderCard.mount(gui)
	OrderCard.hidden = BuildMode.active -- out of the way of the build buttons
end)
step("teleporters", function()
	Teleport.mount(gui)
end)
step("music", function()
	Music.start(gui)
end)
step("jetpack", function()
	Jetpack.start(gui, Notify)
end)
step("offers", function()
	Offer.start(gui)
end)
step("animals", function()
	Animals.start()
end)
step("goals", function()
	Goals.start(gui, hud, Notify)
end)
step("stamina", function()
	StaminaBar.mount(gui)
end)
step("metal detector", function()
	Detector.start(gui, Notify)
end)
step("controls", function()
	Controls.start(function(name)
		if panels then
			panels.open(name)
		end
	end)
	TouchAim.start() -- touch screens: tap or hold still to harvest
end)
step("worlds", function() require(script.Parent:WaitForChild("Worlds")).start(gui, Notify) end)
if not hud then
	hud = { refresh = function() end }
end

-- What the server said about your last click, just under the crosshair. If a click gets no
-- answer at all, say so: that means the server's harvesting isn't running (see Output).
local statusLabel = Ui.label({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.5, 26), Size = UDim2.fromOffset(520, 26), TextTransparency = 1, TextStrokeTransparency = 1, Parent = gui }, 18)
local statusToken, lastAnswer = 0, 0
local function showStatus(text, colour)
	statusToken += 1
	local token = statusToken
	statusLabel.Text = text
	statusLabel.TextColor3 = colour or Ui.colors.cream
	statusLabel.TextTransparency, statusLabel.TextStrokeTransparency = 0, 0.4
	task.delay(2.5, function()
		if token == statusToken then
			Juice.ease(statusLabel, 0.5, { TextTransparency = 1, TextStrokeTransparency = 1 })
		end
	end)
end
player:GetAttributeChangedSignal("HarvestTick"):Connect(function()
	lastAnswer = time()
	showStatus(tostring(player:GetAttribute("HarvestStatus") or ""))
end)
task.spawn(function()
	while true do
		task.wait(0.5)
		local fired = Harvest.lastFired or 0
		if fired > lastAnswer and time() - fired > 2 then
			lastAnswer = time()
			showStatus("The server didn't answer your click. Look for red text in the Output window.", Color3.fromRGB(255, 120, 100))
		end
	end
end)

-- what the crosshair is on, whether you're in the loft (HUD state, not attributes)
task.spawn(function()
	while true do
		task.wait(0.1)
		Hud.state.targeting = Harvest.target() ~= nil
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local inLoft = root ~= nil and root.Position.Y > 300
		if Hud.state.inLoft ~= inLoft then
			Hud.state.inLoft = inLoft
			hud.refresh()
		end
	end
end)

-- milestones: every 1% of the pile, and every 100 clumps, a little celebration
local lastClumps = player:GetAttribute("ClumpsLeft")
player:GetAttributeChangedSignal("ClumpsLeft"):Connect(function()
	local now = player:GetAttribute("ClumpsLeft") or Config.Clumps
	if lastClumps and now < lastClumps then
		local done = Config.Clumps - now
		local before = Config.Clumps - lastClumps
		if done // 100 > before // 100 then -- passed a hundred, even if machines took several at once
			done = done // 100 * 100
			Juice.confetti()
			Notify.banner(done .. " CLUMPS HARVESTED!", math.floor(done / Config.Clumps * 100) .. "% of your pile. The needle is in one of the " .. Format.commas(now) .. " left.", 5)
		elseif done // 10 > before // 10 then
			Notify.toast(done // 10 * 10 .. " clumps cleared!", Ui.colors.wood)
		end
	end
	lastClumps = now
end)

Remotes.SearchFx.OnClientEvent:Connect(function(message)
	if message.kind == "harvest" then
		Juice.hit()
		HayFx.lift(message.position, message.golden)
		Juice.float(message.position + Vector3.new(0, 2, 0), "+" .. message.straws, if message.golden then Ui.colors.hay else Ui.colors.cream)
		if message.gone then -- you cleared a clump: it pops
			Juice.pop(message.position, message.golden)
		end
		if message.warmth then
			Hud.state.warmth = message.warmth
			hud.refresh()
		end
		if message.full then
			Notify.toast("You're full! Dump your hay in your trader's basket.", Ui.colors.red)
		end
	elseif message.kind == "nope" then
		Notify.toast(message.reason, Ui.colors.wood)
	elseif message.kind == "full" then
		Notify.toast("You're full! Dump your hay in your trader's basket (or buy a bucket).", Ui.colors.red)
	elseif message.kind == "dumped" then
		HayFx.dump(message.basket, message.straws, message.reason ~= "bale" and message.reason ~= "belt")
		if message.quiet then
			return -- belt deliveries: the basket fills, no message (the HUD shows the basket)
		end
		if message.coins > 0 then
			Juice.coins(message.coins) -- golden straw is paid for at once
		end
		local what = if message.reason == "bale" then "A bale of " elseif message.reason == "belt" then "The belt brought " else "Dumped "
		Notify.toast(what .. Format.commas(message.straws) .. " straw" .. (if message.reason == "auto" then " (Auto Sell)" else "") .. " into your basket. Your trader sells it as you go.", Ui.colors.green)
	elseif message.kind == "paid" then
		Juice.coins(message.coins)
	elseif message.kind == "order" then
		Juice.coins(message.coins)
		Juice.confetti()
		Notify.banner("DELIVERY ORDER COMPLETE!", message.text, 6)
	elseif message.kind == "find" then
		Juice.burst(message.position, 30, true)
		Juice.confetti()
		panels.addFind(message.name, message.story)
		Notify.banner("LUCKY FIND: " .. message.name, message.story .. "\nThe merchant pays " .. Format.short(message.coins) .. " coins for it.", 6)
	end
end)

Remotes.Announce.OnClientEvent:Connect(function(message)
	if message.kind == "needle" then
		if message.finderId == player.UserId then
			Juice.confetti()
			task.delay(0.6, Juice.confetti)
			Juice.punch(6)
			Notify.banner(if message.golden then "YOU FOUND THE GOLDEN NEEDLE!" else "YOU FOUND THE NEEDLE!",
				"You earned " .. Format.short(message.prize) .. " coins" .. (if message.golden then "." else " and +20% coins forever. A fresh pile with a new needle grows back in a moment."), 12)
		else
			Notify.toast(message.finder .. " found " .. (if message.golden then "a golden needle!" else "their needle!"), Ui.colors.hay)
		end
	elseif message.kind == "reveal" then
		WorldFx.reveal(message.clump)
		Juice.confetti()
		Notify.banner("THE NEEDLE IS REVEALED!", "Its clump glows gold on your pile. Climb up and harvest it!", 10)
	elseif message.kind == "wheel" then
		WorldFx.spin(message.index, #Config.Wheel)
		task.delay(4.3, function()
			Juice.confetti()
			Notify.banner("WHEEL OF FORTUNE: " .. message.name, message.text, 7)
		end)
	elseif message.kind == "loft" then
		if message.finderId ~= player.UserId then
			Notify.toast(message.finder .. " found the way into the Golden Loft!", Ui.colors.hay)
		end
	elseif message.kind == "notice" then
		Notify.toast(message.text, Ui.colors.wood)
	elseif message.kind == "error" then
		report(message.text)
	end
end)

Remotes.Achievement.OnClientEvent:Connect(function(a)
	Juice.confetti()
	Notify.banner("SECRET ACHIEVEMENT: " .. a.name, a.text .. "\n" .. a.done .. " of " .. a.total .. " discovered." .. (if a.done >= a.total then " A golden door in the hub is open!" else ""), 7)
end)

task.delay(3, function()
	Notify.banner(
		"Welcome to " .. Config.FarmName .. "!",
		"This is your farm. Your heap holds " .. Format.commas(Config.TotalStraws) .. " straws and one needle, hidden deep in the upper heap. "
			.. (if Ui.touch() then "Aim the dot at the heap and tap (or hold) to lift hay onto your fork, then dump it in your trader's basket (tap its button). SHOP and BUILD are on the right."
				else "Aim at the heap and click to lift hay onto your fork, then dump it in your trader's basket (E). Buy tools, buckets, stairs, lifts and machines (Q) and build them (B)."),
		12
	)
end)

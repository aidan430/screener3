-- The player's side of the game: first-person harvesting, building, the menus, and all the
-- feedback that makes it feel good. The server decides everything that matters.
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

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

local player = Players.LocalPlayer
local gui = Ui.make("ScreenGui", { Name = "HaystackUi", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = player:WaitForChild("PlayerGui") })

Cursor.mount(gui)
Notify.mount(gui)
local panels
local hud = Hud.mount(gui, function(name)
	panels.open(name)
end)
Juice.mount(gui, hud.coins)
BuildMode.mount(gui, Notify)
panels = Panels.mount(gui, Notify, {
	Build = function()
		BuildMode.toggle()
	end,
	Whistle = function()
		local ok, message = pcall(Remotes.Whistle.InvokeServer, Remotes.Whistle)
		Notify.toast(if ok then message else "Try again.", Ui.colors.green)
	end,
})
Harvest.start()
WorldFx.start()

UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.Q then
		panels.open("Shop")
	end
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt)
	if prompt:GetAttribute("Action") == "wheel" then
		panels.open("Wheel")
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
		if done % 100 == 0 then
			Juice.confetti()
			Notify.banner(done .. " CLUMPS HARVESTED!", math.floor(done / Config.Clumps * 100) .. "% of your pile. The needle is in one of the " .. Format.commas(now) .. " left.", 5)
		elseif done % 10 == 0 then
			Notify.toast(done .. " clumps harvested!", Ui.colors.wood)
		end
	end
	lastClumps = now
end)

Remotes.SearchFx.OnClientEvent:Connect(function(message)
	if message.kind == "harvest" then
		Juice.float(message.position + Vector3.new(0, 2, 0), "+" .. message.straws, if message.golden then Ui.colors.hay else Ui.colors.cream)
		if message.gone then -- you cleared a clump: it pops
			Juice.pop(message.position, message.golden)
		end
		if message.warmth then
			Hud.state.warmth = message.warmth
			hud.refresh()
		end
		if message.full then
			Notify.toast("Your tool is full! Sell at the merchant in the hub.", Ui.colors.red)
		end
	elseif message.kind == "full" then
		Notify.toast("Your tool is full! Sell at the merchant (or buy a bigger tool).", Ui.colors.red)
	elseif message.kind == "sold" then
		Juice.coins(message.coins)
		Notify.toast("Sold " .. Format.commas(message.straws) .. " straw for " .. Format.short(message.coins) .. " coins" .. (if message.reason == "auto" then " (Auto Sell)" else ""), Ui.colors.green)
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
	elseif message.kind == "notice" then
		Notify.toast(message.text, Ui.colors.wood)
	end
end)

Remotes.Achievement.OnClientEvent:Connect(function(a)
	Juice.confetti()
	Notify.banner("SECRET ACHIEVEMENT: " .. a.name, a.text .. "\n" .. a.done .. " of " .. a.total .. " discovered." .. (if a.done >= a.total then " A golden door in the hub is open!" else ""), 7)
end)

task.delay(3, function()
	Notify.banner(
		"Welcome to " .. Config.FarmName .. "!",
		"This is your farm. Your pile holds " .. Format.commas(Config.TotalStraws) .. " straws and one needle. Look at a clump and click to harvest. "
			.. "Sell at the merchant in the hub, buy tools, stairs, lifts, machines and generators (Q), and build them on your farm (B).",
		12
	)
end)

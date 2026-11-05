-- The player's side of the game: builds the UI, listens to the farm, turns clicks with your
-- fork into searches, and offers SELL at the merchant and the climb into the Golden Loft.
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Ui = require(script.Parent:WaitForChild("Ui"))
local Notify = require(script.Parent:WaitForChild("Notify"))
local Hud = require(script.Parent:WaitForChild("Hud"))
local Panels = require(script.Parent:WaitForChild("Panels"))
local WorldFx = require(script.Parent:WaitForChild("WorldFx"))

local player = Players.LocalPlayer
local gui = Ui.make("ScreenGui", { Name = "HaystackUi", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = player:WaitForChild("PlayerGui") })

Notify.mount(gui)
local panels = Panels.mount(gui, Notify)
Hud.mount(gui, panels.open)
WorldFx.start()

local function ask(remote, ...)
	local ok, success, message = pcall(remote.InvokeServer, remote, ...)
	if not ok then
		return false, "The farm didn't answer. Try again."
	end
	return success, message
end

-- The action button at the bottom: SELL at the merchant, CLIMB at the loft hatch, whistle anywhere.
local action = Ui.button("", Ui.colors.green, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -100), Size = UDim2.fromOffset(300, 54), Visible = false, Parent = gui })
Ui.autoScale(action)
local actionKind = nil
action.Activated:Connect(function()
	if actionKind == "sell" then
		local ok, message = ask(Remotes.Sell)
		Notify.toast(message, ok and Ui.colors.green or Ui.colors.red)
	elseif actionKind == "loft" then
		local ok, message = ask(Remotes.Loft, "up")
		Notify.toast(message, ok and Ui.colors.purple or Ui.colors.red)
	elseif actionKind == "down" then
		local _, message = ask(Remotes.Loft, "down")
		Notify.toast(message, Ui.colors.wood)
	elseif actionKind == "whistle" then
		local ok, message = ask(Remotes.Whistle)
		Notify.toast(message, ok and Ui.colors.green or Ui.colors.red)
	end
end)

local MERCHANT, BARN, LOFT_PAD = Vector3.new(74, 0, 10), Vector3.new(0, 0, 96), Vector3.new(0, 130, 132)
local function flat(a, b)
	return (Vector3.new(a.X, 0, a.Z) - Vector3.new(b.X, 0, b.Z)).Magnitude
end
task.spawn(function()
	while true do
		task.wait(0.25)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local kind, text, colour = nil, "", Ui.colors.green
		if root then
			local inLoft = root.Position.Y > 100
			player:SetAttribute("InLoft", inLoft)
			local carried = (player:GetAttribute("BagStraw") or 0) + (player:GetAttribute("BagGolden") or 0)
			if not inLoft and flat(root.Position, MERCHANT) <= Config.MerchantRange then
				kind, text = "sell", "SELL " .. Format.commas(carried) .. " STRAW"
			elseif not inLoft and flat(root.Position, BARN + Vector3.new(0, 0, -14)) <= 9 and root.Position.Z < BARN.Z then
				kind, text, colour = "loft", (if player:GetAttribute("LoftOpen") then "CLIMB INTO THE GOLDEN LOFT" else "LOFT LOCKED: 10 ACHIEVEMENTS"), Ui.colors.purple
			elseif inLoft and flat(root.Position, LOFT_PAD) <= 6 then
				kind, text, colour = "down", "GO BACK DOWN", Ui.colors.wood
			elseif (player:GetAttribute("Whistles") or 0) > 0 and carried > 0 then
				kind, text, colour = "whistle", "WHISTLE: SELL HERE (" .. player:GetAttribute("Whistles") .. " left)", Ui.colors.blue
			end
		end
		actionKind = kind
		action.Visible = kind ~= nil
		action.Text, action.BackgroundColor3 = text, colour
	end
end)

Remotes.SearchFx.OnClientEvent:Connect(function(message)
	if message.kind == "search" then
		WorldFx.searched(message)
		if message.warmth then
			player:SetAttribute("Warmth", message.warmth)
		end
		if message.full then
			Notify.toast("Your bag is full! Sell it to the merchant.", Ui.colors.red)
		end
	elseif message.kind == "full" then
		Notify.toast("Your bag is full! Sell it to the merchant (or buy a bigger bag).", Ui.colors.red)
	elseif message.kind == "sold" then
		Notify.toast("Sold " .. Format.commas(message.straws) .. " straw for " .. Format.short(message.coins) .. " coins" .. (if message.reason == "auto" then " (Auto Sell)" else ""), Ui.colors.green)
	elseif message.kind == "find" then
		panels.addFind(message.name, message.story)
		Notify.banner("LUCKY FIND: " .. message.name, message.story .. "\nThe merchant pays " .. Format.short(message.coins) .. " coins for it.", 6)
	end
end)

Remotes.Announce.OnClientEvent:Connect(function(message)
	if message.kind == "needle" then
		local me = message.finderId == player.UserId
		if me then
			WorldFx.celebrate(message.golden)
			Notify.banner(if message.golden then "YOU FOUND THE GOLDEN NEEDLE!" else "YOU FOUND THE NEEDLE!",
				"You earned " .. Format.short(message.prize) .. " coins" .. (if message.golden then "." else " and +20% coins forever. A new needle is now hidden in a fresh haystack."), 12)
		else
			Notify.toast(message.finder .. " found " .. (if message.golden then "a golden needle!" else "their needle!"), Ui.colors.hay)
		end
	elseif message.kind == "loft" then
		Notify.toast(message.finder .. " unlocked the Golden Loft!", Ui.colors.purple)
	elseif message.kind == "notice" then
		Notify.toast(message.text, Ui.colors.wood)
	end
end)

Remotes.Achievement.OnClientEvent:Connect(function(a)
	Notify.banner("ACHIEVEMENT: " .. a.name, a.text .. "\n" .. a.done .. " of " .. a.total .. " done." .. (if a.done >= a.total then " The Golden Loft is open!" else ""), 7)
end)

-- Clicking (or tapping) with your search tool asks the server to search.
local hooked = setmetatable({}, { __mode = "k" })
local lastSwing = 0
local function hookTool(tool)
	if hooked[tool] or not tool:IsA("Tool") or tool:GetAttribute("Level") == nil then
		return
	end
	hooked[tool] = true
	tool.Activated:Connect(function()
		Remotes.Search:FireServer()
		if os.clock() - lastSwing > 0.35 then
			lastSwing = os.clock()
			local swing = Instance.new("StringValue") -- the default Animate script plays a swing for this
			swing.Name = "toolanim"
			swing.Value = "Slash"
			swing.Parent = tool
			Debris:AddItem(swing, 0.5)
		end
	end)
end

local backpackConnection = nil
local function onCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")
	local backpack = player:WaitForChild("Backpack")
	local equipped = false
	local function arrive(tool)
		hookTool(tool)
		if not equipped and tool:IsA("Tool") and tool:GetAttribute("Level") ~= nil then
			equipped = true
			task.defer(function()
				if humanoid.Parent and tool.Parent == backpack then
					humanoid:EquipTool(tool)
				end
			end)
		end
	end
	if backpackConnection then
		backpackConnection:Disconnect()
	end
	backpackConnection = backpack.ChildAdded:Connect(arrive)
	for _, tool in ipairs(backpack:GetChildren()) do
		arrive(tool)
	end
	character.ChildAdded:Connect(hookTool)
end
player.CharacterAdded:Connect(onCharacter)
if player.Character then
	task.spawn(onCharacter, player.Character)
end

task.delay(2, function()
	Notify.banner(
		"Welcome to " .. Config.FarmName .. "!",
		"A needle is hidden somewhere in " .. Format.commas(Config.TotalStraws) .. " straws. Walk to the haystack and click with your fork to search. "
			.. "Sell your straw to the merchant, buy better tools and machines, and finish all ten achievements to open the Golden Loft.",
		12
	)
end)

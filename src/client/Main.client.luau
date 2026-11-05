-- The player's side of the game: builds the UI, listens to the farm, and turns clicks with
-- your fork into searches (the server decides what each search finds).
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
local gameState = ReplicatedStorage:WaitForChild("GameState")

local gui = Ui.make("ScreenGui", { Name = "HaystackUi", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = player:WaitForChild("PlayerGui") })
local state = { case = 0, clues = {} }

Notify.mount(gui)
local panels = Panels.mount(gui, state, Notify)
local hud = Hud.mount(gui, panels.open)
WorldFx.start()

local function cluesChanged()
	hud.setClues(#state.clues, gameState:GetAttribute("ClueCount") or 0)
	panels.refresh()
	WorldFx.setClues(state.clues, gameState:GetAttribute("Phase") == "solved")
end

Remotes.Clue.OnClientEvent:Connect(function(clue)
	if clue.case ~= state.case then
		state.case, state.clues = clue.case, {}
	end
	state.clues[clue.index] = clue
	Notify.toast("NEW CLUE " .. clue.index .. "/" .. clue.count .. ": " .. clue.text, Ui.colors.blue)
	cluesChanged()
end)

Remotes.Announce.OnClientEvent:Connect(function(message)
	if message.kind == "case" then
		state.case, state.clues = message.case, {}
		cluesChanged()
		Notify.banner("CASE #" .. message.case .. ": " .. message.title, message.intro .. "\n\nSearch any haystack. Every search can turn up a clue.", 9)
	elseif message.kind == "solved" then
		cluesChanged()
		WorldFx.celebrate(message.pileId)
		local who = if message.finderId == player.UserId then "You" else message.finder
		local prize = if message.finderId == player.UserId
			then "\nYou earned " .. Format.short(message.prize) .. " coins!"
			else "\nEveryone who searched this case earned a reward."
		Notify.banner(who .. " found the " .. message.needle .. "!", "It was in the " .. message.pile .. " haystack. " .. message.reveal .. prize .. "\nNext case in " .. message.nextIn .. " seconds.", 10)
	elseif message.kind == "notice" then
		Notify.toast(message.text, Ui.colors.wood)
	end
end)

local lastBeep = 0
Remotes.SearchFx.OnClientEvent:Connect(function(message)
	WorldFx.searched(message)
	if message.detector and os.clock() - lastBeep > 6 then
		lastBeep = os.clock()
		Notify.toast("Your Needle Detector is beeping like crazy!", Ui.colors.green)
	end
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
		-- hold the fork straight away the first time it arrives after spawning
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

-- Catch up on the current case (and any clues found before this script started).
task.spawn(function()
	local ok, snapshot = pcall(function()
		return Remotes.GetState:InvokeServer()
	end)
	if ok and type(snapshot) == "table" and #state.clues == 0 then
		state.case, state.clues = snapshot.case, snapshot.clues
	end
	cluesChanged()
end)

task.delay(2, function()
	Notify.banner(
		"Welcome to " .. Config.FarmName .. "!",
		"A needle is hidden in one of " .. Format.commas(Config.TotalStraws) .. " straws. Walk up to a haystack and click or tap "
			.. "with your fork to search. Searching earns coins and clues, and the clues tell you which haystack hides the needle.",
		10
	)
end)

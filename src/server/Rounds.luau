-- Cases: each round hides one needle in one haystack, gives each player clues as they
-- search, and ends when someone's handful of straw contains the needle.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))(Config)
local Clues = require(Shared:WaitForChild("Clues"))
local Piles = require(Shared:WaitForChild("Piles"))
local Cases = require(Shared:WaitForChild("Cases"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameState = ReplicatedStorage:WaitForChild("GameState")

local Haystacks = require(script.Parent.Haystacks)
local PlayerData = require(script.Parent.PlayerData)
local World = require(script.Parent.World)

local Rounds = {}
local rng = Random.new()
local caseCount = 0
local current = nil -- { number, story, needle, clues, phase }
local found = {} -- [player] = clues found this case
local helpers = {} -- [player] = true once they have searched this case

local function pick(n)
	return rng:NextInteger(1, n)
end

local function clueMessage(index)
	local clue = current.clues[index]
	return { case = current.number, index = index, count = #current.clues, text = clue.text, possible = clue.possible }
end

local function startCase()
	caseCount += 1
	local story = Cases[(caseCount - 1) % #Cases + 1]
	local needle = Piles[rng:NextInteger(1, #Piles)]
	current = { number = caseCount, story = story, needle = needle, clues = Clues.generate(Piles, needle.id, pick), phase = "searching" }
	table.clear(found)
	table.clear(helpers)
	Haystacks.refill()
	gameState:SetAttribute("Case", caseCount)
	gameState:SetAttribute("CaseTitle", story.title)
	gameState:SetAttribute("CaseIntro", story.intro)
	gameState:SetAttribute("NeedleName", story.needle)
	gameState:SetAttribute("ClueCount", #current.clues)
	gameState:SetAttribute("Phase", "searching")
	World.setNotice(caseCount, story.title, story.intro)
	Remotes.Announce:FireAllClients({ kind = "case", case = caseCount, title = story.title, intro = story.intro })
end

-- Hands the player their next clue for this case. Returns false if there is none left.
function Rounds.giveClue(player)
	if not current or current.phase ~= "searching" then
		return false
	end
	local index = (found[player] or 0) + 1
	if index > #current.clues then
		return false
	end
	found[player] = index
	PlayerData.update(player, function(d)
		d.clues += 1
	end)
	Remotes.Clue:FireClient(player, clueMessage(index))
	return true
end

function Rounds.cluesFor(player)
	local list = {}
	if current then
		for index = 1, found[player] or 0 do
			table.insert(list, clueMessage(index))
		end
	end
	return list
end

function Rounds.needleId()
	return current and current.phase == "searching" and current.needle.id or nil
end

-- Called for every handful, before the straws are taken from the haystack.
-- Returns true if this handful holds the needle.
function Rounds.search(player, state, amount)
	if not current or current.phase ~= "searching" then
		return false
	end
	helpers[player] = true
	if state.pile.id == current.needle.id and rng:NextNumber() < Economy.needleChance(amount, state.remaining) then
		return true
	end
	if rng:NextNumber() < Config.ClueChance then
		Rounds.giveClue(player)
	end
	return false
end

local function reward(player, searches)
	local d = PlayerData.get(player)
	if not d then
		return 0
	end
	local coins = Economy.coinsFor(Economy.power(d.tool) * searches, PlayerData.multiplier(player))
	PlayerData.update(player, function(data)
		data.coins += coins
		data.solved += 1
	end)
	return coins
end

function Rounds.solve(finder, state)
	if not current or current.phase ~= "searching" then
		return
	end
	current.phase = "solved"
	gameState:SetAttribute("Phase", "solved")
	local story = current.story
	local reveal = string.gsub(story.reveal, "{pile}", state.pile.name)
	for player in pairs(helpers) do
		if player ~= finder and player.Parent then
			reward(player, Config.HelperRewardSearches)
		end
	end
	local prize = reward(finder, Config.FinderRewardSearches)
	PlayerData.update(finder, function(d)
		d.needles += 1
	end)
	Remotes.Announce:FireAllClients({
		kind = "solved",
		case = current.number,
		finder = finder.DisplayName,
		finderId = finder.UserId,
		needle = story.needle,
		pile = state.pile.name,
		pileId = state.pile.id,
		reveal = reveal,
		prize = prize,
		helperSearches = Config.HelperRewardSearches,
		nextIn = Config.SolvedPause,
	})
	task.delay(Config.SolvedPause, startCase)
end

function Rounds.init()
	Players.PlayerRemoving:Connect(function(player)
		found[player] = nil
		helpers[player] = nil
	end)
	Remotes.GetState.OnServerInvoke = function(player)
		return { case = current and current.number or 0, clues = Rounds.cluesFor(player) }
	end
	startCase()
end

return Rounds

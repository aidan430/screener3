-- A search: the player clicks with their tool next to a haystack; the server checks they
-- really are there, takes a handful of straws, pays coins and asks Rounds about the needle.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))(Config)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Haystacks = require(script.Parent.Haystacks)
local PlayerData = require(script.Parent.PlayerData)
local Rounds = require(script.Parent.Rounds)

local Search = {}
local lastSearch = {}

local function rootOf(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

local function holdingTool(player)
	local character = player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	return tool ~= nil and tool:GetAttribute("Level") ~= nil
end

function Search.perform(player)
	local data = PlayerData.get(player)
	local root = rootOf(player)
	if not data or not root then
		return
	end
	local state = Haystacks.nearest(root.Position)
	if not state then
		return
	end
	if state.remaining <= 0 then
		Remotes.SearchFx:FireClient(player, { pile = state.pile.id, straws = 0, coins = 0, empty = true })
		return
	end
	local amount = math.min(Economy.power(data.tool), state.remaining)
	local detector = data.tool >= Config.DetectorLevel and Rounds.needleId() == state.pile.id
	local hit = Rounds.search(player, state, amount)
	Haystacks.take(state, amount)
	local coins = Economy.coinsFor(amount, PlayerData.multiplier(player))
	PlayerData.update(player, function(d)
		d.coins += coins
		d.straws += amount
	end)
	Remotes.SearchFx:FireClient(player, { pile = state.pile.id, straws = amount, coins = coins, detector = detector })
	if hit then
		Rounds.solve(player, state)
	end
end

function Search.request(player)
	local now = os.clock()
	if now - (lastSearch[player] or 0) < Config.SearchCooldown then
		return
	end
	lastSearch[player] = now
	if holdingTool(player) then
		Search.perform(player)
	end
end

function Search.init()
	Remotes.Search.OnServerEvent:Connect(Search.request)
	Remotes.ToggleAuto.OnServerEvent:Connect(function(player, on)
		player:SetAttribute("AutoOn", on == true)
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastSearch[player] = nil
	end)
	-- the Auto Search pass searches by itself while you hold your tool next to a haystack
	task.spawn(function()
		while true do
			task.wait(Config.AutoSearchInterval)
			for _, player in ipairs(Players:GetPlayers()) do
				if player:GetAttribute("AutoOn") and PlayerData.hasPass(player, "AutoSearch") and holdingTool(player) then
					task.spawn(Search.perform, player)
				end
			end
		end
	end)
end

return Search

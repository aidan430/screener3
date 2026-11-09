-- Small requests from players, checked on the server: a hint (Remotes.Hint) and saving their
-- settings (Remotes.SaveSettings: only known settings, only true/false).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local DataManager = require(script.Parent.DataManager)
local ChestSpawner = require(script.Parent.ChestSpawner)
local RewardManager = require(script.Parent.RewardManager)
local RoundManager = require(script.Parent.RoundManager)

local Requests = {}

-- A hint: one free a day (two with the Extra Hint pass), only during a round you're in.
local function hint(player)
	local r = RoundManager.current()
	local d = DataManager.get(player)
	if not r or not d or not r.participants[player] or ReplicatedStorage:GetAttribute("Phase") ~= "search" then
		return nil, "Hints work during a round."
	end
	local today = math.floor(os.time() / 86400)
	local used = if d.hintsDay == today then d.hintsUsed else 0
	local allowed = Config.Hints.free + (if RewardManager.hasPass(player, "ExtraHint") then Config.Hints.pass else 0)
	if used >= allowed then
		return nil, "No hints left today. They come back tomorrow."
	end
	local text = ChestSpawner.hint(player)
	if not text then
		return nil, "Every chest is open!"
	end
	DataManager.update(player, function(data)
		data.hintsDay, data.hintsUsed = today, used + 1
	end)
	return text, nil
end

function Requests.init()
	Remotes.Hint.OnServerInvoke = hint
	Remotes.SaveSettings.OnServerEvent:Connect(function(player, settings)
		if type(settings) ~= "table" then
			return
		end
		DataManager.update(player, function(d)
			for key, value in pairs(settings) do
				if type(value) == "boolean" and d.settings[key] ~= nil then
					d.settings[key] = value
				end
			end
		end)
	end)
end

return Requests

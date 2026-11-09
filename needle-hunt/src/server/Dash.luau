-- Dashing (Config.Dash; the dash itself is client/DashFx, since each player's device moves its
-- own character). The server only rate-limits the announcement and passes it on, so everyone
-- sees a puff of dust where someone dashed. server/AntiCheat keeps checking speed as always.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Dash = {}
local last = {}

function Dash.init()
	Remotes.Dash.OnServerEvent:Connect(function(player)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not root or os.clock() - (last[player] or 0) < Config.Dash.cooldown * 0.8 then
			return
		end
		last[player] = os.clock()
		Remotes.Dash:FireAllClients(player.UserId, root.Position - Vector3.new(0, 2.5, 0))
	end)
	Players.PlayerRemoving:Connect(function(player)
		last[player] = nil
	end)
end

return Dash

-- The Hidden Straw: one golden straw tucked away somewhere on the farm (Config.SecretStraw).
-- Whoever touches it earns the secret achievement "Hidden Straw" (once each). It glows softly,
-- just enough to be spotted by someone who looks.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local PlayerData = require(script.Parent.PlayerData)
local Achievements = require(script.Parent.Achievements)
local Build = require(script.Parent.Build)

local Secrets = {}

function Secrets.build()
	local at = Config.SecretStraw
	local base = CFrame.new(at[1], at[2], at[3]) * CFrame.Angles(0, math.rad(35), math.rad(70))
	local straw = Build.part({ name = "GoldenStraw", size = Vector3.new(2.6, 0.25, 0.25), cframe = base, color = { 255, 214, 90 }, material = "Neon", collide = false, shape = "Cylinder" })
	straw.CanTouch = true
	straw.Transparency = 0.1
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 220, 120)
	light.Range = 6
	light.Brightness = 0.6
	light.Parent = straw
	-- a bigger, invisible touch zone so brushing past it counts
	local zone = Build.part({ name = "GoldenStrawZone", size = Vector3.new(4, 4, 4), cframe = CFrame.new(at[1], at[2] + 1, at[3]), color = { 255, 255, 255 }, collide = false, transparency = 1 })
	zone.CanTouch = true
	zone.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		local d = player and PlayerData.get(player)
		if d and (d.stats.secret_straw or 0) < 1 then
			PlayerData.update(player, function(data)
				data.stats.secret_straw = 1
			end)
			Achievements.check(player)
		end
	end)
	straw.Parent = workspace
	zone.Parent = workspace
end

return Secrets

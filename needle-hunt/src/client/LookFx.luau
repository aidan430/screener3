-- The look, tuned on your own device (Config.Look.Tiers). Nothing here is sent to the server.
--   Detail: phones and tablets start on "mid", everything else on "high". If the frame rate stays
--   low during a round the tier drops one step (it never climbs back in the same session). On
--   "mid" the arena's smallest dressing (its Fine folder) is removed on your device; on "low" the
--   drifting dust (its Fx folder) goes too, and the glow and sun rays are switched off for you.
--   A soft blur of the far distance (depth of field) in the lobby and on the results screen, on
--   "high" only.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local LookFx = {}
local T = Config.Look.Tiers
local ORDER = { "high", "mid", "low" }
local tier = 1
local blur

local function prune() -- drop what this tier doesn't draw from the arena (on this device only)
	local arena = workspace:FindFirstChild("Arena")
	for i, name in ipairs({ "Fine", "Fx" }) do
		local folder = arena and arena:FindFirstChild(name)
		if folder and tier > i then
			folder:Destroy()
		end
	end
	for _, class in ipairs({ "BloomEffect", "SunRaysEffect" }) do
		local effect = Lighting:FindFirstChildOfClass(class)
		if effect and tier >= 3 then
			effect.Enabled = false
		end
	end
end

local function phase()
	return ReplicatedStorage:GetAttribute("Phase")
end

function LookFx.start()
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		tier = 2
	end
	blur = Instance.new("DepthOfFieldEffect")
	blur.FarIntensity, blur.NearIntensity, blur.FocusDistance, blur.InFocusRadius = T.blur.far, 0, T.blur.focus, T.blur.radius
	blur.Enabled = false
	blur.Parent = workspace.CurrentCamera
	ReplicatedStorage:GetAttributeChangedSignal("Phase"):Connect(function()
		if phase() == "countdown" then -- the server has finished building: now it's safe to prune
			prune()
		end
	end)
	local frames, since = 0, os.clock()
	RunService.RenderStepped:Connect(function()
		frames += 1
		local now = os.clock()
		if now - since >= T.window then
			local rate = frames / (now - since)
			frames, since = 0, now
			local playing = phase() == "countdown" or phase() == "search"
			if playing and rate < T.lowFps and tier < #ORDER then
				tier += 1
				prune()
			end
		end
		local inRound = Players.LocalPlayer:GetAttribute("InRound") == true
		blur.Enabled = tier == 1 and (not inRound or phase() == "results")
	end)
end

-- "high", "mid" or "low".
function LookFx.tier()
	return ORDER[tier]
end

return LookFx

-- The metal detector (Config.MetalDetector), bought once in the shop. While the player holds
-- the key, their client asks Remotes.Detect a few times a second; the server answers only a
-- coarse signal, 0 (nothing in range) to `levels` (right on it), from the distance between
-- their head and their needle's clump. The needle's position never leaves the server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local PlayerData = require(script.Parent.PlayerData)
local Plots = require(script.Parent.Plots)
local Piles = require(script.Parent.Piles)

local Detector = {}
local last = {} -- [player] = { at, signal }
local MIN_GAP = 0.2 -- seconds between real answers (about 4-5 a second); faster asks get the last one

-- 0 = out of range, else 1 (at the edge of the range) to levels (on top of it).
function Detector.signal(distance)
	local cfg = Config.MetalDetector
	if distance >= cfg.range then
		return 0
	end
	return math.clamp(math.ceil((1 - distance / cfg.range) * cfg.levels), 1, cfg.levels)
end

local function detect(player)
	local now = os.clock()
	local previous = last[player]
	if previous and now - previous.at < MIN_GAP then
		return previous.signal
	end
	local d = PlayerData.get(player)
	local plotIndex = Plots.of(player)
	local head = player.Character and player.Character:FindFirstChild("Head")
	local signal = 0
	if d and d.detector and plotIndex and head and d.needleClump >= 1 then
		signal = Detector.signal((head.Position - Piles.position(plotIndex, d.needleClump)).Magnitude)
	end
	last[player] = { at = now, signal = signal }
	return signal
end

function Detector.init()
	Remotes.Detect.OnServerInvoke = detect
	Players.PlayerRemoving:Connect(function(player)
		last[player] = nil
	end)
end

return Detector

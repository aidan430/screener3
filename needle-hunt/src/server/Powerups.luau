-- Power-ups on the maps (Config.Powerups). When a round's search starts, glowing orbs float in
-- random maze cells; walk into one to take it (the server checks you're in the round, it's the
-- search, and you're really there), and a new one appears somewhere else a little later. What it
-- does is decided here; Remotes.Powerup tells your screen what to show (client/PowerupFx):
--   speed     faster walking for a while (set here, on your character)
--   compass   where the nearest unopened chest is (your screen shows an arrow)
--   birdseye  your camera rises above the maze for a few seconds (your screen only)
--   glint     where the unopened chests near you are (your screen makes them sparkle)
--   coins     a pouch of coins, paid here
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Rules = require(Shared:WaitForChild("Rules"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local MapKit = require(script.Parent.MapKit)
local Streaks = require(script.Parent.Streaks)
local RewardManager = require(script.Parent.RewardManager)

local Powerups = {}
local P = Config.Powerups
local active = nil -- { ctx, round, folder, token }
local rng = Random.new()

-- The unopened chests within `range` (glint), and the nearest one (compass).
local function chestsNear(position, range)
	local out = {}
	for _, c in ipairs(active and active.round.chests or {}) do
		if not c.opened and (c.position - position).Magnitude <= range then
			table.insert(out, c.position)
		end
	end
	return out
end

local function nearestChest(position)
	local best, dist = nil, math.huge
	for _, c in ipairs(active.round.chests or {}) do
		local d = (c.position - position).Magnitude
		if not c.opened and d < dist then
			best, dist = c.position, d
		end
	end
	return best
end

local function apply(player, kind, root)
	local message = { kind = kind.id, name = kind.name, seconds = kind.seconds }
	if kind.id == "speed" then
		local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if h then
			local boosted = math.max(kind.walkSpeed, Streaks.walkSpeed(player)) -- never slower than a Marked player's
			h.WalkSpeed = boosted
			local token = (player:GetAttribute("SpeedToken") or 0) + 1
			player:SetAttribute("SpeedToken", token)
			task.delay(kind.seconds, function()
				if player:GetAttribute("SpeedToken") == token and h.Parent and h.WalkSpeed == boosted then
					h.WalkSpeed = Streaks.walkSpeed(player)
				end
			end)
		end
	elseif kind.id == "compass" then
		message.target = nearestChest(root.Position)
	elseif kind.id == "birdseye" then
		message.height = kind.height
	elseif kind.id == "glint" then
		message.points = chestsNear(root.Position, kind.range)
	elseif kind.id == "coins" then
		local coins = kind.coins * (if RewardManager.hasPass(player, "DoubleCoins") then 2 else 1)
		RewardManager.grant(player, coins, kind.xp, nil)
		message.coins = coins
	end
	Remotes.Powerup:FireClient(player, message)
end

local spawnOne

local function take(orb, kind, hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	local root = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or not active or not orb.Parent or not active.round.participants[player] or ReplicatedStorage:GetAttribute("Phase") ~= "search" then
		return
	end
	if (root.Position - orb.Position).Magnitude > 8 then
		return -- too far from the orb: a touch that can't be real
	end
	orb.Parent:Destroy()
	apply(player, kind, root)
	local token = active.token
	task.delay(P.respawn, function()
		if active and active.token == token then
			spawnOne()
		end
	end)
end

spawnOne = function() -- (declared above, so take() can call it)
	local maze = active and active.ctx.maze
	if not maze or #maze.cells == 0 then
		return
	end
	local ctx = active.ctx
	local kind = Rules.pick(P.kinds, rng)
	local cell = maze.cells[rng:NextInteger(1, #maze.cells)]
	local pos = MapKit.at(ctx, cell.x, 2.6, cell.z)
	local model = Instance.new("Model")
	model.Name = "Powerup"
	local colour = Color3.fromRGB(kind.colour[1], kind.colour[2], kind.colour[3])
	local orb = MapKit.part(ctx, { Name = "Orb", CanQuery = false, Shape = "Ball", Size = Vector3.one * 2.2, CFrame = CFrame.new(pos), Color = kind.colour, Material = "Neon", CanCollide = false, Transparency = 0.15, Parent = model })
	local ring = MapKit.part(ctx, { Name = "Ring", Shape = "Cylinder", Size = Vector3.new(0.2, 3.4, 3.4), CFrame = CFrame.new(pos - Vector3.new(0, 2.4, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = kind.colour, Material = "Neon", CanCollide = false, CanQuery = false, Transparency = 0.4, Parent = model })
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness = colour, 12, 1.4
	light.Parent = orb
	local tag = Instance.new("BillboardGui")
	tag.Size, tag.StudsOffset, tag.MaxDistance, tag.AlwaysOnTop = UDim2.fromOffset(120, 70), Vector3.new(0, 2.4, 0), 60, false
	tag.Parent = orb
	for i, t in ipairs({ { kind.icon, 40 }, { kind.name, 20 } }) do
		local picture = i == 1 and (kind.image or 0) > 0 -- the owner's icon, once uploaded
		local l = Instance.new(if picture then "ImageLabel" else "TextLabel")
		l.BackgroundTransparency, l.Size, l.Position = 1, UDim2.new(1, 0, 0, if i == 1 then 44 else 24), UDim2.fromOffset(0, if i == 1 then 0 else 44)
		if picture then
			l.Image, l.ScaleType = "rbxassetid://" .. kind.image, Enum.ScaleType.Fit
		else
			l.Text, l.Font, l.TextScaled, l.TextColor3, l.TextStrokeTransparency = t[1], Enum.Font.BuilderSansBold, true, Color3.new(1, 1, 1), 0.3
		end
		l.Parent = tag
	end
	TweenService:Create(orb, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { CFrame = CFrame.new(pos + Vector3.new(0, 0.8, 0)) }):Play()
	TweenService:Create(ring, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Transparency = 0.8 }):Play()
	model.Parent = active.folder
	orb.Touched:Connect(function(hit)
		take(orb, kind, hit)
	end)
end

-- Starts a round's power-ups (call as the search begins).
function Powerups.start(ctx, round)
	Powerups.stop()
	local folder = Instance.new("Folder")
	folder.Name = "Powerups"
	folder.Parent = ctx.model
	active = { ctx = ctx, round = round, folder = folder, token = rng:NextInteger(1, 2 ^ 30) }
	for _ = 1, P.count do
		spawnOne()
	end
end

-- Ends them: orbs go, and anyone still sped up walks normally again.
function Powerups.stop()
	if active then
		active.folder:Destroy()
		for p in pairs(active.round.participants) do
			local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
			if h and h.WalkSpeed > Streaks.walkSpeed(p) then
				h.WalkSpeed = Streaks.walkSpeed(p)
			end
		end
	end
	active = nil
end

return Powerups

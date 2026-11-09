-- The chests each round (Config.Chests). They go in the maze's dead ends first (then any checked
-- spot), spread apart, each on a real floor with room round it. Hold E (or tap) to open one; the
-- server checks you're in the round's search, close enough, not flagged, and that nobody opened it
-- first. What's inside is rolled here: coins, or a key that opens a box in the lobby. A Golden
-- Chest (Config.GoldenChance) always holds a Starlight Key, and a Key Round puts a key in every
-- chest. The lid swings open for everyone and the chest stays, empty, for the rest of the round.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Rules = require(Shared:WaitForChild("Rules"))
local MapKit = require(script.Parent.MapKit)
local AntiCheat = require(script.Parent.AntiCheat)

local ChestSpawner = {}
ChestSpawner.onOpen = function(_player, _chest, _reward) end -- RoundManager sets these
ChestSpawner.canOpen = function(_player)
	return false
end

local CH = Config.Chests
local folder = nil
local chests = {} -- { model, lid, position, golden, opened, index }
local rng = Random.new()

-- A floor under it and nothing solid where the chest would stand.
local function validSpot(pos, ctx)
	local params = RaycastParams.new()
	params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Include, { ctx.model }
	local hit = workspace:Raycast(pos + Vector3.new(0, 3, 0), Vector3.new(0, -5, 0), params)
	if not hit or hit.Position.Y - (ctx.centre.Y + ctx.floorY) > 1 then
		return nil -- no floor, or up on something: chests stand on the ground
	end
	local overlap = OverlapParams.new()
	overlap.FilterType, overlap.FilterDescendantsInstances = Enum.RaycastFilterType.Include, { ctx.model }
	for _, part in ipairs(workspace:GetPartBoundsInBox(CFrame.new(hit.Position + Vector3.new(0, 1.4, 0)), Vector3.new(4, 2.4, 3.4), overlap)) do
		if part.CanCollide and part ~= hit.Instance then
			return nil
		end
	end
	return hit.Position
end

-- Where the chests go: dead ends first, then the map's other spots, at least CH.spread apart.
local function places(ctx)
	local candidates = {}
	for _, cell in ipairs(ctx.maze and ctx.maze.deadEnds or {}) do
		table.insert(candidates, MapKit.at(ctx, cell.x, 0, cell.z))
	end
	local others = {}
	for _, spot in ipairs(ctx.spots) do
		table.insert(others, spot.cf.Position)
	end
	for i = #candidates, 2, -1 do -- shuffled, so they're somewhere new each time
		local j = rng:NextInteger(1, i)
		candidates[i], candidates[j] = candidates[j], candidates[i]
	end
	for i = #others, 2, -1 do
		local j = rng:NextInteger(1, i)
		others[i], others[j] = others[j], others[i]
	end
	table.move(others, 1, #others, #candidates + 1, candidates)
	local chosen = {}
	for _, pos in ipairs(candidates) do
		local ground = validSpot(pos, ctx)
		local apart = ground ~= nil
		for _, c in ipairs(chosen) do
			if apart and (c - ground).Magnitude < CH.spread then
				apart = false
			end
		end
		if apart then
			table.insert(chosen, ground)
			if #chosen >= CH.count then
				break
			end
		end
	end
	return chosen
end

-- A wooden chest with metal bands; the lid hinges at the back.
local function build(ctx, ground, golden, index)
	local model = Instance.new("Model")
	model.Name = if golden then "GoldenChest" else "Chest"
	local turn = CFrame.Angles(0, rng:NextInteger(0, 3) * math.pi / 2, 0)
	local base = CFrame.new(ground) * turn
	local wood = if golden then { 230, 180, 60 } else { 140, 92, 52 }
	local band = if golden then { 255, 236, 160 } else { 70, 72, 80 }
	local body = MapKit.part(ctx, { Name = "Body", Size = Vector3.new(3.2, 1.8, 2.2), CFrame = base * CFrame.new(0, 0.9, 0), Color = wood, Material = if golden then "Metal" else "WoodPlanks", Parent = model })
	for _, x in ipairs({ -1.2, 1.2 }) do
		MapKit.part(ctx, { Name = "Band", Size = Vector3.new(0.25, 1.86, 2.26), CFrame = base * CFrame.new(x, 0.9, 0), Color = band, Material = "Metal", CanCollide = false, Parent = model })
	end
	local hinge = base * CFrame.new(0, 1.8, 1.1) -- the back top edge
	local lid = MapKit.part(ctx, { Name = "Lid", Size = Vector3.new(3.3, 0.6, 2.3), CFrame = hinge * CFrame.new(0, 0.3, -1.15), Color = wood, Material = if golden then "Metal" else "WoodPlanks", CanCollide = false, Parent = model })
	MapKit.part(ctx, { Name = "Lock", Size = Vector3.new(0.5, 0.6, 0.2), CFrame = base * CFrame.new(0, 1.6, -1.15), Color = { 255, 205, 70 }, Material = "Metal", CanCollide = false, Parent = model })
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness = Color3.fromRGB(255, 214, 120), if golden then 14 else 9, if golden then 1.6 else 0.9
	light.Parent = body
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText, prompt.ObjectText = "Open", if golden then "Golden Chest" else "Chest"
	prompt.HoldDuration, prompt.MaxActivationDistance, prompt.RequiresLineOfSight = CH.hold, CH.reach, false
	prompt.Parent = body
	if RunService:IsStudio() and Config.Testing.revealChests then -- Studio testing only
		local h = Instance.new("Highlight")
		h.DepthMode, h.FillColor = Enum.HighlightDepthMode.AlwaysOnTop, Color3.fromRGB(255, 200, 60)
		h.Parent = model
	end
	model.Parent = folder
	local chest = { model = model, lid = lid, hinge = hinge, position = body.Position, golden = golden, opened = false, index = index, prompt = prompt }
	prompt.Triggered:Connect(function(player)
		ChestSpawner.open(player, chest)
	end)
	return chest
end

-- What's inside: a key (which box it opens, by weight) or a handful of coins.
local function roll(chest, round)
	if chest.golden then
		return { key = CH.goldenKey }
	elseif round.modifiers.keys or rng:NextNumber() < CH.keyChance then
		return { key = Rules.pick(CH.keys, rng).id }
	end
	return { coins = math.floor(rng:NextInteger(CH.coins[1], CH.coins[2]) * round.diff.coins + 0.5) }
end

function ChestSpawner.open(player, chest)
	if chest.opened or not ChestSpawner.canOpen(player) or AntiCheat.flagged(player) then
		return
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - chest.position).Magnitude > CH.reach + 3 then
		return
	end
	chest.opened = true
	chest.prompt.Enabled = false
	local swing = chest.hinge * CFrame.Angles(math.rad(-105), 0, 0) * CFrame.new(0, 0.3, -1.15)
	TweenService:Create(chest.lid, TweenInfo.new(0.5, Enum.EasingStyle.Back), { CFrame = swing }):Play()
	ChestSpawner.onOpen(player, chest, roll(chest, ChestSpawner.round))
end

-- Builds this round's chests. Returns them (positions, opened flags) for hints and power-ups.
function ChestSpawner.spawn(ctx, round)
	ChestSpawner.clear()
	ChestSpawner.round = round
	folder = Instance.new("Folder")
	folder.Name = "Chests"
	folder.Parent = ctx.model
	local spots = places(ctx)
	local goldenAt = if round.golden then rng:NextInteger(1, math.max(1, #spots)) else 0
	for i, ground in ipairs(spots) do
		table.insert(chests, build(ctx, ground, i == goldenAt, i))
	end
	return chests
end

-- Roughly where the nearest unopened chest is, for a hint.
function ChestSpawner.hint(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local best, dist = nil, math.huge
	for _, c in ipairs(chests) do
		local d = root and (c.position - root.Position).Magnitude or math.huge
		if not c.opened and d < dist then
			best, dist = c, d
		end
	end
	if not best then
		return nil
	end
	local rel = root.CFrame:VectorToObjectSpace(best.position - root.Position) -- -Z is ahead
	local dirs = { "straight ahead", "ahead, to your right", "to your right", "behind you, to the right", "behind you", "behind you, to the left", "to your left", "ahead, to your left" }
	local dir = dirs[(math.floor((math.atan2(rel.X, -rel.Z) / (math.pi * 2)) * 8 + 0.5) % 8) + 1]
	local far = if dist < Config.Hints.nearStuds then "very close" elseif dist < Config.Hints.farStuds then "not far" else "a long way off"
	return "A chest is " .. far .. ", " .. dir .. "."
end

function ChestSpawner.clear()
	if folder then
		folder:Destroy()
	end
	folder, chests, ChestSpawner.round = nil, {}, nil
end

return ChestSpawner

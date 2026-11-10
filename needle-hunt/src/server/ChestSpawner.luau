-- The chests each round (Config.Chests), made to be fought over. They go in the dead ends furthest
-- from the spawns (then any checked spot), spread apart, each up on a perch you jump up to; a Golden
-- Chest stands tallest, in a clearing. Hold E (or tap) for a few seconds to open one; the server
-- checks you're in the round's search, up on the perch and close enough, not just hit, not flagged,
-- and that nobody opened it first. What's inside is rolled here: coins, or a key that opens a box in the lobby. A Golden
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

local function nearestSpawn(ctx, pos)
	local best = math.huge
	for _, cf in ipairs(ctx.spawns) do
		local p = if typeof(cf) == "CFrame" then cf.Position else cf
		best = math.min(best, (Vector3.new(p.X, pos.Y, p.Z) - pos).Magnitude)
	end
	return best
end

-- Where the chests go: the dead ends furthest from the spawns first (a little shuffled, so it's
-- never the same five), then other corridors, then the map's other spots, at least CH.spread apart
-- (closer, step by step, on a map too small for five that far apart), stepping round any prop. A Golden Chest goes
-- in a clearing first. Returns the ground positions and, if any, which one is the golden one.
local function places(ctx, golden)
	local chosen, goldenAt = {}, nil
	local rooms = ctx.maze and ctx.maze.rooms or {}
	if golden and #rooms > 0 then
		local room = rooms[rng:NextInteger(1, #rooms)]
		local ground = validSpot(MapKit.at(ctx, room.x, 0, room.z), ctx)
		if ground then
			table.insert(chosen, ground)
			goldenAt = 1
		end
	end
	local candidates = {}
	local function add(list) -- far from the spawns first, a little shuffled
		local group = {}
		for _, cell in ipairs(list) do
			local pos = MapKit.at(ctx, cell.x, 0, cell.z)
			table.insert(group, { pos = pos, far = nearestSpawn(ctx, pos) * rng:NextNumber(0.75, 1.25) })
		end
		table.sort(group, function(a, b)
			return a.far > b.far
		end)
		table.move(group, 1, #group, #candidates + 1, candidates)
	end
	add(ctx.maze and ctx.maze.deadEnds or {}) -- dead ends first: the hardest to reach
	add(ctx.maze and ctx.maze.cells or {}) -- then any corridor, on a small map with few dead ends
	local others = {}
	for _, spot in ipairs(ctx.spots) do
		table.insert(others, { pos = spot.cf.Position })
	end
	for i = #others, 2, -1 do
		local j = rng:NextInteger(1, i)
		others[i], others[j] = others[j], others[i]
	end
	table.move(others, 1, #others, #candidates + 1, candidates)
	local nudges = { Vector3.zero, Vector3.new(3, 0, 0), Vector3.new(-3, 0, 0), Vector3.new(0, 0, 3), Vector3.new(0, 0, -3) }
	for _, spread in ipairs({ CH.spread, CH.spread * 0.66, CH.spread * 0.45, 10 }) do -- closer together only if they must be
		for _, c in ipairs(candidates) do
			if #chosen >= CH.count then
				break
			end
			local ground
			for _, nudge in ipairs(nudges) do -- a prop in the way: try beside it
				ground = validSpot(c.pos + nudge, ctx)
				if ground then
					break
				end
			end
			local apart = ground ~= nil
			for _, g in ipairs(chosen) do
				if apart and (g - ground).Magnitude < spread then
					apart = false
				end
			end
			if apart then
				table.insert(chosen, ground)
			end
		end
	end
	if golden and not goldenAt and #chosen > 0 then
		goldenAt = rng:NextInteger(1, #chosen)
	end
	return chosen, goldenAt
end

local function blocked(ctx, centre, size)
	local overlap = OverlapParams.new()
	overlap.FilterType, overlap.FilterDescendantsInstances = Enum.RaycastFilterType.Include, { ctx.model }
	for _, part in ipairs(workspace:GetPartBoundsInBox(CFrame.new(centre), size, overlap)) do
		if part.CanCollide then
			return true
		end
	end
	return false
end

-- A perch: a stone pillar with the chest on top, and a few steps up to it from the open side of the
-- dead end (the way with the most room). Each step is an easy jump; the last is onto the pillar.
-- Returns the top, where the chest stands.
local function perch(ctx, ground, height)
	local open, room = Vector3.new(1, 0, 0), -1
	local params = RaycastParams.new()
	params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Include, { ctx.model }
	for _, dir in ipairs({ Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 0, -1) }) do
		local hit = workspace:Raycast(ground + Vector3.new(0, 3, 0), dir * 40, params)
		local d = if hit then hit.Distance else 40
		if d > room then
			open, room = dir, d
		end
	end
	local steps = math.clamp(math.floor((room - 4) / 3.4), 1, if height > 6.5 then 3 else 2)
	height = math.min(height, 3.2 * (steps + 1)) -- every jump stays easy
	local stone = { 128, 120, 108 }
	MapKit.part(ctx, { Name = "Perch", Size = Vector3.new(6, height, 6), CFrame = CFrame.new(ground + Vector3.new(0, height / 2, 0)), Color = stone, Material = "Slate" })
	MapKit.part(ctx, { Name = "PerchCap", Size = Vector3.new(6.6, 0.4, 6.6), CFrame = CFrame.new(ground + Vector3.new(0, height + 0.2, 0)), Color = { 150, 142, 128 }, Material = "Slate" })
	for i = steps, 1, -1 do -- the highest step stands nearest the pillar
		local top = height * i / (steps + 1)
		local at = ground + open * (3 + 3.4 * (steps + 1 - i))
		if not blocked(ctx, at + Vector3.new(0, top / 2 + 0.2, 0), Vector3.new(2.8, math.max(0.4, top - 0.4), 2.8)) then
			MapKit.part(ctx, { Name = "Step", Size = Vector3.new(3.2, top, 3.2), CFrame = CFrame.new(at + Vector3.new(0, top / 2, 0)) * CFrame.Angles(0, rng:NextNumber() * 0.3, 0), Color = { 110, 102, 92 }, Material = "Slate" })
		end
	end
	return ground + Vector3.new(0, height + 0.4, 0)
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
	prompt:SetAttribute("Chest", true) -- client/CombatFx cancels a hold when you're hit
	prompt.Parent = body
	if RunService:IsStudio() and Config.Testing.revealChests then -- Studio testing only
		local h = Instance.new("Highlight")
		h.DepthMode, h.FillColor = Enum.HighlightDepthMode.AlwaysOnTop, Color3.fromRGB(255, 200, 60)
		h.Parent = model
	end
	model.Parent = folder
	local chest = { model = model, lid = lid, hinge = hinge, position = body.Position, top = ground.Y, golden = golden, opened = false, index = index, prompt = prompt }
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
	elseif root.Position.Y < chest.top + 1.5 then -- reaching up from the ground doesn't count
		ReplicatedStorage.Remotes.Notify:FireClient(player, { text = "Climb up to it first!", tone = "bad" })
		return
	elseif workspace:GetServerTimeNow() - (player:GetAttribute("HitAt") or -100) < CH.hitLock then
		ReplicatedStorage.Remotes.Notify:FireClient(player, { text = "You were hit! Hold it again.", tone = "bad" })
		return
	end
	chest.opened = true
	chest.prompt.Enabled = false
	chest.prompt:SetAttribute("Opened", true)
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
	local spots, goldenAt = places(ctx, round.golden)
	local cap = (ctx.maze and ctx.maze.height or 10) - 1 -- never above the walls
	for i, ground in ipairs(spots) do
		local h = if i == goldenAt then CH.goldenPerch else rng:NextNumber(CH.perch[1], CH.perch[2])
		table.insert(chests, build(ctx, perch(ctx, ground, math.min(h, cap)), i == goldenAt, i))
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

-- Hides the needle(s) each round and decides, on the server, who found them.
-- A spot is used only if (1) there's a real surface just under it, (2) nothing solid is in the
-- way where the needle would lie, and (3) it's within jumping height of the floor unless the map
-- marked it reachable by stairs (climb). The needle then moves a little (Config.Find.jitter) and
-- turns, so spots can't be memorised.
-- Claims come from a ClickDetector (mouse or tap) or walking into the needle, and only count if
-- RoundManager's canClaim(player) agrees, the character is within reach, the player isn't
-- clicking too fast or locked out by a decoy, and AntiCheat hasn't flagged them.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local MapKit = require(script.Parent.MapKit)
local AntiCheat = require(script.Parent.AntiCheat)
local NeedleModel = require(script.Parent.NeedleModel)

local NeedleSpawner = {}
NeedleSpawner.onClaim = function(_player, _needle) end -- RoundManager sets these
NeedleSpawner.canClaim = function(_player)
	return false
end

local folder = nil
local needles = {} -- { model, hitbox, position, golden, index }
local clicks = {} -- [player] = { times }
local lockedUntil = {} -- [player] = os.clock() a decoy locks them out until

local function validSpot(spot, ctx)
	local pos = spot.cf.Position
	if not spot.climb and pos.Y - (ctx.centre.Y + ctx.floorY) > Config.Find.maxSpotHeight then
		return false
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { ctx.model }
	local hit = workspace:Raycast(pos + Vector3.new(0, 1, 0), Vector3.new(0, -2.5, 0), params)
	if not hit then
		return false -- nothing to lie on
	end
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Include
	overlap.FilterDescendantsInstances = { ctx.model }
	local inside = workspace:GetPartBoundsInBox(CFrame.new(hit.Position + Vector3.new(0, 0.35, 0)), Vector3.new(1.4, 0.4, 1.4), overlap)
	for _, part in ipairs(inside) do
		if part.CanCollide and part ~= hit.Instance then
			return false -- inside a wall or another prop
		end
	end
	return true, hit.Position
end

local function rate(player)
	local now, list = os.clock(), clicks[player] or {}
	local kept = {}
	for _, t in ipairs(list) do
		if now - t < 1 then
			table.insert(kept, t)
		end
	end
	table.insert(kept, now)
	clicks[player] = kept
	return #kept <= Config.Find.clicksPerSecond
end

local function claim(player, needle, decoy)
	if not rate(player) or (lockedUntil[player] or 0) > os.clock() or not NeedleSpawner.canClaim(player) or AntiCheat.flagged(player) then
		return
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - needle.position).Magnitude > Config.Find.reach + 2 then
		return -- too far: the click came from somewhere it couldn't
	end
	if decoy then
		lockedUntil[player] = os.clock() + Config.Find.decoyLockout
		ReplicatedStorage.Remotes.Notify:FireClient(player, { text = "A decoy! Your hands are shaking for " .. Config.Find.decoyLockout .. " seconds...", tone = "bad" })
		return
	end
	NeedleSpawner.onClaim(player, needle)
end

-- Builds one needle (or a decoy) lying at `pos`: a thin shaft, an eye, and an invisible hitbox
-- you click, tap or walk into.
local function build(pos, diff, round, ctx, decoy)
	local rng = ctx.rng
	local turn = CFrame.Angles(0, rng:NextNumber() * math.pi * 2, 0)
	local base = CFrame.new(pos + Vector3.new(0, 0.06, 0)) * turn
	local length = diff.needle
	local colour, material = Color3.fromRGB(205, 210, 220), Enum.Material.Metal
	if round.golden and not decoy then
		colour = Color3.fromRGB(255, 205, 70)
	elseif round.modifiers.camo or decoy then
		colour, material = MapKit.rgb(ctx.def.straw), Enum.Material.SmoothPlastic
	end
	-- the owner's own needle model when there is one (plain rounds only: it can't change colour)
	local own = not decoy and not round.golden and not round.modifiers.camo and NeedleModel.place(CFrame.new(pos) * turn, length)
	local model = own or Instance.new("Model")
	model.Name = if decoy then "Decoy" else "Needle"
	local shaft = nil
	if not own then
		shaft = MapKit.part(ctx, { Name = "Shaft", Shape = "Cylinder", Size = Vector3.new(length, 0.09, 0.09), CFrame = base, Color = colour, Material = material, CanCollide = false, Parent = model })
		MapKit.part(ctx, { Name = "Eye", Size = Vector3.new(0.2, 0.05, 0.14), CFrame = base * CFrame.new(-length / 2 + 0.1, 0, 0), Color = colour:Lerp(Color3.new(0, 0, 0), 0.25), Material = material, CanCollide = false, Parent = model })
	end
	local hitbox = MapKit.part(ctx, { Name = "Hitbox", Size = Vector3.new(length + 0.5, Config.Find.hitbox, Config.Find.hitbox), CFrame = base, Transparency = 0.99, CanCollide = false, Parent = model })
	local detector = Instance.new("ClickDetector")
	detector.MaxActivationDistance = Config.Find.reach
	detector.Parent = hitbox
	if (diff.glint or round.golden) and not decoy then
		local e = Instance.new("ParticleEmitter")
		e.Rate, e.Lifetime, e.Speed = if round.golden then 3 else 0.6, NumberRange.new(0.4, 0.7), NumberRange.new(0)
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.35), NumberSequenceKeypoint.new(1, 0) })
		e.Color, e.LightEmission = ColorSequence.new(if round.golden then Color3.fromRGB(255, 230, 140) else Color3.new(1, 1, 1)), 0.8
		e.Parent = shaft or hitbox
	end
	model.Parent = folder
	local record = { model = model, position = hitbox.Position, golden = round.golden and not decoy, index = #needles + 1 }
	detector.MouseClick:Connect(function(player)
		claim(player, record, decoy)
	end)
	hitbox.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player then
			claim(player, record, decoy)
		end
	end)
	return record
end

-- Hides the round's needles (two for Double Needle) and Hard round decoys. Returns the needles.
function NeedleSpawner.spawn(ctx, diff, round)
	NeedleSpawner.clear()
	folder = Instance.new("Folder")
	folder.Name = "Needles"
	folder.Parent = ctx.model
	local spots = table.clone(ctx.spots)
	local function take()
		while #spots > 0 do
			local spot = table.remove(spots, ctx.rng:NextInteger(1, #spots))
			local j = Config.Find.jitter
			spot = { cf = spot.cf * CFrame.new((ctx.rng:NextNumber() - 0.5) * 2 * j, 0, (ctx.rng:NextNumber() - 0.5) * 2 * j), climb = spot.climb }
			local ok, at = validSpot(spot, ctx)
			if ok then
				return at
			end
		end
		return nil
	end
	for _ = 1, if round.modifiers.double then 2 else 1 do
		local at = take()
		if at then
			table.insert(needles, build(at, diff, round, ctx, false))
		end
	end
	for _ = 1, diff.decoys do
		local at = take()
		if at then
			build(at, diff, round, ctx, true)
		end
	end
	return needles
end

-- A hint for `player`: roughly where the nearest needle they haven't found is.
function NeedleSpawner.hint(player, foundBy)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	local best, dist = nil, math.huge
	for _, n in ipairs(needles) do
		local d = (n.position - root.Position).Magnitude
		if not (foundBy[n.index] and foundBy[n.index][player]) and d < dist then
			best, dist = n, d
		end
	end
	if not best then
		return nil
	end
	local offset = best.position - root.Position
	local rel = root.CFrame:VectorToObjectSpace(offset) -- relative to where you face: -Z is ahead
	local dirs = { "straight ahead", "ahead, to your right", "to your right", "behind you, to the right", "behind you", "behind you, to the left", "to your left", "ahead, to your left" }
	local angle = math.atan2(rel.X, -rel.Z)
	local dir = dirs[(math.floor((angle / (math.pi * 2)) * 8 + 0.5) % 8) + 1]
	local far = if dist < Config.Hints.nearStuds then "very close" elseif dist < Config.Hints.farStuds then "not far" else "a long way off"
	local height = if offset.Y > 4 then ", up high" elseif offset.Y < -4 then ", down low" else ""
	return "The needle is " .. far .. ", " .. dir .. height .. "."
end

function NeedleSpawner.clear()
	if folder then
		folder:Destroy()
	end
	folder, needles = nil, {}
end

Players.PlayerRemoving:Connect(function(player)
	clicks[player], lockedUntil[player] = nil, nil
end)

return NeedleSpawner

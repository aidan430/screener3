-- Builds one player's Practice Yard for a Time Trial (server/Practice, Config.Practice): a hedged
-- paddock of hay bales and crates for cover, straw dummies to tag out (some sliding to and fro),
-- and chests up on perches with steps. Each player's yard is their own, far from the lobby and
-- the round arena, and is destroyed when they leave.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local MapKit = require(script.Parent.MapKit)

local PracticeYard = {}
local P = Config.Practice

local function heartsText(n)
	return string.rep("♥", n) .. string.rep("♡", P.hearts - n)
end
PracticeYard.heartsText = heartsText

-- A straw dummy on a post: a sack body, a round head, a crossbar for arms. Hits find it by the
-- model's DummyId attribute. moving = it slides `range` studs to and fro along X.
local function dummy(ctx, id, owner, x, y, z, moving)
	local model = Instance.new("Model")
	model.Name = "Dummy"
	model:SetAttribute("DummyId", id)
	model:SetAttribute("DummyOwner", owner.UserId)
	model:SetAttribute("Hearts", P.hearts)
	local base = CFrame.new(MapKit.at(ctx, x, y, z)) * CFrame.Angles(0, ctx.rng:NextNumber() * math.pi * 2, 0)
	local root = MapKit.part(ctx, { Name = "Post", Size = Vector3.new(0.5, 3, 0.5), CFrame = base * CFrame.new(0, 1.5, 0), Color = { 110, 78, 46 }, Material = "Wood", Parent = model })
	local parts = {
		MapKit.part(ctx, { Name = "Body", Size = Vector3.new(2, 2.6, 1.2), CFrame = base * CFrame.new(0, 4.2, 0), Color = { 196, 160, 98 }, Material = "Fabric", Parent = model }),
		MapKit.part(ctx, { Name = "Head", Shape = "Ball", Size = Vector3.new(1.5, 1.5, 1.5), CFrame = base * CFrame.new(0, 6.2, 0), Color = { 214, 184, 120 }, Material = "Fabric", Parent = model }),
		MapKit.part(ctx, { Name = "Arms", Size = Vector3.new(4.2, 0.45, 0.45), CFrame = base * CFrame.new(0, 4.9, 0), Color = { 110, 78, 46 }, Material = "Wood", Parent = model }),
		MapKit.part(ctx, { Name = "Rope", Size = Vector3.new(2.06, 0.25, 1.26), CFrame = base * CFrame.new(0, 3.4, 0), Color = { 150, 30, 30 }, Material = "Fabric", CanCollide = false, Parent = model }),
	}
	for _, p in ipairs(parts) do
		p.Anchored = false
		local weld = Instance.new("WeldConstraint")
		weld.Part0, weld.Part1 = root, p
		weld.Parent = p
	end
	model.PrimaryPart = root
	local tag = Instance.new("BillboardGui")
	tag.Size, tag.StudsOffset, tag.MaxDistance = UDim2.fromOffset(120, 34), Vector3.new(0, 6.3, 0), 90
	tag.Parent = root
	local label = Instance.new("TextLabel")
	label.Name, label.Size, label.BackgroundTransparency = "Hearts", UDim2.fromScale(1, 1), 1
	label.Font, label.TextScaled, label.Text = Enum.Font.GothamBold, true, heartsText(P.hearts)
	label.TextColor3, label.TextStrokeTransparency = Color3.fromRGB(235, 40, 50), 0.4
	label.Parent = tag
	model.Parent = ctx.model
	if moving then -- slides along X and back, so you have to time it
		local range = ctx.rng:NextNumber(8, 14)
		TweenService:Create(root, TweenInfo.new(ctx.rng:NextNumber(2.5, 4), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { CFrame = root.CFrame * CFrame.new(range, 0, 0) }):Play()
	end
	return { model = model, root = root, label = label, id = id, hearts = P.hearts, out = false }
end

-- A chest up on a perch: a pillar `h` studs high with a couple of crate steps up to it.
local function chest(ctx, index, x, z, h)
	MapKit.part(ctx, { Name = "Perch", Size = Vector3.new(5, h, 5), CFrame = CFrame.new(MapKit.at(ctx, x, h / 2, z)), Color = { 140, 100, 62 }, Material = "WoodPlanks" })
	local a = ctx.rng:NextNumber() * math.pi * 2
	local dir = Vector3.new(math.cos(a), 0, math.sin(a))
	for k = 1, math.max(1, math.floor(h / 2.6)) do -- steps spiralling up to the top
		local step = math.min(h - 0.6, k * 2.6)
		local p = Vector3.new(x, 0, z) + dir * (3.6 + k * 0.3) + Vector3.new(-dir.Z, 0, dir.X) * (k - 1) * 2.4
		MapKit.part(ctx, { Name = "Step", Size = Vector3.new(3, step, 3), CFrame = CFrame.new(MapKit.at(ctx, p.X, step / 2, p.Z)), Color = { 150, 106, 64 }, Material = "WoodPlanks" })
	end
	local base = CFrame.new(MapKit.at(ctx, x, h, z)) * CFrame.Angles(0, ctx.rng:NextInteger(0, 3) * math.pi / 2, 0)
	local model = Instance.new("Model")
	model.Name = "Chest"
	local body = MapKit.part(ctx, { Name = "Body", Size = Vector3.new(3.2, 1.8, 2.2), CFrame = base * CFrame.new(0, 0.9, 0), Color = { 140, 92, 52 }, Material = "WoodPlanks", Parent = model })
	for _, bx in ipairs({ -1.2, 1.2 }) do
		MapKit.part(ctx, { Name = "Band", Size = Vector3.new(0.25, 1.86, 2.26), CFrame = base * CFrame.new(bx, 0.9, 0), Color = { 70, 72, 80 }, Material = "Metal", CanCollide = false, Parent = model })
	end
	local hinge = base * CFrame.new(0, 1.8, 1.1)
	local lid = MapKit.part(ctx, { Name = "Lid", Size = Vector3.new(3.3, 0.6, 2.3), CFrame = hinge * CFrame.new(0, 0.3, -1.15), Color = { 140, 92, 52 }, Material = "WoodPlanks", CanCollide = false, Parent = model })
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness = Color3.fromRGB(255, 214, 120), 9, 0.9
	light.Parent = body
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText, prompt.ObjectText = "Open", "Practice Chest"
	prompt.HoldDuration, prompt.MaxActivationDistance, prompt.RequiresLineOfSight = Config.Chests.hold, Config.Chests.reach, false
	prompt:SetAttribute("Chest", true) -- the same hold as a round's chest
	prompt.Parent = body
	model.Parent = ctx.model
	return { model = model, lid = lid, hinge = hinge, position = body.Position, top = base.Position.Y, prompt = prompt, index = index, opened = false }
end

-- Builds a player's yard in `slot`. Returns { model, start (CFrame), dummies, chests }.
function PracticeYard.build(player, slot)
	local model = Instance.new("Model")
	model.Name = "PracticeYard_" .. player.UserId
	model.Parent = workspace
	local half = P.size / 2
	local ctx = { model = model, rng = Random.new(), centre = P.centre + Vector3.new(0, 0, (slot - 1) * P.spacing), def = { straw = { 226, 188, 92 } }, spots = {}, spawns = {}, floorY = 0 }
	MapKit.ground(ctx, P.size + 6, P.size + 6, { 110, 150, 70 }, "Grass")
	MapKit.edges(ctx, half, half, { 104, 160, 76 })
	MapKit.part(ctx, { Name = "StartPad", Shape = "Cylinder", Size = Vector3.new(0.3, 10, 10), CFrame = CFrame.new(MapKit.at(ctx, 0, 0.15, -half + 9)) * CFrame.Angles(0, 0, math.rad(90)), Color = { 190, 20, 20 }, Material = "Neon", CanCollide = false })
	local function free(x, z, r) -- clear of the start and the yard's edge
		return math.abs(x) < half - r and math.abs(z) < half - r and Vector2.new(x, z + half - 9).Magnitude > 16
	end
	local function spot(r)
		for _ = 1, 40 do
			local x, z = ctx.rng:NextNumber(-half, half), ctx.rng:NextNumber(-half, half)
			if free(x, z, r) then
				return x, z
			end
		end
		return 0, 0
	end
	for _ = 1, 14 do -- cover: bales and crates, sometimes stacked
		local x, z = spot(6)
		if ctx.rng:NextNumber() < 0.6 then
			MapKit.bale(ctx, x, 0, z, ctx.rng:NextNumber() * math.pi)
			if ctx.rng:NextNumber() < 0.4 then
				MapKit.bale(ctx, x, 2.5, z, ctx.rng:NextNumber() * math.pi)
			end
		else
			MapKit.crate(ctx, x, 0, z, ctx.rng:NextNumber(3, 4.5))
		end
	end
	local yard = { model = model, dummies = {}, chests = {}, start = CFrame.new(MapKit.at(ctx, 0, 3, -half + 9)) * CFrame.Angles(0, math.pi, 0) }
	for i = 1, P.chests do -- spread round the yard: each in its own slice
		local a = (i - 0.5) / P.chests * math.pi * 2 + ctx.rng:NextNumber(-0.3, 0.3)
		local r = ctx.rng:NextNumber(half * 0.45, half * 0.75)
		table.insert(yard.chests, chest(ctx, i, math.cos(a) * r, math.sin(a) * r, ctx.rng:NextNumber(P.perch[1], P.perch[2])))
	end
	for i = 1, P.dummies do
		local x, z = spot(10)
		table.insert(yard.dummies, dummy(ctx, "D" .. i, player, x, 0, z, i <= P.moving))
	end
	return yard
end

return PracticeYard

-- The ten haystacks: their straw counts (the 5,000,000 shared between them) and their looks.
-- A haystack shrinks as it is searched and grows back when a new case starts.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))(Config)
local Build = require(script.Parent.Build)

local Haystacks = {}
local states = {} -- one per haystack, in Piles.json order
local byId = {}
local gameState = ReplicatedStorage:WaitForChild("GameState")

local HAY = { { 226, 190, 92 }, { 212, 172, 76 }, { 236, 204, 112 } }

local function mound(pile, parent)
	local model = Instance.new("Model")
	model.Name = pile.id
	local base = Vector3.new(pile.x, 0, pile.z)
	local function ball(name, size, offset, colour)
		return Build.part({ name = name, shape = "Ball", size = Vector3.new(size, size, size), cframe = CFrame.new(base + offset), color = colour, material = "Grass", parent = model })
	end
	ball("Core", 22, Vector3.new(0, 3, 0), HAY[1])
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2
		ball("Lump", 13 + (i % 3) * 1.5, Vector3.new(math.cos(a) * 8, 0.5, math.sin(a) * 8), HAY[i % 3 + 1])
	end
	ball("Top", 9, Vector3.new(1, 13, -1), HAY[3])
	local rng = Random.new(#pile.id * 31 + math.floor(pile.x))
	for _ = 1, 14 do
		local a = rng:NextNumber() * math.pi * 2
		local h = rng:NextNumber(2, 13)
		local r = 10.5 - h * 0.45
		Build.part({
			name = "Straw",
			shape = "Cylinder",
			size = Vector3.new(rng:NextNumber(2.5, 4.5), 0.18, 0.18),
			cframe = CFrame.new(base + Vector3.new(math.cos(a) * r, h, math.sin(a) * r)) * CFrame.Angles(rng:NextNumber(-1, 1), a, rng:NextNumber(-0.6, 0.6)),
			color = { 246, 222, 140 },
			collide = false,
			shadow = false,
			parent = model,
		})
	end
	model.WorldPivot = CFrame.new(base) -- shrinks towards the ground
	model:SetAttribute("PileId", pile.id)
	model:SetAttribute("DisplayName", pile.name)
	model:SetAttribute("Side", pile.side)
	model.Parent = parent
	return model
end

local elapsed = 0
local function refresh(dt)
	elapsed += dt
	if elapsed < 0.25 then
		return
	end
	elapsed = 0
	local total = 0
	for _, state in ipairs(states) do
		total += state.remaining
		if state.dirty then
			state.dirty = false
			state.model:SetAttribute("Remaining", state.remaining)
			local scale = Economy.pileScale(state.remaining, state.total)
			if math.abs(scale - state.scale) > 0.004 then
				state.scale = scale
				state.model:ScaleTo(scale)
			end
		end
	end
	gameState:SetAttribute("Remaining", total)
end

function Haystacks.build(piles)
	local folder = Instance.new("Folder")
	folder.Name = "Haystacks"
	folder.Parent = workspace
	local each = math.floor(Config.TotalStraws / #piles)
	for _, pile in ipairs(piles) do
		local state = {
			pile = pile,
			model = mound(pile, folder),
			position = Vector3.new(pile.x, 0, pile.z),
			total = each,
			remaining = each,
			scale = 1,
			dirty = true,
		}
		state.model:SetAttribute("Total", each)
		table.insert(states, state)
		byId[pile.id] = state
	end
	gameState:SetAttribute("TotalStraws", each * #piles)
	gameState:SetAttribute("Remaining", each * #piles)
	RunService.Heartbeat:Connect(refresh)
end

-- Every haystack back to full, for a new case.
function Haystacks.refill()
	for _, state in ipairs(states) do
		state.remaining = state.total
		state.dirty = true
		state.model:SetAttribute("Remaining", state.total)
		if state.scale ~= 1 then
			state.scale = 1
			state.model:ScaleTo(1)
		end
	end
	gameState:SetAttribute("Remaining", Config.TotalStraws)
end

-- The haystack a player standing at `position` can search, if any.
function Haystacks.nearest(position)
	local best, bestDistance = nil, Config.SearchRange
	for _, state in ipairs(states) do
		local flat = Vector3.new(position.X - state.position.X, 0, position.Z - state.position.Z)
		if flat.Magnitude <= bestDistance then
			best, bestDistance = state, flat.Magnitude
		end
	end
	return best
end

function Haystacks.take(state, amount)
	state.remaining = math.max(0, state.remaining - amount)
	state.dirty = true
end

function Haystacks.get(id)
	return byId[id]
end

return Haystacks

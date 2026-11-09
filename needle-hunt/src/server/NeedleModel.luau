-- The owner's own needle model (Config.NeedleModel.asset): a model imported into Studio with its
-- textures, saved to Roblox, and loaded here once with InsertService (it must belong to the
-- game's owner, or be public). It's turned so its longest side runs along X, centred, then each
-- round a copy is scaled to that round's needle length and laid flat on the hiding spot.
-- Camouflage and Golden rounds, and decoys, keep the built needle (a textured model can't change
-- colour). With no asset set, or if loading fails, every needle is the built one.
local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local NeedleModel = {}
local template = nil

function NeedleModel.load()
	local id = Config.NeedleModel and Config.NeedleModel.asset or 0
	if id == 0 then
		return
	end
	task.spawn(function()
		local ok, asset = pcall(InsertService.LoadAsset, InsertService, id)
		if not ok or not asset then
			warn("[NeedleModel] couldn't load model " .. id .. ": " .. tostring(asset) .. " (it must be owned by the game's owner or be public)")
			return
		end
		local model = asset:FindFirstChildWhichIsA("Model") or asset
		local parts = 0
		for _, p in ipairs(model:GetDescendants()) do
			if p:IsA("BasePart") then
				p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow, p.Massless = true, false, false, false, false, true
				parts += 1
			end
		end
		if parts == 0 then
			warn("[NeedleModel] model " .. id .. " has no parts")
			return
		end
		-- centre it and turn its longest side along X; then make that the pivot
		local cf, size = model:GetBoundingBox()
		model.WorldPivot = cf
		local turn = CFrame.new()
		if size.Y >= size.X and size.Y >= size.Z then
			turn = CFrame.Angles(0, 0, math.rad(90))
		elseif size.Z >= size.X and size.Z >= size.Y then
			turn = CFrame.Angles(0, math.rad(90), 0)
		end
		model:PivotTo(turn)
		model.WorldPivot = CFrame.new()
		model.Name = "Needle"
		template = model
	end)
end

-- A copy laid on a surface at `base` (the surface point, turned), `length` studs long; or nil.
function NeedleModel.place(base, length)
	if not template then
		return nil
	end
	local m = template:Clone()
	local _, size = m:GetBoundingBox()
	m:ScaleTo(m:GetScale() * length / math.max(size.X, size.Y, size.Z))
	local _, scaled = m:GetBoundingBox()
	m:PivotTo(base * CFrame.new(0, scaled.Y / 2, 0)) -- resting on the surface
	return m
end

return NeedleModel

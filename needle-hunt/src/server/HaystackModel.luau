-- The owner's own haystack model (Config.Haystacks.model): loaded once with InsertService (it must
-- belong to the game's owner, or be public), centred and set on its base. MapKit.haystack places a
-- copy, scaled to each haystack's size, wherever one goes. Until it loads (or with no ID), the
-- built terrain haystacks are used.
local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local HaystackModel = {}
local template = nil

function HaystackModel.load()
	local id = Config.Haystacks.model
	if id == 0 then
		return
	end
	local ok, asset = pcall(InsertService.LoadAsset, InsertService, id)
	if not ok or not asset then
		warn("[HaystackModel] couldn't load model " .. id .. ": " .. tostring(asset) .. " (it must be owned by the game's owner or be public)")
		return
	end
	local model = asset:FindFirstChildWhichIsA("Model") or asset
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored, p.CanQuery, p.CanTouch = true, false, false
		end
	end
	local cf, size = model:GetBoundingBox()
	model.WorldPivot = CFrame.new(cf.Position - Vector3.new(0, size.Y / 2, 0)) -- the middle of its base
	model:PivotTo(CFrame.new())
	model.Name = "Haystack"
	template = model
end

-- A copy standing on `ground` (a Vector3), about `width` studs across; nil if there's no model.
function HaystackModel.place(ground, width, turn)
	if not template then
		return nil
	end
	local m = template:Clone()
	local _, size = m:GetBoundingBox()
	m:ScaleTo(m:GetScale() * width / math.max(size.X, size.Z))
	m:PivotTo(CFrame.new(ground) * CFrame.Angles(0, turn, 0))
	return m
end

return HaystackModel

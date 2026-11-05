-- Things the owner imported in Studio and uploaded, loaded by asset ID: a saved Model (via
-- InsertService, textures and all) or a mesh (via AssetService, at its real size). Loaded once
-- and cached; nil if it can't be loaded (the game then uses its built-in look).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Assets = {}
local AssetService = game:GetService("AssetService")
local InsertService = game:GetService("InsertService")

local loaded = {} -- [asset id] = a template part, or false if it couldn't be loaded as a model

function Assets.template(id)
	if loaded[id] ~= nil then
		return loaded[id]
	end
	loaded[id] = false
	local ok, asset = pcall(function()
		return InsertService:LoadAsset(id)
	end)
	if ok and asset then
		local part = if asset:IsA("BasePart") then asset else asset:FindFirstChildWhichIsA("BasePart", true)
		if part then
			part = part:Clone()
			for _, child in ipairs(part:GetChildren()) do
				if child:IsA("JointInstance") or child:IsA("Constraint") or child:IsA("Attachment") then
					child:Destroy()
				end
			end
			loaded[id] = part
		end
		asset:Destroy()
	end
	if not loaded[id] then -- not a model: try it as a mesh ID, which keeps the mesh's real size
		local made, meshPart = pcall(function()
			return AssetService:CreateMeshPartAsync("rbxassetid://" .. id)
		end)
		if made and meshPart then
			loaded[id] = meshPart
		else
			warn("[Assets] Couldn't load " .. tostring(id) .. " as a model or a mesh: " .. tostring(asset) .. " / " .. tostring(meshPart))
		end
	end
	return loaded[id]
end

-- The imported hay model, shrunk to 1 stud across and shared with every client as
-- ReplicatedStorage.HayTemplate, which HayLook clones for every loose bit of hay.
function Assets.shareHay()
	local id = tonumber(Config.HayModel)
	local part = id and id ~= 0 and Assets.template(id)
	if not part then
		return
	end
	local hay = part:Clone()
	local size = hay.Size
	hay.Size = size / math.max(size.X, size.Y, size.Z)
	hay.Name = "HayTemplate"
	hay.Anchored, hay.CanCollide, hay.CanQuery, hay.CanTouch = true, false, false, false
	hay.Parent = ReplicatedStorage
end

return Assets

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
	local waited = 0
	while loaded[id] == "loading" and waited < 20 do -- another caller is loading it: wait for that
		waited += task.wait(0.1)
	end
	if loaded[id] ~= nil and loaded[id] ~= "loading" then
		return loaded[id]
	end
	loaded[id] = "loading"
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
	if loaded[id] == "loading" then -- not a model: try it as a mesh ID, which keeps the mesh's real size
		local made, meshPart = pcall(function()
			return AssetService:CreateMeshPartAsync("rbxassetid://" .. id)
		end)
		if made and meshPart then
			loaded[id] = meshPart
		else
			loaded[id] = false
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

-- A whole uploaded model (every part of it, textures and all) by asset ID, loaded once; or,
-- for a mesh ID, a model holding that one mesh. Returns a fresh copy, or nil.
local models = {}
function Assets.model(id)
	id = tonumber(id)
	if not id or id == 0 then
		return nil
	end
	local waited = 0
	while models[id] == "loading" and waited < 20 do
		waited += task.wait(0.1)
	end
	if models[id] == nil or models[id] == "loading" then
		models[id] = "loading"
		local ok, asset = pcall(function()
			return InsertService:LoadAsset(id)
		end)
		local template = nil
		if ok and asset then
			local only = asset:GetChildren()
			template = if #only == 1 and only[1]:IsA("Model") then only[1] else asset
			template.Parent = nil
		else
			local made, part = pcall(function()
				return AssetService:CreateMeshPartAsync("rbxassetid://" .. id)
			end)
			if made and part then
				template = Instance.new("Model")
				part.Parent = template
			else
				warn("[Assets] Couldn't load model " .. id .. ": " .. tostring(asset))
			end
		end
		models[id] = template or false
	end
	return if models[id] then models[id]:Clone() else nil
end

-- Places a copy of model `id`: turned by `cf`'s rotation, scaled so its height (or, with
-- `byWidth`, its widest side) is `size`, standing with its base centred on `cf`. Returns it.
function Assets.place(id, cf, size, parent, byWidth)
	local model = Assets.model(id)
	if not model then
		return nil
	end
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
		elseif part:IsA("Script") or part:IsA("LocalScript") then
			part:Destroy() -- never run scripts that came with a model
		end
	end
	model:PivotTo(CFrame.new(model:GetPivot().Position) * cf.Rotation)
	local _, extents = model:GetBoundingBox()
	local now = if byWidth then math.max(extents.X, extents.Z) else extents.Y
	if now > 0 then
		pcall(function()
			model:ScaleTo(model:GetScale() * size / now)
		end)
	end
	local box, ext = model:GetBoundingBox()
	local bottom = box.Position - Vector3.new(0, ext.Y / 2, 0)
	model:PivotTo(model:GetPivot() + (cf.Position - bottom))
	model.Parent = parent
	return model
end

return Assets

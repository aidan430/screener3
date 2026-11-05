-- Tools that wear a model you imported in Studio (Config.Tools[n].model = its asset ID).
-- The ID can be a Model you saved to Roblox (loaded once with InsertService, keeping its
-- textures) or a mesh's ID (made into a MeshPart; add `texture` = "rbxassetid://..." for its
-- image). If neither loads, it's tried as a plain SpecialMesh. The model is
-- turned so its longest side runs along the handle, scaled to `length` studs, and flipped
-- (`flip`) so the working end points up, where the harvested hay sits.
local Assets = require(script.Parent.Assets)

local ToolLook = {}

-- The look for a tool definition, as a part centred on the handle, plus its length.
-- Returns nil when the definition has no model.
function ToolLook.make(def)
	local id = tonumber(def.model)
	if not id or id == 0 then
		return nil
	end
	local length = def.length or 3
	local part = Assets.template(id)
	local look
	if part then
		look = part:Clone()
		local size = look.Size
		local turn = CFrame.new() -- longest side along Y
		if size.X >= size.Y and size.X >= size.Z then
			turn = CFrame.Angles(0, 0, math.rad(90))
		elseif size.Z >= size.Y and size.Z >= size.X then
			turn = CFrame.Angles(math.rad(90), 0, 0)
		end
		look.Size = size * (length / math.max(size.X, size.Y, size.Z))
		look:SetAttribute("Turn", turn)
		if def.texture and look:IsA("MeshPart") then
			look.TextureID = def.texture
		end
	else
		look = Instance.new("Part")
		look.Size = Vector3.new(0.4, length, 0.4)
		look.Transparency = 0
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = "rbxassetid://" .. id
		mesh.TextureId = def.texture or ""
		mesh.Scale = Vector3.new(1, 1, 1) * (def.meshScale or 1)
		mesh.Parent = look
		look:SetAttribute("Turn", CFrame.new())
	end
	look.Name = "Look"
	look.Anchored, look.CanCollide, look.CanQuery, look.CanTouch, look.Massless = false, false, false, false, true
	return look, length
end

return ToolLook

-- One look for every loose bit of hay (on tools, in buckets and baskets, flying, dropped
-- bundles, the mounds round the heap): the imported hay model (Config.HayModel, which the
-- server shares as ReplicatedStorage.HayTemplate), else a mesh from Config.HayMesh, else a
-- rounded ball of the Grass material (which wears the hay texture if one is set).
-- Plain module: works on the server and the client.
return function(Config)
	local HayLook = {}
	local HAY = Color3.fromRGB(Config.HeapColour[1], Config.HeapColour[2], Config.HeapColour[3])
	local GOLD = Color3.fromRGB(255, 214, 90)

	-- A hay lump `size` studs across, `golden` for the Golden Loft's straw.
	function HayLook.lump(size, golden)
		local template = game:GetService("ReplicatedStorage"):FindFirstChild("HayTemplate")
		if template then
			local hay = template:Clone()
			hay.Name = "Hay"
			hay.Anchored, hay.CanCollide, hay.CanQuery, hay.CanTouch, hay.CastShadow = false, false, false, false, false
			hay:SetAttribute("BaseSize", template.Size)
			HayLook.resize(hay, size)
			return hay
		end
		local part = Instance.new("Part")
		part.Name = "Hay"
		part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = false, false, false, false
		part.Material = Enum.Material.Grass
		part.Color = if golden then GOLD else HAY
		part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		if Config.HayMesh ~= "" then
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.FileMesh
			mesh.MeshId = Config.HayMesh
			mesh.TextureId = Config.HayMeshTexture
			mesh.VertexColor = if golden then Vector3.new(1.3, 1.1, 0.4) else Vector3.new(1, 1, 1)
			mesh.Parent = part
		else
			part.Shape = Enum.PartType.Ball
		end
		HayLook.resize(part, size)
		return part
	end

	-- Sets a lump's size (the model is 1 stud across, so its mesh scales with the part).
	function HayLook.resize(part, size)
		local base = part:GetAttribute("BaseSize")
		if base then -- the imported model, 1 stud across at its widest
			part.Size = base * math.max(size, 0.05)
			return
		end
		local s = Vector3.new(size, size * 0.72, size)
		part.Size = Vector3.new(math.max(s.X, 0.05), math.max(s.Y, 0.05), math.max(s.Z, 0.05))
		local mesh = part:FindFirstChildOfClass("SpecialMesh")
		if mesh then
			mesh.Scale = Vector3.new(size, size, size) -- the model is 1 x 0.69 x 1 studs
		end
	end

	return HayLook
end

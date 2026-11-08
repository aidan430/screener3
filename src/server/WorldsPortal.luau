-- The portals: the built-in one is shaped by Config.PortalDesign (server/PortalShape; the owner
-- designs it in the Portal Designer page), its opening's light flowing upwards (Config.PortalTexture,
-- one white texture every portal tints; client/WorldFx scrolls it).
-- Your own design wins: a Model named "Portal" in ServerStorage > Designs (made in Studio), or
-- one you saved to Roblox (Config.PortalModel). In it: a part named "Base" marks the ground
-- under the middle (its Front faces the players), parts named "Glow..." take each portal's
-- colour, a part named "Opening" is where you walk in (it glows and wears the flowing light),
-- and a part named "Sign" gets the portal's name. assets/portal/HOW_TO.md explains it all.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Build = require(script.Parent.Build)
local Assets = require(script.Parent.Assets)
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Portal = {}
-- The flowing light on a part's two big faces (Config.PortalTexture), tinted `colour`.
local function flowOn(part, colour, faces)
	if Config.PortalTexture == "" then
		return
	end
	local tile = math.max(part.Size.X, part.Size.Y, part.Size.Z)
	for _, face in ipairs(faces) do
		local flow = Instance.new("Texture")
		flow.Texture = Config.PortalTexture
		flow.Face = face
		flow.Color3 = Build.rgb(colour):Lerp(Color3.new(1, 1, 1), 0.35)
		flow.StudsPerTileU, flow.StudsPerTileV = tile, tile
		flow.Transparency = 0.1
		flow.Parent = part
		CollectionService:AddTag(flow, "PortalFlow")
	end
end

-- The owner's design, if there is one: a fresh copy, or nil.
local function design()
	local folder = ServerStorage:FindFirstChild("Designs")
	local mine = folder and folder:FindFirstChild("Portal")
	if mine and mine:IsA("Model") then
		return mine:Clone()
	end
	return Assets.model(Config.PortalModel)
end

-- A copy of the owner's design placed at `cf`, in `colour`. Returns the face, or nil (and
-- warns) if the design has no "Base" or no "Opening".
local function fromDesign(model, cf, colour, parent, title, subtitle, Kit)
	local base, opening = model:FindFirstChild("Base", true), model:FindFirstChild("Opening", true)
	if not (base and base:IsA("BasePart") and opening and opening:IsA("BasePart")) then
		warn("[Portal] Your Portal design needs a part named Base and a part named Opening; using the built-in portal.")
		model:Destroy()
		return nil
	end
	model.PrimaryPart = base
	model:PivotTo(cf)
	model.Name = "Portal"
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			if string.sub(part.Name, 1, 4) == "Glow" or part == opening then
				part.Color = Build.rgb(colour)
			end
			if part == base then
				part.Transparency, part.CanCollide = 1, false
			end
		elseif part:IsA("Script") or part:IsA("LocalScript") then
			part:Destroy() -- a design is only looks
		end
	end
	opening.CanCollide = false
	local s = opening.Size
	local thin = if s.X <= s.Y and s.X <= s.Z then "X" elseif s.Y <= s.Z then "Y" else "Z"
	flowOn(opening, colour, if thin == "X" then { Enum.NormalId.Left, Enum.NormalId.Right } elseif thin == "Y" then { Enum.NormalId.Top, Enum.NormalId.Bottom } else { Enum.NormalId.Front, Enum.NormalId.Back })
	local sign = model:FindFirstChild("Sign", true)
	if sign and sign:IsA("BasePart") then
		Build.text(sign, Enum.NormalId.Front, title .. "\n" .. subtitle, { color = Build.rgb(colour), pixels = 30 })
	end
	-- the walk-in face: square to the base, as wide and tall as the opening
	local wide = math.max(s.X, s.Y, s.Z)
	local face = Build.part({ name = "PortalGlow", size = Vector3.new(wide, wide, 0.3), cframe = CFrame.new(opening.Position) * cf.Rotation, transparency = 1, collide = false, shadow = false, parent = model })
	Kit.light(face, colour, 16, 1)
	Kit.drift(face, colour, 6, 1.2, 0.35)
	model.Parent = parent
	return face
end

-- Builds a portal standing at `cf` (its base), opening towards cf's look direction. Returns the
-- face: an invisible flat part over the opening (Kit.trigger puts the walk-in trigger on it).
function Portal.build(cf, colour, parent, title, subtitle, Kit)
	local mine = design()
	if mine then
		local face = fromDesign(mine, cf, colour, parent, title, subtitle, Kit)
		if face then
			return face
		end
	end
	return require(script.Parent.PortalShape).build(cf, colour, parent, title, subtitle, Kit, flowOn)
end

return Portal

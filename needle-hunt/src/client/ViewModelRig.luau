-- Builds the first-person view's parts and moves them: both forearms and sleeves
-- (shared/FirstPerson), the cuffs and the hands' boxes (shared/FirstPersonRig) and the needle
-- (shared/NeedleLook, at the size the grip rule gives), each at the place client/ViewModelPose
-- works out. Every part is anchored and can't be touched, hit by a ray or cast a shadow, and one
-- workspace:BulkMoveTo a frame moves the lot. dev/preview/viewmodel.html draws the same parts.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FP = require(Shared:WaitForChild("FirstPerson"))
local Rig = require(Shared:WaitForChild("FirstPersonRig"))
local Needles = require(Shared:WaitForChild("Needles"))
local NeedleLook = require(Shared:WaitForChild("NeedleLook"))
local Pose = require(script.Parent.ViewModelPose)

local ViewModelRig = {}
-- which of ViewModelPose.frames' places each side's parts hang from
local SIDES = {
	{ arm = "right", cuff = "endRight", hand = "handRight", sign = 1 },
	{ arm = "left", cuff = "endLeft", hand = "handLeft", sign = -1 },
}

local function v3(t)
	return Vector3.new(t[1], t[2], t[3])
end

local function rgb(c)
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function skinColour(character)
	local colours = character:FindFirstChildOfClass("BodyColors")
	if colours then
		return colours.RightArmColor3
	end
	local arm = character:FindFirstChild("RightLowerArm") or character:FindFirstChild("Right Arm")
	return if arm then arm.Color else rgb(Rig.look.skin)
end

-- A box's colour: "skin", "sleeve" or { r, g, b }, times its shade.
local function colourOf(def, skin)
	local base = if def.colour == "sleeve" then rgb(FP.arm.sleeveColour) elseif type(def.colour) == "table" then rgb(def.colour) else skin
	local k = def.shade or 1
	return Color3.new(math.min(base.R * k, 1), math.min(base.G * k, 1), math.min(base.B * k, 1))
end

local function ghost(part) -- seen and nothing else
	part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = true, false, false, false, false
end

-- One part of the view: it hangs from `frame` (a name in ViewModelPose.frames) at `offset`.
local function add(view, part, frame, offset)
	local item = { part = part, frame = frame, offset = offset }
	table.insert(view.items, item)
	table.insert(view.parts, part)
	return item
end

local function block(view, frame, offset, size, colour, material, shape)
	local p = Instance.new("Part")
	ghost(p)
	if shape then
		p.Shape = Enum.PartType[shape]
	end
	p.Size, p.Color, p.Material = size, colour, material
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = view.model
	return add(view, p, frame, offset)
end

local function arms(view, skin)
	local size, sleeve, wide = v3(FP.arm.size), math.min(FP.arm.sleeve, 0.98), Rig.look.sleeveWidth
	local skinMaterial, sleeveMaterial = Enum.Material[Rig.look.skinMaterial], Enum.Material[Rig.look.sleeveMaterial]
	for _, side in ipairs(SIDES) do
		block(view, side.arm, CFrame.identity, size, skin, skinMaterial)
		if sleeve > 0.01 then -- from the elbow end down, a touch proud of the arm
			block(view, side.arm, CFrame.new(0, size.Y / 2 - size.Y * sleeve / 2 + 0.001, 0), Vector3.new(size.X * wide, size.Y * sleeve, size.Z * wide), rgb(FP.arm.sleeveColour), sleeveMaterial)
		end
		local open = if side.sign == 1 then 0 else Rig.left.open
		for _, set in ipairs({ { boxes = Rig.cuff, frame = side.cuff }, { boxes = Rig.hand, frame = side.hand } }) do
			for _, def in ipairs(set.boxes) do
				local item = block(view, set.frame, Pose.box(def, open, side.sign), v3(def.size), colourOf(def, skin), if def.colour == "sleeve" then sleeveMaterial else skinMaterial, def.shape)
				if side.sign == 1 and def.open then -- the right hand's boxes that open when the needle is away
					item.def = def
					table.insert(view.fingers, item)
				end
			end
		end
	end
end

local function needle(view, typeId, skinId)
	local model, back, front = Pose.fitNeedle(FP, Rig, function(scale)
		local ok, built = pcall(NeedleLook.build, typeId, skinId, scale, FP.needleLook.fat)
		return if ok then built else NeedleLook.build("sewing", skinId, scale, FP.needleLook.fat) -- never an empty hand
	end)
	view.needle = { back = back, front = front }
	local pivot = model:GetPivot()
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			ghost(d)
			add(view, d, "needle", pivot:ToObjectSpace(d.CFrame))
			if d.Name ~= "Root" then
				table.insert(view.needleParts, d)
			end
		elseif d:IsA("ParticleEmitter") or d:IsA("Light") then -- an Heirloom's aura, sparkles, a glow: they stay with the hand
			if d:IsA("ParticleEmitter") then
				d.LockedToPart = true
			end
			table.insert(view.effects, d)
		end
	end
	model.Parent = view.model
end

-- The whole view for a character holding the needle `key` ("type:skin"), under the camera.
function ViewModelRig.build(character, key)
	local typeId, skinId = Needles.split(key)
	local model = Instance.new("Model")
	model.Name = "NeedleViewModel"
	local view = { model = model, key = key, items = {}, parts = {}, cframes = {}, fingers = {}, open = 0, needleParts = {}, effects = {}, shown = true }
	arms(view, skinColour(character))
	needle(view, typeId or "sewing", skinId or "steel")
	for _, part in ipairs(view.parts) do -- the whole view is drawn small and close (FirstPersonRig.view.scale)
		part.Size *= Rig.view.scale
	end
	model.Parent = workspace.CurrentCamera
	return view
end

-- Puts every part in its place for this frame. camera: the camera's CFrame; fit: the field of
-- view's fit; frames: ViewModelPose.frames'; open: how open the right hand is (0..1). Everything
-- is shrunk towards the camera by FirstPersonRig.view.scale: it looks the same on screen, but sits
-- close enough that it doesn't reach into walls.
function ViewModelRig.move(view, camera, fit, frames, open)
	if open ~= view.open then
		view.open = open
		for _, item in ipairs(view.fingers) do
			item.offset = Pose.box(item.def, open, 1)
		end
	end
	local at = {}
	for name, frame in pairs(frames) do
		at[name] = fit * frame
	end
	local cframes, scale = view.cframes, Rig.view.scale
	for i, item in ipairs(view.items) do
		local cf = at[item.frame] * item.offset
		cframes[i] = camera * (cf.Rotation + cf.Position * scale)
	end
	workspace:BulkMoveTo(view.parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
end

-- The needle in the hand, or not (thrown: the hand is empty until it's back).
function ViewModelRig.showNeedle(view, shown)
	if view.shown == shown then
		return
	end
	view.shown = shown
	for _, p in ipairs(view.needleParts) do
		p.LocalTransparencyModifier = if shown then 0 else 1
	end
	for _, e in ipairs(view.effects) do
		e.Enabled = shown
	end
end

return ViewModelRig

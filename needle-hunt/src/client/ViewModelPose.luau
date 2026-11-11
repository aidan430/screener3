-- The first-person view's placement maths and nothing else: where the arms, the hands' boxes and
-- the needle sit in front of the camera, from shared/FirstPerson and shared/FirstPersonRig. No
-- Instances are made or moved here (client/ViewModelRig does that), so the preview page can mirror
-- it line for line (dev/preview/viewmodel_pose.js) and dev/preview/viewmodel_data.py runs this very
-- file outside Roblox to check the mirror. Keep it to plain maths on tables and CFrames.
--   camera space: +X right, +Y up, -Z ahead (studs). Rows of six are { x, y, z, rx, ry, rz }:
--   studs, then degrees in CFrame.Angles order, added to a pose's pos and rot.
local Pose = {}

local PARTS = { "right", "left", "needle", "wrist" }
local ZERO = { 0, 0, 0, 0, 0, 0 }
local SKIP = { Root = true, Aura = true, AuraShell = true } -- parts of a needle that aren't the needle

local function at(pos, rot, side)
	return CFrame.new(pos[1] * side, pos[2], pos[3]) * CFrame.Angles(math.rad(rot[1]), math.rad(rot[2]) * side, math.rad(rot[3]) * side)
end

-- A pose ({ pos, rot }) moved by a row of six: pos + its first three, rot + its last three.
function Pose.place(base, off)
	return CFrame.new(base.pos[1] + off[1], base.pos[2] + off[2], base.pos[3] + off[3])
		* CFrame.Angles(math.rad(base.rot[1] + off[4]), math.rad(base.rot[2] + off[5]), math.rad(base.rot[3] + off[6]))
end

-- Every animation by name, from a list of anims tables (a later table wins a name).
function Pose.merge(sources)
	local anims = {}
	for _, source in ipairs(sources) do
		for name, anim in pairs(source) do
			anims[name] = anim
		end
	end
	return anims
end

-- The rows at time t of an animation: between the two keys around t, eased (as the rig tool does).
function Pose.sample(anim, t)
	local keys = anim.keys
	local a, b = keys[1], keys[#keys]
	for i = 1, #keys - 1 do
		if t >= keys[i].t and t <= keys[i + 1].t then
			a, b = keys[i], keys[i + 1]
			break
		end
	end
	local f = if b.t > a.t then math.clamp((t - a.t) / (b.t - a.t), 0, 1) else 0
	f = f * f * (3 - 2 * f)
	local out = {}
	for _, part in ipairs(PARTS) do
		local from, to, row = a[part], b[part], { 0, 0, 0, 0, 0, 0 }
		if from and to then
			for i = 1, 6 do
				row[i] = from[i] + (to[i] - from[i]) * f
			end
		end
		out[part] = row
	end
	return out
end

local function add(off, layer, weight)
	if not layer or weight == 0 then
		return
	end
	for _, part in ipairs(PARTS) do
		local row, into = layer[part], off[part]
		if row then
			for i = 1, 6 do
				into[i] += row[i] * weight
			end
		end
	end
end

-- Everything that moves the hold pose this frame, as one set of rows: the animation playing
-- (already sampled, or nil) plus each of FirstPersonRig.motion's layers times its weight.
--   w.breath -1..1 | w.step -1..1 and w.dip 0..1 (the walk; times FirstPerson.motion.bob) |
--   w.swayX, w.swayY studs | w.land, w.air, w.away, w.wall, w.charge, w.guard 0..1
function Pose.offsets(FP, Rig, playing, w)
	local off = { right = { 0, 0, 0, 0, 0, 0 }, left = { 0, 0, 0, 0, 0, 0 }, needle = { 0, 0, 0, 0, 0, 0 }, wrist = { 0, 0, 0, 0, 0, 0 } }
	local M = Rig.motion
	add(off, playing, 1)
	add(off, M.breathe, w.breath)
	add(off, M.walk.step, w.step * FP.motion.bob)
	add(off, M.walk.dip, w.dip * FP.motion.bob)
	add(off, M.turn.yaw, w.swayX)
	add(off, M.turn.pitch, w.swayY)
	add(off, M.land, w.land)
	add(off, M.air, w.air)
	add(off, M.away, w.away)
	add(off, M.wall, w.wall)
	add(off, M.charge, w.charge or 0)
	add(off, M.guard, w.guard or 0)
	return off
end

-- The walk's two weights at a point in the stride (radians), by how much you're walking (0..1).
function Pose.walk(phase, amount)
	return math.sin(phase) * amount, math.abs(math.cos(phase)) * amount
end

-- The landing dip `since` seconds after touching down: in over land.time, then easing away.
function Pose.landing(Rig, since, strength)
	local x = math.max(since, 0) / Rig.motion.land.time
	return strength * x * math.exp(1 - x)
end

-- How far into the wall pose (0..1): `reach` is how far the needle's point is along the ray to
-- it, `distance` how far along that ray a wall is (nil: none).
function Pose.wall(Rig, reach, distance)
	local W = Rig.motion.wall
	if not distance then
		return 0
	end
	return math.clamp((reach + W.margin - distance) / math.max(reach + W.margin - W.near, 0.01), 0, 1)
end

-- A value eased towards a target at `rate` a second, the same whatever the frame rate.
function Pose.ease(value, target, rate, dt)
	return value + (target - value) * (1 - math.exp(-rate * dt))
end

-- A built needle's back and front ends along its own X (the eye end and the point), from its
-- parts' boxes: NeedleLook builds every needle along +X, whatever its shape.
function Pose.measure(model)
	local pivot = model:GetPivot()
	local back, front = math.huge, -math.huge
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and not SKIP[p.Name] then
			local cf = pivot:ToObjectSpace(p.CFrame)
			local x, y, z = cf.XVector, cf.YVector, cf.ZVector
			local half = (math.abs(x.X) * p.Size.X + math.abs(y.X) * p.Size.Y + math.abs(z.X) * p.Size.Z) / 2
			back, front = math.min(back, cf.X - half), math.max(front, cf.X + half)
		end
	end
	return back, front
end

-- What to multiply a needle's size by so its length lands within FirstPersonRig.grip's limits
-- (a pin isn't a speck, a knitting needle doesn't leave the screen).
function Pose.lengthScale(Rig, back, front)
	local length = math.max(front - back, 0.01)
	return math.clamp(length, Rig.grip.minLength, Rig.grip.maxLength) / length
end

-- The needle at the size the grip rule gives: build(scale) makes one at a scale (NeedleLook's);
-- it is measured, and made again at the right scale if its length is out of bounds.
-- Returns the model, its back and front ends, and the scale it ended up at.
function Pose.fitNeedle(FP, Rig, build)
	local scale = FP.needleLook.scale
	local model = build(scale)
	local back, front = Pose.measure(model)
	local k = Pose.lengthScale(Rig, back, front)
	if math.abs(k - 1) > 0.001 then
		model:Destroy()
		scale *= k
		model = build(scale)
		back, front = Pose.measure(model)
	end
	return model, back, front, scale
end

-- Where everything is in camera space, at the reference field of view:
--   right, left: each forearm's centre (FirstPerson.pose);
--   endRight, endLeft: the forearm's hand end, same turn (the cuff's boxes hang here);
--   handRight, handLeft: the hand, bent at the wrist (FirstPersonRig.wrist; the hand's boxes hang here);
--   needle: the needle's own origin, set so the point grip.back along from its back end sits at
--   FirstPerson.pose.needle in the right hand.
-- needle: { back, front } as measured.
function Pose.frames(FP, Rig, off, needle)
	local half = FP.arm.size[2] / 2
	local right, left = Pose.place(FP.pose.right, off.right), Pose.place(FP.pose.left, off.left)
	local endRight, endLeft = right * CFrame.new(0, -half, 0), left * CFrame.new(0, -half, 0)
	local handRight, handLeft = endRight * Pose.place(Rig.wrist, off.wrist), endLeft * at(Rig.wrist.pos, Rig.wrist.rot, -1)
	local held = handRight * Pose.place(FP.pose.needle, off.needle) * CFrame.new(-(needle.back + Rig.grip.back), 0, 0)
	return { right = right, left = left, endRight = endRight, endLeft = endLeft, handRight = handRight, handLeft = handLeft, needle = held }
end

-- One of the hand's (or the cuff's) boxes in its frame: its gripping place, eased to its open
-- one by `open` (0..1; pos and rot go straight from one to the other). side: 1 the right hand,
-- -1 the left, which is the right hand's mirror image (x, and the turns about y and z, flip).
function Pose.box(part, open, side)
	local pos, rot = part.pos, part.rot or ZERO
	if part.open and open > 0 then
		local toPos, toRot = part.open.pos or pos, part.open.rot or rot
		pos = { pos[1] + (toPos[1] - pos[1]) * open, pos[2] + (toPos[2] - pos[2]) * open, pos[3] + (toPos[3] - pos[3]) * open }
		rot = { rot[1] + (toRot[1] - rot[1]) * open, rot[2] + (toRot[2] - rot[2]) * open, rot[3] + (toRot[3] - rot[3]) * open }
	end
	return at(pos, rot, side)
end

-- The same framing at any field of view: the whole view slides along the camera's axis, nearer
-- for a wide view and further for a narrow one. On screen that is exactly a view scaled by
-- tan(fov / 2) / tan(refFov / 2) about a point view.pivot studs ahead (so offsets scale with
-- tan(fov / 2)), but nothing is resized and a wide view doesn't reach further into walls.
function Pose.fit(Rig, fov)
	local k = math.tan(math.rad(fov) / 2) / math.tan(math.rad(Rig.view.refFov) / 2)
	return CFrame.new(0, 0, Rig.view.pivot * (1 - 1 / k))
end

Pose.ZERO = ZERO

return Pose

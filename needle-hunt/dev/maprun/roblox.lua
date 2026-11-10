-- Just enough of Roblox, in plain Lua, to run the game's map builders outside Studio
-- (dev/maprun/run_map.py): Vector3, CFrame, Color3, Random, Enum, Instance (parts, models,
-- folders and whatever else is made), a workspace with Raycast and GetPartBoundsInBox over the
-- parts built so far, and a Terrain that records what is filled. Nothing is drawn here: run_map
-- reads the parts back out and the preview page draws them.
local R = {}

-- Vector3 ------------------------------------------------------------------------------------
local V = {}
V.__index = function(v, k)
	if k == "X" then return v[1] elseif k == "Y" then return v[2] elseif k == "Z" then return v[3]
	elseif k == "Magnitude" then return math.sqrt(v[1] ^ 2 + v[2] ^ 2 + v[3] ^ 2)
	elseif k == "Unit" then local m = math.sqrt(v[1] ^ 2 + v[2] ^ 2 + v[3] ^ 2); return m > 0 and R.v3(v[1] / m, v[2] / m, v[3] / m) or R.v3(0, 0, 0)
	end
	return V[k]
end
function R.v3(x, y, z) return setmetatable({ x or 0, y or 0, z or 0, __t = "Vector3" }, V) end
V.__add = function(a, b) return R.v3(a[1] + b[1], a[2] + b[2], a[3] + b[3]) end
V.__sub = function(a, b) return R.v3(a[1] - b[1], a[2] - b[2], a[3] - b[3]) end
V.__unm = function(a) return R.v3(-a[1], -a[2], -a[3]) end
V.__mul = function(a, b)
	if type(a) == "number" then return R.v3(a * b[1], a * b[2], a * b[3]) end
	if type(b) == "number" then return R.v3(a[1] * b, a[2] * b, a[3] * b) end
	return R.v3(a[1] * b[1], a[2] * b[2], a[3] * b[3])
end
V.__div = function(a, b)
	if type(b) == "number" then return R.v3(a[1] / b, a[2] / b, a[3] / b) end
	return R.v3(a[1] / b[1], a[2] / b[2], a[3] / b[3])
end
V.__eq = function(a, b) return a[1] == b[1] and a[2] == b[2] and a[3] == b[3] end
function V.Lerp(a, b, t) return a + (b - a) * t end
function V.Dot(a, b) return a[1] * b[1] + a[2] * b[2] + a[3] * b[3] end
function V.Cross(a, b) return R.v3(a[2] * b[3] - a[3] * b[2], a[3] * b[1] - a[1] * b[3], a[1] * b[2] - a[2] * b[1]) end
Vector3 = { new = R.v3, zero = R.v3(0, 0, 0), one = R.v3(1, 1, 1), xAxis = R.v3(1, 0, 0), yAxis = R.v3(0, 1, 0), zAxis = R.v3(0, 0, 1) }
Vector2 = { new = function(x, y) return { X = x, Y = y } end, zero = { X = 0, Y = 0 } }

-- CFrame: a position and a 3x3 rotation, row-major ------------------------------------------
local C = {}
local function cf(p, m) return setmetatable({ p = p, m = m, __t = "CFrame" }, C) end
local I = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }
local function mm(a, b) -- 3x3 times 3x3
	local r = {}
	for i = 0, 2 do for j = 0, 2 do
		r[i * 3 + j + 1] = a[i * 3 + 1] * b[j + 1] + a[i * 3 + 2] * b[3 + j + 1] + a[i * 3 + 3] * b[6 + j + 1]
	end end
	return r
end
local function mv(m, v) return R.v3(m[1] * v[1] + m[2] * v[2] + m[3] * v[3], m[4] * v[1] + m[5] * v[2] + m[6] * v[3], m[7] * v[1] + m[8] * v[2] + m[9] * v[3]) end
C.__index = function(c, k)
	if k == "Position" then return c.p
	elseif k == "X" then return c.p[1] elseif k == "Y" then return c.p[2] elseif k == "Z" then return c.p[3]
	elseif k == "Rotation" then return cf(R.v3(0, 0, 0), c.m)
	elseif k == "LookVector" then return R.v3(-c.m[3], -c.m[6], -c.m[9])
	elseif k == "RightVector" then return R.v3(c.m[1], c.m[4], c.m[7])
	elseif k == "UpVector" then return R.v3(c.m[2], c.m[5], c.m[8])
	end
	return C[k]
end
C.__mul = function(a, b)
	if getmetatable(b) == V then return a.p + mv(a.m, b) end
	return cf(a.p + mv(a.m, b.p), mm(a.m, b.m))
end
C.__add = function(a, v) return cf(a.p + v, a.m) end
C.__sub = function(a, v) return cf(a.p - v, a.m) end
function C.Inverse(c)
	local t = { c.m[1], c.m[4], c.m[7], c.m[2], c.m[5], c.m[8], c.m[3], c.m[6], c.m[9] }
	return cf(-mv(t, c.p), t)
end
function C.PointToWorldSpace(c, v) return c * v end
function C.ToWorldSpace(c, o) return c * o end
function C.ToObjectSpace(c, o) return c:Inverse() * o end
local function rx(a) local s, k = math.sin(a), math.cos(a); return { 1, 0, 0, 0, k, -s, 0, s, k } end
local function ry(a) local s, k = math.sin(a), math.cos(a); return { k, 0, s, 0, 1, 0, -s, 0, k } end
local function rz(a) local s, k = math.sin(a), math.cos(a); return { k, -s, 0, s, k, 0, 0, 0, 1 } end
CFrame = {}
function CFrame.new(x, y, z)
	if x == nil then return cf(R.v3(0, 0, 0), I) end
	if type(x) == "table" then
		if y and type(y) == "table" then return CFrame.lookAt(x, y) end
		return cf(R.v3(x[1], x[2], x[3]), I)
	end
	return cf(R.v3(x, y, z), I)
end
function CFrame.Angles(a, b, c) return cf(R.v3(0, 0, 0), mm(mm(rx(a), ry(b)), rz(c))) end
CFrame.fromEulerAnglesXYZ = CFrame.Angles
function CFrame.lookAt(at, target, up)
	up = up or R.v3(0, 1, 0)
	local back = (at - target).Unit -- +Z points away from the target
	local right = up:Cross(back).Unit
	if right.Magnitude < 1e-6 then right = R.v3(1, 0, 0) end
	local upv = back:Cross(right)
	return cf(R.v3(at[1], at[2], at[3]), { right[1], upv[1], back[1], right[2], upv[2], back[2], right[3], upv[3], back[3] })
end
CFrame.identity = cf(R.v3(0, 0, 0), I)

-- Color3, Random, Enum, NumberRange... -------------------------------------------------------
local function col(r, g, b) return { R = r, G = g, B = b, __t = "Color3", Lerp = function(a, o, t) return col(a.R + (o.R - a.R) * t, a.G + (o.G - a.G) * t, a.B + (o.B - a.B) * t) end } end
Color3 = {
	new = function(r, g, b) return col(r or 0, g or 0, b or 0) end,
	fromRGB = function(r, g, b) return col((r or 0) / 255, (g or 0) / 255, (b or 0) / 255) end,
	fromHSV = function(h, s, v) local i = math.floor(h * 6); local f = h * 6 - i; local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s); local m = ({ { v, t, p }, { q, v, p }, { p, v, t }, { p, q, v }, { t, p, v }, { v, p, q } })[i % 6 + 1]; return col(m[1], m[2], m[3]) end,
}
Random = { new = function(seed)
	local a = math.floor(seed or 1) % 2147483646 + 1
	local function nxt() a = (a * 48271) % 2147483647; return a / 2147483647 end
	return { NextNumber = function(_, lo, hi) local x = nxt(); if lo == nil then return x end return lo + (hi - lo) * x end,
		NextInteger = function(_, lo, hi) return lo + math.floor(nxt() * (hi - lo + 1)) end }
end }
Enum = setmetatable({}, { __index = function(_, kind) return setmetatable({}, { __index = function(_, name) return name end }) end })
NumberRange = { new = function(a, b) return { a, b or a } end }
NumberSequence = { new = function(...) return { ... } end }
NumberSequenceKeypoint = { new = function(...) return { ... } end }
ColorSequence = { new = function(...) return { ... } end }
TweenInfo = { new = function(...) return { ... } end }
UDim2 = { new = function(...) return { ... } end, fromScale = function(...) return { ... } end, fromOffset = function(...) return { ... } end }
UDim = { new = function(...) return { ... } end }
function typeof(v)
	if type(v) == "table" and v.__t then return v.__t end
	return type(v)
end
function math.clamp(x, lo, hi) return math.max(lo, math.min(hi, x)) end
function math.sign(x) return x > 0 and 1 or x < 0 and -1 or 0 end
function math.round(x) return math.floor(x + 0.5) end
function table.clone(t) local o = {}; for k, v in pairs(t) do o[k] = v end; return o end
function table.find(t, v) for i, x in ipairs(t) do if x == v then return i end end end
table.unpack = table.unpack or unpack
function __if(c, a, b) if c then return a() end return b() end
local signal = { Connect = function() return { Disconnect = function() end } end, Wait = function() end }
task = { spawn = function(f, ...) end, delay = function() end, wait = function() return 0 end, defer = function() end }
function wait() return 0 end

-- Instances ----------------------------------------------------------------------------------
local INST = {}
R.parts = {}
local DEFAULTS = {
	Part = { Size = R.v3(4, 1, 2), Shape = "Block", Material = "Plastic", Transparency = 0, Anchored = false, CanCollide = true, CanQuery = true, CanTouch = true, Color = Color3.fromRGB(163, 162, 165) },
	SpawnLocation = { Size = R.v3(12, 1, 12), Shape = "Block", Material = "Plastic", Transparency = 0, CanCollide = true, CanQuery = true, Color = Color3.fromRGB(163, 162, 165) },
	TrussPart = { Size = R.v3(2, 2, 2), Shape = "Block", Material = "Metal", Transparency = 0, CanCollide = true, CanQuery = true, Color = Color3.fromRGB(163, 162, 165) },
	Seat = { Size = R.v3(2, 1, 2), Shape = "Block", Material = "Plastic", Transparency = 0, CanCollide = true, CanQuery = true, Color = Color3.fromRGB(163, 162, 165) },
}
local PARTLIKE = { Part = true, SpawnLocation = true, Seat = true, WedgePart = true, MeshPart = true, TrussPart = true }
local function inst(class)
	local o = { __t = "Instance", __class = class, __props = {}, __kids = {}, __attrs = {} }
	for k, v in pairs(DEFAULTS[class] or {}) do o.__props[k] = v end
	o.__props.Name = class
	if class == "Part" then o.__props.CFrame = CFrame.new() end
	return setmetatable(o, INST)
end
INST.__index = function(o, k)
	local v = o.__props[k]
	if v ~= nil then return v end
	if k == "Position" and o.__props.CFrame then return o.__props.CFrame.p end
	if k == "ClassName" then return o.__class end
	if INST[k] then return INST[k] end
	if k == "Triggered" or k == "Touched" or k == "Changed" or k == "Completed" or k:match("Changed$") or k:match("Added$") then return signal end
	for _, c in ipairs(o.__kids) do if c.__props.Name == k then return c end end
	return nil
end
INST.__newindex = function(o, k, v)
	if k == "Parent" then
		local old = o.__props.Parent
		if old then for i, c in ipairs(old.__kids) do if c == o then table.remove(old.__kids, i); break end end end
		if v then table.insert(v.__kids, o) end
	elseif k == "Position" then
		local c = o.__props.CFrame or CFrame.new()
		v = cf(v, c.m); k = "CFrame"
	end
	o.__props[k] = v
end
function INST.IsA(o, class)
	if class == "BasePart" then return PARTLIKE[o.__class] == true end
	if class == "Instance" then return true end
	return o.__class == class
end
function INST.GetChildren(o) return table.clone(o.__kids) end
function INST.GetDescendants(o)
	local out = {}
	local function walk(x) for _, c in ipairs(x.__kids) do table.insert(out, c); walk(c) end end
	walk(o)
	return out
end
function INST.FindFirstChild(o, name, deep)
	for _, c in ipairs(deep and o:GetDescendants() or o.__kids) do if c.__props.Name == name then return c end end
end
function INST.FindFirstChildOfClass(o, class) for _, c in ipairs(o.__kids) do if c.__class == class then return c end end end
function INST.FindFirstChildWhichIsA(o, class, deep) for _, c in ipairs(deep and o:GetDescendants() or o.__kids) do if c:IsA(class) then return c end end end
function INST.FindFirstAncestorOfClass(o, class) local p = o.__props.Parent; while p do if p.__class == class then return p end; p = p.__props.Parent end end
function INST.WaitForChild(o, name) return o.__props[name] or o:FindFirstChild(name) end
function INST.SetAttribute(o, k, v) o.__attrs[k] = v end
function INST.GetAttribute(o, k) return o.__attrs[k] end
function INST.ClearAllChildren(o) for _, c in ipairs(table.clone(o.__kids)) do c.Parent = nil end end
function INST.Destroy(o) o.Parent = nil; o.__dead = true end
function INST.Clone(o)
	local c = inst(o.__class)
	for k, v in pairs(o.__props) do if k ~= "Parent" then c.__props[k] = v end end
	for k, v in pairs(o.__attrs) do c.__attrs[k] = v end
	for _, kid in ipairs(o.__kids) do kid:Clone().Parent = c end
	return c
end
local function partsOf(o)
	local list = {}
	if o:IsA("BasePart") then table.insert(list, o) end
	for _, d in ipairs(o:GetDescendants()) do if d:IsA("BasePart") then table.insert(list, d) end end
	return list
end
local function aabb(p) -- a part's world-space box
	local s, c = p.__props.Size, p.__props.CFrame
	local lo, hi = R.v3(math.huge, math.huge, math.huge), R.v3(-math.huge, -math.huge, -math.huge)
	for _, dx in ipairs({ -0.5, 0.5 }) do for _, dy in ipairs({ -0.5, 0.5 }) do for _, dz in ipairs({ -0.5, 0.5 }) do
		local w = c * R.v3(s[1] * dx, s[2] * dy, s[3] * dz)
		lo = R.v3(math.min(lo[1], w[1]), math.min(lo[2], w[2]), math.min(lo[3], w[3]))
		hi = R.v3(math.max(hi[1], w[1]), math.max(hi[2], w[2]), math.max(hi[3], w[3]))
	end end end
	return lo, hi
end
function INST.GetBoundingBox(o)
	local lo, hi = R.v3(math.huge, math.huge, math.huge), R.v3(-math.huge, -math.huge, -math.huge)
	for _, p in ipairs(partsOf(o)) do
		local a, b = aabb(p)
		lo = R.v3(math.min(lo[1], a[1]), math.min(lo[2], a[2]), math.min(lo[3], a[3]))
		hi = R.v3(math.max(hi[1], b[1]), math.max(hi[2], b[2]), math.max(hi[3], b[3]))
	end
	return CFrame.new((lo + hi) / 2), hi - lo
end
function INST.GetPivot(o)
	if o.__props.PrimaryPart then return o.__props.PrimaryPart.__props.CFrame end
	if o.__props.CFrame then return o.__props.CFrame end
	return (o:GetBoundingBox())
end
function INST.PivotTo(o, target)
	local delta = target * o:GetPivot():Inverse()
	for _, p in ipairs(partsOf(o)) do p.__props.CFrame = delta * p.__props.CFrame end
end
function INST.GetScale() return 1 end
function INST.ScaleTo() end
function INST.Play() end
function INST.Emit() end
function INST.FireClient() end
function INST.FireAllClients() end
Instance = { new = function(class, parent) local o = inst(class); if parent then o.Parent = parent end; return o end }

-- workspace, Terrain, services ---------------------------------------------------------------
workspace = inst("Workspace")
workspace.__props.Name = "Workspace"
local terrain = inst("Terrain")
terrain.Parent = workspace
R.terrain = {}
function terrain.FillBall(_, centre, radius, material) table.insert(R.terrain, { kind = "ball", p = centre, r = radius, material = material }) end
function terrain.FillCylinder(_, c, height, radius, material) table.insert(R.terrain, { kind = "cylinder", cf = c, h = height, r = radius, material = material }) end
function terrain.FillBlock(_, c, size, material) table.insert(R.terrain, { kind = "block", cf = c, size = size, material = material }) end
function terrain.SetMaterialColor(_, material, colour) R.terrain.colours = R.terrain.colours or {}; R.terrain.colours[material] = colour end
function terrain.Clear() end
function terrain.FillRegion() end
workspace.__props.Terrain = terrain
function workspace.GetServerTimeNow() return 0 end

local function included(params)
	local set = {}
	for _, root in ipairs(params and params.FilterDescendantsInstances or {}) do
		for _, p in ipairs(partsOf(root)) do set[p] = true end
	end
	return set
end
RaycastParams = { new = function() return {} end }
OverlapParams = { new = function() return {} end }
function workspace.Raycast(_, origin, dir, params) -- a ray against each part's box, in its own space
	local best
	local allow = included(params)
	for p in pairs(allow) do
		if p.__props.CanQuery ~= false and not p.__dead then
			local c, s = p.__props.CFrame, p.__props.Size
			local inv = c:Inverse()
			local o, d = inv * origin, inv.m and R.v3(0, 0, 0) or nil
			d = mv(inv.m, dir)
			local tmin, tmax = 0, 1
			local ok = true
			for i = 1, 3 do
				local h = s[i] / 2
				if math.abs(d[i]) < 1e-9 then
					if o[i] < -h or o[i] > h then ok = false end
				else
					local t1, t2 = (-h - o[i]) / d[i], (h - o[i]) / d[i]
					if t1 > t2 then t1, t2 = t2, t1 end
					tmin, tmax = math.max(tmin, t1), math.min(tmax, t2)
					if tmin > tmax then ok = false end
				end
			end
			if ok and (not best or tmin < best.t) then best = { t = tmin, part = p } end
		end
	end
	if not best then return nil end
	local pos = origin + dir * best.t
	return { Position = pos, Distance = dir.Magnitude * best.t, Instance = best.part, Normal = R.v3(0, 1, 0) }
end
function workspace.GetPartBoundsInBox(_, c, size, params)
	local lo, hi = c.p - size / 2, c.p + size / 2
	local out = {}
	for p in pairs(included(params)) do
		if not p.__dead then
			local a, b = aabb(p)
			if a[1] < hi[1] and b[1] > lo[1] and a[2] < hi[2] and b[2] > lo[2] and a[3] < hi[3] and b[3] > lo[3] then table.insert(out, p) end
		end
	end
	return out
end

local services = {}
function R.service(name)
	if not services[name] then
		local s = inst(name)
		s.__props.Name = name
		if name == "TweenService" then s.__props.Create = function() return { Play = function() end, Completed = signal, Cancel = function() end } end end
		if name == "RunService" then s.__props.IsStudio = function() return false end; s.__props.Heartbeat = signal end
		if name == "InsertService" then s.__props.LoadAsset = function() error("no assets outside Roblox") end end
		services[name] = s
	end
	return services[name]
end
game = { GetService = function(_, name) return R.service(name) end, Workspace = workspace }
setmetatable(game, { __index = function(_, k) return R.service(k) end })

-- the parts built, for the preview ------------------------------------------------------------
function R.collect(root)
	local out = {}
	for _, p in ipairs(partsOf(root)) do
		if not p.__dead then
			local c = p.__props.CFrame
			local light
			for _, k in ipairs(p.__kids) do
				if k.__class == "PointLight" or k.__class == "SpotLight" then
					local lc = k.__props.Color or Color3.new(1, 1, 1)
					light = { range = k.__props.Range or 8, color = { lc.R * 255, lc.G * 255, lc.B * 255 } }
				end
			end
			local pc = p.__props.Color
			table.insert(out, { name = p.__props.Name, shape = p.__props.Shape or "Block", size = { p.__props.Size[1], p.__props.Size[2], p.__props.Size[3] },
				pos = { c.p[1], c.p[2], c.p[3] }, rot = c.m, color = { pc.R * 255, pc.G * 255, pc.B * 255 }, material = p.__props.Material or "Plastic",
				transparency = p.__props.Transparency or 0, light = light })
		end
	end
	return out
end

return R

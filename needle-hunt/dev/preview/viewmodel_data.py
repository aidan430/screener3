"""The data for the first-person preview (dev/preview/viewmodel.html), read from the game itself.

    python3 needle-hunt/dev/preview/viewmodel_data.py [rigDir] [outFile] [type:skin ...]

rigDir holds FirstPerson.luau and FirstPersonRig.luau (default: needle-hunt/src/shared); a folder
with only an old FirstPerson.luau is drawn the old way (one box an arm, the needle by its middle).
Everything is run in Lua 5.4 with lupa (pip install lupa, or put it on PYTHONPATH), on dev/maprun's
stand-in for Roblox:
  - the two rig modules, as they are;
  - every needle asked for, built by the real shared/NeedleLook at the size the grip rule gives
    (client/ViewModelPose.fitNeedle), part by part;
  - the game's own placement maths (client/ViewModelPose.luau) on a spread of test poses: the page
    checks its JavaScript mirror (viewmodel_pose.js) against these before it draws anything;
  - the game's own view (client/ViewModel, ViewModelRig and ViewModelMotion) for a few seconds of
    frames with a stand-in player: walking, a jab, a throw and its catch. Nothing may error, and
    every part it builds (its size, colour and place in the hold) is kept for the page to check
    its drawing against.
Writes window.VM_DATA = { fp, rig, legacy, needles, parity, game } to outFile (default viewmodel_data.js).
"""
import json
import random
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(HERE.parent / "maprun"))
from luau2lua import convert  # noqa: E402
import lupa.lua54 as lupa  # noqa: E402

NEEDLES = ["pin:steel", "sewing:steel", "knitting:candycane", "woodsword:oak", "eyeofneedle:golden"]
# an old rig (no FirstPersonRig.luau): no hand, the needle held by its own middle, nothing extra moving
LEGACY = """return {
	view = { refFov = 70, pivot = 0 }, look = { skin = { 234, 184, 146 }, skinMaterial = "SmoothPlastic", sleeveMaterial = "Fabric" },
	wrist = { pos = { 0, 0, 0 }, rot = { 0, 0, 0 } }, cuff = {}, hand = {}, left = { open = 0 }, grip = { back = 0, minLength = 0, maxLength = 1e9 }, throw = { release = 0.2, wait = 0.5 },
	motion = { breathe = { speed = 1 }, walk = { least = 0.1, step = { right = { 0.5, 0, 0, 0, 0, 0 }, left = { 0.5, 0, 0, 0, 0, 0 } }, dip = { right = { 0, -1, 0, 0, 0, 0 }, left = { 0, -1, 0, 0, 0, 0 } }, rate = 8 },
		turn = { gain = -0.25, max = 0.25, rate = 12, yaw = { right = { 1, 0, 0, 0, 0, 0 }, left = { 1, 0, 0, 0, 0, 0 } }, pitch = {} },
		land = { time = 0.1, speed = 40, least = 0 }, air = { rate = 8 }, away = { rate = 8 }, wall = { margin = 0, near = 0.5, rateIn = 1, rateOut = 1 } },
	anims = {},
}"""
# what the stand-in lacks: a CFrame's three axes, and the few engine calls the view makes
EXTRA = """
local C = getmetatable(CFrame.new())
local index = C.__index
C.__index = function(c, k)
	if k == "XVector" then return Vector3.new(c.m[1], c.m[4], c.m[7])
	elseif k == "YVector" then return Vector3.new(c.m[2], c.m[5], c.m[8])
	elseif k == "ZVector" then return Vector3.new(c.m[3], c.m[6], c.m[9]) end
	return index(c, k)
end
function C.VectorToWorldSpace(c, v) return c * v - c.Position end
local I = getmetatable(Instance.new("Folder"))
function I.GetAttributeChangedSignal() return { Connect = function() end } end
rawset(Enum, "RenderPriority", { Camera = { Value = 200 } })
math.atan2 = math.atan2 or function(y, x) return math.atan(y, x) end
workspace.__props.Raycast = function() return nil end -- no walls here: the wall's maths is checked with the rest of ViewModelPose
workspace.__props.BulkMoveTo = function(_, parts, cframes) for i, p in ipairs(parts) do p.CFrame = cframes[i] end end
__R.service("RunService").__props.BindToRenderStep = function(_, _, _, step) __STEP = step end
"""
# The real client modules, run for a few seconds with a stand-in player in first person.
GAME = """
local camera = Instance.new("Camera"); camera.CFrame = CFrame.new(0, 5, 0); camera.FieldOfView = 70
workspace.__props.CurrentCamera = camera
local player = Instance.new("Player"); __R.service("Players").__props.LocalPlayer = player
local character = Instance.new("Model"); player.Character = character
local head = Instance.new("Part"); head.Name = "Head"; head.CFrame = camera.CFrame; head.Parent = character
local root = Instance.new("Part"); root.Name = "HumanoidRootPart"; root.AssemblyLinearVelocity = Vector3.new(0, 0, 0); root.Parent = character
local humanoid = Instance.new("Humanoid"); humanoid.FloorMaterial = "Grass"; humanoid.MoveDirection = Vector3.new(0, 0, 0); humanoid.Parent = character
local tool = Instance.new("Tool"); tool.Name = "Needle"; tool:SetAttribute("Key", __KEY); tool.Parent = character
local handle = Instance.new("Part"); handle.Name = "Handle"; handle.Parent = tool
local ViewModel = require(__SHARED.ViewModel)
ViewModel.start()
local log = { mode = player.CameraMode }
local function frames(n) for _ = 1, n do __STEP(1 / 60) end end
local function model() return camera:FindFirstChild("NeedleViewModel") end
frames(1)
log.hold = {}
local clock = os.clock
os.clock = function() return clock() + 100 end           -- past the equip: the hold, as the page draws it
frames(1)
for _, p in ipairs(model():GetDescendants()) do
	if p:IsA("BasePart") then
		local c = p.Color
		table.insert(log.hold, { name = p.Name, shape = p.Shape, size = { p.Size.X, p.Size.Y, p.Size.Z }, cf = __cf(p.CFrame), colour = { c.R * 255, c.G * 255, c.B * 255 },
			ghost = p.Anchored == true and p.CanCollide == false and p.CanQuery == false and p.CanTouch == false and p.CastShadow == false })
	end
end
log.toolHidden = handle.LocalTransparencyModifier == 1
humanoid.MoveDirection = Vector3.new(0, 0, -1); frames(20)   -- walking
humanoid.FloorMaterial = "Air"; root.AssemblyLinearVelocity = Vector3.new(0, -40, 0); frames(10)   -- a jump
humanoid.FloorMaterial = "Grass"; frames(10)                 -- and the landing
ViewModel.play("jab"); frames(8)
ViewModel.play("inspect"); frames(8)
player:SetAttribute("InRound", true)
local t0 = 200
os.clock = function() return clock() + t0 end
ViewModel.play("throw")
local function shaft() for _, p in ipairs(model():GetDescendants()) do if p:IsA("BasePart") and p.Parent ~= model() and p.Name ~= "Root" then return p end end end
frames(1); log.heldAtStart = shaft().LocalTransparencyModifier ~= 1
t0 = 200 + Rig.throw.release + 0.05; player:SetAttribute("NeedleAway", true); frames(1)
log.goneAfterRelease = shaft().LocalTransparencyModifier == 1
t0 = t0 + 1; player:SetAttribute("NeedleAway", nil); frames(2)
log.backAfterReturn = shaft().LocalTransparencyModifier ~= 1
camera.CFrame = CFrame.new(0, 5, 0) * CFrame.Angles(0, 0.4, 0); frames(5)   -- a turn
head.CFrame = CFrame.new(0, 5, 9); frames(1)                 -- third person: the view goes away
log.hiddenInThirdPerson = model() == nil
return log
"""


def runtime(rig_dir):
    lua = lupa.LuaRuntime(unpack_returned_tuples=True)
    lua.execute("package.path = ''")
    lua.globals().__R = lua.execute((HERE.parent / "maprun" / "roblox.lua").read_text())
    lua.execute(EXTRA)

    def source(name):
        for path in (rig_dir / (name + ".luau"), ROOT / "src" / "shared" / (name + ".luau"), ROOT / "src" / "client" / (name + ".luau")):
            if path.exists() and (path.parent == rig_dir or name not in ("FirstPerson", "FirstPersonRig")):
                return convert(path.read_text())
        return LEGACY if name == "FirstPersonRig" else None

    lua.globals().__source = source
    lua.execute("""
    local cache = {}
    __SHARED = setmetatable({}, { __index = function(f, k)
        if k == "WaitForChild" or k == "FindFirstChild" then return function(_, n) if __source(n) then return f[n] end return nil end end
        return { __module = k }
    end })
    __R.service("ReplicatedStorage").__props.Shared = __SHARED
    function require(ref)
        if cache[ref.__module] then return cache[ref.__module] end
        local code = __source(ref.__module)
        if not code then error("no module " .. ref.__module) end
        local env = setmetatable({ script = { Parent = __SHARED, Name = ref.__module } }, { __index = _G, __newindex = _G })
        local fn, err = load(code, "@" .. ref.__module, "t", env)
        if not fn then error(err) end
        cache[ref.__module] = fn()
        return cache[ref.__module]
    end
    FP, Rig, Pose = require(__SHARED.FirstPerson), require(__SHARED.FirstPersonRig), require(__SHARED.ViewModelPose)
    NeedleLook, Needles = require(__SHARED.NeedleLook), require(__SHARED.Needles)
    function __cf(c) return { c.p[1], c.p[2], c.p[3], c.m[1], c.m[2], c.m[3], c.m[4], c.m[5], c.m[6], c.m[7], c.m[8], c.m[9] } end
    """)
    return lua


def plain(value):
    """A Lua table as Python lists and dicts."""
    if lupa.lua_type(value) != "table":
        return value
    keys = list(value.keys())
    if keys and all(isinstance(k, int) for k in keys) and sorted(keys) == list(range(1, len(keys) + 1)):
        return [plain(value[i]) for i in range(1, len(keys) + 1)]
    return {str(k): plain(value[k]) for k in keys}


def needle(lua, key, legacy):
    type_id, skin_id = key.split(":")
    built = lua.execute(f"""
    local model, back, front = Pose.fitNeedle(FP, Rig, function(scale)
        local ok, m = pcall(NeedleLook.build, "{type_id}", "{skin_id}", scale, FP.needleLook.fat)
        if not ok then error("NeedleLook can't build {key}: " .. tostring(m)) end
        return m
    end)
    local t = Needles.type("{type_id}")
    return {{ parts = __R.collect(model), back = back, front = front, grade = t and t.grade or "classic" }}
    """)
    out = plain(built)
    if legacy:  # the old view held the needle by its model's own middle
        out["back"] = 0
    return out


def parity(lua, keys, cases=40):
    """Test poses and the game's own answers for them (client/ViewModelPose.luau, run here)."""
    rng = random.Random(7)
    names = sorted(plain(lua.eval("(function() local t = {} for n in pairs(Pose.merge({ FP.anims, Rig.anims })) do table.insert(t, n) end return t end)()")) or [])
    out = []
    for i in range(cases):
        w = {k: round(rng.uniform(lo, hi), 3) for k, (lo, hi) in dict(breath=(-1, 1), step=(-1, 1), dip=(0, 1), swayX=(-0.25, 0.25), swayY=(-0.25, 0.25), land=(0, 1), air=(0, 1), away=(0, 1), wall=(0, 1)).items()}
        if i == 0:
            w = {k: 0 for k in w}
        case = {"key": keys[i % len(keys)], "anim": rng.choice(names) if names and i % 3 else None, "frac": round(rng.random(), 3), "w": w,
                "open": round(rng.random(), 3), "fov": rng.choice([60, 70, 80, 90, 100]), "since": round(rng.uniform(0, 0.5), 3), "reach": round(rng.uniform(1, 3), 3), "distance": round(rng.uniform(0.3, 3), 3)}
        lua.globals().__case = lua.table_from({**case, "w": lua.table_from(w)})
        lua.globals().__needle = lua.table_from({k: v for k, v in NEEDLE_CACHE[case["key"]].items() if k in ("back", "front")})
        got = lua.execute("""
        local c, anims = __case, Pose.merge({ FP.anims, Rig.anims })
        local playing = c.anim and Pose.sample(anims[c.anim], anims[c.anim].length * c.frac) or nil
        local off = Pose.offsets(FP, Rig, playing, c.w)
        local f = Pose.frames(FP, Rig, off, __needle)
        local out = { off = off, frames = {}, boxes = {}, fit = __cf(Pose.fit(Rig, c.fov)), landing = Pose.landing(Rig, c.since, 0.8), wall = Pose.wall(Rig, c.reach, c.distance) }
        for k, v in pairs(f) do out.frames[k] = __cf(v) end
        for _, list in ipairs({ Rig.cuff, Rig.hand }) do
            for _, part in ipairs(list) do table.insert(out.boxes, { __cf(Pose.box(part, c.open, 1)), __cf(Pose.box(part, c.open, -1)) }) end
        end
        out.step, out.dip = Pose.walk(c.frac * 12, 0.7)
        return out
        """)
        case["expect"] = plain(got)
        out.append(case)
    return out


def game(rig_dir, key):
    """Runs the real client view (a fresh Lua state: its modules keep state) and returns its log."""
    lua = runtime(rig_dir)
    lua.globals().__KEY = key
    return plain(lua.execute(GAME))


NEEDLE_CACHE = {}


def main():
    args = sys.argv[1:]
    rig_dir = Path(args[0]).resolve() if args else ROOT / "src" / "shared"
    out_file = Path(args[1]) if len(args) > 1 else Path("viewmodel_data.js")
    keys = args[2:] or NEEDLES
    legacy = not (rig_dir / "FirstPersonRig.luau").exists()
    lua = runtime(rig_dir)
    for key in keys:
        NEEDLE_CACHE[key] = needle(lua, key, legacy)
    data = {"fp": plain(lua.eval("FP")), "rig": plain(lua.eval("Rig")), "legacy": legacy, "rigDir": str(rig_dir),
            "needles": NEEDLE_CACHE, "parity": parity(lua, keys)}
    if not legacy:
        data["game"] = dict(game(rig_dir, keys[0]), key=keys[0])
        for check in ("toolHidden", "heldAtStart", "goneAfterRelease", "backAfterReturn", "hiddenInThirdPerson"):
            assert data["game"][check] is True, f"client/ViewModel: {check} failed in the stand-in run"
        assert all(p["ghost"] for p in data["game"]["hold"]), "a part of the view can be touched, hit or casts a shadow"
    out_file.write_text("window.VM_DATA = " + json.dumps(data, allow_nan=False) + ";\n")
    print(f"{out_file}: rig from {rig_dir}{' (old rig)' if legacy else ''}, {len(keys)} needles, {len(data['parity'])} parity poses"
          + ("" if legacy else f", the game's own view ran clean ({len(data['game']['hold'])} parts)"))


if __name__ == "__main__":
    main()

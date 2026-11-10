"""Runs the game's real map builders (server/MapsA-D, MapKit, MazeKit, MazeWalls, FarmProps,
ChestSpawner) in Lua 5.4 outside Roblox, with dev/maprun/roblox.lua standing in for the engine
and luau2lua.py turning the few Luau-only bits into Lua. Writes dev/preview/mapdata/<map>.js
(every part, the spawns and the chests) for dev/preview/render.html?json=<map> to draw.

    python3 needle-hunt/dev/maprun/run_map.py pumpkin corn ...   (or "all")
    needs the lupa package: pip install lupa (or put it on PYTHONPATH)
"""
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(HERE))
from luau2lua import convert  # noqa: E402
import lupa.lua54 as lupa  # noqa: E402

SERVER_STUBS = {"AntiCheat", "HaystackModel", "DataManager", "RewardManager"}


def run(map_id, seed=11, golden=True, spread=None, probe=None):
    lua = lupa.LuaRuntime(unpack_returned_tuples=True)
    lua.execute("package.path = ''")
    R = lua.execute(open(HERE / "roblox.lua").read())
    lua.globals().__R = R

    def source(folder, name):
        path = ROOT / "src" / folder / (name + ".luau")
        return convert(path.read_text()) if path.exists() else None

    lua.globals().__source = source
    lua.execute("""
    local cache = {}
    local function folder(name)
        return setmetatable({ __folder = name }, { __index = function(f, k)
            if k == "WaitForChild" or k == "FindFirstChild" then return function(_, n) return f[n] end end
            return { __module = name .. "/" .. k, __name = k, __folder = name }
        end })
    end
    __SHARED, __SERVER = folder("shared"), folder("server")
    __R.service("ReplicatedStorage").__props.Shared = __SHARED
    local STUB = setmetatable({}, { __index = function() return function() return nil end end })
    function require(ref)
        if type(ref) ~= "table" or not ref.__module then error("can't require " .. tostring(ref)) end
        if cache[ref.__module] then return cache[ref.__module] end
        local code = __source(ref.__folder, ref.__name)
        if code == nil or __STUBS[ref.__name] then cache[ref.__module] = STUB; return STUB end
        local env = setmetatable({ script = { Parent = ref.__folder == "shared" and __SHARED or __SERVER, Name = ref.__name } }, { __index = _G, __newindex = _G })
        local fn, err = load(code, "@" .. ref.__module, "t", env)
        if not fn then error(err) end
        local result = fn()
        cache[ref.__module] = result
        return result
    end
    """)
    lua.globals().__STUBS = lua.table_from({k: True for k in SERVER_STUBS})
    lua.globals().__PROBE_FN = lua.eval('function() ' + probe + ' end') if probe else None
    data = lua.execute(f"""
    local Maps = require(__SHARED.Maps)
    local Config = require(__SHARED.Config)
    local def = Maps.get("{map_id}")
    local builders = {{}}
    for _, name in ipairs({{ "MapsA", "MapsB", "MapsC", "MapsD" }}) do
        local ok, m = pcall(require, __SERVER[name])
        if ok then for k, v in pairs(m) do builders[k] = v end elseif not tostring(m):find("can't require") then error(m) end
    end
    local model = Instance.new("Model"); model.Name = "Arena"; model.Parent = workspace
    local diff = Config.Difficulty[2]
    local ctx = {{ model = model, rng = Random.new({seed}), centre = Vector3.new(0, 0, 0), def = def, spots = {{}}, spawns = {{}}, floorY = 0, diff = diff }}
    builders[def.builder](ctx)
    __CTX = ctx
    __PROBE = __PROBE_FN and __PROBE_FN() or nil
    {'Config.Chests.spread = ' + str(spread) if spread else ''}
    local Chests = require(__SERVER.ChestSpawner)
    local chests = Chests.spawn(ctx, {{ golden = {str(golden).lower()}, diff = diff, modifiers = {{}} }})
    local spawns = {{}}
    for _, s in ipairs(ctx.spawns) do local p = typeof(s) == "CFrame" and s.Position or s; table.insert(spawns, {{ p.X, p.Y, p.Z }}) end
    local cs = {{}}
    for _, c in ipairs(chests) do table.insert(cs, {{ c.position.X, c.position.Y, c.position.Z, c.golden and 1 or 0 }}) end
    return {{ probe = __PROBE, parts = __R.collect(model), spawns = spawns, chests = cs, name = def.name, def = def }}
    """)

    def py(v):
        if lupa.lua_type(v) == "table":
            keys = list(v.keys())
            if keys and all(isinstance(k, int) for k in keys):
                return [py(v[k]) for k in sorted(keys)]
            return {str(k): py(v[k]) for k in keys}
        return v

    out = py(data)
    return out


if __name__ == "__main__":
    ids = sys.argv[1:] or ["pumpkin"]
    if ids == ["all"]:
        import re
        ids = re.findall(r'\{ id = "(\w+)", name', (ROOT / "src" / "shared" / "Maps.luau").read_text())
    dest = ROOT / "dev" / "preview" / "mapdata"
    dest.mkdir(exist_ok=True)
    for mid in ids:
        d = run(mid)
        (dest / f"{mid}.js").write_text("window.MAPDATA = " + json.dumps(d, separators=(",", ":")) + ";\n")
        print(f"{mid}: {len(d['parts'])} parts, {len(d['spawns'])} spawns, {len(d['chests'])} chests")

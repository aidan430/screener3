# Hayfield Farm, realistic: the build specification

Single source of truth for the builders. Repo: `/home/user/screener3`, game: `needle-hunt/`.
Scratchpad (called `$S` below): `/tmp/claude-0/-home-user-screener3/58693bae-13a9-5ef3-95b8-b9e36f9effe2/scratchpad`.
Everything here is design; no game source was changed while writing it.

Contents: 0 Read this first · 1 Look target · 2 Render setup · 3 Landscape · 4 Walls ·
5 Landmarks and props · 6 FX · 7 Budget · 8 Interfaces · 9 Work packages · 10 Verification ·
11 Owner notes · 12 Risks

---

## 0. READ THIS FIRST

### 0.1 What the owner asked for, honestly read
"Maps that look straight out of Unreal Engine 5, Call of Duty standards." Roblox has no Nanite or
Lumen and nothing can be uploaded from here, so the target is the best a script-built Roblox map can
be: realistic lighting and atmosphere, built-in PBR materials, real terrain with moving grass, dense
and believable set dressing, strong composition, and a level that reads at a glance. Scope: the map
Hayfield Farm (`bigfarm`), plus one global look system that also lifts the lobby and the other 15 maps.

### 0.2 Verdict on the three designs
Scores out of 10.

| | Visual payoff | Engine realism | Gameplay safety | Performance | Buildable offline | Total |
|---|---|---|---|---|---|---|
| Design 1 (light) | 9 | 8 | 8 | 7 | 7 | 39 |
| **Design 2 (world)** | 8 | 8 | 8 | 8 | 9 | **41** |
| Design 3 (land) | 8.5 | 7 | 9 | 9 | 7 | 40.5 |

**Spine: Design 2.** It has the cleanest split (one unchanged collider per wall plus kits, a backdrop
built once outside the play square, a fresh terrain floor each round, the invisible floor part that
keeps every raycast working) and it asks the least of tooling nobody here can run.

**Grafted from Design 1:** the full preset set (dusk, night, interior as well as gold, noon,
overcast); dimming as a blue hour through exposure, not Brightness; decoration on its own random
stream; painted occlusion (darker bottom courses) for phones without shadows; gate lanterns and
banners as wayfinding; a census in the maprun shim; the needle weathervane.

**Grafted from Design 3:** the sun argument (corridors need a lit strip, so aim for a sun height, not a
clock time) and a solver that finds it at boot; a vista end on each road axis seen through a field
gate; terrain strips under walls and worn paths between cells; quality tiers on the client; the flat
barn roof kept as the collider under a dressed roof; road cover with clear lanes; tethered balloons
over the landmarks; a noise heightfield for the hills (with a plain fallback).

**Dropped:** collidable roof planes on the barn (Design 2); a slab that spans the lobby with holes cut
in it (Design 1); Ball-part hills (their facets show on the skyline); CornerWedge parts (their
orientation cannot be checked offline); `UserSettings` quality reads (unverified, and the checker
does not know the name); `GeometryService` and `EditableMesh`.

### 0.3 Measured before writing (dev/maprun, seeds 1 to 3)
- Hayfield Farm today: 5,780 to 5,980 parts; 1,962 Balls and Cylinders; 10 spawns; 5 chests; a build
  takes about 2 s in maprun.
- Each quarter has about 65 wall runs (one `wall()` call each) and about 83 sixteen-stud lengths:
  **260 runs and about 335 lengths in all** (not 730). Budgets use 340.
- `needle-hunt/NeedleHunt.rbxlx` has **no MaterialService item**: `dev/build.py` adds one only when
  Config names an uploaded texture. The place probably opens with pre-2022 materials today.
- `Config.Studs.on` is still `true` in source; this work sets it to `false` (the switch stays).
- `RoundManager.luau` is 289 lines, `ChestSpawner.luau` 294, `Config.luau` 279 (limit: under 300).
- The climb geometry is the same for every seed. Its signature is saved in
  `$S/realmaps/baseline_bigfarm.json` (made by `$S/realmaps/baseline.py`): the build must keep it.
- Other work is in flight in this checkout (first-person view: `src/client/ViewModelPose.luau` is
  untracked). Re-read any shared file just before editing it.

### 0.4 Fixed numbers of the map (map-local studs; `MapKit.at(ctx, x, y, z)` gives world)
| Thing | Value |
|---|---|
| Arena centre | `Config.ArenaCentre` = (0, 0, 600); maprun uses (0, 0, 0). Both are on the 4-stud grid |
| Edge (`HALF`) | 185. Hedge collider 3 thick (183.5 to 186.5), invisible wall above to y = 209 |
| Play square (terrain) | x and z from -188 to 188 |
| Quarters | 9 x 9 cells of 16; centres (-82,-82) corn, (82,-82) vines, (-82,82) hedge, (82,82) stonehedge; each spans 10 to 154 on both axes |
| Walls | 10 high, T = 2; wall lines at 10 + 16k, cell centres at 18 + 16k (both are 2 mod 4, the middle of a terrain cell); a corridor is 14 clear |
| Cross roads | clear between walls from -9 to 9; painted -8 to 8 |
| Ring road (`RING`) | centre line 168; clear from 155 to 183.5; painted 156 to 180 |
| Spawns | 10 on the ring: (168, 52), (125.8, 168), (2.3, 168), (-118.7, 168), (-168, 57.2), (-168, -52), (-125.8, -168), (-2.3, -168), (118.7, -168), (168, -57.2) |
| Landmarks | silo (corn yard), lookout (vines yard), barn (hedge yard), windmill (stonehedge yard): the first 2 x 2 clearing of each maze (30 x 30 clear). Water tower at (-168, 168). Hay Tower at (0, 0) |

### 0.5 Rules every builder follows
1. **Built-in content only.** Parts (Block, Ball, Cylinder, Wedge), `TrussPart`, smooth Terrain,
   `Enum.Material`, lights, `ParticleEmitter`, `Beam`, `Atmosphere`, `Sky`, `Clouds`, post effects.
   No `rbxassetid://`, no meshes, no Decal or Texture, no CornerWedge, no CSG, no EditableMesh.
   The only asset paths allowed are `rbxasset://textures/particles/smoke_main.dds` and the default
   particle texture; an effect must still be fine if a texture is missing.
2. **Never write these from Luau** (they throw in the engine; the shim throws too):
   `Lighting.Technology`, `Lighting.LightingStyle`, `Lighting.PrioritizeLightingQuality`,
   `Terrain.Decoration`, `Terrain.GrassLength`, `MaterialService.Use2022Materials`,
   `Workspace.StreamingEnabled`. They live in `default.project.json`.
3. **Gameplay parts do not move.** Every existing collider keeps its name, size and position:
   wall cores, `Climb` blocks, `Ladder` trusses, decks, the loft, the `Balcony`, stair bales, legs,
   barn walls and roof slab. New colliders are allowed only where section 5 names them (`Support`
   piers inside a step's footprint, `Trunk` of the 16 road trees, `Cover` cores on the ring road).
4. **Decoration goes through `Dress.part`** (section 8.2): anchored, `CanCollide`, `CanQuery` and
   `CanTouch` all false, in `Arena.Detail` (silhouette: kept on every device) or `Arena.Fine`
   (deleted on weak devices). Gameplay parts go through `MapKit.part` into the model root as now.
5. **Decoration never draws from `ctx.rng`.** Use `Dress.rng(ctx)`. Gameplay placement (mazes,
   props that add hiding spots, cover) keeps using `ctx.rng`.
6. **Shapes.** A Ball is always uniform (`Vector3.one * d`). A Cylinder's axis is X: a vertical one
   is `Size = (height, d, d)` with `CFrame.Angles(0, 0, math.rad(90))`, as `Landmarks.luau` does.
   A Wedge is a `Part` with `Shape = "Wedge"`: X is its width, the slope rises from the front (-Z)
   bottom edge to the back (+Z) top edge, so the tall face is the back.
7. **No coplanar faces.** Lift a visible part 0.1 above terrain or sink it 0.5; overlap neighbours
   by 0.05. Nothing thin lies on `Grass` terrain (blades poke through): thin ground pieces go on
   `Ground`, `Mud`, `LeafyGrass` or `Cobblestone`.
8. **Colour.** Every repeated piece gets `Dress.tone(colour, 0.06, rng)` (plus or minus 6%, all
   channels together). Bottom courses and feet are `Dress.shade(colour, 0.88)`: painted occlusion.
9. **Shadows.** `Dress.part` makes every decoration part with `CastShadow = false`; pass
   `CastShadow = true` only where a recipe says "shadow": every second corn stalk, posts, top
   lumps, trunks, two canopy balls per tree, roof strips, sail stocks and canvas, the boundary
   hedge body. Gameplay parts (wall cores, cover cores, landmark masses) cast shadows as now.
10. **Luau that maprun can run** (`dev/maprun/luau2lua.py` only converts `x += y` and
    `if a then b else c` expressions): no type annotations, no `continue`, no `for k, v in t do`
    without `pairs`/`ipairs`, no backtick strings, no `bit32`, no loop that runs until time passes
    (`task.wait()` returns at once in maprun; yielding between chunks is fine), no `Lighting` or effect-class calls inside map builders except
    through `Dress`. CFrame use is limited to `CFrame.new`, `CFrame.Angles`, `CFrame.lookAt`,
    `*`, `:Inverse()`, `.Position`, `.LookVector`, `.RightVector`, `.UpVector`,
    `:PointToWorldSpace`, `:ToWorldSpace`, `:VectorToWorldSpace`.
11. **Files under 300 lines**, comments in the repo's plain style, every tunable in
    `ConfigFarm.luau` or `ConfigLook.luau`. Kid-friendly farm; original designs only (no real
    brands, nothing copied from another game).
12. **Do not edit a file another package owns** (section 9). If you need something from one, say
    so in your final message and work round it.

---

## 1. LOOK TARGET

The last dry afternoon of harvest, mid to late afternoon. A warm sun, about 36 degrees up and
off the grid of the maze, lays a lit strip down every corridor beside a cool violet-grey shadow.
Wall tops, corn tassels, tin roofs and the white windmill catch the light; honey-coloured haze
softens rolling fields and a ridge of hills beyond the hedge bank, under slow cumulus. Grass moves
in the wind on the verges and in the orchard. Colour is quiet (straw, dry earth, hedge green) and
saturated only where it guides: the red barn, the galvanised silo, the white mill, a gold banner on
the Hay Tower, one coloured banner and lantern at every maze gate, one balloon over every landmark.

Composition rules the builders hold to:
- **Four long sightlines.** Each road axis is a 370-stud view: the Hay Tower in the middle, a field
  gate at the far end, and through it a lane running to a vista end (red barn and twin silos, wind
  pumps on a ridge, farmhouse under an oak, pond with a willow).
- **Four grounds, four walls, four colours.** Corn: dry soil, gold stalks, gold banners. Pumpkin
  patch: dark mud, a leafy trellis, orange. Orchard: long grass with trodden paths, clipped hedge
  with apple trees growing out of it, apple red. Mill: short turf with cobbled lanes, dry-stone
  wall under hedge, blue. A player always knows which quarter they are in.
- **Landmarks read from far.** Each keeps a strong silhouette above the 10-stud walls and flies a
  balloon 70 studs up in its quarter's colour.
- **Grounded.** Nothing floats: every step has a pier or an arm, every building a plinth, every
  wall a foot (soil ridge, dark base, footing stones).

Palette (RGB): straw 214,180,90 · dry corn 196,170,92 · corn green 128,138,66 · hedge 58,100,48 ·
barn red 142,52,44 · weathered timber 112,96,80 · galvanised 150,156,160 · rust 128,78,50 ·
whitewash 226,220,204 · warm stone 138 to 176 grey · dry earth 134,108,76 · mud 84,66,50 ·
sun amber 255,214,160 · shade violet 86,96,128. The full table is `ConfigFarm.Palette` (8.1).

---

## 2. RENDER SETUP

### 2.1 Place file: `needle-hunt/default.project.json` (integrator)
Add these three entries to `"tree"` (the existing `"Workspace": {"$className": "Workspace"}` is
replaced by the third). `dev/build.py` already writes bool, `{"token": n}` and `{"float": x}`.

```json
"Lighting": {
  "$className": "Lighting",
  "$properties": {
    "Technology": { "token": 4 },
    "LightingStyle": { "token": 0 },
    "PrioritizeLightingQuality": true,
    "GlobalShadows": true
  }
},
"MaterialService": {
  "$className": "MaterialService",
  "$properties": { "Use2022Materials": true, "Use2022MaterialsXml": true }
},
"Workspace": {
  "$className": "Workspace",
  "$properties": { "StreamingEnabled": false },
  "Terrain": {
    "$className": "Terrain",
    "$properties": { "Decoration": true, "GrassLength": { "float": 0.4 } }
  }
}
```

`dev/build.py` (shared with the main game; a three-line, additive change in `material_textures`):
reuse a MaterialService node the project already declares instead of making a second one.

```python
service = tree.child("MaterialService") or Node("MaterialService", "MaterialService")
service.props["Use2022Materials"] = True
...                                  # the texture loop is unchanged
if service.children and service not in tree.children:
    tree.children.append(service)
```

The main game's project declares no MaterialService, so its output is byte-for-byte the same; run
`python3 dev/build.py --check` (no `--project`) to prove it.

### 2.2 Set by script once at boot: `Look.init()` (`server/Look.luau`)
- `Lighting.GlobalShadows = true`, `EnvironmentDiffuseScale = 1`, `EnvironmentSpecularScale = 1`,
  `GeographicLatitude = 41.7333`, `ColorShift_Bottom = Color3.new(0, 0, 0)`.
- Find or create, in `Lighting`: one `Atmosphere`, one `Sky` (`SunAngularSize = 14`,
  `MoonAngularSize = 9`, `StarCount = 3000`, default textures), one `BloomEffect`, one
  `ColorCorrectionEffect`, one `SunRaysEffect`. In `workspace.Terrain`: one `Clouds`.
- For every `ColorGradingEffect` already in Lighting: `TonemapperPreset = Enum.TonemapperPreset.Default`
  (in `pcall`).
- Read `Lighting.LightingStyle` in `pcall`; if it is not `Enum.LightingStyle.Realistic`, `warn` once
  ("the place file's lighting did not load as Realistic: see README, Realistic look"). Never write it.
- Solve the sun for every preset (2.4), apply the lobby's preset, start the gust loop (2.6).
- Fog properties are not touched: they do nothing once an Atmosphere exists.

### 2.3 Presets: `ConfigLook.presets` (values are starting points; nobody has seen them in Studio)

| | harvest | gold | noon | overcast | dusk | night | interior |
|---|---|---|---|---|---|---|---|
| ClockTime | 15.0 (see 2.4) | 16.2 | 13.5 | 12.5 | 17.5 | 0.5 | 15 |
| sunElevation (degrees) | 36 | none | none | none | none | none | none |
| Brightness | 3 | 3 | 3 | 1.3 | 2.4 | 1.6 | 2 |
| ExposureCompensation | 0.05 | 0.1 | 0 | 0.25 | 0.25 | 0.6 | 0.4 |
| Ambient | 58,54,62 | 58,52,62 | 60,62,66 | 96,100,106 | 70,54,66 | 38,46,72 | 104,88,70 |
| OutdoorAmbient | 108,104,116 | 104,98,112 | 95,100,108 | 150,154,160 | 124,96,104 | 64,76,112 | 120,104,86 |
| ColorShift_Top | 52,32,10 | 60,38,12 | 12,8,0 | 0,0,0 | 110,56,18 | 0,8,30 | 40,26,8 |
| ShadowSoftness | 0.2 | 0.25 | 0.15 | 1 | 0.4 | 0.5 | 0.5 |
| Atmosphere Density | 0.3 | 0.3 | 0.28 | 0.42 | 0.36 | 0.42 | 0.2 |
| Atmosphere Offset | 0.25 | 0.25 | 0.25 | 0.1 | 0.3 | 0.1 | 0 |
| Atmosphere Haze | 1.5 | 1.6 | 0.6 | 2.4 | 2.2 | 1.2 | 0.8 |
| Atmosphere Glare | 0.3 | 0.35 | 0.1 | 0 | 0.8 | 0 | 0 |
| Atmosphere Color | 228,198,148 | 232,196,140 | 199,206,214 | 190,196,204 | 250,170,120 | 60,74,110 | 190,160,120 |
| Atmosphere Decay | 116,104,120 | 120,98,110 | 106,112,125 | 120,126,134 | 96,70,120 | 20,26,44 | 90,76,60 |
| Clouds Cover | 0.52 | 0.55 | 0.5 | 0.92 | 0.6 | 0.35 | 0.4 |
| Clouds Density | 0.35 | 0.35 | 0.3 | 0.55 | 0.4 | 0.3 | 0.3 |
| Clouds Color | 255,240,222 | 255,236,214 | 255,255,255 | 200,204,210 | 255,190,150 | 120,130,160 | 255,255,255 |
| Bloom Intensity | 0.6 | 0.8 | 0.5 | 0.3 | 0.9 | 1 | 0.6 |
| Bloom Size | 28 | 28 | 24 | 24 | 32 | 30 | 24 |
| Bloom Threshold | 1.7 | 1.8 | 2 | 2 | 1.6 | 1.2 | 1.6 |
| Grade Contrast | 0.12 | 0.12 | 0.08 | 0.05 | 0.14 | 0.1 | 0.08 |
| Grade Saturation | 0.08 | 0.1 | 0.05 | -0.12 | 0.14 | -0.1 | 0 |
| Grade TintColor | 255,245,232 | 255,244,230 | 255,255,255 | 236,242,255 | 255,232,214 | 214,226,255 | 255,240,220 |
| SunRays Intensity | 0.1 | 0.12 | 0.05 | off | 0.2 | off | off |
| SunRays Spread | 0.6 | 0.6 | 0.4 | off | 0.7 | off | off |
| Wind (GlobalWind) | 9,0,4 | 9,0,4 | 6,0,3 | 12,0,5 | 5,0,2 | 3,0,1 | 0,0,0 |

`ColorCorrectionEffect.Brightness` is 0 in every preset. Bloom `Threshold` stays above 1 (below 1
everything glows).

### 2.4 The sun: a height, not a clock time
At 10-stud walls and 14-stud corridors a sun 36 degrees up throws a 13.8-stud shadow; turned 45
degrees off the grid that shades about 9.7 studs of every corridor and lights the rest. A golden-hour
sun (about 20 to 25 degrees) would black out every corridor across it. The warm colour comes from
`ColorShift_Top`, the tint and the haze instead.

The sun's real height for a clock time cannot be checked offline, so `Look` solves it:
`Look.init` steps `Lighting.ClockTime` from `ConfigLook.Sun.from` (12.5) to `Sun.to` (17.5) in
0.05 steps, reads `Lighting:GetSunDirection()` (in `pcall`), takes the step whose elevation
(`math.deg(math.asin(dir.Y))`) is nearest the preset's `sunElevation`, and remembers that clock time
and direction for the preset. If the call fails, or the direction never changes, the preset's own
`ClockTime` is used (15.0: between 32 and 48 degrees on either plausible sun model). Presets without
`sunElevation` just read the direction at their `ClockTime`. `Look.sunFor(name)` returns the
remembered direction (a unit vector towards the sun) or nil; builders use
`ctx.sun or Vector3.new(table.unpack(Farm.sunFallback))` (fallback -0.62, 0.59, 0.52).
`GeographicLatitude` stays at the default.

### 2.5 How the map rows map onto presets (`src/shared/Maps.luau`, integrator)
Each row's `lighting = { ... }` table is deleted and replaced by `look = "<preset>"`.
`Maps.lobbyLighting` becomes `Maps.lobbyLook = "noon"`. The file header comment is updated.

| Preset | Maps |
|---|---|
| harvest | bigfarm |
| gold | pumpkin, corn, windmill |
| noon | field, sunflower, orchard, market, fair, and the lobby |
| overcast | frozen, greenhouse, marsh |
| dusk | sunset |
| night | forest |
| interior | barn, attic |

Two rows also gain `terrain = { Grass = { r, g, b } }` so the backdrop hills match the map:
frozen `{ 236, 242, 250 }`, forest `{ 52, 84, 52 }`. `RoundManager` passes `def.terrain` to
`Landscape.colours` each round (nil = the farm's colours).

### 2.6 Per round and per frame
- `Look.apply(name, dim)` (called by RoundManager before the map is built, and with the lobby look
  when a round ends or fails) writes the preset to Lighting, the Atmosphere, Clouds, Bloom,
  ColorCorrection and SunRays, sets `ClockTime` to the solved time, and sets the wind base.
  Set `Ambient` before `OutdoorAmbient` (the engine clamps OutdoorAmbient to at least Ambient).
- **Dim** (`dim` = the difficulty's `dim` plus 0.45 on a Low Light round; today 0, 0.35, 0.45 or
  0.8), from `ConfigLook.Dim`: `ExposureCompensation -= 1.6 * dim`; both ambients
  `* (1 - 0.5 * dim)`; `Atmosphere.Density += 0.1 * dim` (capped at 1); `Saturation -= 0.15 * dim`;
  `TintColor` lerps `0.5 * dim` towards 200,214,255. Brightness is left alone so shadows still read.
- **Wind:** `workspace.GlobalWind` = the preset's wind, re-set every 6 to 10 s to the base times a
  random 0.7 to 1.3 (`ConfigLook.Gust`). One server loop started by `Look.init`.
- **Depth of field** is the client's (`client/LookFx.luau`): one `DepthOfFieldEffect` in
  `workspace.CurrentCamera`, `FarIntensity` 0.15, `NearIntensity` 0, `FocusDistance` 120,
  `InFocusRadius` 50; enabled only while the player's `InRound` attribute is false or the phase is
  `results`; off on the low tier.
- **Quality tiers** (`client/LookFx.luau`, `ConfigLook.Tiers`): start `high`, or `mid` on a
  touch-only device (`UserInputService.TouchEnabled and not KeyboardEnabled`). While the phase is
  `countdown` or `search`, if the mean frame rate over 4 s is under 28, drop one tier (never back up
  in that session). When the phase becomes `countdown` (the server has finished building), apply the
  tier to `workspace.Arena` (and again at once whenever the tier drops): `mid` destroys
  `Arena.Fine`; `low` also destroys `Arena.Fx` and disables the local Bloom, SunRays and depth of
  field. Never prune during `loading`: the map is still arriving. All local; nothing is sent to
  the server.
  The engine drops shadows by itself below quality level 4; ambients, Atmosphere, the grade and
  painted occlusion carry the look there.

---

## 3. LANDSCAPE

All terrain work is in `server/Landscape.luau`; the edge is `server/Boundary.luau`; the far set
dressing is `server/Vista.luau` and `VistaSets.luau`. Coordinates are map-local; every fill lies
on multiples of 4. Terrain materials used: Grass, LeafyGrass, Ground, Mud, Cobblestone, Sand
(only as stubble, at the haystack colour `MapKit.haystack` already sets), Water, Air.

### 3.1 Colours, set at the start of every round: `Landscape.colours(overrides)`
`SetMaterialColor` for Grass 88,124,54 · LeafyGrass 96,118,60 · Ground 134,108,76 · Mud 84,66,50 ·
Cobblestone 150,146,136 · Rock 112,110,104 (`ConfigFarm.Terrain.colours`), then any `overrides`
(a map row's `terrain`). Never Sand (the haystacks own it) and never Water (it errors: water uses
`Terrain.WaterColor`).

### 3.2 The backdrop, built once per server: `Landscape.backdrop(centre)`
A frame of land round the play square, from 188 to 448 studs out, that is never cleared. It is
idempotent (a second call returns the same context) and is started by `Main.server` on game servers
and in Studio; `Landscape.floor` starts it in the background if nobody has. It returns `bctx`
(`{ model = workspace.Backdrop, centre = centre, floorY = 0, rng = Random.new(7), def = { straw = { 214, 180, 90 } } }`)
and ends by calling `Vista.build(bctx, Landscape.height)`.

**Height.** `Landscape.height(x, z)` is a pure function (no Roblox calls except `math.noise`):

```
d    = max(|x|, |z|)                        s(t) = smoothstep = c*c*(3 - 2*c), c = clamp(t, 0, 1)
n1   = clamp(math.noise(x/150, z/150, 3.7), -0.5, 0.5)
n2   = clamp(math.noise(x/48,  z/48,  9.1), -0.5, 0.5)
roll = s((d - 232)/90) * (14 + 20*(0.5 + n1) + 6*n2)          -- 0 on the fields, about 8 to 37 on the hills
lane = min(|x|, |z|)                                           -- distance from the nearer road axis
if lane < 28: roll = lerp(6 * s((d - 232)/90), roll, s((lane - 12)/16))   -- a low rise along each lane
rim  = 44 * s((d - 340)/60)                                    -- a ridge that hides the world's edge
h    = max(roll, rim) * (1 - s((d - 404)/40))                  -- falls back to 0 by 444
h    = h * s((p - 26)/30), p = distance from the pond centre (-292, 0)
h    = 0 where d <= 188
```

So: flat fields from 188 to 232, rolling hills to 340, a 44-stud ridge at 400 that hides the slab's
edge from every tower and from the Bird's Eye camera (55 up), and a fall to nothing at 444 so the
lobby (whose own ground reaches z = 450) sees a ridge on its horizon, not a cliff.

**Material of a column** `Landscape.column(x, z) -> height, materialName` (first match):
1. within 20 of the pond centre: Mud;
2. `lane <= 6` and `d < 300`: Ground (the track running on from each field gate);
3. inside a field rectangle (`ConfigFarm.Terrain.fields`, all in the flat band, clear of the lanes):

| Side | Rectangle (x0, z0, x1, z1) | Material | Read as |
|---|---|---|---|
| -Z | -180, -232, -24, -188 | Sand | stubble, with round bales |
| -Z | 24, -232, 180, -188 | Ground | standing wheat (a slab part over it) |
| +Z | -180, 188, -24, 232 | Ground | ploughed |
| +Z | 24, 188, 180, 232 | Sand | stubble, with round bales |
| -X | -232, -180, -188, -24 | LeafyGrass | meadow |
| -X | -232, 24, -188, 180 | Ground | standing wheat |
| +X | 188, -180, 232, -24 | Ground | ploughed |
| +X | 188, 24, 232, 180 | LeafyGrass | meadow |

4. otherwise Grass.

**Writing it.** The frame is four rectangles (never the play square, so a round starting during
the build is safe): x -448..448 by z 188..448; the same at z -448..-188; x -448..-188 by
z -188..188; x 188..448 by z -188..188. Each is cut into chunks at most 128 studs a side (all
multiples of 4). Per chunk: `region = Region3.new(min, max):ExpandToGrid(4)` with y from -16 to 48
(16 cells); `materials[x][y][z]` and `occupancy[x][y][z]` are 1-based arrays sized `region.Size / 4`;
for the cell whose bottom is `y0`: `occupancy = clamp((h - y0) / 4, 0, 1)` and the material is the
column's material where occupancy > 0, `Enum.Material.Air` otherwise; then
`workspace.Terrain:WriteVoxels(region, 4, materials, occupancy)` inside `pcall`, and `task.wait()`
between chunks. About 660,000 voxels in all.

**Fallback** (the first `WriteVoxels` that fails switches to this for the whole frame): the four
rectangles as `FillBlock` Grass from y -16 to 0; 24 mounds `FillBall(at(x, 20 - 70, z), 70, Grass)`
at 300 to 330 out, clear of the lanes; 36 ridge balls `FillBall(at(x, 44 - 90, z), 90, Grass)` every
100 studs at 400 out; lanes and fields painted with `FillBlock` on the top layer.

**Pond** (either path, after the land): `FillBall(at(-292, 12, 0), 20, Air)` cuts a bowl,
`FillCylinder(CFrame.new(at(-292, -4.5, 0)), 5, 15, Water)` fills it; `Terrain.WaterColor` 58,92,84,
`WaterTransparency` 0.45, `WaterReflectance` 0.6, `WaterWaveSize` 0.05, `WaterWaveSpeed` 6. Water is
104 studs outside the walls: nobody can reach it and no throw can hit it.

### 3.3 The far set: `Vista.build(bctx, height)` (parts in `workspace.Backdrop.Far`, built once)
Everything is `Dress.part(bctx, "Far", ...)`, stands on `height(x, z)` (`Landscape.height`, passed in), and is sized about 1.3
times life so it reads at 120 to 300 studs. About 1,000 parts.

| Piece | Where | Recipe | Parts |
|---|---|---|---|
| Red barn and twin silos | -Z lane end, (0, -300), facing the map | body 36 x 16 x 24 (barn red boards as 6 big panels), gambrel roof of 8 tin strips, cream trim 8, doors 4, 2 silos (Cylinder 24 x 9 and 18 x 8, galvanised, Ball domes), hoops 6, plinth 4 | 60 |
| Wind pumps | +X lane end, (300, -18), (306, 4), (296, 24) | each: lattice mast 18 tall (4 legs, 6 braces), hub tweened round every 6 s, 12 welded blades 0.15 x 3 x 0.6, tail vane | 3 x 26 |
| Farmhouse and oak | +Z lane end, (0, 300) | walls 22 x 12 x 16 whitewash Plaster, gable roof of 2 x 6 Slate strips, chimney (Brick-coloured Slate 132,84,70), 6 dark windows with frames, porch 8, door; an oak 30 tall (the "oak" recipe of 5.9 at 1.4 scale); 2 amber Neon windows | 80 |
| Pond dressing | -X lane end, (-292, 0) | jetty of 8 planks on 6 posts, a rowing boat (9 parts), a willow (trunk, 3 limbs, 5 Balls, 14 hanging strips 0.15 x 6 to 9 x 0.6, LeafyGrass 96,124,60), 12 reeds | 60 |
| Lane fences | both sides of each lane, 188 to 268 out, 7 studs from the axis | posts 0.6 x 4 x 0.6 every 8, two rails per 16; one run in five down | 4 x 34 |
| Standing wheat | over the two wheat fields | one slab each, 150 x 1.6 x 40, Material Grass, 206,176,96; 3 darker tramlines 150 x 0.1 x 1.2 on top | 8 |
| Round bales | the two stubble fields | 12 each: Cylinder 4 x 5 x 5 lying, straw, turned at random | 24 |
| Far trees | 110 on the hills, 240 to 380 out, in clumps of 3 to 6, never within 30 of a lane | trunk 1.6 x h x 1.6 (h 14 to 22) and two crossed canopy Blocks 9 x 8 x 9 turned 45 degrees, greens 62,98,44 to 96,124,52 | 330 |
| Telegraph poles | 10 along the +Z lane, 9 studs to one side | pole 0.7 x 16 x 0.7, cross arm, 2 wire Blocks 0.06 x 0.06 x 24 to the next pole (sagging 0.6 by tilting two halves) | 40 |
| Birds | 3, circling at y = 90, radius 110 to 150 | an invisible hub at (0, 90, 0) tweened round the Y axis every 50 to 70 s; body and wing Block welded at the radius | 9 |

Backdrop effects (hosts in `workspace.Backdrop.Fx`): chimney smoke at the farmhouse and pond mist
(6.2).

### 3.4 The play square's floor, every round: `Landscape.floor(ctx, half)`
- `FillBlock(CFrame.new(at(0, -8, 0)), Vector3.new(376, 16, 376), Grass)`: a slab whose top is y = 0.
- The **floor part stays**: `MapKit.part` named `Ground`, 376 x 2 x 376, top at y = 0,
  `Transparency = 1`, `CastShadow = false`, collidable and query-able. ChestSpawner's rays
  (`Include { ctx.model }`) and the maprun shim only see parts, so this keeps both unchanged.
  No `Countryside` part and no `Road` parts on this map.
- If `Config.Studs.on` is true (the owner flips the switch back): no terrain is filled or painted;
  the `Ground` part is visible in `ctx.def.ground` and gets its studs from `MapKit.part` as before.

### 3.5 Painting it: `Landscape.farm(ctx, plan)` (after the mazes and landmarks exist)
`Landscape.paint(ctx, x0, z0, x1, z1, material)` snaps the rectangle outwards to multiples of 4 and
refills the top cell layer: `FillBlock(CFrame.new(at(cx, -2, cz)), Vector3.new(w, 4, l), material)`.
Material borders blend over about 4 studs by themselves. In this order (later wins):

| Step | Rectangles | Material |
|---|---|---|
| 1 Quarter floors | each quarter, 8 to 156 on both axes | corn Ground · vines Mud · hedge Grass · stonehedge LeafyGrass |
| 2 Yards | 28 x 28 under each maze landmark, and the same under the second clearing | corn Cobblestone · vines Ground · hedge Ground · stonehedge Cobblestone |
| 3 Wall feet | a 4-wide strip under every `maze.runs` entry, 2 past each end | corn Mud · vines LeafyGrass · hedge LeafyGrass · stonehedge Ground |
| 4 Worn paths | a 4-wide strip along every `maze.links` entry (cell centre to cell centre, 2 past each end) | corn none · vines Ground · hedge Ground · stonehedge Cobblestone |
| 5 Gate sills | 12 along the wall by 8 across at every `maze.gates` entry | corn Mud · the others Ground |
| 6 Roads | cross roads: x -8..8 by z -188..188 and the same turned; ring: the four strips between 156 and 180 | Ground |
| 7 Ruts | cross roads: the strips -8..-4 and 4..8; ring: 160..164 and 172..176 | Mud |
| 8 Crossroads | -12..12 on both axes | Cobblestone |

What is left as Grass (with moving blades): the orchard floor between its paths, and the verges
from 180 to 188 at the hedge bank. Loose straw would vanish in the orchard's blades, which is why
its paths are bare Ground and its litter is leaves and windfalls (5.11).

`plan` is built by `MapsBig` (8.6).

### 3.6 Clearing between rounds: `Landscape.clear(centre)`
Replaces `MapKit.clearTerrain`:
`FillBlock(CFrame.new(centre + Vector3.new(0, 44, 0)), Vector3.new(376, 120, 376), Enum.Material.Air)`:
exactly the play square, from y -16 to 104, so the backdrop is never touched and the other maps
(part floors, Sand haystacks) start from bare air as they do now.

### 3.7 The lobby: `Landscape.lobby(centre)` (once, from `Main.server`)
Twelve grassy mounds outside the lobby's hedge: for i = 0..11, at angle `i * 30 + 15` degrees and
150 studs out, `FillBall(centre + Vector3.new(x, top - 46, z), 46, Grass)` with `top = 14 + (i % 3) * 4`.
With the `noon` preset, the Atmosphere, clouds and depth of field, that is the lobby's whole lift.
`LobbyBuilder` and `LobbyDecor` are not edited.

### 3.8 The edge: `Boundary.build(ctx, half)` (every round, replaces `MapKit.edges` on this map)
- **Colliders, exactly as `MapKit.edges` makes them** (same sizes and positions, `CanQuery = false`):
  four `Hedge` boxes (now `Transparency = 1`, `CastShadow = false`) and four `Edge` invisible walls.
- **Hedge bank**, in modules of 17 studs laid from 14 out to 184 on each half of each side (10 a
  half, 80 in all), which leaves a 28-stud opening on each road axis; plus four corner pieces (a
  hedge block 3.4 x 5.6 x 3.4 on a footing stone). Each module is 8 parts:

| Part | Size | Material, colour | Tier |
|---|---|---|---|
| 2 footing stones | 8.7 x 3 x 3.4, yaw plus or minus 2 degrees, y 1.5 | Rock, grey 120 to 150 | Detail, no shadow |
| coping | 17.2 x 0.5 x 3.8 at y 3.25 | Slate 118,114,108 | Detail, no shadow |
| hedge body | 17.2 x 5.6 x 3 at y 6.3 (top 9.1) | LeafyGrass 58,92,44 | Detail, shadow |
| 2 top lumps | 4 to 6 x 1.6 x 2.6, rolled 45 degrees about the side's axis, y 9.2 | LeafyGrass 84,122,56 | Detail, shadow |
| inner face panel | 0.5 x 4.6 to 5.2 x 5 to 7, 0.2 proud of the inside face | LeafyGrass 62,100,48 | Detail, no shadow |
| leaning stake | 0.3 x 3.4 x 0.3, 10 to 20 degrees | Wood 104,88,70 | Fine |

- **Field gates** at the four openings (26 parts each): two Rock piers 3 x 5 x 3 with Slate caps;
  two closed five-bar leaves, each 5 bars 0.25 x 0.25 x 13, 3 uprights and a diagonal, Wood
  112,96,80; a chain block. The invisible `Hedge` collider still crosses the opening, so the gate
  is sealed but the view runs on down the lane to the vista end.
- The corner outside (-192, 192) is left empty for the wind pump (5.6).

---

## 4. WALLS

### 4.1 The rule
`MazeWalls.<style>(ctx, a, b, height, T)` builds the **collider core exactly as today** (one
`MazeWall` part per run; for stone, two) and then calls a kit that only adds decoration. The wall
frame `cf` is `CFrame.lookAt(mid, mid + (b - a))` on the floor: X across the wall, Y up, Z along
it; `len = (b - a).Magnitude + T`. Decoration stays within 2.6 studs of the centre plane.
Counts below are per 16 studs of length and scale with `len / 16`; `ConfigFarm.Walls` holds them
and `ConfigFarm.Budget.wallDensity` (1) scales every Fine count.

| Style | Core (unchanged size) | Core material, new colour |
|---|---|---|
| corn | 1.6 x 8.5 x len at y 4.25 | Grass, 104,96,52 |
| vines | 2 x 10 x len at y 5 | LeafyGrass, 44,84,40 |
| hedge (new entry `MazeWalls.hedge`; MazeKit's inline hedge is no longer reached) | 2 x 10 x len at y 5 | LeafyGrass, 44,78,40 |
| stone | **one** 2.6 x 5 x len at y 2.5 (replaces the two rows of small blocks) plus 2 x 5 x len at y 7.5 | Slate 92,90,86 · LeafyGrass 48,84,42 |
| stonehedge | one `ctx.rng:NextNumber() < 0.5` draw as now: stone, or the hedge core with footing stones | as above |

The other 15 maps use the same styles and inherit the new look.

### 4.2 Corn: `WallKitCrop.corn(ctx, cf, len, height, T)` (48 parts per 16 studs)
| Piece | Count | Recipe | Tier |
|---|---|---|---|
| Stalks | 16 | one per stud of length, alternating sides: x = side * 0.95 plus or minus 0.12, z = -len/2 + 0.5 + i; Block 0.3 x h x 0.3, h = height + 0.2 to 2.2; lean up to 4 degrees on X and Z; Grass; colour a random mix between corn green 128,138,66 and dry corn 196,170,92, then toned | Detail; every second one casts a shadow |
| Bent tops | 2 | one stalk in eight: its top 40% is a second Block bent 35 degrees | Fine |
| Leaves | 16 | a Block 0.08 x 0.5 x 3.2 through each stalk at 35 to 70% of its height, yawed at random, pitched 20 to 40 degrees; the stalk's colour times 0.92 | Fine |
| Tassels | 8 | every second stalk: 0.22 x 1.1 x 0.22 on top, leaning up to 12 degrees, 232,204,128 | Fine |
| Ears | 4 | one stalk in four: Block 0.42 x 1.3 x 0.42 at 55% height, 0.3 outboard, tilted 20 degrees, husk 168,172,96 | Fine |
| Soil ridges | 2 | each side: Block 1.3 x 0.5 x (up to 16) at x = plus or minus 0.95, top at y 0.45, Ground, 112,90,62 | Fine |

### 4.3 Vines, as a bean and gourd trellis: `WallKitCrop.vines` (24 parts per 16 studs)
| Piece | Count | Recipe | Tier |
|---|---|---|---|
| Posts | 2 to 3 | every 8 studs and at both ends: Block 2.5 x 11 x 0.6 (through the wall, so it shows on both faces), Wood 112,96,80 | Detail, shadow |
| Top rail | 1 | 0.4 x 0.4 x len at y 10.6, Wood 104,88,70 | Detail |
| Leaf slabs | 8 | alternate faces, every 2 studs: Block 0.6 x 3 to 4.2 x 3 to 4.2 at x = side * (1.0 to 1.25), y 2.5 to 8.5, turned 45 plus or minus 15 degrees about X (a diamond); three of the eight sit at y 9 to 10.5 and break the top line; LeafyGrass in 58,98,44 / 74,116,50 / 92,128,58 | Detail; the top three cast shadows |
| Crown lumps | 2 | Block 1.9 x 1.9 x 3 to 4 at y 10.1, rolled 45 degrees about Z, 96,134,62 | Detail, shadow |
| Stems | 4 | Block 0.22 x 5 to 9 x 0.22 on a face (x = side * 1.08), leaning 15 to 25 degrees along the wall, Wood 70,58,40 | Fine |
| Leaf cards | 3 | 0.06 x 1.6 x 1.6 turned 45 degrees, x = side * 1.35, lighter greens | Fine |
| Gourds | 2 | Ball 0.9 to 1.3 at y 1.2 to 4, x = side * 1.35; 204,108,36 or 150,160,60; SmoothPlastic | Fine |
| Dirt skirts | 2 | Wedge 8 long x 0.5 high x 0.9 out, each side, tall face against the wall, Ground 104,86,60 | Fine |

### 4.4 Hedge: `WallKitHedge.hedge(ctx, cf, len, height, T, y0, share)` (18 parts per 16 studs)
`y0` (default 0) lifts the kit and `share` (default 1) scales its counts: the stone wall calls it
with `height - 5`, `y0 = 5` and `share = 0.67` for the hedge that grows on top of the stones.
| Piece | Count | Recipe | Tier |
|---|---|---|---|
| Face panels | 6 | 3 a face: Block 0.5 x (height - 1.8 to height - 0.8) x 4.6 to 5.6 at x = side * (1.1 to 1.35), standing 0.7 above the foot, yaw plus or minus 3 degrees, LeafyGrass 58,100,48 | Detail, no shadow |
| Dark base | 1 | 2.9 x 0.9 x (up to 16) at y 0.45, LeafyGrass 40,52,34 (omitted when y0 > 0) | Detail, no shadow |
| Top lumps | 3 | two Blocks 2.4 x 1.3 x 3.5 to 5 at the top, rolled up to 8 degrees, 84,128,60; one diamond 1.8 x 1.8 x 2.6 rolled 45 degrees | Detail, shadow |
| Leaf cards | 4 | 0.05 x 2.2 x 2.2, two crossed pairs poking from a face or the top, 96,134,62 | Fine |
| Sprigs | 2 | 0.15 x 1.2 x 0.15 on top, leaning | Fine |
| Stake and weed | 2 | a leaning Wood stake 0.3 x 3 x 0.3 and a weed blade 0.06 x 1.1 x 0.7 at the foot (omitted when y0 > 0) | Fine |

### 4.5 Stone: `WallKitHedge.stone(ctx, cf, len, height, T)` (36 parts per 16 studs)
| Piece | Count | Recipe | Tier |
|---|---|---|---|
| Through stones | 16 | three courses, 1.9, 1.7 and 1.4 high (centres 0.95, 2.75, 4.3); each course is stones 2.2 to 4.2 long laid end to end with 0.05 overlap; Block 2.9 to 3.3 (across the wall, so one stone shows on both faces) x course x length; yaw plus or minus 3 degrees, x plus or minus 0.1; warm grey v = 138 to 176 as (v, v - 2, v - 8); one in eight mossy 96,108,78; the bottom course shaded 0.88; Slate, every fourth Rock | Detail, no shadow |
| Cap stones | 4 | 3.4 x 0.45 x 3 to 5 at y 5.1: a ledge under the hedge, Slate 124,120,112 | Detail, no shadow |
| Hedge on top | 10 | `WallKitHedge.hedge(ctx, cf, len, height - 5, T, 5, 0.67)`: 4 panels and 2 lumps (Detail), 4 cards and sprigs (Fine) | both |
| Moss, ivy, fallen stone | 6 | 2 moss pads 1.2 x 0.15 x 2 on the ledge (LeafyGrass 86,112,60); 2 ivy strips 0.12 x 2 to 4 x 0.5 down a face (40,70,40); 1 fallen stone 1.2 x 0.8 x 1.5 at the foot; 1 weed | Fine |

The hedge half of `stonehedge` is the hedge kit plus 4 footing stones (3 x 0.9 x 2.5 to 4, Slate) per
16 studs: 22 parts.

### 4.6 Maze records: `MazeKit.build` adds three lists to the maze it returns
- `maze.runs = { { a = Vector3, b = Vector3 }, ... }`: every wall built, world positions on the floor.
- `maze.links = { { x1, z1, x2, z2 }, ... }`: every open side between two neighbouring cells, as
  their map-local centres (after loops and clearings).
- `maze.gates = { { a = Vector3, b = Vector3, out = Vector3 }, ... }`: every gap in the outside
  wall (`o.doors`), world positions of its two ends on the wall line (16 apart; 14 clear) and the
  unit vector pointing out of the maze.
Nothing else in `MazeKit.build` changes: the carve, the loops, the clearings, the hiding spots and
`maze.spawns` draw from `ctx.rng` in the same order.

### 4.7 Gates: `GateKit.gates(ctx, maze, quarterId)` (16 parts a gate, up to 32 gates)
All decoration (posts included: nothing new to snag on).
| Piece | Recipe | Tier |
|---|---|---|
| 2 posts | 0.9 x 12 x 0.9, 1.45 in from each end of the gap, Wood 104,88,70 | Detail, shadow |
| Lintel and 2 knee braces | 0.7 x 0.9 x 14.6 at y 11.6; braces 0.5 x 0.5 x 2.4 at 45 degrees | Detail |
| Sign plank | 0.3 x 2.2 x 5 hanging under the lintel (y 9 to 11.2), WoodPlanks in the quarter's colour times 0.9 | Detail, no shadow |
| Icon, both faces | 3 small blocks a face: a corn cob, a pumpkin, an apple or a mill sail, by quarter | Fine |
| Pennant | a pole 0.2 x 2.4 x 0.2 on one post and a Fabric Wedge 0.08 x 1.4 x 2.2 in the quarter's colour | Fine |
| Lantern | a bracket and a Neon block 0.7 x 0.9 x 0.7 (255,196,120) with `Dress.light` (Point, range 14, brightness 0.9, 255,190,110, no shadows) | Detail |

Quarter colours (`ConfigFarm.Quarters[id].colour`): corn 236,196,60 · vines 232,128,40 ·
hedge 170,44,40 · stonehedge 70,110,170 · centre (`ConfigFarm.centreColour`) 255,205,70.

---

## 5. LANDMARKS AND PROPS

`Landmarks.<name>(ctx, x, z)` keeps its signature and return value (the chest top). Each builds
its gameplay parts exactly as now (same names, sizes, positions: the baseline in
`dev/maprun/baseline_bigfarm.json` is checked), recolours the visible ones, then calls its skin.
Part budgets are ceilings. "Support" means a collidable `MapKit.part` named `Support` that stays
inside the footprint of the step above it; everything else new is `Dress.part`.

### 5.1 Silo (corn yard): `LandmarkSkins.silo(ctx, x, z, h)`, h = 24, up to 140 parts
Existing: tube (Cylinder 24 x 9 x 9), 3 bands, catwalk 12 x 1 x 12 (top 24.6), 3 rails, ladder truss
at (x + 6.2, z + 2). Recolour: tube Metal 150,156,160; bands Metal 120,126,132; catwalk and rails as now.
| Dressing | Recipe |
|---|---|
| 12 seam ribs | Block 0.18 x 24 x 0.5 at radius 4.55, every 30 degrees, Metal 132,138,144 |
| 9 hoops | Cylinder 0.25 x 9.25 x 9.25 at y 2, 4, 8, 10, 14, 16, 20, 22, 23.6, Metal 120,126,132 |
| Red band | Cylinder 1.6 x 9.12 x 9.12 at y 20.9, 128,44,38: the silo's colour mark |
| 10 rust streaks | Block 0.1 x 2 to 6 x 0.5 to 1.1 at radius 4.58 under hoops, CorrodedMetal 128,78,50 (Fine) |
| Deck frame | 4 joists 0.5 x 0.6 x 12 at y 23.8; 4 struts 0.4 x 0.4 x 4.2 from the tube to the deck corners; Metal 90,94,100 |
| Rail posts | 8 posts 0.3 x 2.4 x 0.3 at the deck edge (Fine) |
| Ladder cage | 6 hoops round the truss at y 6, 9.5, 13, 16.5, 20, 23.5, each three bars 0.15 thick forming a U 2.6 across; 2 straps 0.12 x 18 x 0.3 (Fine) |
| Auger | Cylinder 14 x 1.1 x 1.1 leaning 60 degrees from a hopper (5 parts, CorrodedMetal and Metal) on the -x side to the tube at y 12 |
| Hatch | door 2 x 3.2 x 0.3 at the base facing -z, darker Metal, a frame and a handle |
| Lamp | a Neon block over the hatch with `Dress.light` (Point, range 18, brightness 1) |

### 5.2 Lookout (vines yard): `LandmarkSkins.lookout(ctx, x, z, h, steps, lastAngle)`, h = 15, up to 110
Existing: 4 legs 1 x 20 x 1 at plus or minus 3, deck 8 x 1 x 8 (top 15), flat `Roof` 9 x 0.6 x 9 at y 20
(kept as the collider, recoloured dark 70,56,44), 6 spiral steps 3 x 1 x 3 at radius 8.5.
`Landmarks.spiral` now returns the list of step parts and the last angle, passed to the skin.
| Dressing | Recipe |
|---|---|
| Supports | under each spiral step a log pier: collidable `Support` 1.2 x (step underside) x 1.2 from the ground, Wood 104,70,42 |
| Braces and girts | 8 X-braces 0.35 x 0.35 x 9.2 between the legs (y 2 to 8.5 and 8.5 to 14); 8 girts 0.4 x 0.4 x 6 at y 5 and 10 |
| Roof | a cross-gable roof over the flat one: four Wedges 9.6 wide x 2.6 high x 4.8 deep, tall faces together at the centre; Metal 96,112,98 with two CorrodedMetal patches 2 x 0.1 x 1.5; a ridge finial |
| Rails | top and mid rails 0.25 x 0.25 x 6 on three sides, open on the side facing `lastAngle` (Detail, no shadow) |
| Pennant and hoist | a pole 0.2 x 3 x 0.2 with an orange Fabric Wedge on the finial; a hoist beam, rope 0.08 thick and bucket (Fine) |
| Lamp | under the roof: Neon block, `Dress.light` (Point, range 18, brightness 1) |

### 5.3 Barn (hedge yard): `BarnKit.dress(ctx, x, z, dims, bales)`, up to 380
Existing (W 26, D 18, H 16, loft at 10): back wall, two side walls, two front panels and a header
(a doorway 8 wide and 12 high facing -z), flat roof slab 28 x 1 x 20 at y 16.5, loft 24 x 1 x 9 over
the back half, six stair bales. Recolour: walls WoodPlanks 88,66,48 (the dark inside skin), roof
slab 60,50,44, loft 124,100,78. The roof slab stays the only roof collider.
| Dressing | Recipe |
|---|---|
| Boards | about 62 vertical boards outside the walls: 1.3 wide x 16 x 0.25, 0.15 proud, 0.1 gaps; reds 142,52,44 / 128,46,40 / 156,64,52; every eighth silvered 150,132,118 (Detail, no shadow) |
| Plinth | Cobblestone band 1.4 high, 0.35 proud, round the foot except the doorway (5 blocks, 138,132,122) |
| Trim | 4 corner boards 0.5 x 16 x 0.5, the door frame (3), eave fascia (4); cream 232,226,210 |
| Doors | two leaves 4.4 x 11.5 x 0.3 slid open either side of the doorway on a rail 17 x 0.3 x 0.3 at y 12.2; each a frame of 4 and an X of 2 in cream on red |
| Gambrel roof | ridge along x. Each side: a steep plane from the eave (z = plus or minus 10.4, y 17) to (plus or minus 7, 22.9) and a shallow one on to the ridge (0, 26.2); each plane is 9 tin strips 3.18 wide x 0.3 thick (36 in all), weathered tin 132,136,138 (Metal), one in four CorrodedMetal 118,84,62; shadows on |
| Gable ends | each end (x = plus or minus 13.3): a block 0.4 x 5.9 x 14, two Wedges for the steep sides, two for the upper triangle, in barn red; a dark loft window 3 x 3 with a cream frame on the front gable |
| Ridge and cupola | ridge cap 29 x 0.4 x 0.8; a cupola (box 3 x 3 x 3, cross-gable of four Wedges, a weathervane of 4 parts) |
| Loft frame | 7 joists 0.5 x 0.6 x 9 under the loft at y 9.2; 2 posts 0.8 x 9.5 x 0.8 against the side walls at the loft's front edge |
| Hay hood | a beam 0.6 x 0.6 x 3.5 out of the front ridge, a rope and a hanging bale |
| Lean-to | against the back wall, 2.2 deep: a sloped roof 10 x 0.3 x 2.6, 2 posts, 12 firewood logs (Cylinders 2 x 0.7 x 0.7) (Fine) |
| Stair bales | each of the six: 2 paler cut-end caps and 2 wisps (Fine) |
| Light | 3 warm Neon slits (Block 0.15 wide x 6 tall x 0.1 thick, 255,232,190) high on the inside of the wall that faces `ctx.sun` most, each with two `Dress.beam` shafts running down along `-ctx.sun` to the floor (6 Beams: Width0 1.2 and 3, Width1 3.6 and 9, Transparency 0.92 to 1, LightEmission 1, LightInfluence 0, FaceCamera); 2 hanging lanterns (Point, range 20, brightness 1.2); one SpotLight over the doorway pointing down and out (range 32, angle 110, brightness 1.6, 255,179,73, **shadows on**: one of the map's two) |

### 5.4 Windmill (stonehedge yard): `MillKit.build(ctx, x, z)` and `MillKit.dress(ctx, x, z, steps, lastAngle)`, up to 220
`Landmarks.windmill` stops calling `FarmProps.windmill` (which stays for the Windmill Hill map)
and calls `MillKit.build`, which makes the same colliders: tower Cylinder 14 x 9 x 9 named
`Windmill` (with `MapKit.spotsOn(ctx, tower, 0, 5)`), `Cap` 8 x 6 x 8 at y 17, `Roof` 8.6 x 1 x 8.6 at
y 20.4, and the hub at (x, 17, z - 4.6) tweened round every 12 s. The `Balcony` (Cylinder 1 x 15 x 15,
top 12) and five spiral stones at radius 10 stay in `Landmarks.windmill`.
| Dressing | Recipe |
|---|---|
| Staves | 16 round the tower: Block 2.1 x 14.3 x 0.45, radius 5.3 at the foot and 4.6 at the top (leaning in 2.9 degrees), Plaster 226,220,204 |
| Footing | 12 Cobblestone blocks 2.9 x 2.2 x 0.9 at radius 5.5, y 1.1, 138,132,122 |
| Cap and roof | cap recoloured dark timber 96,74,56; over the roof slab two Wedges 8.8 x 3 x 4.4 back to back (ridge along the hub's axis), Slate 88,70,58, and a ridge cap |
| Sails | four lattice sails welded to the hub (`Dress.weld`; unanchored, Massless): stock 0.35 x 11.5 x 0.35, 2 rails 0.15 x 9 x 0.15, 7 bars 2.4 x 0.12 x 0.12, canvas 2.2 x 8.6 x 0.06 Fabric 232,224,200 (11 parts a sail; stock and canvas cast shadows) |
| Fantail | behind the cap: a hub, 6 blades 0.2 x 2.2 x 0.6 and a frame of 3 (Fine) |
| Door and windows | a dark door 2.2 x 4.6 x 0.3 on the +x side under an arch of 5 small stones, a step; 3 dark windows 1 x 1.6 x 0.2 with stone lintels up the tower, the top one warm Neon with `Dress.light` (Point, range 16) |
| Balcony | 12 brackets 0.4 x 0.4 x 3 at 45 degrees under the disc; 12 rail posts 0.25 x 2.6 x 0.25 at radius 7.3 and 10 rail pieces 0.2 x 0.2 x 3.8 at y 14.4, open on the side facing `lastAngle` |
| Supports | under each spiral stone a collidable `Support` pier 2.2 x (stone underside) x 2.2, Cobblestone |

### 5.5 Hay Tower (0, 0): `LandmarkSkins2.hayTower(ctx, x, z, h, bales)`, h = 26, up to 160
Existing: the mast (Cylinder 32 x 3 x 3), 11 climb bales 5 x 2.5 x 4 at radius 7, deck 10 x 1 x 10
(top 26.5), a flag. `Landmarks.hayTower` passes its bale parts to the skin.
| Dressing | Recipe |
|---|---|
| Arms | under each bale an arm 0.6 x 0.6 x 7 out from the mast and, where the bale is more than 3 up, a knee brace 0.5 x 0.5 x 3.2 at 45 degrees; Wood 104,70,42; **not** collidable, so the crossroads stays as open as now |
| Mast | 5 iron bands (Cylinder 0.3 x 3.2 x 3.2, CorrodedMetal) |
| Bales | each: 2 twine bands, 2 paler cut-end caps (Fine) |
| Deck | 4 joists, 8 posts 0.3 x 2.6 x 0.3 and rails on all four sides (decoration) |
| Banners | four gold banners 0.1 x 9 x 2.4 (255,205,70, Fabric) hanging from the deck's edge down each road axis, each on a short pole |
| Bunting | four lines from the deck corners down to short posts (0.3 x 3 x 0.3) standing on top of the four wall corners at (plus or minus 10, plus or minus 10, y 10): 12 Fabric Wedge flags 0.06 x 0.9 x 0.8 a line, in the four quarter colours (Fine) |
| Top | the flag stays; a needle weathervane (a pole, a thin Metal Cylinder 4 long, an eye ring); a Neon beacon with a SpotLight pointing down over the deck (range 28, angle 120, brightness 1.4, **shadows on**: the map's second) |
| Derrick | a boom 0.5 x 0.5 x 6 off the deck with a hanging bale (5 parts) |

### 5.6 Water tower (-168, 168): `LandmarkSkins2.waterTower(ctx, x, z, h)` and `windPump`, up to 140
Existing: 4 legs, tank (Cylinder 6 x 8 x 8 at y 17), deck 9 x 1 x 9 (top 20.5), ladder truss.
| Dressing | Recipe |
|---|---|
| Tank | 20 staves 1.3 x 6.1 x 0.3 at radius 4.05, WoodPlanks 124,100,78 toned 8%; 3 hoops (Cylinder 0.25 x 8.5 x 8.5, CorrodedMetal) |
| Frame | 8 X-braces and 4 girts between the legs; 4 Slate pads 2 x 0.5 x 2 under them |
| Spout | a pipe (Cylinder 3 x 0.5 x 0.5) off the tank; a drip emitter (6.2); a puddle under it (5.11) |
| Lamp | on the deck's edge: Neon block, `Dress.light` (Point, range 20, brightness 1.1) |
| Wind pump | `LandmarkSkins2.windPump(ctx, -192, 192, 16)`, outside the hedge: a lattice mast (4 legs, 8 braces), a hub tweened round every 5 s, 12 welded blades, a tail vane (30 parts) |

### 5.7 Balloons: `LandmarkSkins.balloon(ctx, top, colour)` (5 parts each, 6 of them)
Over each landmark's chest top: a tether Block 0.1 thick up to y = 70, a Ball 7 across in the
quarter's colour (the Hay Tower's is gold), a small knot and two darker stripes. From a corridor a
24-stud landmark hides behind the wall within about 27 studs; a balloon at 70 shows from about 100.
`ConfigFarm.Balloons.on` switches them off.

### 5.8 What each quarter holds: `FarmDress.quarter(ctx, id, maze, room)`
This replaces the `props` closures in `MapsBig`. The gameplay props keep their colliders and
hiding spots (drawn from `ctx.rng`, placed with `MapsA.inCell` as now); the dressing is new.
| Quarter | Gameplay props (as today) | New dressing |
|---|---|---|
| corn | hay cart in the clearing, scarecrow at (+6, +5), 6 crow posts, 8 bales | bales dressed (`GroundKit.baleDress`); 150 husks (`GroundKit.litter`); 6 leaning tools against walls; a wheelbarrow in the clearing |
| vines | a patch of 9 pumpkins, a pumpkin cart at (+6, -6), 18 pumpkins in cells | every pumpkin dressed (`Flora.pumpkin`); 54 pumpkin leaves; 4 crates; milk churns in the clearing |
| hedge | cider press in the clearing, 10 crate stacks | 24 apple trees growing out of the hedges (`Flora.inWalls`); 180 fallen leaves and 60 windfall apples; 4 ladders leaning on trees; a beehive row in the clearing |
| stonehedge | 5 flour sacks in the clearing, 14 in cells | 8 trees in the hedges; 60 fallen stones; a millstone and a sack stack in the clearing |

`FarmProps` keeps every function's signature, collider and spots; its looks improve: the cart gets
plank sides, spoked wheels (a rim Cylinder, 4 spoke Blocks, a hub) and iron tyres; the scarecrow a
straw collar and patches; the crow a tail and wings; apple crates slats; the flour sack a tied neck;
the cider press hoops and a spout.

### 5.9 Trees: `Flora.tree(ctx, x, z, h, kind)`
Leaves are LeafyGrass in 62,98,44 to 96,124,52, one tree in five turning 150,128,52. One canopy Ball
sits towards `ctx.sun` in the lighter 104,140,62 and one in the middle is the darker 52,84,44
(painted light). Two Balls and the trunk cast shadows.
| Kind | Where | Recipe | Parts |
|---|---|---|---|
| oak | 16 road trees on the ring's outer verge at (plus or minus 132, plus or minus 181.2), (plus or minus 66, plus or minus 181.2) and the same with x and z swapped; h 20 to 26 | a collidable `Trunk` 2 x 0.5h x 2 (`MapKit.part`, with 2 hiding spots at its foot as `MapKit.tree` gives), an upper trunk 1.3 x 0.5h x 1.3 turned 45 degrees, 3 limbs 0.7 x 5 to 7 x 0.7 at 40 to 60 degrees, 4 root Wedges, 6 Balls 7 to 11 across, 6 leaf cards 0.05 x 6 x 6 | 22 |
| line | `Flora.treeLine`: 48 trees in 16 clumps of 2 to 4, 191 to 197 out, h 22 to 30; none within 24 of a road axis or 14 of (-192, 192) | the oak without the roots and with 4 cards and 5 Balls; nothing collides | 14 |
| wall | `Flora.inWalls(ctx, maze, n, apples)`: at the middle of randomly chosen wall runs | no lower trunk (the hedge hides it): 2 limbs from y 8, 4 Balls 5 to 7 across at y 11 to 15, 3 cards, and with `apples` 6 Balls 0.7 across in 214,40,40 (Fine) | 15 |

### 5.10 Road cover and corners: `FarmDress.roads(ctx, plan)` (after the spawns are placed)
- **Cover** on the ring road: candidates every 48 studs along each side, alternating between the
  inner edge (centre 159.5) and the outer edge (centre 178). A candidate is dropped if it is within
  12 studs of a spawn, 10 of a gate that opens on the ring, 30 of a corner, or 20 of a road axis.
  Each item is at most 5 deep and 8 long, so at least a 20-stud lane stays clear. Items in turn:
  `FarmSet.baleStack` (three bales and two on top, as `MapKit.bale`, with their spots),
  `FarmSet.wagon`, `FarmSet.trough` (a trough and a hand pump), `FarmSet.pallets`,
  `Flora.shock` twice (a corn shock: a collidable `Cover` core 2.6 x 5 x 2.6 inside 6 leaning
  stalk bundles and a twine band). Each has one or two collidable cores (`MapKit.part`, named
  `Cover`) and adds hiding spots with `MapKit.spot`. The cross roads stay clear.
- **Corners:** (168, -168) `FarmSet.tractor` with `FarmSet.trailer` (an original blocky tractor in
  teal 72,118,122: about 60 parts, big rear wheels, exhaust, seat; a hay trailer of about 50);
  (168, 168) a bale yard (`FarmSet2.roundBales`: 3 round bales and a stack); (-168, -168)
  `FarmSet2.sheepPen` (a 12 x 12 pen of `MapKit.fence` and three blocky sheep of 6 parts);
  (-168, 168) is the water tower's.
- **Crossroads:** `FarmSet2.signpost` at (8.2, 8.2), tucked into a corner of the crossing: a post
  0.5 x 9 x 0.5 with four finger boards at y 7 to 8.5 in the quarter colours, each pointing into
  its quarter (decoration only).
- **Puddles:** 14 `GroundKit.puddle` in the road ruts (5.11).
- **Verges:** `GroundKit.verge(ctx, plan)`: 200 weed tufts and 100 flower specks along wall feet
  and road edges where the ground is not Grass; 20 rock clusters at wall corners.

### 5.11 Ground contact: `GroundKit`
| Piece | Recipe | Tier |
|---|---|---|
| `skirt(ctx, cf, size)` | a dirt Wedge against a building or pier: 0.6 high, 1.2 out, Ground 104,86,60; about 60 on the map (barn, silo pad, piers, cover) | Detail, no shadow |
| `tuft` (in `verge`) | two crossed Blocks 0.06 x 0.9 to 1.4 x 0.7, greens 96,124,60 to 150,150,80 | Fine |
| flower speck | Block 0.35 x 0.12 x 0.35 at y 0.9 on a tuft: white, 240,206,80 or 150,120,190 | Fine |
| rock cluster | 3 Blocks up to 1.4 x 0.6 x 1.1, turned, Rock and Slate greys | Detail, no shadow |
| `litter(ctx, maze, kind, n)` | `husks` 0.9 x 0.06 x 0.25 in 214,190,120; `leaves` 0.6 x 0.05 x 0.6 in 170,120,50 to 120,96,50; `pumpkinLeaves` 1.6 x 0.06 x 1.6 in 70,110,50; `stones` 0.5 to 0.9 cubes in greys; `windfalls` Balls 0.6 in 200,60,50. All lie within 5 studs of a wall on that quarter's bare ground (stones stand on it) | Fine |
| `puddle(ctx, x, z, r)` | Cylinder 0.05 thick, 2r across, top at y 0.1, SmoothPlastic 44,40,36, `Reflectance = 0.35` | Fine |
| `baleDress(ctx, bale)` | 2 paler cut-end caps 0.06 thick (232,204,128) and 3 wisps 0.1 x 0.1 x 0.8 | Fine |

---

## 6. FX

### 6.1 Lights (all through `Dress.light`, which counts them)
| Light | Count | Values |
|---|---|---|
| Gate lanterns | up to 32 | PointLight, range 14, brightness 0.9, 255,190,110, no shadows |
| Landmark lamps | 5 | PointLight, range 16 to 20, brightness 1 to 1.2 |
| Barn | 2 lanterns and 1 doorway SpotLight | the SpotLight casts shadows (5.3) |
| Hay Tower beacon | 1 SpotLight | casts shadows (5.5) |
| Chests and power-ups | as now | unchanged |
Two shadow-casting lights; the cap is 4 (`ConfigFarm.Budget.shadowLights`).

### 6.2 Particles and beams (through `Dress.emitter` and `Dress.beam`; hosts in `Arena.Fx`)
`soft` = `rbxasset://textures/particles/smoke_main.dds`; `spark` = the default texture (leave
`Texture` unset). Every emitter that should drift has `Drag = 1.5`, `WindAffectsDrag = true`.
| Effect | Built by | Hosts | Values |
|---|---|---|---|
| Dust motes | `FarmFx.build` | 5 boxes 80 x 16 x 80 at y 10 over the crossroads, the middle of the corn and mill quarters and two ring-road sides; one box 24 x 12 x 16 in the barn | spark; `Shape = "Box"`, `ShapeStyle = "Volume"`; Rate 15; Lifetime 6 to 10; Speed 0.2 to 0.6; SpreadAngle 180,180; Size 0.08 to 0.15; Transparency 1, 0.6, 1; LightEmission 0.6; Color 255,236,190 |
| Chaff | `FarmFx.build` | 2 boxes 60 x 6 x 60 at y 12 over the corn | soft; Rate 6; Lifetime 5 to 8; Size 0.25; RotSpeed -90 to 90; Color 240,220,160; Transparency 0.2 to 1 |
| Leaves | `FarmFx.build` | under 8 orchard wall trees | soft; Rate 1; Lifetime 6; Size 0.3; Acceleration 0,-1.5,0; RotSpeed -180 to 180; Color 170,120,50 |
| Fireflies | `FarmFx.build`, only when `ctx.diff.dim >= 0.3` | 6 boxes 30 x 6 x 30 in the orchard and mill quarters | spark; Rate 4; Lifetime 4 to 7; Size 0, 0.2, 0; LightEmission 1; LightInfluence 0; Brightness 3; Color 220,255,150 |
| Tank drip | `LandmarkSkins2.waterTower` | the spout | spark; Rate 2; Lifetime 1.2; Speed 0; Acceleration 0,-30,0; Size 0.12 |
| Barn shafts | `BarnKit.dress` | 6 Beams (5.3) | |
| Chimney smoke | `Vista.build` | the farmhouse chimney | soft; `EmissionDirection = "Top"`; Rate 3; Lifetime 5 to 8; Speed 3 to 4; SpreadAngle 8,8; Size 1.5 to 6; Transparency 0.5 to 1 |
| Pond mist | `Vista.build` | 2 boxes 40 x 2 x 40 over the pond | soft; Rate 1.5; Lifetime 12 to 18; Size 18 to 30; Transparency 1, 0.92, 1; Drag 1 |
Steady-state particles: about 950 (cap 1,500). Beams: 6 (cap 12). Particles carry no gameplay.

### 6.3 Motion
Windmill sails (12 s), fantail still; the wind pump by the water tower (5 s) and three far ones
(6 s); three circling birds; grass blades and clouds on `GlobalWind`; tumbling hay on Hard rounds
as now. All by `TweenService` on an anchored hub with welded parts, as `FarmProps.windmill` does.

---

## 7. BUDGET

Hayfield Farm, whole world while a round is on (ceiling 25,000; `ConfigFarm.Budget`).

| Category | Root (gameplay) | Detail | Fine | Far |
|---|---|---|---|---|
| Floor, boundary colliders | 9 | | | |
| Wall cores (260 runs; stone runs have 2) | 295 | | | |
| Wall dressing: corn 4,080 · vines 2,040 · hedge 1,530 · stonehedge 2,465 | | 5,100 | 5,015 | |
| Gates (up to 32 x 16) | | 256 | 256 | |
| Landmarks (existing 95, supports 11) and their dressing | 106 | 720 | 400 | |
| Balloons | | 30 | | |
| Hedge bank, corners, field gates | | 672 | 80 | |
| Trees: line 48 x 14 · road 16 x 22 · wall 32 x 15 | 16 | 864 | 624 | |
| Quarter props (gameplay as now) and dressing | 260 | 420 | 300 | |
| Road cover, corners, signpost | 70 | 330 | 120 | |
| Ground contact (skirts, tufts, flowers, rocks, litter, puddles) | | 120 | 1,010 | |
| Loose straw and tumbling hay (the difficulty setting, unchanged) | up to 1,152 | | | |
| Chests, perches, steps, power-ups | 90 | | | |
| FX hosts | | | 25 (in `Fx`) | |
| Backdrop (built once) | | | | 1,000 |
| **Totals** | **about 2,000** | **about 8,500** | **about 7,800** | **1,000** |

**About 19,300 parts on the high tier; about 11,500 on mid and low.**

| Limit | Target | Cap asserted by `check_maps.py` |
|---|---|---|
| Parts | 19,300 | 25,000 |
| Balls and Cylinders | about 1,450 (1,962 today) | 1,800 |
| Part materials | 16 (Grass, LeafyGrass, Wood, WoodPlanks, Slate, Rock, Cobblestone, Metal, CorrodedMetal, DiamondPlate, Fabric, Plaster, Ground, SmoothPlastic, Neon, Sand) | 18 |
| Semi-transparent parts | 0 new (windows are dark SmoothPlastic or Neon; puddles are opaque and reflective) | 150 |
| Shadow-casting parts | about 2,300 | not asserted (reported) |
| Local lights with shadows | 2 | 4 |
| Local lights in all | about 55 | 70 |
| Steady particles | about 950 | 1,500 |
| Beams | 6 | 12 |

Pacing: `Dress.part` yields once every `Budget.pauseEvery` (2,500) decoration parts when
`ctx.pace` is set (RoundManager sets it; maprun does not), and RoundManager waits
`Budget.settle` (1.5 s) after the build before anyone is moved in, so the map replicates behind
the loading phase. If the decoration count passes `Budget.parts - 1500`, further Fine parts are
made but not parented (they never replicate).

---

## 8. INTERFACES

Paths are under `needle-hunt/`. "Returns" is what the caller may rely on. Modules marked (edit)
exist today; the rest are new. Every new server module starts with a short header comment in the
repo's style and requires only what is listed.

### 8.1 `src/shared/ConfigFarm.luau` (new, foundation): the world-building numbers
Requires nothing. `Config.luau` gains `Config.Farm = require(script.Parent.ConfigFarm)` (integrator);
builders require it directly: `require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ConfigFarm"))`.

```lua
local Farm = {}
Farm.Budget = { parts = 25000, round = 1800, materials = 18, transparent = 150, shadowLights = 4, lights = 70,
	particles = 1500, beams = 12, pauseEvery = 2500, settle = 1.5, wallDensity = 1 }
Farm.sunFallback = { -0.62, 0.59, 0.52 } -- towards the sun, when Lighting can't say (section 2.4)
Farm.centreColour = { 255, 205, 70 }
Farm.Quarters = { -- by maze style: banner colour and terrain (section 3.5); link = false for none
	corn = { colour = { 236, 196, 60 }, floor = "Ground", yard = "Cobblestone", strip = "Mud", link = false, sill = "Mud", icon = "cob" },
	vines = { colour = { 232, 128, 40 }, floor = "Mud", yard = "Ground", strip = "LeafyGrass", link = "Ground", sill = "Ground", icon = "pumpkin" },
	hedge = { colour = { 170, 44, 40 }, floor = "Grass", yard = "Ground", strip = "LeafyGrass", link = "Ground", sill = "Ground", icon = "apple" },
	stonehedge = { colour = { 70, 110, 170 }, floor = "LeafyGrass", yard = "Cobblestone", strip = "Ground", link = "Cobblestone", sill = "Ground", icon = "sail" },
}
Farm.Terrain = {
	half = 188, depth = 16, outer = 448, flat = 232, rollWidth = 90, laneHalf = 6, laneRise = 6,
	rim = { from = 340, width = 60, height = 44, fallFrom = 404, fallWidth = 40 }, top = 48, chunk = 128,
	pond = { x = -292, z = 0, bowl = 20, water = 15 },
	colours = { Grass = { 88, 124, 54 }, LeafyGrass = { 96, 118, 60 }, Ground = { 134, 108, 76 }, Mud = { 84, 66, 50 }, Cobblestone = { 150, 146, 136 }, Rock = { 112, 110, 104 } },
	water = { colour = { 58, 92, 84 }, transparency = 0.45, reflectance = 0.6, waveSize = 0.05, waveSpeed = 6 },
	fields = { -- x0, z0, x1, z1, material, what it is (section 3.2)
		{ -180, -232, -24, -188, "Sand", "stubble" }, { 24, -232, 180, -188, "Ground", "wheat" },
		{ -180, 188, -24, 232, "Ground", "ploughed" }, { 24, 188, 180, 232, "Sand", "stubble" },
		{ -232, -180, -188, -24, "LeafyGrass", "meadow" }, { -232, 24, -188, 180, "Ground", "wheat" },
		{ 188, -180, 232, -24, "Ground", "ploughed" }, { 188, 24, 232, 180, "LeafyGrass", "meadow" },
	},
}
Farm.Walls = { -- counts per 16 studs of wall (section 4)
	corn = { stalkGap = 1, bent = 0.125, tassel = 0.5, ear = 0.25 },
	vines = { postGap = 8, slabs = 8, lumps = 2, stems = 4, cards = 3, gourds = 2 },
	hedge = { panels = 6, lumps = 3, cards = 4, sprigs = 2 },
	stone = { courses = { 1.9, 1.7, 1.4 }, length = { 2.2, 4.2 }, caps = 4, mossy = 0.125, hedgeShare = 0.67, footings = 4 },
}
Farm.Balloons = { on = true, height = 70, size = 7 }
Farm.Cover = { every = 48, spawnClear = 12, gateClear = 10, cornerClear = 30, axisClear = 20 }
Farm.Lights = { gate = { range = 14, brightness = 0.9, colour = { 255, 190, 110 } }, lamp = { range = 18, brightness = 1.1, colour = { 255, 196, 120 } },
	barn = { range = 32, angle = 110, brightness = 1.6, colour = { 255, 179, 73 } }, beacon = { range = 28, angle = 120, brightness = 1.4, colour = { 255, 214, 150 } } }
Farm.Fx = { soft = "rbxasset://textures/particles/smoke_main.dds", beamTexture = "", -- beamTexture: an uploaded soft gradient, later
	motes = { rate = 15, life = { 6, 10 }, size = { 0.08, 0.15 } }, chaff = { rate = 6 }, leaves = { rate = 1 }, fireflies = { rate = 4, dim = 0.3 } }
Farm.Palette = { -- every colour the builders share (section 1); recipes name them
	straw = { 214, 180, 90 }, strawPale = { 232, 204, 128 }, cornDry = { 196, 170, 92 }, cornGreen = { 128, 138, 66 }, cornCore = { 104, 96, 52 }, husk = { 168, 172, 96 },
	hedge = { 58, 100, 48 }, hedgeCore = { 44, 78, 40 }, hedgeLight = { 84, 128, 60 }, hedgeBase = { 40, 52, 34 }, vineCore = { 44, 84, 40 },
	leaves = { { 58, 98, 44 }, { 74, 116, 50 }, { 92, 128, 58 } }, leafTurn = { 150, 128, 52 }, leafSun = { 104, 140, 62 }, leafShade = { 52, 84, 44 },
	timber = { 112, 96, 80 }, timberDark = { 104, 88, 70 }, log = { 104, 70, 42 }, bark = { 96, 74, 54 },
	barnRed = { { 142, 52, 44 }, { 128, 46, 40 }, { 156, 64, 52 } }, barnSilver = { 150, 132, 118 }, barnInside = { 88, 66, 48 }, trim = { 232, 226, 210 },
	tin = { 132, 136, 138 }, galvanised = { 150, 156, 160 }, steelDark = { 120, 126, 132 }, rust = { 128, 78, 50 }, rustRoof = { 118, 84, 62 }, oxblood = { 128, 44, 38 },
	whitewash = { 226, 220, 204 }, stone = { 138, 176 }, stoneMoss = { 96, 108, 78 }, stoneCore = { 92, 90, 86 }, cobble = { 138, 132, 122 }, slateRoof = { 88, 70, 58 },
	soil = { 112, 90, 62 }, dirt = { 104, 86, 60 }, canvas = { 232, 224, 200 }, lantern = { 255, 196, 120 }, window = { 30, 28, 26 }, puddle = { 44, 40, 36 }, tractor = { 72, 118, 122 },
}
return Farm
```

### 8.2 `src/server/Dress.luau` (new, foundation): the decoration factory
Requires `ConfigFarm` only (not `MapKit`, so `MapKit` and everything else may require it).

| Function | Does and returns |
|---|---|
| `Dress.rng(ctx) -> Random` | the decoration stream: made on first use as `Random.new(ctx.rng:NextInteger(1, 1000000))` and kept in `ctx.decoRng` |
| `Dress.folder(ctx, tier) -> Folder` | `tier` is `"Detail"`, `"Fine"`, `"Far"` or `"Fx"`; the Folder of that name under `ctx.model`, made on first use (errors on any other name) |
| `Dress.part(ctx, tier, props) -> Part` | a decoration Part: `Anchored = true`, `CanCollide`, `CanQuery`, `CanTouch` false, smooth surfaces, `Material` SmoothPlastic unless given, `CastShadow` false unless given, `Name` = the tier unless given. `props` as `MapKit.part` takes them (`Color` as `{r,g,b}` or Color3; `Material` and `Shape` as strings or enums; `Size`, `CFrame`, `Transparency`, `Reflectance`, `Anchored = false` for welded movers). Passing `CanCollide`, `CanQuery` or `CanTouch = true`, or `Parent`, is an error. Parented last. Counts into `ctx.count[tier]`; yields when `ctx.pace` (section 7); over budget, a Fine part is returned unparented |
| `Dress.tone(rgb, pct, rng) -> {r,g,b}` | all three channels times one random factor in 1 plus or minus `pct`, clamped to 0..255 |
| `Dress.shade(rgb, k) -> {r,g,b}` | times `k` |
| `Dress.mix(a, b, t) -> {r,g,b}` | a lerp |
| `Dress.pick(list, rng) -> any` | a random entry |
| `Dress.weld(hub, part)` | `part.Anchored = false`, `part.Massless = true`, a WeldConstraint to `hub` (for sails and fans) |
| `Dress.light(ctx, part, spec) -> Instance` | `spec = { kind = "Point" or "Spot" or "Surface", range, brightness, colour = {r,g,b}, shadows = false, angle, face = "Bottom" }`; makes the light under `part`; counts `ctx.count.lights` and `shadowLights`; past `Budget.shadowLights` it is made without shadows |
| `Dress.host(ctx, cf, size, name) -> Part` | an invisible decoration Part in `Fx` to hold an emitter or attachments |
| `Dress.emitter(ctx, host, spec) -> ParticleEmitter or nil` | `spec` keys are ParticleEmitter property names with plain values: numbers and booleans as they are; `Lifetime`, `Speed`, `RotSpeed`, `Rotation` as `{min, max}`; `Size` and `Transparency` as a number, `{from, to}` or `{ {time, value}, ... }`; `Color` as `{r,g,b}` or two of them; `SpreadAngle` as `{x, y}`; `Acceleration` as `{x, y, z}`; `Shape`, `ShapeStyle`, `EmissionDirection` as enum item names. Counts `Rate * Lifetime max` into `ctx.count.particles`; returns nil (makes nothing) past `Budget.particles` |
| `Dress.beam(ctx, from, to, spec) -> Beam or nil` | a host at `from` with two Attachments (the second at `to`); `spec`: `Width0`, `Width1`, `Transparency`, `Color`, `LightEmission`, `LightInfluence`, `FaceCamera`, `Segments`, `Texture` (default `Farm.Fx.beamTexture`); counts `ctx.count.beams`; nil past `Budget.beams` |

`ctx.count = { Detail, Fine, Far, Fx, lights, shadowLights, particles, beams }` (numbers).

### 8.3 Look (package `look`)
**`src/shared/ConfigLook.luau`** (new): requires nothing; `Config.Look = require(script.Parent.ConfigLook)` (integrator).

```lua
local Look = {}
Look.presets = {
	harvest = { ClockTime = 15.0, sunElevation = 36, Brightness = 3, ExposureCompensation = 0.05,
		Ambient = { 58, 54, 62 }, OutdoorAmbient = { 108, 104, 116 }, ColorShift_Top = { 52, 32, 10 }, ShadowSoftness = 0.2,
		Atmosphere = { Density = 0.3, Offset = 0.25, Haze = 1.5, Glare = 0.3, Color = { 228, 198, 148 }, Decay = { 116, 104, 120 } },
		Clouds = { Cover = 0.52, Density = 0.35, Color = { 255, 240, 222 } },
		Bloom = { Intensity = 0.6, Size = 28, Threshold = 1.7 },
		Grade = { Contrast = 0.12, Saturation = 0.08, TintColor = { 255, 245, 232 } },
		SunRays = { Intensity = 0.1, Spread = 0.6 }, -- false = off
		Wind = { 9, 0, 4 } },
	-- gold, noon, overcast, dusk, night, interior: the same keys, from the table in section 2.3
}
Look.lobby = "noon"
Look.Sun = { from = 12.5, to = 17.5, step = 0.05 }
Look.Dim = { exposure = 1.6, ambient = 0.5, density = 0.1, saturation = 0.15, tint = { 200, 214, 255 }, tintMix = 0.5 }
Look.Gust = { amount = 0.3, every = { 6, 10 } }
Look.Sky = { SunAngularSize = 14, MoonAngularSize = 9, StarCount = 3000 }
Look.DepthOfField = { FarIntensity = 0.15, NearIntensity = 0, FocusDistance = 120, InFocusRadius = 50 }
Look.Tiers = { start = "high", touchStart = "mid", fpsDrop = 28, window = 4 }
return Look
```

**`src/server/Look.luau`** (new): requires `ConfigLook`.
| Function | Does and returns | Called by |
|---|---|---|
| `Look.init()` | section 2.2; safe to call twice | `Main.server`, first step |
| `Look.apply(name, dim) -> preset` | section 2.6; an unknown name warns and uses `noon`; `dim` defaults to 0; also `ReplicatedStorage:SetAttribute("Look", name)` | `RoundManager` (round start, round end, failure, `start`) |
| `Look.sunFor(name) -> Vector3 or nil` | section 2.4 | `RoundManager`, into `ctx.sun` |
| `Look.preset(name) -> table` | the preset, or `noon` | internal, tests |

**`src/client/LookFx.luau`** (new): requires `ConfigLook`.
| Function | Does and returns | Called by |
|---|---|---|
| `LookFx.start()` | section 2.6: tiers, pruning, depth of field | `Main.client.luau` |
| `LookFx.tier() -> "high" or "mid" or "low"` | the current tier | nobody yet (Settings later) |

### 8.4 Land (package `land`)
**`src/server/Landscape.luau`** (new): requires `ConfigFarm`, `Config`, `MapKit`, `Vista`.
| Function | Does and returns | Called by |
|---|---|---|
| `Landscape.height(x, z) -> number` | section 3.2, map-local | `Vista`, itself, the preview through maprun |
| `Landscape.column(x, z) -> number, string` | height and terrain material name | itself |
| `Landscape.backdrop(centre) -> bctx` | section 3.2; idempotent; yields between chunks | `Main.server` (game servers and Studio), `run_map.py` for bigfarm |
| `Landscape.floor(ctx, half) -> Part` | section 3.4; returns the `Ground` part | `MapsBig` |
| `Landscape.paint(ctx, x0, z0, x1, z1, material)` | section 3.5; `material` a name or enum | itself, `MapsBig` if needed |
| `Landscape.farm(ctx, plan)` | section 3.5 | `MapsBig` |
| `Landscape.colours(overrides)` | section 3.1; `overrides` may be nil | `RoundManager` each round |
| `Landscape.clear(centre)` | section 3.6 | `RoundManager` (three places) |
| `Landscape.lobby(centre)` | section 3.7 | `Main.server` |

**`src/server/Boundary.luau`** (new): requires `ConfigFarm`, `MapKit`, `Dress`.
`Boundary.build(ctx, half)` (section 3.8), called by `MapsBig` in place of `MapKit.edges`.

**`src/server/Vista.luau`** and **`VistaSets.luau`** (new): require `ConfigFarm` and `Dress` only
(never `Landscape`: it requires them). `Vista.build(bctx, height)` (section 3.3) is called by
`Landscape.backdrop`, which passes `Landscape.height` as `height(x, z) -> number`.
`VistaSets.barn / windPumps / farmhouse / pond(bctx, x, y, z, facing)` are Vista's own helpers
(`y` = the ground height there).

### 8.5 Walls (package `walls`)
- **`src/server/MazeKit.luau`** (edit): adds `maze.runs`, `maze.links`, `maze.gates` (section 4.6).
- **`src/server/MazeWalls.luau`** (edit): `corn`, `vines`, `stone`, `stonehedge` build the core and
  call the kit; new `MazeWalls.hedge(ctx, a, b, height, T)`. Same signatures as today.
- **`src/server/WallKitCrop.luau`** (new): `corn(ctx, cf, len, height, T)`, `vines(ctx, cf, len, height, T)`.
- **`src/server/WallKitHedge.luau`** (new): `hedge(ctx, cf, len, height, T, y0, share)`,
  `stone(ctx, cf, len, height, T)`, `footings(ctx, cf, len)`.
- **`src/server/GateKit.luau`** (new): `GateKit.gates(ctx, maze, quarterId) -> number` (gates
  dressed; called by `MapsBig` after each maze); `GateKit.arch(ctx, a, b, out, quarterId)`.
All kits return nothing, require `ConfigFarm`, `Dress` (and `MapKit` only for `MapKit.at`), and
draw only from `Dress.rng(ctx)`.

### 8.6 Landmarks (package `landmarks`)
- **`src/server/Landmarks.luau`** (edit): same six public functions and return values. `spiral`
  returns `steps, lastAngle`. `windmill` calls `MillKit.build`, not `FarmProps.windmill`.
- **`src/server/LandmarkSkins.luau`** (new): `silo(ctx, x, z, h)`, `lookout(ctx, x, z, h, steps, lastAngle)`,
  `balloon(ctx, top, colour)` (`top` is the world Vector3 a landmark returned; called by `MapsBig`).
- **`src/server/LandmarkSkins2.luau`** (new): `waterTower(ctx, x, z, h)`, `windPump(ctx, x, z, h)`,
  `hayTower(ctx, x, z, h, bales)`.
- **`src/server/BarnKit.luau`** (new): `BarnKit.dress(ctx, x, z, dims, bales)` with
  `dims = { W = 26, D = 18, H = 16, loftY = 10 }`.
- **`src/server/MillKit.luau`** (new): `MillKit.build(ctx, x, z) -> tower Part`,
  `MillKit.dress(ctx, x, z, steps, lastAngle)`.
All require `ConfigFarm`, `Dress`, `MapKit`; none requires another package's module.

### 8.7 Dressing (package `dressing`)
- **`src/server/FarmProps.luau`** (edit): signatures, colliders and spots unchanged; looks per 5.8.
- **`src/server/Flora.luau`** (new): `tree(ctx, x, z, h, kind) -> Part or nil` (the `Trunk` for an
  oak), `treeLine(ctx, half)`, `roadTrees(ctx, ring, half)`, `inWalls(ctx, maze, n, apples) -> { Vector3 }`
  (the canopy centres, for leaf emitters), `pumpkin(ctx, body)` (dresses an existing pumpkin Ball:
  two lobes, a curled vine, a leaf), `shock(ctx, x, z) -> Part` (its `Cover` core).
- **`src/server/FarmSet.luau`** (new): `tractor`, `trailer`, `wagon`, `baleStack`, `trough`,
  `pallets`, each `(ctx, x, z, yaw) -> Part` (its main collidable core; each records its own spots).
- **`src/server/FarmSet2.luau`** (new): `signpost(ctx, x, z)`, `roundBales(ctx, x, z)`,
  `sheepPen(ctx, x, z)`, `barrow`, `churns`, `hives`, `tools(ctx, cf)`, `millstone`, `sackStack`.
- **`src/server/GroundKit.luau`** (new): `skirt(ctx, cf, size)`, `litter(ctx, maze, kind, n)`,
  `puddle(ctx, x, z, r)`, `baleDress(ctx, bale)`, `verge(ctx, plan)`.
- **`src/server/FarmDress.luau`** (new): `quarter(ctx, id, maze, room)` (section 5.8),
  `roads(ctx, plan)` (section 5.10). Called by `MapsBig`.
- **`src/server/FarmFx.luau`** (new): `build(ctx, plan)` (section 6.2). Called last by `MapsBig`.

### 8.8 `src/server/MapsBig.luau` after integration (integrator)
`plan = { half = 185, ring = 168, quarters = { { id, x, z, maze, yard = { x, z }, room = { x, z } }, ... },
landmarks = { silo = { x, z }, lookout = ..., barnLoft = ..., windmill = ..., waterTower = { x = -168, z = 168 }, hayTower = { x = 0, z = 0 } } }`.
`id` is the maze style name (`corn`, `vines`, `hedge`, `stonehedge`).

```lua
local QUARTERS = {
	{ id = "corn", x = -Q, z = -Q, landmark = "silo" }, { id = "vines", x = Q, z = -Q, landmark = "lookout" },
	{ id = "hedge", x = -Q, z = Q, landmark = "barnLoft" }, { id = "stonehedge", x = Q, z = Q, landmark = "windmill" },
}

function MapsBig.bigfarm(ctx)
	ctx.sun = ctx.sun or Vector3.new(table.unpack(Farm.sunFallback))
	Landscape.floor(ctx, Farm.Terrain.half) -- the terrain slab and the invisible floor part
	Boundary.build(ctx, HALF) -- the edge's colliders, the hedge bank and the field gates
	ctx.landmarks = {}
	local all = { cells = {}, deadEnds = {}, rooms = {}, height = 10, size = 16 }
	local plan = { half = HALF, ring = RING, quarters = {}, landmarks = { waterTower = { x = -RING, z = RING }, hayTower = { x = 0, z = 0 } } }
	for _, q in ipairs(QUARTERS) do
		local maze = MazeKit.build(ctx, { cols = 9, rows = 9, size = 16, height = 10, style = q.id, loops = 0.12, rooms = 2, ox = q.x, oz = q.z, doors = 2 })
		local yard, room = maze.rooms[1], maze.rooms[2] or maze.rooms[1]
		local top = Landmarks[q.landmark](ctx, yard.x, yard.z)
		table.insert(ctx.landmarks, top)
		LandmarkSkins.balloon(ctx, top, Farm.Quarters[q.id].colour)
		FarmDress.quarter(ctx, q.id, maze, room)
		GateKit.gates(ctx, maze, q.id)
		table.insert(plan.quarters, { id = q.id, x = q.x, z = q.z, maze = maze, yard = yard, room = room })
		plan.landmarks[q.landmark] = yard
		for _, key in ipairs({ "cells", "deadEnds" }) do
			table.move(maze[key], 1, #maze[key], #all[key] + 1, all[key])
		end
		table.insert(all.rooms, room) -- (the landmark's clearing is taken)
	end
	table.insert(ctx.landmarks, Landmarks.waterTower(ctx, -RING, RING))
	ctx.goldenSpot = Landmarks.hayTower(ctx, 0, 0)
	LandmarkSkins.balloon(ctx, ctx.goldenSpot, Farm.centreColour)
	Landscape.farm(ctx, plan) -- paint the ground now the mazes are known
	function all.randomCell()
		return all.cells[ctx.rng:NextInteger(1, #all.cells)]
	end
	ctx.maze = all
	for i = 0, 9 do -- everyone starts round the ring road, facing in (unchanged)
		...
	end
	Flora.treeLine(ctx, HALF)
	Flora.roadTrees(ctx, RING, HALF)
	FarmDress.roads(ctx, plan) -- after the spawns: cover keeps clear of them
	FarmFx.build(ctx, plan)
	MapKit.clutter(ctx, ctx.diff.clutter * 3, HALF - 10, HALF - 10)
	MapKit.moving(ctx, ctx.diff.moving * 3, 150, 150)
end
```

The line `height = 10, style = q.id` must keep the text `height = 10, style` (a rule test reads it).

### 8.9 The other shared files (integrator)
- **`src/shared/Config.luau`**: `Config.Studs = { on = false, ...` (same line; update its comment:
  off for the realistic look, the switch stays); before `return Config`:
  `Config.Look = require(script.Parent.ConfigLook)` and `Config.Farm = require(script.Parent.ConfigFarm)`
  (281 lines).
- **`src/shared/Maps.luau`**: section 2.5.
- **`src/server/RoundManager.luau`**: delete the local `light` function, the `Lighting` service and
  the `MapKit` require (only `clearTerrain` used it); require `Look` and `Landscape`. In `playRound`:
  `Landscape.clear(Config.ArenaCentre)` in the three places `MapKit.clearTerrain` was; `ctx` gains
  `sun = Look.sunFor(def.look)` and `pace = true`; straight after `phase("loading", 3)`:
  `Landscape.colours(def.terrain)` and `Look.apply(def.look, diff.dim + (if mods.lowlight then 0.45 else 0))`
  (before the build, so the sky is right while it loads; the old `light(def.lighting, ...)` line
  goes); after the chests are placed and before players are moved in:
  `task.wait(Config.Farm.Budget.settle)`. Every `light(Maps.lobbyLighting)` becomes
  `Look.apply(Maps.lobbyLook)`, and where the round ends `Landscape.colours()` puts the farm's
  terrain colours back. The file ends shorter than its 289 lines.
- **`src/server/Main.server.luau`**: first step `{ "Look", Look.init }`; after `"Lobby"`:
  `{ "Backdrop", function() Landscape.lobby(Config.LobbyCentre) if GameServer.isGameServer() or RunService:IsStudio() then Landscape.backdrop(Config.ArenaCentre) end end }`
  (needs `Config`; lobby servers never play a round outside Studio, so they skip the backdrop).
- **`src/client/Main.client.luau`**: `require(script.Parent:WaitForChild("LookFx")).start()`.
- **`default.project.json`**, **`/home/user/screener3/dev/build.py`**: section 2.1.

### 8.10 maprun (foundation; the integrator may adjust afterwards)
**`dev/maprun/roblox.lua`, exact additions:**
1. **Fast queries.** A generation counter bumped whenever any instance's `Parent`, `CanQuery`,
   `CanCollide`, `CFrame`, `Size` or `Position` is set, or it is destroyed. `included(params)` caches,
   per filter root and generation, the list of parts with `CanQuery ~= false`; `aabb(part)` is
   cached on the part until its CFrame or Size changes. `GetPartBoundsInBox` skips parts with
   `CanQuery == false` as the engine does. (Without this, 19,000 parts make every ray crawl.)
2. **Strict enums.** `Enum.Material` and `Enum.PartType` raise an error for a name that is not a
   real item: Material = the 45 names in the terrain research (Plastic, SmoothPlastic, Neon, Wood,
   WoodPlanks, Marble, Basalt, Slate, CrackedLava, Concrete, Limestone, Granite, Pavement, Brick,
   Pebble, Cobblestone, Rock, Sandstone, CorrodedMetal, DiamondPlate, Foil, Metal, Grass, LeafyGrass,
   Sand, Fabric, Snow, Mud, Ground, Asphalt, Salt, Ice, Glacier, Glass, ForceField, Air, Water,
   Cardboard, Carpet, CeramicTiles, ClayRoofTiles, RoofShingles, Leather, Plaster, Rubber);
   PartType = Ball, Block, Cylinder, Wedge, CornerWedge. Other enums stay permissive.
3. **Strict classes.** Setting a property that the class does not have raises an error (`Name`,
   `Parent`, `Archivable` are always allowed). Lists: Atmosphere {Density, Offset, Color, Decay,
   Glare, Haze}; Sky {SkyboxBk, SkyboxDn, SkyboxFt, SkyboxLf, SkyboxRt, SkyboxUp, SunTextureId,
   MoonTextureId, SunAngularSize, MoonAngularSize, StarCount, CelestialBodiesShown,
   SkyboxOrientation}; Clouds {Cover, Density, Color, Enabled}; BloomEffect {Intensity, Size,
   Threshold, Enabled}; ColorCorrectionEffect {Brightness, Contrast, Saturation, TintColor, Enabled};
   SunRaysEffect {Intensity, Spread, Enabled}; DepthOfFieldEffect {FarIntensity, FocusDistance,
   InFocusRadius, NearIntensity, Enabled}; ColorGradingEffect {TonemapperPreset, Enabled};
   PointLight {Brightness, Color, Enabled, Range, Shadows}; SpotLight and SurfaceLight {the same
   plus Angle, Face}; Attachment {CFrame, Position, Orientation, WorldCFrame, WorldPosition,
   Visible}; Beam {Attachment0, Attachment1, Brightness, Color, CurveSize0, CurveSize1, Enabled,
   FaceCamera, LightEmission, LightInfluence, Segments, Texture, TextureLength, TextureMode,
   TextureSpeed, Transparency, Width0, Width1, ZOffset}; ParticleEmitter {Acceleration, Brightness,
   Color, Drag, EmissionDirection, Enabled, Lifetime, LightEmission, LightInfluence, LockedToPart,
   Orientation, Rate, RotSpeed, Rotation, Shape, ShapeInOut, ShapePartial, ShapeStyle, Size, Speed,
   SpreadAngle, Squash, Texture, TimeScale, Transparency, VelocityInheritance, WindAffectsDrag,
   ZOffset}; Lighting {Ambient, OutdoorAmbient, Brightness, ColorShift_Top, ColorShift_Bottom,
   EnvironmentDiffuseScale, EnvironmentSpecularScale, ExposureCompensation, GlobalShadows,
   ShadowSoftness, GeographicLatitude, ClockTime, TimeOfDay, FogColor, FogStart, FogEnd}; Terrain
   {WaterColor, WaterReflectance, WaterTransparency, WaterWaveSize, WaterWaveSpeed}; Workspace
   {GlobalWind, Gravity}. (The shim's own methods, such as `workspace.Raycast` and the Terrain
   fills, are installed past this check.)
4. **Forbidden writes** raise "The current thread cannot write '<name>'": Lighting.Technology,
   LightingStyle, PrioritizeLightingQuality; Terrain.Decoration, GrassLength;
   MaterialService.Use2022Materials; Workspace.StreamingEnabled. Reading `Lighting.LightingStyle`
   returns `"Realistic"`.
5. **New globals and methods:** `ColorSequenceKeypoint.new`; `NumberRange.new` keeps `Min`, `Max`;
   `Region3.new(min, max)` with `.Size`, `.CFrame` and `:ExpandToGrid(4)`; `math.noise(x, y, z)`
   (any smooth deterministic noise in -0.5..0.5); `table.create`; `CFrame:VectorToWorldSpace`;
   `Lighting:GetSunDirection()` (a simple model from `ClockTime`, so `Look` can be smoke-run);
   `Instance:FindFirstChildOfClass` already exists.
6. **Terrain:** every Fill call checks the material is one terrain accepts (Asphalt, Basalt, Brick,
   Cobblestone, Concrete, CrackedLava, Glacier, Grass, Ground, Ice, LeafyGrass, Limestone, Mud,
   Pavement, Rock, Salt, Sand, Sandstone, Slate, Snow, WoodPlanks, Water, Air) and errors otherwise;
   `SetMaterialColor` errors for Water. New `FillWedge` and `ReplaceMaterial` (recorded, no effect).
   `WriteVoxels(region, resolution, materials, occupancy)` errors unless `resolution == 4`, the
   region's corners are multiples of 4 and both arrays are exactly `Size / 4` on all three axes
   (`[x][y][z]`); it records, per column, the top height and its material.
7. **`R.collect(root)`** adds to each part: `collide`, `query`, `shadow` (booleans), `tier` (the
   name of the Folder directly under the root that holds it, or `""`), `reflectance`; lights also
   from SurfaceLight, with `kind`, `brightness`, `shadows`, `angle`.
8. **`R.census(root)`** returns `{ parts, byTier, byShape, byMaterial, lights, shadowLights,
   particles (the sum of Rate times the longest Lifetime), beams, shadowParts, transparent (parts
   with 0 < Transparency < 1), badDeco (parts in Detail, Fine, Far or Fx that collide, answer
   queries or can be touched) }`.

**`dev/maprun/run_map.py`:** `run()` also returns `terrain` (the recorded ops: blocks, balls,
cylinders, voxel columns, and material colours), `look` (`ConfigLook.presets[def.look]` when both
exist), `looks` (every preset, for the preview's `look=` switch), `sun` (`ctx.sun` or the fallback), `census`, `cells` (`ctx.maze.cells` as `[x, z]`),
`gates` and `runs` (when the maze records them), `tops` (`ctx.landmarks` and `ctx.goldenSpot`).
For bigfarm it first calls `Landscape.backdrop(ctx.centre)` when that module exists and appends
`workspace.Backdrop`'s parts (tier `Far`). Numbers written to `mapdata/*.js` are rounded (positions
and sizes to 0.01, rotations to 0.0001) to keep the file near 4 MB. A missing module is a stub
whose functions return nil, as now.

**`dev/maprun/smoke.py`** (new): runs one Lua snippet in the shim, for a package to try its own
module before `MapsBig` is wired:
`python3 needle-hunt/dev/maprun/smoke.py [--seed N] [--out /abs/path/name.js] '<lua using ctx>'`.
It makes an empty `Arena`, a 400 x 2 x 400 `Ground` part (top y = 0), and `ctx` exactly as `run_map`
does (`def` = the bigfarm row, `diff` = Normal, `centre` = 0,0,0), runs the snippet, prints the
census and writes the parts (and terrain) in `run_map`'s format when `--out` is given. It exits 1
if `badDeco > 0` or the snippet errors.

**`dev/maprun/check_maps.py`:** keeps today's checks for every map and adds, for bigfarm on every
seed: exactly 10 spawns and 5 chests; `census.parts <= Budget.parts`; Balls plus Cylinders, part
materials, transparent parts, lights, shadow lights, particles and beams within `ConfigFarm.Budget`;
`badDeco == 0`; no CornerWedge parts; **walls**: for every entry of `runs`, five points along it at y = 4 lie inside a
collidable `MazeWall`; **climbs**: for each landmark (found from `tops` by its height), every row
of `dev/maprun/baseline_bigfarm.json` (copied from `$S/realmaps/baseline_bigfarm.json`; the
signature code is in `$S/realmaps/baseline.py`) is still present among the collidable parts within
16.5 studs of its anchor (other collidable parts found there are printed, for a person to read);
**corridors**: a raster walk (1-stud cells; a collidable part blocks where its box crosses y 0 to 5
and its top is above y 6, since anything lower can be hopped over; each box grown by a 1.25-stud
player radius) from the first spawn reaches within 5 studs of every spawn, every maze cell centre,
every gate and the foot of both ladders. A working prototype is `$S/realmaps/walk_proto.py`: today's
map passes it on seeds 1 to 6 in about a second each. It also prints, for every map, its part count (the other maps inherit the walls).

### 8.11 Preview (package `preview`)
Files: `dev/preview/render.html` (edit), `dev/preview/look.js`, `dev/preview/terrain.js`,
`dev/preview/shoot_maps.js` (new). Working copies and `three.min.js` (r128) are in `$S/maps`;
Playwright is installed globally. The page must keep drawing the old mapdata files and the built-in
(non-json) maps.

| Area | Requirement |
|---|---|
| Data | `window.MAPDATA` as section 8.10 writes it; every new field optional (old files have `def.lighting` and no `tier`, `look`, `terrain`) |
| Drawing | one `InstancedMesh` per (shape, material, casts shadow) with per-instance colour; Wedge as now; Neon emissive; a part with `transparency >= 1` is skipped; up to 12 local lights from `part.light`, the ones with `shadows` as shadow-casting SpotLights |
| Materials | a table from Roblox material to roughness, metalness and a procedural 256-pixel tile (colour variation and a bump map): Grass and LeafyGrass rough 1.0 blades; Wood and WoodPlanks 0.8 grain and board lines; Slate, Rock, Cobblestone 0.9 cracks and cobbles; Metal 0.35 with metalness 0.8; CorrodedMetal 0.75, metalness 0.4, blotches; DiamondPlate 0.4, metalness 0.8; Fabric 0.95 weave; Plaster 0.9 fine noise; Ground and Mud 1.0 clods; SmoothPlastic 0.5 plain; Neon emissive. Textures are mapped in world space (triplanar, 8 studs a tile, through `onBeforeCompile`) so long walls do not stretch |
| Light | from `MAPDATA.look` (or `def.lighting` for old files): a sun along `MAPDATA.sun` (or from the clock time) with intensity from `Brightness` and colour warmed by `ColorShift_Top`; a hemisphere light from `OutdoorAmbient` and `Ambient`; `ACESFilmicToneMapping` with exposure `2 ^ ExposureCompensation`; sRGB output; soft shadows (`PCFSoftShadowMap`, 4096, radius from `ShadowSoftness`) with the shadow box fitted to the view |
| Air | `FogExp2` from `Atmosphere.Density`, `Haze` and `Color`; a sky dome shaded from the haze colour at the horizon to blue above, a sun disc with glare, soft cloud patches scaled by `Clouds.Cover`; contrast, saturation and tint from `Grade` applied to the canvas (CSS `filter` and a multiply overlay are enough: Playwright captures them) |
| Terrain | `terrain.js` turns `MAPDATA.terrain` into one mesh: a 4-stud grid over the ops' extent, each vertex's height and material from the ops in order (blocks, balls, cylinders, voxel columns), vertex colours from the recorded material colours (defaults from `ConfigFarm.Terrain.colours`), smooth normals, receives shadows; Water as a flat glossy translucent plane; short grass blades (instanced) on Grass within 70 studs of the camera |
| Views | `top`, `aerial`, `player:<spawn>`, `chest:<n>`, `near:<n>` as now, plus `corridor:<quarter>` (eye height in a corridor of that quarter), `gate:<n>`, `landmark:<n>`, `vista:<n or e or s or w>` (from the crossroads down a road), `orbit` (fits any mapdata, for smoke files) |
| Switches | `tier=high or mid or low` (mid hides `Fine`; low hides `Fine` and `Fx`), `shadows=0` (what a phone below quality 4 sees), `look=<preset>` and `dim=<n>` (need `MAPDATA.looks`, optional) |
| Output | `window.DONE = { parts, instances, calls: renderer.info.render.calls, triangles }`; `shoot_maps.js` takes jobs `map:view[:n]`, the switches through the environment (`TIER`, `SHADOWS`, `LOOK`), and `--out <dir>` |
| Speed | Hayfield Farm with 20,000 parts renders in under 90 s at 1280 x 720 under SwiftShader |

---

## 9. WORK PACKAGES

One small package goes first (`foundation`); six then run in parallel in the same checkout; the
integrator runs last. A package edits only its own files. A package that starts before
`ConfigFarm.luau` and `Dress.luau` exist waits for them (it never creates them). While the
parallel packages are in flight, `build.py --check` may report modules another package has not
written yet: ignore errors that name files you do not own; the integrator runs the full check.
Each package ends with a short message: what was built, the census numbers from its smoke run,
anything in the spec it had to bend, any shim gap it met.

### foundation (first; nothing depends on it being perfect, everything on it existing)
Files: `needle-hunt/src/shared/ConfigFarm.luau` (new), `needle-hunt/src/server/Dress.luau` (new),
`needle-hunt/dev/maprun/roblox.lua`, `needle-hunt/dev/maprun/run_map.py`,
`needle-hunt/dev/maprun/check_maps.py`, `needle-hunt/dev/maprun/smoke.py` (new),
`needle-hunt/dev/maprun/baseline_bigfarm.json` (new, copied from `$S/realmaps/`),
`needle-hunt/dev/maprun/luau2lua.py` (only to close a converter gap).
Build: sections 8.1, 8.2, 8.10. Write `ConfigFarm.luau` and `Dress.luau` first (the others wait
on them), then the shim, `smoke.py` and `run_map.py`, then `check_maps.py`.
Done when: today's maps still pass `check_maps.py` with the new checks (the walls check is skipped
while `runs` is absent); `smoke.py` runs a `Dress` snippet (a part in every tier, a light, an
emitter, a beam) and prints the census; a deliberate bad write (`Lighting.LightingStyle = 0`,
`Enum.Material.Hay`, a `WriteVoxels` with a wrong-sized array, `Dress.part` with `CanCollide = true`)
errors.

### look (parallel)
Files: `needle-hunt/src/shared/ConfigLook.luau`, `needle-hunt/src/server/Look.luau`,
`needle-hunt/src/client/LookFx.luau` (all new).
Build: sections 2.2 to 2.6 and 8.3. All seven presets from the table in 2.3.

### land (parallel)
Files: `needle-hunt/src/server/Landscape.luau`, `Boundary.luau`, `Vista.luau`, `VistaSets.luau`
(all new, in `needle-hunt/src/server/`).
Build: sections 3 and 8.4. `Landscape.farm` must tolerate a maze without `runs`, `links` or
`gates` (the walls package adds them).

### walls (parallel)
Files: `needle-hunt/src/server/MazeKit.luau` (edit), `MazeWalls.luau` (edit), `WallKitCrop.luau`,
`WallKitHedge.luau`, `GateKit.luau` (new).
Build: sections 4 and 8.5. The other 15 maps must still pass `check_maps.py`.

### landmarks (parallel)
Files: `needle-hunt/src/server/Landmarks.luau` (edit), `LandmarkSkins.luau`, `LandmarkSkins2.luau`,
`BarnKit.luau`, `MillKit.luau` (new).
Build: sections 5.1 to 5.7 and 8.6. The climb baseline must hold.

### dressing (parallel)
Files: `needle-hunt/src/server/FarmProps.luau` (edit), `Flora.luau`, `FarmSet.luau`,
`FarmSet2.luau`, `GroundKit.luau`, `FarmDress.luau`, `FarmFx.luau` (new).
Build: sections 5.8 to 5.11, 6.2 (the rows `FarmFx.build` owns) and 8.7. `FarmDress.quarter`
must place the same gameplay props `MapsBig`'s `props` closures place today.

### preview (parallel; needs nothing from the others to start)
Files: `needle-hunt/dev/preview/render.html` (edit), `needle-hunt/dev/preview/look.js`,
`terrain.js`, `shoot_maps.js` (new). Work in `$S/maps` and copy the results back.
Build: section 8.11. Test on today's `mapdata/bigfarm.js` and on a synthetic terrain file made
from the height formula in 3.2 (a few lines of Python).

### integrator (last)
Files: `needle-hunt/src/server/MapsBig.luau`, `needle-hunt/src/shared/Config.luau`,
`needle-hunt/src/shared/Maps.luau`, `needle-hunt/src/server/RoundManager.luau`,
`needle-hunt/src/server/Main.server.luau`, `needle-hunt/src/client/Main.client.luau`,
`needle-hunt/default.project.json`, `/home/user/screener3/dev/build.py`,
`needle-hunt/dev/test_rules.py`, `needle-hunt/README.md`,
`needle-hunt/dev/preview/mapdata/bigfarm.js` (regenerated), `needle-hunt/previews/hayfield_*.png`,
and, once everything passes, the rebuilt `needle-hunt/NeedleHunt.rbxlx` (committing is the calling
workflow's decision). After the parallel packages finish, the integrator may also fix any file.
Steps:
1. Sections 2.1, 2.5, 8.8, 8.9.
2. `dev/test_rules.py`: add tests that (a) every map row has a `look` that is a preset, no row has
   `lighting` or `FogEnd`, and `Maps.lobbyLook` is a preset; (b) every preset has every key of
   section 2.3, Bloom `Threshold` is at least 1, ClockTime is 0 to 24, Atmosphere Density 0 to 1;
   (c) no file under `src/` assigns `LightingStyle`, `Technology`, `PrioritizeLightingQuality`,
   `Decoration`, `GrassLength`, `Use2022Materials` or `StreamingEnabled`; (d) `default.project.json`
   carries the properties of section 2.1; (e) `Config.Studs.on` is false and `MapKit` still reads
   it; (f) no `rbxassetid://` in the modules this work adds; (g) `ConfigFarm.Budget.parts` is at
   most 25,000; (h) `RoundManager` calls `Look.apply`, `Landscape.clear` and `Landscape.colours`
   and no longer writes `Lighting`. Rename the studs test to say the studs are a switch, off.
3. Run everything in section 10; fix what fails; read the census against section 7 and turn
   `Budget.wallDensity` down if parts run over.
4. Regenerate `mapdata/bigfarm.js`, shoot the previews listed in section 10, look at them, and fix
   what looks wrong (floating parts, gaps, colours, dark lanes).
5. README: the Hayfield Farm paragraph, a new "Realistic look" section (presets, tiers, the
   place-file properties, what changed by default: studs off, lighting rows replaced by looks, the
   1.5 s settle), "Checking the maps outside Studio" (smoke, the new checks, the preview's views
   and switches), the folder list, the Studio test checklist (section 11) and Previews.

---

## 10. VERIFICATION

Environment for every command: `cd /home/user/screener3` and
`export PYTHONPATH=/tmp/claude-0/-home-user-screener3/58693bae-13a9-5ef3-95b8-b9e36f9effe2/scratchpad/pylib`
(that is where `lupa` is).

| Who | Commands |
|---|---|
| Every package that writes Luau | `python3 dev/build.py --project needle-hunt --check` (own files clean) · `python3 needle-hunt/dev/test_rules.py` |
| foundation | `python3 needle-hunt/dev/maprun/check_maps.py 2` (all 16 maps, unchanged source) · the smoke and bad-write runs in its "done when" |
| look | `python3 needle-hunt/dev/maprun/smoke.py 'local L = require(__SERVER.Look) L.init() for name in pairs(require(__SHARED.ConfigLook).presets) do L.apply(name, 0.8) assert(L.sunFor(name)) end'` |
| land | `python3 needle-hunt/dev/maprun/smoke.py --out $S/realmaps/land.js 'local L = require(__SERVER.Landscape) L.colours() L.backdrop(ctx.centre) L.floor(ctx, 188) require(__SERVER.Boundary).build(ctx, 185) L.clear(ctx.centre)'` and check: `Landscape.height` is 0 at 188, at most 37 between 232 and 340, 44 at 400, 0 at 444, and under 7 on a lane at 300 |
| walls | `python3 needle-hunt/dev/maprun/smoke.py --out $S/realmaps/walls.js 'local W = require(__SERVER.MazeWalls) for i, s in ipairs({ "corn", "vines", "hedge", "stone" }) do W[s](ctx, Vector3.new(i * 20, 0, -24), Vector3.new(i * 20, 0, 24), 10, 2) end'` (census within 10% of 3.1 times the per-16 counts of section 4) · `python3 needle-hunt/dev/maprun/check_maps.py 2` |
| landmarks | a smoke run that calls all six `Landmarks` functions 60 studs apart · `python3 needle-hunt/dev/maprun/check_maps.py 2` (climbs) |
| dressing | a smoke run that builds one maze (`MazeKit.build` with the bigfarm options), calls `FarmDress.quarter` for each id, `Flora.treeLine`, `Flora.roadTrees`, `FarmDress.roads`, `FarmFx.build` with a hand-made `plan` |
| preview | `cd $S/maps && node shoot_maps.js bigfarm:aerial bigfarm:player:2 bigfarm:top` on today's data, and `orbit` on a smoke file |
| integrator | all of the above, then `python3 needle-hunt/dev/maprun/check_maps.py 3`, `python3 needle-hunt/dev/maprun/run_map.py bigfarm`, `python3 dev/build.py --check` (the main game: still passes, same output), `python3 needle-hunt/dev/test_rules.py && python3 dev/build.py --project needle-hunt` |

Acceptance (the integrator signs off each line):
1. `check_maps.py 3` passes for all 16 maps: 5 chests and enough spawns everywhere; for bigfarm 10
   spawns, the wall, climb and corridor checks, `badDeco == 0`, and every cap of section 7.
2. `test_rules.py` passes, including the new tests.
3. `build.py --project needle-hunt --check` reports 0 problems (every file under 300 lines), and
   the main game's check still passes.
4. The built `NeedleHunt.rbxlx` contains a `Lighting` item with `LightingStyle` and `Technology`
   tokens, a `MaterialService` item with both `Use2022Materials` names, and a `Terrain` item with
   `Decoration` under `Workspace` (grep the file).
5. Census: parts between 15,000 and 22,000 on the high tier, at most 12,500 without `Fine`.
6. Previews shot and looked at: `bigfarm:aerial`, `bigfarm:top`, `bigfarm:corridor:corn`,
   `corridor:vines`, `corridor:hedge`, `corridor:stonehedge`, `vista:n`, `vista:e`, `vista:s`,
   `vista:w`, `landmark:0` to `landmark:5`, `player:2`, and `corridor:corn` again with `TIER=low`
   and with `SHADOWS=0`. In each corridor shot the wall reads as its material (corn, trellis,
   hedge, stone), the ground differs by quarter, nothing floats, and the lane is not black.
7. A maprun build of bigfarm takes under 20 s.

---

## 11. OWNER NOTES

**Nothing is published or priced by this work.** After opening `NeedleHunt.rbxlx` in Studio:

1. **Check five settings once** (the place file sets them; scripts cannot):
   - Lighting: `LightingStyle` = Realistic and `PrioritizeLightingQuality` ticked (older Studio:
     `Technology` = Future). If not, set them by hand and save.
   - Lighting has no `ColorGradingEffect` set to Retro (delete one if Studio added it).
   - MaterialService: `Use2022Materials` ticked.
   - Workspace > Terrain: `Decoration` ticked (grass blades show on the verges and in the orchard).
   - Workspace: `StreamingEnabled` off.
   If the Output window warns "the place file's lighting did not load as Realistic", the first
   item needs doing by hand.
2. **Graphics level.** In Studio: File > Studio Settings > Rendering > Editor Quality Level and
   Quality Level = 21. In a play test: Esc > Settings > Graphics Quality to manual, full. Players
   choose their own; shadows appear from level 4 up.
3. **Look at the sun.** In a round, each corridor should have a sunlit strip. If lanes are dark,
   raise `sunElevation` for `harvest` in `ConfigLook.luau` (36 to 42); if the light is flat, lower
   it. Every number in section 2.3 is a starting point: tune in Studio and copy the values back.
4. **Performance.** Shift+F2 (or View > Stats > Render) shows draw calls and triangles; Shift+F5
   the frame rate. Try the Device emulator on a phone preset: the map should drop its fine detail
   by itself within a few seconds if the frame rate is under 28. If a phone still struggles, lower
   `ConfigFarm.Budget.wallDensity` (1 to 0.6).
5. **Studs.** `Config.Studs.on = true` brings the classic studded floors and walls back.
6. **Balloons** over the landmarks: `ConfigFarm.Balloons.on`.

**Optional textures to upload later** (nothing depends on them; each is one ID in Config):
a soft gradient for the light shafts (`ConfigFarm.Fx.beamTexture`); a leaf cluster card with
transparency for canopies and hedge cards; a hay material (colour and normal map) applied by name
to bales and straw parts, not as an override of Grass (an override would repaint the terrain's
grass too); corrugated tin for the barn roof; board-and-batten for the barn walls; a custom
skybox with a lower, warmer horizon.

---

## 12. RISKS

1. **Things nobody here can see.** The lighting tokens, the `Use2022MaterialsXml` name, a Terrain
   item with only two properties, `WriteVoxels`, the sun's real path and every preset value are
   unverified in Studio. Cover: fallbacks (the sun solver falls back to a clock time, the voxel
   writer to `FillBall` mounds), warnings in the Output window, and the owner's checklist.
2. **Chests, spawns, corridors.** Covered by unchanged colliders, the invisible floor part,
   decoration that cannot be hit or queried, and three checks in `check_maps.py` (walls, climbs,
   corridors). The `Support` piers and `Cover` cores are the only new colliders.
3. **Replication burst and server hitch.** About 19,000 parts arrive at once. Cover: paced building,
   the 1.5 s settle before players move in, client tiers. If phones still stall, the `Fine` tier
   can later be built on the client from a seed.
4. **Phones.** Below quality level 4 there are no shadows and maybe no bloom or sun rays. The look
   must hold on ambients, Atmosphere, the grade, painted occlusion and silhouettes: preview with
   `SHADOWS=0` and `TIER=low`.
5. **Terrain.** Grass blades through thin parts (kept off Grass); flicker where a part face meets
   the terrain surface (0.1 lift); colours that persist between maps (reset every round and after);
   Sand is the haystacks' colour (used only as stubble); the clear box matches the play square
   exactly; no water inside the walls.
6. **Solid-looking decoration.** Rails, the lean-to, gate posts and tower arms do not collide.
   They are kept thin, high or against walls; anything a player would walk into on the ground
   (piers, cover, road trees) collides.
7. **The shim is not the engine.** Strict property lists catch typos, not behaviour. Wedge
   orientation, Beam looks and particle looks are only seen in Studio; the preview draws Wedges the
   way the engine does but cannot prove a roof faces the right way: look at the previews.
8. **Parallel work.** Missing-module errors until every package lands; `foundation` must come
   first; other workstreams (combat and movement, first-person view) may edit `RoundManager`,
   `Config` or `Main.client`: re-read before editing.
9. **The other 15 maps** inherit the richer walls (part counts rise; `check_maps.py` prints them)
   and new presets they have never been seen under. They are out of rotation; a later pass can
   tune them.
10. **Line limits.** `BarnKit`, `LandmarkSkins`, `Landscape` and `FarmSet` will be close to 300
    lines: split before the checker fails, never squeeze recipes out.
11. **Built-in particle textures** live in the client's own files and may be missing on a
    platform: every effect is optional.
12. **Originality.** The tractor, barn and farm are plain, original designs: no real brands and
    nothing modelled on another game's map.

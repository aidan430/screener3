# research:terrain

# Terrain, materials and wind (research only, no code changed)

**Access:** WebFetch could not reach create.roblox.com or devforum.roblox.com (outside this session's allowed network domains; allow them in network settings to check). I did not work around it. "(search)" = confirmed only from web-search summaries of the cited page; "(memory)" = unverified.

Sources: [T] https://create.roblox.com/docs/reference/engine/classes/Terrain · [G] https://create.roblox.com/docs/parts/terrain · [W] https://create.roblox.com/docs/environment/global-wind · [R] https://create.roblox.com/docs/workspace/raycasting · [M] https://create.roblox.com/docs/reference/engine/enums/Material · [DF] https://devforum.roblox.com/t/

## FACTS
1. `Terrain:FillBlock(cframe: CFrame, size: Vector3, material: Enum.Material)`, `:FillWedge(cframe, size, material)`, `:FillBall(center: Vector3, radius: number, material)`, `:FillCylinder(cframe, height, radius, material)`, `:FillRegion(region: Region3, resolution, material)`; all return nothing. [T] (search), high.
2. Cells are 4x4x4 studs with occupancy 0-1 plus a material; `resolution` must be 4. [T] (search), high.
3. `WriteVoxels(region, 4, materials, occupancy)` / `ReadVoxels(region, 4)`: 3D arrays `[x][y][z]` sized `region.Size/4`; limit 4,194,304 voxels per call (1024x256x1024 studs). [T] (search), high.
4. The region must be grid-aligned or the call errors (enforced 2025, also `ReplaceMaterial`). `ExpandToGrid` returns a new Region3: `region = Region3.new(min, max):ExpandToGrid(4)`. [DF]3633317, [DF]3639054 (search), medium.
5. `ReadVoxelChannels` / `WriteVoxelChannels(region, 4, channels)` exist; channels `"SolidMaterial"`, `"SolidOccupancy"`, `"LiquidOccupancy"`. Not needed here. [DF]2828798 (search), medium.
6. FillBlock landing: an unrotated box with every face on a multiple of 4 fills whole cells and its top is flat at the box top (memory, medium). Unaligned boxes land off, reported "slightly below the part". [DF]1830925, [DF]315931 (search), medium.
7. `Terrain.Decoration: boolean` and `Terrain.GrassLength: number` (0.1-1, default 0.7) are tagged Not Scriptable: place file only. Animated grass is on the `Grass` material only. [T], [G] (search), high. LeafyGrass has none (memory, medium).
8. Grass blades poke through parts lying on Grass terrain. [DF]3675828, [DF]427328 (search), high.
9. Water, all scriptable: `WaterColor` (default 12,84,92), `WaterReflectance` 0-1 (1), `WaterTransparency` 0-1 (0.3), `WaterWaveSize` 0-1 (0.15), `WaterWaveSpeed` 0-100 (10). [T] plus robloxapi.github.io (search), ranges high, last three defaults medium.
10. `Terrain:SetMaterialColor(material, Color3)` / `GetMaterialColor(material)` are global per material; Water errors "Unsupported terrain material" (use `WaterColor`). [T], [DF]117551 (search), high.
11. `Enum.Material` (45): Plastic, SmoothPlastic, Neon, Wood, WoodPlanks, Marble, Basalt, Slate, CrackedLava, Concrete, Limestone, Granite, Pavement, Brick, Pebble, Cobblestone, Rock, Sandstone, CorrodedMetal, DiamondPlate, Foil, Metal, Grass, LeafyGrass, Sand, Fabric, Snow, Mud, Ground, Asphalt, Salt, Ice, Glacier, Glass, ForceField, Air, Water, Cardboard, Carpet, CeramicTiles, ClayRoofTiles, RoofShingles, Leather, Plaster, Rubber. [M] (search confirmed about half), rest memory; high.
12. Terrain accepts: Asphalt, Basalt, Brick, Cobblestone, Concrete, CrackedLava, Glacier, Grass, Ground, Ice, LeafyGrass, Limestone, Mud, Pavement, Rock, Salt, Sand, Sandstone, Slate, Snow, WoodPlanks, Water, Air. Water and Air are terrain-only; Glass is part-only. [G], [M] (search, partial), medium-high.
13. `MaterialService.Use2022Materials`: game scripts cannot write it ("lacking capability RobloxScript"). Studio templates turn it on for new places; existing places were unchanged. [DF]2887351, [DF]1886517 (search), high. A file that omits it gets legacy materials (memory, medium).
14. Its `CanSave` became false in v524 (robloxapi.github.io, search). Studio saves it as `Use2022MaterialsXml` (memory, medium).
15. `workspace.GlobalWind: Vector3` is scriptable (docs show a gust script). It moves terrain grass and dynamic clouds, Fire and Smoke automatically, and ParticleEmitters only when `WindAffectsDrag = true` and `Drag > 0`. Not parts or Beams. Reduce Motion slows grass. [W] (search), high.
16. `WorldRoot:Raycast` hitting terrain: `RaycastResult.Instance` is `workspace.Terrain`, `.Material` is the cell's material; `RaycastParams.IgnoreWater` decides whether Water counts. [R] (search), high.
17. An Include filter without `workspace.Terrain` never hits terrain (memory, high). `GetPartBoundsInBox` does not return Terrain (memory, medium).

## RECOMMENDED VALUES / RECIPES
- **Ground:** the floor top is y = 0 at ArenaCentre (0,0,600), already on the grid. One call: `FillBlock(CFrame.new(0, -8, 600), Vector3.new(896, 16, 896), Enum.Material.Grass)`. Use 896, not 900, so edges sit on multiples of 4 (200,704 cells).
- **Roads and dirt:** refill the top cell layer: `FillBlock(CFrame.new(x, -2, z), Vector3.new(w, 4, len), Enum.Material.Ground)`, with w, len and edges on multiples of 4 and width at least 12. Material borders blend over about 4 studs.
- **Under maze floors, buildings and thin parts:** paint `LeafyGrass` or `Ground` so no blades poke through.
- **Hills, outside the 370 square only:** `FillBall(Vector3.new(x, h - R, z), R, Enum.Material.Grass)` with R 120-200 and h 16-36, at least 230 studs from centre. This uses only calls the maprun shim already has. `WriteVoxels` is optional: 224x16x224 cells is 802,816 voxels, legal in one call, but write it in chunks of about 64x16x64 cells with `task.wait()`.
- **Colours (starting points):** `SetMaterialColor` Grass (88,124,54), LeafyGrass (96,118,60), Ground (118,96,66), Mud (74,58,44), Rock (112,110,104).
- **Grass (place file):** `"Workspace": {"$className":"Workspace","Terrain":{"$className":"Terrain","$properties":{"Decoration":true,"GrassLength":{"float":0.35}}}}`. dev/build.py already writes bool and float.
- **Wind:** `workspace.GlobalWind = Vector3.new(9, 0, 4)`, Y kept at 0; optional gusts of plus or minus 30% every 6-10 s. Dust and chaff emitters: `Drag = 1.5`, `WindAffectsDrag = true`.
- **Pond (outside the play area):** WaterColor (58,92,84), WaterTransparency 0.45, WaterReflectance 0.6, WaterWaveSize 0.05, WaterWaveSpeed 6.
- **Part materials (my judgement, untested):**
  - Weathered wood: `WoodPlanks` for boards, `Wood` for beams, greyed browns such as (112,96,80).
  - Rust: `CorrodedMetal` (128,78,50); galvanised silo: `Metal` (150,156,160).
  - Stone walls: `Cobblestone`, `Slate`, `Rock`; foundations: `Brick`.
  - Gravel: `Pebble`.
  - Roofs: `ClayRoofTiles`, `RoofShingles`, or `CorrodedMetal` for tin.
  - Hay: no built-in; `Grass` or `LeafyGrass` tinted (214,180,90).
  - Foliage: `LeafyGrass` or `Grass` in greens.
  - Render walls: `Plaster`.

## CAVEATS
- `ChestSpawner.validSpot` and `perch` raycast with `Include, { ctx.model }`, so a terrain-only floor gives "no floor" and no chests. Add `workspace.Terrain` to those lists, or keep an invisible collidable floor part (Material Grass, top at y = 0) in `ctx.model`. The second is lower risk: the shim's `Raycast` only sees parts.
- `MapKit.clearTerrain` clears only 340x100x340 at y -10..90. It would leave most of an 896 slab and cut a ragged trench through it. Resize it on grid multiples, for example 912x160x912.
- `MapKit.haystack` recolours `Sand` to straw gold globally, so do not use Sand terrain for anything else. Colours also persist across maps: set them at each round start.
- Never assign `Decoration`, `GrassLength` or `Use2022Materials` from Luau: it throws at runtime and the Python checker will not catch it.
- dev/build.py writes `Use2022Materials`. Also emit `Use2022MaterialsXml = true`; Studio ignores unknown names. Without it the place may open with legacy materials. Unverified.
- build.py has no Color3 or Vector3 writer: set `WaterColor` and `GlobalWind` from script.
- The shim (dev/maprun/roblox.lua) has only FillBall, FillCylinder, FillBlock, SetMaterialColor, Clear and FillRegion. Add FillWedge, ReplaceMaterial, WriteVoxels, Region3 and ExpandToGrid if used.
- Terrain is a singleton and cannot live in `ctx.model`. The slab reaches z = 152; the lobby is at z = 0, so check its extent.
- Passing a part-only material to a Fill call probably errors (memory, low).
- Water makes characters swim and stops throw raycasts (`IgnoreWater` defaults to false). Keep water out of the play area.
- A part face coplanar with terrain may flicker, more so at distance. Raise visible parts about 0.1 studs or sink them at least 0.5 (memory, medium).
- I found no official timing for large terrain writes. Build during intermission and yield between chunks.


# research:lighting

# Lighting and post-processing research (2026-11-11)

**Network:** create.roblox.com, devforum.roblox.com and robloxapi.github.io were refused (not in this session's allowed network domains; allow them in the session's network settings to re-check). Not bypassed. I read the docs' own source repo on GitHub (same text as create.roblox.com/docs; Lighting.yaml updated 2026-10-22) and the rbx-dom reflection database (Studio 0.745); DevForum only as search snippets.
Keys: **[D]** github.com/Roblox/creator-docs/tree/main/content/en-us/ ; **[R]** github.com/rojo-rbx/rbx-dom/blob/master/rbx_dom_lua/src/database.json ; **[I]** github.com/rojo-rbx/rbx-dom/issues/665 ; **[U]** devforum.roblox.com/t/3401512 (snippet).

## FACTS
1. `Lighting.Technology` exists but is Deprecated; read and write are RobloxScriptSecurity; it serializes. `Enum.Technology`: Legacy 0, Voxel 1, Compatibility 2, ShadowMap 3, Future 4, Unified 5. [D reference/engine/classes/Lighting.yaml, enums/Technology.yaml] high
2. Replacements: `Lighting.LightingStyle` (`Enum.LightingStyle.Realistic` = 0, `.Soft` = 1) and `Lighting.PrioritizeLightingQuality` (bool); both serialize. [D enums/LightingStyle.yaml] high
3. Game scripts can read but NOT write them (write capability `PluginOrOpenCloud`; error "The current thread cannot write 'LightingStyle' (lacking capability PluginOrOpenCloud)"). The docs page's "security None" misleads. Place file only. [I, Studio 0.740] high
4. Mapping: Future = Realistic + Prioritize true; ShadowMap = Soft + true; Voxel = Soft + false. [U; D] high
5. A place that sets none (ours: `NeedleHunt.rbxlx` has no Lighting item) loads as Soft, Prioritize false, Technology Voxel (migrated from constructor default Compatibility), `GlobalShadows` false, Brightness about 1.98, Ambient = OutdoorAmbient = 127,127,127, ShadowSoftness 0.5, Environment scales 0, GeographicLatitude 41.7333, TimeOfDay "14:00:00". [R DefaultProperties] high for values; medium that "no item" equals "empty item"
6. That Compatibility migration may also add Retro tone mapping (`ColorGradingEffect.TonemapperPreset`; `Enum.TonemapperPreset.Default` = 0, `.Retro` = 1; scriptable). [devforum.roblox.com/t/3128560 snippet; D] medium
7. Scriptable: `Ambient`, `OutdoorAmbient` (clamped >= Ambient), `Brightness`, `ColorShift_Top`, `ColorShift_Bottom`, `EnvironmentDiffuseScale`, `EnvironmentSpecularScale` (default 0; when raised, lower the ambients), `ExposureCompensation` (-5..5; +1 doubles exposure), `GlobalShadows`, `ShadowSoftness` (0..1), `GeographicLatitude`, `ClockTime` (0..24) / `TimeOfDay`, `FogColor/FogStart/FogEnd`. [D Lighting.yaml, environment/lighting.md] high
8. Fog properties do nothing once Lighting contains an `Atmosphere`. [D Atmosphere.yaml] high
9. `Atmosphere` (parent Lighting) defaults: `Density` 0.395, `Offset` 0, `Color` 199,170,107, `Decay` 92,60,13, `Glare` 0, `Haze` 0. Glare needs Haze > 0; Decay needs both. [D, R] high. Ranges Density/Offset 0..1, Haze/Glare 0..10: unverified (memory), medium
10. `Sky` (parent Lighting): `SkyboxBk/Dn/Ft/Lf/Rt/Up`, `SunTextureId`, `MoonTextureId`, `SunAngularSize` (21, clamp 0..60), `MoonAngularSize` (11), `StarCount` (3000), `CelestialBodiesShown`, `SkyboxOrientation`. Default textures are built in (`rbxasset://textures/sky/sky512_*.tex`). [D Sky.yaml, R] high
11. `Clouds` render only under `workspace.Terrain`: `Cover` (0..1, default 0.5), `Density` (0.7), `Color`, `Enabled`. [D Clouds.yaml, R] high. Drift follows `workspace.GlobalWind`: unverified (memory), high
12. Post effects (parent Lighting = everyone, `workspace.CurrentCamera` = one client; each has `Enabled`; all scriptable), defaults: `BloomEffect.Intensity/Size/Threshold` 0.4/24/0.95; `ColorCorrectionEffect.Brightness/Contrast/Saturation` 0 (-1 = black / flat / grey), `.TintColor` white (multiplies); `SunRaysEffect.Intensity` 0.25, `.Spread` 1 (both 0..1); `DepthOfFieldEffect.FarIntensity`, `.NearIntensity` 0.75, `.FocusDistance` 0.05, `.InFocusRadius` 10 (studs). [D, R] high. Bloom Size 0..56, FocusDistance 0..200, InFocusRadius 0..50: unverified (memory), medium
13. Replication: Lighting properties and children (and Clouds under Terrain) set by a server Script reach every client; LocalScript changes stay local. `ClockTime` is tagged NotReplicated but drives `TimeOfDay`, which replicates. unverified (memory), high
14. Quality: shadows degrade with client quality and switch off below level 4 [D performance-optimization/improve.md] high. Post effects "work differently or not at all" at low quality; SunRays "may not render on low-end devices" [D PostEffect.yaml, SunRaysEffect.yaml] high. Bloom from level 6, SunRays from 8, ColorCorrection always: 2016 snippet (devforum.roblox.com/t/25023), low
15. Local light `Range` clamps at 120 studs. [D Lighting.yaml] high
16. Official outdoor tutorial: Realistic, both Environment scales 1, ClockTime 17, Ambient = OutdoorAmbient 156,136,176, Atmosphere Density 0.272, Haze 1, Color 85,78,54; fire PointLight Range 48, Brightness 2, Shadows on, 255,179,73. [D tutorials/use-case-tutorials/lighting/enhance-outdoor-environments.md] high

## RECOMMENDED VALUES
**Place file** (`/home/user/screener3/needle-hunt/default.project.json`; build.py's existing value types suffice):
`"Lighting": {"$className": "Lighting", "$properties": {"Technology": {"token": 4}, "LightingStyle": {"token": 0}, "PrioritizeLightingQuality": true, "GlobalShadows": true}}`
(Technology 4 keeps the legacy field consistent, so neither migration should choose Voxel or Retro.)

**Script, every recipe:** `GlobalShadows = true`, `EnvironmentDiffuseScale = 1`, `EnvironmentSpecularScale = 1`; leave `GeographicLatitude` at 41.7333; a Sky with only `SunAngularSize = 14`; force any `ColorGradingEffect` in Lighting to `Enum.TonemapperPreset.Default`. Starting points, untested here:

| | Late-afternoon gold (Hayfield) | Clear midday | Overcast |
|---|---|---|---|
| ClockTime / Brightness / ExposureCompensation | 16.2 / 3 / 0.1 | 13.5 / 3 / 0 | 12.5 / 1.3 / 0.25 |
| Ambient; OutdoorAmbient | 58,52,62; 104,98,112 | 60,62,66; 95,100,108 | 96,100,106; 150,154,160 |
| ColorShift_Top; ShadowSoftness | 60,38,12; 0.25 | 12,8,0; 0.15 | 0,0,0; 1 |
| Atmosphere Density / Offset / Haze / Glare | 0.3 / 0.25 / 1.6 / 0.35 | 0.28 / 0.25 / 0.6 / 0.1 | 0.42 / 0.1 / 2.4 / 0 |
| Atmosphere Color; Decay | 232,196,140; 120,98,110 | 199,206,214; 106,112,125 | 190,196,204; 120,126,134 |
| Clouds Cover / Density | 0.55 / 0.35 | 0.5 / 0.3 | 0.92 / 0.55 |
| Bloom Intensity / Size / Threshold | 0.8 / 28 / 1.8 | 0.5 / 24 / 2 | 0.3 / 24 / 2 |
| ColorCorrection Contrast / Saturation; TintColor | 0.12 / 0.1; 255,244,230 | 0.08 / 0.05; 255,255,255 | 0.05 / -0.12; 236,242,255 |
| SunRays Intensity / Spread | 0.12 / 0.6 | 0.05 / 0.4 | disabled |

Depth of field: lobby and results only (`FarIntensity` 0.15, `NearIntensity` 0, `FocusDistance` 120, `InFocusRadius` 50); off in rounds.

## CAVEATS
- Never write `LightingStyle`, `PrioritizeLightingQuality` or `Technology` from game scripts: it throws. Read inside `pcall` and warn if not Realistic.
- Precedence between Technology and LightingStyle in one file is undocumented: keep them consistent, and have the owner confirm once in Studio (LightingStyle Realistic, Prioritize ticked, no Retro ColorGradingEffect).
- An Atmosphere kills every `FogEnd/FogColor` row in `needle-hunt/src/shared/Maps.luau`: convert them to `Atmosphere.Density/Color/Haze`. `RoundManager.light` writes `Lighting[key]`, so Atmosphere, Clouds and effects (child instances) need their own applier.
- With Environment scales at 1, today's ambients (about 120 / 150) wash out; the `dim` path should also lower `ExposureCompensation`.
- Phones on automatic quality often run below level 4: no shadows, maybe no sun rays, bloom or depth of field. The look must hold on ambients, Atmosphere and ColorCorrection alone.
- Sun height and compass direction cannot be checked offline. Past ClockTime 16.8 shadows get very long (dark corridors) and the sun fades near 18; verify with `Lighting:GetSunDirection()` in Studio.
- Bloom `Threshold`: docs describe 0..1, but Studio's HDR templates use 2 (memory); below 1 everything glows.
- `Light.Shadows = true` on a handful of lights only; `CastShadow = false` on small decoration.
- Keep look code outside the map builders, or teach `needle-hunt/dev/maprun/roblox.lua` the new classes and `workspace.Terrain`.


# research:geometry

# Geometry, detail and performance: research (11 Nov 2026)

**Network:** direct fetches of `create.roblox.com` and `devforum.roblox.com` were refused (ENOTFOUND; both hosts must be allowed in the session's network settings). Nothing below was read from a page. "Search" means a search-engine summary of that URL. CR = `https://create.roblox.com/docs`, DF = `https://devforum.roblox.com/t`.

## FACTS
**Budgets**
1. Low-end baseline is at most ~1,000 draw calls and ~1,000,000 triangles. CR/performance-optimization/design (search, medium-high)
2. Staff example for a fixed map: ~300 draw calls, ~300k triangles. Each Beam or ParticleEmitter costs one draw call. Shadows exist only in ShadowMap/Future at higher quality levels. DF/real-world-building-and-scripting-optimization-for-roblox/3127146 (search, medium-high)
3. Parts sharing shape and Material batch into one draw call. CFrame, Size and Color do not break batches; Material, mesh type, textures and above all Transparency do. DF/part-instancing-pre-release-announcement/130333 (2018) and 3127146 (search, medium)
4. CastShadow cost is disputed. Staff advise `CastShadow = false` on small detail. Same thread, 3127146 (medium)
5. A Block is 12 triangles; Ball and Cylinder are far more. Anchored parts cost memory and join replication, not physics. Unverified (memory), medium
6. Community rule: ~75k parts is still manageable on mobile. DF 4629258 (low)

**Lights**
7. Range maximum is now 120 (was 60) for PointLight, SpotLight and SurfaceLight; cost climbs steeply with range. DF/extended-light-ranges-doubling-the-limit-to-120/3954367 (search, high)
8. Unified Lighting is live: `Lighting.LightingStyle` (Realistic | Soft) and `Lighting.PrioritizeLightingQuality` replace `Technology`. Future equals Realistic plus true. DF 3401512 (search, medium-high)
9. Android gets Future only at quality 4/10 or above, and the engine may drop it. DF 3235808 (search, medium)
10. No official cap on shadow-casting lights was found. A PointLight shadow renders six faces against one for a SpotLight. Unverified (memory), medium

**Effects without textures**
11. Default `ParticleEmitter.Texture` is `rbxasset://textures/particles/sparkles_main.dds`, a white sparkle. CR/effects/particle-emitters (search, high)
12. `rbxasset://textures/particles/smoke_main.dds` (soft puff) and `.../fire_main.dds` exist. DF 2885322 (search, medium). This repo already uses the first two at `/home/user/screener3/needle-hunt/src/shared/NeedleAura.luau:65,75`.
13. Rate is capped at 400/s per emitter (100/s on mobile); cost is overdraw. CR/effects/particle-emitters (search, medium-high). Rate scaling with quality level is in flux: DF 4834736.
14. `Beam.Texture` and `Trail.Texture` default to empty, giving a flat hard-edged ribbon. Legacy `Smoke` and `Fire` instances need no texture. Unverified (memory), medium-high
15. `rbxasset://` is the client's local content folder, with no per-platform guarantee; `SpawnLocation.png` is no longer local. CR/projects/assets, DF 4309920 (search, medium)

**CSG and EditableMesh**
16. `GeometryService:UnionAsync` / `SubtractAsync` / `IntersectAsync` are fully released, run on the server and replicate. DF 4065505, DF 4554628, CR/parts/solid-modeling (search, medium-high)
17. They yield and can throw; docs warn against long call series. 2026 bugs: client crash (DF 4534537), console warning spam (DF 4656576).
18. EditableMesh needs an owner who is 13+ and ID-verified, plus Game Settings > Security > "Allow Mesh / Image APIs". Editable objects do not replicate. DF 3267293 (search, high)
19. `AssetService:CreateDataModelContentAsync` (2026) bakes replicating static content, 200 MB server cap. DF 4541898 (search, medium)

**Shapes, streaming, terrain**
20. `Enum.PartType`: Ball 0, Block 1, Cylinder 2, Wedge 3, CornerWedge 4; `Part.Shape` is scriptable. CR/reference/engine/enums/PartType (search, high)
21. No ellipsoids: Ball diameter is the smallest axis; a Cylinder's axis is X. Unverified (memory), medium
22. Size minimum is 0.001 per axis, collision treats it as at least 0.05, maximum is 2048. DF 1394733 (search, high)
23. `Workspace.StreamingEnabled` cannot be set by script and is on only for new Studio places. CR/workspace/streaming (search, high)
24. `needle-hunt/default.project.json` has no `$properties`, so the built file takes the engine default (off: unverified, medium).
25. `Terrain.Decoration` (animated grass) is not scriptable. DF 440321, DF 1890959 (search, medium-high)

## RECOMMENDED VALUES / RECIPES
- **Parts:** aim for 15,000–20,000 (25,000 ceiling), about 85% Blocks and Wedges. Keep Balls and Cylinders to roughly 1,500. Use at most 12 materials.
- **Transparency:** at most ~150 semi-transparent parts. Windows should be opaque dark SmoothPlastic, or Neon when lit.
- **Decoration flags:** `Anchored = true`, `CanCollide`, `CanQuery`, `CanTouch = false`. Set `CastShadow = false` on anything under ~2 studs or lying flat; keep it on walls, trunks, canopies and landmarks.
- **Build order:** set properties first and `Parent` last; put decoration in a `Detail` folder the client may delete on phones.
- **Lights:** at most 6 with `Shadows = true`, all SpotLight or SurfaceLight, Range 40 or less, not overlapping. Add up to 40 non-shadow PointLights at Range 12–24. No lights on particles.
- **Dust motes:** 4–6 invisible parts of about 80x16x80. `Shape = Enum.ParticleEmitterShape.Box`, `ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume`, default texture, Size 0.08–0.15, Rate 15, Lifetime 6–10, Speed 0.2–0.6, `SpreadAngle = Vector2.new(180, 180)`, Transparency 1 → 0.6 → 1, LightEmission 0.6.
- **Mist:** `smoke_main.dds`, Size 18–30, Transparency 1 → 0.92 → 1, Rate 1–2, Lifetime 12–18, `Drag = 1`, `WindAffectsDrag = true` with `workspace.GlobalWind`; at most 4 emitters.
- **Chimney smoke:** `smoke_main.dds`, `EmissionDirection = Enum.NormalId.Top`, Rate 3, Lifetime 5–8, Speed 3–4, SpreadAngle (8, 8), Size 1.5 → 6, Transparency 0.5 → 1. Fallback: `Instance.new("Smoke")` with Opacity 0.2, RiseVelocity 3, Size 2.
- **Fireflies:** default texture, Size 0 → 0.2 → 0, Rate 4, Lifetime 4–7, LightEmission 1, LightInfluence 0, Brightness 3.
- **Leaves:** the weakest effect without a texture. `smoke_main.dds`, Size 0.3, Transparency 0, RotSpeed ±180, `Acceleration = Vector3.new(0, -1.5, 0)`, Rate 1, at most 8 trees.
- **Light shafts:** at most 12 Beams between two Attachments, `FaceCamera = true`, LightEmission 1, LightInfluence 0, Width0 3, Width1 9, Transparency 0.92 → 1. Layer three widths to soften edges.
- **Total steady-state particles:** under about 1,500.
- **Realism tricks:**
  - Trim: 0.15–0.3 stud strips on edges, sills and corner posts.
  - Variation: ±4–8% colour jitter per plank or stone; rotate pieces 1–3° and overlap by 0.05 to avoid z-fighting.
  - Roofs: Wedges with 0.5-stud overhang and ridge caps.
  - Arches: 12–16 rotated blocks.
  - Foliage: canopies of 5–9 overlapping Balls, plus crossed 0.05-thick LeafyGrass cards.
  - Ground: smooth Terrain for ground, ruts and verges; parts for structures.
- **CSG and EditableMesh:** do not depend on either. If CSG is ever added, build at most 10 templates once at boot, wrap in `pcall`, `Clone()` them, and keep a part-only fallback.
- **Streaming:** write `"StreamingEnabled": false` explicitly on Workspace. A 370-stud arena fits in memory, and streaming would hide far landmarks and break client raycasts.
- **Decal/Texture:** avoid; use materials and colour.

## CAVEATS
- Every `rbxasset://` path is unverified per platform. A missing file renders nothing, so effects must be optional.
- Batching and CastShadow evidence is old or disputed. Only Studio's Draw (scene) and Draw (shadow) counters settle it.
- Lighting style and Terrain grass must go in the place file. The token values for `LightingStyle` were not verified.
- Particle density varies with quality level; never make particles carry gameplay information.
- `dev/maprun/roblox.lua` reads only PointLight and SpotLight for previews (line 330). GeometryService and AssetService calls would need yielding stubs.
- A 20k-part build replicates in one burst; hide it behind the intermission fade.
- Thin parts under 0.05 still collide and raycast as 0.05, so keep them `CanQuery = false`.


# design:world

# Hayfield Farm visual overhaul: geometry-first plan (design only, nothing edited)

**Three corrections to the brief, checked in the repo:**
- **Walls.** The real builder in maprun (seeds 1-3) makes 250-265 walls, 5,700-5,900 studs: about **365 16-stud segments, not 730** (91 per style). Budgets use 365; `ConfigLook.Budget.wallDensity` scales detail if that is wrong.
- **Use2022Materials is not emitted today.** `/home/user/screener3/needle-hunt/NeedleHunt.rbxlx` has no MaterialService item: `/home/user/screener3/dev/build.py` adds it only when a Config texture ID exists.
- **Balls cannot be flattened** (research fact 21): today's squashed pumpkins and pines are plain spheres in the engine. Every Ball below is uniform.

## 1. LOOK TARGET
Late September, 16:10, the last dry afternoon of harvest. A low gold sun rakes across four working fields; shadows lie long and cool across dusty lanes, and warm haze turns the hills beyond the boundary wall violet. Palette: straw 214,180,90; dry corn 186,160,88; barn red 142,52,44; silvered timber 112,96,80; galvanised steel 150,156,160; hedge 58,92,44; track dirt 118,96,66.

## 2. RENDER SETUP
**Place file** (`needle-hunt/default.project.json`, existing value types):
- `Lighting`: `Technology {"token":4}`, `LightingStyle {"token":0}`, `PrioritizeLightingQuality true`, `GlobalShadows true`
- `Workspace`: `StreamingEnabled false`; child `Terrain`: `Decoration true`, `GrassLength {"float":0.35}`
- `MaterialService`: `Use2022Materials true`, `Use2022MaterialsXml true` (build.py reuses this node rather than adding a second: two lines)

**Script** (`server/Look.luau`; instances made once): `Atmosphere`, `Sky` (`SunAngularSize 14`, default textures), `BloomEffect`, `ColorCorrectionEffect`, `SunRaysEffect` in Lighting; `Clouds` in `workspace.Terrain`. Every preset: `GlobalShadows true`, `EnvironmentDiffuseScale 1`, `EnvironmentSpecularScale 1`, `GeographicLatitude 41.7333`, any `ColorGradingEffect.TonemapperPreset` forced to Default. `LightingStyle` is pcall-read and warned about, never written.

| | gold (bigfarm, corn, windmill) | midday (lobby, other outdoor maps) | overcast (greenhouse, frozen, barn, attic) |
|---|---|---|---|
| ClockTime / Brightness / ExposureCompensation | 16.2 / 3 / 0.1 | 13.5 / 3 / 0 | 12.5 / 1.3 / 0.25 |
| Ambient; OutdoorAmbient | 58,52,62; 104,98,112 | 60,62,66; 95,100,108 | 96,100,106; 150,154,160 |
| ColorShift_Top / ShadowSoftness | 60,38,12 / 0.25 | 12,8,0 / 0.15 | 0,0,0 / 1 |
| Atmosphere Density / Offset / Haze / Glare | 0.3 / 0.25 / 1.6 / 0.35 | 0.28 / 0.25 / 0.6 / 0.1 | 0.42 / 0.1 / 2.4 / 0 |
| Atmosphere Color; Decay | 232,196,140; 120,98,110 | 199,206,214; 106,112,125 | 190,196,204; 120,126,134 |
| Clouds Cover / Density | 0.55 / 0.35 | 0.5 / 0.3 | 0.92 / 0.55 |
| Bloom Intensity / Size / Threshold | 0.8 / 28 / 1.8 | 0.5 / 24 / 2 | 0.3 / 24 / 2 |
| ColorCorrection Contrast / Saturation; TintColor | 0.12 / 0.1; 255,244,230 | 0.08 / 0.05; 255,255,255 | 0.05 / -0.12; 236,242,255 |
| SunRays Intensity / Spread | 0.12 / 0.6 | 0.05 / 0.4 | off |

- `sunset` = gold with ClockTime 17.4, Brightness 2.4, Atmosphere Color 244,170,120. `night` (forest): ClockTime 0.5, Brightness 1.2, ExposureCompensation 0.4, Ambient 34,40,58, OutdoorAmbient 58,68,96, Atmosphere Color 60,72,104, SunRays off.
- Dim rounds: Brightness × (1 − dim), ambients lerped to black by dim, ExposureCompensation − 0.6 × dim.
- Depth of field, client-side, lobby and results only: `FarIntensity 0.15`, `NearIntensity 0`, `FocusDistance 120`, `InFocusRadius 50`.

All values are untested starting points.

## 3. LANDSCAPE
Map-local coordinates on the 4-stud grid. The play square stays flat at y = 0.
- **Backdrop, built once before the first round, never cleared** (`Landscape.backdrop`, one call per frame): a Grass frame from 188 to 448 out, 16 deep: `FillBlock` (896,16,260) at z = ±318 and (260,16,376) at x = ±318, centre y −8. On it, fixed seed: 14 near hills `FillBall(Vector3.new(x, h − R, z), R, Grass)` (R 120-200, h 16-36, 250-330 out); 10 ridge hills (R 160-220, h 40-70, 380-430 out) hiding the slab edge even from the Bird's Eye camera; 9 field patches of 60-120 studs in Sand (stubble, at `Config.Haystacks.colour`), Ground and LeafyGrass; a pond at (250, −250): `FillBall(Vector3.new(250,14,-250), 22, Air)`, then `FillCylinder(CFrame.new(250,-5,-250), 6, 15, Water)`.
- **Play square, each round** (`Landscape.floor`): `FillBlock(centre + (0,-8,0), (376,16,376), Grass)`. An invisible `Ground` part (372×2×372, top y = 0, CanCollide and CanQuery true) stays in `ctx.model` for ChestSpawner's and maprun's raycasts. `Countryside` and the `Road` parts go.
- **Paint** (`Landscape.paint`: `FillBlock(CFrame.new(cx,-2,cz), (w,4,l), material)`, edges snapped out to multiples of 4). Quarters (8..156): corn Ground, pumpkin Mud, orchard Grass (the one maze with moving blades), mill LeafyGrass; Ground under every landmark. Roads last: cross roads Ground −8..8, leaving 4-stud Grass verges at the wall feet; ring road Ground 160..176. 40 one-cell Mud patches at gates and the crossroads.
- **Colours, set each round**: Grass 88,124,54; LeafyGrass 96,118,60; Ground 118,96,66; Mud 74,58,44; Rock 112,110,104.
- **Clear** (replaces `MapKit.clearTerrain`): `FillBlock(centre + (0,44,0), (376,120,376), Air)`.
- **Boundary at ±185** (`Boundary.build`): the `Hedge` boxes turn invisible; the `Edge` walls are untouched. Per 16 studs (93 runs, 7 parts): 2 Rock footing stones (8×3×3.4), 1 Slate coping (16×0.5×3.8), 1 hedge body (16×5.5×3, LeafyGrass 58,92,44), 2 top lumps (Blocks turned 45°), 1 leaning stake. Where the cross roads end: four closed five-bar gates between Rock piers (26 parts each), the lane running on as an 8-wide Ground track over the first hill.
- **Tree line**: 48 trees 22-30 tall at 191-197 out, in clumps of 2-4 so sun crosses the ring road in bars; no hiding spots outside the walls. The 64 trunks now standing on the ring road go.
- **Far dressing**: 110 far trees (trunk + 2 crossed Blocks), a farmhouse and two sheds with amber Neon windows, 30 round bales, 10 telegraph poles.

## 4. WALLS
Each wall keeps **one collidable `MazeWall` core at today's exact size and position** (corn 1.6×8.5, others 2×10). Everything else goes through `MapKit.deco` (CanCollide, CanQuery, CanTouch false) into `Arena.Detail` (silhouette pieces, shadows on) or `Arena.Detail.Fine` (`CastShadow false`, deleted on weak devices). Every piece: colour jitter ±6%, tilt 1-4°, 0.05 overlap.

| Per 16 studs | Core | Detail | Fine | Parts |
|---|---|---|---|---|
| **corn** | recoloured 92,84,48 (shadowed depth) | 14 stalks in two staggered rows at ±0.95 (0.3 × 9.5-12 × 0.3, Grass, 186,160,88 to 128,138,66, lean 2-5°, one in eight bent 35° at 60% height) | 14 leaf blades (a 0.08×0.5×3.4 Block through each stalk at 30°), 7 tassels (0.25×1.1×0.25, 236,204,110), 4 cobs (Block 0.45×1.3×0.45, 240,200,70), 2 planting ridges (1.2×0.5×16, Ground) | 42 |
| **vines**, as a hop trellis | LeafyGrass 44,84,40 | 2 posts through the wall (0.6×11×2.5, Wood 112,96,80), 1 top rail (0.4×0.4×16), 8 leaf slabs (LeafyGrass 0.6 × 3-4 × 3-4 turned 45°, three breaking the top line), 2 crown Balls (4-5) | 3 vine stems (0.25 thick, leaning 15-25°), 1 gourd (Ball 0.9), 2 dirt skirts (Wedge 0.5 high, 0.9 out) | 20 |
| **hedge** | LeafyGrass 58,92,44 | 6 face slabs (0.8 × 4-7 × 4-6, 0.25 proud), 2 top Balls (3-4.2, 84,122,56), 1 dark base (2.5×0.9×16, 54,60,36) | 4 crossed leaf cards (0.05×2.5×2.5), 1 stake | 15 |
| **stonehedge**, stone half | hidden | 16 Rock stones in three courses (1.8, 1.6, 1.4 high; 2-4.5 long; 2.6-2.9 through the wall; greys 150-178), 4 upright Slate copings, 2 hedge slabs and 2 Balls above | 2 moss caps, 1 fallen stone | 28 |

The hedge half of stonehedge is the hedge kit on 6 footing stones (21). Total: 91×42 + 90×20 + 91×15 + 91×24.5 = about 9,220. Each of the 32 maze gates (`maze.gates`, new) gets a 12-part timber arch: posts 0.9×12×0.9, lintel, a hanging plank with a part-built icon (cob, pumpkin, apple, sail) and a pennant in the quarter's colour (236,196,60 / 232,128,40 / 170,44,40 / 70,110,170).

## 5. LANDMARKS AND PROPS
Every `Climb`, `Ladder`, deck, loft, `Balcony` and stair bale keeps its size and position. Supports added under floating steps are non-colliding. No decorative ladders.
- **Silo (140)**: Metal 150,156,160; 12 hoop Cylinders (0.25×9.25); 10 CorrodedMetal streaks (128,78,50); deck joists and railing; six three-block cage hoops round the truss; an auger pipe down to a hopper; Slate pad.
- **Lookout (120)**: 16 X-braces, 8 girts; a pitched roof replaces the flat slab (two slopes of 5 lapped boards 9.6×0.2×1.2, ridge cap, 2 CorrodedMetal patches); a log post under each spiral step; bucket hoist.
- **Barn (420)**: the wall slabs stay as the inner skin (88,66,48); 62 outside boards (1.3×16×0.25; reds 142,52,44 / 128,46,40 / 156,64,52; every eighth silvered; three missing, letting light in); Rock plinth (1.4 high, 0.3 proud); trim 232,226,210; two X-braced doors slid open. A **gambrel roof replaces the flat slab**: four collidable planes (28×0.4×6 at 60°, 28×0.4×6.7 at 25°, ridge at y 24), 8 gable Wedges, 36 tin strips alternating CorrodedMetal 118,84,62 and Metal, a cupola (CornerWedge pyramid) with weathervane; 9 rafter pairs, 7 loft joists; hay hood with pulley; lean-to with firewood.
- **Windmill (230)**: the cylinder stays as the core; 16 whitewashed staves (Plaster 226,220,204, 1.95×14.2×0.5, leaning in 3°) taper the tower over a Rock footing band; the box cap becomes a drum (Cylinder 8.6 across, 4 high) under a 12-Wedge cone (4.5 high, Slate 88,70,58); four lattice sails (stock, 2 rails, 7 bars, canvas 232,224,200; welded to the tweened hub as now); 12 balcony struts; a Rock pier under each spiral stone.
- **Water tower (110)**: 20 tank staves (1.3×6×0.3), 4 CorrodedMetal hoops, 24 X-braces, 4 Slate pads, spout.
- **Hay Tower (150)**: each climb bale sits on a timber arm (0.6×0.6×7) with a 45° strut from the mast, non-colliding, so the crossroads stays passable under steps 4-9 as now; 5 iron bands; a derrick boom with a hanging bale; two long gold banners (255,205,70) visible down every lane.
- **Bale (8)**: block, 2 twines, 2 darker cut-end caps, 3 tufts. **Tree (22)**: two tapered trunk sections, 3 limbs, 4 root-flare Wedges, 5 Balls, 6 crossed leaf cards; 62,98,44 to 96,124,52, one in five turning 150,128,52. **Orchard**: 14 apple trees at cell centre ±4.5 (clear of power-up orbs). **Wagon (60)**: plank bed, staked sides, spoked wheels with iron tyres. **Fence (6 per 16 studs)**: leaning posts, two rails, one down every fifth run.
- **New**: tractor and hay trailer (120); 12 corn shocks; 20 leaning tools; slatted apple crates; lobed pumpkins (5 Balls and a stem); chicken coop; churns, troughs, wheelbarrows.
- **Ground contact** (`GroundKit`): 60 Wedge dirt skirts (Ground 104,86,60, 0.6 high, 1.2 out) round buildings and piers; 250 weed tufts at wall feet on the bare-soil quarters; litter by quarter: husks (150), pumpkin leaves (54), fallen leaves and windfalls (240), fallen stones (60).

## 6. FX
`server/Ambience` builds these after `Look.apply` from plain `ctx.fx` records, so builders never touch an effect class.
- **Wind**: `workspace.GlobalWind = Vector3.new(9,0,4)`, gusts ±30% every 6-10 s.
- **Motes**: 5 volumes of 80×16×80 (crossroads, barn, corn, mill yard, north road): default texture, Size 0.08-0.15, Rate 15, Lifetime 6-10, `Drag 1.5`, `WindAffectsDrag true`.
- **Mist**: 3 emitters beyond the hedge (`smoke_main.dds`, Size 18-30, Rate 1.5, Lifetime 12-18, Transparency 1 to 0.92 to 1). **Smoke**: farmhouse chimney (Rate 3). **Leaves**: 8 orchard trees, Rate 1. **Fireflies**: 6 emitters, Rate 4, only when dim ≥ 0.3.
- **Beams**: 6 barn light shafts through the missing boards, aimed along `Lighting:GetSunDirection()` (Width0 3, Width1 9, Transparency 0.92 to 1); 10 sagging telegraph wires (Width 0.08).
- **Lights**: 6 shadow SpotLights (Range 32, Angle 110, Brightness 1.6, 255,179,73): barn door, loft, mill door, hay-tower deck, silo base, lookout. 24 PointLights without shadows (Range 14-20) at gate arches, water tower, farmhouse.
- **Water** (pond only): `WaterColor 58,92,84`, `WaterTransparency 0.45`, `WaterReflectance 0.6`, `WaterWaveSize 0.05`, `WaterWaveSpeed 6`.

## 7. BUDGET
| Category | Parts |
|---|---|
| Wall cores / wall detail / gate arches | 265 / 9,220 / 385 |
| Boundary and field gates / tree line / orchard trees | 760 / 1,060 / 320 |
| Landmarks / props | 1,170 / 1,900 |
| Ground contact and loose straw | 1,850 |
| Far world / chests and orbs | 600 / 80 |
| **Total** | **about 17,600** (ceiling 25,000, asserted in check_maps) |

- About 1,700 Balls and Cylinders. Twelve materials (Grass, LeafyGrass, Wood, WoodPlanks, Rock, Slate, Metal, CorrodedMetal, Fabric, Plaster, Ground, SmoothPlastic) plus Neon lamp glass. No semi-transparent parts.
- 6 shadow lights; about 900 steady particles.
- Weak devices (`client/LookFx`: touch-only, or saved quality 1-3): `Arena.Detail.Fine` is destroyed locally (about 5,600 parts); motes, mist, leaves and Beams go off. The engine drops shadows, sun rays and bloom itself; ambients, Atmosphere, ColorCorrection and silhouettes carry the look.

## 8. MODULES
New (all under 300 lines):
- `shared/ConfigLook.luau`: presets, palette, `Budget { parts, wallDensity, pauseEvery }`, wind, water, terrain colours, FX rates. Merged with `for k, v in pairs(require(script.Parent.ConfigLook)) do Config[k] = v end`.
- `server/Look.luau`: `boot()`, `apply(name, dim)`.
- `server/Landscape.luau`: `backdrop(centre)`, `floor(ctx, half)`, `paint(ctx, x0, z0, x1, z1, material)`, `colours()`, `clear(centre)`.
- `server/Boundary.luau`: `build(ctx, half)`. `server/Flora.luau`: `tree(ctx, x, z, h, kind, spots)`, `appleTree`, `shock`, `pumpkin`, `tuft`.
- `server/WallKitCrop.luau` (corn, trellis), `server/WallKitHedge.luau` (hedge, stone): `kit(ctx, cf, len, height, T)`.
- `server/LandmarkSkins.luau` (silo, lookout, water tower, hay tower), `BarnKit`, `MillKit`, `FarmDress` (wagon, tractor, arches, tools), `GroundKit`: `skirt(ctx, cf, size)`, `litter(ctx, maze, theme, n)`.
- `server/Ambience.luau`: `start(ctx, dim)`, `stop()`. `client/LookFx.luau`.

Changed:
- `MapKit`: `deco(ctx, props, fine)`, `tint(ctx, rgb, pct)`; `bale`, `tree`, `edges` delegate. `Config.Studs.on = false`.
- `MazeWalls`: corn, vines, stone and a new `hedge` build the core and call a kit, so the other maps using them improve too. `MazeKit` records `maze.gates`.
- `Maps`: `look = "gold"` replaces each `lighting` row; Fog values go (dead under an Atmosphere).
- `RoundManager` (289 lines): `Look.apply` replaces `light()`, a net cut. Decoration is built before players move in, pausing every 3,000 parts (`ctx.pause`, absent in maprun), then 1.5 s for replication; today nothing waits after `phase("loading", 3)`.

`dev/maprun/roblox.lua`: builders need nothing new by design (Part shapes, TrussPart, Folder and the Fill calls it has). Add `collide`, `query` and `tier` to `R.collect`; cache the part list in `included()` (rebuilt for every ray today); `Lighting:GetSunDirection()` so Ambience can be smoke-run. `check_maps.py` then asserts for bigfarm: parts within budget, 10 spawns, 5 chests, no Detail part collides or answers queries, one core per wall with today's total length.

Optional textures later (nothing depends on them): corrugated tin on CorrodedMetal, board-and-batten on WoodPlanks. Never an override on Grass: it would probably repaint terrain grass too (unverified).

## 9. RISKS
1. **Chests find no floor on terrain**: the invisible `Ground` part keeps the `Include { ctx.model }` raycasts and the shim unchanged.
2. **Decoration blocks rays, throws or chest spots**: one `MapKit.deco` path, asserted in check_maps; cores unchanged, so corridors and throw stops are identical.
3. **Climb routes**: no gameplay part moves; only the barn's ceiling slab becomes collidable roof planes above it.
4. **Terrain between rounds**: the clear box is grid-aligned and covers only the play square; colours reset each round; no water inside the walls.
5. **Non-scriptable properties**: place file only. The owner confirms once in Studio: LightingStyle Realistic, Use2022Materials ticked, grass blades visible, no Retro tone mapping. A Terrain item without voxel data in the file, and the `Use2022MaterialsXml` name, are unverified.
6. **Dark corridors at 16.2**: sky fill lights the shade; fallback ClockTime 15.6. Sun compass direction is unknown offline, so nothing is composed around it.
7. **Server hitch and replication burst**: paced build under the loading screen.
8. **Other 15 maps**: they keep part floors (the backdrop frame starts at 188) and inherit kits and presets; re-run check_maps on all.
9. **`rbxasset://` particle textures missing on a platform**: effects carry no gameplay information.
10. **Blades through thin parts**: blades only on verges and in the orchard, which gets leaves instead of loose straw.


# design:light

# Hayfield Farm: lighting-first overhaul plan

Design only: no source was edited, nothing built or committed. The plan runs over the 1,800-word target (about 2,200 words plus table markup) because the preset and wall tables carry the exact values.

Two things I measured differ from the brief:
- **Walls:** maprun (seeds 1-3) gives about 83 sixteen-stud lengths per quarter: **about 335 in total, not 730**. Budgets use 335.
- **Materials:** `/home/user/screener3/needle-hunt/NeedleHunt.rbxlx` has **no MaterialService item** (`dev/build.py` appends it only when Config names an uploaded texture), so the place most likely opens with pre-2022 materials today.

## 1. LOOK TARGET
The last dry afternoon of harvest, 4:12 pm. A low amber sun rakes in from the corner behind the water tower: wall tops, tassels, tin roofs and the white windmill burn gold; the lanes sit in cool violet shade, a lantern glowing at every gate. Honey haze swallows rolling fields beyond the hedge, under slow cumulus. Palette: straw (214,180,90), sun amber (255,214,160), shade violet (86,96,128), olive (88,124,54), oxblood (128,44,38), whitewash (226,220,206), galvanised steel (150,156,160), weathered wood (112,96,80).

## 2. RENDER SETUP
**Place file** (`/home/user/screener3/needle-hunt/default.project.json`; scripts cannot write these):
```json
"Lighting": {"$className":"Lighting","$properties":{"Technology":{"token":4},"LightingStyle":{"token":0},"PrioritizeLightingQuality":true,"GlobalShadows":true}},
"MaterialService": {"$className":"MaterialService","$properties":{"Use2022Materials":true,"Use2022MaterialsXml":true}},
"Workspace": {"$className":"Workspace","$properties":{"StreamingEnabled":false},
  "Terrain":{"$className":"Terrain","$properties":{"Decoration":true,"GrassLength":{"float":0.45}}}}
```
**Script, once** (`Look.init`): `GlobalShadows = true`, `EnvironmentDiffuseScale = 1`, `EnvironmentSpecularScale = 1`, `GeographicLatitude = 41.7333`; one `Atmosphere`, `Sky` (`SunAngularSize` 16, `MoonAngularSize` 9, default textures), `BloomEffect`, `ColorCorrectionEffect`, `SunRaysEffect` in Lighting; `Clouds` in `workspace.Terrain`; any `ColorGradingEffect.TonemapperPreset = Default`. `DepthOfFieldEffect` goes on the client's camera, lobby and results only: `FarIntensity` 0.15, `NearIntensity` 0, `FocusDistance` 120, `InFocusRadius` 50.

**Script, per preset** (`Look.apply`):

| | gold | noon | overcast | dusk | night | interior |
|---|---|---|---|---|---|---|
| ClockTime | 16.2 | 13.5 | 12.5 | 17.5 | 0.5 | 15 |
| Brightness | 3 | 3 | 1.3 | 2.4 | 1.6 | 2 |
| ExposureCompensation | 0.1 | 0 | 0.25 | 0.25 | 0.6 | 0.4 |
| Ambient | 58,52,62 | 60,62,66 | 96,100,106 | 70,54,66 | 38,46,72 | 104,88,70 |
| OutdoorAmbient | 104,98,112 | 95,100,108 | 150,154,160 | 124,96,104 | 64,76,112 | 120,104,86 |
| ColorShift_Top | 72,44,14 | 12,8,0 | 0,0,0 | 110,56,18 | 0,8,30 | 40,26,8 |
| ShadowSoftness | 0.25 | 0.15 | 1 | 0.4 | 0.5 | 0.5 |
| Atmosphere Density/Offset/Haze/Glare | 0.3/0.25/1.6/0.35 | 0.28/0.25/0.6/0.1 | 0.42/0.1/2.4/0 | 0.36/0.3/2.2/0.8 | 0.42/0.1/1.2/0 | 0.2/0/0.8/0 |
| Atmosphere Color | 232,196,140 | 199,206,214 | 190,196,204 | 250,170,120 | 60,74,110 | 190,160,120 |
| Atmosphere Decay | 112,104,128 | 106,112,125 | 120,126,134 | 96,70,120 | 20,26,44 | 90,76,60 |
| Clouds Cover/Density | 0.55/0.35 | 0.5/0.3 | 0.92/0.55 | 0.6/0.4 | 0.35/0.3 | 0.4/0.3 |
| Clouds Color | 255,236,214 | 255,255,255 | 200,204,210 | 255,190,150 | 120,130,160 | 255,255,255 |
| Bloom Intensity/Size/Threshold | 0.6/28/1.6 | 0.5/24/2 | 0.3/24/2 | 0.9/32/1.6 | 1/30/1.2 | 0.6/24/1.6 |
| ColorCorrection Contrast/Saturation | 0.12/0.1 | 0.08/0.05 | 0.05/-0.12 | 0.14/0.14 | 0.1/-0.1 | 0.08/0 |
| ColorCorrection TintColor | 255,244,230 | 255,255,255 | 236,242,255 | 255,232,214 | 214,226,255 | 255,240,220 |
| SunRays Intensity/Spread | 0.12/0.6 | 0.05/0.4 | off | 0.2/0.7 | off | off |
| workspace.GlobalWind | 9,0,4 | 6,0,3 | 12,0,5 | 5,0,2 | 3,0,1 | 0,0,0 |

Each `Maps.list` row swaps `lighting = {...}` for `look = "<preset>"`; the Fog keys go (dead under an Atmosphere). gold: bigfarm, pumpkin, corn, windmill. noon: lobby, field, sunflower, orchard, market, fair. overcast: frozen, greenhouse, marsh. dusk: sunset. night: forest. interior: barn, attic.

**Dim** (Hard 0.35, Low Light +0.45) replaces the ambient lerp: `ExposureCompensation -= 1.6*dim`, both ambients `*(1 - 0.5*dim)`, `Atmosphere.Density += 0.1*dim`, `Saturation -= 0.15*dim`, `TintColor` lerps `0.5*dim` towards (200,214,255): a blue hour the gate lanterns carry.

**Sun.** By my calculation (unverified), ClockTime 16.2 puts the sun at (-0.85, 0.43, 0.31): 25 degrees up, over the -X/+Z corner. A 10-stud wall throws 21 studs of shadow, so north-south lanes are fully shaded and east-west lanes half lit. Builders read `Lighting:GetSunDirection()` in a pcall (`ctx.sun`). If the lanes read too dark in Studio, use ClockTime 15.0 (42 degrees, 11-stud shadows).

## 3. LANDSCAPE
**Persistent world, once at boot** (`Landscape.world`; maprun never runs it):
- Slab: `FillBlock` Grass, x -448..448, z -448..1048, y -8..0, in 256-stud strips. Air holes at y -4..0: 264x264 under the lobby, 376x376 under the arena. `MapKit.edges` shrinks its Countryside part to the hole, so the lobby and all 16 maps share one horizon.
- Fields outside the holes (top cell layer, 96-240 studs a side): stubble `Sand` (the haystack gold, deliberately), tilled `Mud`, clover `LeafyGrass`; the rest long `Grass` in the wind.
- Pond in the sun's corner, arena-local (-250, 250): `FillCylinder` Mud radius 42, then Water radius 36, height 4 at y -2. `WaterColor` 58,92,84; `WaterTransparency` 0.45; `WaterReflectance` 0.6; `WaterWaveSize` 0.05; `WaterWaveSpeed` 6.
- Horizon: hills are Ball parts (Grass, 88,124,54; no collision, query or shadow), since a terrain ball that size is over 300,000 cells. 30 (diameter 560-680, tops 30-44 studs) ring the slab edge every 160 studs and hide it; eight (diameter 360, top 40) every 120 studs along world z = 296 screen the lobby from the arena. Tree clumps, three far farmsteads (60 parts each) and 12 telegraph poles give scale.

**Hayfield floor, every round** (`Landscape.farm(ctx)`; `FillBlock` only, 4-stud aligned, y -4..0):
- Base 376x376 Grass. Corn and pumpkin quarters (12..156 on each axis) `Mud` as tilled soil, so gold corn sits on a dark value. Orchard and mill quarters `LeafyGrass` (no blades to poke through props). Roads `Ground`, 24 wide (-12..12 and 156..180), each with two 4-wide `Mud` ruts. Crossroads 40x40 and 28x28 landmark aprons `Cobblestone`.
- `SetMaterialColor` every round: Grass 88,124,54; LeafyGrass 92,116,58; Ground 146,120,84; Mud 96,76,54; Cobblestone 138,132,122.
- The `Ground` part stays as the collision and raycast floor: 376x2x376, `Transparency = 1`, `CastShadow = false`. `Road` parts go. `MapKit.clearTerrain` becomes 376x100x376 centred y +46: exactly the hole.
- Edge: the hedge keeps its collider and gains 370 cladding slabs and lumps, with 40 poplars behind it.

## 4. WALLS
One rule: the collidable `MazeWall` core keeps today's size and position and turns dark, so corridors, perches and raycasts do not change. Everything else has `CanCollide`, `CanQuery` and `CanTouch` false, sits within 2 studs of the wall's centre plane, and uses its own `Random`, never `ctx.rng`, so a seed still builds the same maze. Colours jitter 6%; bottom courses are 12% darker (painted occlusion for phones without shadows).

| Style | Parts per 16 studs | Recipe |
|---|---|---|
| Corn `farmCorn` | 58 | Core 1.6x8.5, Grass (62,66,36). Soil ridge 3.2x0.5x16, Ground. 20 stalks in two staggered rows (x +/-0.8, every 1.6): 0.3x(10.5-12.5)x0.3, lean to 3 degrees, (120,140,62) to (206,182,96); every second casts a shadow. 20 leaves: Wedge 0.06x0.55x2.6 drooping 25-55 degrees. 10 tassels 0.22x1.1x0.22 (232,204,128). 5 cobs 0.42x1.2x0.42 (168,170,84). 2 litter mats. |
| Vines `farmVines` | 34 | Core 2x10, LeafyGrass (34,58,32). 2 posts 0.6x11x0.6, Wood (112,96,80); 4 rails. 10 leaf slabs 3.4x(3-5)x0.5, tilt to 8 degrees, greens (48-84,104-146,44-58). Top: 3 Balls of diameter 2.4-3.4, 2 cubes turned 45 degrees. 6 stems 0.22x(5-9). 3 blossoms (246,196,58), 1 gourd, 1 mulch strip. |
| Hedge `farmHedge` | 21 | Core 2x10 (30,54,30). 8 face slabs 4.2x9.4x0.45, yaw to 2 degrees, (50-66,96-116,48-58), starting 0.7 up over a dark stem strip. 4 caps 2.9x1.1x4.2 in lighter (84,128,60) and 2 Wedge bevels: the sunlit rim. 3 weed tufts, 2 sprigs, 1 mulch strip. |
| Stone `farmStone` | 41 stone or 21 hedge, 50:50 per run | Core 2.6x5, Slate (86,82,78), hedge core above. 18 through-stones in 3 courses, (2.9-3.3)x1.55x(1.8-3.4), yaw to 3 degrees, warm greys 140-178. 8 tilted coping stones. Hedge top: 6 slabs, 3 caps. 2 moss pads, 2 ivy strands, 2 weeds. |

**Gates** (32, 14 parts each, from a `MazeWalls.gate` hook in MazeKit): two posts, a lintel at 11.5, a banner in the quarter's colour (corn 236,196,70; pumpkin 232,120,40; orchard 190,48,44; mill 236,232,220) and a Neon lantern with a PointLight: the wayfinding.

## 5. LANDMARKS AND PROPS
Every `Climb` collider, ladder and chest top stays put; dressing goes round it. Nothing floats any more.
- **Silo** (+75): galvanised Metal (150,156,160), the map's brightest highlight; 12 seam ribs, 6 hoops, an oxblood band, CorrodedMetal streaks, ladder cage, auger chute.
- **Lookout** (+60): cross-braces, rails, four-Wedge pyramid roof, red pennant; a leg under every jump post.
- **Barn** (+260): gable roof of 14 Wedge strips (Metal, two CorrodedMetal) over the kept ceiling slab; 68 battens on oxblood boards; white trim, X-braced doors; Cobblestone plinth; posts and tie beams inside; two hanging lanterns; sun shafts through the west wall.
- **Windmill** (+150): whitewashed Cobblestone (226,220,206) on raw stone; lattice sails (32 welded parts) whose shadows sweep the tower; Wedge cap, arched door, one Neon window, balcony rail on 8 brackets; a stone pier under each jump stone.
- **Water tower** (+90): 16 staves, 3 rusty hoops, braced legs, a dripping spout over a reflective puddle, a 12-blade wind pump turning beside it. It stands in the sun's corner: the backlit silhouette.
- **Hay Tower** (+120): banded log mast, a beam and knee brace under every bale, four bunting lines (48 flags), a needle-shaped weathervane, a beacon lantern.
- **Trees** (18 parts x 64): two-piece tapered trunk, 3 limbs, 3 root Wedges, 6 Balls (sun side 104,140,62; core 52,84,44), 4 leaf cards; trunk and two Balls cast dappled shade on the ring road.
- **Bales** get paler cut ends and wisps; **carts** spoked wheels; **fences** posts every 8 studs, rails spanning 16.
- **New**: an original blocky tractor and hay wagon at the crossroads; a colour-coded signpost; 14 puddles in the ruts (Cylinder 0.05 thick, SmoothPlastic 44,40,36, `Reflectance` 0.35, top at y 0.1); trough, chicken coop, beehives, milk churns; 200 wildflower tufts; 20 rock clusters.

## 6. FX
- **Wind**: the preset's `GlobalWind`, gusting 30% either way every 6-10 s.
- **Dust motes**: 6 invisible hosts (80x16x80 over each quarter and the crossroads; 24x12x16 in the barn). The research recipe (Box volume, default texture, Rate 15, Lifetime 6-10, Transparency 1 to 0.6 to 1) with Size 0.1, Color 255,236,190, `Drag` 1.5, `WindAffectsDrag`.
- **Chaff** over the corn: 2 emitters, Rate 6, Size 0.25, straw tint, RotSpeed +/-90, Lifetime 5-8.
- **Shafts**: 4 (three in the barn, one through the western trees), each 3 Beams: Width0 3/1.8/0.9, Width1 9/5.4/2.7, Transparency 0.92 to 1, LightEmission 1, LightInfluence 0, FaceCamera, aimed along `-ctx.sun`.
- **Others**: smoke at three far chimneys (Rate 3, Lifetime 5-8); leaves under 8 trees (Rate 1); the spout drip (Rate 2); pond mist (2 emitters, Rate 1.5, Size 18-30).
- **Lights**: 32 gate lanterns (PointLight Range 14, Brightness 0.9, 255,190,110); 5 landmark lamps (silo, lookout, windmill door, water tower, Hay Tower; Range 16-24); 2 barn SpotLights (Range 32, Angle 110, Brightness 2.2, `Shadows = true`).

## 7. BUDGET
| Category | Parts |
|---|---|
| Walls: corn 4,870, vines 2,860, hedge 1,760, stone 2,600, gates 450 | 12,540 |
| Landmarks (80 kept, 755 new) | 835 |
| Trees 1,150, edge hedge 370, poplars 200, fence 450, tufts 600, rocks 60 | 2,830 |
| Props (700 re-dressed, 450 new) | 1,150 |
| Loose straw (the difficulty setting, unchanged) | up to 1,140 |
| Chests, perches, FX hosts | 90 |
| Persistent countryside, shared with the lobby | 500 |
| **Total** | **about 19,100 of 25,000** |

- Balls and Cylinders about 1,350 (1,960 today); 12 materials; no semi-transparent parts (windows are dark SmoothPlastic or Neon).
- Shadow casters about 2,200 (cores, alternate stalks, caps, trunks, landmark masses, sails); the rest `CastShadow = false`.
- Lights: 2 with shadows (cap 4), 37 without, plus 5 chest lights. Particles: about 970 alive (cap 1,500) from 22 emitters; 12 Beams.
- **Weak devices** (`client/LookClient`): touch-only devices start low; anyone under 30 fps for 4 s after the countdown drops to it. Low destroys `Arena.Fine` (about 7,100 parts: leaves, tassels, cobs, tufts, trim, straw), keeps two mote volumes at Rate 6, and disables Beams, SunRays and depth of field. Below quality 4 the engine drops shadows itself; Atmosphere, grade and painted occlusion carry the look.

## 8. MODULES
All under `/home/user/screener3/needle-hunt/`, each under 300 lines.

| File | Responsibility and key signatures |
|---|---|
| `src/shared/ConfigLook.luau` (new) | `presets`, `sunFallback`, terrain colours, palette, `density`, `budget = { parts = 25000, shadowLights = 4, particles = 1500 }`, tiers. Config.luau gains `Config.Look = require(script.Parent.ConfigLook)` and `Studs.on = false`. |
| `src/server/Look.luau` (new) | `Look.init()`, `Look.apply(name, dim, over)`, `Look.sun() -> Vector3`; gust loop; warns if `LightingStyle` is not Realistic (pcall read). |
| `src/server/Landscape.luau`, `Dress.luau` (new) | `Landscape.world()`, `Landscape.farm(ctx)`; `Dress.part(ctx, layer, props)` (layer "detail" or "fine" sets the flags and folder), `Dress.tone(rgb, pct, rng)`. |
| `src/server/WallsFarm.luau`, `WallsFarm2.luau` (new) | `farmCorn`, `farmVines`; `farmHedge`, `farmStone`, each `(ctx, a, b, height, T)`; `gate(ctx, style, a, b, height)`. Merged into MazeWalls. |
| `src/server/LandmarkDress.luau`, `BarnDress.luau`, `Flora.luau`, `FarmSet.luau`, `FarmFx.luau` (new) | One function per landmark, `(ctx, x, z)`, called from Landmarks; `Flora.tree(ctx, x, z, h, kind)`; props such as `FarmSet.lantern(ctx, pos, shadows)`; `FarmFx.build(ctx)`. |
| `src/client/LookClient.luau` (new) | `LookClient.start()`: tiers, lobby depth of field. |
| Changed | `MapsBig` (orchestrates; yields between quarters), `MapKit` (edges, clearTerrain, trees, bales), `MazeKit` (+6 lines), `MazeWalls` (+4), `Landmarks`, `RoundManager` (`light()` becomes `Look.apply`; shorter than its 289 lines), `Maps`, `Main.server`, `default.project.json`, `/home/user/screener3/dev/build.py` (3 lines: reuse an existing MaterialService node), `dev/maprun/check_maps.py`, `dev/test_rules.py`, NOTES.md. ChestSpawner (294 lines) is untouched. |

**`dev/maprun/roblox.lua` must learn:**
- `included()` skips parts that neither collide nor answer queries; otherwise each raycast walks 19,000 boxes (a build takes 1.8 s today).
- `R.collect` exports `canCollide`, `castShadow` and the folder; a new `R.census(model)` counts shadow lights, emitters (Rate x longest Lifetime) and Beams, so `check_maps.py` can hold bigfarm to `ConfigLook.budget` and assert no decoration collides.
- `ColorSequenceKeypoint.new` (missing today).
- Nothing for Atmosphere, Clouds or wind: Look and `Landscape.world` never run there. Decoration keeps to `CFrame.new/Angles/lookAt`, Wedge (the preview cannot draw CornerWedge) and the Luau subset `luau2lua.py` converts.

## 9. RISKS
- **Chests, spawns, corridors:** colliders are unchanged and decoration has its own RNG, so seeds build the same mazes; the invisible `Ground` part keeps ChestSpawner's Include-filter raycasts working.
- **Terrain:** blades poke through thin parts, so `Grass` is only on verges and outside; colours are reset every round; the clear box matches the hole, so it cannot trench the countryside; water is outside the invisible walls.
- **Unwritable properties** (`LightingStyle`, `Technology`, `Decoration`, `GrassLength`, `Use2022Materials`) appear only in the project file; the Python checker would not catch a write. The owner confirms once in Studio: Realistic, quality prioritised, no Retro grading, 2022 materials, grass on.
- **Dark lanes, phones:** half the lanes are shaded by design, and the sun's direction is calculated, not measured; the fallback clock time, painted occlusion and lanterns cover both.
- **Build burst:** about 19,000 parts replicate during the 3 s countdown. If phones stall, wall dressing can move to the client (it needs only the run list and a seed).
- **Textures:** only the default particle texture is required; smoke and mist use `rbxasset://textures/particles/smoke_main.dds` and may not draw. Optional uploads later: hay maps, a leaf card, a soft Beam gradient.


# design:land

# Hayfield Farm visual overhaul: landscape, level design and performance

Design only; no source was edited. File names below are under `/home/user/screener3/needle-hunt/src/` unless a fuller path is shown.

**Checked first (these change the brief)**
- Measured with dev/maprun (seeds 1-3): 325-336 sixteen-stud wall segments, about 83 per quarter, in about 260 runs. 730 is the slot count before carving. Today: about 5,800 parts, 1,962 of them Balls or Cylinders.
- `/home/user/screener3/needle-hunt/NeedleHunt.rbxlx` has no MaterialService: `/home/user/screener3/dev/build.py:236` appends it only when a texture ID exists, so the place opens with pre-2022 materials today.
- `RoundManager.luau` is 289 lines and `ChestSpawner.luau` 294. This plan shrinks the first and leaves the second alone.
- `dev/preview/render.html` reads `def.lighting.ClockTime`, so that key must survive.

## 1. LOOK TARGET
Late-summer harvest, mid-afternoon: a 38 degree sun raking diagonally across the maze, so every corridor has a warm sunlit strip beside a cool blue-grey shadow. Bleached straw (214,180,90), packed-earth ochre (134,108,76) and deep hedgerow green (52,84,40); saturated colour only on landmarks (barn red 128,52,44, galvanised 150,156,160, white sails). Thin warm haze turns the rim hills lilac under soft cumulus: dusty, calm, sun-baked.

## 2. RENDER SETUP
**Place file** (`needle-hunt/default.project.json`):
- `"Lighting": {"$className":"Lighting","$properties":{"Technology":{"token":4},"LightingStyle":{"token":0},"PrioritizeLightingQuality":true,"GlobalShadows":true}}`
- `"Workspace": {"$className":"Workspace","$properties":{"StreamingEnabled":false},"Terrain":{"$className":"Terrain","$properties":{"Decoration":true,"GrassLength":{"float":0.35}}}}`
- `dev/build.py`: always append MaterialService, with `Use2022Materials` and `Use2022MaterialsXml` true (additive; the main game's file already carries the first).

**Script** (`Look.apply`, every preset): `GlobalShadows=true`, `EnvironmentDiffuseScale=1`, `EnvironmentSpecularScale=1`, `GeographicLatitude=41.7333`, `ColorShift_Bottom=0,0,0`. One `Sky` (`SunAngularSize=14`, `MoonAngularSize=9`, `StarCount=3000`). `Atmosphere`, `BloomEffect`, `ColorCorrectionEffect`, `SunRaysEffect`, `DepthOfFieldEffect` in Lighting; `Clouds` in `workspace.Terrain`; any `ColorGradingEffect` forced to `Enum.TonemapperPreset.Default`.

| Property | harvest (bigfarm) | gold (lobby, sunset) | night (forest) | indoor (barn, attic) |
|---|---|---|---|---|
| ClockTime / Brightness / ExposureCompensation | 14.25 / 3 / 0.05 | 16.4 / 3 / 0.1 | 0.5 / 1.2 / 0.4 | 13 / 1.6 / 0.2 |
| Ambient | 58,54,62 | 58,52,62 | 34,40,60 | 70,60,50 |
| OutdoorAmbient | 108,104,116 | 104,98,112 | 58,66,96 | 96,84,70 |
| ColorShift_Top / ShadowSoftness | 40,26,8 / 0.2 | 60,38,12 / 0.25 | 0,0,0 / 0.6 | 20,12,4 / 0.4 |
| Atmosphere Density / Offset / Haze / Glare | 0.3 / 0.25 / 1.4 / 0.3 | 0.3 / 0.25 / 1.6 / 0.35 | 0.42 / 0 / 1.2 / 0 | 0.2 / 0 / 2.2 / 0 |
| Atmosphere Color | 226,200,152 | 232,196,140 | 40,52,84 | 150,126,96 |
| Atmosphere Decay | 116,104,118 | 120,98,110 | 20,26,44 | 90,72,56 |
| Clouds Cover / Density | 0.5 / 0.35 | 0.55 / 0.35 | 0.35 / 0.3 | 0.4 / 0.3 |
| Bloom Intensity / Size / Threshold | 0.6 / 28 / 1.8 | 0.8 / 28 / 1.8 | 0.6 / 24 / 1.6 | 0.6 / 24 / 1.6 |
| ColorCorrection Contrast / Saturation | 0.12 / 0.08 | 0.12 / 0.1 | 0.1 / -0.1 | 0.08 / 0 |
| ColorCorrection TintColor | 255,246,234 | 255,244,230 | 214,226,255 | 255,240,222 |
| SunRays Intensity / Spread | 0.1 / 0.6 | 0.12 / 0.6 | off | 0.15 / 0.8 |

- **midday** (the eight sunny maps) and **overcast** (frozen, greenhouse, marsh) use the lighting researcher's two columns unchanged.
- **Why 14.25, not 16.2.** On a 12-hour day at the default latitude I estimate the sun about 20 degrees up at 16.2 (equinox model, unverified): a 10-stud wall then throws 27 studs of shadow and every corridor across the sun is dark. At 14.25 it is about 38 degrees up and 45 degrees off the grid, so each wall shades about 9 of a corridor's 14 studs, both ways. `Look.sun` checks this at boot: it steps `ClockTime` 12.5-16.5 by 0.05, reads `Lighting:GetSunDirection()`, takes the nearest match, and falls back to 14.25 if the direction never changes.
- **Depth of field:** lobby and results only (`FarIntensity` 0.15, `NearIntensity` 0, `FocusDistance` 120, `InFocusRadius` 50).
- **dim** (Hard 0.35, Low Light +0.45): `ExposureCompensation -= 1.3*dim`, both ambients x (1 - 0.6*dim), `Atmosphere.Density += 0.08*dim`, `Saturation -= 0.2*dim`. Brightness stays, so shadows still read.

## 3. LANDSCAPE
Map-local coordinates, every fill on multiples of 4. Wall lines and cell centres fall on cell middles (2 mod 4), so 4-wide strips under them are aligned.
- **Colours** (`SetMaterialColor`, each round): Grass 88,124,54; LeafyGrass 96,118,60; Ground 134,108,76; Mud 84,66,50; Cobblestone 150,146,136. Never Sand (haystacks own it).
- **Slab:** `FillBlock(at(0,-8,0), 896x16x896, Grass)`. The `Ground` part (top y=0) stays as an invisible collidable floor, so ChestSpawner and the shim are untouched. The four `Hedge` colliders also go invisible. `Countryside` and `Road` parts are deleted.
- **Top-layer paint (y -4..0):**
  - Cross roads: Ground on [-8,8], Mud ruts on [-8,-4] and [4,8]. Ring road: Ground on [156,180], ruts on [160,164] and [172,176].
  - Quarter floors, [12,152] squared: corn Ground, pumpkin LeafyGrass, orchard and windmill Grass.
  - A 4-wide strip under every wall run: Mud (corn, vines), LeafyGrass (hedge, stonehedge).
  - A 20x4 worn strip per open link between cell centres: Mud (pumpkin), Ground (orchard), Cobblestone (windmill).
  - A 28x28 yard under each landmark: Cobblestone (silo, windmill), Ground (barn), Mud (lookout).
- **Edge (185):** a planted hedgerow of 6-stud LeafyGrass modules 8-12 high in two jittered layers, a tree every 32 studs, and at each road end a 28-stud opening with a closed five-bar gate. The invisible colliders still seal it.
- **Fields (186-240):** eight painted fields (Ground ploughed, LeafyGrass meadow), six wheat slabs 1.2 high (Grass, 206,176,96), 24 round bales, post-and-rail fences.
- **Hills (240-448):** `WriteVoxels` in chunks of at most 64x12x64 cells with `task.wait()`. Height = s x (12 + 22(0.5 + 0.5 noise(x/150, z/150)) + 6 noise(x/48, z/48)), s = smoothstep((d-240)/90), d = max(|x|,|z|), never below 44 x smoothstep((d-350)/60): a rim that hides the slab edge even from the hay tower. Occupancy = clamp((h - y0)/4, 0, 1). Each chunk in `pcall`; on failure, 20 `FillBall` mounds (R 70, top 20) at d = 330.
- **Four vista ends,** one per road axis at d about 300, each down a painted lane through its gate: red barn with twin silos (-z), three wind pumps on a ridge (+x), farmhouse with chimney smoke under an oak (+z), pond with jetty and willow (-x).
- **Lobby:** no terrain inside its hedge; 12 `FillBall` mounds (R 40, top 12) at d = 118 and 20 trees. `Landscape.clear` is exactly the slab footprint (896x256x896, four calls), so lobby terrain survives.

## 4. WALLS
Colliders keep today's footprints; all dressing is `CanCollide/CanQuery/CanTouch=false`, `CastShadow=false`.

| Style | Collider | Dressing per 16 studs | High | Low |
|---|---|---|---|---|
| corn | core 1.6x8.5, LeafyGrass 62,84,38 | 14 stalks 0.3x(10-12)x0.3 in two rows at +/-0.9, tilted 2-4 degrees, Grass 128,138,62 to 176,160,88; 14 strap leaves 4.5x0.06x0.7 crossing each stalk at 25-40 degrees; 7 second leaves; 7 tassels 0.5x1.1x0.5 (206,178,104); 5 husked ears 0.45x1.3x0.45 (168,172,96) | 48 | 22 |
| vines | core 2x10, LeafyGrass 48,84,40 | a trellis: 5 posts 2.2x10.6x0.5 (Wood 104,88,70), 4 rails; 14 leaf slabs (2.6-4)x(2-3.2)x0.5 rolled +/-20 degrees in 58,98,44 / 74,116,50 / 92,128,58; 4 diamond top lumps 1.8x1.8x3.5; 4 stems; 3 gourds (Ball 0.9-1.3, 204,108,36) | 35 | 16 |
| hedge | core 2x10, LeafyGrass 44,78,40 | 8 face panels 0.5x(8.2-9.2)x(3.6-4.4), proud 0.15-0.4, yaw +/-3 degrees, 58,100,48 +/-6%; 2 crown caps 1.5x0.9x8; 3 sprigs (96,134,62); dark foot strip (34,44,30) | 15 | 9 |
| stone (half of stonehedge) | core 2.6x5 Slate 92,90,86, hedge core 2x5 on top | 30 facing stones in three courses a face (2.0, 1.6, 1.4 high; 2.4-4 long; proud 0.35 down to 0.15), Slate and Cobblestone greys 108-140, one in eight mossy 96,108,78; 8 upright coping stones 0.5x1.2x2.3 tilted 8-15 degrees; 10 hedge parts | 50 | 22 |

Stonehedge averages 33. Total about 10,900 on High, 5,200 on Low. Run ends and 32 gate frames (two 12-stud posts, lintel, quarter-coloured board) add 600. Cylinder vines and cobs go: Balls plus Cylinders fall from 1,962 to about 1,050.

## 5. LANDMARKS AND PROPS
Climb blocks, ladders, decks and returned tops keep their exact positions; only materials and dressing change.
- **Silo:** galvanised Metal, 24 vertical ribs, ladder cage hoops, rust streaks (CorrodedMetal 128,78,50), a shorter domed twin.
- **Lookout:** eight cross-braces, railed deck, four-wedge green tin roof, orange pennant.
- **Barn:** gambrel roof over the old flat one (kept as the collider), white trim and door leaves, battens every 2 studs, Brick plinth, dark windows, hoist beam.
- **Windmill:** three stacked drums (10, 9, 8 across) in Plaster 226,220,206 on a Cobblestone course, lattice sails of seven parts each, fantail, balcony rail.
- **Water tower:** braced legs, faded green tank (96,120,100) with hoops and rust.
- **Hay tower:** twine on every bale, mast stays, bunting in the quarter colours.
- **Orientation:** a tethered balloon 80 studs above each landmark in its quarter's colour (corn 212,170,60; pumpkin 204,108,36; orchard 150,48,44; windmill 200,208,214; centre gold). Landmarks hide behind 10-stud walls at close range; a balloon shows from nearly every corridor. Floor material, wall style and the diagonal shadows are three more cues.
- **Trees:** two crossed trunk blocks, three branches, five Balls, four leaf cards. 40 on the boundary, 24 standing in orchard and windmill hedge lines (no new collision). Far clumps: a trunk and two Balls.
- **Road cover** every 48 studs on alternate sides, leaving a 10-stud lane, never within 12 studs of a spawn or 10 of a gate: bale stacks, hay wagon, a blocky teal tractor (72,118,122), trough and pump, pallets. Three corners get a tractor shed, a bale yard and a sheep paddock.
- **Also new:** crossroads fingerpost, power poles along one road, beehives, apple ladders, pumpkin pyramids, verge tufts and flower specks.

## 6. FX
- **Wind:** `workspace.GlobalWind = Vector3.new(9,0,4)`, gusts of +/-30% every 8 s.
- **Dust motes:** four Box emitters (80x16x80) over the crossroads and road ends; Rate 15, Lifetime 6-10, Size 0.08-0.15.
- **Corn chaff:** one emitter, Rate 20, 240,220,160, `Drag=1.5`, `WindAffectsDrag=true`.
- **Mist:** two `smoke_main.dds` emitters at the pond and far lane, Rate 1.5, Size 18-30. Leaves on six orchard trees, Rate 1. Chimney smoke, Rate 3.
- **Barn:** six roof Beams (`Width0` 3, `Width1` 9, Transparency 0.92 to 1), one warm SpotLight with `Shadows=true` (Range 30), two plain PointLights.
- **Motion:** sails and far wind pumps tween; three two-part birds circle at y = 90.
- **Water** (pond only, 230 studs out): `WaterColor` 58,92,84, `WaterTransparency` 0.45, `WaterReflectance` 0.6, `WaterWaveSize` 0.05, `WaterWaveSpeed` 6.

## 7. BUDGET
| Category | High | Mid | Low |
|---|---|---|---|
| Maze walls | 10,900 | 8,200 | 5,200 |
| Run ends, gates | 600 | 600 | 350 |
| Landmarks, balloons | 650 | 650 | 450 |
| Maze props and road cover | 2,200 | 1,900 | 1,300 |
| Boundary hedgerow, near trees | 1,500 | 1,500 | 1,000 |
| Ground detail (tufts, flowers, 300 straws) | 2,200 | 0 | 0 |
| Vista | 1,400 | 1,400 | 700 |
| Gameplay (chests, perches, floor, bounds) | 150 | 150 | 150 |
| **Total** | **19,600** | **14,400** | **9,150** |

- Shadow-casting local lights: 1. Other lights: at most 12. Beams: 6. Steady particles: about 750. Twelve materials; no semi-transparent parts. Shadows only from wall cores, trunks, canopies, landmark bodies and bale stacks.
- **Tiers** (client): `SavedQualityLevel` 1-3 Low, 4-6 Mid, 7-10 High; Automatic starts High, or Mid on touch-only devices. A frame-rate watch during the countdown drops one tier below 28 fps, never raising it mid-round. Mid deletes `Detail.Fine` locally; Low also deletes `Detail.Dress` and half of `Detail.Vista`, and disables emitters, Beams, Bloom and SunRays.
- The server always builds High and parents gameplay parts first, then `Bulk`, `Vista`, `Dress`, `Fine`, yielding between. `Config.Round.loadCountdown` goes 3 to 5. If replication still hurts phones, `Fine` can later move to a seeded client-side builder.

## 8. MODULES
| File | Responsibility and signatures |
|---|---|
| `shared/ConfigLook.luau` (new, 150 lines) | presets, palette, terrain colours, sun target, wind, wall densities, tiers, `maxParts=25000`, `maxRound=1500`. Merged by `Config.Look = require(script.Parent.ConfigLook)`; `Config.Studs.on = false` |
| `shared/Maps.luau` | each row gains `look`; `lighting` is filled from the preset |
| `server/Look.luau` (new, 150) | `Look.init()`, `Look.apply(name, dim, dof)`, `Look.sun(elevation, offGrid) -> number?`, `Look.wind(base)` |
| `server/Landscape.luau` (new, 230) | `Landscape.build(ctx, half)`, `.paint(ctx, x0, z0, x1, z1, material)` (snaps to 4), `.maze(ctx, maze, spec)`, `.hills(ctx) -> boolean`, `.clear(centre)`, `.lobby(centre)` |
| `server/Dress.luau` (new, 110) | `Dress.part(ctx, tier, props)`, `.free(ctx, x, z, r)`, `.commit(ctx)` |
| `server/WallsFarm.luau` (new, 250) | `corn / vines / hedge / stone / stonehedge(ctx, a, b, height, T)`; `MazeWalls` delegates, so the other 15 maps inherit |
| `server/MazeKit.luau` (+8) | records `maze.runs`, `maze.links`, `maze.gates` |
| `server/Flora.luau` (new, 180) | `tree(ctx, x, z, kind, h)`, `clump`, `hedgerow(ctx, ax, az, bx, bz, gaps)`, `tufts` |
| `server/LandmarkDress.luau`, `BarnDress.luau` (new, 230 and 120) | one function per landmark; `balloon(ctx, x, z, colour, height)` |
| `server/FarmSet.luau`, `Vista.luau`, `FarmFx.luau` (new, 240, 220, 120) | new props and `FarmSet.cover(ctx)`; `Vista.build(ctx, half)`; `FarmFx.build(ctx)` |
| `server/MapsBig.luau` (170) | order: landscape, mazes, landmarks, spawns, dressing, commit |
| `server/RoundManager.luau` (-8) | `light()` becomes `Look.apply`; `clearTerrain` becomes `Landscape.clear` |
| `client/LookClient.luau` (new, 110) | `LookClient.start()`: tiers and pruning |

**dev/maprun/roblox.lua must learn:** `terrain.WriteVoxels`, `FillWedge`, `ReplaceMaterial` (no-ops); `Region3.new` with `ExpandToGrid`; `math.noise`; skipping `CanQuery=false` parts in `Raycast` and `GetPartBoundsInBox` with the part list cached (otherwise 20,000 parts make check_maps crawl). `check_maps.py` also fails bigfarm above 25,000 parts or 1,500 Balls plus Cylinders. `dev/luau.py` needs `UserSettings` in GLOBALS.

## 9. RISKS
- **Chests and spawns:** the invisible floor keeps every raycast; all dressing is `CanQuery=false`; nothing new collides inside maze cells; check_maps still demands 5 chests and 10 spawns.
- **Runtime throws:** `Decoration`, `GrassLength`, `LightingStyle`, `Technology` and `Use2022Materials` are never written from Luau; `Look.init` reads `LightingStyle` in `pcall` and warns.
- **Terrain:** every fill goes through the snapping `paint`; `WriteVoxels` has its fallback; no water inside 186 studs; no thin parts left on Grass for blades to poke through.
- **Sun model unverified:** the solver corrects it; the owner confirms once in Studio, with Realistic lighting and no Retro tone mapping.
- **Replication burst:** staged parenting, the longer countdown, pruning during it.
- **Shared tooling:** the build.py and luau.py edits are additive. Builder modules must avoid type annotations, `continue` and `for k, v in t do`, which luau2lua cannot convert.
- **Other maps:** inherited walls raise their part counts (the largest, corn, from 2,567 to about 3,900); check_maps prints them.
- **Unverified:** a two-property Terrain item, `Use2022MaterialsXml` and `SavedQualityLevel` (memory). If Studio drops the first two, the owner ticks Decoration and 2022 materials by hand; a failed quality read falls back to the frame-rate watch.
- **Particle textures** are `rbxasset://` and may be missing on a platform: every effect is optional and carries no gameplay.

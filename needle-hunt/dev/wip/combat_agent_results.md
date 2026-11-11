# research:movement

**Network:** WebFetch to create.roblox.com and devforum.roblox.com was refused (both hosts are outside this session's allowed network domains; allow them in the network settings to read the pages). I did not work around it. Every URL below was seen only as a web-search summary of that page, not the page itself. `/t/N` means `https://devforum.roblox.com/t/N`.

## FACTS
**Replication**
1. A client owns its character's physics: root CFrame and velocity flow client → server → others. Humanoid values set in a LocalScript (WalkSpeed, HipHeight, CameraOffset) never reach the server, but their physical result does. /t/4077247, /t/240523, /t/2423849. High.
2. A server write to a Humanoid property replicates only if the server-side value changes; setting 16 when the server already holds 16 sends nothing, so a client-local WalkSpeed sticks. /t/3735951. High.
3. Motor6D.Transform is not replicated; the Animator overwrites it every frame, even with no track playing. Write it in RunService.PreSimulation (Stepped), the last Luau event before Transform moves the parts. https://create.roblox.com/docs/performance-optimization/microprofiler/task-scheduler, /t/526807, /t/2444010. High.
4. C0/C1 are plain properties: the Animator leaves them alone, client edits stay local, server edits replicate to all but snap. /t/373730, /t/3160452. Medium.
5. Standard cross-client pose: replicate a small state (attribute or remote); each client poses that character locally. /t/3083557, /t/2156012. High.
6. Playing an un-uploaded KeyframeSequence (KeyframeSequenceProvider:RegisterKeyframeSequence) is unreliable outside Studio. /t/2222384. Medium.

**Crouch and collision**

7. R15 HipHeight is ground to the bottom of HumanoidRootPart, set per avatar (about 2 for a default blocky avatar; number unverified). R6 defaults to 0, measured at the leg bottoms; −2 or lower breaks movement. /t/265366, /t/1080338, /t/2832698. Medium.
8. The engine forces limbs CanCollide false and Head/torso true, re-applied on state change, so script toggles revert. HumanoidRootPart is left alone. /t/14497, /t/2709067. Medium.
9. A crouch animation alone does not reliably lower clearance. Lowering HipHeight does, but step-climbing gets worse and can bounce. Turning HumanoidRootPart collision off risks wall clipping. /t/4022530, /t/1649588. Medium.
10. The default camera follows HumanoidRootPart + about 1.5 studs + Humanoid.CameraOffset (root space), not the Head. /t/2402297, /t/513827. Medium.

**Physics**

11. The server cannot push a client-owned character: server ApplyImpulse and AssemblyLinearVelocity are ignored or unreliable, so the victim's client must apply knockback. Server CFrame teleports work (AntiCheat already uses one). /t/3186898, /t/3119602. High.
12. Per-frame AssemblyLinearVelocity writes fight the Humanoid's controller; a LinearVelocity constraint (Line/Plane, large MaxForce) on the root is the usual slide mover. /t/1945168, /t/4552190. Medium.
13. Only the network owner can change Humanoid state. /t/1131039. Medium.

**Server checks**

14. The server sees client-reported positions, late and in bursts; velocity is the client's claim. Consensus: windows of 0.5 s or more, generous margin, ignore Y, grace after server teleports, put back rather than kick. /t/280892, /t/2026856. Medium.

**Camera**

15. Player.CameraMode = Enum.CameraMode.LockFirstPerson (or CameraMinZoomDistance = CameraMaxZoomDistance = 0.5) forces first person; the server cannot verify it. https://create.roblox.com/docs/workspace/camera, /t/4533032. High.
16. Kick: RunService:BindToRenderStep after Enum.RenderPriority.Camera, multiply Camera.CFrame by a small rotation; ease one value, never start a tween per frame. /t/3904950, /t/109231. Medium. That the default camera rebuilds its CFrame each frame, so a kick never accumulates: unverified (memory), medium.

**Platform**

17. Server Authority (Workspace.AuthorityMode = Server) reached full release in 2026 and is opt-in. It forces StreamingEnabled, deferred signals, fixed simulation and NextGenerationReplication, and rolls back client-side movement. /t/4727993, https://create.roblox.com/docs/projects/server-authority. Medium.

## RECOMMENDED PATTERNS
- **A. Stance.** Client fires Remotes.Stance("crouch"|"slide"|"stand"). Server rate-limits, checks alive, sets character attribute `Stance`, and stays the only WalkSpeed writer (fold a 0.5 crouch factor into Streaks.walkSpeed so Powerups/RoundManager comparisons hold). The client changes body and camera at once.
- **B. Crouch (owner's client).**
  - Read `stand = humanoid.HipHeight` while standing; ease to `stand − drop` over 0.15 s.
  - R15: crouch drop = min(1.2, stand − 0.8); slide drop = min(1.6, stand − 0.4). R6: HipHeight −1.0, never below −1.5.
  - The camera drops by itself (facts 7, 10); add Humanoid.CameraOffset (0, −0.4, 0) only as a slide dip.
  - Before standing: `workspace:Spherecast(root.Position, 0.9, Vector3.yAxis * (drop + 1.7), paramsExcludingCharacter)`; a hit means stay down.
- **C. Pose (every client, every character whose Stance is not stand).**
  - In RunService.PreSimulation: `motor.Transform = motor.Transform * offset`, weight eased over 0.12 s; write CFrame.identity when done.
  - R15 Motor6Ds (each inside its Part1): Root (LowerTorso), Waist (UpperTorso), Neck (Head), Left/RightShoulder, Left/RightElbow, Left/RightWrist, Left/RightHip, Left/RightKnee, Left/RightAnkle.
  - Crouch angles: φ = acos(1 − drop/stand); Hip +φ, Knee −2φ, Ankle +φ about X; Waist −15° (signs derived, unverified).
  - R6: HumanoidRootPart.RootJoint; Torso "Neck", "Left Shoulder", "Right Shoulder", "Left Hip", "Right Hip". Their C0/C1 are rotated, so skip R6 leg posing.
- **D. Slide (owner's client).**
  - Reuse DashFx's mover exactly: LinearVelocity, Plane mode, world X/Z tangents, MaxForce 1e6.
  - Set PlaneVelocity each frame from 30 down to 14 studs/s over 0.6 s (about 13 studs), direction fixed at start.
  - Start only when humanoid.FloorMaterial ~= Enum.Material.Air and horizontal speed ≥ 0.85 × WalkSpeed.
  - End on jump, 0.25 s airborne, or measured speed under half the commanded speed for 0.1 s (a wall).
  - One mover at a time: dash, slide and knockback destroy each other's.
- **E. Knockback.** Server decides and adds `push` (horizontal unit × 28 studs/s for 0.14 s, about 4 studs) to Remotes.Hit; only the victim's client builds the same mover. Dummies are welded, server-moved models, so the server tweens them.
- **F. Speed and reach.** 30 and 28 stay under Config.AntiCheat.maxSpeed 70; leave it. For reach checks keep about 0.5 s of root positions per player and accept a hit that was in reach at any recent sample.
- **G. Camera.**
  - Kick at Enum.RenderPriority.Camera.Value + 1 and move ViewModel to + 2; at most 1.5° pitch, gone in 0.18 s, off under reduceEffects; read aim before the kick.
  - One FieldOfView owner: target = Aim.fov() + active deltas (slide +6, dash +8), eased per frame.

## CAVEATS
- Joint rotation signs and R6 axes cannot be checked here: put per-joint degrees in ConfigMoves so the owner can flip them in Studio.
- "Fit under things" is the riskiest promise. Default R15 is about 5.3 studs tall (R6 5.0), crouched about 4.1, sliding 3.7 (unverified). Avatars vary in height, so a gap that blocks standing but admits crouching has under 1 stud of margin unless avatar scale is normalised.
- Lower HipHeight means lower step-up: crouch-walking stalls on steps taller than roughly the crouched HipHeight (0.8), and slides stop at stairs.
- Automatic scaling can rewrite HipHeight on respawn or appearance load: re-read `stand` at every crouch and reset on CharacterAdded.
- ViewModel and Aim detect first person as camera-to-Head under 1.5 studs: keep CameraOffset plus any local head pose shift under 1 stud.
- DashFx restores FieldOfView with task.delay, which will fight a slide tween unless FOV has one owner.
- AntiCheat measures 3D speed: a fall of roughly 35 studs already exceeds 70, and sliding off a ledge makes that likelier.
- A cheating client can ignore knockback and crouch speed: never tie hearts to them.
- Do not enable AuthorityMode Server or Workspace.ImprovedPhysicsReplication (open character-mismatch report, /t/4734415).


# research:combat

**Network:** `create.roblox.com` and `devforum.roblox.com` are outside this session's allowed domains (fetch refused, not worked around; they need allowing in the network settings). Facts citing them come from search summaries only. Two primary sources were read directly from GitHub (`MaximumADHD/Roblox-Client-Tracker`, branch `roblox`, client v0.747.0.7471481): the install's file list [manifest] and the engine API dump [API].

## FACTS

**Sound**
- The install ships exactly 11 sounds: `rbxasset://sounds/` + `action_falling.ogg`, `action_footsteps_plastic.mp3`, `action_get_up.mp3`, `action_jump.mp3`, `action_jump_land.mp3`, `action_swim.mp3`, `impact_explosion_03.mp3`, `impact_water.mp3`, `oof.ogg`, `ouch.ogg`, `volume_slider.ogg`. [manifest] High (Studio build; the player build is assumed to match).
- Of the task's candidates only `action_footsteps_plastic.mp3`, `action_jump.mp3` and `impact_water.mp3` exist. Missing: `swordslash.wav`, `swordlunge.wav`, `unsheath.wav`, `hit.wav`, `snap.mp3`, `switch.mp3`, `electronicpingshort.wav`, `clickfast.wav`, `bass.wav`, `uuhhh.mp3`; also `button.wav`, `swoosh.wav`. [manifest]; a forum thread shows `swoosh.wav` failing to load (https://devforum.roblox.com/t/custom-jump-sound-not-working/1439389). High.
- So all four of needle-hunt's `Config.Sounds` (found, click, whoosh, countdown) name missing files and probably play nothing today. Medium (untested).
- What they sound like, unverified (memory), medium: jump = short soft whoosh; jump_land = low thud; get_up = cloth scuffle; footsteps_plastic = looping steps; falling = looping wind; swim = looping swish; impact_water = splash; explosion_03 = loud boom; oof = the classic "oof"; ouch = short grunt; volume_slider = tiny tick.
- `Sound.PlaybackSpeed` (not replicated: set it on the client) and `PlaybackRegionsEnabled`/`PlaybackRegion` exist. [API] High. Pitch-shifting (about 0.6 to 2.0) is a reasonable way to get distinct impacts; it also changes length.

**Hit detection and timing**
- `WorldRoot:Spherecast(position, radius, direction, params)`, `:Blockcast(cframe, size, direction, params)`, `:GetPartBoundsInBox(cframe, size, overlapParams)`, `:GetPartBoundsInRadius(position, radius, overlapParams)` exist as written. [API] High.
- Shape casts miss parts already overlapping the start shape. https://create.roblox.com/docs/reference/engine/classes/WorldRoot Medium.
- `Player:GetNetworkPing()` returns seconds; refreshed only every few seconds, possibly one-way, 0 in Studio. https://devforum.roblox.com/t/playergetnetworkping-lacks-documentation/1544599 Medium.
- `workspace:GetServerTimeNow()` is the synced, monotonic client/server clock. https://devforum.roblox.com/t/workspacegetservertimenow-documentation-incorrect-and-datetimenow-needs-more-information/1909687 High.
- Server-side impulses on a player's character do nothing: the client owns it. https://devforum.roblox.com/t/applyimpulse-doesnt-work-on-the-server-for-player-characters/3186898 Medium-high.
- `UnreliableRemoteEvent`: unordered, never resent, payloads over 900 bytes dropped. https://create.roblox.com/docs/reference/engine/classes/UnreliableRemoteEvent High.
- `RemoteEvent` has no documented per-second cap. https://devforum.roblox.com/t/does-remoteevent-have-limits/2891323 Low.

**Input and haptics**
- `ContextActionService:BindAction(name, fn, createTouchButton, ...inputs)`, `BindActionAtPriority`, `SetPosition`, `SetTitle`, `SetImage`, `GetButton` (yields) exist and are not deprecated; states are `Begin/Change/End/Cancel`. [API] High.
- `Enum.KeyCode.ButtonA/B/X/Y`, `ButtonL1/R1/L2/R2/L3/R3`, `DPadUp/Down/Left/Right`; `Enum.UserInputType.MouseButton1/2/3`, `Touch`. [API] High.
- `HapticEffect` (`Type` = `Enum.HapticEffectType.GameplayCollision`, `GameplayExplosion`, `UIClick`, `Custom`; `:Play()`, `:Stop()`, `.Ended`) is live; `HapticService:SetMotor` still exists. [API]; https://devforum.roblox.com/t/full-release-you-can-now-publish-haptic-effects-in-your-experience/3660577 High (device coverage: low).

**Visual limits**
- The Highlight cap is 255 instances (31 until Nov 2025); disabled ones still count; extras are silently ignored. https://devforum.roblox.com/t/lights-camera-more-highlights/4061534 High. Low-end phones draw a fill-only fallback. https://devforum.roblox.com/t/highlights-do-not-show-on-mobile-devices/2083168 Medium.
- No BillboardGui count cap is known. Unverified (memory), medium.
- Built-in textures present: `rbxasset://textures/particles/sparkles_main.dds`, `smoke_main.dds`, `fire_sparks_main.dds`; `rbxasset://textures/loading/loadingvignette.png`. [manifest] High (Studio build).

## RECOMMENDED PATTERNS
1. **Position history for player hits.** The server records each in-round `HumanoidRootPart.Position` every `Heartbeat` in a 1 s ring buffer. A hit counts if the target was inside the hit shape at any sample in the last `W = math.clamp(2 * attacker:GetNetworkPing() + 0.1, 0.1, 0.35)` seconds. Do the geometry as pure math (point-to-segment distance; player = upright capsule, radius 2, half-height 3) in a shared module that `test_rules.py` can cover, then one `workspace:Raycast` for walls (today's poke has no wall check).
2. **Poke:** the client still names the target; the server accepts `distance <= reach + lunge + 2` at any sample in W and `dot >= 0` (its view of facing lags). The attacker's own client moves the lunge, like the dash: about 40 studs/s for 0.12 s, under `AntiCheat.maxSpeed` 70.
3. **Throw:** step it on the server each `Heartbeat` instead of deciding at release, so dodges count. Radius 0.4 against walls, 2.0-2.5 against players.
4. **Exploit bounds:** type- and NaN-check every argument; never accept client positions, durations or timestamps (time charges and blocks from server receipt, 0.1 s grace); cap rewind at 0.35 s; a per-player limiter on each remote; server cooldown = configured minus 0.1 s, so jitter doesn't drop honest pokes.
5. **Knockback:** the server sends the vector and the victim's client applies it (18-25 studs/s for 0.15 s; 30 for a heavy hit). Cosmetic only, since an exploiter can ignore it. Dummies: tween on the server.
6. **Feel (client only, cut down under `reduceEffects`):** hit-stop = freeze the view-model animation 0.05-0.08 s; camera kick 2 degrees (attacker) or 3-4 (victim), sprung back in 0.2 s in `BindToRenderStep` after the camera; FOV -2 for 0.05 s, back in 0.2 s; hit marker = four rotated Frames for 0.25 s, gold on a tag-out; one local Highlight ease-out per hit (`FillTransparency` 0.35 to 1 over 0.2 s, `DepthMode.Occluded`); `ParticleEmitter:Emit(10)`; vignette = edge Frames with `UIGradient`, opacity at most 0.35.
7. **Sounds (picked by description, not by ear):** swing `action_jump.mp3` at 1.7; hit `action_jump_land.mp3` at 1.5 plus `volume_slider.ogg` at 1.4; heavy hit `action_jump_land.mp3` at 0.7; block `volume_slider.ogg` at 2.0; catch `action_get_up.mp3` at 1.5; slide `action_footsteps_plastic.mp3` at 0.5; vary each by 6%.
8. **Input:** keep the game's own on-screen buttons (`createTouchButton = false`). Hold-to-charge: `Tool.Activated`/`Tool.Deactivated` or CAS `Begin`/`End`, treating `Cancel` as abort; fire the light poke on press, not release.

## CAVEATS
- Gamepad defaults, unverified (memory): `ButtonR2` activates the tool (pokes), `ButtonA` jumps, `ButtonL1/R1` cycle backpack tools (the backpack is on), `ButtonR3` toggles zoom, and `ButtonX` is the chest prompt's button as well as Throw. Only `ButtonL2` and `ButtonL3` look free.
- The right mouse button turns the camera when zoomed out, and the game allows zoom: not a safe block key.
- One owner for `Camera.FieldOfView`: the dash already tweens it, and a second tween will fight it.
- `DepthMode.AlwaysOnTop` on a hit flash shows players through walls.
- Today's throw starts its `Spherecast` (radius 1.2) 1.5 studs ahead of the head: thrown while pressed against a wall, it can skip that wall. Test the origin with `GetPartBoundsInRadius` first.
- The default death sound already plays on a tag-out. Haptics: wrap in `pcall`, never rely on them.
- Roblox's own classic sword sound IDs (12222216, 12222208, 12222225) may still work, but they are asset IDs: unverified, and outside the brief unless the owner agrees.


# design:net

# Combat and movement overhaul: fairness and netcode first

Design only: nothing was edited, built or committed.

## 1. GOALS
A hit that looks like it landed on your screen lands, at 150 ms ping and on a phone, because the server rewinds to where your target was on your screen. Every move has a visible tell and a clear answer, and no route tags out a full-health player faster than today's 1.4 s. Crouch, slide and lunge respond at once because your own device moves you, while the server alone owns hearts, cooldowns, stances and walking speed.

## 2. MOVESET
The server times everything from when it receives the remote.

| Move | Keyboard / pad / touch | Timing (s) | Hearts, range | Movement |
|---|---|---|---|---|
| Poke | Click / R2 / tap | wind-up 0.10, one check; cooldown 0.7 | 1; reach 8 | lunge 40 studs/s, up to 0.12 |
| One-two | poke again within 1.2 of a landed poke | cooldown 0.5 after the first hit, 0.9 after the second | 1 | bigger knockback; chain resets |
| Charged stab | hold Click / hold R2 / hold "Heavy" | charge 0.8 from the end of the poke cooldown; fizzles 1.5 after ready; wind-up 0.14; cooldown 1.0 | 2 (1 through a guard, which it breaks) | walk x0.7 charging; lunge 46 for 0.14 |
| Guard | hold R / hold L2 / hold "Guard" | raise 0.12, up at most 1.5, cooldown 1.2 (2.5 broken) | blocks pokes and throws from the front half; the poker's cooldown becomes 1.1 | walk x0.5; no poke or throw |
| Throw | Q / X / "Throw" | 90 studs/s, sticks 0.3, returns in 0.5; cooldown 4 | 2; range 45 | none |
| Catch | Q again / X / "Catch" | 0.20 before `returnAt` to 0.15 after (+ping, at most 0.15); one try | none | cooldown -1.0; a miss costs 0.25 more empty-handed |
| Dash | C / B / "Dash" | unchanged: 55 for 0.22, cooldown 3 | none | cancels a charge or guard |
| Crouch, slide | Left Ctrl (hold) / L3 (toggle) / "Crouch" (toggle) | section 3 | none | section 3 |

Three hearts take three pokes (landing at 0.1, 0.6 and 1.5 s) or a poke then a charged stab (1.44 s): never faster than today's 1.4.

What beats what: guard beats poke and throw; a charged stab beats guard; any hit cancels a charge; dash and slide dodge a charged stab or a throw; a hit from behind beats guard. A blocked hit still interrupts a chest hold.

The server keeps one attack state per player (idle, poke wind-up, charging, heavy wind-up, guarding); starting one ends the others, and a respawn clears them. `Guarding` and `Charging` are character attributes, so everyone sees the tell.

## 3. CROUCH AND SLIDE
**Server state:** the character attribute `Stance` (nil, "crouch", "slide"), changed only through `Remotes.Stance:FireServer("crouch" | "slide" | "stand")`.
- To crouch: alive and not frozen.
- To slide: also 1.5 s since the last slide, and the server's own position history shows at least 0.6 x walking speed over the last 0.25 s; otherwise it becomes a crouch.
- A slide ends as a crouch on the server's timer at 0.85 s, whatever the client says. Standing: on request, respawn, freeze or tag-out.

**Speed.** New `server/Speed.luau` is the only WalkSpeed writer: 16 x the larger of `SpeedMult` (Marked) and Hay Boots, x the smallest of crouch 0.5, guard 0.5, charge 0.7. Powerups, Streaks, RoundManager.freeze and Practice.hold call it instead of comparing WalkSpeed values (Powerups ends Hay Boots only if WalkSpeed still equals the boosted value, so a crouch would leave it stuck). The client predicts with the same formula.

**Slide** (own client, the dash's LinearVelocity mover): only on the ground at 0.85 x WalkSpeed or more; from WalkSpeed + 14 down to 0.875 x WalkSpeed over 0.6 s (about 13 studs), direction fixed; ends on jump, 0.25 s airborne, or a wall. Dash, slide, lunge and knockback share one mover and replace each other.

**Body and camera** (own client): HipHeight eases over 0.15 s by min(1.2, stand - 0.8) crouching, min(1.6, stand - 0.4) sliding (R6: -1.0), and the camera follows the root; a slide adds `Humanoid.CameraOffset` (0, -0.4, 0) and field of view +5. Standing needs a clear `workspace:Spherecast(root.Position, 0.9, Vector3.yAxis * (drop + 1.7), params)`.

**Others see** `client/Poses.luau` bend hips, knees and ankles in `RunService.PreSimulation` (degrees in ConfigMoves). Quiet: while crouched the server sets `Humanoid.NameDisplayDistance` to 12 and each client mutes that character's `Running` sound.

**Hitbox.** Throws test the same capsule for every avatar: radius 2.0, from 2.5 below the root to 2.3 above (crouch 1.7, slide 1.3). Pokes ignore stance.

**AntiCheat** keeps the 70 studs/s cap and adds a horizontal budget: over the last 2 s, distance may not exceed server WalkSpeed x time x 1.25 + 5 studs + credits. Only the server grants credits (`AntiCheat.credit`): dash 13, slide 5, lunge 5, knockback 6. Two failures in a row put the player back. That catches a sustained 1.45x speed cheat; today's cap only catches 4.4x.

## 4. HIT REGISTRATION
**History.** `server/Rewind.luau` records each character's root position, facing and stance every Heartbeat (64 samples), and moving dummies; `AntiCheat.allow` clears it. The window is `W = math.clamp(2 * attacker:GetNetworkPing() + 0.1, 0.1, 0.35)`: the attacker saw the server's picture one round trip plus interpolation ago.

**Poke.** The client sends only `Remotes.Poke:FireServer(target)`: a UserId, a dummy id or nil. At receipt + 0.10 s the server accepts if, for some attacker sample since receipt and some target sample within W before it:
- flat distance is at most 8 + 1.5 and height difference at most 6;
- the attacker faced the target (dot 0.2 or more) at any sample in the last 0.25 s;
- one `workspace:Raycast` to that sample (`RespectCanCollide`, characters excluded) hits no wall. Today's poke goes through walls.

Alive, safe time, needle in hand and guard are judged at the server's present, never rewound.

**Lunge and aim assist** (client only). The target is whoever is nearest the crosshair within 11 studs, in line of sight, inside 16 degrees (mouse), 24 (pad) or 28 (touch). The body lunges only at a named target 5 to 11 studs away and stops 4.5 short; the camera is never turned. An honest poke from 11 studs lands even if the server saw half the lunge (8.6 studs); a cheater who skips the lunge gains 0.5 stud over today.

**Throw.** The client sends the aim direction, as now. The server starts at the head (`GetPartBoundsInRadius` first, so no throw begins inside a wall) and steps the needle each Heartbeat: `workspace:Spherecast(prev, 0.4, step, mapOnly)` for walls, the capsule test against each target's samples within W, then one Raycast to the sample. A dodge after release now counts. `Remotes.Thrown` carries `{ id, from, key, origin, dir, t0 }`, `Remotes.ThrowEnd` `{ id, at, hit, returnAt }`; the thrower's client draws its own flight at once.

**Guard** counts if it reached the server 0.12 s before the hit resolves and the defender faced the attacker (dot 0 or more) in the last 0.25 s.

**Limits.** Every remote passes `RateLimit.allow` (per second: Poke 4, Charge 4, Guard 6, Stance 6, Throw 2, Catch 2, Dash 2, Inspect 1); extra calls are dropped, never kicked. Types and NaN are checked. Cooldowns use `if now >= ready - 0.1 then ready = math.max(ready, now) + cooldown`: jitter is forgiven, the long-run rate cannot rise. No client position, duration or timestamp is accepted.

## 5. FEEDBACK
Sounds are verified built-ins (`rbxasset://sounds/`) at the playback speed given. Kicks and field-of-view changes are off under `reduceEffects`; nothing flashes.

- **Swing.** View model `stab`: at 0.04 draw back `{ 0.06, 0.02, 0.22, 8, 0, 0 }`, at 0.10 thrust `{ -0.12, 0.14, -0.9, -10, 0, -6 }`, at 0.32 home. Third person: today's Grip tween plus a shoulder thrust. `action_jump.mp3` at 1.7.
- **Hit dealt.** Four-bar hit marker for 0.22 s (orange for a charged stab, gold for a tag-out); view model frozen 0.06 s; camera kick 1.2 degrees, back in 0.18 s; `action_jump_land.mp3` at 1.5 with `volume_slider.ogg` at 1.4; `Emit(10)` straw sparkles; one Highlight on the target easing 0.35 to 1 in 0.2 s, `DepthMode.Occluded`.
- **Hit taken.** Today's red edge plus a soft wedge on the side it came from; view model `flinch`; kick 2.5 degrees; `HapticEffect` in a pcall; every client leans the victim's waist 12 degrees for 0.2 s. Knockback: the server adds `push` to `Remotes.Hit` and the victim's client applies it (poke 22 studs/s for 0.14 s; one-two, charged stab and throw 30 for 0.16).
- **Blocked.** A grey "BLOCKED", eight white sparkles, `volume_slider.ogg` at 2.0; the defender plays `guardHit`; the attacker is pushed back 18 for 0.12 s.
- **Charged.** View model `charge` (right arm back, left hand up), field of view -3; when ready, a tip glint eases in with `volume_slider.ogg` at 1.2. Others see the arm back and the glint.
- **Tag-out.** Gold marker, `action_jump_land.mp3` at 0.7, a straw burst; the feed says poke, heavy or throw. Catch: `action_get_up.mp3` at 1.5. Slide: `action_footsteps_plastic.mp3` at 0.5.

## 6. MODULES
**Shared (new):** `ConfigMoves.luau` (tables Stance, Slide, Poke, Heavy, Combo, Guard, Catch, Knockback, HitReg, SpeedCheck, Feel, MoveSounds, Pose; Config.luau merges it); `HitMath.luau` (`segmentCapsule(p0, p1, base, top, radius)`, `window(ping)`, `walkSpeed(mult, boots, stance, guarding, charging)`); `FirstPersonMoves.luau` (stab, stab2, charge, heavy, guard, guardHit, catch, flinch).

**Server (new):** `Rewind.luau` (`track(key, part)`, `samples(key, since)`, `speed(player, seconds)`, `forget(player)`); `HitCheck.luau` (`poke(attacker, key, since)`, `sweep(attacker, p0, p1)`); `CombatMoves.luau` (wind-up, one-two, charge; owns `Remotes.Poke` and `Remotes.Charge`); `Guard.luau` (`resolve(attacker, target, amount, kind) -> amount, blocked, broken`); `Stance.luau`; `Speed.luau` (`refresh(player)`, `boost(player, speed, seconds)`, `freeze(player, on)`); `RateLimit.luau` (`allow(player, name, perSecond, burst)`); `PracticeMoves.luau` (a guarding dummy that only a charged stab or a hit from behind hurts, a gate to slide under, dummies that rock when hit).

**Server (changed):** Combat (poke moves out; `damage(attacker, target, amount, kind)` calls Guard, cancels a charge, and adds `kind, blocked, broken, combo, push` to `Remotes.Hit`); CombatThrow (stepped flight, catch); AntiCheat; Dash; Powerups, Streaks, RoundManager, Practice (Speed calls; each gets shorter). ChestSpawner (294 lines) is untouched.

**Client (new):** `Mover.luau` (`push(kind, direction, speedAt, seconds)`); `CamFx.luau` (the only FieldOfView writer: `fov(key, delta)`, `kick(pitch, yaw)` at Camera + 1; ViewModel moves to + 2); `StanceFx.luau`; `Poses.luau`; `HitFx.luau`; `MovesFx.luau` (charge, guard, catch: input, buttons, a GUARD bar). **Changed:** CombatFx, ThrowFx, DashFx, Effects, ViewModel (merges FirstPersonMoves, the owner's rig winning a clash; `hold(name)`, `freeze(seconds)`), KeyHints (four new rows; on a pad the buttons show pad names), CooldownBars, UIController.

**New RemoteEvents:** `Stance`, `Guard`, `Charge`, `Catch`, `ThrowEnd`.

**Tests:** no route to three hearts beats 2 x Combat.cooldown; reach + pad is at most 10 and W at most 0.35; the worst honest 2 s fits the budget and 1.45x walking fails it; guard's maximum is under Chests.hold; every new remote's handler calls RateLimit.allow; every sound named is one of the eleven that exist; FirstPerson.luau gains no animation. Two existing assertions move with the code (Aim.fov in DashFx, C.cooldown in Combat).

## 7. RISKS
- **Favouring the attacker.** A 250 ms attacker can hit a walking target up to 5.6 studs behind where they now are. W's cap is one number; lower it if "hit behind cover" complaints outweigh "my hits don't land". `GetNetworkPing` may be one-way and slow to update; the 0.1 floor covers that.
- **Guard at high ping.** An attacker can be blocked by a guard not yet on their screen, by at most their one-way delay; the 0.12 s raise absorbs most of it.
- **The tighter AntiCheat could rubber-band honest players** on bad connections. Ship it logging only and enforce once the logs are clean; the 70 cap stays live.
- **Crouch clearance.** Avatar heights differ and the map is being rebuilt elsewhere: promise only gaps of 4.5 studs or more. Crouch-walking stalls on steps over about 0.8 studs.
- **Needs Studio to confirm:** joint rotation signs, R6 leg posing (skipped), the `Running` sound name, whether L2 and L3 are free, and whether `Tool.Activated` fires on touch-down. Touch therefore gets its own Heavy and Guard buttons, and the server's time limits end a stuck hold.
- **Sounds were picked by description, not by ear.** Separately, `Config.Sounds` today names four files that don't exist, so the game is probably silent.
- **Exploits left:** an aim cheat (reach, line of sight and rate still hold), ignoring knockback or crouch speed (never tied to hearts), a perfect catch macro (worth 1 s of cooldown).
- **Owner's call:** a 1 of 1's throw tags out in one hit and can come from a box Robux opens, which sits badly with "every needle fights the same". Guard now blocks it.
- **Time Trial board.** New dummies and moves change clear times; a new store name keeps it fair.

Workflow note: the scratchpad is shared, and another agent and I briefly both wrote `design.md` there; I moved my draft and left theirs alone.


# design:feel

# Combat and movement overhaul: feel-first design

Design only: nothing edited, committed or pushed. Paths are under `/home/user/screener3/needle-hunt/src/`.

## 1. GOALS
A press answers within a frame: the arm thrusts, you lunge, and contact lands as a tiny freeze, a kick and a thud before the server's marker confirms it. Every move shows itself coming and has an answer, so a fight reads as a rhythm, not a click race. Movement flows (dash into a slide, duck a throw, come up poking) and nothing ever flashes.

## 2. MOVESET
| Move | Keys / gamepad / touch | Timing | Hearts | Range and movement |
|---|---|---|---|---|
| Poke combo 1-2-3 | click (on press) / R2 / Poke button or tap | Decided on server receipt. Next poke after 0.55 s, 0.55 s, then 0.9 s after the third (finisher). Chain resets after 1.1 s idle | 1 each | Reach 8. A target within 12 studs in the aim cone pulls a lunge: 44 studs/s for up to 0.11 s, stopping 3.5 studs short. No target, no lunge (nobody lunges off a perch) |
| Big Stab | keep holding the same button | Charge starts 0.2 s into the hold, full 0.6 s later, auto-fires at 1.5 s. Early release cancels. Recovery 1.0 s | 2 | Lunge range 15: 52 studs/s for 0.15 s. Walk x0.75 while charging. Any hit taken cancels it |
| Guard | R / L2 / Guard | Up 0.4 s, then 0.3 s recovery; cooldown 1.8 s (0.6 s, no recovery, after a parry) | 0 | Stops pokes and throws from your front half. A parried poker is Staggered 0.9 s: no attack or guard, combo reset. Walk x0.6 |
| Throw | Q / X / Throw | Speed 110 (was 90); away 1.2 s; cooldown 4 s | 2 | 45 studs |
| Clean Catch | Throw again as it returns | One try a throw, from 0.3 s before the return to 0.1 s after | - | Cooldown 4 to 2.5 s; needle in hand at once |
| Dash | C / B / Dash | Unchanged: 55 for 0.22 s, cooldown 3 s | - | May chain into a slide |
| Crouch | LeftControl or V (a toggle, so Ctrl is never held during a click) / L3 / Crouch | 0.14 s down | - | Walk x0.5; footsteps off; name tag hidden beyond 18 studs |
| Slide | crouch button while running on the ground | 0.65 s; cooldown 1.2 s | - | Section 3 |

Inspect is unchanged. Jump stands you up from a crouch and ends a slide.

**What beats what.** Poke beats Big Stab (cancels the charge). Guard beats Poke and Throw and earns a free riposte. Big Stab goes through Guard. Dash and slide escape Big Stab; a slide ducks a head-height throw. Fastest tag-out from full hearts: 1.1 s by combo (1.4 s today), or 0.8 s by poke into Big Stab, which shows for 0.6 s and loses to one poke.

## 3. CROUCH AND SLIDE
- **States**: character attribute `Stance` (nil, `"crouch"`, `"slide"`), set by the server, predicted by the client.
- **Crouch**: the button while slow or airborne. Standing needs headroom: `workspace:Spherecast(root.Position, 0.9, Vector3.yAxis * (drop + 1.7), params)`; a hit keeps you down.
- **Slide**: the button with `humanoid.FloorMaterial ~= Enum.Material.Air` and flat speed >= 0.85 x WalkSpeed. Ends after 0.65 s, on jump, after 0.25 s airborne, or at a wall. You come out standing if a move key is held and there is headroom, otherwise crouched.
- **Body** (your own client): R15 `humanoid.HipHeight` drops by `min(1.2, stand - 0.8)` for a crouch and `min(1.6, stand - 0.4)` for a slide, eased over 0.14 s. R6: -1.0.
- **Slide curve**: `v0 = clamp(1.6 x flat speed, 28, 44)`, falling linearly to half: 13.7 studs from a walk, 20 with Hay Boots, 21 from a dash. Direction fixed at the start. One `client/Mover` owns the dash's LinearVelocity: dash, slide, lunge and knockback replace each other.
- **Camera**: drops with HipHeight by itself. A slide adds `Humanoid.CameraOffset` (0, -0.35, 0), 3.5 degrees of roll and +6 FOV, in over 0.12 s, out over 0.3 s. Your own character gets no head or waist pose, so first-person detection (camera within 1.5 studs of the Head) holds.
- **Hitbox**: pokes unchanged. Throws test a capsule from `root - 2` to `root + 1.5`, radius 2.0; a server-approved slide cuts the top to `root + 0.6`, so a throw at standing head height passes over and a chest-height one hits.
- **Others see** `client/Poser` bend the legs (Hip +phi, Knee -2 phi, Ankle +phi, `phi = acos(1 - drop / stand)`; Waist -15 degrees), a slide lean, and straw dust (`rbxasset://textures/particles/smoke_main.dds`).
- **Speed**: new `server/Speed` is the only WalkSpeed writer: 0 if frozen, else `max(16 x SpeedMult, boots) x stance x act`. Crouched with Hay Boots is 13, Marked 12. The client predicts from character attribute `BaseWalk`.
- **AntiCheat**: untouched. The worst 0.5 s window (dash, then a capped slide) is 23 studs: 46 studs/s against the limit of 70.

## 4. HIT REGISTRATION
**The client sends** `Remotes.Poke:FireServer(target, aim, heavy)` (UserId, dummy id or nil; the camera's unit look; boolean), `Charge(on)`, `Guard()`, `Throw(aim)`, `Catch()`, `Stance(stance)`. Never a position, a duration or a time.

**Aim assist (client).** The poke target is the player in line of sight within 12 studs (15 heavy) nearest the camera look: at most 30 degrees off beyond 4 studs, 60 inside. On gamepad and touch a throw's aim bends up to 6 degrees onto a visible target; mouse throws get none.

**Server poke checks, in order:**
1. Aim is a finite Vector3 of length 0.9 to 1.1; at most 8 requests a second.
2. Needle in hand, not Staggered, cooldown minus 0.1 s for jitter.
3. Heavy only if `os.clock() - chargeStart >= 0.5`, counted from the server's receipt of `Charge(true)`.
4. Rewind: `W = math.clamp(2 * attacker:GetNetworkPing() + 0.1, 0.1, 0.35)`. Pass if any target sample in W (`server/History`: a 1 s ring of root positions, one per Heartbeat) lies within `range + margin` flat and 7 studs vertically of the attacker now; `margin = 2 + min(4, 0.1 x attacker's measured flat speed)`. Worst case accepted: 18 studs (21 heavy).
5. Facing: the server's own root look against the flat direction >= 0 (skipped under 2 studs); aim against the direction >= 0.6 (skipped under 4).
6. One `workspace:Raycast` to that sample, excluding characters: a wall rejects. Today's poke has no wall check.
7. `Guard.blocks`, then `Combat.damage`.

**Throw.** The server steps it every Heartbeat. Origin `head + dir * 1.5`, or the head itself if `workspace:GetPartBoundsInRadius(origin, 0.4)` finds a wall. The first step is advanced by `110 * min(ping, 0.1)`. Each step: `workspace:Spherecast` radius 0.4 for the world, capsule math for players where they are now, so dodges count.

**Guard, charge and catch** are timed from server receipt with 0.1 s grace. A slide needs a server-measured flat speed >= 0.7 x WalkSpeed and ends by itself after 0.85 s.

## 5. FEEDBACK
First-person keys are right-arm offsets from the hold pose (x, y, z, rx), in new `shared/FirstPersonMoves.luau`. Contact is predicted on your screen; the marker waits for `Remotes.Hit`. Sounds are `Config.Sfx` rows, pitch varied 6%.

| Event | First person | Third person | Camera and UI | Sound | World |
|---|---|---|---|---|---|
| Swing | `jab1` 0.34 s: pull at 0.04 (0.04, -0.03, 0.10, 6), thrust at 0.10 (-0.12, 0.14, -0.75, -10), settle at 0.16. `jab2` crosses inward. `jab3` 0.48 s: wind-up at 0.07, thrust at 0.14 (-0.16, 0.20, -0.95, -16) | Waist -18 degrees, right shoulder +25, elbow +30; 0.07 s in, 0.2 s out. The server's Grip jab stays | 0.5 degree yaw; three combo pips under the reticle | `action_jump.mp3` at 1.7, 1.85, 1.45 | - |
| Charging | Layer: arm drawn back (0.14, 0.10, 0.34, 22), a growing tremor | Waist +25, shoulder -35, elbow -60 | A ring round the reticle fills, gold when full | `volume_slider.ogg` at 1.8 when full | 6 sparkles at the tip (`sparkles_main.dds`) |
| Hit dealt | Hit-stop: the view-model clock freezes 0.05 s (0.08 s for a stab or tag-out) | Victim rocks back (Waist -14, Neck -10; 0.07 s in, 0.25 s out). One local Highlight eased from 0.5 to 1 in 0.2 s, `DepthMode.Occluded` | Kick 1.2 degrees (2.2 stab), gone in 0.18 s; four diagonal ticks for 0.22 s, gold on a tag-out | `action_jump_land.mp3` at 1.5 plus `volume_slider.ogg` at 1.4; stab: land at 0.7 | 12 straw bits. The victim's client pushes itself, speed `v0 (1 - t/T)^2`: poke 34 studs/s over 0.18 s (2 studs), finisher 48 over 0.26 (4.2), stab 56 over 0.30 (5.6) |
| Hit taken | `hurt` 0.3 s: both arms dip | as above | Kick 3 degrees (4 stab) away from the attacker; an arc pointing at them for 0.9 s; the existing soft red edge | `action_jump_land.mp3` at 0.9 | Haptic `GameplayCollision` (pcall) |
| Blocked | `guard`: needle swung across (-0.42, 0.24, -0.10; needle rz 62). Attacker's `stagger` 0.6 s | The server tweens Grip crosswise | 1.5 degrees for both; "PARRY!"; a GUARD bar | `volume_slider.ogg` at 2.0 | Attacker pushed 30 over 0.16 s |

Catch: a ring closes on the reticle over the last 0.4 s; `action_get_up.mp3` at 1.5. Slide: arms low, needle tilted 18 degrees; `action_get_up.mp3` at 0.8. Under `reduceEffects`: no kick, roll, FOV change, hit-stop or Highlight.

## 6. MODULES
**New**
- `shared/ConfigMoves.luau`: `Melee`, `Guard`, `Catch`, `Stance`, `HitCheck`, `Feel`, `Sfx`, `Pose` (degrees per joint), `Keys`. Config.luau merges it in three lines (282 total).
- `shared/FirstPersonMoves.luau`: `anims` (jab1, jab2, jab3, stab, guard, parry, stagger, catch, hurt), `layers` (crouch, slide, charge). The owner's rig wins on a shared name.
- `shared/HitMath.luau` (pure): `window(ping)`, `margin(speed)`, `inReach(from, samples, now, window, range)`, `body(rootPos, stance)`, `segmentCapsule(a, b, foot, top, radius)`.
- `server/History.luau`: `samples(player, window)`, `speed(player, seconds)`.
- `server/Speed.luau`: `set(player, layer, value)`; layers freeze, boots, stance, act.
- `server/Melee.luau`: Poke and Charge; `stagger(player, seconds)`, `cancelCharge(player)`.
- `server/Guard.luau`: `blocks(target, fromPosition, kind)`. `server/Stance.luau`: `of(player)`.
- `server/PracticeMoves.luau`: `rock(dummy, dir, power)` tilts still dummies; one sparring dummy pokes every 2.5 s after a visible 0.5 s wind-up, and parrying it takes one of its hearts. It never hurts you.
- `client/Mover.luau`: `push(dir, v0, v1, seconds, curve, tag)`.
- `client/CamFx.luau`: the only FieldOfView writer; `kick(pitch, yaw, roll)`, `fov(key, delta, inS, outS)`, `roll(key, degrees)`. Bound at `Enum.RenderPriority.Camera.Value + 1`; idle unless `CameraType` is Custom (Bird's Eye).
- `client/Sfx.luau`: `play(name, position)`. `client/Poser.luau`: `Motor6D.Transform` in `RunService.PreSimulation`.
- `client/MeleeFx.luau`, `StanceFx.luau`, `HitFx.luau`.
- `client/TouchPad.luau`: `add(id, label, slot, onDown, onUp)`, an arc of round buttons by the jump button. Today's stack of 46 px buttons with two more added would not fit a small phone.

**Changed**
- `Combat.luau`: loses `poke`; `Combat.damage(attacker, target, amount, info)`, `info = { kind, push }`.
- `CombatThrow.luau`: stepped flight, Catch. `Practice.luau`: `hitDummy(player, id, amount, thrown, info)`.
- `Powerups`, `Streaks`, `RoundManager`, `Practice`: `Speed.set` instead of writing WalkSpeed.
- `ViewModel.luau`: merges FirstPersonMoves; `layer(name, on)`, `freeze(seconds)`; priority Camera + 2.
- `DashFx`, `Effects`: use Mover and CamFx. `ThrowFx`: own flight drawn at once, the return flight, the catch ring. `CombatFx`, `CooldownBars`, `KeyHints`, `FeedFx`: small edits.

**Practice Yard.** Dummies take pokes, Big Stabs and throws through `hitDummy`, with the same lunge, markers and hit-stop; the sparring dummy teaches Guard; Catch, crouch and slide work there as in a round.

**Remotes.** New: `Stance`, `Charge`, `Guard`, `Catch` (client to server); `Swing`, `Blocked`, `ThrowEnd` (server to clients). Changed: `Poke`; `Hit` adds `kind` and `push`; `Thrown` carries `id`, `origin`, `dir`, `speed`.

**Tests to add**
- HitMath mirrored in Python: W clamps at 0.1 and 0.35; a target who left reach 0.3 s ago counts at 150 ms ping, 0.5 s ago does not; a head-height throw clears a slider and hits a stander; nothing beyond 21 studs is accepted.
- No tag-out from full hearts in under 0.8 s.
- Dash, slide, lunge and knockback stay under `AntiCheat.maxSpeed` in any 0.5 s window.
- Only `Speed.luau` writes `.WalkSpeed`.
- Every `Sfx` file is one of the 11 verified built-in names; every `Keys` row has a key, a gamepad button and a touch slot, and is in KeyHints.
- FirstPersonMoves keys run in order from 0 to their length; `FirstPerson.luau` gains nothing.
- Melee, Guard and Stance never mention rarity or Robux, and read no client time.
- CamFx and HitFx honour `reduceEffects`; HitFx has no `AlwaysOnTop`.

## 7. RISKS
| Risk | Conservative choice |
|---|---|
| Joint signs and axes can't be checked here; R6 differs | Degrees live in `Config.Pose`. The server's Grip tweens stay, so every move still reads if a pose is wrong. R6 gets no joint posing |
| A HipHeight crouch may bounce or stall on steps; avatar heights vary | No map needs a crouch. `Config.Stance.lowerBody = false` makes crouch speed, camera and pose only |
| The kick drifts if the default camera doesn't rebuild its CFrame each frame (unverified) | Check in Studio; `Config.Feel.kick = 0` turns it off |
| Sounds were picked by description, not by ear. All four `Config.Sounds` name files that don't exist, so the game is probably silent today | Every sound is a `{ file, pitch, volume }` row to audition in Studio; repoint the four |
| `Tool.Deactivated` on touch and gamepad; L2 and L3 being free | Release also listens to `UserInputService.InputEnded`; the 1.5 s auto-fire is the backstop; buttons are `Config.Keys` rows |
| A cheat ignores knockback, crouch speed or the lunge, or fakes `Stance`, `Charge` or Guard | Hearts depend only on server checks; those three are server-timed and rate-limited; AntiCheat still caps speed |
| Poke range grows from 8 to 12 and tag-outs get faster, so chests get harder to hold | All in `Config.Melee`; fall back to cooldowns 0.7, 0.7, 0.9 and lunge range 10 |
| A 1 of 1's three-heart throw returns every 2.5 s with a Clean Catch; Time Trial records get easier | Owner's calls: no catch refund for that needle; a fresh board |


# design:depth

# Combat and movement overhaul: depth and balance first

Design only; nothing was edited. Paths are under `/home/user/screener3/needle-hunt/src/` (`server/`, `client/`, `shared/`).

## 1. GOALS
A fight is three readable choices: a quick poke stops a Power Poke, a Power Poke pops a Thimble, a Thimble stops pokes and throws. Hits land when they looked like they should and are felt in the hand, the camera and the ears, and every miss shows its reason (blocked, dodged, ducked). Crouch, slide and dash set up or escape those choices; they are never a second health bar.

## 2. MOVESET
UI names: **Power Poke** (code `stab`; kinder for children) and **Thimble** (the guard).

| Action | Keyboard/mouse | Gamepad | Touch | Timing | Effect |
|---|---|---|---|---|---|
| Poke | click (fires on press) | R2 | tap, or POKE | cooldown 0.7 s; 0.55 s after a landed poke (chain window 1.2 s) | 1 heart; reach 7 + lunge 3.5; push 2.6 studs. Third in a chain: "COMBO!", push 4.8. A whiff, block or hit taken resets it |
| Power Poke | keep holding; release when the ring is full | hold R2 | hold POKE | charge 0.6 s at 0.6x walk, starting once the poke is ready; auto-releases 1.5 s later; next poke 0.8 s after a hit, 1.0 s after a whiff | 2 hearts; reach 7 + lunge 6; push 5.4; always breaks a Thimble. Early release: ordinary poke. Losing a heart cancels it |
| Thimble | hold right-click (first person only) or R | hold L2 | hold GUARD | re-raise 0.8 s; 0.6x walk; no attacking | 3 pips; blocks pokes and throws from any side; -1 pip per block and per 2 s held; +1 per 2.5 s once lowered; drops at 0. Perfect (within 0.25 s of raising): no pip, attacker locked out 1.0 s, your poke is ready |
| Throw | Q | X | THROW | cooldown 4 s; range 45, 90 studs/s (unchanged) | 2 hearts; needle back at `BackAt`, 1.0 to 1.4 s after release by distance |
| Catch | Q as it returns | X | THROW (reads CATCH) | from 0.3 s before to 0.15 s after `BackAt` | throw cooldown -1.5 s. Early or no press: in hand 0.25 s late |
| Dash | C | B | DASH | 55 studs/s x 0.22 s, 3 s (unchanged) | new: 0.2 s dodge; pokes and throws miss |
| Crouch / Slide | Left Ctrl or V (toggle) | L3 | CROUCH | section 3 | Slide Poke: reach +2, push 4.8 |

Jump (Space, A) and Inspect (F, Y) are unchanged.

**What beats what**
- Poke > Power Poke (interrupts it). Power Poke > Thimble (full 2 hearts, pips to 0). Thimble > Poke and Throw (a blocked poke costs the attacker a 1.0 s cooldown).
- Throw > a slow charger. Slide > Throw (throws miss a slider). Dash > one timed attack every 3 s.
- A blocked hit still sets `HitAt`, so a Thimble cannot protect a chest hold.

**Time to tag out (3 hearts, unanswered):** combo 1.1 s; poke then Power Poke about 1.25 s; throw, clean catch, poke about 1.0 s (the floor). Today: three pokes 1.4 s, throw then poke 1.2 s. No stuns, only attack lockouts.

**Practice Yard and prompts.** Time Trial dummies stay plain and take every move (stationary ones rock back; moving ones cannot, because their slide tween owns the root CFrame). A new untimed, no-reward Lessons yard (`Remotes.Practice:InvokeServer("start", "lessons")`) teaches seven server-checked steps, each card showing your device's input: poke; combo; Power Poke a Thimble dummy; block a Tosser dummy's hay ball; Perfect Thimble; slide under one; throw and catch. KeyHints gains gamepad and touch columns, and a tip shows at most three times a session ("Thimble! Hold [input] for a Power Poke").

## 3. CROUCH AND SLIDE
Player attribute `Stance` = `stand`, `crouch` or `slide`: set by the server, predicted by the owner's client.
- **Crouch:** Crouch pressed on the ground below 0.85 x WalkSpeed.
- **Slide:** Crouch pressed on the ground at 0.85 x WalkSpeed or more, or within 0.3 s of a dash; cooldown 1.5 s. It lasts 0.6 s and ends standing (crouched without headroom); earlier on a jump, 0.25 s airborne, or under half the commanded speed for 0.1 s.
- **Stand:** Crouch, Jump or Dash, only if `workspace:Spherecast(root.Position, 0.9, Vector3.yAxis * (drop + 1.7), params)` is clear. Forced by respawn, tag-out, sitting, a freeze (WalkSpeed 0) and a `Phase` change.

**Speeds.** Crouch 0.5 x walk (8; 13 with Hay Boots; 12 Marked). Slide: a `LinearVelocity` (Plane) from min(44, 1.75 x walk) down to 0.9 x walk, direction fixed: 12.7 studs, 20 with Hay Boots.

**Body and camera.** The owner's client eases HipHeight over 0.15 s by min(1.2, stand - 0.8) for a crouch, min(1.6, stand - 0.4) for a slide. The camera follows the root; a slide adds `Humanoid.CameraOffset` (0, -0.4, 0), FOV +6 and 3 degrees of roll. Others see folded legs or a leaning slide (client/Poses) and a hay-dust puff.

**Hitbox.** Clearance is physical: a default avatar should fit a 4.75-stud gap crouched, 4.3 sliding (unverified). The server's hit capsule hangs from the root (-2.5 to +1.5 studs), so it drops only as far as the body really did. `Stance` grants only the speed factor, a quieter crouch (`Humanoid.NameDisplayDistance` 100 to 15; footsteps muted if that root's "Running" sound exists), the slide's throw-duck (`SlideUntil`, 0.7 s at most) and Slide Poke.

**Speed.** The server stays the only WalkSpeed writer: `Streaks.walkSpeed(player)` = max(16 x `SpeedMult`, `BoostSpeed`) x `SlowMult` (lowest of crouch 0.5, Thimble 0.6, charging 0.6), written by `Streaks.refresh(player)`, which leaves a frozen 0 alone. Powerups stores `BoostSpeed` instead of comparing WalkSpeed values; RoundManager and Practice are untouched.

**Dash and AntiCheat.** A dash from a crouch stands you up; Crouch during a dash chains a slide; one mover at a time. `maxSpeed` stays 70 (worst 0.5 s, dash into a Hay Boots slide: about 47 studs/s). The server grants a slide only if Rewind shows 0.7 x walk over the last 0.2 s.

## 4. HIT REGISTRATION
**The client sends intent only:** `Poke(target)` (userId, dummy id or nil), `Stab("charge" | "release", target)`, `Guard(boolean)`, `Throw(aimUnit)`, `Catch()`, `Stance(name)`, `Dash()`; never positions, times or damage. Every remote type- and NaN-checks its arguments, allows 8 events a second and times everything from server receipt.

**Poke and Power Poke, in order**
1. Alive, in the round (or your own dummy), needle in hand, not guarding, `BusyUntil` passed, cooldown minus 0.1 s.
2. Rewind: 1 s of root positions per player, recorded every Heartbeat. W = clamp(2 x `attacker:GetNetworkPing()` + 0.1, 0.1, 0.35). Accept if, at any target sample in W, horizontal distance is at most reach + lunge + 2 (poke 12.5, Slide Poke 14.5, Power Poke 15), height difference at most 6, and attacker look . direction is 0 or more (ignored inside 1.5 studs).
3. One `workspace:Raycast` from the attacker's head to that sample, characters excluded (today's poke passes through walls).
4. `Fight.resolve`: `SafeUntil`, then `DodgeUntil` ("dodged"), then Thimble ("blocked", "perfect", "broken"), else hearts.
5. A Power Poke needs now - `ChargeAt` of 0.5 s or more; otherwise it is an ordinary poke.

**Throw.** The origin is tested with `GetPartBoundsInRadius(origin, 0.4)` and a ray from the head. The flight is stepped each Heartbeat: `Spherecast` radius 0.4 for walls; segment-to-capsule distance of 2.0 or less (pure maths) for players and dummies. Dodging or sliding targets are skipped. `Thrown` becomes phased: `fly`, `stop`, `back` (`BackAt`).

**Aim assist (client only; the server re-checks everything)**
- Candidates: within reach + lunge, in line of sight, inside a cone round the camera look (30 degrees mouse, 40 gamepad and touch, 70 inside 4 studs). The smallest angle wins; the reticle turns pink.
- Lunge only with a candidate more than 5 studs away: 40 studs/s until 4.5 studs away or 0.09 s (Power Poke 45 studs/s, 0.13 s). A whiff never moves you, and the camera is never turned.

## 5. FEEDBACK
First-person keys go in `shared/FirstPersonMoves.luau` (offsets {x, y, z, rx, ry, rz}); third person is `Motor6D.Transform` in `RunService.PreSimulation` on every client, plus today's Grip tween. Sounds are verified `rbxasset://sounds/` files, chosen by description and never heard.

| Event | First person | Others see | Camera and UI | Sound (x pitch) | Particles, push |
|---|---|---|---|---|---|
| Swing | `poke` 0.32 s: right {0.05,-0.04,0.18,6,0,0} at 0.04, {-0.14,0.14,-0.85,-10,0,0} at 0.10 | Grip jab | | action_jump.mp3 x1.7 | lunge |
| Hit dealt | view-model freeze 0.05 s (heavy 0.08) | victim: Highlight fill 0.35 to 1 in 0.2 s (Occluded), Waist flinch | kick 1.2 degrees (heavy 2); marker of four rotated Frames, 0.25 s: white, orange for 2 hearts, gold for a tag-out | action_jump_land.mp3 x1.5 + volume_slider.ogg x1.4; heavy x0.7 | 10 hay sparks |
| Hit taken | `hurt` 0.3 s: both arms {0.1,-0.15,0.2,10,0,6} at 0.06 | | kick 2.5 degrees (heavy 3.5); edge vignette on the side it came from, opacity 0.35 at most | action_jump_land.mp3 x1.1 | victim's client pushes itself 22 studs/s x 0.12 s (heavy 34 x 0.16) |
| Blocked | hold: right {-0.55,0.25,-0.15,-20,0,35}, left {0.35,0.45,-0.25,-25,0,-10}; attacker `bounce` 0.4 s | silver glass dome (local Ball, 5 studs, Transparency 0.8), left arm up | grey marker; GUARD pips; "PERFECT!" | volume_slider.ogg x2.0 | perfect: attacker recoils 2 studs |
| Charged | hold: right {0.12,0.1,0.45,22,0,0}; `stab` 0.5 s: {-0.2,0.18,-1.15,-14,0,0} at 0.07 | arm drawn back; steady sparkle at the tip when full | ring fills round the reticle | volume_slider.ogg x0.8 when full | Thimble broken: dome bursts into sparks |

A catch plays `catch` (0.25 s), a closing ring and action_get_up.mp3 x1.5; a slide action_footsteps_plastic.mp3 x0.5; a tag-out keeps today's pop, panel and death sound. Kicks, roll and freeze are off under reduceEffects; nothing flashes. The four current `Config.Sounds` name missing files: repoint them.

## 6. MODULES
**Shared, new:** `ConfigMoves.luau` (tables `Stance`, `Stab`, `Chain`, `Guard`, `Catch`, `HitReg`, `Feel`, `MoveSounds`, `Poses`, `Inputs`, `Lessons`; Config.luau gains a three-line merge loop); `HitMath.luau` (`window(ping)`, `pokeOk(attackerPos, look, samples, limit)`, `segmentCapsule(p0, p1, root, radius)`); `FirstPersonMoves.luau` (`anims`, `holds`).

**Server, new:** `Rewind.luau` (`samples(player, window)`, `speed(player, seconds)`); `Fight.luau` (pips, charge, chain, lockouts: `canAttack(player)`, `resolve(attacker, target, kind)`, `landed(attacker, result)`); `CombatPoke.luau` (poke checks moved out of Combat.luau, which stays under 300); `Stance.luau`; `PracticeDrills.luau` (Lessons, Thimble and Tosser dummies).
**Server, changed:** Combat (`damage(attacker, target, amount, kind)`; `Hit` gains `kind`, `result`, `push`, `pushTime`, `chain`), CombatThrow (stepped flight, catch), Dash (`DodgeUntil`), Streaks, Powerups, Practice, PracticeYard, Main.

**Client, new:** `Mover.luau` (`push(velocityXZ, seconds, tag)`: the one LinearVelocity for dash, slide, lunge and knockback); `CamFx.luau` (`kick(pitch, roll)`, `fov(name, delta, seconds)`: sole FieldOfView owner, at `Enum.RenderPriority.Camera.Value + 1`, idle unless CameraType is Custom); `FightInput.luau` (holds, touch buttons; ContextActionService with `createTouchButton = false`); `StanceFx.luau`; `Poses.luau`; `HitFx.luau`.
**Client, changed:** ViewModel (merges FirstPersonMoves; `hold(name)`, `freeze(seconds)`; render priority Camera + 2), Aim (`firstPerson()`, `hot(on)`), ThrowFx (ignores X while a chest prompt shows), DashFx, CombatFx, CooldownBars, KeyHints, PracticeFx, UIController.

**New RemoteEvents:** `Stab`, `Guard`, `Stance`, `Catch`.
**Player attributes:** `Stance`, `SlideUntil`, `Guarding`, `GuardPips`, `ChargeAt`, `Chain`, `BusyUntil`, `DodgeUntil`, `BackAt`, `SlowMult`, `BoostSpeed`.

**Tests:** Python mirrors of `HitMath`; fastest tag-out about 1.0 s or more; pips drain faster than they refill; worst 0.5 s of movers under `maxSpeed`; every `Config.Inputs` row has key, pad and touch; FirstPersonMoves passes the rig checks; every sound is one of the verified 11; no rarity or Robux in combat modules.

## 7. RISKS
- **Joint signs** cannot be checked here: per-joint degrees live in `Config.Poses`; R6 gets HipHeight (-1.0) only.
- **"Fit under things"** has under a stud of margin and avatars vary: no route may need a crouch; the map team gets the gap numbers.
- **Input defaults** (R2 activating the tool, L2 and L3 free) are unverified: holds use `UserInputService.InputBegan/InputEnded`, touch charges only from the POKE button, and `Config.Inputs` rebinds everything. Right-click turns the camera when zoomed out, so it guards only in first person.
- **All-round Thimble** is deliberate: the server's view of facing lags. Pips and the hold drain stop turtling.
- **Exploits:** reach is capped at 12.5 to 15 studs with a wall ray and a 0.35 s rewind; a cheat can ignore knockback and crouch speed, so no hearts depend on them; the dodge is at most 0.2 s every 2.4 s (`Dash.dodge` 0 removes it).
- **Camera kick** assumes the default camera rebuilds its CFrame each frame (unverified): `Feel.kick = 0` switches it off.
- **Faster tag-outs:** `Chain.cooldown` 0.7 switches the quicker combo off. Time Trial records will fall too: the owner may want a fresh board.
- **The 1 of 1's 3-heart throw** already breaks "every needle fights the same"; Thimble, slide and dash now answer it, but the owner should re-confirm it.

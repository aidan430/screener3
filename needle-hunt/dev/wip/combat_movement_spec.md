# Combat and movement: final specification (Needle Hunt)

Design only: nothing in the game was edited, built or committed. This file is the single source of
truth for the builders. Paths are relative to `/home/user/screener3/needle-hunt/` unless they start
with `/`. Baseline when this was written: commit `3e67e57`; `python3 dev/build.py --project
needle-hunt --check` reports 0 problems in 85 scripts and `python3 needle-hunt/dev/test_rules.py`
passes 41 tests.

Two other teams are working in this checkout at the same time:
- the map team (do not touch `MapsBig`, `MapKit`, `MazeKit`, `MazeWalls`, `Landmarks`, `FarmProps*`,
  `Maps` or lighting);
- the first-person rebuild (task "First-person view: rebuild hands, hold pose, motion and
  animations"). It has an untracked `src/client/ViewModelPose.luau` and is rewriting
  `src/client/ViewModel.luau`, `src/shared/FirstPerson.luau` and adding `shared/FirstPersonRig`,
  `client/ViewModelRig`, `client/ViewModelMotion`. Nothing here may edit those files except the
  integrator's four small hooks in `ViewModel.luau` (section 6.6), applied to whatever that file
  is when the integrator runs.

## 0. The decision

| Design | Feel | Fairness | Depth | Exploit safety | Buildable blind | Total |
|---|---|---|---|---|---|---|
| 1 (feel) | 9 | 6 | 7 | 7 | 6 | 35 |
| 2 (net) | 6 | 9 | 7 | 9 | 7 | 38 |
| 3 (depth) | 7 | 7 | 9 | 7 | 5 | 35 |

**Spine: Design 2.** Its server owns every decision, rewinds to what the attacker saw, limits every
remote, and never makes a tag-out faster than it is today.

**Grafted from Design 1:** the poke fires on the press with no wind-up; one `client/Mover` for dash,
slide, lunge and knockback; one field-of-view owner (`client/CamFx`); hit-stop; first-person
keyframes that use only x, y, z and the tip angle; the sparring dummy.
**Grafted from Design 3:** the names Power Poke and Thimble; a Thimble that blocks from every side
(the server's view of facing lags, so a front-only block is unfair at high ping); a blocked hit
still stops a chest hold; inputs as data rows; X is ignored by Throw while a chest prompt shows.

**Cut, to keep it learnable in a minute:** stagger, Thimble pips and Perfect Thimble, dash
invulnerability, Slide Poke, the Lessons yard, camera roll, throw aim bending, Design 2's tighter
AntiCheat budget (it could rubber-band honest players and cannot be tested here), and Design 2's
0.10 s poke wind-up.

## 1. GOALS

1. A press answers in the same frame (the arm stabs, you lunge) and a hit is confirmed by a marker,
   a thud, a small kick and a push on the player who was hit. Nothing is shown as a hit until the
   server says so.
2. A hit that looked right on your screen lands, at 150 ms ping and on a phone: the server checks
   where the target was on your screen, not where they are now.
3. Three choices a child can say in one breath: **Poke beats Power Poke, Power Poke pops a
   Thimble, Thimble stops Pokes and Throws.**
4. Crouch and slide are movement, not a second health bar. No tag-out route is faster than
   today's fastest (throw then poke, 1.2 s).
5. Needles, hay and hearts. Nothing flashes; "Reduce effects" switches off kicks, field-of-view
   changes, hit-stop and tints. Every needle fights the same.

## 2. MOVESET

| Move | Keyboard and mouse | Gamepad | Touch | Timing (seconds) | Hearts and range |
|---|---|---|---|---|---|
| **Poke** | Left click (fires on the press) | R2 | Tap the screen, or POKE | Cooldown 0.7. After a landed poke the next is ready in 0.5; after that second hit ("ONE-TWO!"), 0.9. A blocked poke: 1.1 | 1 heart. Reach 8 studs, plus a lunge of up to 4 studs at a target up to 11 away |
| **Power Poke** | Keep holding left click; let go when the ring is gold | Hold R2 | Hold POKE | Charging starts 0.25 into the hold (never before the poke is ready), is full 0.7 later, and lets itself go 1.5 after full. Letting go early cancels it. Cooldown 1.0 | 2 hearts. Lunge up to 6.4 studs at a target up to 13 away. Pops a Thimble and still takes 2 |
| **Thimble** | Hold R | Hold L2 | Hold GUARD | Up for as long as held, 1.5 at most; then 1.2 before the next (2.5 if it was popped) | Blocks pokes and throws from any side. No hearts lost. You walk at half speed and cannot poke, charge or throw |
| **Throw** | Q | X (ignored while a chest prompt shows) | THROW | Unchanged: 90 studs/s, range 45, needle back in hand 1.2 after the throw, cooldown 4 | 2 hearts |
| **Catch** | Q again as it returns | X | THROW (reads CATCH) | One try a throw, from 0.25 before the needle is back to 0.15 after | Next throw 1.5 sooner. The needle is never back early |
| **Dash** | C | B | DASH | Unchanged: 55 studs/s for 0.22, cooldown 3 | Ends a charge, lowers a Thimble, stands you up |
| **Crouch** | Left Ctrl or V (press to crouch, press again to stand) | L3 | CROUCH | 0.15 down or up | Walk at half speed, no footsteps, name tag hidden |
| **Slide** | The crouch button while running on the ground | L3 | CROUCH | 0.6; cooldown 1.5 | About 13 studs (19 with Hay Boots). Ducks a head-high throw |

Unchanged: Jump (Space, A, the jump button; it also stands you up), Inspect (F, Y, INSPECT), opening
a chest (hold E, hold X, hold the prompt).

**What beats what**
- Poke beats Power Poke: losing a heart ends a charge.
- Power Poke beats Thimble: it pops it and takes 2 hearts.
- Thimble beats Poke and Throw: nothing lost, and the poker waits 1.1 s and is bounced back.
- Dash and slide get you out of a Power Poke's lunge; a slide passes under a head-high throw.
- A Thimble cannot guard a chest: a blocked hit still stops the hold (`HitAt` is set).

**Time to tag out from 3 hearts (nothing faster than today)**

| Route | Hits land at | Today |
|---|---|---|
| Three pokes | 0, 0.5, 1.4 | 0, 0.7, 1.4 |
| Poke, keep holding, Power Poke | 0, 1.2 | - |
| Throw, then poke when it is back | up to 0.5, 1.2 | the same |

`test_rules.py` asserts `Combo.first + Combo.second >= 2 x Combat.cooldown` and
`Combo.first + Power.charge >= Throw.back`.

**Rules the server keeps**
- One thing at a time: guarding refuses pokes, charges and throws; raising a Thimble ends a
  charge; a throw ends a charge; no charge while the needle is away.
- A charge counts from `max(time the server got Charge(true), time the poke is ready)`.
- Hearts, safe time (3 s), regrowth (8 s), respawn (5 s), streaks, Marked and the feed are unchanged.
  The feed says POWER for a Power Poke tag-out.

## 3. CROUCH AND SLIDE

All numbers are `Config.Stance` (section 6.3).

### 3.1 State machine (the player's own device predicts; the server confirms)

States: `stand`, `crouch`, `slide`. The server's copy is the player attribute `Stance`
(nil = stand, `"crouch"`, `"slide"`).

| From | Event | Condition | To | What happens |
|---|---|---|---|---|
| stand | crouch button | on the ground, flat speed >= 0.85 x `humanoid.WalkSpeed` (or a dash is running, or ended under 0.3 s ago), 1.5 s since the last slide began, WalkSpeed > 0, not sitting | slide | `Remotes.Stance:FireServer("slide")`; mover starts; body drops; Thimble and charge end |
| stand | crouch button | otherwise (WalkSpeed > 0, alive, not sitting) | crouch | `Remotes.Stance:FireServer("crouch")`; body drops |
| crouch | crouch button, jump, or dash | headroom clear | stand | `Remotes.Stance:FireServer("stand")`; body rises |
| crouch | the same | no headroom | crouch | nothing (a jump just bumps) |
| slide | 0.6 s up, jump, 0.25 s off the ground, a wall (moving under half the pushed speed for 0.1 s), or another mover (dash, knockback) | headroom clear | stand | `Remotes.Stance:FireServer("stand")` |
| slide | the same | no headroom | crouch | `Remotes.Stance:FireServer("crouch")` |
| any | respawn, tagged out, frozen (WalkSpeed 0), sitting | - | stand | the server clears `Stance` itself; the client follows |

Reconciling: when the local `Stance` attribute changes and the client is not sliding and made no
change of its own in the last 0.5 s, it adopts the server's stance.

### 3.2 Body and camera (the player's own device, `client/StanceFx`)

- `stand = humanoid.HipHeight`, read each time the player leaves `stand`.
- R15: crouch drop = `min(1.2, stand - 0.8)`, slide drop = `min(1.6, stand - 0.4)`; a drop under
  0.2 is treated as 0. R6 (`humanoid.RigType == Enum.HumanoidRigType.R6`): drop 1.0 for both.
- `humanoid.HipHeight` eases to `stand - drop` (rate `4.6 / 0.15` a second, snapping within 0.01)
  and back. The camera follows the root by itself.
- Slide only: `humanoid.CameraOffset` eases to `(0, -0.4, 0)` and back; `CamFx.fov("slide", 5, 0.6)`.
- `Config.Stance.lowerBody = false` switches the HipHeight change off: the camera dips by
  `CameraOffset (0, -0.9, 0)` instead and nothing fits under anything (a Studio fallback).
- Headroom before standing: `workspace:Spherecast(root.Position, 0.9, Vector3.yAxis * (drop + 1.7),
  params)` with the character excluded and `RespectCanCollide = true`; a hit means stay down.
- On `CharacterAdded` everything resets (a new Humanoid has its own HipHeight).
- StanceFx never writes WalkSpeed. The server's value arrives one round trip later.

### 3.3 The slide's push (`client/Mover`, the dash's exact mover)

- Direction: the root's flat velocity when it started (`humanoid.MoveDirection` if that is tiny),
  fixed for the whole slide.
- Speed: `HitMath.slideSpeed(walk, t)`: from `min(44, walk + 14)` straight down to `0.875 x walk`
  over 0.6 s, where `walk` is `humanoid.WalkSpeed` at the press. Walking 16: 30 down to 14, 13.2
  studs. Hay Boots (26): 40 to 22.75, 18.8 studs. Marked (24): 38 to 21, 17.7 studs.
- One mover at a time: dash, slide, lunge and knockback each replace whatever is running.

### 3.4 The server (`server/Stance`, `server/Speed`)

- `Remotes.Stance` is limited to 8 a second; the argument must be one of the three strings.
- Refused when dead or frozen (`Speed.frozen`).
- `"slide"` also needs 1.4 s since the last slide began (1.5 minus 0.1 for jitter) and
  `Rewind.speed(player, 0.25) >= 0.6 x Speed.walk(player)`; otherwise it is stored as `"crouch"`.
  A slide becomes `"crouch"` by the server's own clock after 0.85 s if the client has not said.
  Starting a slide calls `Fight.interrupt(player, "slide")`.
- `"crouch"`: `Speed.slow(player, "stance", 0.5)` and
  `humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None`.
  `"slide"`: no slow (the mover sets the speed). `"stand"`: slow cleared, `DisplayDistanceType`
  back to `Viewer`.
- A sweep every 0.2 s ends overdue slides and clears the stance of anyone frozen or dead.
- `server/Speed` is the only script that writes `Humanoid.WalkSpeed` or `JumpHeight`:
  `0` when frozen, otherwise `max(16 x SpeedMult, Hay Boots speed) x the lowest slow`
  (crouch 0.5, Thimble 0.5, charging 0.7). Crouched: 8; with Hay Boots 13; Marked 12.

### 3.5 What others see and hear (`client/Poses`, `client/Tells`)

- Legs fold on R15 (`Motor6D.Transform` in `RunService.PreSimulation`): with
  `phi = acos(clamp(1 - drop / stand, 0, 1))`, Hip `+phi`, Knee `-2 phi`, Ankle `+phi` about X
  (the three multipliers are `Config.Poses.legs`), Waist -12 degrees crouched, +20 sliding.
  R6 gets no joint posing.
- Crouched: each client sets that character's `HumanoidRootPart.Running` sound to volume 0 (only
  if a Sound of that name is there) and restores it on standing.
- Sliding: straw dust at the feet (`rbxasset://textures/particles/smoke_main.dds`, 12 a second,
  hay colour) and the `slide` sound at the slider's position.

### 3.6 Hitbox

- Pokes ignore stance.
- Throws test the body's centre line from 2.0 below the root to `hi` above it (stand 1.0, crouch
  0.7, slide -0.4), radius 2.2. The root itself is lower when the body really dropped, so a cheat
  that claims a slide without dropping gains 1.4 studs of clearance for at most 0.85 s in every 1.5.
  A level head-high throw hits a stander and a croucher and passes over a slider; a throw aimed
  at a slider hits.
- Fitting under things: a default R15 avatar is about 5.3 studs tall standing, 4.1 crouched and
  3.7 sliding (unverified; avatars vary). No route in any map may need a crouch. The Practice
  Yard gets one bar 4.6 studs up to try it on.

### 3.7 AntiCheat

`server/AntiCheat.luau` is not changed. Every mover's top speed (dash 55, power lunge 46, slide 44,
lunge 40, knockback 34) is under 0.8 x `Config.AntiCheat.maxSpeed` (56), and only one runs at a time.

## 4. HIT REGISTRATION

### 4.1 What the client may send (never a position, a duration or a time)

| Remote | Arguments | Meaning |
|---|---|---|
| `Poke` | `target`, `power` | `target`: a UserId (number), a dummy id (string, at most 8 characters) or nil. `power`: `true` when letting a full charge go, otherwise nil |
| `Charge` | `on` (boolean) | started holding / let go early |
| `Guard` | `on` (boolean) | Thimble up / down |
| `Throw` | `aim` (Vector3) | as today |
| `Catch` | none | a catch try |
| `Stance` | `"crouch"`, `"slide"` or `"stand"` | section 3 |
| `Dash` | none | as today |

Every handler first calls `RateLimit.allow(player, name)` (a second: Poke 6, Charge 6, Guard 6,
Stance 8, Throw 3, Catch 3, Dash 3; extras are dropped, nobody is kicked) and checks each
argument's type (`type`, `typeof`, and `x ~= x` for NaN). All timing is from the server's
`os.clock()` at receipt.

### 4.2 History (`server/Rewind`)

Every Heartbeat, for each player with a character: `{ p = root.Position, look = flat unit of
root.CFrame.LookVector, t = os.clock() }` into a ring of the last 1 s. A jump of more than 30 studs
between samples, or a new character, clears that player's ring.

The window: `W = HitMath.window(attacker:GetNetworkPing()) = clamp(2 x ping + 0.1, 0.1, 0.35)`.
It is bounded whichever unit or direction the engine's ping turns out to be.

### 4.3 Poke and Power Poke (`server/CombatPoke`), in this order

1. `RateLimit.allow`; argument types.
2. Attacker alive, holding the Needle tool, `NeedleAway` not set, not guarding.
3. Power only: `Fight.takeCharge(attacker, now)` must be true (charged for at least
   `Power.charge - 0.1`); otherwise stop here with no cooldown and no jab (the press already poked).
4. Cooldown: `base = Fight.claimPoke(attacker, now)`; nil (still cooling, with 0.1 s forgiven)
   stops here. The rule inside: `if now >= ready - 0.1 then base = max(ready, now)`, so jitter is
   forgiven and the long-run rate cannot rise.
5. `Combat.jab(attacker, kind)` (everyone sees the Grip thrust).
6. A string target is a dummy: `result = Combat.onDummy(attacker, id, amount, false, { kind = kind,
   combo = n })` (Practice does its own reach check, 4.5). Go to 10.
7. A number target: both `Combat.inRound`, target alive, not the attacker. Otherwise a miss.
8. Reach, rewound: `range = Combat.reach + lunge + HitCheck.pad` = 8 + 3 + 1.5 = **12.5** studs
   on the flat (Power Poke 8 + 5 + 1.5 = **14.5**), at most 6 studs up or down, measured from the
   attacker's current root to **any** target sample in `W` (`HitMath.pokeSample`, newest first).
   Today: 9 studs, no rewind.
9. Facing and walls, against that sample: some attacker sample in the last 0.25 s has
   `HitMath.facing(look, from, sample)` true (dot >= 0, always true within 2 studs; today 0.2);
   and `workspace:Raycast(attackerRoot + (0, 1.5, 0), sample + (0, 0.5, 0) - that, Rewind.worldParams())`
   hits nothing (every character excluded, `RespectCanCollide = true`). Today's poke passes
   through walls.
10. `result = Combat.damage(attacker, target, amount, { kind = kind, combo = n })` for a player.
    Then `Fight.setReady(attacker, base, seconds)` with `HitMath.cooldown(kind, result, chain)`:

| Outcome | Next poke in | Chain |
|---|---|---|
| Power Poke, hit or miss | 1.0 | reset |
| Poke blocked by a Thimble | 1.1 | reset |
| Poke missed, or no target | 0.7 | reset |
| Poke landed, first of a chain | 0.5 | 1 |
| Poke landed within 1.2 s of the first | 0.9 | reset (this is the ONE-TWO) |

Alive, safe time, needle in hand and Thimble are always judged at the server's present.

### 4.4 Throw (`server/CombatThrow`): stepped, so dodges count

1. `RateLimit.allow`; `aim` is a Vector3 of length 0.5 to 2 and not NaN (today's check); alive,
   holding the Needle, in the round's search or `Practicing`, `NeedleAway` not set, not guarding;
   cooldown with 0.1 s forgiven. `Fight.interrupt(player, "throw")`.
2. Origin: `head.Position + dir * 1.5`, unless `workspace:Raycast(head.Position, dir * 1.5,
   worldParams)` hits something, then `head.Position` (today a throw against a wall can start
   beyond it).
3. `backAt = workspace:GetServerTimeNow() + Throw.back`. Tell everyone:
   `Remotes.Thrown { phase = "fly", id, from, key, origin, dir, speed, range, backAt }`.
4. Each Heartbeat, with `step = min(speed x dt, range left)`:
   - walls: `workspace:Spherecast(pos, 0.4, dir * step, worldParams)` where `worldParams` excludes
     every character and the thrower's own dummies, `RespectCanCollide = true`;
   - players in the round (not the thrower, alive): for each sample in `W`,
     `HitMath.needleHits(pos, pos + dir * reach, foot, top, 2.2)` with `foot, top =
     HitMath.body(sample.p, target:GetAttribute("Stance"))`, where `reach` is the step cut short
     at the wall. The smallest "how far along" wins. Then one
     `workspace:Raycast(needlePoint, bodyPoint - needlePoint, worldParams)`: a wall between cancels
     that hit;
   - the thrower's own dummies (models with `DummyId`, not `Out`, in `PracticeYard_<UserId>`):
     the same test on the line from 1.0 below to 4.5 above the post's position, radius 2.0, no
     rewind.
5. On a player: `Combat.damage(thrower, target, amount, { kind = "throw", dir = flat dir })` (the 1
   of 1's amount is unchanged). On a dummy: `Combat.onDummy(thrower, id, Throw.damage, true,
   { kind = "throw" })`. Then, and on a wall or at full range:
   `Remotes.Thrown { phase = "stop", id, from, at, hit = "player" | "dummy" | "wall" | "none" }`.
6. At `backAt` the needle is back in hand, as today (`NeedleAway` cleared). Never earlier.
7. `Remotes.Catch`: one try for each throw. Caught if `backAt - 0.25 <= now <= backAt + 0.15 +
   clamp(ping, 0, 0.15)` (server time): the throw's ready time moves 1.5 s earlier (never before
   now), `ThrowAt` is republished and everyone gets `Remotes.Thrown { phase = "catch", id, from }`.
   Outside the window the try is spent and nothing else happens.

### 4.5 Dummies (`server/Practice.hitDummy`)

Pokes: flat distance at most `Combat.reach + lunge + HitCheck.dummyPad` (13.5; Power Poke 15.5),
at most 7 up or down, `HitMath.facing` with the attacker's current look. Throws are already
traced. Then `PracticeMoves.resolve(dummy, kind)` (the Thimble dummy), hearts, and
`PracticeMoves.rock`.

### 4.6 Thimble and charge (`server/Fight`)

- `Guard(true)`: alive, holding the Needle, `now >= guardReady - 0.1`. Sets `Guarding`, ends a
  charge, `Speed.slow(player, "guard", 0.5)`. It blocks from the moment the server has it.
- It drops on `Guard(false)`, after 1.5 s by the server's clock, on a dash or slide, on respawn, or
  when popped. Dropping sets `guardReady = now + 1.2` (2.5 if popped) and publishes `GuardAt`.
- `Charge(true)`: alive, holding the Needle, needle not away, not guarding. Sets
  `ChargeAt` (server time the charge counts from) and `Speed.slow(player, "charge", 0.7)`.
  It ends on `Charge(false)`, on the Power Poke, on losing a heart, on a dash, slide or throw, on
  respawn, or 0.5 s after it would have let itself go (charge + hold + 0.5 = 2.7 s).

### 4.7 Aim assist and lunge (client only; the server re-checks everything)

`AimAssist.target(range)`:
- candidates: other players (when you are in a round's search: only those with `InRound`) and your
  own yard's dummies that are not `Out`, with flat distance at most `range` and at most 6 up or down;
- the same cone as today: flat camera look . flat direction > 0.3 (always inside 0.5 studs);
- in line of sight: `workspace:Raycast(camera position, toward the target's root, params)` with
  every character and your yard's dummies excluded and `RespectCanCollide = true` hits nothing;
- the smallest angle to the camera's look wins (today: the nearest).

`range` is `Combat.reach + Lunge.range` = 11 for a poke and `Combat.reach + Lunge.powerRange` = 13
for a Power Poke.

Lunge, only with a target further than 4.5 studs: `Mover.push("lunge", flat direction, 40, 40,
min(0.1, (distance - 4.5) / 40))`; Power Poke: 46 and 0.14. No target, no lunge. The camera is
never turned.

### 4.8 What a cheat can still do

Ignore knockback, crouch speed and the lunge (no heart depends on them); poke from 12.5 studs
without lunging (today 9); hold a slide's smaller throw target for 0.85 s in every 1.5; press
Catch perfectly (worth 1.5 s of cooldown). Reach, walls, rate, cooldowns and hearts hold.

## 5. FEEDBACK

Rules for all of it: contact effects play only when `Remotes.Hit` (or the yard's
`PracticeState`) arrives, never on a guess. Sounds are `Config.MoveSounds` rows played by
`client/Sfx` (verified built-in files; pitch varied 6%). Under "Reduce effects": no camera kick,
no field-of-view change, no hit-stop, no tint, and bursts are quartered (today's rule). Nothing
strobes: every effect eases once and stops.

### 5.1 Per event

| Event | Your first-person view (`ViewModel` / `ViewMoves`) | Camera and UI | Sound | What everyone sees | Push |
|---|---|---|---|---|---|
| **Poke press** (yours, at once) | `ViewModel.play(Feel.pokeAnims[1])`; `[2]` when your last landed poke was under 1.2 s ago | POKE bar empties | `swing` | the server's Grip thrust (`Combat.jab`, as today) | lunge (4.7) |
| **Charging** | `ViewMoves.hold("charge", true)` | a ring at the reticle shrinks from 64 to 40 px as it fills, gold and steady when full; `CamFx.fov("charge", -3, 2.2)` | `ready` once when full | `Poses`: arm drawn back while `ChargeAt` is set; `Tells`: a steady sparkle on the needle once `now - ChargeAt >= 0.7` (6 a second, `sparkles_main.dds`) | walk x0.7 |
| **Power Poke let go** | `ViewMoves.hold("charge", false, true)` then `ViewModel.play("power")` | ring gone; `CamFx.fovOff("charge")` | `swingPower` | Grip thrust, longer (`Combat.jab(player, "power")`) | lunge |
| **Hit dealt** (`Hit.from` is you; result hit or broken) | `ViewMoves.freeze(0.05)`; 0.08 for a Power Poke or a tag-out | marker for 0.22 s: four short bars in an X round the reticle, white (1 heart), orange 255,150,60 (2 or more), gold (tag-out); `CamFx.kick(1.2, 0)`, Power Poke 2.0; `CamFx.fov("hit", -2, 0.06)` | `hit` + `tick`; Power Poke or tag-out: `heavy` + `tick` | - | - |
| **Hit, for everyone** (any `Hit` with result hit or broken) | - | - | bystanders: `hit` at the place | text over the target: "POP!" pink 255,120,150; "ONE-TWO!" when `combo == 2`; "POWER!" orange; gold on a tag-out; "POPPED!" above it when broken; "-N ♥" under it. Straw burst (`Effects.burst`, 14 bits; 30 on a tag-out). Tint: one local Highlight on the target, fill white from 0.5 to 1 in 0.2 s, no outline, `DepthMode.Occluded` (skipped if the target is Marked). `Poses.flinch(character)`: Waist +14, Neck +8 degrees, in 0.07 s, out 0.22 s | - |
| **Hit taken** (`Hit.to` is you; result hit or broken) | `ViewModel.play("flinch")` | today's soft red edge; a small red bar on a 110 px circle round the reticle on the side it came from, 0.9 s; `CamFx.kick(2.5, 0.8 away from that side)`, Power Poke 3.5; chest prompts lock (today's rule); haptic `GameplayCollision` in a pcall | `hurt` | as above | your own device: `Mover.push("knock", dir, v0, v1, t)` from `Feel.knock`: poke 22 to 6 over 0.14 s (2.0 studs); ONE-TWO 30 to 8 over 0.16 (3.0); Power Poke 34 to 8 over 0.18 (3.8); throw 26 to 6 over 0.14 (2.2) |
| **Blocked** (result blocked) | defender: `ViewModel.play("guardHit")`; poker: `ViewModel.play("bounce")` | poker: grey X marker; both: `CamFx.kick(1, 0)`; defender's chest prompts lock | `block` at the place | grey "BLOCKED"; 8 white sparkles | the poker's own device: `Mover.push("knock", -dir, 18, 4, 0.12)` (1.3 studs) |
| **Thimble up** | `ViewMoves.hold("guard", true)` | a steady silver edge (UIStroke 10 px, transparency 0.5, eased in 0.1 s); GUARD bar drains over 1.5 s, then refills | - | `Tells`: a silver bubble round the player (a local anchored Ball, 6 studs, SmoothPlastic, transparency 0.8, moved to the root each frame); `Poses`: left arm up. Popped: the bubble fades in 0.15 s with 12 sparkles | walk x0.5 |
| **Throw** | `ViewModel.play("throw")` (the rig's own) | THROW bar empties | `throw` | the needle flies from `origin` along `dir` (your own is drawn at the press, others on `Thrown`); it stops at `at`; it flies back to the thrower over the last 0.4 s before `backAt` | - |
| **Catch** | `ViewModel.play("catch")` | a ring at the reticle closes from 80 to 30 px over the last 0.4 s before `backAt` (only while your try is unused); on a catch: gold "CATCH!" for 0.5 s, THROW bar jumps | `catch` | - | - |
| **Dash** | - | `CamFx.fov("dash", 8, 0.22)` | `dash` | today's trail and dust | `Mover.push("dash", ...)` |
| **Crouch** | `ViewMoves.hold("crouch", true)` | the camera lowers with the body | footsteps off | legs fold; no name tag | walk x0.5 |
| **Slide** | `ViewMoves.hold("slide", true)` | camera dips 0.4; `CamFx.fov("slide", 5, 0.6)` | `slide` at your position | legs fold, lean back, straw dust | the slide |
| **Dummy hit** (`PracticeState` event hit) | as Hit dealt | as Hit dealt | as Hit dealt | text and burst as above; a still dummy rocks back 12 degrees and returns in 0.25 s | - |
| **Sparring dummy pokes you** (`PracticeState` event poked) | flinch, or guardHit when blocked | as Hit taken / Blocked | `hurt` / `block` | the dummy leans back for 0.5 s with "!" over it, then jabs | as Hit taken; no hearts |
| **Tag-out** | - | today's callout, panel and feed; gold marker | `heavy` + `tick`, and Roblox's own sound | today's pop | - |

### 5.2 First-person keyframes

They live in the new `src/shared/FirstPersonMoves.luau` (exact data in 6.3), never in
`FirstPerson.luau`. Offsets from the hold pose, the rig's own format. Only x, y, z (camera space:
x right, y up, -z ahead) and rx (tips the arm up about the camera's X axis) are used: in
`CFrame.Angles(rx, ry, rz)` the X turn is the outermost, so these read the same whatever hold
pose the owner's rig has. Animations: `stab1`, `stab2`, `power`, `flinch`, `bounce`, `guardHit`,
`catch`. Held layers: `charge`, `guard`, `crouch`, `slide`. If the owner's rig defines an animation
with one of these names, the rig's plays. To use the rig's own `jab` for pokes, set
`Config.Feel.pokeAnims = { "jab", "jab" }`.

### 5.3 Third-person poses

`Config.Poses` (6.3), applied by `client/Poses` to every R15 character on every client in
`RunService.PreSimulation` as `motor.Transform = motor.Transform * CFrame.Angles(x, y, z)`,
weights eased over 0.12 s. On your own character Waist and Neck are skipped, so your Head stays
where the camera expects it (ViewModel and Aim find first person by camera-to-Head distance).
Signs are derived, not seen: about X, a part that hangs down (arm, leg) swings forward with a
positive angle; a part that stands up (torso, head) tips back.

### 5.4 Sounds (picked by description, not by ear)

| Name | File in `rbxasset://sounds/` | Pitch | Volume |
|---|---|---|---|
| swing | action_jump.mp3 | 1.7 | 0.5 |
| swingPower | action_jump.mp3 | 1.3 | 0.6 |
| hit | action_jump_land.mp3 | 1.5 | 0.7 |
| tick | volume_slider.ogg | 1.4 | 0.5 |
| heavy | action_jump_land.mp3 | 0.7 | 0.8 |
| hurt | action_jump_land.mp3 | 1.1 | 0.7 |
| block | volume_slider.ogg | 2.0 | 0.7 |
| ready | volume_slider.ogg | 1.2 | 0.5 |
| throw | action_jump.mp3 | 1.3 | 0.5 |
| catch | action_get_up.mp3 | 1.5 | 0.6 |
| dash | action_jump.mp3 | 1.1 | 0.5 |
| slide | action_get_up.mp3 | 0.8 | 0.5 |

`Config.Sounds` (found, click, whoosh, countdown) is left alone here: see OWNER NOTES.

## 6. INTERFACES

House style for every file: tabs, no type annotations (the checker does not parse them), a header
comment that says what the module does, `local function` only, under 300 lines (the build fails at
300), `Remotes.X` and `script.Parent.X` only for things that exist (the build checks both).
Where two packages meet, they meet at exactly the names and signatures below.

### 6.1 Remotes (`default.project.json`, all RemoteEvents)

| Name | New? | Direction | Payload |
|---|---|---|---|
| `Poke` | changed | player to server | `(target, power)`: section 4.1 |
| `Charge` | **new** | player to server | `(on)` boolean |
| `Guard` | **new** | player to server | `(on)` boolean |
| `Catch` | **new** | player to server | none |
| `Stance` | **new** | player to server | `(name)`: `"crouch"`, `"slide"`, `"stand"` |
| `Throw` | same | player to server | `(aim)` Vector3 |
| `Dash` | same | both ways | as today |
| `Hit` | changed | server to all | `{ from, to, hearts, position, amount, kind, result, combo, dir }` |
| `Thrown` | changed | server to all | `{ phase = "fly", id, from, key, origin, dir, speed, range, backAt }`, `{ phase = "stop", id, from, at, hit }`, `{ phase = "catch", id, from }` |
| `PracticeState` | changed | server to player | event `hit` gains `id, kind, result, combo, dir`; new event `poked`: `{ event = "poked", position, dir, blocked }` |

`Hit` fields: `from`, `to` UserIds; `hearts` the target's hearts afterwards; `position` the
target's root; `amount` hearts taken (0 when blocked); `kind` `"poke"`, `"power"` or `"throw"`;
`result` `"hit"`, `"blocked"` or `"broken"`; `combo` 2 on the second poke of a one-two, otherwise 1;
`dir` a flat unit Vector3 from attacker to target (a throw: its flat flight direction).
`Thrown.id` is a number unique to the throw; `backAt` is server time (`workspace:GetServerTimeNow()`);
`hit` is `"player"`, `"dummy"`, `"wall"` or `"none"`.

No remote name may be a built-in Instance member (the build refuses `Remove`, `Changed`, ...).

### 6.2 Player attributes (set by the server only)

| Attribute | Value | Set by | Read by |
|---|---|---|---|
| `Stance` | nil, `"crouch"`, `"slide"` | `server/Stance` | `CombatThrow` (body line), `StanceFx`, `Poses`, `Tells` |
| `Guarding` | true or nil | `server/Fight` | `GuardFx`, `Poses`, `Tells` |
| `GuardAt` | server time the Thimble can go up again | `server/Fight` | `GuardFx` |
| `ChargeAt` | server time the charge counts from, or nil | `server/Fight` | `PowerFx`, `Poses`, `Tells` |
| `PokeAt` | server time the next poke is ready | `server/Fight` | `CombatFx` |
| `ThrowAt` | server time the next throw is ready | `server/CombatThrow` | `ThrowFx` |

Unchanged: `Hearts`, `SafeUntil`, `HitAt`, `NeedleAway`, `SpeedMult`, `Marked`, `Streak`, `InRound`,
`Practicing`. `SpeedToken` is no longer used.

### 6.3 Shared modules (new)

#### `src/shared/ConfigMoves.luau` (write exactly this)

```lua
-- Crouch, slide, Power Poke, Thimble, catch, the hit checks and how hits feel: every number for
-- the combat and movement moves. shared/Config.luau merges these tables in, so the rest of the
-- game reads Config.Stance, Config.Power and so on. Studs, seconds, studs a second, degrees.
local M = {}

-- Crouch and slide (client/StanceFx, server/Stance, server/Speed).
M.Stance = {
	walk = 16, jump = 7.2, -- the standard walking speed and jump height (server/Speed writes both)
	crouchWalk = 0.5, -- x walking speed while crouched
	crouchDrop = 1.2, minHip = 0.8, -- R15: HipHeight drops by min(crouchDrop, standing - minHip)
	slideDrop = 1.6, minHipSlide = 0.4, -- and by min(slideDrop, standing - minHipSlide) in a slide
	r6Drop = 1, -- R6: both drop HipHeight by this
	leastDrop = 0.2, -- a smaller drop than this isn't made
	lowerBody = true, -- false: leave HipHeight alone and dip the camera by cameraDip instead
	cameraDip = 0.9, -- keep under 1: first person is found by the camera's distance to the Head
	ease = 0.15, -- seconds to drop or rise
	headroom = 1.7, headRadius = 0.9, -- standing up needs a clear sphere cast up drop + headroom
	slideMin = 0.85, -- a slide needs this x walking speed, on the ground (your own device checks)
	slideMinServer = 0.6, slideMeasure = 0.25, -- and this x by the server's measure over slideMeasure
	slideBoost = 14, slideMaxSpeed = 44, slideEnd = 0.875, -- min(slideMaxSpeed, walk + slideBoost) down to slideEnd x walk
	slideSeconds = 0.6, slideServerMax = 0.85, slideCooldown = 1.5,
	slideAir = 0.25, -- off the ground this long ends it
	slideStall = 0.5, slideStallTime = 0.1, -- so does moving under slideStall x the pushed speed this long (a wall)
	slideAfterDash = 0.3, -- the crouch button this soon after a dash slides
	slideCameraDip = 0.4, slideFov = 5,
	hi = { stand = 1, crouch = 0.7, slide = -0.4 }, -- throws: the top of the body's centre line above the root
}

-- The poke's lunge (client/CombatFx, client/PowerFx): only at a target, stopping stopShort away.
M.Lunge = { range = 3, speed = 40, seconds = 0.1, stopShort = 4.5, powerRange = 5, powerSpeed = 46, powerSeconds = 0.14 }
-- One-two: after a landed poke the next is ready in `first`; a second landed within `window` is the
-- ONE-TWO and the next is `second` away. first + second is never under two normal cooldowns.
M.Combo = { window = 1.2, first = 0.5, second = 0.9 }
-- Power Poke: hold; charging starts holdDelay into the hold, is full `charge` later and lets itself
-- go `hold` after that. walk = x walking speed while charging; fov = field of view while charging.
M.Power = { charge = 0.7, holdDelay = 0.25, hold = 1.5, damage = 2, cooldown = 1, walk = 0.7, fov = -3 }
-- Thimble: up for `max` at most, `cooldown` before the next (`broken` after a Power Poke pops it).
-- A blocked poker's next poke is `bounce` away. bubble = its size in studs.
M.Guard = { max = 1.5, cooldown = 1.2, broken = 2.5, walk = 0.5, bounce = 1.1, bubble = 6, colour = { 200, 210, 225 } }
-- Catch: Throw again from `early` before the needle is back to `late` after (plus ping, lateMax at
-- most): the next throw is `refund` sooner. returnTime = the flight back, the ring's time.
M.Catch = { early = 0.25, late = 0.15, lateMax = 0.15, refund = 1.5, returnTime = 0.4 }

-- Hit checks (shared/HitMath, server/Rewind, server/CombatPoke, server/CombatThrow).
M.HitCheck = {
	base = 0.1, minWindow = 0.1, maxWindow = 0.35, -- rewind: clamp(2 x ping + base, minWindow, maxWindow)
	history = 1, teleport = 30, -- seconds of positions kept; a jump this big clears them
	pad = 1.5, maxUp = 6, closeFacing = 2, facingWindow = 0.25, grace = 0.1,
	wallRadius = 0.4, bodyRadius = 2.2, lo = -2, -- throws: the needle against walls; a player's body line
	dummyPad = 2.5, dummyUp = 7, dummyRadius = 2, dummyLo = -1, dummyHi = 4.5,
}
-- Remote calls a second each player may make (server/RateLimit); extras are dropped.
M.Limits = { Poke = 6, Charge = 6, Guard = 6, Stance = 8, Throw = 3, Catch = 3, Dash = 3 }

-- How hits feel (client/HitFx, client/HitPop, client/CamFx). knock rows: from, to (studs a
-- second), seconds. kick: degrees, gone in `back` seconds. scale = 0 switches either off.
M.Feel = {
	pokeAnims = { "stab1", "stab2" }, -- the first-person animation for a poke, and for the second of a one-two
	knock = { poke = { 22, 6, 0.14 }, combo = { 30, 8, 0.16 }, power = { 34, 8, 0.18 }, throw = { 26, 6, 0.14 }, bounce = { 18, 4, 0.12 }, scale = 1 },
	kick = { dealt = 1.2, dealtPower = 2, taken = 2.5, takenPower = 3.5, takenYaw = 0.8, blocked = 1, back = 0.18, scale = 1 },
	hitStop = { hit = 0.05, power = 0.08 },
	fov = { hit = -2, hitSeconds = 0.06, dash = 8, flash = -8, flashSeconds = 0.1, rate = 14 },
	marker = { seconds = 0.22, length = 12, thickness = 3, gap = 7 },
	tint = { from = 0.5, seconds = 0.2 },
	wedge = { seconds = 0.9, transparency = 0.3, radius = 110 },
	pitchVary = 0.06,
}

-- Sounds: file in rbxasset://sounds/ (only ones the Roblox install really has), pitch, volume.
M.MoveSounds = {
	swing = { "action_jump.mp3", 1.7, 0.5 }, swingPower = { "action_jump.mp3", 1.3, 0.6 },
	hit = { "action_jump_land.mp3", 1.5, 0.7 }, tick = { "volume_slider.ogg", 1.4, 0.5 },
	heavy = { "action_jump_land.mp3", 0.7, 0.8 }, hurt = { "action_jump_land.mp3", 1.1, 0.7 },
	block = { "volume_slider.ogg", 2, 0.7 }, ready = { "volume_slider.ogg", 1.2, 0.5 },
	throw = { "action_jump.mp3", 1.3, 0.5 }, catch = { "action_get_up.mp3", 1.5, 0.6 },
	dash = { "action_jump.mp3", 1.1, 0.5 }, slide = { "action_get_up.mp3", 0.8, 0.5 },
}

-- What other players see (client/Poses): degrees about X, Y, Z for each R15 joint. legs = each
-- joint's share of the fold angle in a crouch or slide. If a joint bends the wrong way in Studio,
-- flip its sign here.
M.Poses = {
	ease = 0.12, flinchIn = 0.07, flinchOut = 0.22,
	legs = { hip = 1, knee = -2, ankle = 1 },
	crouch = { Waist = { -12, 0, 0 } },
	slide = { Waist = { 20, 0, 0 } },
	guard = { LeftShoulder = { 75, 0, 0 }, LeftElbow = { 55, 0, 0 } },
	charge = { RightShoulder = { -40, 0, 0 }, RightElbow = { 50, 0, 0 }, Waist = { 0, -15, 0 } },
	flinch = { Waist = { 14, 0, 0 }, Neck = { 8, 0, 0 } },
}

-- Every action on every device (client/Inputs binds `codes`, Enum.KeyCode names; client/KeyHints
-- shows key or pad; touch = the on-screen button's label).
M.Inputs = {
	{ id = "poke", key = "Click", pad = "R2", touch = "POKE", text = "Poke with your needle" },
	{ id = "power", key = "Hold click", pad = "Hold R2", touch = "Hold POKE", text = "Power Poke: 2 hearts, pops a Thimble" },
	{ id = "guard", key = "Hold R", pad = "Hold L2", touch = "GUARD", text = "Thimble: blocks pokes and throws", codes = { "R", "ButtonL2" } },
	{ id = "throw", key = "Q", pad = "X", touch = "THROW", text = "Throw (again as it returns: catch)", codes = { "Q", "ButtonX" } },
	{ id = "dash", key = "C", pad = "B", touch = "DASH", text = "Dash", codes = { "C", "ButtonB" } },
	{ id = "crouch", key = "Ctrl or V", pad = "L3", touch = "CROUCH", text = "Crouch (running: slide)", codes = { "LeftControl", "V", "ButtonL3" } },
	{ id = "chest", key = "Hold E", pad = "Hold X", touch = "Hold the prompt", text = "Open a chest" },
	{ id = "inspect", key = "F", pad = "Y", touch = "INSPECT", text = "Inspect your needle", codes = { "F", "ButtonY" } },
	{ id = "jump", key = "Space", pad = "A", touch = "Jump button", text = "Jump" },
}
-- The on-screen buttons (touch only): round, `size` across, `gap` apart, in a grid to the left of
-- Roblox's jump button: a slot { column, row } is `right` + column x (size + gap) from the right
-- edge and `bottom` + row x (size + gap) from the bottom.
M.Touch = { size = 56, gap = 8, right = 210, bottom = 70, slots = { poke = { 0, 0 }, throw = { 1, 0 }, dash = { 2, 0 }, guard = { 0, 1 }, crouch = { 1, 1 }, inspect = { 2, 1 } } }

-- The Practice Yard's extra dummies (server/PracticeMoves): dummy number `guard` holds a Thimble
-- (only a Power Poke hurts it), number `spar` pokes at you every sparEvery seconds after sparTell
-- of warning when you're within sparReach (it never takes your hearts; block it to take one of
-- its). rock = degrees a still dummy tips when hit. bar = a beam to crouch or slide under.
M.Yard = { guard = 4, spar = 5, sparEvery = 2.5, sparTell = 0.5, sparReach = 9, rock = 12, rockSeconds = 0.25, barHeight = 4.6, barWidth = 9 }

return M
```

#### `src/shared/HitMath.luau` (write exactly this; `test_rules.py` mirrors it in Python)

```lua
-- The maths behind the hit checks and the moves' timings: no Instances, only numbers and
-- Vector3s, so dev/test_rules.py can mirror every function. Used by the server's checks
-- (server/CombatPoke, CombatThrow, Fight, Speed, Stance) and the client's slide (client/StanceFx).
local Config = require(script.Parent.Config)

local HitMath = {}
local H = Config.HitCheck

-- How far back (seconds) the server looks for where a target was on the attacker's screen.
function HitMath.window(ping)
	if type(ping) ~= "number" or ping ~= ping then
		ping = 0
	end
	return math.clamp(2 * ping + H.base, H.minWindow, H.maxWindow)
end

-- Is `target` within `range` studs of `from` on the flat, and no more than `maxUp` above or below?
function HitMath.inReach(from, target, range, maxUp)
	local dx, dz = target.X - from.X, target.Z - from.Z
	return dx * dx + dz * dz <= range * range and math.abs(target.Y - from.Y) <= maxUp
end

-- Not behind you (`look` is a flat unit vector); always true within HitCheck.closeFacing studs.
function HitMath.facing(look, from, target)
	local dx, dz = target.X - from.X, target.Z - from.Z
	local d = math.sqrt(dx * dx + dz * dz)
	return d < H.closeFacing or (look.X * dx + look.Z * dz) / d >= 0
end

-- The first of `samples` (newest first, each { p = Vector3 }) a poke from `from` reaches, or nil.
function HitMath.pokeSample(from, samples, range)
	for _, s in ipairs(samples) do
		if HitMath.inReach(from, s.p, range, H.maxUp) then
			return s
		end
	end
	return nil
end

-- A player's centre line for throws: from HitCheck.lo below the root to Stance.hi[stance] above.
function HitMath.body(position, stance)
	local hi = Config.Stance.hi[stance or "stand"] or Config.Stance.hi.stand
	return position + Vector3.new(0, H.lo, 0), position + Vector3.new(0, hi, 0)
end

-- The closest the segments a-b and c-d come, how far along a-b that is (0..1), and along c-d.
function HitMath.segments(a, b, c, d)
	local u, v, w = b - a, d - c, a - c
	local uu, uv, vv, uw, vw = u:Dot(u), u:Dot(v), v:Dot(v), u:Dot(w), v:Dot(w)
	local den = uu * vv - uv * uv
	local s = if den > 1e-9 then math.clamp((uv * vw - vv * uw) / den, 0, 1) else 0
	local t = if vv > 1e-9 then math.clamp((uv * s + vw) / vv, 0, 1) else 0
	s = if uu > 1e-9 then math.clamp((uv * t - uw) / uu, 0, 1) else 0
	return ((a + u * s) - (c + v * t)).Magnitude, s, t
end

-- Does a needle moving from a to b pass within `radius` of the line foot-top? Returns whether,
-- how far along a-b (0..1), and the nearest point on the line.
function HitMath.needleHits(a, b, foot, top, radius)
	local distance, s, t = HitMath.segments(a, b, foot, top)
	return distance <= radius, s, foot + (top - foot) * t
end

-- Walking speed: the faster of the usual and a boost, times the slowest slow.
function HitMath.walkSpeed(base, boost, slow)
	return math.max(base, boost or 0) * (slow or 1)
end

-- A slide's speed `t` seconds in, for someone who walks at `walk`.
function HitMath.slideSpeed(walk, t)
	local S = Config.Stance
	local v0, v1 = math.min(S.slideMaxSpeed, walk + S.slideBoost), S.slideEnd * walk
	return v0 + (v1 - v0) * math.clamp(t / S.slideSeconds, 0, 1)
end

-- After a poke: seconds until the next, and the chain to keep. kind "poke" | "power"; result
-- "hit" | "broken" | "blocked" | "miss"; chain = landed pokes so far in this chain (0 or 1).
function HitMath.cooldown(kind, result, chain)
	if kind == "power" then
		return Config.Power.cooldown, 0
	elseif result == "blocked" then
		return Config.Guard.bounce, 0
	elseif result ~= "hit" then
		return Config.Combat.cooldown, 0
	elseif chain >= 1 then
		return Config.Combo.second, 0
	end
	return Config.Combo.first, 1
end

return HitMath
```

#### `src/shared/FirstPersonMoves.luau` (write exactly this)

```lua
-- First-person animations for the combat and movement moves, kept apart from
-- shared/FirstPerson.luau (the owner pastes a new rig over that file). client/ViewMoves lays these
-- under the rig's own animations: a name the rig also has plays the rig's. The rig's format: keys
-- are offsets from the hold pose, { t, right = { x, y, z, rx, ry, rz }, left = {...}, needle = {...} };
-- x right, y up, -z ahead (studs); rx tips the arm up (degrees). Only x, y, z and rx are used, so
-- they read the same on any hold pose. holds = layers added on top while a move is held.
local Z = { 0, 0, 0, 0, 0, 0 }
return {
	ease = 14, -- how quickly a held layer comes in and goes (per second)
	anims = {
		stab1 = { length = 0.3, keys = { -- a small pull back, then straight out
			{ t = 0, right = Z, left = Z, needle = Z },
			{ t = 0.04, right = { 0.05, -0.03, 0.14, 6, 0, 0 }, left = Z, needle = Z },
			{ t = 0.1, right = { -0.12, 0.14, -0.85, -10, 0, 0 }, left = { 0, -0.03, 0.06, 0, 0, 0 }, needle = Z },
			{ t = 0.16, right = { -0.08, 0.1, -0.55, -6, 0, 0 }, left = Z, needle = Z },
			{ t = 0.3, right = Z, left = Z, needle = Z },
		} },
		stab2 = { length = 0.3, keys = { -- the second of a one-two: across the middle
			{ t = 0, right = Z, left = Z, needle = Z },
			{ t = 0.04, right = { 0.1, 0, 0.12, 4, 0, 0 }, left = Z, needle = Z },
			{ t = 0.1, right = { -0.34, 0.08, -0.8, -8, 0, 0 }, left = { 0, -0.03, 0.06, 0, 0, 0 }, needle = Z },
			{ t = 0.16, right = { -0.22, 0.06, -0.5, -5, 0, 0 }, left = Z, needle = Z },
			{ t = 0.3, right = Z, left = Z, needle = Z },
		} },
		power = { length = 0.45, keys = { -- starts where the charge layer holds the arm
			{ t = 0, right = { 0.12, 0.1, 0.4, 20, 0, 0 }, left = { -0.05, 0.05, -0.1, 0, 0, 0 }, needle = Z },
			{ t = 0.07, right = { -0.18, 0.18, -1.1, -14, 0, 0 }, left = { 0, -0.05, 0.1, 0, 0, 0 }, needle = Z },
			{ t = 0.16, right = { -0.12, 0.12, -0.8, -8, 0, 0 }, left = Z, needle = Z },
			{ t = 0.45, right = Z, left = Z, needle = Z },
		} },
		flinch = { length = 0.3, keys = { -- hit: both arms dip
			{ t = 0, right = Z, left = Z, needle = Z },
			{ t = 0.06, right = { 0.08, -0.14, 0.18, 8, 0, 0 }, left = { -0.08, -0.14, 0.18, 8, 0, 0 }, needle = Z },
			{ t = 0.3, right = Z, left = Z, needle = Z },
		} },
		bounce = { length = 0.4, keys = { -- your poke met a Thimble: the arm recoils
			{ t = 0, right = Z, left = Z, needle = Z },
			{ t = 0.05, right = { 0.1, 0.06, 0.35, 14, 0, 0 }, left = Z, needle = Z },
			{ t = 0.4, right = Z, left = Z, needle = Z },
		} },
		guardHit = { length = 0.25, keys = { -- your Thimble took a hit
			{ t = 0, right = Z, left = Z, needle = Z },
			{ t = 0.05, right = { 0, -0.05, 0.12, 4, 0, 0 }, left = { 0, -0.05, 0.12, 4, 0, 0 }, needle = Z },
			{ t = 0.25, right = Z, left = Z, needle = Z },
		} },
		catch = { length = 0.25, keys = { -- the hand reaches out and closes
			{ t = 0, right = Z, left = Z, needle = Z },
			{ t = 0.06, right = { 0.06, 0.1, -0.2, -6, 0, 0 }, left = Z, needle = Z },
			{ t = 0.12, right = { 0, -0.06, 0.1, 6, 0, 0 }, left = Z, needle = Z },
			{ t = 0.25, right = Z, left = Z, needle = Z },
		} },
	},
	holds = {
		charge = { right = { 0.12, 0.1, 0.4, 20, 0, 0 }, left = { -0.05, 0.05, -0.1, 0, 0, 0 } },
		guard = { right = { -0.3, 0.2, -0.1, -10, 0, 0 }, left = { 0.45, 0.55, -0.3, -20, 0, 0 } },
		crouch = { right = { 0, -0.06, 0.04, 0, 0, 0 }, left = { 0, -0.06, 0.04, 0, 0, 0 } },
		slide = { right = { 0.04, -0.16, 0.1, 8, 0, 0 }, left = { -0.04, -0.16, 0.1, 8, 0, 0 } },
	},
}
```

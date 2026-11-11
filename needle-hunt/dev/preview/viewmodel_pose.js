// viewmodel_pose.js: client/ViewModelPose.luau, function for function and line for line, for
// dev/preview/viewmodel.html. Change one, change the other: the page checks this mirror against
// the game's own answers (VM_DATA.parity, made by viewmodel_data.py) before it draws anything.
// CF stands in for Roblox's CFrame: { p: [x, y, z], m: nine numbers, row-major }; CF.angles is
// CFrame.Angles (Rx * Ry * Rz, radians) and CF.mul is CFrame * CFrame.
(function (root) {
const rad = d => d * Math.PI / 180, clamp = (x, lo, hi) => Math.max(lo, Math.min(hi, x));
const mm = (a, b) => { const r = []; for (let i = 0; i < 3; i++) for (let j = 0; j < 3; j++) r[i * 3 + j] = a[i * 3] * b[j] + a[i * 3 + 1] * b[3 + j] + a[i * 3 + 2] * b[6 + j]; return r; };
const mv = (m, v) => [m[0] * v[0] + m[1] * v[1] + m[2] * v[2], m[3] * v[0] + m[4] * v[1] + m[5] * v[2], m[6] * v[0] + m[7] * v[1] + m[8] * v[2]];
const rx = a => { const s = Math.sin(a), k = Math.cos(a); return [1, 0, 0, 0, k, -s, 0, s, k]; };
const ry = a => { const s = Math.sin(a), k = Math.cos(a); return [k, 0, s, 0, 1, 0, -s, 0, k]; };
const rz = a => { const s = Math.sin(a), k = Math.cos(a); return [k, -s, 0, s, k, 0, 0, 0, 1]; };
const CF = {
  new: (x, y, z) => ({ p: [x || 0, y || 0, z || 0], m: [1, 0, 0, 0, 1, 0, 0, 0, 1] }),
  angles: (a, b, c) => ({ p: [0, 0, 0], m: mm(mm(rx(a), ry(b)), rz(c)) }),
  mul: (...list) => list.reduce((a, b) => ({ p: mv(a.m, b.p).map((v, i) => v + a.p[i]), m: mm(a.m, b.m) })),
  point: (a, v) => mv(a.m, v).map((x, i) => x + a.p[i]),
  inverse: a => { const t = [a.m[0], a.m[3], a.m[6], a.m[1], a.m[4], a.m[7], a.m[2], a.m[5], a.m[8]]; return { p: mv(t, a.p).map(v => -v), m: t }; },
  flat: a => a.p.concat(a.m),
};
const Pose = {};

const PARTS = ['right', 'left', 'needle', 'wrist'];
const ZERO = [0, 0, 0, 0, 0, 0];
const SKIP = { Root: true, Aura: true, AuraShell: true }; // parts of a needle that aren't the needle

const at = (pos, rot, side) => CF.mul(CF.new(pos[0] * side, pos[1], pos[2]), CF.angles(rad(rot[0]), rad(rot[1]) * side, rad(rot[2]) * side));

// A pose ({ pos, rot }) moved by a row of six: pos + its first three, rot + its last three.
Pose.place = (base, off) => CF.mul(CF.new(base.pos[0] + off[0], base.pos[1] + off[1], base.pos[2] + off[2]),
  CF.angles(rad(base.rot[0] + off[3]), rad(base.rot[1] + off[4]), rad(base.rot[2] + off[5])));

// Every animation by name, from a list of anims tables (a later table wins a name).
Pose.merge = (sources) => {
  const anims = {};
  for (const source of sources) for (const name in source) anims[name] = source[name];
  return anims;
};

// The rows at time t of an animation: between the two keys around t, eased (as the rig tool does).
Pose.sample = (anim, t) => {
  const keys = anim.keys;
  let a = keys[0], b = keys[keys.length - 1];
  for (let i = 0; i < keys.length - 1; i++) if (t >= keys[i].t && t <= keys[i + 1].t) { a = keys[i]; b = keys[i + 1]; break; }
  let f = b.t > a.t ? clamp((t - a.t) / (b.t - a.t), 0, 1) : 0;
  f = f * f * (3 - 2 * f);
  const out = {};
  for (const part of PARTS) {
    const from = a[part], to = b[part], row = [0, 0, 0, 0, 0, 0];
    if (from && to) for (let i = 0; i < 6; i++) row[i] = from[i] + (to[i] - from[i]) * f;
    out[part] = row;
  }
  return out;
};

const add = (off, layer, weight) => {
  if (!layer || weight === 0) return;
  for (const part of PARTS) {
    const row = layer[part], into = off[part];
    if (row) for (let i = 0; i < 6; i++) into[i] += row[i] * weight;
  }
};

// Everything that moves the hold pose this frame, as one set of rows: the animation playing
// (already sampled, or null) plus each of FirstPersonRig.motion's layers times its weight.
Pose.offsets = (FP, Rig, playing, w) => {
  const off = { right: [0, 0, 0, 0, 0, 0], left: [0, 0, 0, 0, 0, 0], needle: [0, 0, 0, 0, 0, 0], wrist: [0, 0, 0, 0, 0, 0] };
  const M = Rig.motion;
  add(off, playing, 1);
  add(off, M.breathe, w.breath);
  add(off, M.walk.step, w.step * FP.motion.bob);
  add(off, M.walk.dip, w.dip * FP.motion.bob);
  add(off, M.turn.yaw, w.swayX);
  add(off, M.turn.pitch, w.swayY);
  add(off, M.land, w.land);
  add(off, M.air, w.air);
  add(off, M.away, w.away);
  add(off, M.wall, w.wall);
  return off;
};

// The walk's two weights at a point in the stride (radians), by how much you're walking (0..1).
Pose.walk = (phase, amount) => [Math.sin(phase) * amount, Math.abs(Math.cos(phase)) * amount];

// The landing dip `since` seconds after touching down: in over land.time, then easing away.
Pose.landing = (Rig, since, strength) => {
  const x = Math.max(since, 0) / Rig.motion.land.time;
  return strength * x * Math.exp(1 - x);
};

// How far into the wall pose (0..1): `reach` is how far the needle's point is along the ray to
// it, `distance` how far along that ray a wall is (null: none).
Pose.wall = (Rig, reach, distance) => {
  const W = Rig.motion.wall;
  if (distance === null || distance === undefined) return 0;
  return clamp((reach + W.margin - distance) / Math.max(reach + W.margin - W.near, 0.01), 0, 1);
};

// A value eased towards a target at `rate` a second, the same whatever the frame rate.
Pose.ease = (value, target, rate, dt) => value + (target - value) * (1 - Math.exp(-rate * dt));

// A built needle's back and front ends along its own X, from its parts' boxes.
// model: the parts as viewmodel_data.py wrote them ({ name, size, pos, rot }), about the model's own origin.
Pose.measure = (model) => {
  let back = Infinity, front = -Infinity;
  for (const p of model) {
    if (!SKIP[p.name]) {
      const half = (Math.abs(p.rot[0]) * p.size[0] + Math.abs(p.rot[1]) * p.size[1] + Math.abs(p.rot[2]) * p.size[2]) / 2;
      back = Math.min(back, p.pos[0] - half); front = Math.max(front, p.pos[0] + half);
    }
  }
  return [back, front];
};

// What to multiply a needle's size by so its length lands within FirstPersonRig.grip's limits.
Pose.lengthScale = (Rig, back, front) => {
  const length = Math.max(front - back, 0.01);
  return clamp(length, Rig.grip.minLength, Rig.grip.maxLength) / length;
};

// Where everything is in camera space, at the reference field of view: each forearm's centre
// (right, left), its hand end (endRight, endLeft: the cuff's boxes), the hand bent at the wrist
// (handRight, handLeft: the hand's boxes) and the needle's own origin, set so the point grip.back
// along from its back end sits at FirstPerson.pose.needle in the right hand.
Pose.frames = (FP, Rig, off, needle) => {
  const half = FP.arm.size[1] / 2;
  const right = Pose.place(FP.pose.right, off.right), left = Pose.place(FP.pose.left, off.left);
  const endRight = CF.mul(right, CF.new(0, -half, 0)), endLeft = CF.mul(left, CF.new(0, -half, 0));
  const handRight = CF.mul(endRight, Pose.place(Rig.wrist, off.wrist)), handLeft = CF.mul(endLeft, at(Rig.wrist.pos, Rig.wrist.rot, -1));
  const held = CF.mul(handRight, Pose.place(FP.pose.needle, off.needle), CF.new(-(needle.back + Rig.grip.back), 0, 0));
  return { right, left, endRight, endLeft, handRight, handLeft, needle: held };
};

// One of the hand's (or the cuff's) boxes in its frame: its gripping place, eased to its open
// one by `open` (0..1). side: 1 the right hand, -1 the left (the right hand's mirror image).
Pose.box = (part, open, side) => {
  let pos = part.pos, rot = part.rot || ZERO;
  if (part.open && open > 0) {
    const toPos = part.open.pos || pos, toRot = part.open.rot || rot;
    pos = [pos[0] + (toPos[0] - pos[0]) * open, pos[1] + (toPos[1] - pos[1]) * open, pos[2] + (toPos[2] - pos[2]) * open];
    rot = [rot[0] + (toRot[0] - rot[0]) * open, rot[1] + (toRot[1] - rot[1]) * open, rot[2] + (toRot[2] - rot[2]) * open];
  }
  return at(pos, rot, side);
};

// The same framing at any field of view: the whole view slides along the camera's axis.
Pose.fit = (Rig, fov) => {
  const k = Math.tan(rad(fov) / 2) / Math.tan(rad(Rig.view.refFov) / 2);
  return CF.new(0, 0, Rig.view.pivot * (1 - 1 / k));
};

Pose.ZERO = ZERO;
root.CF = CF; root.Pose = Pose;
})(typeof window !== 'undefined' ? window : module.exports);

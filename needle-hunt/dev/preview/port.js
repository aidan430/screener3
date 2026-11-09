// A line-for-line JavaScript port of needle-hunt's MapKit, MapsA, MapsB and the lobby's geometry,
// so the maps can be previewed outside Roblox. Same sizes, colours, materials and spot rules.
// Parts: { size:[x,y,z], m: THREE.Matrix4, color:[r,g,b], material, shape, transparency, light }
const T = THREE;

function rng(seed) {
  let a = seed >>> 0;
  const next = () => { a |= 0; a = (a + 0x6D2B79F5) | 0; let t = Math.imul(a ^ (a >>> 15), 1 | a); t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t; return ((t ^ (t >>> 14)) >>> 0) / 4294967296; };
  return { NextNumber: (lo, hi) => lo === undefined ? next() : lo + (hi - lo) * next(), NextInteger: (lo, hi) => lo + Math.floor(next() * (hi - lo + 1)) };
}
const cf = (x, y, z) => new T.Matrix4().makeTranslation(x, y, z);
const ang = (x, y, z) => new T.Matrix4().makeRotationFromEuler(new T.Euler(x, y, z, 'XYZ'));
const mul = (...ms) => ms.reduce((a, b) => a.clone().multiply(b));
const pos = (m) => new T.Vector3().setFromMatrixPosition(m);
const rad = (d) => d * Math.PI / 180;
const lookAt = (p, target) => { const m = new T.Matrix4().lookAt(p, target, new T.Vector3(0, 1, 0)); m.setPosition(p); return m; };

const K = {};
K.part = (ctx, p) => { const part = { size: p.Size, m: p.CFrame, color: p.Color, material: p.Material || 'Plastic', shape: p.Shape || 'Block', transparency: p.Transparency || 0, name: p.Name, light: p.light }; ctx.parts.push(part); return part; };
K.at = (ctx, x, y, z) => new T.Vector3(ctx.centre.x + x, ctx.centre.y + ctx.floorY + y, ctx.centre.z + z);
K.spot = (ctx, p, climb) => ctx.spots.push({ p, climb: !!climb });
K.spotsOn = (ctx, part, onTop, around, climb) => {
  const [sx, sy, sz] = part.size;
  for (let i = 0; i < onTop; i++) {
    const x = (ctx.rng.NextNumber() - 0.5) * sx * 0.7, z = (ctx.rng.NextNumber() - 0.5) * sz * 0.7;
    K.spot(ctx, new T.Vector3(x, sy / 2, z).applyMatrix4(part.m), climb);
  }
  for (let i = 0; i < around; i++) {
    const a = ctx.rng.NextNumber() * Math.PI * 2, r = Math.max(sx, sz) / 2 + 1.0, c = pos(part.m);
    K.spot(ctx, new T.Vector3(c.x + Math.cos(a) * r, ctx.centre.y + ctx.floorY, c.z + Math.sin(a) * r));
  }
};
K.ground = (ctx, sx, sz, colour, material) => K.part(ctx, { Name: 'Ground', Size: [sx, 2, sz], CFrame: cf(...K.at(ctx, 0, -1, 0).toArray()), Color: colour, Material: material || 'Grass' });
K.edges = (ctx, hx, hz, colour) => K.part(ctx, { Name: 'Countryside', Size: [900, 2, 900], CFrame: cf(...K.at(ctx, 0, -1.1, 0).toArray()), Color: colour, Material: 'Grass' });
K.spawnAt = (ctx, x, z) => ctx.spawns.push(K.at(ctx, x, 3, z));
K.bale = (ctx, x, y, z, turn, climb) => {
  const m = mul(cf(...K.at(ctx, x, y + 1.25, z).toArray()), ang(0, turn || 0, 0));
  const bale = K.part(ctx, { Name: 'Bale', Size: [4, 2.5, 2.5], CFrame: m, Color: ctx.def.straw, Material: 'Grass' });
  for (const dx of [-1, 1]) K.part(ctx, { Name: 'Twine', Size: [0.15, 2.56, 2.56], CFrame: mul(m, cf(dx, 0, 0)), Color: [150, 100, 60], Material: 'Fabric' });
  K.spotsOn(ctx, bale, 1, y > 0 ? 0 : 1, climb);
  return bale;
};
K.haystack = (ctx, x, z, radius, height) => {
  const layers = 4;
  for (let i = 0; i < layers; i++) {
    const r = radius * (1 - i / (layers + 1.5));
    K.part(ctx, { Name: 'Haystack', Shape: 'Cylinder', Size: [height / layers, r * 2, r * 2], CFrame: mul(cf(...K.at(ctx, x, (i + 0.5) * height / layers, z).toArray()), ang(0, 0, rad(90))), Color: ctx.def.straw, Material: 'Grass' });
  }
  K.part(ctx, { Name: 'Haystack', Shape: 'Ball', Size: [radius * 1.1, radius * 1.1, radius * 1.1], CFrame: cf(...K.at(ctx, x, height, z).toArray()), Color: ctx.def.straw, Material: 'Grass' });
  for (let i = 0; i < 3; i++) { const a = ctx.rng.NextNumber() * Math.PI * 2; K.spot(ctx, K.at(ctx, x + Math.cos(a) * (radius + 1.4), 0, z + Math.sin(a) * (radius + 1.4))); }
};
K.crate = (ctx, x, y, z, size, climb) => {
  size = size || 3;
  const c = K.part(ctx, { Name: 'Crate', Size: [size, size, size], CFrame: mul(cf(...K.at(ctx, x, y + size / 2, z).toArray()), ang(0, ctx.rng.NextNumber() * 0.6, 0)), Color: [150, 106, 64], Material: 'WoodPlanks' });
  K.spotsOn(ctx, c, 1, y > 0 ? 0 : 1, climb);
  return c;
};
K.wall = (ctx, m, size, colour, material) => K.part(ctx, { Name: 'Wall', Size: size, CFrame: m, Color: colour, Material: material || 'WoodPlanks' });
K.fence = (ctx, ax, az, bx, bz) => {
  const a = K.at(ctx, ax, 0, az), b = K.at(ctx, bx, 0, bz), length = b.clone().sub(a).length();
  for (let i = 0; i <= Math.floor(length / 8); i++) { const p = a.clone().lerp(b, i * 8 / length); K.part(ctx, { Name: 'Post', Size: [0.6, 4, 0.6], CFrame: cf(p.x, p.y + 2, p.z), Color: [120, 84, 50], Material: 'Wood' }); }
  for (const h of [1.6, 3.2]) { const mid = a.clone().add(b).multiplyScalar(0.5); mid.y += h; K.part(ctx, { Name: 'Rail', Size: [0.3, 0.4, length], CFrame: lookAt(mid, mid.clone().add(b.clone().sub(a))), Color: [140, 100, 60], Material: 'Wood' }); }
};
K.tree = (ctx, x, z, height, leaf) => {
  const h = height || 14;
  K.part(ctx, { Name: 'Trunk', Shape: 'Cylinder', Size: [h, 1.8, 1.8], CFrame: mul(cf(...K.at(ctx, x, h / 2, z).toArray()), ang(0, 0, rad(90))), Color: [96, 70, 46], Material: 'Wood' });
  for (let i = 1; i <= 3; i++) {
    const o = new T.Vector3((ctx.rng.NextNumber() - 0.5) * 4, h - 1 + i, (ctx.rng.NextNumber() - 0.5) * 4);
    K.part(ctx, { Name: 'Leaves', Shape: 'Ball', Size: [8 - i, 8 - i, 8 - i], CFrame: cf(...K.at(ctx, x, 0, z).add(o).toArray()), Color: leaf || [60, 110, 60], Material: 'Grass' });
  }
  for (let i = 0; i < 2; i++) { const a = ctx.rng.NextNumber() * Math.PI * 2; K.spot(ctx, K.at(ctx, x + Math.cos(a) * 2.2, 0, z + Math.sin(a) * 2.2)); }
};
K.lamp = (ctx, p, colour, range) => K.part(ctx, { Name: 'Lamp', Size: [0.8, 1.2, 0.8], CFrame: cf(p.x, p.y, p.z), Color: colour || [255, 200, 120], Material: 'Neon', light: { range: range || 22, color: colour || [255, 200, 120] } });
K.clutter = (ctx, count, hx, hz) => {
  const s = ctx.def.straw;
  for (let i = 1; i <= count; i++) {
    let p;
    if (i % 2 === 0 && ctx.spots.length) { const sp = ctx.spots[ctx.rng.NextInteger(0, ctx.spots.length - 1)].p; p = sp.clone().add(new T.Vector3((ctx.rng.NextNumber() - 0.5) * 5, 0, (ctx.rng.NextNumber() - 0.5) * 5)); }
    else p = K.at(ctx, (ctx.rng.NextNumber() * 2 - 1) * hx, 0, (ctx.rng.NextNumber() * 2 - 1) * hz);
    const shade = 0.75 + ctx.rng.NextNumber() * 0.4;
    K.part(ctx, { Name: 'Straw', Size: [0.12, 0.08, 0.8 + ctx.rng.NextNumber() * 1.4], CFrame: mul(cf(p.x, p.y + 0.05, p.z), ang(0, ctx.rng.NextNumber() * Math.PI * 2, 0)), Color: s.map(c => Math.min(255, c * shade)), Material: 'SmoothPlastic' });
  }
};
K.moving = (ctx, count, hx, hz) => {
  for (let i = 0; i < count; i++) { const p = K.at(ctx, (ctx.rng.NextNumber() * 2 - 1) * hx, 1.2, (ctx.rng.NextNumber() * 2 - 1) * hz); K.part(ctx, { Name: 'Tumble', Shape: 'Ball', Size: [2.4, 2.4, 2.4], CFrame: cf(p.x, p.y, p.z), Color: ctx.def.straw, Material: 'Grass' }); }
};

const ring = (ctx, count, radius) => { for (let i = 1; i <= count; i++) { const a = i / count * Math.PI * 2; K.spawnAt(ctx, Math.cos(a) * radius, Math.sin(a) * radius); } };
const B = {};
B.field = (ctx) => {
  const r = ctx.rng;
  K.ground(ctx, 140, 140, ctx.def.ground, 'Grass');
  K.edges(ctx, 68, 68, ctx.def.ground);
  for (const e of [[-60, -60, 60, -60], [60, -60, 60, 60], [60, 60, -60, 60], [-60, 60, -60, -60]]) K.fence(ctx, ...e);
  for (let i = 0; i < 9; i++) K.haystack(ctx, r.NextNumber(-48, 48), r.NextNumber(-48, 48), r.NextNumber(5, 7.5), r.NextNumber(9, 13));
  for (let i = 0; i < 7; i++) {
    const x = r.NextNumber(-50, 50), z = r.NextNumber(-50, 50), turn = r.NextNumber() * Math.PI;
    const ax = Math.cos(turn) * 4.1, az = -Math.sin(turn) * 4.1;
    for (let j = -1; j <= 1; j++) K.bale(ctx, x + ax * j, 0, z + az * j, turn);
    K.bale(ctx, x, 2.5, z, turn);
  }
  for (let i = 0; i < 4; i++) {
    const x = r.NextNumber(-45, 45), z = r.NextNumber(-45, 45);
    K.crate(ctx, x, 0.8, z, 4);
    for (const d of [[-2, -2], [2, -2], [-2, 2], [2, 2]]) K.part(ctx, { Name: 'Wheel', Shape: 'Cylinder', Size: [0.4, 1.6, 1.6], CFrame: cf(...K.at(ctx, x + d[0], 0.8, z + d[1]).toArray()), Color: [90, 64, 40], Material: 'Wood' });
  }
  ring(ctx, 8, 30); K.clutter(ctx, ctx.diff.clutter, 55, 55); K.moving(ctx, ctx.diff.moving, 44, 44);
};
B.barn = (ctx) => {
  const r = ctx.rng, W = 76, D = 52, H = 24, wood = [150, 96, 60], dark = [110, 70, 44];
  K.ground(ctx, W + 10, D + 10, ctx.def.ground, 'WoodPlanks');
  for (const w of [[0, -D / 2, W, 1], [0, D / 2, W, 1], [-W / 2, 0, 1, D], [W / 2, 0, 1, D]]) K.wall(ctx, cf(...K.at(ctx, w[0], H / 2, w[1]).toArray()), [w[2], H, w[3]], [168, 70, 56], 'WoodPlanks').name = 'BarnWall';
  K.wall(ctx, cf(...K.at(ctx, 0, H + 0.5, 0).toArray()), [W, 1, D], dark, 'WoodPlanks').name = 'Roof';
  const loftZ = -D / 2 + 7;
  K.wall(ctx, cf(...K.at(ctx, 0, 10, loftZ).toArray()), [W - 2, 1, 14], wood, 'WoodPlanks');
  for (let i = 0; i <= 11; i++) K.wall(ctx, cf(...K.at(ctx, -W / 2 + 4, 0.4 + i * 0.8, loftZ + 7 + 19 - i * 1.6).toArray()), [6, 0.8, 1.7], wood, 'WoodPlanks');
  for (let i = 0; i < 8; i++) K.bale(ctx, r.NextNumber(-W / 2 + 10, W / 2 - 6), 10.5, loftZ + r.NextNumber(-4, 4), r.NextNumber() * 3, true);
  for (let i = 0; i <= 4; i++) K.spot(ctx, K.at(ctx, -W / 2 + 12 + i * 12, 10.5, loftZ + 6), true);
  for (let i = 0; i <= 4; i++) {
    const x = -W / 2 + 12 + i * 13;
    K.wall(ctx, cf(...K.at(ctx, x, 2, D / 2 - 7).toArray()), [0.6, 4, 12], dark, 'WoodPlanks');
    K.bale(ctx, x + 4, 0, D / 2 - 5, Math.PI / 2); K.bale(ctx, x + 4, 2.5, D / 2 - 5, Math.PI / 2);
    K.crate(ctx, x + 7.5, 0, D / 2 - 10, 2.5);
  }
  for (let i = 0; i < 10; i++) K.crate(ctx, r.NextNumber(-W / 2 + 8, W / 2 - 8), 0, r.NextNumber(-4, 10), r.NextNumber(2, 3.5));
  for (let i = 0; i < 6; i++) K.bale(ctx, r.NextNumber(-W / 2 + 8, W / 2 - 8), 0, r.NextNumber(-6, 12), r.NextNumber() * 3);
  for (let i = 0; i <= 3; i++) K.lamp(ctx, K.at(ctx, -W / 2 + 12 + i * 17, H - 3, 0), [255, 196, 120], 30);
  ring(ctx, 8, 12); K.clutter(ctx, ctx.diff.clutter, 32, 32); K.moving(ctx, ctx.diff.moving, 25, 25);
};
B.sunset = (ctx) => {
  const r = ctx.rng;
  K.ground(ctx, 140, 140, ctx.def.ground, 'Grass');
  K.edges(ctx, 68, 68, ctx.def.ground);
  const house = K.wall(ctx, cf(...K.at(ctx, -38, 8, -38).toArray()), [24, 16, 18], [236, 226, 200], 'WoodPlanks');
  const hp = pos(house.m);
  K.part(ctx, { Name: 'Roof', Size: [26, 2, 20], CFrame: cf(hp.x, hp.y + 9, hp.z), Color: [150, 60, 50], Material: 'Slate' });
  K.spotsOn(ctx, house, 0, 4);
  const body = K.wall(ctx, cf(...K.at(ctx, 30, 2.5, -30).toArray()), [8, 3, 4.5], [196, 52, 40], 'SmoothPlastic');
  K.part(ctx, { Name: 'Cab', Size: [3.5, 3.5, 4], CFrame: mul(body.m, cf(-2, 3, 0)), Color: [196, 52, 40], Material: 'SmoothPlastic' });
  for (const w of [[-3, 2.2, 3.6], [3, 1.4, 2.2]]) for (const side of [-1, 1]) K.part(ctx, { Name: 'Wheel', Shape: 'Cylinder', Size: [1, w[2] * 2, w[2] * 2], CFrame: mul(cf(...K.at(ctx, 30 + w[0], w[2], -30 + side * 2.8).toArray()), ang(0, Math.PI / 2, 0)), Color: [40, 40, 44], Material: 'Fabric' });
  K.spotsOn(ctx, body, 1, 4);
  for (let row = 0; row <= 7; row++) {
    const x = -10 + row * 5;
    K.part(ctx, { Name: 'Crops', Size: [2, 1.2, 36], CFrame: cf(...K.at(ctx, x, 0.6, 30).toArray()), Color: [90, 140, 60], Material: 'Grass' });
    for (let k = 0; k < 2; k++) K.spot(ctx, K.at(ctx, x + 2.5, 0, 30 + r.NextNumber(-16, 16)));
  }
  K.part(ctx, { Name: 'Pole', Size: [0.5, 9, 0.5], CFrame: cf(...K.at(ctx, 7, 4.5, 30).toArray()), Color: [120, 84, 50], Material: 'Wood' });
  K.part(ctx, { Name: 'Scarecrow', Shape: 'Ball', Size: [2.4, 2.4, 2.4], CFrame: cf(...K.at(ctx, 7, 9.5, 30).toArray()), Color: [214, 186, 140], Material: 'Fabric' });
  for (let i = 0; i < 7; i++) K.haystack(ctx, r.NextNumber(-50, 50), r.NextNumber(-50, 10), r.NextNumber(5, 7), r.NextNumber(9, 12));
  for (let i = 0; i < 10; i++) K.bale(ctx, r.NextNumber(-50, 50), 0, r.NextNumber(-50, 50), r.NextNumber() * 3);
  for (const e of [[-60, 60, 60, 60], [60, -60, 60, 60]]) K.fence(ctx, ...e);
  ring(ctx, 8, 26); K.clutter(ctx, ctx.diff.clutter, 55, 55); K.moving(ctx, ctx.diff.moving, 44, 44);
};
B.forest = (ctx) => {
  const r = ctx.rng;
  K.ground(ctx, 130, 130, ctx.def.ground, 'Grass');
  K.edges(ctx, 63, 63, ctx.def.ground);
  for (let i = 0; i < 26; i++) K.tree(ctx, r.NextNumber(-55, 55), r.NextNumber(-55, 55), r.NextNumber(14, 22), [40, 76, 50]);
  for (let i = 0; i < 9; i++) {
    const x = r.NextNumber(-48, 48), z = r.NextNumber(-48, 48), turn = r.NextNumber() * Math.PI;
    const log = K.part(ctx, { Name: 'Log', Shape: 'Cylinder', Size: [r.NextNumber(8, 14), 2.2, 2.2], CFrame: mul(cf(...K.at(ctx, x, 1.1, z).toArray()), ang(0, turn, 0)), Color: [92, 66, 44], Material: 'Wood' });
    for (let k = 0; k < 2; k++) K.spot(ctx, new T.Vector3(r.NextNumber(-3, 3), 1.1, 0).applyMatrix4(log.m));
    K.spotsOn(ctx, log, 0, 2);
  }
  for (let i = 0; i < 12; i++) { const s = r.NextNumber(2.5, 5); const rock = K.part(ctx, { Name: 'Rock', Shape: 'Ball', Size: [s, s, s], CFrame: cf(...K.at(ctx, r.NextNumber(-50, 50), 0.6, r.NextNumber(-50, 50)).toArray()), Color: [96, 104, 100], Material: 'Slate' }); K.spotsOn(ctx, rock, 0, 2); }
  for (let i = 0; i < 16; i++) {
    const x = r.NextNumber(-50, 50), z = r.NextNumber(-50, 50);
    K.part(ctx, { Name: 'Stalk', Size: [0.3, 0.8, 0.3], CFrame: cf(...K.at(ctx, x, 0.4, z).toArray()), Color: [230, 226, 210], Material: 'SmoothPlastic' });
    K.part(ctx, { Name: 'Cap', Shape: 'Ball', Size: [1.1, 1.1, 1.1], CFrame: cf(...K.at(ctx, x, 0.9, z).toArray()), Color: [120, 200, 255], Material: 'Neon' });
  }
  for (let i = 1; i <= 6; i++) {
    const a = i / 6 * Math.PI * 2;
    K.part(ctx, { Name: 'LanternPost', Size: [0.4, 6, 0.4], CFrame: cf(...K.at(ctx, Math.cos(a) * 30, 3, Math.sin(a) * 30).toArray()), Color: [60, 50, 40], Material: 'Wood' });
    K.lamp(ctx, K.at(ctx, Math.cos(a) * 30, 6.4, Math.sin(a) * 30), [255, 190, 110], 34);
  }
  ring(ctx, 8, 20); K.clutter(ctx, ctx.diff.clutter, 52, 52); K.moving(ctx, ctx.diff.moving, 40, 40);
};
B.attic = (ctx) => {
  const r = ctx.rng, L = 72, Wd = 32, H = 20, wood = [132, 98, 66], dark = [96, 70, 48];
  K.ground(ctx, L + 6, Wd + 6, ctx.def.ground, 'WoodPlanks');
  const slope = 20, tilt = rad(55), run = slope / 2 * Math.cos(tilt), rise = slope / 2 * Math.sin(tilt);
  for (const side of [-1, 1]) {
    K.wall(ctx, mul(cf(...K.at(ctx, 0, 3 + rise, side * (Wd / 2 - run)).toArray()), ang(side * tilt, 0, 0)), [L, 1, slope], dark, 'WoodPlanks').name = 'Roof';
    K.wall(ctx, cf(...K.at(ctx, 0, 1.5, side * Wd / 2).toArray()), [L, 3, 1], wood, 'WoodPlanks');
  }
  K.wall(ctx, cf(...K.at(ctx, 0, 3 + slope * Math.sin(tilt) + 0.2, 0).toArray()), [L, 1, Wd - 4 * run + 2], dark, 'WoodPlanks').name = 'Roof';
  for (const side of [-1, 1]) {
    K.wall(ctx, cf(...K.at(ctx, side * L / 2, H / 2, 0).toArray()), [1, H, Wd], wood, 'WoodPlanks').name = 'EndWall';
    K.part(ctx, { Name: 'Window', Shape: 'Cylinder', Size: [1.2, 6, 6], CFrame: cf(...K.at(ctx, side * (L / 2 - 0.2), 9, 0).toArray()), Color: [255, 236, 190], Material: 'Neon', light: { range: 50, color: [255, 226, 170] } });
  }
  for (let i = 0; i < 22; i++) {
    const x = r.NextNumber(-L / 2 + 5, L / 2 - 5), z = r.NextNumber(-Wd / 2 + 4, Wd / 2 - 4), s = r.NextNumber(2, 3.4);
    K.crate(ctx, x, 0, z, s);
    if (r.NextNumber() < 0.4) K.crate(ctx, x, s, z, s * 0.8);
  }
  for (let i = 0; i < 5; i++) { const t = K.part(ctx, { Name: 'Trunk', Size: [4.5, 2.6, 2.6], CFrame: mul(cf(...K.at(ctx, r.NextNumber(-30, 30), 1.3, r.NextNumber(-10, 10)).toArray()), ang(0, r.NextNumber() * Math.PI, 0)), Color: [110, 70, 46], Material: 'Wood' }); K.spotsOn(ctx, t, 1, 1); }
  const top = K.part(ctx, { Name: 'Table', Size: [8, 0.5, 4.5], CFrame: cf(...K.at(ctx, 6, 3, 2).toArray()), Color: wood, Material: 'Wood' });
  for (const d of [[-3.6, -1.9], [3.6, -1.9], [-3.6, 1.9], [3.6, 1.9]]) K.part(ctx, { Name: 'Leg', Size: [0.5, 2.8, 0.5], CFrame: cf(...K.at(ctx, 6 + d[0], 1.4, 2 + d[1]).toArray()), Color: dark, Material: 'Wood' });
  K.spotsOn(ctx, top, 3, 2);
  const wardrobe = K.wall(ctx, cf(...K.at(ctx, -26, 4.5, -10).toArray()), [6, 9, 3], dark, 'Wood'); K.spotsOn(ctx, wardrobe, 0, 3);
  for (let i = 0; i < 4; i++) { const sheet = K.part(ctx, { Name: 'DustSheet', Size: [r.NextNumber(4, 6), r.NextNumber(3, 4.5), r.NextNumber(3, 4)], CFrame: cf(...K.at(ctx, r.NextNumber(-28, 28), 2, r.NextNumber(-9, 9)).toArray()), Color: [226, 222, 210], Material: 'Fabric' }); K.spotsOn(ctx, sheet, 1, 2); }
  for (let i = 0; i <= 2; i++) K.lamp(ctx, K.at(ctx, -24 + i * 24, 11, 0), [255, 214, 150], 26);
  ring(ctx, 8, 8); K.clutter(ctx, ctx.diff.clutter, L / 2 - 4, Wd / 2 - 4); K.moving(ctx, ctx.diff.moving, L / 2 - 8, Wd / 2 - 6);
};
// The lobby's geometry (LobbyBuilder), with its signs' words as textures.
B.lobby = (ctx) => {
  K.ground(ctx, 260, 260, [104, 160, 76], 'Grass');
  K.edges(ctx, 125, 125, [104, 160, 76]);
  K.part(ctx, { Name: 'Plaza', Size: [90, 0.4, 90], CFrame: cf(...K.at(ctx, 0, 0.2, 0).toArray()), Color: [170, 128, 86], Material: 'WoodPlanks' });
  K.part(ctx, { Name: 'Spawn', Size: [12, 1, 12], CFrame: cf(...K.at(ctx, 0, 0.5, 30).toArray()), Color: [196, 150, 92], Material: 'WoodPlanks' });
  for (const e of [[-45, -45, 45, -45], [45, -45, 45, 45], [-45, -45, -45, 45]]) K.fence(ctx, ...e);
  const board = (name, x, y, z, w, h, sign) => {
    const p = K.at(ctx, x, y, z), m = lookAt(p, K.at(ctx, 0, y, 10));
    const b = K.part(ctx, { Name: name, Size: [w, h, 0.6], CFrame: m, Color: [120, 84, 50], Material: 'WoodPlanks' });
    b.sign = sign;
    for (const dx of [-w / 2 + 0.6, w / 2 - 0.6]) K.part(ctx, { Name: 'Post', Size: [0.8, h + y, 0.8], CFrame: mul(m, cf(dx, -y / 2, 0.5)), Color: [96, 66, 40], Material: 'Wood' });
  };
  board('TitleSign', 0, 12, -38, 40, 9, 'title');
  K.part(ctx, { Name: 'BigNeedle', Shape: 'Cylinder', Size: [16, 0.6, 0.6], CFrame: mul(cf(...K.at(ctx, 0, 21.6, -38).toArray()), ang(0, 0, rad(-12))), Color: [210, 214, 224], Material: 'Metal' });
  K.part(ctx, { Name: 'PlayPad', Shape: 'Cylinder', Size: [0.4, 18, 18], CFrame: mul(cf(...K.at(ctx, 0, 0.6, 6).toArray()), ang(0, 0, rad(90))), Color: [255, 206, 80], Material: 'Neon', light: { range: 30, color: [255, 206, 80] } });
  board('Leaderboard', -34, 9, -8, 18, 16, 'leaderboard');
  board('DailyChallenge', 34, 9, -8, 18, 12, 'daily');
  const stall = (name, x, z, colour, label) => {
    const base = K.at(ctx, x, 0, z);
    K.part(ctx, { Name: name, Size: [10, 3, 5], CFrame: cf(base.x, 1.5, base.z), Color: [150, 106, 64], Material: 'WoodPlanks' });
    for (const dx of [-4.6, 4.6]) K.part(ctx, { Name: 'Post', Size: [0.6, 8, 0.6], CFrame: cf(base.x + dx, 4, base.z - 2), Color: [96, 66, 40], Material: 'Wood' });
    const roof = K.part(ctx, { Name: 'Awning', Size: [11, 0.5, 6], CFrame: mul(cf(base.x, 8.2, base.z - 0.5), ang(rad(-12), 0, 0)), Color: colour, Material: 'Fabric' });
    roof.label = label;
  };
  ctx.hall = [];
  board('HallSign', 0, 4.4, -31, 16, 2.6, 'hall');
  const rims = [[200, 206, 216], [255, 200, 70], [205, 140, 90]];
  [-13, 0, 13].forEach((x, i) => {
    const h = i === 1 ? 4.2 : 3.2, base = K.at(ctx, x, 0, -24);
    K.part(ctx, { Name: 'Pedestal', Shape: 'Cylinder', Size: [h, 6, 6], CFrame: mul(cf(base.x, h / 2, base.z), ang(0, 0, rad(90))), Color: [236, 230, 214], Material: 'Marble' });
    K.part(ctx, { Name: 'Rim', Shape: 'Cylinder', Size: [0.35, 6.4, 6.4], CFrame: mul(cf(base.x, h - 0.1, base.z), ang(0, 0, rad(90))), Color: rims[i], Material: 'Metal' });
    ctx.hall.push({ top: new T.Vector3(base.x, h + 2.6, base.z), tag: new T.Vector3(base.x, h + 5.4, base.z), slot: i });
  });
  stall('ShopStall', -18, 30, [196, 64, 50], 'SHOP');
  stall('Wardrobe', 18, 30, [76, 106, 170], 'INVENTORY');
  for (const h of [[-70, -60], [70, -64], [-80, 40], [82, 50], [0, -90], [-50, 90], [56, 96]]) K.haystack(ctx, h[0], h[1], 7, 12);
  for (const b of [[-30, 0, -30], [30, 0, -32], [-40, 0, 36], [40, 0, 38]]) K.bale(ctx, b[0], b[1], b[2], ctx.rng.NextNumber() * 3);
};
window.NH = { B, K, rng, cf, ang, mul, pos };

// A port of server/MazeKit.luau and the maze map builders (MapsA, MapsB), for previews.
(() => {
const { B, K, cf, ang, mul } = window.NH; const T = 2;
const lookAt = (p, target) => { const m = new THREE.Matrix4().lookAt(p, target, new THREE.Vector3(0, 1, 0)); m.setPosition(p); return m; };
function wall(ctx, style, a, b, height) {
  const mid = a.clone().add(b).multiplyScalar(0.5), len = b.clone().sub(a).length() + T, along = lookAt(mid, mid.clone().add(b.clone().sub(a)));
  if (style === 'hedge' || style === 'thicket') {
    K.part(ctx, { Name: 'MazeWall', Size: [T, height, len], CFrame: mul(along, cf(0, height / 2, 0)), Color: style === 'hedge' ? [58, 112, 56] : [34, 64, 40], Material: 'Grass' });
    if (style === 'thicket') for (let i = 0; i <= Math.floor(len / 5); i++) { const s = ctx.rng.NextNumber(2.5, 4); K.part(ctx, { Name: 'Bush', Shape: 'Ball', Size: [s, s, s], CFrame: mul(along, cf(0, height - 0.3, -len / 2 + i * 5 + 2)), Color: [40, 76, 46], Material: 'Grass' }); }
  } else if (style === 'bales') {
    const st = ctx.def.straw;
    for (let lv = 0; lv <= 3; lv++) { const sh = 0.86 + (lv % 2) * 0.1, skew = lv % 2;
      K.part(ctx, { Name: 'MazeWall', Size: [T + 0.5, 2.5, len - skew], CFrame: mul(along, cf(0, 1.25 + lv * 2.5, 0)), Color: st.map(c => c * sh), Material: 'Grass' });
      for (let i = 0; i < Math.floor(len / 4); i++) K.part(ctx, { Name: 'Twine', Size: [T + 0.56, 2.52, 0.15], CFrame: mul(along, cf(0, 1.25 + lv * 2.5, -len / 2 + skew / 2 + 2 + i * 4)), Color: [150, 100, 60], Material: 'Fabric' }); }
  } else if (style === 'planks') {
    K.part(ctx, { Name: 'MazeWall', Size: [T * 0.6, height, len], CFrame: mul(along, cf(0, height / 2, 0)), Color: [128, 82, 50], Material: 'WoodPlanks' });
    for (const z of [-len / 2 + 0.4, len / 2 - 0.4]) K.part(ctx, { Name: 'Post', Size: [1.2, height + 0.6, 1.2], CFrame: mul(along, cf(0, (height + 0.6) / 2, z)), Color: [96, 62, 38], Material: 'Wood' });
  } else {
    const n = Math.max(1, Math.floor(len / 3)), s = len / n;
    for (let i = 0; i < n; i++) for (let lv = 0; lv <= Math.floor(height / s); lv++) K.part(ctx, { Name: 'MazeWall', Size: [T + 0.6, s, s], CFrame: mul(along, cf(0, s / 2 + lv * s, -len / 2 + s / 2 + i * s), ang(0, ctx.rng.NextNumber(-0.08, 0.08), 0)), Color: [150 - lv * 8, 106 - lv * 6, 64], Material: 'WoodPlanks' });
  }
}
function build(ctx, o) {
  const { cols, rows, size } = o, rng = ctx.rng, east = [], south = [], seen = [];
  for (let c = 1; c <= cols; c++) { east[c] = []; south[c] = []; seen[c] = []; for (let r = 1; r <= rows; r++) { east[c][r] = c < cols; south[c][r] = r < rows; } }
  const stack = [[rng.NextInteger(1, cols), rng.NextInteger(1, rows)]]; seen[stack[0][0]][stack[0][1]] = true;
  while (stack.length) { const [c, r] = stack[stack.length - 1]; const opts = [];
    for (const d of [[1, 0], [-1, 0], [0, 1], [0, -1]]) { const nc = c + d[0], nr = r + d[1]; if (nc >= 1 && nc <= cols && nr >= 1 && nr <= rows && !seen[nc][nr]) opts.push([nc, nr, d]); }
    if (!opts.length) stack.pop(); else { const [nc, nr, d] = opts[rng.NextInteger(0, opts.length - 1)];
      if (d[0] === 1) east[c][r] = false; else if (d[0] === -1) east[nc][nr] = false; else if (d[1] === 1) south[c][r] = false; else south[nc][nr] = false;
      seen[nc][nr] = true; stack.push([nc, nr]); } }
  for (let c = 1; c <= cols; c++) for (let r = 1; r <= rows; r++) { if (east[c][r] && rng.NextNumber() < o.loops) east[c][r] = false; if (south[c][r] && rng.NextNumber() < o.loops) south[c][r] = false; }
  const rooms = [], taken = [];
  for (let k = 0; k < o.rooms * 6 && rooms.length < o.rooms; k++) { const c = rng.NextInteger(1, cols - 1), r = rng.NextInteger(1, rows - 1);
    if (taken.every(q => Math.abs(q[0] - c) >= 3 || Math.abs(q[1] - r) >= 3)) { east[c][r] = east[c][r + 1] = south[c][r] = south[c + 1][r] = false; taken.push([c, r]); rooms.push({ c, r }); } }
  const x0 = (o.ox || 0) - cols * size / 2, z0 = (o.oz || 0) - rows * size / 2, at = (x, z) => K.at(ctx, x, 0, z);
  const centre = (c, r) => [x0 + (c - 0.5) * size, z0 + (r - 0.5) * size];
  for (let c = 1; c <= cols; c++) for (let r = 1; r <= rows; r++) { const x = x0 + c * size, z = z0 + r * size;
    if (east[c][r]) wall(ctx, o.style, at(x, z - size), at(x, z), o.height); if (south[c][r]) wall(ctx, o.style, at(x - size, z), at(x, z), o.height); }
  const x1 = x0 + cols * size, z1 = z0 + rows * size;
  for (const w of [[x0, z0, x1, z0], [x0, z1, x1, z1], [x0, z0, x0, z1], [x1, z0, x1, z1]]) wall(ctx, o.style, at(w[0], w[1]), at(w[2], w[3]), o.height);
  const maze = { size, cells: [], rooms: [] }, inRoom = {};
  for (const rm of rooms) { const [cx, cz] = centre(rm.c, rm.r); maze.rooms.push({ x: cx + size / 2, z: cz + size / 2 }); for (const d of [[0, 0], [1, 0], [0, 1], [1, 1]]) inRoom[(rm.c + d[0]) + ',' + (rm.r + d[1])] = true; }
  for (let c = 1; c <= cols; c++) for (let r = 1; r <= rows; r++) if (!inRoom[c + ',' + r]) { const [x, z] = centre(c, r); maze.cells.push({ c, r, x, z }); K.spot(ctx, at(x + size / 2 - 2, z)); }
  maze.randomCell = () => maze.cells[rng.NextInteger(0, maze.cells.length - 1)];
  maze.spawns = (n) => { for (let i = 0; i < n; i++) { const cell = maze.randomCell(); K.spawnAt(ctx, cell.x, cell.z); } };
  return maze;
}
const inCell = (ctx, maze, margin) => { const cell = maze.randomCell(), room = maze.size / 2 - 1 - (margin || 1.5); return [cell.x + ctx.rng.NextNumber(-room, room), cell.z + ctx.rng.NextNumber(-room, room)]; };
const finish = (ctx, half) => { K.clutter(ctx, ctx.diff.clutter, half, half); K.moving(ctx, ctx.diff.moving, half * 0.8, half * 0.8); };
B.field = (ctx) => { const r = ctx.rng; K.ground(ctx, 140, 140, ctx.def.ground, 'Grass'); K.edges(ctx, 68, 68, ctx.def.ground);
  const maze = build(ctx, { cols: 8, rows: 8, size: 16, height: 10, style: 'hedge', loops: 0.15, rooms: 3 });
  for (const rm of maze.rooms) K.haystack(ctx, rm.x + r.NextNumber(-3, 3), rm.z + r.NextNumber(-3, 3), r.NextNumber(5, 6.5), r.NextNumber(9, 12));
  for (let i = 0; i < 14; i++) { const [x, z] = inCell(ctx, maze, 2.5); K.bale(ctx, x, 0, z, r.NextNumber() * Math.PI); }
  for (let i = 0; i < 6; i++) { const [x, z] = inCell(ctx, maze, 3); K.crate(ctx, x, 0, z, 2.5); }
  maze.spawns(8); finish(ctx, 62); };
B.barn = (ctx) => { const r = ctx.rng, W = 76, D = 52, H = 24, wood = [150, 96, 60], dark = [110, 70, 44];
  K.ground(ctx, W + 10, D + 10, ctx.def.ground, 'WoodPlanks');
  for (const w of [[0, -D / 2, W, 1], [0, D / 2, W, 1], [-W / 2, 0, 1, D], [W / 2, 0, 1, D]]) K.wall(ctx, cf(...K.at(ctx, w[0], H / 2, w[1]).toArray()), [w[2], H, w[3]], [168, 70, 56], 'WoodPlanks').name = 'BarnWall';
  K.wall(ctx, cf(...K.at(ctx, 0, H + 0.5, 0).toArray()), [W, 1, D], dark, 'WoodPlanks').name = 'Roof';
  const loftZ = -D / 2 + 7; K.wall(ctx, cf(...K.at(ctx, 0, 10, loftZ).toArray()), [W - 2, 1, 14], wood, 'WoodPlanks').name = 'Loft';
  for (let i = 0; i <= 11; i++) K.wall(ctx, cf(...K.at(ctx, -W / 2 + 3.5, 0.4 + i * 0.8, loftZ + 7 + 19 - i * 1.6).toArray()), [5, 0.8, 1.7], wood, 'WoodPlanks');
  for (let i = 0; i < 8; i++) K.bale(ctx, r.NextNumber(-W / 2 + 10, W / 2 - 6), 10.5, loftZ + r.NextNumber(-4, 4), r.NextNumber() * 3, true);
  const maze = build(ctx, { cols: 6, rows: 4, size: 11, height: 8, style: 'planks', loops: 0.2, rooms: 1, ox: 3.5, oz: 0 });
  for (let i = 0; i < 10; i++) { const [x, z] = inCell(ctx, maze, 1.5); K.crate(ctx, x, 0, z, r.NextNumber(1.8, 2.6)); }
  for (let i = 0; i < 6; i++) { const [x, z] = inCell(ctx, maze, 2.5); K.bale(ctx, x, 0, z, r.NextNumber() * 3); }
  for (let i = 0; i <= 3; i++) K.lamp(ctx, K.at(ctx, -W / 2 + 12 + i * 17, H - 3, 6), [255, 196, 120], 30);
  maze.spawns(8); finish(ctx, 32); };
B.sunset = (ctx) => { const r = ctx.rng; K.ground(ctx, 140, 140, ctx.def.ground, 'Grass'); K.edges(ctx, 68, 68, ctx.def.ground);
  const maze = build(ctx, { cols: 8, rows: 8, size: 16, height: 10, style: 'bales', loops: 0.15, rooms: 3 });
  maze.rooms.forEach((rm, i) => {
    if (i === 0) { const house = K.wall(ctx, cf(...K.at(ctx, rm.x, 7, rm.z).toArray()), [16, 14, 12], [236, 226, 200], 'WoodPlanks'); K.part(ctx, { Name: 'Roof', Size: [18, 2, 14], CFrame: cf(...K.at(ctx, rm.x, 15, rm.z).toArray()), Color: [150, 60, 50], Material: 'Slate' }); }
    else if (i === 1) { const body = K.wall(ctx, cf(...K.at(ctx, rm.x, 2.5, rm.z).toArray()), [8, 3, 4.5], [196, 52, 40], 'SmoothPlastic'); K.part(ctx, { Name: 'Cab', Size: [3.5, 3.5, 4], CFrame: mul(body.m, cf(-2, 3, 0)), Color: [196, 52, 40], Material: 'SmoothPlastic' });
      for (const w of [[-3, 2.2], [3, 1.4]]) for (const side of [-1, 1]) K.part(ctx, { Name: 'Wheel', Shape: 'Cylinder', Size: [1, w[1] * 2, w[1] * 2], CFrame: mul(cf(...K.at(ctx, rm.x + w[0], w[1], rm.z + side * 2.8).toArray()), ang(0, Math.PI / 2, 0)), Color: [40, 40, 44], Material: 'Fabric' }); }
    else { for (let row = 0; row <= 4; row++) K.part(ctx, { Name: 'Crops', Size: [2, 1.2, 22], CFrame: cf(...K.at(ctx, rm.x - 10 + row * 5, 0.6, rm.z).toArray()), Color: [90, 140, 60], Material: 'Grass' });
      K.part(ctx, { Name: 'Pole', Size: [0.5, 9, 0.5], CFrame: cf(...K.at(ctx, rm.x + 1, 4.5, rm.z).toArray()), Color: [120, 84, 50], Material: 'Wood' });
      K.part(ctx, { Name: 'Scarecrow', Shape: 'Ball', Size: [2.4, 2.4, 2.4], CFrame: cf(...K.at(ctx, rm.x + 1, 9.5, rm.z).toArray()), Color: [214, 186, 140], Material: 'Fabric' }); } });
  for (let i = 0; i < 10; i++) { const [x, z] = inCell(ctx, maze, 2.5); K.bale(ctx, x, 0, z, r.NextNumber() * 3); }
  maze.spawns(8); finish(ctx, 62); };
B.forest = (ctx) => { const r = ctx.rng; K.ground(ctx, 130, 130, ctx.def.ground, 'Grass'); K.edges(ctx, 63, 63, ctx.def.ground);
  const maze = build(ctx, { cols: 8, rows: 8, size: 15, height: 10, style: 'thicket', loops: 0.18, rooms: 3 });
  for (const rm of maze.rooms) { K.tree(ctx, rm.x, rm.z, r.NextNumber(16, 22), [40, 76, 50]);
    K.part(ctx, { Name: 'LanternPost', Size: [0.4, 6, 0.4], CFrame: cf(...K.at(ctx, rm.x + 6, 3, rm.z + 6).toArray()), Color: [60, 50, 40], Material: 'Wood' }); K.lamp(ctx, K.at(ctx, rm.x + 6, 6.4, rm.z + 6), [255, 190, 110], 34);
    K.part(ctx, { Name: 'Log', Shape: 'Cylinder', Size: [10, 2.2, 2.2], CFrame: mul(cf(...K.at(ctx, rm.x - 5, 1.1, rm.z - 4).toArray()), ang(0, r.NextNumber() * Math.PI, 0)), Color: [92, 66, 44], Material: 'Wood' }); }
  for (let i = 0; i < 8; i++) { const [x, z] = inCell(ctx, maze, 2.5); K.tree(ctx, x, z, r.NextNumber(14, 20), [40, 76, 50]); }
  for (let i = 0; i < 10; i++) { const [x, z] = inCell(ctx, maze, 2.5); const s = r.NextNumber(2.5, 4); K.part(ctx, { Name: 'Rock', Shape: 'Ball', Size: [s, s, s], CFrame: cf(...K.at(ctx, x, 0.6, z).toArray()), Color: [96, 104, 100], Material: 'Slate' }); }
  for (let i = 0; i < 18; i++) { const [x, z] = inCell(ctx, maze, 1.5); K.part(ctx, { Name: 'Stalk', Size: [0.3, 0.8, 0.3], CFrame: cf(...K.at(ctx, x, 0.4, z).toArray()), Color: [230, 226, 210], Material: 'SmoothPlastic' }); K.part(ctx, { Name: 'Cap', Shape: 'Ball', Size: [1.1, 1.1, 1.1], CFrame: cf(...K.at(ctx, x, 0.9, z).toArray()), Color: [120, 200, 255], Material: 'Neon' }); }
  maze.spawns(8); finish(ctx, 58); };
B.attic = (ctx) => { const r = ctx.rng, L = 80, Wd = 48, H = 20, wood = [132, 98, 66], dark = [96, 70, 48];
  K.ground(ctx, L + 6, Wd + 6, ctx.def.ground, 'WoodPlanks');
  const slope = 20, tilt = 55 * Math.PI / 180, run = slope / 2 * Math.cos(tilt), rise = slope / 2 * Math.sin(tilt);
  for (const side of [-1, 1]) { K.wall(ctx, mul(cf(...K.at(ctx, 0, 3 + rise, side * (Wd / 2 - run)).toArray()), ang(side * tilt, 0, 0)), [L, 1, slope], dark, 'WoodPlanks').name = 'Roof'; K.wall(ctx, cf(...K.at(ctx, 0, 1.5, side * Wd / 2).toArray()), [L, 3, 1], wood, 'WoodPlanks'); }
  K.wall(ctx, cf(...K.at(ctx, 0, 3 + slope * Math.sin(tilt) + 0.2, 0).toArray()), [L, 1, Wd - 4 * run + 2], dark, 'WoodPlanks').name = 'Roof';
  for (const side of [-1, 1]) { K.wall(ctx, cf(...K.at(ctx, side * L / 2, H / 2, 0).toArray()), [1, H, Wd], wood, 'WoodPlanks').name = 'EndWall'; K.part(ctx, { Name: 'Window', Shape: 'Cylinder', Size: [1.2, 6, 6], CFrame: cf(...K.at(ctx, side * (L / 2 - 0.2), 12, 0).toArray()), Color: [255, 236, 190], Material: 'Neon', light: { range: 60, color: [255, 226, 170] } }); }
  const maze = build(ctx, { cols: 8, rows: 3, size: 9.5, height: 6, style: 'crates', loops: 0.22, rooms: 1 });
  for (const rm of maze.rooms) { K.part(ctx, { Name: 'Table', Size: [7, 0.5, 4], CFrame: cf(...K.at(ctx, rm.x, 3, rm.z).toArray()), Color: wood, Material: 'Wood' }); for (const d of [[-3.1, -1.6], [3.1, -1.6], [-3.1, 1.6], [3.1, 1.6]]) K.part(ctx, { Name: 'Leg', Size: [0.5, 2.8, 0.5], CFrame: cf(...K.at(ctx, rm.x + d[0], 1.4, rm.z + d[1]).toArray()), Color: dark, Material: 'Wood' }); }
  for (let i = 0; i < 4; i++) { const [x, z] = inCell(ctx, maze, 2); K.part(ctx, { Name: 'Trunk', Size: [3.4, 2.4, 2.2], CFrame: mul(cf(...K.at(ctx, x, 1.2, z).toArray()), ang(0, r.NextNumber() * Math.PI, 0)), Color: [110, 70, 46], Material: 'Wood' }); }
  for (let i = 0; i < 3; i++) { const [x, z] = inCell(ctx, maze, 2); K.part(ctx, { Name: 'DustSheet', Size: [3.5, 3.5, 3.3], CFrame: cf(...K.at(ctx, x, 1.8, z).toArray()), Color: [226, 222, 210], Material: 'Fabric' }); }
  for (let i = 0; i <= 3; i++) K.lamp(ctx, K.at(ctx, -30 + i * 20, 15, 0), [255, 214, 150], 30);
  maze.spawns(8); finish(ctx, 36); };
})();

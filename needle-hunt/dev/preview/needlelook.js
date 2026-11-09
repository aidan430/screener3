// needlelook.js: the port of shared/NeedleLook.luau (from needle.html), for scenes
const lin = (c) => new THREE.Color(c[0] / 255, c[1] / 255, c[2] / 255).convertSRGBToLinear();
const hsv = (h, s, v) => { const c = new THREE.Color(); c.setHSL(h, s, v * (1 - s / 2)); return c.convertSRGBToLinear(); };
function buildNeedle(DATA, typeId, skinId, FAT) {
  FAT = FAT || 1;
  const skin = DATA.skins.find(s => s.id === skinId);
  const group = new THREE.Group();
  const A = lin(skin.colours[0]), B = lin(skin.colours[1] || skin.colours[0]);
  const colourAt = (i, n) => {
    const t = (i - 0.5) / n;
    if (skin.pattern === 'stripes') return i % 2 === 1 ? A : B;
    if (skin.pattern === 'gradient') return A.clone().lerp(B, t);
    if (skin.pattern === 'rainbow') return hsv(t * 0.85, 0.65, 1);
    return A;
  };
  const accent = () => skin.pattern === 'rainbow' ? hsv(0.85, 0.5, 1) : (skin.pattern === 'solid' ? A : B);
  const mat = (colour) => {
    const m = { color: colour, roughness: 0.4, metalness: 0 };
    if (skin.material === 'Metal') { m.metalness = 0.8; m.roughness = 0.28; }
    if (skin.material === 'Neon') { m.emissive = colour; m.emissiveIntensity = 0.75; }
    if (skin.material === 'Glass' || skin.material === 'Ice') { m.roughness = 0.08; m.metalness = 0.1; m.transparent = true; m.opacity = 0.82; }
    if (skin.material === 'Wood') m.roughness = 0.85;
    return new THREE.MeshStandardMaterial(m);
  };
  const geo = { Block: new THREE.BoxGeometry(1, 1, 1), Ball: new THREE.SphereGeometry(0.5, 20, 14), Cylinder: new THREE.CylinderGeometry(0.5, 0.5, 1, 20).rotateZ(-Math.PI / 2) };
  const part = (size, x, y, colour, shape, rotZ, onCurve) => { const m = new THREE.Mesh(geo[shape || 'Block'], mat(colour)); if (shape === 'Ball') m.scale.set(size[0] * FAT, size[1] * FAT, size[2] * FAT); else m.scale.set(size[0], size[1] * FAT, size[2] * FAT); m.position.set(x, onCurve ? y : y * FAT, 0); if (rotZ) m.rotation.z = rotZ; group.add(m); return m; };
  const shaft = (x0, x1, d, n, y, flat) => { const len = (x1 - x0) / n; for (let i = 1; i <= n; i++) { if (flat) part([len + 0.01, d, flat], x0 + (i - 0.5) * len, y || 0, colourAt(i, n)); else part([len + 0.01, d, d], x0 + (i - 0.5) * len, y || 0, colourAt(i, n), 'Cylinder'); } };
  const tip = (x, d, steps) => { for (let i = 1; i <= steps; i++) { const k = 1 - i / (steps + 1); part([0.08, d * k, d * k], x + i * 0.07, 0, colourAt(6, 6), 'Cylinder'); } };
  const eye = (x, len, gap, d) => { for (const s of [-1, 1]) part([len, d * 0.45, d * 0.45], x, s * gap, accent(), 'Cylinder'); part([d * 0.6, gap * 2 + d * 0.45, d * 0.5], x - len / 2, 0, accent()); };
  const ball = (x, d, y, onCurve) => part([d, d, d], x, y || 0, accent(), 'Ball', 0, onCurve);
  const t = typeId;
  if (t === 'pin') { shaft(-0.75, 0.85, 0.06, 6); tip(0.85, 0.06, 2); ball(-0.85, 0.28); }
  else if (t === 'quilting') { shaft(-0.6, 0.6, 0.07, 5); tip(0.6, 0.07, 2); eye(-0.7, 0.18, 0.03, 0.07); }
  else if (t === 'darning') { shaft(-1.15, 1.1, 0.12, 7); tip(1.1, 0.12, 3); eye(-1.3, 0.34, 0.07, 0.12); }
  else if (t === 'embroidery') { shaft(-0.85, 0.85, 0.09, 6); tip(0.85, 0.09, 3); eye(-1.02, 0.34, 0.08, 0.1); }
  else if (t === 'tapestry') { shaft(-0.95, 1.0, 0.11, 6); ball(1.03, 0.13); eye(-1.12, 0.34, 0.07, 0.11); }
  else if (t === 'safety') { shaft(-0.9, 0.85, 0.06, 6, 0.13); shaft(-0.75, 0.85, 0.06, 6, -0.13); for (let i = 0; i < 8; i++) { const a = i / 8 * Math.PI * 2; part([0.06, 0.06, 0.06], -0.95 + Math.cos(a) * 0.13, Math.sin(a) * 0.13, accent(), 'Ball'); } part([0.24, 0.38, 0.12], 0.95, 0, accent()); }
  else if (t === 'knitting') { shaft(-1.45, 1.3, 0.18, 8); tip(1.3, 0.18, 4); ball(-1.6, 0.4); }
  else if (t === 'crochet') { shaft(-1.3, 1.1, 0.16, 7); part([0.6, 0.24, 0.1], -0.2, 0, accent()); part([0.22, 0.12, 0.12], 1.21, 0, colourAt(7, 7), 'Cylinder'); part([0.16, 0.07, 0.08], 1.28, 0.07, colourAt(7, 7), 'Block', -0.7); }
  else if (t === 'bodkin') { shaft(-1.1, 1.0, 0.2, 7, 0, 0.05); ball(1.05, 0.16); part([0.3, 0.06, 0.07], -0.85, 0, new THREE.Color(0.02, 0.02, 0.03)); }
  else if (t === 'curved') { const n = 9, r = 0.95; for (let i = 1; i <= n; i++) { const a = (20 + (i - 0.5) * 140 / n) * Math.PI / 180; part([r * (140 / n) * Math.PI / 180 + 0.02, 0.08, 0.08], -Math.cos(a) * r, Math.sin(a) * r - 0.5, colourAt(i, n), 'Cylinder', Math.PI / 2 - a, true); } const a0 = 20 * Math.PI / 180; ball(-Math.cos(a0) * r, 0.1, Math.sin(a0) * r - 0.5, true); }
  else if (t === 'sailmaker') { shaft(-1.2, 0.9, 0.14, 7); tip(0.9, 0.16, 3); part([1.6, 0.03, 0.03], -0.2, 0.08, accent()); eye(-1.36, 0.3, 0.07, 0.13); }
  else { shaft(-0.9, 0.85, 0.08, 6); tip(0.85, 0.08, 3); eye(-1.03, 0.24, 0.05, 0.09); }
  return group;
}
window.buildNeedle = buildNeedle;

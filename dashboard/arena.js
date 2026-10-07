/* Venture Factory arena: a top-down MOBA map drawn from state.arena (/api/state).
   Arena.mount(canvas, {onSelect}) -> {update(state), replay(), select(id)}.
   Units stand at the tower their card waits at; agents move only for real AgentRun rows. */
(function (root) {
  'use strict';
  var W = 400, H = 400;
  var DEPT = {research: '#3987e5', dive: '#d95926', train: '#199e70', ops: '#c98500', treasury: '#c98500', warden: '#d55181'};
  var FREE = '#46D27A', MONEY = '#F0525A';
  var BASE = [42, 358], MARKET = [358, 42];
  var LANE = {top: [[58, 330], [58, 58], [330, 58]], mid: [[78, 322], [322, 78]], bot: [[70, 342], [342, 342], [342, 70]]};
  var TOWER = {
    top: [[58, 280], [58, 210], [58, 140], [140, 58], [210, 58], [280, 58]],
    mid: [[112, 288], [146, 254], [180, 220], [220, 180], [254, 146], [288, 112]],
    bot: [[120, 342], [190, 342], [260, 342], [342, 260], [342, 190], [342, 120]]
  };
  var CAMP = {research: [118, 190], dive: [200, 298], train: [190, 112], ops: [290, 205],
              treasury: [120, 312], warden: [252, 252], archive: [104, 86]};
  var CAMP_NAME = {research: 'Research', dive: 'Deep Dive', train: 'Training', ops: 'Operations',
                   treasury: 'Treasury', warden: 'Warden', archive: 'Archive'};
  var MINE_SLOTS = [[330, 74], [314, 52], [350, 88], [296, 70], [326, 98], [292, 44]];

  function rng(seed) { return function () { seed |= 0; seed = seed + 0x6D2B79F5 | 0; var t = Math.imul(seed ^ seed >>> 15, 1 | seed); t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t; return ((t ^ t >>> 14) >>> 0) / 4294967296; }; }
  function lerp(a, b, k) { return [a[0] + (b[0] - a[0]) * k, a[1] + (b[1] - a[1]) * k]; }
  function dist(a, b) { return Math.hypot(a[0] - b[0], a[1] - b[1]); }
  function segDist(p, a, b) { var dx = b[0] - a[0], dy = b[1] - a[1], k = ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / (dx * dx + dy * dy); k = Math.max(0, Math.min(1, k)); return dist(p, [a[0] + dx * k, a[1] + dy * k]); }
  function nearLane(p, pad) { for (var k in LANE) { var L = LANE[k]; for (var i = 0; i < L.length - 1; i++) if (segDist(p, L[i], L[i + 1]) < pad) return true; } return segDist(p, [64, 64], [336, 336]) < pad; }

  /* static scenery, drawn once into an offscreen canvas */
  function scenery(dpr) {
    var c = document.createElement('canvas'); c.width = W * dpr; c.height = H * dpr;
    var g = c.getContext('2d'); g.scale(dpr, dpr); var r = rng(7);
    var bg = g.createLinearGradient(0, 0, W, H); bg.addColorStop(0, '#3A1D3F'); bg.addColorStop(.5, '#24183A'); bg.addColorStop(1, '#3B1E2E'); g.fillStyle = bg; g.fillRect(0, 0, W, H);
    [[30, 30, 230, 'rgba(240,140,90,.45)'], [390, 380, 260, 'rgba(160,80,200,.35)'], [390, 30, 160, 'rgba(240,110,150,.3)']].forEach(function (b) { var rg = g.createRadialGradient(b[0], b[1], 0, b[0], b[1], b[2]); rg.addColorStop(0, b[3]); rg.addColorStop(1, 'rgba(0,0,0,0)'); g.fillStyle = rg; g.fillRect(0, 0, W, H); });
    for (var i = 0; i < 60; i++) { g.fillStyle = 'rgba(255,255,255,' + (.3 + r() * .5) + ')'; g.fillRect(r() * W, r() * H, 1, 1); }
    rrect(g, 10, 10, 380, 380, 28); g.fillStyle = '#5F5868'; g.fill(); g.lineWidth = 3; g.strokeStyle = '#8B8494'; g.stroke();
    rrect(g, 20, 20, 360, 360, 22); g.fillStyle = '#4A4255'; g.fill();
    for (i = 0; i < 70; i++) { var t = r() * 4, s = r() * 360 + 20, p = t < 1 ? [s, 15] : t < 2 ? [385, s] : t < 3 ? [s, 385] : [15, s]; bush(g, p[0], p[1], 4 + r() * 4, r); }
    for (i = 0; i < 26; i++) { var q = [40 + r() * 320, 40 + r() * 320]; g.fillStyle = 'rgba(255,255,255,.035)'; g.beginPath(); g.arc(q[0], q[1], 10 + r() * 18, 0, 7); g.fill(); }
    // river, corner to corner between towers 3 and 4
    var river = []; for (i = 0; i <= 24; i++) { var k = i / 24, w = Math.sin(k * Math.PI * 3) * 9 * Math.sin(k * Math.PI); river.push([64 + 272 * k + w, 64 + 272 * k - w]); }
    path(g, river, 24, '#24576F'); path(g, river, 17, '#3D93B5'); path(g, river, 3, 'rgba(255,255,255,.25)');
    g.fillStyle = '#8C7A5E'; g.beginPath(); g.ellipse(CAMP.warden[0], CAMP.warden[1] + 2, 21, 17, Math.PI / 4, 0, 7); g.fill();
    g.fillStyle = '#B9A47C'; g.beginPath(); g.ellipse(CAMP.warden[0], CAMP.warden[1], 18, 14, Math.PI / 4, 0, 7); g.fill();
    // jungle
    for (i = 0; i < 140; i++) { var j = [34 + r() * 332, 34 + r() * 332]; if (nearLane(j, 18) || near(j, 26)) continue; bush(g, j[0], j[1], 3 + r() * 5, r); }
    for (i = 0; i < 18; i++) { var k2 = [40 + r() * 320, 40 + r() * 320]; if (nearLane(k2, 16) || near(k2, 24)) continue; g.fillStyle = '#7C7486'; g.beginPath(); g.ellipse(k2[0], k2[1], 4 + r() * 3, 3, r() * 3, 0, 7); g.fill(); }
    // lanes
    for (var key in LANE) { path(g, LANE[key], 20, '#5B5163'); path(g, LANE[key], 14, '#A89A93'); path(g, LANE[key], 1, 'rgba(255,255,255,.18)'); }
    base(g, BASE, '#46D27A', 'YOUR BASE'); base(g, MARKET, '#F0525A', 'THE MARKET');
    return c;
  }
  function near(p, pad) { for (var k in CAMP) if (dist(p, CAMP[k]) < pad) return true; return dist(p, BASE) < 44 || dist(p, MARKET) < 44; }
  function rrect(g, x, y, w, h, r) { g.beginPath(); g.moveTo(x + r, y); g.arcTo(x + w, y, x + w, y + h, r); g.arcTo(x + w, y + h, x, y + h, r); g.arcTo(x, y + h, x, y, r); g.arcTo(x, y, x + w, y, r); g.closePath(); }
  function path(g, pts, w, c) { g.lineJoin = 'round'; g.lineCap = 'round'; g.lineWidth = w; g.strokeStyle = c; g.beginPath(); pts.forEach(function (p, i) { i ? g.lineTo(p[0], p[1]) : g.moveTo(p[0], p[1]); }); g.stroke(); }
  function bush(g, x, y, s, r) { g.fillStyle = '#1F5A2A'; g.beginPath(); g.arc(x, y + 1, s, 0, 7); g.fill(); g.fillStyle = r() < .5 ? '#3E9A3A' : '#2F7A2E'; g.beginPath(); g.arc(x - s * .2, y - s * .2, s * .8, 0, 7); g.fill(); }
  function base(g, p, col, label) {
    g.fillStyle = '#2E2936'; g.beginPath(); g.arc(p[0], p[1], 34, 0, 7); g.fill();
    g.fillStyle = '#8B95A1'; g.beginPath(); g.arc(p[0], p[1], 29, 0, 7); g.fill();
    g.fillStyle = '#C8D0D8'; g.beginPath(); g.arc(p[0], p[1], 21, 0, 7); g.fill();
    g.strokeStyle = col; g.lineWidth = 3; g.beginPath(); g.arc(p[0], p[1], 25, 0, 7); g.stroke();
    g.fillStyle = col; g.beginPath(); g.moveTo(p[0], p[1] - 12); g.lineTo(p[0] + 10, p[1]); g.lineTo(p[0], p[1] + 12); g.lineTo(p[0] - 10, p[1]); g.closePath(); g.fill();
    label9(g, label, p[0], p[1] + (p[1] > 200 ? -38 : 46), '#fff');
  }
  function label9(g, t, x, y, col) { g.font = '800 9px Nunito, system-ui, sans-serif'; g.textAlign = 'center'; g.fillStyle = 'rgba(0,0,0,.6)'; g.fillText(t, x + 1, y + 1); g.fillStyle = col || '#fff'; g.fillText(t, x, y); }

  function mount(cv, opts) {
    opts = opts || {};
    var reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
    var dpr = Math.min(devicePixelRatio || 1, 2), g = cv.getContext('2d');
    cv.width = W * dpr; cv.height = H * dpr; cv.style.aspectRatio = '1 / 1'; g.scale(dpr, dpr);
    var bg = scenery(dpr), S = null, skew = 0, sel = null, t = 0, mode = 'live', rp = null, hits = [], coins = [];
    var lanePos = {digital: 'top', commerce: 'mid', content: 'bot'};

    function towerXY(lane, n) { var pos = lanePos[lane] || 'mid'; return TOWER[pos][Math.max(1, Math.min(6, n)) - 1]; }
    function unitXY(u, i, n) { var tw = towerXY(u.lane, u.tower), pos = lanePos[u.lane] || 'mid', prev = u.tower > 1 ? TOWER[pos][u.tower - 2] : LANE[pos][0];
      var back = lerp(tw, prev, 18 / dist(tw, prev)), side = (i - (n - 1) / 2) * 11, dx = tw[0] - prev[0], dy = tw[1] - prev[1], L = Math.hypot(dx, dy);
      return [back[0] - dy / L * side, back[1] + dx / L * side]; }
    function target(run) {
      if (run.tower && run.lane) return towerXY(run.lane, run.tower);
      if (run.tower) return towerXY('commerce', run.tower);
      if (run.dept === 'research' && / scout$/.test(run.role)) { var h = 0; for (var i = 0; i < run.role.length; i++) h = (h * 31 + run.role.charCodeAt(i)) % 360; var a = (h / 360) * Math.PI * .5 + Math.PI * .5; return [200 + Math.cos(a) * 178, 200 + Math.sin(a) * 178]; }
      return CAMP[run.dept] || CAMP.research;
    }
    function now() { return Date.now() + skew; }

    function camp(p, id, dept) {
      var built = !dept || dept.built, col = DEPT[id] || '#8A8FA3';
      if (!built) { g.setLineDash([3, 3]); g.strokeStyle = '#C9B98A'; g.lineWidth = 1.5; g.strokeRect(p[0] - 13, p[1] - 11, 26, 22); g.setLineDash([]);
        g.strokeStyle = '#8A6A3A'; g.beginPath(); g.moveTo(p[0] - 13, p[1] - 11); g.lineTo(p[0] + 13, p[1] + 11); g.moveTo(p[0] + 13, p[1] - 11); g.lineTo(p[0] - 13, p[1] + 11); g.stroke();
        label9(g, CAMP_NAME[id] + ' · Phase ' + dept.phase, p[0], p[1] + (id === 'warden' ? -24 : 22), '#E8D9B0'); return; }
      g.fillStyle = 'rgba(0,0,0,.3)'; g.beginPath(); g.ellipse(p[0] + 2, p[1] + 4, 17, 12, 0, 0, 7); g.fill();
      if (id === 'research') { for (var i = 0; i < 4; i++) { var x = p[0] - 12 + i * 8, y = p[1] + (i % 2 ? 3 : -3); g.fillStyle = i % 2 ? '#E9D3A1' : '#D8B978'; g.beginPath(); g.moveTo(x - 6, y + 6); g.lineTo(x, y - 6); g.lineTo(x + 6, y + 6); g.closePath(); g.fill(); }
        g.fillStyle = '#F08A3C'; g.beginPath(); g.arc(p[0], p[1] + 9, 2.5 + (reduce ? 0 : Math.sin(t / 5) * .6), 0, 7); g.fill(); }
      else if (id === 'dive') { g.fillStyle = '#CFCFD8'; g.beginPath(); g.arc(p[0], p[1], 13, 0, 7); g.fill(); g.fillStyle = '#E8E8F0'; g.beginPath(); g.arc(p[0], p[1], 9, 0, 7); g.fill(); g.save(); g.translate(p[0], p[1]); g.rotate(reduce ? -.6 : t / 120); g.fillStyle = '#3B3F55'; g.fillRect(-2, -12, 4, 12); g.restore(); }
      else if (id === 'train') { g.fillStyle = '#E9D3A1'; g.fillRect(p[0] - 13, p[1] - 9, 26, 18); g.fillStyle = col; g.beginPath(); g.moveTo(p[0] - 15, p[1] - 8); g.lineTo(p[0], p[1] - 18); g.lineTo(p[0] + 15, p[1] - 8); g.closePath(); g.fill(); }
      else if (id === 'ops') { g.fillStyle = '#A3702F'; g.fillRect(p[0] - 14, p[1] - 9, 28, 18); g.fillStyle = '#DDA86A'; g.fillRect(p[0] - 11, p[1] - 6, 22, 12); g.fillStyle = '#5A3A1E'; g.fillRect(p[0] + 7, p[1] - 15, 5, 8); }
      else if (id === 'treasury') { g.fillStyle = '#B88A38'; poly(p, 13, 6); g.fillStyle = '#F7C331'; poly(p, 9, 6); }
      else if (id === 'warden') { g.fillStyle = '#4F4A63'; g.beginPath(); g.arc(p[0], p[1], 13, 0, 7); g.fill(); g.fillStyle = col; g.globalAlpha = .6 + (reduce ? 0 : Math.sin(t / 12) * .3); g.beginPath(); g.arc(p[0], p[1], 6, 0, 7); g.fill(); g.globalAlpha = 1; }
      else if (id === 'archive') { for (i = 0; i < 4; i++) { g.fillStyle = '#9A9EAD'; var tx = p[0] - 10 + i * 7, ty = p[1] + (i % 2) * 4; g.fillRect(tx - 2.5, ty - 6, 5, 8); g.beginPath(); g.arc(tx, ty - 6, 2.5, Math.PI, 0); g.fill(); } }
      if (dept && id !== 'archive') { g.fillStyle = '#1A3545'; g.fillRect(p[0] + 12, p[1] - 22, 2, 14); g.fillStyle = col; g.beginPath(); g.moveTo(p[0] + 14, p[1] - 22); g.lineTo(p[0] + 24, p[1] - 19); g.lineTo(p[0] + 14, p[1] - 16); g.closePath(); g.fill(); }
      label9(g, CAMP_NAME[id], p[0], p[1] + 24);
    }
    function poly(p, r, n) { g.beginPath(); for (var i = 0; i < n; i++) { var a = i / n * Math.PI * 2; g[i ? 'lineTo' : 'moveTo'](p[0] + Math.cos(a) * r, p[1] + Math.sin(a) * r); } g.closePath(); g.fill(); }
    function person(x, y, col, carry, alpha) {
      g.globalAlpha = alpha == null ? 1 : alpha;
      g.fillStyle = 'rgba(0,0,0,.3)'; g.beginPath(); g.ellipse(x, y + 1, 3.5, 1.5, 0, 0, 7); g.fill();
      g.fillStyle = '#10202A'; g.beginPath(); g.arc(x, y - 3, 4, 0, 7); g.fill(); g.fillStyle = col; g.beginPath(); g.arc(x, y - 3, 3, 0, 7); g.fill();
      g.fillStyle = '#F2C9A0'; g.beginPath(); g.arc(x, y - 7.5, 2, 0, 7); g.fill();
      if (carry) { g.fillStyle = '#10202A'; g.fillRect(x + 2, y - 9, 6, 5); g.fillStyle = '#F7E6C3'; g.fillRect(x + 2.7, y - 8.3, 4.6, 3.6); }
      g.globalAlpha = 1;
    }
    function towers() {
      ['top', 'mid', 'bot'].forEach(function (pos) { TOWER[pos].forEach(function (p, i) {
        var col = i < 3 ? FREE : MONEY, isSel = sel && sel.kind === 'tower' && sel.id === 't' + (i + 1);
        g.fillStyle = '#26212C'; g.beginPath(); g.arc(p[0], p[1], 9.5, 0, 7); g.fill();
        g.lineWidth = 2.5; g.strokeStyle = col; g.beginPath(); g.arc(p[0], p[1], 9.5, 0, 7); g.stroke();
        if (isSel) { g.lineWidth = 2; g.strokeStyle = '#fff'; g.beginPath(); g.arc(p[0], p[1], 13, 0, 7); g.stroke(); }
        g.fillStyle = col; g.globalAlpha = .85; g.beginPath(); g.moveTo(p[0], p[1] - 5); g.lineTo(p[0] + 3.5, p[1]); g.lineTo(p[0], p[1] + 5); g.lineTo(p[0] - 3.5, p[1]); g.closePath(); g.fill(); g.globalAlpha = 1;
        g.font = '800 7px Nunito, system-ui, sans-serif'; g.textAlign = 'center'; g.fillStyle = '#fff'; g.fillText(String(i + 1), p[0] + 9, p[1] - 7);
        hits.push({kind: 'tower', id: 't' + (i + 1), p: p, r: 11});
      }); });
    }
    function units() {
      var groups = {};
      (S.arena.units || []).forEach(function (u) { var k = u.lane + ':' + u.tower; (groups[k] = groups[k] || []).push(u); });
      Object.keys(groups).forEach(function (k) {
        var list = groups[k], live = list.filter(function (u) { return u.state !== 'dead'; }), dead = list.filter(function (u) { return u.state === 'dead'; });
        var shown = live.slice(0, 3);
        shown.forEach(function (u, i) {
          var p = unitXY(u, i, shown.length), isSel = sel && sel.kind === 'unit' && sel.id === u.card_id;
          var ring = u.state === 'blocked' ? '#F7C331' : u.state === 'testing' ? '#B07CF0' : '#10202A';
          if (u.state === 'testing' && !reduce) { g.strokeStyle = 'rgba(176,124,240,' + (.5 + Math.sin(t / 8) * .3) + ')'; g.lineWidth = 2; g.beginPath(); g.arc(p[0], p[1], 10, 0, 7); g.stroke(); }
          g.fillStyle = '#F7E6C3'; g.beginPath(); g.arc(p[0], p[1], 6.5, 0, 7); g.fill(); g.lineWidth = u.state === 'blocked' ? 2.5 : 1.5; g.strokeStyle = ring; g.stroke();
          if (isSel) { g.strokeStyle = '#fff'; g.lineWidth = 2; g.beginPath(); g.arc(p[0], p[1], 9.5, 0, 7); g.stroke(); }
          g.font = '800 6.5px Nunito, system-ui, sans-serif'; g.textAlign = 'center'; g.fillStyle = '#3B2A14'; g.fillText(u.short, p[0], p[1] + 2.3);
          if (u.state === 'blocked') { var bob = reduce ? 0 : Math.sin(t / 8) * 1.5; g.fillStyle = '#B23A2B'; g.beginPath(); g.arc(p[0] + 6, p[1] - 7 + bob, 4.5, 0, 7); g.fill(); g.fillStyle = '#fff'; g.font = '800 7px Nunito, sans-serif'; g.fillText('!', p[0] + 6, p[1] - 4.5 + bob); }
          hits.push({kind: 'unit', id: u.card_id, p: p, r: 8, data: u});
        });
        if (live.length > 3) { var q = unitXY(live[0], 3, 4); g.fillStyle = '#10202A'; g.beginPath(); g.arc(q[0], q[1], 6, 0, 7); g.fill(); g.fillStyle = '#fff'; g.font = '800 6.5px Nunito, sans-serif'; g.textAlign = 'center'; g.fillText('+' + (live.length - 3), q[0], q[1] + 2.3); }
        if (dead.length) { var d = unitXY(dead[0], -1.6, 1); g.fillStyle = 'rgba(200,200,210,.75)'; g.font = '800 9px Nunito, sans-serif'; g.textAlign = 'center'; g.fillText('✕' + (dead.length > 1 ? dead.length : ''), d[0], d[1] + 3); }
      });
    }
    function mines() {
      (S.arena.mines || []).forEach(function (m, i) { var p = MINE_SLOTS[i % MINE_SLOTS.length];
        g.fillStyle = '#8E6A2A'; g.beginPath(); g.arc(p[0], p[1], 8, 0, 7); g.fill(); g.fillStyle = m.status === 'live' ? '#F7C331' : '#B9A98A'; g.beginPath(); g.arc(p[0], p[1], 5.5, 0, 7); g.fill();
        hits.push({kind: 'mine', id: m.venture_id, p: p, r: 10, data: m});
        if (m.status === 'live' && m.revenue > 0 && !reduce && Math.random() < .02) coins.push({lane: lanePos[m.lane] || 'mid', k: 1}); });
      coins.forEach(function (c) { c.k -= .004; if (c.k <= 0) return; var L = LANE[c.lane], seg = (L.length - 1) * c.k, i = Math.min(L.length - 2, Math.floor(seg)), p = lerp(L[i], L[i + 1], seg - i); g.fillStyle = '#8A6A10'; g.beginPath(); g.arc(p[0], p[1], 3.4, 0, 7); g.fill(); g.fillStyle = '#F7C331'; g.beginPath(); g.arc(p[0], p[1], 2.5, 0, 7); g.fill(); });
      coins = coins.filter(function (c) { return c.k > 0; });
    }
    function agentsLayer() {
      var depts = {}; (S.departments || []).forEach(function (d) { depts[d.id] = d; });
      ['research', 'dive', 'train', 'ops', 'treasury', 'warden', 'archive'].forEach(function (id) { camp(CAMP[id], id, depts[id]); hits.push({kind: id === 'archive' ? 'archive' : 'camp', id: id, p: CAMP[id], r: 20}); });
      var at = mode === 'replay' ? rp.clock() : now(), busy = {}, beam = 0;
      (S.arena.runs || []).forEach(function (r) { if (r.dept !== 'warden') return; var s = Date.parse(r.started), w = mode === 'replay' ? rp.walk : 9000,
        f = r.finished ? Date.parse(r.finished) : (r.status === 'running' ? at + 1 : s); if (at >= s - w && at <= f + w) beam = Math.max(beam, at <= f ? 1 : 1 - (at - f) / w); });
      if (beam > 0 && depts.warden && depts.warden.built) { var wp = CAMP.warden, pulse = reduce ? .5 : (t % 60) / 60;
        ['research', 'dive', 'train', 'ops', 'treasury', 'archive'].forEach(function (id) { var p = CAMP[id];
          g.strokeStyle = 'rgba(213,81,129,' + (.55 * beam) + ')'; g.lineWidth = 1.5; g.setLineDash([4, 4]); g.beginPath(); g.moveTo(wp[0], wp[1] - 10); g.lineTo(p[0], p[1]); g.stroke(); g.setLineDash([]);
          g.strokeStyle = 'rgba(213,81,129,' + (.7 * beam * (1 - pulse)) + ')'; g.beginPath(); g.arc(p[0], p[1], 8 + pulse * 18, 0, 7); g.stroke(); }); }
      (S.arena.runs || []).forEach(function (r) {
        var s = Date.parse(r.started), f = r.finished ? Date.parse(r.finished) : (r.status === 'running' ? at + 1 : s), walk = mode === 'replay' ? rp.walk : 9000;
        if (at < s - walk || at > f + walk) return;
        var home = CAMP[r.dept] || CAMP.research, tgt = target(r), p, carry = false;
        if (at < s) p = lerp(home, tgt, (at - (s - walk)) / walk);
        else if (at <= f) { p = [tgt[0] + (reduce ? 0 : Math.sin(t / 6 + r.id) * 1.5), tgt[1]]; busy[r.dept] = (busy[r.dept] || 0) + 1; carry = r.dept === 'research'; }
        else { p = lerp(tgt, home, (at - f) / walk); carry = r.status === 'ok'; }
        person(p[0], p[1], DEPT[r.dept] || '#ccc', carry, r.status === 'failed' || r.status === 'blocked' ? .55 : 1);
      });
      Object.keys(depts).forEach(function (id) { var d = depts[id]; if (!d.built) return; var idle = Math.min(6, Math.max(0, d.agents - (busy[id] || 0))), p = CAMP[id];
        for (var i = 0; i < idle; i++) { var a = i / 6 * Math.PI * 2 + .4; person(p[0] + Math.cos(a) * 19, p[1] + 4 + Math.sin(a) * 11, DEPT[id], false, .7); }
        var txt = d.agents + (busy[id] ? ' · ' + busy[id] + ' working' : ''); g.font = '800 8px Nunito, sans-serif'; var w = g.measureText(txt).width + 8;
        g.fillStyle = 'rgba(16,32,42,.85)'; rrect(g, p[0] - w / 2, p[1] - 33, w, 11, 5); g.fill(); g.fillStyle = busy[id] ? '#7CE08A' : '#CFE5F0'; g.textAlign = 'center'; g.fillText(txt, p[0], p[1] - 25); });
    }
    function frame() {
      t++; hits = []; g.clearRect(0, 0, W, H); g.drawImage(bg, 0, 0, W, H);
      hits.push({kind: 'base', id: 'base', p: BASE, r: 30}, {kind: 'market', id: 'market', p: MARKET, r: 30});
      if (S) { towers(); agentsLayer(); units(); mines(); }
      if (mode === 'replay') { var at = new Date(rp.clock()); var txt = 'REPLAY · ' + at.toLocaleString(undefined, {weekday: 'short', hour: '2-digit', minute: '2-digit'}); g.font = '800 10px Nunito, sans-serif'; var w = g.measureText(txt).width + 14;
        g.fillStyle = 'rgba(16,32,42,.9)'; rrect(g, 200 - w / 2, 372, w, 16, 8); g.fill(); g.fillStyle = '#F7C331'; g.textAlign = 'center'; g.fillText(txt, 200, 383);
        if (rp.done()) { mode = 'live'; if (opts.onReplayEnd) opts.onReplayEnd(); } }
      if (!reduce || mode === 'replay') requestAnimationFrame(frame);
    }
    cv.addEventListener('click', function (e) {
      var r = cv.getBoundingClientRect(), x = (e.clientX - r.left) * W / r.width, y = (e.clientY - r.top) * H / r.height, best = null;
      hits.forEach(function (h) { var d = dist([x, y], h.p); if (d <= h.r && (!best || d - h.r < best.d - best.r || h.kind === 'unit')) best = Object.assign({d: d}, h); });
      if (best) { sel = best; if (opts.onSelect) opts.onSelect(best); if (reduce) frame(); }
    });
    frame();
    return {
      update: function (state) { S = state; (state.arena.lanes || []).forEach(function (l) { lanePos[l.id] = l.position; });
        if (state.generated_at) skew = Date.parse(state.generated_at) - Date.now(); if (reduce) frame(); },
      select: function (kind, id) { sel = {kind: kind, id: id}; if (reduce) frame(); },
      replay: function () {
        var runs = (S && S.arena.runs || []).slice().sort(function (a, b) { return Date.parse(a.started) - Date.parse(b.started); });
        if (!runs.length) return false;
        var t0 = Date.parse(runs[0].started) - 2000, t1 = Math.max.apply(null, runs.map(function (r) { return Date.parse(r.finished || r.started); })) + 4000;
        var span = Math.max(t1 - t0, 1), real0 = performance.now(), length = 40000;
        rp = {clock: function () { return t0 + (performance.now() - real0) / length * span; }, walk: span / length * 1200, done: function () { return performance.now() - real0 > length; }};
        mode = 'replay'; if (reduce) requestAnimationFrame(frame); return true;
      }
    };
  }
  root.Arena = {mount: mount};
})(window);

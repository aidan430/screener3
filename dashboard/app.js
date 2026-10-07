/* Venture Base dashboard: renders /api/state around the arena map. Polls every 60 s. */
(function () {
  'use strict';
  var COLOR = {research: '#3987e5', dive: '#d95926', train: '#199e70', ops: '#c98500', treasury: '#c98500', warden: '#d55181'};
  var S = null, current = {kind: 'camp', id: 'research'};
  var $ = function (id) { return document.getElementById(id); };
  function el(tag, cls, txt) { var e = document.createElement(tag); if (cls) e.className = cls; if (txt != null) e.textContent = txt; return e; }
  function R(n) { if (n == null) return '–'; var v = Math.abs(n), s = v >= 10 ? Math.round(v).toLocaleString('en-ZA') : v.toFixed(2); return (n < 0 ? '−' : '') + 'R' + s.replace(/ |\s/g, ','); }
  function pct(x) { return x == null ? '–' : Math.round(x * 100) + '%'; }
  function hhmm(iso) { var d = new Date(iso); return String(d.getHours()).padStart(2, '0') + ':' + String(d.getMinutes()).padStart(2, '0'); }

  var arena = Arena.mount($('c'), {onSelect: function (h) { current = {kind: h.kind, id: h.id}; panel(); }, onReplayEnd: function () { hint(); }});
  $('replay').addEventListener('click', function () { if (!arena.replay()) $('hint').textContent = 'Nothing to replay: no agent has worked in the last 36 hours.'; else $('hint').textContent = 'Replaying the last 36 hours of agent work at speed'; });

  function hint() {
    if (!S) return;
    var u = S.arena.units.filter(function (x) { return x.state !== 'dead'; }).length;
    $('hint').textContent = u ? 'Tap a tower, camp or niche · ' + S.agents_working + ' agents working now' : 'No niches in the lanes yet. Tap a camp to see what its agents did last.';
  }

  function panel() {
    if (!S) return;
    var p = null;
    if (current.kind === 'unit') p = unitPanel(S.arena.units.filter(function (u) { return u.card_id === current.id; })[0]);
    else if (current.kind === 'mine') p = minePanel(S.arena.mines.filter(function (m) { return m.venture_id === current.id; })[0]);
    else p = S.buildings.filter(function (b) { return b.id === current.id; })[0];
    if (!p) { current = {kind: 'camp', id: 'research'}; p = S.buildings.filter(function (b) { return b.id === 'research'; })[0]; }
    arena.select(current.kind, current.id);
    var nm = $('i-name'); nm.textContent = ''; if (COLOR[p.id]) { var d = el('i', 'dot'); d.style.background = COLOR[p.id]; nm.appendChild(d); } nm.appendChild(document.createTextNode(p.name));
    $('i-lvl').textContent = p.lvl || ''; $('i-desc').textContent = p.desc || '';
    var kv = $('i-kv'); kv.textContent = ''; (p.kv || []).forEach(function (k) { var x = el('div'); x.appendChild(el('b', null, k[0])); x.appendChild(el('span', null, k[1])); kv.appendChild(x); });
    var act = $('i-act'); act.textContent = '';
    (p.actions || []).forEach(function (a) { var b = el('button', 'btn ' + (a.style || 'grey'), a.label); b.onclick = function () { run(b, a); }; act.appendChild(b); });
    if (p.link) { var ln = el('a', null, p.link.label); ln.href = p.link.url; ln.target = '_blank'; ln.rel = 'noopener'; act.appendChild(ln); }
    var ro = $('i-roster'); ro.textContent = '';
    (p.roster || []).forEach(function (r) { var li = el('li'), mid = el('div'); mid.appendChild(el('div', 'who', r.who)); if (r.task) mid.appendChild(el('div', 'task', r.task)); li.appendChild(mid);
      li.appendChild(el('span', 'state ' + r.state, {work: '▶ Working', idle: '■ Idle', block: '▲ Needs attention'}[r.state] || r.state)); ro.appendChild(li); });
  }
  function unitPanel(u) {
    if (!u) return null;
    var tw = S.arena.towers[u.tower - 1], lane = S.arena.lanes.filter(function (l) { return l.id === u.lane; })[0];
    var states = {waiting: 'Waiting to be judged', blocked: 'Waiting on you', testing: 'Smoke test running', dead: 'Killed here, now in the Archive'};
    var d = u.dossier, kv = [['T' + u.tower, tw.name], [d ? R(d.capital) : '–', 'start-up'], [d ? pct(d.margin) : '–', 'margin']];
    if (u.smoke && u.state === 'testing') kv = [[String(u.smoke.visitors), 'visitors'], [String(u.smoke.buy_clicks), 'buy-clicks'], [u.smoke.visitors ? pct(u.smoke.buy_clicks / u.smoke.visitors) : '–', 'rate']];
    return {id: 'unit', name: u.title, lvl: (lane ? lane.name : u.lane) + (u.lane_guessed ? ' (guessed)' : ''),
            desc: states[u.state] + ' at tower ' + u.tower + ': ' + tw.rule + (d ? ' Deep Dive score ' + d.score + '/10, break-even after ' + (d.break_even || 'never') + ' sales.' : ''),
            kv: kv, actions: u.actions, link: {label: 'Open the evidence', url: u.url}, roster: []};
  }
  function minePanel(m) {
    if (!m) return null;
    return {id: 'mine', name: m.name, lvl: 'Gold mine · ' + m.status, desc: 'Sells ' + (m.price || 'its product') + '. Gold travels home down its lane.',
            kv: [[R(m.revenue), 'earned'], [R(m.uncollected), 'uncollected'], [m.lane, 'lane']], actions: m.actions, roster: []};
  }
  function run(btn, a) {
    if (a.endpoint === '#side_quests') { msg((S.side_quests.length ? S.side_quests.map(function (q, i) { return (i + 1) + '. ' + q; }).join('\n') : 'No side quests. The base runs itself.')); return; }
    if (a.style === 'spend' && !btn.dataset.armed) { btn.dataset.armed = '1'; btn.textContent = 'TAP AGAIN TO SPEND'; return; }
    msg('Working…');
    fetch(a.endpoint, {method: 'POST'}).then(function (r) { return r.json().then(function (j) { return {ok: r.ok, j: j}; }); })
      .then(function (res) { var text = res.j.message || res.j.detail || (res.ok ? 'Done.' : 'Failed.'); load().then(function () { msg(text); }); })
      .catch(function () { msg('Could not reach the factory API.'); });
  }
  function msg(t) { var act = $('i-act'); act.textContent = ''; act.appendChild(el('p', 'okmsg', t)); }

  function feed() {
    var ol = $('feed'); ol.textContent = '';
    var runs = S.arena.runs.slice(0, 12);
    if (!runs.length) { ol.appendChild(el('li', null, 'No agent has worked in the last 36 hours. The night run starts at 01:00.')); return; }
    runs.forEach(function (r) { var li = el('li'), dt = el('i', 'dot'); dt.style.background = COLOR[r.dept] || '#999';
      li.appendChild(el('time', null, hhmm(r.started))); li.appendChild(dt);
      li.appendChild(el('span', r.status === 'failed' || r.status === 'blocked' ? 'fail' : null, r.role + (r.subject ? ' · ' + r.subject : '') + ': ' + (r.status === 'running' ? 'working…' : r.summary || r.status)));
      ol.appendChild(li); });
  }
  function depts() {
    var box = $('depts'); box.textContent = '';
    S.departments.forEach(function (d) { var b = el('button', 'dept'); b.style.setProperty('--c', COLOR[d.id]);
      b.appendChild(el('b', null, d.name)); b.appendChild(el('span', null, d.built ? d.agents + ' agent' + (d.agents === 1 ? '' : 's') + ' · ' + d.working + ' working' : 'Under construction · Phase ' + d.phase));
      var last = S.arena.runs.filter(function (r) { return r.dept === d.id; })[0];
      b.appendChild(el('span', 'last', last ? 'Last: ' + last.role + ', ' + hhmm(last.started) + ' · ' + (last.summary || last.status) : 'No work in the last 36 hours'));
      b.onclick = function () { current = {kind: 'camp', id: d.id}; panel(); $('info').scrollIntoView({behavior: 'smooth', block: 'nearest'}); };
      box.appendChild(b); });
  }
  function niches() {
    var tl = $('tiles'), box = $('niches'); tl.textContent = ''; box.textContent = '';
    var n = S.niches.slice();
    if (!n.length) { box.appendChild(el('p', 'empty', 'No niche has reached a smoke test yet. Each one appears here with its revenue, costs and profit once it does.')); return; }
    var byRev = n.slice().sort(function (a, b) { return b.revenue - a.revenue; })[0], byProf = n.slice().sort(function (a, b) { return b.profit - a.profit; })[0], worst = n.slice().sort(function (a, b) { return a.profit - b.profit; })[0];
    [['Highest grossing', R(byRev.revenue), byRev.name], ['Most profitable', R(byProf.profit), byProf.name], ['Lowest earner', R(worst.profit), worst.name], ['Net, all niches', R(n.reduce(function (a, x) { return a + x.profit; }, 0)), n.length + ' niches']]
      .forEach(function (x) { var d = el('div', 'tile'); d.appendChild(el('span', 'k', x[0])); d.appendChild(el('span', 'v' + (x[1].charAt(0) === '−' ? ' neg' : ''), x[1])); d.appendChild(el('span', 's', x[2])); tl.appendChild(d); });
    var wrap = el('div', 'tablewrap'), t = el('table'), hd = el('tr');
    ['Niche', 'Lane', 'Model', 'Stage', 'Revenue', 'Costs', 'Profit', 'Start-up'].forEach(function (h) { hd.appendChild(el('th', null, h)); });
    var thead = el('thead'); thead.appendChild(hd); t.appendChild(thead); var tb = el('tbody');
    n.sort(function (a, b) { return b.profit - a.profit; }).forEach(function (x) { var tr = el('tr');
      [x.name, x.lane, x.model, x.stage].forEach(function (v) { tr.appendChild(el('td', null, v)); });
      tr.appendChild(el('td', 'money', R(x.revenue))); tr.appendChild(el('td', 'money', R(x.costs))); tr.appendChild(el('td', 'money ' + (x.profit < 0 ? 'neg' : 'pos'), R(x.profit))); tr.appendChild(el('td', 'money', R(x.capital)));
      tb.appendChild(tr); });
    t.appendChild(tb); wrap.appendChild(t); box.appendChild(wrap);
  }
  function caps() {
    var box = $('caps'); box.textContent = '';
    if (!S.dossiers.length) { box.appendChild(el('p', 'empty', 'No niche has passed the Deep Dive yet. Each one that does gets a card here with its start-up capital, line by line.')); return; }
    var grid = el('div', 'caps');
    S.dossiers.forEach(function (d) { var c = el('article', 'cap');
      c.appendChild(el('span', 'meta', d.model + ' · ' + d.lane + ' lane · score ' + d.score + '/10'));
      c.appendChild(el('h3', null, d.title)); c.appendChild(el('div', 'big', R(d.capital)));
      var ul = el('ul'); d.lines.forEach(function (l) { var li = el('li'); li.appendChild(el('span', null, l[0])); li.appendChild(el('span', null, R(l[1]))); ul.appendChild(li); }); c.appendChild(ul);
      c.appendChild(el('span', 'meta', 'Price ' + d.price + ' ' + d.currency + ' ' + d.price_unit + ' · margin ' + pct(d.margin) + ' · break-even ' + (d.break_even || 'never') + ' sales'));
      c.appendChild(el('span', 'meta', 'Unit cost: ' + d.unit_cost_basis));
      grid.appendChild(c); });
    box.appendChild(grid);
  }
  function treasury() {
    var box = $('treasury'); box.textContent = '';
    S.treasury.forEach(function (r) { var row = el('div', 'trow');
      row.appendChild(el('div', 'ic', r.kind === 'income' ? '⛏️' : r.kind === 'soon' ? '🧪' : /^Elixir/.test(r.name) ? '⚗️' : '🛒'));
      var mid = el('div'); mid.appendChild(el('div', 'tname', r.name)); mid.appendChild(el('div', 'tsub', r.sub)); var bar = el('div', 'tbar'), b = el('b', r.kind === 'income' ? '' : r.kind); b.style.width = (r.pct || 0) + '%'; bar.appendChild(b); mid.appendChild(bar); row.appendChild(mid);
      var v = r.projected_30d; row.appendChild(el('div', 'tval' + (r.kind === 'cost' ? ' neg' : r.kind === 'soon' ? ' soon' : ''), v == null ? (r.label || 'unknown') : (Math.round(v) < 0 ? '−' : Math.round(v) > 0 ? '+' : '') + R(Math.abs(v))));
      box.appendChild(row); });
    $('net').textContent = (Math.round(S.net_30d) < 0 ? '−' : Math.round(S.net_30d) > 0 ? '+' : '') + R(Math.abs(S.net_30d));
    $('foot').textContent = S.foot || '';
  }
  function apply(st) {
    S = st; arena.update(st);
    $('p-gold').textContent = R(st.gold); $('p-elixir').textContent = R(st.elixir_month);
    $('p-agents').textContent = st.agents_total; $('p-agents-sub').textContent = 'AGENTS · ' + st.agents_working + ' WORKING NOW';
    $('p-niches').textContent = st.arena.units.filter(function (u) { return u.state !== 'dead'; }).length;
    hint(); panel(); feed(); depts(); niches(); caps(); treasury();
  }
  function load() { return fetch('/api/state', {cache: 'no-store'}).then(function (r) { if (!r.ok) throw r; return r.json(); }).then(apply).catch(function () { $('hint').textContent = 'Factory offline, retrying…'; }); }
  load(); setInterval(load, 60000);
})();

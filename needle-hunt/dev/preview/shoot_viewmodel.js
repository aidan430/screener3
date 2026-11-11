// Renders the first-person view's standard sheets for a rig (a folder holding FirstPerson.luau and
// FirstPersonRig.luau; default the game's own src/shared) into a folder:
//
//   node needle-hunt/dev/preview/shoot_viewmodel.js [rigDir] [outDir] [sheet ...]
//
//   needles.png  the idle hold with five very different needles, fov 70 (or the type:skin list in $VM_NEEDLES)
//   fov.png      the sewing needle at fov 60, 70, 90, 100 (the framing should not change)
//   jab.png throw.png inspect.png equip.png   each animation in evenly spaced frames (throw.png goes on
//                through the empty hand and the catch)
//   motion.png   the walk's extremes, a hard turn each way, a landing, breathing in and out, in the air
//   wall.png     facing a wall 0.6, 1.2 and 2.5 studs away
//   hold.png     the sewing needle's hold at full size (1280 x 720)
//   sheets.json  where the needle's point and the grip land on screen in every tile
// It first runs viewmodel_data.py (python3 with lupa: set PYTHONPATH if lupa lives somewhere of its
// own) to read the real rig and build the real needles, then checks the page's maths against the
// game's (client/ViewModelPose.luau) and stops if they differ. Needs playwright, and three.min.js
// (r128) next to viewmodel.html, in outDir, in the working folder or at $THREE_JS.
const { chromium } = require('playwright');
const { execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');

(async () => {
  const args = process.argv.slice(2);
  const rigDir = path.resolve(args[0] || path.join(__dirname, '..', '..', 'src', 'shared'));
  const outDir = path.resolve(args[1] || 'viewmodel_sheets');
  fs.mkdirSync(outDir, { recursive: true });
  const dataFile = path.join(outDir, 'viewmodel_data.js');
  const needles = (process.env.VM_NEEDLES || '').split(/[\s,]+/).filter(Boolean); // other needles for needles.png: VM_NEEDLES="narwhal:frost treasurekey:golden"
  process.stdout.write(execFileSync('python3', [path.join(__dirname, 'viewmodel_data.py'), rigDir, dataFile, ...needles], { encoding: 'utf8' }));
  const three = [process.env.THREE_JS, path.join(__dirname, 'three.min.js'), path.join(outDir, 'three.min.js'), path.resolve('three.min.js')].find(p => p && fs.existsSync(p));
  if (!three) throw new Error('three.min.js (r128) not found: put it next to viewmodel.html, in the output folder or set THREE_JS');

  const browser = await chromium.launch({ args: ['--use-gl=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', '--allow-file-access-from-files'] });
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  page.on('pageerror', e => { console.log('PAGE ERROR', e.message); process.exitCode = 1; });
  page.on('console', m => { if (m.type() === 'error') console.log('ERR', m.text()); });
  await page.route('**/three.min.js', r => r.fulfill({ body: fs.readFileSync(three), contentType: 'application/javascript' }));
  await page.route('**/viewmodel_data.js', r => r.fulfill({ body: fs.readFileSync(dataFile), contentType: 'application/javascript' }));
  await page.goto(`file://${__dirname}/viewmodel.html?quiet=1`);
  await page.waitForFunction(() => window.READY, null, { timeout: 60000 });

  const check = await page.evaluate(() => window.VM.parity());
  console.log(`maths check: ${check.cases} poses, worst difference from the game's own maths ${check.worst.toExponential(1)}`);
  if (!(check.worst < 1e-6)) { console.log('  the page and client/ViewModelPose.luau disagree on: ' + check.bad.join(', ')); await browser.close(); process.exit(1); }

  if (!(await page.evaluate(() => window.VM_DATA.legacy))) {
    const game = await page.evaluate(() => window.VM.gameCheck());
    console.log(`parts check: ${game.parts} parts built and placed by the game's own client/ViewModelRig, worst difference from the page's ${game.worst.toExponential(1)}`);
    if (!(game.worst < 1e-4)) { console.log('  the page draws these differently: ' + game.bad.join(', ')); await browser.close(); process.exit(1); }
    const wall = await page.evaluate(() => window.VM.wallCheck());
    console.log(wall.worst > 0 ? `wall check: the point goes ${wall.worst.toFixed(2)} studs INTO a wall (${wall.at}): raise motion.wall's rows or margin`
      : `wall check: the point stays ${(-wall.worst).toFixed(2)} studs or more out of a wall square on (closest: ${wall.at})`);
  }
  const png = (file, url) => fs.writeFileSync(path.join(outDir, file), Buffer.from(url.split(',')[1], 'base64'));
  const all = await page.evaluate(() => window.VM.sheets), wanted = args.slice(2).length ? args.slice(2) : all.concat(['hold']);
  const notes = {};
  for (const name of wanted) {
    if (name === 'hold') { png('hold.png', await page.evaluate(() => window.VM.frame({ key: window.VM.needles.includes('sewing:steel') ? 'sewing:steel' : window.VM.needles[0] }).canvas.toDataURL('image/png'))); console.log('hold.png'); continue; }
    const made = await page.evaluate(n => window.VM.sheet(n), name);
    if (!made) { console.log(name + ': nothing to draw for this rig'); continue; }
    png(name + '.png', made.url); notes[name] = made.notes; console.log(name + '.png', made.notes.length, 'tiles');
  }
  fs.writeFileSync(path.join(outDir, 'sheets.json'), JSON.stringify(notes, null, 1));
  await browser.close();
})().catch(e => { console.error(e); process.exit(1); });

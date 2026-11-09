const { chromium } = require('playwright');
const fs = require('fs');
(async () => {
  const browser = await chromium.launch({ args: ['--use-gl=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', '--allow-file-access-from-files'] });
  const page = await browser.newPage({ viewport: { width: 360, height: 220 } });
  page.on('pageerror', e => console.log('PAGEERR', e.message));
  await page.goto(`file://${__dirname}/needle.html`);
  await page.waitForFunction(() => window.READY, null, { timeout: 60000 });
  const data = JSON.parse(fs.readFileSync(`${__dirname}/needles.json`));
  const jobs = [];
  for (const t of data.types) jobs.push([t.id, 'steel']);
  for (const s of data.skins) jobs.push(['darning', s.id]);
  for (const [t, s] of [['knitting', 'candycane'], ['safety', 'golden'], ['crochet', 'aurora'], ['curved', 'galaxy'], ['pin', 'rainbow'], ['embroidery', 'sakura'], ['bodkin', 'lava'], ['sailmaker', 'prism']]) jobs.push([t, s]);
  for (const [t, s] of jobs) {
    const url = await page.evaluate(([t, s]) => window.render(t, s), [t, s]);
    fs.writeFileSync(`${__dirname}/needles/${t}_${s}.png`, Buffer.from(url.split(',')[1], 'base64'));
  }
  console.log('rendered', jobs.length);
  await browser.close();
})();

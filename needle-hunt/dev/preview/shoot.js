const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch({ args: ['--use-gl=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  page.on('console', m => { if (m.type() === 'error') console.log('ERR', m.text()); });
  page.on('pageerror', e => console.log('PAGEERR', e.message));
  const jobs = process.argv.slice(2);
  for (const job of jobs) {
    const [map, view] = job.split(':');
    await page.goto(`file://${__dirname}/render.html?map=${map}&view=${view}&needleSeed=${process.env.NS || 5}&powerups=${process.env.PU || ''}&spawn=${process.env.SP || 0}&ahead=${process.env.AH || 1}`);
    await page.waitForFunction(() => window.DONE, null, { timeout: 120000 });
    const info = await page.evaluate(() => ({ done: window.DONE, needle: window.NEEDLE_SCREEN }));
    await page.screenshot({ path: `${map}_${view}.png` });
    console.log(job, JSON.stringify(info));
  }
  await browser.close();
})();

// Screenshot + console-error check for the running netroot-io site.
// chromium-cli isn't installed in this environment, so this hand-rolled
// Playwright script is the driver of record — see SKILL.md.
//
// Usage: node driver.mjs [url] [screenshot-path]
//   node driver.mjs http://127.0.0.1:8899/ /tmp/netroot.png

import { chromium } from 'playwright';

const url = process.argv[2] || 'http://127.0.0.1:8899/';
const outPath = process.argv[3] || '/tmp/netroot-io-screenshot.png';

(async () => {
  const browser = await chromium.launch({ args: ['--no-sandbox'] });
  const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });
  const errors = [];
  page.on('console', (msg) => { if (msg.type() === 'error') errors.push(msg.text()); });
  page.on('pageerror', (err) => errors.push(err.message));

  await page.goto(url, { waitUntil: 'networkidle' });
  await page.screenshot({ path: outPath, fullPage: true });

  console.log('TITLE:', await page.title());
  console.log('SCREENSHOT:', outPath);
  console.log('CONSOLE_ERRORS:', JSON.stringify(errors));

  await browser.close();
  process.exit(errors.length ? 1 : 0);
})();

#!/usr/bin/env node

const fs = require('node:fs');
const path = require('node:path');
const { pathToFileURL } = require('node:url');
const { createRequire } = require('node:module');

const args = process.argv.slice(2);
if (args.length !== 2) {
  console.error('Usage: render_report_browser.cjs <input-html> <output-pdf>');
  process.exit(1);
}

const [inputHtml, outputPdf] = args;
if (!fs.existsSync(inputHtml)) {
  console.error(`Input HTML file not found: ${inputHtml}`);
  process.exit(1);
}

const rendererPackage = path.resolve(__dirname, '..', '.report-renderer', 'package.json');
if (!fs.existsSync(rendererPackage)) {
  console.error('Local Playwright renderer package is missing. Install it under .report-renderer/.');
  process.exit(1);
}

const requireFromRenderer = createRequire(rendererPackage);
const { chromium } = requireFromRenderer('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({
    viewport: {
      width: 816,
      height: 1056,
    },
  });

  await page.emulateMedia({ media: 'print' });

  await page.goto(pathToFileURL(path.resolve(inputHtml)).href, {
    waitUntil: 'load',
  });

  await page.waitForFunction(() => document.body.dataset.reportReady === '1');
  await page.evaluate(() => document.fonts && document.fonts.ready);

  await page.pdf({
    path: outputPdf,
    format: 'Letter',
    preferCSSPageSize: true,
    printBackground: true,
    displayHeaderFooter: false,
    margin: {
      top: '0mm',
      right: '0mm',
      bottom: '0mm',
      left: '0mm',
    },
  });

  await browser.close();
})().catch((error) => {
  console.error(error instanceof Error ? error.stack || error.message : String(error));
  process.exit(1);
});

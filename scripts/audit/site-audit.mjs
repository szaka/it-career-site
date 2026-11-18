import { createRequire } from 'node:module';
import { spawn } from 'node:child_process';
import { readdir, writeFile } from 'node:fs/promises';
import { resolve, relative } from 'node:path';

const require = createRequire(resolve(process.env.AUDIT_TOOLS, 'package.json'));
const { chromium, firefox, webkit } = require('playwright');
const AxeBuilder = require('@axe-core/playwright').default;
const origin = 'http://127.0.0.1:4330';
const results = [];
async function pages(dir) {
  const output = [];
  for (const entry of await readdir(dir, { withFileTypes: true })) {
    const path = resolve(dir, entry.name);
    if (entry.isDirectory()) output.push(...await pages(path));
    else if (entry.name.endsWith('.html')) output.push('/' + relative(resolve('dist'), path).replace(/index\.html$/, ''));
  }
  return output;
}
function record(name, ok, detail = '') {
  results.push({ name, ok, detail });
  console.log(`${ok ? 'PASS' : 'FAIL'} ${name}${detail ? ' — ' + detail : ''}`);
}
const server = spawn('npm', ['run', 'preview', '--', '--host', '127.0.0.1', '--port', '4330'], { stdio: 'ignore' });
try {
  let ready = false;
  for (let attempt = 0; attempt < 100; attempt++) {
    try { ready = (await fetch(origin)).ok; } catch {}
    if (ready) break;
    await new Promise((resolve) => setTimeout(resolve, 200));
  }
  if (!ready) throw new Error('Preview did not start on port 4330.');
  const routes = await pages(resolve('dist'));
  for (const [engine, browserType] of Object.entries({ chromium, firefox, webkit })) {
    let browser;
    try {
      browser = await browserType.launch();
    } catch (error) {
      record(`${engine} browser launch`, false, error.message);
      continue;
    }
    try {
      for (const width of [320, 390, 768, 1280]) {
        for (const mode of ['light', 'dark']) {
          const context = await browser.newContext({ viewport: { width, height: 900 }, colorScheme: mode });
          await context.addInitScript(() => localStorage.setItem('portfolio-analytics-consent-v1', 'reject'));
          const page = await context.newPage();
          const errors = [];
          page.on('pageerror', (error) => errors.push(error.message));
          try {
            for (const route of routes) {
              const label = `${engine} ${width}px ${mode} ${route}`;
              errors.length = 0;
              const response = await page.goto(origin + route);
              await page.evaluate(() => document.fonts.ready);
              record(label + ' response', response.ok());
              const structure = await page.evaluate(() => ({
                title: document.title.trim(),
                language: document.documentElement.lang,
                h1: document.querySelectorAll('h1').length,
                overflow: document.documentElement.scrollWidth > innerWidth + 1,
                imageIssues: [...document.images].filter((img) => !img.hasAttribute('alt') || !img.getAttribute('width') || !img.getAttribute('height')).map((img) => img.src),
              }));
              record(label + ' structure/reflow', Boolean(structure.title) && structure.language === 'en' && structure.h1 === 1 && !structure.overflow && !structure.imageIssues.length, JSON.stringify(structure));
              const axe = await new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa', 'wcag21aa', 'wcag22aa']).analyze();
              record(label + ' axe', axe.violations.length === 0, axe.violations.map((issue) => `${issue.id}: ${issue.nodes.map((node) => node.target.join(' ')).join(', ')}`).join('; '));
              if (axe.incomplete.length) console.log('REVIEW', label, JSON.stringify(axe.incomplete.map((issue) => ({
                id: issue.id,
                nodes: issue.nodes.map((node) => ({
                  target: node.target,
                  summary: node.failureSummary,
                })),
              }))));
              record(label + ' JavaScript', errors.length === 0, errors.join('; '));
            }
            for (const [route, topic, search, count] of [
              ['/blog/', '[data-blog-topic]', '#blog-search', '[data-blog-search-status]'],
              ['/projects/', '[data-project-topic]', '[data-project-search]', '[data-project-count]'],
            ]) {
              await page.goto(origin + route);
              await page.locator(topic).selectOption({ label: 'GitHub Pages' });
              await page.locator(search).fill('zzzz-no-match');
              record(`${engine} ${width} ${mode} ${route} empty state`, /0 projects|No matching posts/.test(await page.locator(count).innerText()));
              await page.locator(route === '/blog/' ? '[data-blog-search-reset]' : '[data-project-reset]').click();
              record(`${engine} ${width} ${mode} ${route} reset`, await page.locator(topic).inputValue() === '' && await page.locator(search).inputValue() === '');
            }
            await page.goto(origin + '/');
            await page.locator('.skip-link').focus();
            await page.keyboard.press('Enter');
            record(`${engine} skip link`, await page.evaluate(() => document.activeElement?.id === 'main-content'));
            const settingsToggle = page.locator('[data-footer-settings-toggle]');
            if (await settingsToggle.getAttribute('aria-expanded') !== 'true') {
              await settingsToggle.click();
            }
            await page.locator('#site-appearance').waitFor({ state: 'visible' });
            await page.locator('#site-appearance').selectOption('dark');
            record(`${engine} theme override`, await page.evaluate(() => document.documentElement.dataset.siteAppearance === 'dark'));
            await page.locator('[data-preferences]').click();
            await page.locator('[data-choice="reject"]').click();
            record(`${engine} consent reject`, await page.evaluate(() => localStorage.getItem('portfolio-analytics-consent-v1') === 'reject'));
          } finally { await context.close(); }
        }
      }
    } finally { await browser.close(); }
  }
} catch (error) { record('Audit execution', false, error.stack); }
finally {
  server.kill('SIGTERM');
  await writeFile('site-audit-results.json', JSON.stringify(results, null, 2));
}
console.log(`${results.filter((result) => !result.ok).length} failures across ${results.length} checks.`);
process.exitCode = results.some((result) => !result.ok) ? 1 : 0;

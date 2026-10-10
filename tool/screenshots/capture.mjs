// Plays through CodeQuest in a headless browser and saves screenshots plus
// video frames. Used by .github/workflows/screenshots.yml.
//
//   WEB_ROOT=build/web OUT_DIR=docs/screenshots FRAMES_DIR=/tmp/frames \
//     node tool/screenshots/capture.mjs
//
// It serves build/web locally with the same security headers as vercel.json,
// so it also checks that the Content-Security-Policy does not break the app.

import { createServer } from 'node:http';
import { mkdir, readFile, stat } from 'node:fs/promises';
import { extname, join, normalize, resolve } from 'node:path';
import puppeteer from 'puppeteer';

const ROOT = resolve(process.env.WEB_ROOT || 'build/web');
const OUT = resolve(process.env.OUT_DIR || 'docs/screenshots');
const FRAMES = process.env.FRAMES_DIR ? resolve(process.env.FRAMES_DIR) : '';
const PORT = Number(process.env.PORT || 8089);
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// ---------------------------------------------------------------- server ---
const vercel = JSON.parse(await readFile('vercel.json', 'utf8'));
const securityHeaders = Object.fromEntries(vercel.headers[0].headers.map((h) => [h.key, h.value]));
delete securityHeaders['Strict-Transport-Security'];
// Plain http on localhost: do not upgrade requests to https.
securityHeaders['Content-Security-Policy'] = securityHeaders['Content-Security-Policy']
  .replace(/;\s*upgrade-insecure-requests/, '');

const TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript',
  '.mjs': 'text/javascript',
  '.wasm': 'application/wasm',
  '.json': 'application/json',
  '.png': 'image/png',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
};

const server = createServer(async (req, res) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);
  if (url.pathname.startsWith('/api/')) {
    res.writeHead(503, { 'Content-Type': 'application/json' });
    res.end('{"error":"AI tutor is not configured."}');
    return;
  }
  let path = normalize(join(ROOT, decodeURIComponent(url.pathname)));
  if (!path.startsWith(ROOT)) {
    res.writeHead(403).end();
    return;
  }
  try {
    if ((await stat(path)).isDirectory()) path = join(path, 'index.html');
    const body = await readFile(path);
    res.writeHead(200, {
      ...securityHeaders,
      'Content-Type': TYPES[extname(path)] || 'application/octet-stream',
    });
    res.end(body);
  } catch {
    res.writeHead(404).end('not found');
  }
});
await new Promise((r) => server.listen(PORT, r));

// --------------------------------------------------------------- browser ---
await mkdir(OUT, { recursive: true });
if (FRAMES) await mkdir(FRAMES, { recursive: true });

const browser = await puppeteer.launch({
  headless: true,
  executablePath: process.env.CHROME_PATH || undefined,
  args: ['--no-sandbox', '--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'],
});
const page = await browser.newPage();
const problems = [];
page.on('console', (msg) => {
  const text = msg.text();
  if (msg.type() === 'error' || /Content Security Policy/i.test(text)) problems.push(text);
});
page.on('pageerror', (err) => problems.push(String(err)));

let recording = false;
let frame = 0;
async function recordLoop() {
  while (recording) {
    try {
      await page.screenshot({
        path: join(FRAMES, `${String(frame++).padStart(5, '0')}.jpg`),
        type: 'jpeg',
        quality: 70,
      });
    } catch {
      // page may be navigating; skip this frame
    }
    await sleep(120);
  }
}

/** Finds the smallest semantics element whose label/text contains `text`. */
async function locate(text, { timeout = 15000, exact = false } = {}) {
  const end = Date.now() + timeout;
  while (Date.now() < end) {
    const hit = await page.evaluate(
      (needle, exactMatch) => {
        let best = null;
        for (const el of document.querySelectorAll('flt-semantics, [role], [aria-label]')) {
          const label = (el.getAttribute('aria-label') || el.textContent || '').trim();
          const ok = exactMatch ? label === needle : label.includes(needle);
          if (!ok) continue;
          const r = el.getBoundingClientRect();
          if (r.width < 2 || r.height < 2 || r.bottom < 0 || r.top > innerHeight) continue;
          const area = r.width * r.height;
          if (!best || area < best.area) best = { x: r.x + r.width / 2, y: r.y + r.height / 2, area };
        }
        return best;
      },
      text,
      exact,
    );
    if (hit) return hit;
    await sleep(250);
  }
  throw new Error(`Could not find "${text}" on screen`);
}

async function tap(text, opts) {
  const p = await locate(text, opts);
  await page.mouse.click(p.x, p.y);
  await sleep(700);
}

async function shot(name) {
  await sleep(500);
  await page.screenshot({ path: join(OUT, `${name}.png`) });
  console.log('saved', name);
}

async function scroll(dy) {
  await page.mouse.move(640, 500);
  await page.mouse.wheel({ deltaY: dy });
  await sleep(600);
}

// The right answers for the Python world (options are shuffled in game).
const runnerAnswers = ['print("Hi")', '5', '#', 'HiHiHi', 'Indentation'];
const battleAnswers = ["<class 'str'>", 'my_score', '15', 'float', 'Hi Om'];

try {
  await page.setViewport({ width: 1280, height: 860, deviceScaleFactor: 1 });
  await page.goto(`http://localhost:${PORT}/`, { waitUntil: 'networkidle0', timeout: 60000 });
  await locate('Choose your world', { timeout: 60000 });
  await sleep(1500);
  if (FRAMES) {
    recording = true;
    recordLoop();
  }
  await shot('01-home');

  // World map
  await tap('Python Jungle');
  await shot('02-world-map');

  // Lesson
  await tap('Level 1: Hello, Python!');
  await shot('03-lesson');

  // Runner game
  await tap('Start Code Runner');
  await sleep(1800);
  await shot('04-runner');
  for (let i = 0; i < runnerAnswers.length; i++) {
    await tap(`: ${runnerAnswers[i]}`, { exact: false });
    await tap('Run through gate');
    if (i === 0) await shot('05-runner-correct');
    await tap(i === runnerAnswers.length - 1 ? 'See results' : 'Next gate');
  }
  await sleep(800);
  await shot('06-results');

  // Battle level (show one mistake first, then win)
  await tap('Next: Variables & Types');
  await tap('Start Bug Battle');
  await sleep(800);
  await shot('07-battle');
  await tap('Move', { exact: false }); // first move button - may be wrong
  await sleep(600);
  await shot('08-battle-feedback');
  await tap('Next move').catch(() => tap('See results'));
  for (let guard = 0; guard < 12; guard++) {
    if (await locate('See results', { timeout: 400 }).then(() => true).catch(() => false)) break;
    let hit = null;
    for (const a of battleAnswers) {
      hit = await locate(`Move`, { timeout: 200 })
        .then(() => locate(`: ${a}`, { timeout: 200 }))
        .catch(() => null);
      if (hit) break;
    }
    if (!hit) break;
    await page.mouse.click(hit.x, hit.y);
    await sleep(700);
    await tap('Next move', { timeout: 1500 }).catch(() => {});
  }
  await tap('See results').catch(() => {});
  await sleep(800);

  // Puzzle level
  await tap('Next: If / Else Decisions').catch(() => {});
  await tap('Start Block Builder').catch(() => {});
  await sleep(800);
  for (const line of ['age = 20', 'if age >= 18:', 'print("Adult")', 'else:']) {
    await tap(`Add block: ${line}`).catch(() => {});
  }
  await shot('09-puzzle');
  await page.goto(`http://localhost:${PORT}/`, { waitUntil: 'networkidle0' });
  await locate('Choose your world', { timeout: 60000 });

  // Doubt Buddy
  await tap('Doubt Buddy');
  await tap('What is a pointer in C?');
  await sleep(1200);
  await shot('10-doubt-buddy');

  // Settings with high contrast
  await page.goto(`http://localhost:${PORT}/`, { waitUntil: 'networkidle0' });
  await locate('Choose your world', { timeout: 60000 });
  await tap('Settings and accessibility');
  await tap('High contrast');
  await sleep(600);
  await shot('11-settings-high-contrast');
  await tap('High contrast');

  // Mobile view
  recording = false;
  await page.setViewport({ width: 390, height: 844, deviceScaleFactor: 2, isMobile: true, hasTouch: true });
  await page.goto(`http://localhost:${PORT}/`, { waitUntil: 'networkidle0' });
  await locate('Choose your world', { timeout: 60000 });
  await sleep(1200);
  await shot('12-mobile-home');
} catch (err) {
  console.error('Capture failed:', err.message);
  await page.screenshot({ path: join(OUT, 'zz-error.png') }).catch(() => {});
  process.exitCode = 1;
} finally {
  recording = false;
  await sleep(300);
  console.log(`frames: ${frame}`);
  if (problems.length) {
    console.log('Browser console errors / CSP reports:');
    for (const p of problems) console.log(' -', p.slice(0, 300));
  } else {
    console.log('No console errors and no CSP violations.');
  }
  await browser.close();
  server.close();
}

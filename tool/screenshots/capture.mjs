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

/**
 * Like locate(), but waits until the element has stopped moving (panels slide
 * and pop in) and its centre is inside the window, so the click lands on it.
 */
async function locateStable(text, opts = {}) {
  const end = Date.now() + (opts.timeout ?? 15000);
  let last = null;
  let inViewSince = 0;
  while (Date.now() < end) {
    const p = await locate(text, { ...opts, timeout: Math.max(300, end - Date.now()) });
    const viewportHeight = await page.evaluate(() => innerHeight);
    const inView = p.y > 2 && p.y < viewportHeight - 2;
    if (!inView) {
      last = null;
      inViewSince = 0;
    } else {
      inViewSince ||= Date.now();
      // Small idle bobbing is fine; sliding panels move much more than 4px.
      const settled = last && Math.abs(last.x - p.x) < 4 && Math.abs(last.y - p.y) < 4;
      if (settled || Date.now() - inViewSince > 2500) return p;
      last = p;
    }
    await sleep(200);
  }
  throw new Error(`"${text}" never settled on screen`);
}

async function tap(text, opts) {
  const p = await locateStable(text, opts);
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

/** Scrolls down until `text` is on screen, then taps it. */
async function tapScrolling(text, opts = {}) {
  for (let i = 0; i < 10; i++) {
    const hit = await locateStable(text, { ...opts, timeout: 1200 }).catch(() => null);
    if (hit) {
      await page.mouse.click(hit.x, hit.y);
      await sleep(700);
      return;
    }
    await scroll(450);
  }
  throw new Error(`Could not scroll to "${text}"`);
}

/** Taps a battle move whose label is NOT one of the right answers. */
async function tapWrongMove(rightAnswers) {
  for (let attempt = 0; attempt < 6; attempt++) {
    const hit = await page.evaluate((answers) => {
      let best = null;
      for (const el of document.querySelectorAll('flt-semantics, [role], [aria-label]')) {
        const label = (el.getAttribute('aria-label') || el.textContent || '').trim();
        if (!/^Move \d: /.test(label) || /removed/.test(label)) continue;
        if (answers.some((a) => label.endsWith(`: ${a}`))) continue;
        const r = el.getBoundingClientRect();
        if (r.width < 2 || r.height < 2 || r.bottom < 0 || r.top > innerHeight) continue;
        const area = r.width * r.height;
        if (!best || area < best.area) best = { x: r.x + r.width / 2, y: r.y + r.height / 2, area };
      }
      return best;
    }, rightAnswers);
    if (hit) {
      await page.mouse.click(hit.x, hit.y);
      await sleep(250);
      return;
    }
    await scroll(400);
  }
  throw new Error('No wrong move found');
}

async function goHome() {
  await page.goto(`http://localhost:${PORT}/`, { waitUntil: 'networkidle0', timeout: 60000 });
  await tap('Play', { timeout: 60000, exact: true });
  await locate('Choose your world');
  await sleep(800);
}

// The right answers for the Python world (options are shuffled in game).
const runnerAnswers = ['print("Hi")', '5', '#', 'HiHiHi', 'Indentation'];
const battleAnswers = ["<class 'str'>", 'my_score', '15', 'float', 'Hi Om'];
const puzzleLines = ['age = 20', 'if age >= 18:', 'print("Adult")', 'else:', 'print("Kid")'];

try {
  await page.setViewport({ width: 1280, height: 860, deviceScaleFactor: 1 });
  await page.goto(`http://localhost:${PORT}/`, { waitUntil: 'networkidle0', timeout: 60000 });
  await locate('Play', { timeout: 60000, exact: true });
  await sleep(1500);
  if (FRAMES) {
    recording = true;
    recordLoop();
  }
  await shot('00-title');
  await tap('Play', { exact: true });
  await locate('Choose your world');
  await sleep(900);
  await shot('01-home');

  // World map
  await tap('Python Jungle.');
  await sleep(600);
  await shot('02-world-map');

  // Lesson
  await tap('Level 1: Hello, Python!');
  await sleep(1400);
  await shot('03-lesson');

  // Code Runner (action game): film Byte's demo run - real running, jumping,
  // sliding, coins and code gates.
  await tapScrolling('Watch Byte play');
  await sleep(5500); // page change + 3-2-1 countdown
  await shot('04-runner');
  // The first code gate is close: Byte switches to the right lane.
  await locate('Choose now!', { timeout: 40000 });
  await sleep(700);
  await shot('05-runner-correct');
  // Through the gate: the explanation pops up.
  await locate('+5 coins', { timeout: 20000 });
  await sleep(300);
  await shot('05b-runner-action');
  // The demo ends back on the lesson.
  await locate('Watch Byte play', { timeout: 150000 });
  await sleep(800);

  // Play level 1 for real in the calm, step-by-step runner ("No timer"),
  // which a script can drive, to unlock the next levels.
  const wasRecording = recording;
  recording = false;
  await goHome();
  await tap('Settings and accessibility');
  await tapScrolling('No timer');
  await sleep(500);
  await goHome();
  await tap('Python Jungle.');
  await sleep(600);
  await tap('Level 1: Hello, Python!');
  await sleep(1000);
  await tapScrolling('Start Code Runner');
  await sleep(1500);
  for (let i = 0; i < runnerAnswers.length; i++) {
    await tap(`: ${runnerAnswers[i]}`, { exact: false });
    await tap('Run through gate');
    await tapScrolling(i === runnerAnswers.length - 1 ? 'See results' : 'Next gate');
    await sleep(600);
  }
  recording = wasRecording;
  if (recording) recordLoop();
  await sleep(1800);
  await shot('06-results');

  // Battle: hit, then one miss, then win
  await tapScrolling('Next: Variables & Types');
  await sleep(600);
  await tapScrolling('Start Bug Battle');
  await sleep(1200);
  await shot('07-battle');
  let attacked = false;
  for (const a of battleAnswers) {
    const hit = await locate(`: ${a}`, { timeout: 300 }).catch(() => null);
    if (hit) {
      await page.mouse.click(hit.x, hit.y);
      attacked = true;
      break;
    }
  }
  if (attacked) {
    await sleep(180);
    await page.screenshot({ path: join(OUT, '08-battle-attack.png') });
    console.log('saved 08-battle-attack');
    await sleep(1200);
    await tapScrolling('Next move');
    await sleep(700);
    await tapWrongMove(battleAnswers);
    await sleep(900);
    await shot('09-battle-miss');
    await tapScrolling('Next move');
  }
  for (let guard = 0; guard < 12; guard++) {
    if (await locate('See results', { timeout: 400 }).then(() => true).catch(() => false)) break;
    let hit = null;
    for (const a of battleAnswers) {
      hit = await locate(`: ${a}`, { timeout: 200 }).catch(() => null);
      if (hit) break;
    }
    if (!hit) {
      await scroll(400);
      continue;
    }
    await page.mouse.click(hit.x, hit.y);
    await sleep(900);
    await tapScrolling('Next move', { timeout: 1500 }).catch(() => {});
  }
  await tapScrolling('See results').catch(() => {});
  await sleep(1500);

  // Puzzle: build the program, then run it
  await tapScrolling('Next: If / Else Decisions');
  await sleep(600);
  await tapScrolling('Start Block Builder');
  await sleep(800);
  for (const [i, line] of puzzleLines.entries()) {
    await tapScrolling(`Add block: ${line}`);
    if (i === 2) await shot('10-puzzle');
  }
  await tapScrolling('Run code');
  await sleep(1500);
  await shot('11-puzzle-run');

  // Trophy room
  await goHome();
  await tap('Trophy room');
  await sleep(800);
  await shot('12-trophies');

  // Doubt Buddy
  await goHome();
  await tap('Doubt Buddy');
  await sleep(600);
  await tap('What is a pointer in C?');
  await sleep(1600);
  await shot('13-doubt-buddy');

  // High-contrast mode
  await goHome();
  await tap('Settings and accessibility');
  await tap('High contrast');
  await sleep(800);
  await shot('14-high-contrast');
  await tap('High contrast');

  // Phone size
  recording = false;
  await page.setViewport({ width: 390, height: 844, deviceScaleFactor: 2, isMobile: true, hasTouch: true });
  await page.goto(`http://localhost:${PORT}/`, { waitUntil: 'networkidle0' });
  await locate('Play', { timeout: 60000, exact: true });
  await sleep(1500);
  await shot('15-mobile-title');
  await tap('Play', { exact: true });
  await locate('Choose your world');
  await sleep(1000);
  await shot('16-mobile-home');
  await tap('C Caves.');
  await sleep(900);
  await shot('17-mobile-map');
} catch (err) {
  console.error('Capture failed:', err.message);
  await page.screenshot({ path: join(OUT, 'zz-error.png') }).catch(() => {});
  // Print what a screen reader would see, to make failures easy to debug.
  const labels = await page
    .evaluate(() =>
      [...document.querySelectorAll('[aria-label], flt-semantics')]
        .map((el) => {
          const r = el.getBoundingClientRect();
          const label = (el.getAttribute('aria-label') || '').trim();
          return label ? `${label.slice(0, 70)} @${Math.round(r.x)},${Math.round(r.y)} ${Math.round(r.width)}x${Math.round(r.height)}` : '';
        })
        .filter(Boolean)
        .slice(0, 60),
    )
    .catch(() => []);
  console.error('On screen:\n  ' + labels.join('\n  '));
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

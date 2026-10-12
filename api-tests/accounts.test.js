// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

// Tests for player accounts. The most important one: a player can never see
// or change another player's progress.

import assert from 'node:assert/strict';
import { test } from 'node:test';

import { createAccountHandler } from '../api/_lib/account-handler.js';
import {
  accountIdFor,
  cleanName,
  createSessionToken,
  hashPassword,
  normalizeEmail,
  passwordProblem,
  readSessionToken,
  sessionCookie,
  tokenFromRequest,
  validateProgress,
  verifyPassword,
} from '../api/_lib/accounts.js';
import { createSecretsLoader, SECRETS_PATH } from '../api/_lib/secrets.js';
import { createMemoryStore, StoreConflictError } from '../api/_lib/store.js';

const SECRET = 's'.repeat(40);
const NO_ENV = {}; // force secrets to come from the store

function fakeRes() {
  return {
    statusCode: 0,
    headers: {},
    body: '',
    setHeader(k, v) {
      this.headers[k.toLowerCase()] = v;
    },
    status(code) {
      this.statusCode = code;
      return this;
    },
    send(b) {
      this.body = b;
      return this;
    },
    get json() {
      return JSON.parse(this.body);
    },
  };
}

/** A pretend browser: remembers the session cookie like a real one would. */
function browser(handler, ip = '10.1.1.1') {
  let cookie = null;
  return {
    get cookie() {
      return cookie;
    },
    async call(method, body, headers = {}) {
      const res = fakeRes();
      await handler(
        {
          method,
          body,
          headers: {
            host: 'codequest.vercel.app',
            origin: 'https://codequest.vercel.app',
            'content-type': 'application/json',
            'x-forwarded-for': ip,
            ...(cookie ? { cookie: `cq_session=${cookie}` } : {}),
            ...headers,
          },
        },
        res,
      );
      const setCookie = res.headers['set-cookie'];
      if (setCookie) {
        const value = setCookie.split(';')[0].split('=').slice(1).join('=');
        cookie = value || null;
      }
      return res;
    },
  };
}

const progressA = { version: 1, stars: { 'py-1': 3, 'py-2': 2 }, xp: 120, coins: 40, achievements: ['first_steps'] };
const progressB = { version: 1, stars: { 'java-1': 1 }, xp: 10, coins: 5 };

function setup(options = {}) {
  const store = createMemoryStore();
  let clock = Date.parse('2026-10-12T10:00:00Z');
  const handler = createAccountHandler({ store, env: NO_ENV, now: () => clock, ...options });
  return { store, handler, tick: (ms) => (clock += ms) };
}

// ---- pure helpers -------------------------------------------------------

test('emails are tidied and checked', () => {
  assert.equal(normalizeEmail('  Om.Shiva@Example.COM '), 'om.shiva@example.com');
  assert.equal(normalizeEmail('not-an-email'), '');
  assert.equal(normalizeEmail('a@b'), '');
  assert.equal(normalizeEmail(`${'a'.repeat(250)}@x.com`), '');
  assert.equal(normalizeEmail(42), '');
});

test('names are tidied and checked', () => {
  assert.equal(cleanName('  Om   Shiva '), 'Om Shiva');
  assert.equal(cleanName('ஓம்'), 'ஓம்'); // Tamil letters are fine
  assert.equal(cleanName('x'), '');
  assert.equal(cleanName('<script>'), '');
  assert.equal(cleanName('a'.repeat(21)), '');
});

test('weak passwords are refused with a clear reason', () => {
  assert.match(passwordProblem('short'), /at least 8/);
  assert.match(passwordProblem('password123'), /too easy/);
  assert.match(passwordProblem('om@ex.com', 'om@ex.com'), /at least 8|email/);
  assert.match(passwordProblem('omshiva24@ex.com', 'omshiva24@ex.com'), /email/);
  assert.equal(passwordProblem('blue-tiger-42'), null);
});

test('passwords are hashed with a salt and verified', async () => {
  const a = await hashPassword('blue-tiger-42');
  const b = await hashPassword('blue-tiger-42');
  assert.notEqual(a, b, 'same password, different salt');
  assert.doesNotMatch(a, /blue-tiger/);
  assert.equal(await verifyPassword('blue-tiger-42', a), true);
  assert.equal(await verifyPassword('blue-tiger-43', a), false);
  assert.equal(await verifyPassword('blue-tiger-42', 'scrypt$1048576$8$1$xx$yy'), false, 'refuses costly params');
  assert.equal(await verifyPassword('blue-tiger-42', 'garbage'), false);
});

test('account ids hide the email', () => {
  const id = accountIdFor('om@example.com', SECRET);
  assert.match(id, /^[0-9a-f]{64}$/);
  assert.equal(id, accountIdFor('om@example.com', SECRET));
  assert.notEqual(id, accountIdFor('om@example.com', 't'.repeat(40)));
  assert.doesNotMatch(id, /om|example/);
});

test('session tokens: valid, tampered and expired', () => {
  const id = accountIdFor('om@example.com', SECRET);
  const now = Date.parse('2026-10-12T10:00:00Z');
  const token = createSessionToken(id, SECRET, now);
  assert.equal(readSessionToken(token, SECRET, now), id);
  // Changing the account id breaks the signature.
  const other = accountIdFor('someone@else.com', SECRET);
  assert.equal(readSessionToken(token.replace(id, other), SECRET, now), null);
  assert.equal(readSessionToken(token, 'x'.repeat(40), now), null, 'wrong secret');
  assert.equal(readSessionToken(token, SECRET, now + 31 * 24 * 3600 * 1000), null, 'expired');
  assert.equal(readSessionToken('v1.abc.1.sig', SECRET, now), null);
  assert.equal(readSessionToken(undefined, SECRET, now), null);
});

test('session cookie is HttpOnly, Secure, SameSite=Strict and only sent to /api', () => {
  const c = sessionCookie('tok');
  for (const part of ['HttpOnly', 'Secure', 'SameSite=Strict', 'Path=/api']) assert.ok(c.includes(part), part);
  assert.equal(tokenFromRequest({ cookie: 'a=1; cq_session=tok; b=2' }), 'tok');
  assert.equal(tokenFromRequest({ authorization: 'Bearer abc' }), 'abc');
  assert.equal(tokenFromRequest({}), null);
});

test('progress is validated field by field', () => {
  assert.equal(validateProgress(progressA).ok, true);
  assert.equal(validateProgress({ ...progressA, settings: { highContrast: true, timerMode: 'off' } }).ok, true);
  assert.equal(validateProgress(null).ok, false);
  assert.equal(validateProgress([]).ok, false);
  assert.equal(validateProgress({ admin: true }).ok, false);
  assert.equal(validateProgress({ xp: -1 }).ok, false);
  assert.equal(validateProgress({ xp: 1.5 }).ok, false);
  assert.equal(validateProgress({ stars: { 'py-1': 9 } }).ok, false);
  assert.equal(validateProgress({ stars: { '../evil': 1 } }).ok, false);
  assert.equal(validateProgress({ settings: { evil: 1 } }).ok, false);
  assert.equal(validateProgress({ achievements: ['x'.repeat(41)] }).ok, false);
  assert.equal(validateProgress({ achievements: Array(30000).fill('a') }).ok, false, 'too large');
});

test('secrets are created once and then reused', async () => {
  const store = createMemoryStore();
  const first = await createSecretsLoader(store, NO_ENV)();
  const second = await createSecretsLoader(store, NO_ENV)();
  assert.deepEqual(first, second);
  assert.ok(first.session.length >= 32 && first.accountId.length >= 32);
  assert.notEqual(first.session, first.accountId);
  // Environment secrets win when set.
  const fromEnv = await createSecretsLoader(store, { SESSION_SECRET: SECRET, ACCOUNT_ID_SECRET: 'a'.repeat(32) })();
  assert.equal(fromEnv.session, SECRET);
});

test('two servers creating secrets at once agree on one set', async () => {
  const store = createMemoryStore();
  const realPut = store.putJson;
  // The other server writes first, between our read and our write.
  store.putJson = async (path, value, opts) => {
    if (path === SECRETS_PATH && !store.files.has(path)) {
      await realPut(path, { v: 1, session: 'w'.repeat(43), accountId: 'z'.repeat(43) });
    }
    return realPut(path, value, opts);
  };
  const secrets = await createSecretsLoader(store, NO_ENV)();
  assert.equal(secrets.session, 'w'.repeat(43));
});

test('memory store refuses to overwrite when asked not to', async () => {
  const store = createMemoryStore();
  await store.putJson('a', { x: 1 }, { overwrite: false });
  await assert.rejects(store.putJson('a', { x: 2 }, { overwrite: false }), StoreConflictError);
});

// ---- the API -------------------------------------------------------------

test('a guest with no session gets 401 without any storage use', async () => {
  const store = createMemoryStore();
  let reads = 0;
  const realGet = store.getJson;
  store.getJson = async (p) => {
    reads++;
    return realGet(p);
  };
  const handler = createAccountHandler({ store, env: NO_ENV });
  const res = await browser(handler).call('GET');
  assert.equal(res.statusCode, 401);
  assert.equal(reads, 0);
  assert.equal(res.headers['cache-control'], 'no-store');
});

test('register, see my progress, save, log out, log back in', async () => {
  const { handler, store } = setup();
  const om = browser(handler);

  let res = await om.call('POST', { action: 'register', name: 'Om', email: 'Om@Example.com', password: 'blue-tiger-42', progress: progressA });
  assert.equal(res.statusCode, 201);
  assert.equal(res.json.user.name, 'Om');
  assert.deepEqual(res.json.progress, progressA);
  assert.equal(res.json.token, undefined, 'web never sees the token');
  assert.ok(om.cookie);
  assert.match(res.headers['set-cookie'], /HttpOnly/);

  // Nothing stored contains the email or the password.
  const everything = [...store.files.values()].join('\n');
  assert.doesNotMatch(everything, /example\.com|blue-tiger/i);

  res = await om.call('GET');
  assert.equal(res.statusCode, 200);
  assert.deepEqual(res.json.progress, progressA);

  const more = { ...progressA, xp: 999 };
  res = await om.call('PUT', { progress: more });
  assert.equal(res.statusCode, 200);

  res = await om.call('POST', { action: 'logout' });
  assert.equal(res.statusCode, 200);
  assert.equal(om.cookie, null);
  assert.equal((await om.call('GET')).statusCode, 401);

  res = await om.call('POST', { action: 'login', email: ' om@example.COM ', password: 'blue-tiger-42' });
  assert.equal(res.statusCode, 200);
  assert.equal(res.json.progress.xp, 999);
});

test('a new player starts fresh and NEVER sees another player\'s progress', async () => {
  const { handler } = setup();
  const om = browser(handler, '10.0.0.1');
  const friend = browser(handler, '10.0.0.2');

  await om.call('POST', { action: 'register', name: 'Om', email: 'om@example.com', password: 'blue-tiger-42', progress: progressA });
  let res = await friend.call('POST', { action: 'register', name: 'Priya', email: 'priya@example.com', password: 'green-lion-77' });
  assert.equal(res.statusCode, 201);
  assert.equal(res.json.progress, null, 'new player starts at zero');

  res = await friend.call('GET');
  assert.equal(res.json.user.name, 'Priya');
  assert.equal(res.json.progress, null);

  await friend.call('PUT', { progress: progressB });
  assert.deepEqual((await friend.call('GET')).json.progress, progressB);
  assert.deepEqual((await om.call('GET')).json.progress, progressA, 'Om\'s save is untouched');

  // The friend cannot pick whose file to read: the account comes from the
  // signed session only, and extra fields are refused.
  res = await friend.call('PUT', { progress: progressB, account: 'om@example.com' });
  assert.equal(res.statusCode, 400);
});

test('a forged or tampered session is refused', async () => {
  const { handler } = setup();
  const om = browser(handler);
  await om.call('POST', { action: 'register', name: 'Om', email: 'om@example.com', password: 'blue-tiger-42' });
  const [v, id, exp] = om.cookie.split('.');

  const attacker = browser(handler, '10.9.9.9');
  let res = await attacker.call('GET', undefined, { cookie: `cq_session=${v}.${id}.${exp}.forged` });
  assert.equal(res.statusCode, 401);
  res = await attacker.call('GET', undefined, { cookie: `cq_session=${v}.${id}.${Number(exp) + 999}.${om.cookie.split('.')[3]}` });
  assert.equal(res.statusCode, 401, 'cannot extend expiry');
  res = await attacker.call('PUT', { progress: progressB }, { cookie: 'cq_session=junk' });
  assert.equal(res.statusCode, 401);
});

test('sessions expire after 30 days', async () => {
  const { handler, tick } = setup();
  const om = browser(handler);
  await om.call('POST', { action: 'register', name: 'Om', email: 'om@example.com', password: 'blue-tiger-42' });
  tick(31 * 24 * 3600 * 1000);
  assert.equal((await om.call('GET')).statusCode, 401);
});

test('the same email cannot register twice', async () => {
  const { handler } = setup();
  await browser(handler).call('POST', { action: 'register', name: 'Om', email: 'om@example.com', password: 'blue-tiger-42' });
  const res = await browser(handler, '10.0.0.3').call('POST', { action: 'register', name: 'Fake', email: 'OM@example.com', password: 'another-pass-1' });
  assert.equal(res.statusCode, 409);
});

test('wrong password and unknown email give the same answer', async () => {
  const { handler } = setup();
  await browser(handler).call('POST', { action: 'register', name: 'Om', email: 'om@example.com', password: 'blue-tiger-42' });
  const a = await browser(handler, '10.0.0.4').call('POST', { action: 'login', email: 'om@example.com', password: 'wrong-pass-1' });
  const b = await browser(handler, '10.0.0.5').call('POST', { action: 'login', email: 'nobody@example.com', password: 'wrong-pass-1' });
  assert.equal(a.statusCode, 401);
  assert.equal(b.statusCode, 401);
  assert.equal(a.json.error, b.json.error);
  assert.equal(a.headers['set-cookie'], undefined);
});

test('an account is locked for a while after 5 wrong passwords', async () => {
  const { handler, tick } = setup({ authPerMinute: 100 });
  await browser(handler).call('POST', { action: 'register', name: 'Om', email: 'om@example.com', password: 'blue-tiger-42' });
  const guesser = browser(handler, '10.0.0.6');
  for (let i = 0; i < 5; i++) {
    assert.equal((await guesser.call('POST', { action: 'login', email: 'om@example.com', password: `guess-${i}-xxxx` })).statusCode, 401);
  }
  // Even the right password is refused while locked.
  let res = await guesser.call('POST', { action: 'login', email: 'om@example.com', password: 'blue-tiger-42' });
  assert.equal(res.statusCode, 429);
  tick(5 * 60_000 + 1);
  res = await guesser.call('POST', { action: 'login', email: 'om@example.com', password: 'blue-tiger-42' });
  assert.equal(res.statusCode, 200);
});

test('too many login tries from one place are slowed down', async () => {
  const { handler } = setup({ authPerMinute: 3 });
  const spammer = browser(handler, '10.0.0.7');
  const codes = [];
  for (let i = 0; i < 4; i++) {
    codes.push((await spammer.call('POST', { action: 'login', email: `x${i}@example.com`, password: 'whatever-1' })).statusCode);
  }
  assert.deepEqual(codes, [401, 401, 401, 429]);
});

test('bad input is refused with a helpful message', async () => {
  const { handler } = setup();
  const b = browser(handler);
  const cases = [
    [{ action: 'register', name: 'O', email: 'om@example.com', password: 'blue-tiger-42' }, /Name/],
    [{ action: 'register', name: 'Om', email: 'nope', password: 'blue-tiger-42' }, /email/],
    [{ action: 'register', name: 'Om', email: 'om@example.com', password: 'short' }, /8/],
    [{ action: 'register', name: 'Om', email: 'om@example.com', password: 'blue-tiger-42', isAdmin: true }, /Unknown field/],
    [{ action: 'register', name: 'Om', email: 'om@example.com', password: 'blue-tiger-42', progress: { xp: 'lots' } }, /xp/],
    [{ action: 'hack' }, /action/],
    [[], /object/],
  ];
  for (const [body, message] of cases) {
    const res = await b.call('POST', body);
    assert.equal(res.statusCode, 400, JSON.stringify(body));
    assert.match(res.json.error, message);
  }
});

test('other websites, wrong methods and non-JSON are refused', async () => {
  const { handler } = setup();
  const b = browser(handler);
  assert.equal((await b.call('POST', { action: 'logout' }, { origin: 'https://evil.example' })).statusCode, 403);
  assert.equal((await b.call('POST', { action: 'logout' }, { 'sec-fetch-site': 'cross-site' })).statusCode, 403);
  const del = await b.call('DELETE');
  assert.equal(del.statusCode, 405);
  assert.equal(del.headers.allow, 'GET, POST, PUT');
  assert.equal((await b.call('POST', 'action=login', { 'content-type': 'application/x-www-form-urlencoded' })).statusCode, 415);
  assert.equal((await b.call('POST', 'x'.repeat(30 * 1024))).statusCode, 413);
  assert.equal((await b.call('POST', '{not json')).statusCode, 400);
});

test('the mobile app gets a token and can use it as a Bearer header', async () => {
  const { handler } = setup();
  const app = browser(handler);
  const res = await app.call('POST', { action: 'register', name: 'Om', email: 'om@example.com', password: 'blue-tiger-42' }, { 'x-codequest-client': 'app', origin: undefined });
  assert.ok(res.json.token);
  const me = await browser(handler, '10.0.0.8').call('GET', undefined, { authorization: `Bearer ${res.json.token}`, origin: undefined });
  assert.equal(me.statusCode, 200);
  assert.equal(me.json.user.name, 'Om');
});

test('deleting an account removes all its data and needs the password', async () => {
  const { handler, store } = setup();
  const om = browser(handler);
  await om.call('POST', { action: 'register', name: 'Om', email: 'om@example.com', password: 'blue-tiger-42', progress: progressA });
  assert.equal((await om.call('POST', { action: 'delete', password: 'wrong-pass-1' })).statusCode, 401);
  const oldCookie = om.cookie;
  const res = await om.call('POST', { action: 'delete', password: 'blue-tiger-42' });
  assert.equal(res.statusCode, 200);
  const left = [...store.files.keys()].filter((k) => !k.startsWith('_system/'));
  assert.deepEqual(left, []);
  // An old copy of the session cannot bring anything back.
  const res2 = await browser(handler).call('PUT', { progress: progressA }, { cookie: `cq_session=${oldCookie}` });
  assert.equal(res2.statusCode, 401);
  assert.deepEqual([...store.files.keys()].filter((k) => !k.startsWith('_system/')), []);
});

test('storage problems give a friendly 503, not internal details', async () => {
  const store = createMemoryStore();
  store.getJson = async () => {
    throw new Error('secret internal path /accounts/abc');
  };
  const handler = createAccountHandler({ store, env: NO_ENV });
  const originalError = console.error;
  console.error = () => {};
  try {
    const res = await browser(handler).call('POST', { action: 'login', email: 'om@example.com', password: 'blue-tiger-42' });
    assert.equal(res.statusCode, 503);
    assert.doesNotMatch(res.body, /internal|accounts/);
    assert.match(res.json.error, /guest/);
  } finally {
    console.error = originalError;
  }
});

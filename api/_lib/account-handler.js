// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

// The account API, written as a factory so tests can give it an in-memory
// store and a fake clock.
//
//   GET  /api/account                      -> who is logged in + their progress
//   POST /api/account {action:'register'}  -> new account (email + password)
//   POST /api/account {action:'login'}     -> log in
//   POST /api/account {action:'logout'}    -> log out
//   POST /api/account {action:'delete'}    -> delete account and all its data
//   PUT  /api/account {progress}           -> save the logged-in player's progress
//
// Every player can only ever reach their own files: the file name comes from
// the signed session, never from anything the browser sends.

import {
  ACCOUNT_LIMITS,
  accountIdFor,
  cleanName,
  clearSessionCookie,
  createSessionToken,
  dummyPasswordHash,
  hashPassword,
  normalizeEmail,
  passwordProblem,
  readSessionToken,
  sessionCookie,
  tokenFromRequest,
  validateProgress,
  verifyPassword,
} from './accounts.js';
import { BodyError, isCrossSiteFetch, isJsonRequest, readJsonBody, sendJson } from './http.js';
import { createSecretsLoader } from './secrets.js';
import { StoreConflictError, StoreUnavailableError } from './store.js';
import { clientKey, createRateLimiter, isAllowedOrigin } from './tutor.js';

const accountPath = (id) => `accounts/${id}.json`;
const progressPath = (id) => `progress/${id}.json`;

const MESSAGES = Object.freeze({
  wrongLogin: 'Email or password is wrong.',
  notLoggedIn: 'Please log in again.',
  unavailable: 'Accounts are not available right now. You can still play as a guest.',
  tooMany: 'Too many tries. Please wait a minute and try again.',
  locked: 'Too many wrong passwords. Please wait 5 minutes and try again.',
});

class HttpError extends Error {
  constructor(status, message, headers = {}) {
    super(message);
    this.status = status;
    this.headers = headers;
  }
}

function onlyFields(body, allowed) {
  if (body === null || typeof body !== 'object' || Array.isArray(body)) {
    throw new HttpError(400, 'Body must be a JSON object.');
  }
  for (const key of Object.keys(body)) {
    if (!allowed.includes(key)) throw new HttpError(400, `Unknown field: ${key.slice(0, 40)}`);
  }
}

const publicUser = (account) => ({ name: account.name, since: account.createdAt });

export function createAccountHandler({
  store,
  env = process.env,
  now = () => Date.now(),
  authPerMinute = 10,
  savesPerMinute = 30,
  lockAfterFails = 5,
  lockMs = 5 * 60_000,
} = {}) {
  const getSecrets = createSecretsLoader(store, env);
  const allowAuth = createRateLimiter({ limit: authPerMinute, windowMs: 60_000, now });
  const allowSave = createRateLimiter({ limit: savesPerMinute, windowMs: 60_000, now });
  const failures = new Map(); // account id -> { count, until }

  const isLocked = (id) => (failures.get(id)?.until ?? 0) > now();

  function noteFailure(id) {
    const entry = failures.get(id) ?? { count: 0, until: 0 };
    entry.count += 1;
    if (entry.count >= lockAfterFails) {
      entry.count = 0;
      entry.until = now() + lockMs;
    }
    failures.set(id, entry);
    if (failures.size > 5000) failures.delete(failures.keys().next().value);
  }

  /** Account id from the signed session, or throws 401. */
  async function sessionAccount(req, secrets) {
    const id = readSessionToken(tokenFromRequest(req.headers), secrets.session, now());
    if (!id) throw new HttpError(401, MESSAGES.notLoggedIn, { 'Set-Cookie': clearSessionCookie() });
    const account = await store.getJson(accountPath(id));
    if (!account) throw new HttpError(401, MESSAGES.notLoggedIn, { 'Set-Cookie': clearSessionCookie() });
    return account;
  }

  async function readProgress(id) {
    const saved = await store.getJson(progressPath(id));
    return saved && typeof saved.data === 'object' ? saved.data : null;
  }

  async function writeProgress(id, data) {
    const savedAt = new Date(now()).toISOString();
    await store.putJson(progressPath(id), { v: 1, savedAt, data });
    return savedAt;
  }

  /** Logged-in reply: sets the cookie; mobile apps also get the token. */
  function loggedIn(req, res, status, account, progress, secrets) {
    const token = createSessionToken(account.id, secrets.session, now());
    const body = { user: publicUser(account), progress };
    if (req.headers['x-codequest-client'] === 'app') body.token = token;
    sendJson(res, status, body, { 'Set-Cookie': sessionCookie(token) });
  }

  function checkAuthRate(req) {
    if (!allowAuth(clientKey(req.headers))) throw new HttpError(429, MESSAGES.tooMany, { 'Retry-After': '60' });
  }

  async function register(req, res, body, secrets) {
    onlyFields(body, ['action', 'name', 'email', 'password', 'progress']);
    checkAuthRate(req);
    const name = cleanName(body.name);
    if (!name) throw new HttpError(400, 'Name must be 2 to 20 letters or numbers.');
    const email = normalizeEmail(body.email);
    if (!email) throw new HttpError(400, 'Please enter a valid email.');
    const problem = passwordProblem(body.password, email);
    if (problem) throw new HttpError(400, problem);
    let progress = null;
    if (body.progress !== undefined && body.progress !== null) {
      const checked = validateProgress(body.progress);
      if (!checked.ok) throw new HttpError(400, checked.error);
      progress = checked.value;
    }

    const id = accountIdFor(email, secrets.accountId);
    const taken = 'This email already has an account. Please log in instead.';
    if (await store.getJson(accountPath(id))) throw new HttpError(409, taken);
    const account = {
      v: 1,
      id,
      name,
      passHash: await hashPassword(body.password),
      createdAt: new Date(now()).toISOString(),
    };
    try {
      await store.putJson(accountPath(id), account, { overwrite: false });
    } catch (err) {
      if (err instanceof StoreConflictError) throw new HttpError(409, taken);
      throw err;
    }
    if (progress) await writeProgress(id, progress);
    loggedIn(req, res, 201, account, progress, secrets);
  }

  async function login(req, res, body, secrets) {
    onlyFields(body, ['action', 'email', 'password']);
    checkAuthRate(req);
    const email = normalizeEmail(body.email);
    if (!email || typeof body.password !== 'string' || body.password.length > ACCOUNT_LIMITS.passwordMax) {
      throw new HttpError(401, MESSAGES.wrongLogin);
    }
    const id = accountIdFor(email, secrets.accountId);
    if (isLocked(id)) throw new HttpError(429, MESSAGES.locked, { 'Retry-After': String(Math.ceil(lockMs / 1000)) });
    const account = await store.getJson(accountPath(id));
    // Always check a hash, so a missing account takes as long as a wrong password.
    const ok = await verifyPassword(body.password, account?.passHash ?? (await dummyPasswordHash()));
    if (!account || !ok) {
      noteFailure(id);
      throw new HttpError(401, MESSAGES.wrongLogin);
    }
    failures.delete(id);
    loggedIn(req, res, 200, account, await readProgress(id), secrets);
  }

  async function deleteAccount(req, res, body, secrets) {
    onlyFields(body, ['action', 'password']);
    checkAuthRate(req);
    const account = await sessionAccount(req, secrets);
    if (isLocked(account.id)) throw new HttpError(429, MESSAGES.locked);
    if (!(await verifyPassword(body.password, account.passHash))) {
      noteFailure(account.id);
      throw new HttpError(401, 'Password is wrong.');
    }
    await store.delete(progressPath(account.id));
    await store.delete(accountPath(account.id));
    sendJson(res, 200, { ok: true }, { 'Set-Cookie': clearSessionCookie() });
  }

  async function me(req, res, secrets) {
    const account = await sessionAccount(req, secrets);
    sendJson(res, 200, { user: publicUser(account), progress: await readProgress(account.id) });
  }

  async function save(req, res, body, secrets) {
    onlyFields(body, ['progress']);
    const checked = validateProgress(body.progress);
    if (!checked.ok) throw new HttpError(400, checked.error);
    const account = await sessionAccount(req, secrets);
    if (!allowSave(account.id)) throw new HttpError(429, 'Saving too often. Please wait a moment.', { 'Retry-After': '30' });
    const savedAt = await writeProgress(account.id, checked.value);
    sendJson(res, 200, { ok: true, savedAt });
  }

  return async function handler(req, res) {
    try {
      const { method, headers } = req;
      if (!['GET', 'POST', 'PUT'].includes(method)) {
        throw new HttpError(405, 'Method not allowed.', { Allow: 'GET, POST, PUT' });
      }
      if (!isAllowedOrigin(headers.origin, headers.host) || isCrossSiteFetch(headers)) {
        throw new HttpError(403, 'Origin not allowed.');
      }
      // Guests have no session: answer at once without touching storage.
      if (method === 'GET' && !tokenFromRequest(headers)) throw new HttpError(401, 'Not logged in.');

      let body = null;
      if (method !== 'GET') {
        if (!isJsonRequest(headers)) throw new HttpError(415, 'Send JSON.');
        if (Number(headers['content-length'] || 0) > ACCOUNT_LIMITS.bodyMax) throw new HttpError(413, 'Request too large.');
        try {
          body = await readJsonBody(req, ACCOUNT_LIMITS.bodyMax);
        } catch (err) {
          const tooLarge = err instanceof BodyError && err.kind === 'too_large';
          throw new HttpError(tooLarge ? 413 : 400, tooLarge ? 'Request too large.' : 'Invalid JSON.');
        }
        if (body === null || typeof body !== 'object' || Array.isArray(body)) {
          throw new HttpError(400, 'Body must be a JSON object.');
        }
      }
      if (method === 'POST' && body?.action === 'logout') {
        return sendJson(res, 200, { ok: true }, { 'Set-Cookie': clearSessionCookie() });
      }

      const secrets = await getSecrets();
      if (method === 'GET') return await me(req, res, secrets);
      if (method === 'PUT') return await save(req, res, body, secrets);
      switch (body?.action) {
        case 'register':
          return await register(req, res, body, secrets);
        case 'login':
          return await login(req, res, body, secrets);
        case 'delete':
          return await deleteAccount(req, res, body, secrets);
        default:
          throw new HttpError(400, 'action must be register, login, logout or delete.');
      }
    } catch (err) {
      if (err instanceof HttpError) return sendJson(res, err.status, { error: err.message }, err.headers);
      // Never echo internal errors (they could include storage details).
      console.error('account API error', err instanceof StoreUnavailableError ? 'storage not configured' : err?.name);
      return sendJson(res, 503, { error: MESSAGES.unavailable });
    }
  };
}

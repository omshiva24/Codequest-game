// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

// Pure helpers for player accounts: input checks, password hashing, account
// ids and signed session tokens. No network or storage here, so every rule
// can be unit-tested with `node --test`.
//
// Privacy by design:
// - The raw email is never stored. It is turned into an account id with a
//   keyed hash (HMAC-SHA256), so the storage only ever sees random-looking ids.
// - Passwords are stored only as salted scrypt hashes.
// - Sessions are signed tokens kept in an HttpOnly cookie that page scripts
//   cannot read.

import { createHmac, randomBytes, scrypt as scryptCb, timingSafeEqual } from 'node:crypto';
import { promisify } from 'node:util';

const scrypt = promisify(scryptCb);

export const ACCOUNT_LIMITS = Object.freeze({
  emailMax: 254,
  passwordMin: 8,
  passwordMax: 128,
  nameMin: 2,
  nameMax: 20,
  bodyMax: 24 * 1024, // bytes
  progressMax: 20_000, // bytes of JSON
  sessionDays: 30,
});

export const SESSION_COOKIE = 'cq_session';

const SCRYPT = Object.freeze({ N: 16384, r: 8, p: 1, keyLen: 32, saltLen: 16 });

// A few passwords that are guessed first in every attack.
const COMMON_PASSWORDS = new Set([
  'password', 'password1', 'password123', '12345678', '123456789', '1234567890',
  'qwerty123', 'qwertyuiop', '11111111', '00000000', 'iloveyou', 'abcd1234',
  'codequest', 'letmein1', 'welcome1', 'admin123', 'football', 'baseball',
]);

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
const NAME_RE = /^[\p{L}\p{N}][\p{L}\p{M}\p{N} ._-]*$/u;

/** Lower-cases and trims an email. Returns '' when it is not a valid email. */
export function normalizeEmail(value) {
  if (typeof value !== 'string') return '';
  const email = value.trim().toLowerCase();
  if (email.length > ACCOUNT_LIMITS.emailMax || !EMAIL_RE.test(email)) return '';
  return email;
}

/** Returns a tidy player name, or '' when it is not allowed. */
export function cleanName(value) {
  if (typeof value !== 'string') return '';
  const name = value.trim().replace(/\s+/g, ' ');
  if (name.length < ACCOUNT_LIMITS.nameMin || name.length > ACCOUNT_LIMITS.nameMax) return '';
  return NAME_RE.test(name) ? name : '';
}

/** Explains what is wrong with a new password, or returns null when it is fine. */
export function passwordProblem(password, email = '') {
  if (typeof password !== 'string') return 'Enter a password.';
  if (password.length < ACCOUNT_LIMITS.passwordMin) {
    return `Password must be at least ${ACCOUNT_LIMITS.passwordMin} characters.`;
  }
  if (password.length > ACCOUNT_LIMITS.passwordMax) {
    return `Password must be at most ${ACCOUNT_LIMITS.passwordMax} characters.`;
  }
  const lower = password.toLowerCase();
  if (COMMON_PASSWORDS.has(lower)) return 'That password is too easy to guess. Try another one.';
  if (email && (lower === email || lower === email.split('@')[0])) {
    return 'Password must not be your email.';
  }
  return null;
}

/** Hashes a password with scrypt and a random salt. */
export async function hashPassword(password) {
  const salt = randomBytes(SCRYPT.saltLen);
  const hash = await scrypt(password, salt, SCRYPT.keyLen, {
    N: SCRYPT.N, r: SCRYPT.r, p: SCRYPT.p, maxmem: 64 * 1024 * 1024,
  });
  return ['scrypt', SCRYPT.N, SCRYPT.r, SCRYPT.p, salt.toString('base64url'), hash.toString('base64url')].join('$');
}

/** Checks a password against a stored hash in constant time. */
export async function verifyPassword(password, stored) {
  if (typeof password !== 'string' || typeof stored !== 'string') return false;
  const parts = stored.split('$');
  if (parts.length !== 6 || parts[0] !== 'scrypt') return false;
  const [N, r, p] = parts.slice(1, 4).map(Number);
  // Only accept the parameters we create, so a tampered record cannot make
  // the server do a huge amount of work.
  if (N !== SCRYPT.N || r !== SCRYPT.r || p !== SCRYPT.p) return false;
  const salt = Buffer.from(parts[4], 'base64url');
  const expected = Buffer.from(parts[5], 'base64url');
  if (salt.length !== SCRYPT.saltLen || expected.length !== SCRYPT.keyLen) return false;
  const actual = await scrypt(password, salt, SCRYPT.keyLen, { N, r, p, maxmem: 64 * 1024 * 1024 });
  return timingSafeEqual(actual, expected);
}

/** A hash of a random password, used to keep timing the same for unknown emails. */
let dummyHash;
export async function dummyPasswordHash() {
  dummyHash ??= hashPassword(randomBytes(16).toString('hex'));
  return dummyHash;
}

/** Turns an email into a stable, private account id (64 hex characters). */
export function accountIdFor(email, secret) {
  return createHmac('sha256', secret).update(`account:${email}`).digest('hex');
}

export function isAccountId(value) {
  return typeof value === 'string' && /^[0-9a-f]{64}$/.test(value);
}

function sign(payload, secret) {
  return createHmac('sha256', secret).update(`session:${payload}`).digest('base64url');
}

/** Creates a signed session token: v1.<accountId>.<expiry seconds>.<signature>. */
export function createSessionToken(accountId, secret, nowMs = Date.now()) {
  const exp = Math.floor(nowMs / 1000) + ACCOUNT_LIMITS.sessionDays * 24 * 60 * 60;
  const payload = `v1.${accountId}.${exp}`;
  return `${payload}.${sign(payload, secret)}`;
}

/** Returns the account id inside a valid, unexpired token, otherwise null. */
export function readSessionToken(token, secret, nowMs = Date.now()) {
  if (typeof token !== 'string' || token.length > 200) return null;
  const parts = token.split('.');
  if (parts.length !== 4 || parts[0] !== 'v1') return null;
  const [, id, expText, sig] = parts;
  if (!isAccountId(id) || !/^\d{1,12}$/.test(expText)) return null;
  const expected = Buffer.from(sign(`v1.${id}.${expText}`, secret));
  const given = Buffer.from(sig);
  if (given.length !== expected.length || !timingSafeEqual(given, expected)) return null;
  if (Number(expText) * 1000 <= nowMs) return null;
  return id;
}

/** Cookie that keeps the session. HttpOnly: page scripts can never read it. */
export function sessionCookie(token) {
  const maxAge = ACCOUNT_LIMITS.sessionDays * 24 * 60 * 60;
  return `${SESSION_COOKIE}=${token}; Path=/api; Max-Age=${maxAge}; HttpOnly; Secure; SameSite=Strict`;
}

export function clearSessionCookie() {
  return `${SESSION_COOKIE}=; Path=/api; Max-Age=0; HttpOnly; Secure; SameSite=Strict`;
}

/** Finds the session token in the cookie (web) or Authorization header (mobile app). */
export function tokenFromRequest(headers = {}) {
  const auth = headers.authorization;
  if (typeof auth === 'string' && auth.startsWith('Bearer ')) return auth.slice(7).trim();
  const cookie = headers.cookie;
  if (typeof cookie !== 'string') return null;
  for (const part of cookie.split(';')) {
    const [name, ...rest] = part.trim().split('=');
    if (name === SESSION_COOKIE) return rest.join('=') || null;
  }
  return null;
}

const SETTINGS_KEYS = new Set(['highContrast', 'reduceMotion', 'timerMode', 'textScale', 'soundOn']);
const MAX_COUNTER = 10_000_000;

const isCounter = (v) => Number.isInteger(v) && v >= 0 && v <= MAX_COUNTER;
const isShortId = (v) => typeof v === 'string' && /^[a-z0-9_-]{1,40}$/i.test(v);

/**
 * Checks saved game progress before it is stored. Only the fields the game
 * really saves are kept; anything else is refused.
 * Returns { ok: true, value } or { ok: false, error }.
 */
export function validateProgress(progress) {
  if (progress === null || typeof progress !== 'object' || Array.isArray(progress)) {
    return { ok: false, error: 'progress must be an object.' };
  }
  if (JSON.stringify(progress).length > ACCOUNT_LIMITS.progressMax) {
    return { ok: false, error: 'progress is too large.' };
  }
  const value = {};
  for (const [key, v] of Object.entries(progress)) {
    switch (key) {
      case 'version':
        if (v !== 1) return { ok: false, error: 'Unknown progress version.' };
        break;
      case 'stars': {
        if (v === null || typeof v !== 'object' || Array.isArray(v)) return { ok: false, error: 'stars must be an object.' };
        const entries = Object.entries(v);
        if (entries.length > 300) return { ok: false, error: 'Too many levels.' };
        for (const [id, s] of entries) {
          if (!isShortId(id) || !Number.isInteger(s) || s < 0 || s > 3) {
            return { ok: false, error: 'stars has a bad entry.' };
          }
        }
        break;
      }
      case 'xp':
      case 'coins':
      case 'streak':
      case 'bestCombo':
        if (!isCounter(v)) return { ok: false, error: `${key} must be a whole number.` };
        break;
      case 'lastPlayDay':
        if (v !== null && !(typeof v === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(v))) {
          return { ok: false, error: 'lastPlayDay must be a date.' };
        }
        break;
      case 'askedDoubt':
        if (typeof v !== 'boolean') return { ok: false, error: 'askedDoubt must be true or false.' };
        break;
      case 'achievements':
        if (!Array.isArray(v) || v.length > 100 || !v.every(isShortId)) {
          return { ok: false, error: 'achievements has a bad entry.' };
        }
        break;
      case 'settings':
        if (v === null || typeof v !== 'object' || Array.isArray(v)) return { ok: false, error: 'settings must be an object.' };
        for (const [sk, sv] of Object.entries(v)) {
          if (!SETTINGS_KEYS.has(sk)) return { ok: false, error: 'settings has an unknown field.' };
          if (!['boolean', 'number', 'string'].includes(typeof sv)) return { ok: false, error: 'settings has a bad value.' };
          if (typeof sv === 'string' && sv.length > 20) return { ok: false, error: 'settings has a bad value.' };
        }
        break;
      default:
        return { ok: false, error: `Unknown progress field: ${String(key).slice(0, 40)}` };
    }
    value[key] = v;
  }
  return { ok: true, value };
}

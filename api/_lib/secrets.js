// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

// Server secrets for signing sessions and hiding emails.
//
// If SESSION_SECRET and ACCOUNT_ID_SECRET are set (32+ characters each) they
// are used. Otherwise strong random secrets are created once, on the server,
// and kept in the private store, so nobody ever has to copy a secret by hand
// and no secret is ever in the code or the repository.

import { randomBytes } from 'node:crypto';

import { StoreConflictError } from './store.js';

export const SECRETS_PATH = '_system/secrets.json';

const isStrong = (s) => typeof s === 'string' && s.length >= 32;

const isValid = (s) => s && isStrong(s.session) && isStrong(s.accountId);

const fresh = () => ({
  v: 1,
  session: randomBytes(32).toString('base64url'),
  accountId: randomBytes(32).toString('base64url'),
});

export function createSecretsLoader(store, env = process.env) {
  let cached = null;

  async function loadOrCreate() {
    const existing = await store.getJson(SECRETS_PATH);
    if (isValid(existing)) return existing;
    if (existing) throw new Error('Stored secrets are damaged.');
    const created = fresh();
    try {
      await store.putJson(SECRETS_PATH, created, { overwrite: false });
      return created;
    } catch (err) {
      // Two servers raced to create them: use the one that won.
      if (!(err instanceof StoreConflictError)) throw err;
      const winner = await store.getJson(SECRETS_PATH);
      if (!isValid(winner)) throw new Error('Stored secrets are damaged.');
      return winner;
    }
  }

  return async function getSecrets() {
    if (isStrong(env.SESSION_SECRET) && isStrong(env.ACCOUNT_ID_SECRET)) {
      return { session: env.SESSION_SECRET, accountId: env.ACCOUNT_ID_SECRET };
    }
    cached ??= loadOrCreate().catch((err) => {
      cached = null; // try again on the next request
      throw err;
    });
    const { session, accountId } = await cached;
    return { session, accountId };
  };
}

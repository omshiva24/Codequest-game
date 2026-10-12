// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

// Tiny JSON key-value store used by the account API.
// - createBlobStore(): Vercel Blob in PRIVATE mode. Files can only be read
//   with the server-side BLOB_READ_WRITE_TOKEN; there are no public URLs.
// - createMemoryStore(): same interface in memory, for tests and local runs.

export class StoreConflictError extends Error {
  constructor(path) {
    super(`Already exists: ${path}`);
    this.name = 'StoreConflictError';
  }
}

export class StoreUnavailableError extends Error {
  constructor(message = 'Storage is not configured.') {
    super(message);
    this.name = 'StoreUnavailableError';
  }
}

export function createMemoryStore() {
  const files = new Map();
  return {
    files,
    async getJson(path) {
      return files.has(path) ? JSON.parse(files.get(path)) : null;
    },
    async putJson(path, value, { overwrite = true } = {}) {
      if (!overwrite && files.has(path)) throw new StoreConflictError(path);
      files.set(path, JSON.stringify(value));
    },
    async delete(path) {
      files.delete(path);
    },
  };
}

export function createBlobStore({ env = process.env } = {}) {
  let sdk;
  const load = async () => {
    if (!env.BLOB_READ_WRITE_TOKEN) throw new StoreUnavailableError();
    sdk ??= await import('@vercel/blob');
    return sdk;
  };
  return {
    async getJson(path) {
      const { get, BlobNotFoundError } = await load();
      let result;
      try {
        // useCache: false reads straight from storage, so a save is seen at once.
        result = await get(path, { access: 'private', useCache: false });
      } catch (err) {
        if (err instanceof BlobNotFoundError) return null;
        throw err;
      }
      if (!result || result.statusCode !== 200 || !result.stream) return null;
      const text = await new Response(result.stream).text();
      return JSON.parse(text);
    },
    async putJson(path, value, { overwrite = true } = {}) {
      const { put, BlobPreconditionFailedError } = await load();
      try {
        await put(path, JSON.stringify(value), {
          access: 'private',
          addRandomSuffix: false,
          allowOverwrite: overwrite,
          contentType: 'application/json',
          cacheControlMaxAge: 60,
        });
      } catch (err) {
        const exists = err instanceof BlobPreconditionFailedError
          || (err instanceof Error && /already exists/i.test(err.message));
        if (!overwrite && exists) throw new StoreConflictError(path);
        throw err;
      }
    },
    async delete(path) {
      const { del } = await load();
      await del(path);
    },
  };
}

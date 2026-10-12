// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

// Small HTTP helpers shared by the API endpoints.

/** Sends JSON that is never cached and never sniffed as another type. */
export function sendJson(res, status, payload, extraHeaders = {}) {
  res.setHeader('Content-Type', 'application/json; charset=utf-8');
  res.setHeader('Cache-Control', 'no-store');
  res.setHeader('X-Content-Type-Options', 'nosniff');
  for (const [key, value] of Object.entries(extraHeaders)) res.setHeader(key, value);
  res.status(status).send(JSON.stringify(payload));
}

export class BodyError extends Error {
  constructor(kind) {
    super(kind);
    this.name = 'BodyError';
    this.kind = kind; // 'too_large' | 'invalid'
  }
}

/** Reads a JSON body of at most `maxBytes`. Throws BodyError on problems. */
export async function readJsonBody(req, maxBytes) {
  try {
    // Vercel parses JSON bodies for us; fall back to reading the stream.
    if (req.body !== undefined) {
      if (typeof req.body === 'string') {
        if (Buffer.byteLength(req.body) > maxBytes) throw new BodyError('too_large');
        return JSON.parse(req.body);
      }
      if (Buffer.isBuffer(req.body)) {
        if (req.body.length > maxBytes) throw new BodyError('too_large');
        return JSON.parse(req.body.toString('utf8'));
      }
      if (JSON.stringify(req.body ?? null).length > maxBytes) throw new BodyError('too_large');
      return req.body;
    }
    let size = 0;
    const chunks = [];
    for await (const chunk of req) {
      size += chunk.length;
      if (size > maxBytes) throw new BodyError('too_large');
      chunks.push(chunk);
    }
    return JSON.parse(Buffer.concat(chunks).toString('utf8') || '{}');
  } catch (err) {
    if (err instanceof BodyError) throw err;
    throw new BodyError('invalid');
  }
}

/** True when the request says it carries JSON. */
export function isJsonRequest(headers = {}) {
  return String(headers['content-type'] || '').toLowerCase().startsWith('application/json');
}

/** Browsers mark requests from other sites; refuse those outright. */
export function isCrossSiteFetch(headers = {}) {
  return headers['sec-fetch-site'] === 'cross-site';
}

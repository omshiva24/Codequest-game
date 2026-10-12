// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

// POST /api/ask - the AI "Doubt Buddy" endpoint (Vercel serverless function).
//
// Security notes:
// - The Gemini API key is read from the GEMINI_API_KEY environment variable
//   on the server. It is never sent to the browser.
// - Only POST with a small JSON body is accepted; every field is validated.
// - Requests from other websites are refused (Origin check) and each client
//   is rate limited.
// - Questions are not logged or stored.
// - If no key is configured the endpoint answers 503 and the app falls back
//   to its built-in offline Doubt Buddy.

import {
  LIMITS,
  buildGeminiRequest,
  clientKey,
  createRateLimiter,
  extractAnswer,
  isAllowedOrigin,
  validateBody,
} from './_lib/tutor.js';
import { BodyError, isCrossSiteFetch, isJsonRequest, readJsonBody, sendJson } from './_lib/http.js';

const allow = createRateLimiter();
const MODEL = /^[a-z0-9.-]{1,64}$/.test(process.env.GEMINI_MODEL || '')
  ? process.env.GEMINI_MODEL
  : 'gemini-2.5-flash';

const send = sendJson;

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return send(res, 405, { error: 'Method not allowed.' });
  }
  if (!isAllowedOrigin(req.headers.origin, req.headers.host) || isCrossSiteFetch(req.headers)) {
    return send(res, 403, { error: 'Origin not allowed.' });
  }
  if (!isJsonRequest(req.headers)) {
    return send(res, 415, { error: 'Send JSON.' });
  }
  const length = Number(req.headers['content-length'] || 0);
  if (length > LIMITS.bodyMax) {
    return send(res, 413, { error: 'Request too large.' });
  }
  if (!allow(clientKey(req.headers))) {
    res.setHeader('Retry-After', '60');
    return send(res, 429, { error: 'Too many questions. Please wait a minute.' });
  }

  let body;
  try {
    body = await readJsonBody(req, LIMITS.bodyMax);
  } catch (err) {
    const tooLarge = err instanceof BodyError && err.kind === 'too_large';
    return send(res, tooLarge ? 413 : 400, { error: tooLarge ? 'Request too large.' : 'Invalid JSON.' });
  }
  const checked = validateBody(body);
  if (!checked.ok) return send(res, 400, { error: checked.error });

  const key = process.env.GEMINI_API_KEY;
  if (!key) return send(res, 503, { error: 'AI tutor is not configured.' });

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 15_000);
  try {
    const upstream = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-goog-api-key': key },
        body: JSON.stringify(buildGeminiRequest(checked.value)),
        signal: controller.signal,
      },
    );
    if (!upstream.ok) {
      console.error('AI upstream error', upstream.status);
      return send(res, 502, { error: 'AI tutor is unavailable right now.' });
    }
    const answer = extractAnswer(await upstream.json());
    if (!answer) return send(res, 502, { error: 'AI tutor gave no answer.' });
    return send(res, 200, { answer });
  } catch (err) {
    console.error('AI request failed', err instanceof Error ? err.name : 'unknown');
    return send(res, 504, { error: 'AI tutor timed out.' });
  } finally {
    clearTimeout(timer);
  }
}

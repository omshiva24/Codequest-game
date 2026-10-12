# Security

## Reporting a problem
Please open a private security advisory on GitHub (Security → Advisories → Report a vulnerability) instead of a public issue.

## How CodeQuest is protected

| Area | Measure |
|---|---|
| Secrets | The AI key is read from the `GEMINI_API_KEY` environment variable inside the server function only. It is never shipped to the browser or committed (`.env*` is git-ignored). |
| API input | `POST` + `application/json` only, 4 KB body limit, allow-listed fields, length limits, control characters removed, enum check for language. |
| Abuse | Per-client rate limit (10/min, best effort per instance - enable Vercel Firewall rate limiting for heavy traffic), same-origin check, 15 s upstream timeout. |
| Prompt injection | Rules live in the system instruction; student text and context are wrapped and labelled as data; output length is capped; Gemini safety filters on. |
| Output | Answers are shown as plain text widgets (Flutter does not render HTML), so there is no XSS path. Code in lessons and answers is never executed. |
| Browser | Strict CSP (no inline or third-party scripts), HSTS, `X-Frame-Options: DENY`, `nosniff`, Referrer-Policy, Permissions-Policy, COOP/CORP. Engine and fonts are self-hosted. |
| Player isolation | Every account's progress is a separate private file. The server chooses the file from the signed session only - never from anything the browser sends - so one player can never read or change another player's progress (tested). Switching player wipes progress from memory before the next player's save is loaded. |
| Passwords | scrypt (N=16384, r=8, p=1) with a random 16-byte salt per password, constant-time comparison, only known-safe parameters accepted. 8-128 characters; very common passwords and the email itself are refused. |
| Emails | Never stored. An email becomes a keyed HMAC-SHA256 id (the key is a server secret), so the storage only contains random-looking ids. |
| Sessions | `v1.<id>.<expiry>.<HMAC>` tokens, 30 days, verified in constant time. Web: `HttpOnly; Secure; SameSite=Strict; Path=/api` cookie (page scripts can't read it). Mobile app: Bearer token, only sent back when the app asks for it. |
| Brute force | Per-client limit on log in / sign up (10 per minute per instance), 5-minute account lock after 5 wrong passwords, the same message and timing for "unknown email" and "wrong password". |
| CSRF | SameSite=Strict cookie, same-origin `Origin` check, `Sec-Fetch-Site: cross-site` refused, JSON-only bodies (24 KB limit). |
| Saved progress | Validated field by field on the server (allow-listed keys, whole numbers in range, short ids, 20 KB limit) and again in the app when loaded. |
| Storage | Private Vercel Blob store (no public URLs). `BLOB_READ_WRITE_TOKEN` exists only on the server. Server secrets are random 256-bit values generated on the server on first use and kept in the private store (or set by env vars) - never in code, the repo or logs. |
| Errors | Storage/internal errors return a generic message; details are never sent to the browser. API responses are `no-store`. |
| Local data | Guest progress and accessibility settings only. Account progress is kept in memory, never on the device. Loaded data is validated and clamped; unknown keys are dropped. |
| Privacy | Guests give no personal data. Accounts store only a player name, a password hash and progress. Players can delete their account and all its data. No ads, no analytics. Questions are not logged. |
| Dependencies | 3 runtime Dart packages from the Flutter/Dart teams; 1 npm runtime package (`@vercel/blob`) pinned by `package-lock.json`, installed with `npm ci --ignore-scripts` and checked with `npm audit` in CI. Dependabot enabled, pinned Flutter SDK for builds. |

## Known limits (honest list)

- **No password reset or email check yet.** Emails are not stored in a readable form and no email service is connected, so a forgotten password cannot be recovered. Players are told this on the sign-up screen.
- **Rate limits and lockouts are per server instance** (in memory). For heavy traffic, also turn on Vercel Firewall rate limiting for `/api/account`.
- **Sessions are stateless.** Logging out clears the cookie; a copied token stays valid until it expires (30 days) unless the account is deleted or `SESSION_SECRET` is changed.
- **Guest progress is per device/browser**, so people sharing one device share the guest game. Accounts are the way to keep progress private.

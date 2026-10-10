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
| Local data | Only game progress and settings are stored on the device. Loaded data is validated and clamped; unknown keys are dropped. |
| Privacy | No accounts, no analytics, no personal data. Questions are not logged. |
| Dependencies | 2 runtime Dart packages from the Flutter/Dart teams, 0 npm runtime packages, Dependabot enabled, pinned Flutter SDK for builds. |

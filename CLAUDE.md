# BC Hydro Proxy

Cloudflare Worker that proxies BC Hydro outage data with location-based filtering. No runtime dependencies — Cloudflare Workers environment provides all globals.

## Commands

```bash
npm run lint          # check for lint errors (must pass before committing)
npm run lint:fix      # auto-fix fixable lint issues
npm test              # run all tests
npm run test:watch    # run tests in watch mode
npm run dev           # start local Wrangler dev server at localhost:8787
```

Pre-commit check: `npm run lint && npm test` — both must pass locally before pushing.

## Git & Commits

- **Always ask for permission before running `git commit`** — never auto-commit
- Commit message format: lowercase, past tense, no prefixes, no emojis, under 50 characters
  - Good: `updated default env variables`, `fixed coordinate validation`
  - Bad: `Update README` (uppercase), `update readme` (imperative), `feat: add X` (prefix)
- All commits must be signed (branch protection enforces this on `main`)
- Rebase to organize commits into logical units before pushing

## API Design

All responses — including errors — must include an `outages` array:

```json
{ "error": "message", "outages": [] }
```

Never omit `outages` from any response shape.

## Testing

- Framework: Node.js built-in test runner (not Jest or Vitest)
- Use generic BC coordinates in all test data — never real personal addresses
  - Vancouver: `49.2827, -123.1207` | Victoria | Kelowna
- Write tests before code (TDD preferred); confirm they pass before committing

## Test Mode

Enabled via `TEST_MODE=true` env var (set in `.dev.vars` locally, `false` in production).

Query parameter `?test=` accepts: `outage`, `no-outage`, `multiple`

All mock outage data must include `(TEST DATA)` in the cause field. Test responses are never cached.

## Privacy & Security

This is a public repository. Never commit:
- Personal coordinates, home addresses, or private locations
- API keys, tokens, passwords, or account credentials
- Cloudflare-specific account details (zones, domains, account IDs)
- Email addresses

Store sensitive config in environment variables or Cloudflare Dashboard only. Review `git diff` before every push.

## Deployment

Deployment is handled by Cloudflare's native GitHub integration — do not write manual deploy scripts or add deploy commands. CI (GitHub Actions) runs lint + tests on Node 22.x and 24.x; all checks must pass before deployment.

## BC Service Area

Coordinates are validated against BC Hydro's service area before any API call:
- Latitude: 48.3–60.0°N
- Longitude: -139.0 to -114.0°W

Return a 400 (with `"outages": []`) for coordinates outside this range.

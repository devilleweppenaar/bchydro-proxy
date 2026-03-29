# BC Hydro Proxy

Cloudflare Worker that proxies BC Hydro outage data with location-based filtering. Written in Gleam (targeting JavaScript), deployed via wrangler.

## Commands

```bash
gleam format --check   # check formatting (must pass before committing)
gleam format           # auto-format all source files
gleam test             # run all tests
gleam build            # build to build/dev/javascript/
npm run dev            # start local Wrangler dev server at localhost:8787
```

Pre-commit check: `gleam format --check && gleam test && gleam build` — all three must pass before committing. Use the `/check` skill to run them in sequence.

## Git & Commits

- **Always ask for permission before running `git commit`** — never auto-commit
- Commit message format: lowercase, past tense, no prefixes, no emojis, under 50 characters
  - Good: `updated default env variables`, `fixed coordinate validation`
  - Bad: `Update README` (uppercase), `update readme` (imperative), `feat: add X` (prefix)
- All commits must be signed (branch protection enforces this on `main`)
- Rebase to organize commits into logical units before pushing
- Run `/simplify` before suggesting a commit is ready; commit any simplify changes separately

## API Design

All responses — including errors — must include an `outages` array:

```json
{ "error": "message", "outages": [] }
```

Never omit `outages` from any response shape.

## Documentation

Three docs, each with a distinct audience — keep them in sync when making changes:

- `README.md` — user-facing; how to use the API, example responses, test mode, error messages
- `REQUIREMENTS.md` — implementation reference; what the worker must do, exact strings, response shapes, all scenarios
- `CLAUDE.md` — developer/AI guidance; commands, conventions, process rules

When changing behaviour, error messages, test mode, or response shapes: update all affected docs in the same commit as the code change.

## Project Structure

```
src/
  bchydro_proxy.gleam   # main entry point; exports handle(Request, Env)
  cloudflare_ffi.mjs    # JavaScript FFI for Cloudflare Workers platform APIs
  worker.js             # thin Cloudflare Worker wrapper; imports from build/
  coordinates.gleam     # coordinate parsing and BC area validation
  crew.gleam            # crew status enum and descriptions
  outage.gleam          # Outage type, JSON decoder, response encoder
  polygon.gleam         # ray-casting point-in-polygon
  test_mode.gleam       # test mode logic and mock outage fixtures
test/
  *_test.gleam          # gleeunit tests (one file per module)
build/                  # Gleam build output (gitignored)
```

## Testing

- Framework: gleeunit (Gleam's test framework)
- Test functions must end in `_test`
- Use generic BC coordinates in all test data — never real personal addresses
  - Vancouver: `49.2827, -123.1207` | Victoria: `48.4284, -123.3656` | Kelowna: `49.888, -119.496`
- Write tests before code (TDD preferred); confirm they pass before committing

## Gleam Conventions

- Float operators: `+.`, `-.`, `*.`, `/.` and comparisons `>.`, `<.`, `>=.`, `<=.`
- Within-package imports: `import coordinates` (no package prefix)
- Import both type and constructor when needed: `import outage.{type Outage, Outage}`
- Cloudflare FFI: `@external(javascript, "./cloudflare_ffi.mjs", "fn_name")`
- Gleam Result in JS FFI: `{ isOk: true/false, 0: value }`; tuples: plain JS arrays

## Test Mode

Enabled via `TEST_MODE=true` env var (set in `.dev.vars` locally, `false` in production).

Query parameter `?test=` accepts: `outage`, `no-outage`, `multiple`, `error`

Test responses are never cached. The `summary` and `error` fields in test responses are prefixed with `"This is a test. "`. Mock outage cause fields use standard BC Hydro cause strings.

## Privacy & Security

This is a public repository. Never commit:
- Personal coordinates, home addresses, or private locations
- API keys, tokens, passwords, or account credentials
- Cloudflare-specific account details (zones, domains, account IDs)
- Email addresses

Store sensitive config in environment variables or Cloudflare Dashboard only. Review `git diff` before every push.

## Deployment

CI (GitHub Actions) runs format check, tests, and build on every push/PR. On push to `main`, it also deploys via `wrangler deploy` using the `CLOUDFLARE_API_TOKEN` repository secret.

Do not write manual deploy scripts or add deploy commands.

## BC Service Area

Coordinates are validated against BC Hydro's service area before any API call:
- Latitude: 48.3–60.0°N
- Longitude: -139.0 to -114.0°W

Return a 400 (with `"outages": []`) for coordinates outside this range.

# Project Guidelines for BC Hydro Proxy

This document provides guidance for future development and maintenance of this project, including AI agents and developers.

**Key Principle**: Code quality is enforced through automated linting and testing. All new and existing code must pass linting and tests before deployment.

**Privacy & Security Principle**: Never commit personal information, home addresses, private coordinates, account credentials, API keys, or deployment-specific details. This repository is public. Use generic, well-known locations for examples (downtown Vancouver, Victoria, etc.). Sensitive configuration belongs in environment variables or Cloudflare Dashboard, never in code.

## Project Purpose

This is a Cloudflare Worker that proxies BC Hydro outage data and provides location-based filtering for outages. It fetches outage information, filters by geographic area (using point-in-polygon algorithms), and returns structured data with crew status information.

## Core Principles

### 1. Runtime Compatibility
- **Target Runtime**: Node.js LTS (currently 24.x, minimum 20.x)
- **Deployment**: Cloudflare Workers via Wrangler v4
- **All code must be compatible with the Node.js LTS version specified in `.nvmrc`**
- CI/CD validates Node.js compatibility before any deployment
- Use `nvm use` to switch to the correct Node.js version locally

### 2. Development Environment
- **Node.js LTS**: Use the version specified in `.nvmrc` (currently 24)
- **Package Manager**: npm (comes with Node.js)
- **Installation**: Use nvm to manage Node.js versions (`nvm install 24`, `nvm use`)
- Keep development environment aligned with CI/CD and production runtime

### 3. Project Structure
```
src/
  index.js           # Worker entry point
  helpers/
    coordinates.js   # Coordinate parsing and validation
    polygon.js       # Point-in-polygon algorithm and polygon operations
    crew.js          # Crew status code mapping
tests/
  *.test.js          # Unit tests (Node.js test runner format)
.nvmrc              # Specifies Node.js LTS version (24)
wrangler.toml       # Cloudflare Worker configuration
```

### 4. Testing Strategy
- **Framework**: Node.js built-in test runner (no external framework)
- **Location**: `tests/` directory
- **Coverage**: Helpers and worker logic should have unit tests
- **Command**: `npm test` for running tests locally
- **Watch mode**: `npm run test:watch` for development
- **CI**: GitHub Actions validates on Node.js 22.x and 24.x before deployment
- **Workflow**: Write tests, run them locally, confirm they pass before pushing code
- **Requirement**: All tests must pass locally before code is committed and pushed

### 5. Deployment & CI/CD
- **GitHub Actions**: Runs tests on every push and PR
- **Cloudflare Integration**: Native GitHub integration handles actual deployment (separate from CI)
- **Branch Protection**: Main branch should require test status checks to pass before merge
- **No Manual Deploy Scripts**: Cloudflare's native integration is responsible for deployments

### 6. Dependencies
- **Runtime**: None (Cloudflare Worker environment provides globals)
- **Dev**: `wrangler` v4+ (Cloudflare CLI)
- **Keep it minimal** — avoid unnecessary dependencies

### 7. Code Standards
- **Language**: JavaScript (ES modules)
- **Syntax**: Modern JS (arrow functions, async/await, etc.) compatible with Node.js 20+
- **Modules**: Use ES6 modules (`import`/`export`)
- **Error Handling**: Graceful error handling in the worker; return meaningful HTTP responses
- **Helper Functions**: Keep helpers pure and testable; separate from worker logic

### 9. Privacy & Security (Mandatory)
- **No personal information**: Never commit home addresses, personal coordinates, or any private details
- **No account credentials**: API keys, tokens, passwords, account IDs must never be in code or git history
- **Generic examples**: Use well-known public locations for examples (downtown Vancouver: 49.2827, -123.1207; Victoria; Nanaimo, etc.)
- **Sensitive config**: Store in environment variables or Cloudflare Dashboard, never hardcoded or committed
- **No deployment specifics**: Don't reference specific Cloudflare zones, domains, or account-specific routing
- **Code review for commits**: Before pushing, verify no sensitive data leaked (check diffs carefully)

### 10. Linting & Code Quality (Mandatory)
- **Tool**: ESLint with minimal, Node.js-friendly configuration
- **Command**: `npm run lint` to check for issues
- **Auto-fix**: `npm run lint:fix` to automatically fix fixable issues
- **Rules**: Enforces semicolons, double quotes, proper indentation, `const` over `var`, strict equality, and undefined variable detection
- **Cloudflare globals**: ESLint is configured to recognize Cloudflare Worker globals (Request, Response, fetch, caches, URL)
- **CI Enforcement**: GitHub Actions runs linting on every push and PR — linting must pass before tests run
- **Remember**: Linting also catches obvious secrets and suspicious patterns. If linting passes, you're less likely to accidentally leak credentials
- **Requirements** (Non-negotiable):
  - Run `npm run lint` before committing code
  - Fix all lint errors (red) — code will not pass CI if errors exist
  - Warnings (yellow) must be addressed or suppressed with inline comments if intentional
  - Linting must pass locally before pushing code
  - No code will be deployed if linting fails in GitHub Actions

## When Making Changes

1. **Before writing code**: Ensure the change aligns with the project's purpose
2. **Review for sensitive data**: Before coding, check that examples/test data don't contain personal info (addresses, account details, API keys)
3. **Write tests first** (TDD recommended): Tests should cover the new functionality
   - Use generic coordinates for BC locations (Vancouver: 49.2827/-123.1207, Victoria, Nanaimo, etc.)
   - Never hardcode real personal addresses or private details
4. **Lint your code**: Run `npm run lint` to check for issues
   - Fix all lint errors (red) — code will not pass CI without passing linting
   - Address warnings (yellow) or suppress with inline comments if intentional
   - Use `npm run lint:fix` to automatically fix fixable issues
   - Linting is a quality gate — code will not pass CI without passing linting
5. **Test locally**: Run `npm test` to ensure Node.js compatibility and confirm your changes work
6. **Run tests and lint after every change**: Always verify both pass after modifying code
   - Use `npm run test:watch` for continuous test validation during development
   - Tests and linting must pass before committing code
7. **Check structure**: Keep helpers separated and testable; don't add logic to `index.js` that should be in helpers
8. **Update wrangler.toml if needed**: Use generic variable names; never include account-specific details or credentials
9. **No hardcoded secrets**: Use environment variables for configuration (set in Cloudflare Dashboard, never in code)
10. **Review your diff before pushing**: Scan `git diff` for any accidentally committed credentials, personal addresses, or account details
11. **Verify CI passes**: Before merging, ensure GitHub Actions linting and test jobs succeed on all tested Node.js versions

## Caching Strategy

BC Hydro outage data is updated frequently (roughly every 5-10 minutes). To balance not hitting their servers too hard while serving reasonably fresh data:

- **Cache TTL**: 5 minutes (`Cache-Control: public, max-age=300`)
- **Rationale**: Users typically check outage status every 5-10 minutes, and a 5-minute cache prevents excessive backend requests
- **Implementation**: Set cache headers in Worker responses; Cloudflare will automatically cache

## Secret Scanning

To prevent accidental commits of credentials or sensitive data:

- **Use GitHub's built-in secret scanning**: Automatically enabled for public repositories
- **Optional: Add pre-commit hooks**: Consider `detect-secrets` or `git-secrets` for local validation before commits

## Quick Reference

| Task | Command |
|------|---------|
| Install correct Node version | `nvm install 24 && nvm use` |
| Install deps | `npm install` |
| Lint code | `npm run lint` |
| Fix lint issues | `npm run lint:fix` |
| Run tests | `npm test` |
| Watch tests | `npm run test:watch` |
| Pre-commit check | `npm run lint && npm test` |
| Local dev server | `npm run dev` or `npx wrangler dev` |
| Check Node version | `node --version` (should match `.nvmrc`) |
| Check Wrangler version | `npx wrangler --version` (should be v4.x.x) |

## License

This project uses the Unlicense (public domain). See LICENSE file for details.
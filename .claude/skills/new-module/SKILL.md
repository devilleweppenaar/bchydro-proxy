---
name: new-module
description: Add a new Gleam module to this project. Creates src/<name>.gleam, test/<name>_test.gleam, and FFI bindings if needed. Use when the user asks to add a new module, feature, or component.
---

Add a new Gleam module to this project. Follow these steps:

1. Create `src/<module_name>.gleam` with the module's public types and functions.
2. Create `test/<module_name>_test.gleam` with gleeunit tests covering the public API.
3. If the module needs to call JavaScript/Cloudflare APIs not already in `src/cloudflare_ffi.mjs`, add the FFI bindings there and declare `@external` functions in the module.

Conventions to follow:
- Use `Result(a, b)` for operations that can fail — never panic or use `assert` in library code.
- Use `Option(a)` for optional values, not nullable types.
- Keep modules focused: one concern per file, matching the existing pattern (coordinates, crew, polygon, test_mode).
- All public types and functions that form the module's API should be `pub`. Internal helpers are private (no `pub`).
- Tests live in `test/` and use `gleeunit/should` for assertions.
- Run `/check` after writing the module to verify format, tests, and build all pass.

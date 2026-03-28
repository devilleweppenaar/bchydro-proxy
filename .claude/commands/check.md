Run the full quality check for this Gleam project in sequence:

1. `gleam format --check` — verify all Gleam source files are correctly formatted. If this fails, tell the user to run `gleam format` to fix it.
2. `gleam test` — run all tests. Report any failures with the test name and error.
3. `gleam build` — verify the project compiles cleanly.

Report the result of each step clearly. If any step fails, stop and do not proceed to the next step. The pre-commit requirement is that all three pass.

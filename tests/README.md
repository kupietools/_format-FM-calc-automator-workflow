# Regression test corpus

This is the running record of every known edge case for `source-and-info/mk-format-fm-calc.pl`, one pair of files per case in `tests/cases/`:

- `NN-slug.input` — a calc, fed to the script exactly as-is via stdin (byte-for-byte, including its line-ending style — several cases exist specifically *because* line-ending style matters).
- `NN-slug.expected` — the exact, complete stdout the script should produce for that input (including the trailing credit-comment block), captured only after the corresponding output has actually been read and confirmed correct.

Run the whole suite with `./run-tests.sh` from the repo root. It runs each `.input` through `source-and-info/mk-format-fm-calc.pl` (the single source of truth — the packaged workflow and zip are synced from this file, never edited independently) with a hang timeout, diffs stdout against `.expected`, and reports pass/fail per case plus a summary. Nonzero exit if anything fails or hangs, so it's usable as a pre-commit/pre-release gate, not just a manual check.

## The rule this exists to enforce

Every bug found in this script so far — the `\r`/`\r\n` hang, `%`/`?` field-name corruption, `NEXTGETSSPACES`/`THISGETSSPACES` silently deleting field names, and (found during the architectural review that led to this corpus) the `//`-comment kludge corrupting quoted URLs and `%BREAKHERE%` colliding with real field-name text — has been the same underlying shape: a bare, unescaped internal marker colliding with something legal in real FileMaker calc syntax. Each one was caught by a human or a cold-review pass stumbling into it, not by any mechanical check. This corpus is that mechanical check, going forward.

**Whenever a new edge case is found or even just thought of — a bug, a close call, something that turned out fine but felt worth checking — add it here as a new case, with a name that says what it's testing.** Don't wait for it to actually break something first. Whenever a fix lands for anything in this script, the entire suite must pass before considering the fix done, not just the one case the fix was aimed at.

## Adding a new case

1. Write the `.input` file — the exact calc text to feed the script, however it needs to be constructed (see `make-cr-input.sh` for line-ending manipulation helpers, if line-ending style is what the case is testing).
2. Run `perl source-and-info/mk-format-fm-calc.pl < tests/cases/NN-slug.input` and **read the output yourself, actually confirm it's correct** — don't just save whatever comes out.
3. Once confirmed correct, save that exact output as `tests/cases/NN-slug.expected` (`... > tests/cases/NN-slug.expected`).
4. Run `./run-tests.sh` and confirm the new case (and everything else) passes.

`./run-tests.sh --record NN-slug` will (re)generate the `.expected` file for one case from the script's current actual output — useful after fixing a bug whose case previously had a hand-written "this is what it *should* say" expected file, or after a deliberate, verified formatting-behavior change. It does **not** ask you to verify the output first — that's still on you, every time, before trusting what it writes. Never use `--record` to "make a failing test pass" without reading the output and confirming by eye that it's actually now correct.

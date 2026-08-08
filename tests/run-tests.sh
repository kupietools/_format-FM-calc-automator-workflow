#!/bin/bash
# Regression test runner for mk-format-fm-calc.pl. See README.md in this directory.
#
# Usage:
#   ./run-tests.sh                 run every case in cases/, report pass/fail, nonzero exit on any failure
#   ./run-tests.sh NN-slug         run just one case
#   ./run-tests.sh --record NN-slug   (re)generate NN-slug.expected from the script's CURRENT actual
#                                      output. Only use this after reading the output yourself and
#                                      confirming it's actually correct -- this does not check that for you.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
FORMATTER="$REPO_ROOT/source-and-info/mk-format-fm-calc.pl"
CASES_DIR="$SCRIPT_DIR/cases"
HANG_TIMEOUT_SECS=8

if [ ! -f "$FORMATTER" ]; then
    echo "ERROR: formatter not found at $FORMATTER" >&2
    exit 1
fi

# Runs one case; prints PASS/FAIL/HANG/MISSING-EXPECTED; returns 0 on pass, 1 otherwise.
run_one() {
    local input="$1"
    local name expected actual_file pid
    name="$(basename "$input" .input)"
    expected="$CASES_DIR/$name.expected"
    actual_file=$(mktemp)

    # Hang protection: run in background, poll for completion, kill if it overruns.
    perl "$FORMATTER" < "$input" > "$actual_file" 2>&1 &
    pid=$!
    local waited=0
    while kill -0 "$pid" 2>/dev/null; do
        sleep 1
        waited=$((waited + 1))
        if [ "$waited" -ge "$HANG_TIMEOUT_SECS" ]; then
            kill -9 "$pid" 2>/dev/null
            echo "HANG   $name  (still running after ${HANG_TIMEOUT_SECS}s, killed)"
            rm -f "$actual_file"
            return 1
        fi
    done
    wait "$pid" 2>/dev/null

    if [ "${RECORD_MODE:-0}" = "1" ]; then
        cp "$actual_file" "$expected"
        echo "RECORDED $name -> $expected (NOT verified for correctness -- read it yourself)"
        rm -f "$actual_file"
        return 0
    fi

    if [ ! -f "$expected" ]; then
        echo "MISSING-EXPECTED  $name  (no $name.expected -- run with --record after verifying output by eye)"
        rm -f "$actual_file"
        return 1
    fi

    if diff -q "$expected" "$actual_file" > /dev/null 2>&1; then
        echo "PASS   $name"
        rm -f "$actual_file"
        return 0
    else
        echo "FAIL   $name"
        echo "  --- expected ---"
        sed 's/^/  /' "$expected"
        echo "  --- actual ---"
        sed 's/^/  /' "$actual_file"
        echo "  --- diff (expected vs actual) ---"
        diff "$expected" "$actual_file" | sed 's/^/  /'
        rm -f "$actual_file"
        return 1
    fi
}

RECORD_MODE=0
TARGET=""
if [ "${1:-}" = "--record" ]; then
    RECORD_MODE=1
    TARGET="${2:-}"
elif [ -n "${1:-}" ]; then
    TARGET="$1"
fi

fail_count=0
total_count=0

if [ -n "$TARGET" ]; then
    input="$CASES_DIR/$TARGET.input"
    if [ ! -f "$input" ]; then
        echo "ERROR: no such case: $CASES_DIR/$TARGET.input" >&2
        exit 1
    fi
    total_count=1
    run_one "$input" || fail_count=1
else
    for input in "$CASES_DIR"/*.input; do
        [ -e "$input" ] || continue
        total_count=$((total_count + 1))
        run_one "$input" || fail_count=$((fail_count + 1))
    done
fi

echo
echo "$((total_count - fail_count))/$total_count passed."
[ "$fail_count" -eq 0 ]

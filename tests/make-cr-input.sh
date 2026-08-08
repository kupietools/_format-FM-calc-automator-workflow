#!/bin/bash
# Helper: convert a \n-delimited input file's line endings to \r-only or \r\n, for building
# line-ending-specific test cases. Line-ending style has mattered before (the \r/\r\n hang) --
# this makes it easy to construct new cases that test it deliberately rather than by accident.
#
# Usage:
#   ./make-cr-input.sh cr   < some.input > some-cr.input
#   ./make-cr-input.sh crlf < some.input > some-crlf.input
set -euo pipefail
case "${1:-}" in
    cr)   perl -pe 's/\n/\r/' ;;
    crlf) perl -pe 's/\n/\r\n/' ;;
    *) echo "Usage: $0 {cr|crlf} < input > output" >&2; exit 1 ;;
esac

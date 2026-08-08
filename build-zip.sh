#!/bin/bash
# Rebuilds "_Format FM Calc.workflow.zip" from the tracked "_Format FM Calc.workflow" bundle.
#
# The .workflow folder in this repo is the source of truth (it's what actually gets edited/tested,
# and its document.wflow is plain XML plist, so it diffs and reviews cleanly in git). The .zip is a
# generated distributable — never hand-edit it, always regenerate it from the bundle with this script,
# so the two can't silently drift out of sync the way they did before.
#
# Usage: ./build-zip.sh
# On success, prints the path to the freshly-built, verified zip.

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

BUNDLE="_Format FM Calc.workflow"
ZIP="_Format FM Calc.workflow.zip"

if [ ! -d "$BUNDLE" ]; then
    echo "ERROR: '$BUNDLE' not found next to this script." >&2
    exit 1
fi

echo "== Validating source bundle =="
plutil -lint "$BUNDLE/Contents/document.wflow"
plutil -lint "$BUNDLE/Contents/Info.plist"

# Sanity-check the embedded perl script actually parses before we ship it.
PERL_SCRIPT=$(mktemp)
trap 'rm -f "$PERL_SCRIPT"' EXIT
python3 - "$BUNDLE/Contents/document.wflow" "$PERL_SCRIPT" << 'PYEOF'
import plistlib, sys
wflow_path, out_path = sys.argv[1], sys.argv[2]
with open(wflow_path, "rb") as f:
    d = plistlib.load(f)
script = d['actions'][0]['action']['ActionParameters']['COMMAND_STRING']
with open(out_path, "w") as f:
    f.write(script)
PYEOF
echo "== Checking embedded perl script syntax =="
perl -c "$PERL_SCRIPT"

echo "== Rebuilding zip =="
rm -f "$ZIP"
zip -r -X "$ZIP" "$BUNDLE" > /dev/null

echo "== Verifying rebuilt zip =="
VERIFY_DIR=$(mktemp -d)
trap 'rm -f "$PERL_SCRIPT"; rm -rf "$VERIFY_DIR"' EXIT
unzip -q "$ZIP" -d "$VERIFY_DIR"
diff "$VERIFY_DIR/$BUNDLE/Contents/document.wflow" "$BUNDLE/Contents/document.wflow"
plutil -lint "$VERIFY_DIR/$BUNDLE/Contents/document.wflow" > /dev/null

echo "OK: $ZIP rebuilt and verified against '$BUNDLE'."

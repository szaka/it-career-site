#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
npm run build
python3 scripts/audit/check-built-site.py
AUDIT_TOOLS="$(mktemp -d "${TMPDIR:-/tmp}/portfolio-audit-tools.XXXXXX")"
export AUDIT_TOOLS
trap 'rm -rf "$AUDIT_TOOLS"' EXIT
npm install --prefix "$AUDIT_TOOLS" --no-audit --no-fund playwright @axe-core/playwright
if [ "${AUDIT_REINSTALL_FIREFOX:-0}" = "1" ]; then
  "$AUDIT_TOOLS/node_modules/.bin/playwright" install --force firefox
fi
"$AUDIT_TOOLS/node_modules/.bin/playwright" install chromium firefox webkit
node scripts/audit/site-audit.mjs 2>&1 | tee site-audit-report.txt

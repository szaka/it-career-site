#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: bash scripts/report-entry.sh PROJECT-ID POST-SLUG" >&2
  exit 2
fi

project=$1
post=$2
for slug in "$project" "$post"; do
  if [[ ! "$slug" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
    echo "Invalid project ID or post slug: $slug" >&2
    exit 2
  fi
done

cd "$(dirname "$0")/.."
report="$HOME/Downloads/portfolio-check-$project-$(date +%Y%m%d-%H%M%S).txt"

run_check() {
  local label=$1
  shift
  if "$@"; then
    printf '✅ %s\n' "$label"
  else
    printf '❌ %s\n' "$label"
    failed=1
  fi
}

check_metadata() {
  python3 - "$project" "$post" <<'PY'
import re
import sys
from datetime import date
from html.parser import HTMLParser
from pathlib import Path

class Metadata(HTMLParser):
    def __init__(self):
        super().__init__()
        self.in_title = False
        self.title = []
        self.dates = []

    def handle_starttag(self, tag, attrs):
        if tag == "title":
            self.in_title = True
        if tag == "time":
            self.dates.append(dict(attrs).get("datetime", ""))

    def handle_endtag(self, tag):
        if tag == "title":
            self.in_title = False

    def handle_data(self, data):
        if self.in_title:
            self.title.append(data)

project, post = sys.argv[1:]
failed = False
for path in (
    Path(f"dist/projects/{project}/index.html"),
    Path(f"dist/blog/{post}/index.html"),
):
    metadata = Metadata()
    metadata.feed(path.read_text(encoding="utf-8"))
    title = "".join(metadata.title).strip()
    valid_dates = []
    for stamp in metadata.dates:
        if re.match(r"^\d{4}-\d{2}-\d{2}(?:T|$)", stamp):
            try:
                valid_dates.append(date.fromisoformat(stamp[:10]))
            except ValueError:
                pass
    if not title.endswith(" | Shahid Zaka") or not title.split(" | ", 1)[0].strip():
        print(f"{path}: unexpected browser title {title!r}")
        failed = True
    if not valid_dates:
        print(f"{path}: missing a valid date in a <time> element")
        failed = True
    elif title:
        print(f"{title} — {valid_dates[0]}")
sys.exit(1 if failed else 0)
PY
}

{
  printf 'Portfolio check — %s\n' "$(date)"
  printf 'Project: %s\nArticle: %s\nFolder: %s\n\n' "$project" "$post" "$PWD"

  failed=0
  run_check "Build, routes, related article, topic backlinks, reading time, local files, and RSS" \
    bash scripts/check-entry.sh "$project" "$post"

  if [ "$failed" -eq 0 ]; then
    run_check "Browser titles and machine-readable dates" check_metadata
  else
    printf '⏭ Metadata check skipped because the entry check failed.\n'
  fi

  printf '\nHuman review before publishing\n'
  printf '%s\n' \
    '□ Read the prose for spelling, grammar, and claims supported by the lab.' \
    '□ Check screenshots and alt text, and open each attachment.' \
    '□ Test Copy Code and narrow-screen wrapping in Safari.' \
    '□ Open external evidence links as a visitor.' \
    '□ Review staged files for drafts, sample assets, and private information.'

  if [ "$failed" -eq 0 ]; then
    printf '\n✅ Automated checks passed. Human review is pending.\n'
  else
    printf '\n❌ Fix the failed checks before publishing.\n'
  fi
  printf 'Report: %s\n' "$report"
  exit "$failed"
} | tee "$report"

#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

project=${1:?Enter a project ID}
post=${2:?Enter a post slug}
for slug in "$project" "$post"; do
  if [[ ! "$slug" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
    echo "Invalid project ID or post slug: $slug" >&2
    exit 2
  fi
done

git fetch origin main
head="$(git rev-parse HEAD)"
if [ "$head" != "$(git rev-parse origin/main)" ]; then
  echo "Local HEAD differs from GitHub main. Sync or review the branch before publishing."
  exit 1
fi

if ! git diff --cached --quiet; then
  echo "Git already has staged changes. Review them before running this task."
  exit 1
fi

files=("src/data/topics.ts" "src/content/blog/$post.md")
if [ -d "public/entries/$post" ]; then
  files+=("public/entries/$post")
fi

# Use a temporary Git index so a failed check leaves your normal staging area alone.
scratch="$(mktemp -d "${TMPDIR:-/tmp}/portfolio-publish.XXXXXX")"
trap 'rm -rf -- "$scratch"' EXIT
export GIT_INDEX_FILE="$scratch/index"
git read-tree "$head"
git add -- "${files[@]}"

if git diff --cached --quiet; then
  echo "There are no changes to publish for this entry."
  exit 0
fi

echo "Files selected for publishing:"
git diff --cached --name-status

snapshot="$scratch/site"
mkdir "$snapshot"
git checkout-index --all --prefix="$snapshot/"
mkdir -p "$snapshot/scripts"
cp scripts/check-entry.sh scripts/report-entry.sh "$snapshot/scripts/"

(
  cd "$snapshot"
  npm ci
  bash scripts/report-entry.sh "$project" "$post"
)

# Commit the same tree that passed the report.
tree="$(git write-tree)"
unset GIT_INDEX_FILE
if [ "$(git rev-parse HEAD)" != "$head" ] || ! git diff --cached --quiet; then
  echo "The local branch or index changed during validation. Nothing pushed."
  exit 1
fi
commit="$(printf 'Publish portfolio entry %s\n' "$post" | git commit-tree "$tree" -p "$head")"
git push origin "$commit:refs/heads/main"

# Advance the local branch and update its index without overwriting working files.
git update-ref HEAD "$commit" "$head"
git reset --mixed "$commit"
echo "Published commit $commit to GitHub main."

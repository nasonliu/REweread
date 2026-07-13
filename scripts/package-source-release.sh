#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '[:space:]' <"$ROOT_DIR/VERSION")"
OUT_DIR="${OUT_DIR:-$ROOT_DIR/packages}"
ARCHIVE="$OUT_DIR/REweread-v${VERSION}-source.tar.gz"
CHECKSUMS="$OUT_DIR/SHA256SUMS.txt"

if [[ -n "$(git -C "$ROOT_DIR" status --short)" ]]; then
  echo "Refusing to package a dirty worktree." >&2
  exit 1
fi

node "$ROOT_DIR/scripts/check-repository.mjs"
node "$ROOT_DIR/tests/run-all.mjs"

mkdir -p "$OUT_DIR"
rm -f "$ARCHIVE" "$CHECKSUMS"
git -C "$ROOT_DIR" archive \
  --format=tar.gz \
  --prefix="REweread-v${VERSION}/" \
  --output="$ARCHIVE" \
  HEAD

(
  cd "$OUT_DIR"
  shasum -a 256 "$(basename "$ARCHIVE")" >"$(basename "$CHECKSUMS")"
)

printf 'archive=%s\n' "$ARCHIVE"
printf 'checksums=%s\n' "$CHECKSUMS"

#!/bin/bash
# build.sh — renders every raw screenshot into a finished App Store screenshot
# for every language found under store/screenshots/raw/<lang>/.
#
# Usage:
#   Scripts/screenshots/build.sh              # all languages
#   Scripts/screenshots/build.sh tr en         # only these languages
#
# Must be run from the repository root (paths below are relative to it).

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

RAW_DIR="store/screenshots/raw"
OUT_DIR="store/screenshots/out"
COMPOSE="Scripts/screenshots/compose.swift"
THEME="Scripts/screenshots/theme.json"
CAPTIONS="Scripts/screenshots/captions.json"
METADATA_DIR="store/metadata"

if [ ! -d "$RAW_DIR" ]; then
  echo "build.sh: no raw directory at $RAW_DIR" >&2
  exit 1
fi

if [ "$#" -gt 0 ]; then
  LANGS=("$@")
else
  LANGS=()
  for d in "$RAW_DIR"/*/; do
    [ -d "$d" ] || continue
    LANGS+=("$(basename "$d")")
  done
fi

if [ "${#LANGS[@]}" -eq 0 ]; then
  echo "build.sh: no language directories found under $RAW_DIR" >&2
  exit 1
fi

total=0
echo "Mihrab screenshot build — languages: ${LANGS[*]}"
echo

for lang in "${LANGS[@]}"; do
  lang_dir="$RAW_DIR/$lang"
  if [ ! -d "$lang_dir" ]; then
    echo "  [$lang] skipped — no raw directory at $lang_dir" >&2
    continue
  fi

  shopt -s nullglob
  raw_files=("$lang_dir"/*.png)
  shopt -u nullglob

  if [ "${#raw_files[@]}" -eq 0 ]; then
    echo "  [$lang] skipped — no PNGs in $lang_dir" >&2
    continue
  fi

  mkdir -p "$OUT_DIR/$lang"
  count=0

  for raw in "${raw_files[@]}"; do
    base="$(basename "$raw")"
    # Leading digits before the first "-" become the output index, e.g.
    # "02-times.png" -> index "02" -> out/<lang>/02.png. Falls back to the
    # bare filename stem if there is no leading-digit prefix.
    if [[ "$base" =~ ^([0-9]+)- ]]; then
      index="${BASH_REMATCH[1]}"
    else
      index="${base%.png}"
    fi
    out="$OUT_DIR/$lang/$index.png"

    swift "$COMPOSE" \
      --lang "$lang" \
      --index "$index" \
      --raw "$raw" \
      --out "$out" \
      --theme "$THEME" \
      --captions "$CAPTIONS" \
      --metadata-dir "$METADATA_DIR"

    dims="$(sips -g pixelWidth -g pixelHeight "$out" 2>/dev/null | awk '/pixelWidth/{w=$2} /pixelHeight/{h=$2} END{print w"x"h}')"
    echo "  [$lang] $index.png  ($dims)  <- $base"
    count=$((count + 1))
    total=$((total + 1))
  done

  echo "  [$lang] $count frame(s) done"
  echo
done

echo "Total frames rendered: $total"
echo "Output: $OUT_DIR/<lang>/<NN>.png"

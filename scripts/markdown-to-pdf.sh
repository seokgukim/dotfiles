#!/usr/bin/env bash

set -euo pipefail

usage() {
    echo "Usage: $(basename "$0") <input.md> [output.pdf]" >&2
}

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    usage
    exit 2
fi

INPUT="$1"
if [ ! -f "$INPUT" ]; then
    echo "Error: Markdown file not found: $INPUT" >&2
    exit 1
fi

case "$INPUT" in
    *.md|*.markdown) ;;
    *)
        echo "Error: Input must have a .md or .markdown extension: $INPUT" >&2
        exit 1
        ;;
esac

INPUT_DIR="$(cd -- "$(dirname -- "$INPUT")" && pwd -P)"
INPUT_PATH="$INPUT_DIR/$(basename -- "$INPUT")"
GENERATED_PATH="${INPUT_PATH%.*}.pdf"

if [ "$#" -eq 2 ]; then
    OUTPUT_DIR="$(dirname -- "$2")"
    mkdir -p -- "$OUTPUT_DIR"
    OUTPUT_DIR="$(cd -- "$OUTPUT_DIR" && pwd -P)"
    OUTPUT_PATH="$OUTPUT_DIR/$(basename -- "$2")"
else
    OUTPUT_PATH="$GENERATED_PATH"
fi

case "$OUTPUT_PATH" in
    *.pdf) ;;
    *)
        echo "Error: Output must have a .pdf extension: $OUTPUT_PATH" >&2
        exit 1
        ;;
esac

PDF_OPTIONS='{"format":"A4","margin":"20mm","printBackground":true}'

if command -v md-to-pdf >/dev/null 2>&1; then
    md-to-pdf "$INPUT_PATH" --basedir "$INPUT_DIR" --pdf-options "$PDF_OPTIONS"
elif command -v npx >/dev/null 2>&1; then
    npx --yes md-to-pdf@5.2.5 "$INPUT_PATH" --basedir "$INPUT_DIR" --pdf-options "$PDF_OPTIONS"
else
    echo "Error: md-to-pdf or npx is required. Install Node.js and npm first." >&2
    exit 1
fi

if [ "$OUTPUT_PATH" != "$GENERATED_PATH" ]; then
    mv -f -- "$GENERATED_PATH" "$OUTPUT_PATH"
fi

printf 'Created %s\n' "$OUTPUT_PATH"

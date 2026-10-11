#!/bin/sh

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 source_file" >&2
    exit 1
fi

SOURCE=$1

if [ ! -f "$SOURCE" ]; then
    echo "Error: source file not found: $SOURCE" >&2
    exit 2
fi

OUTPUT=$(awk '/Output:/ {
    sub(/^.*Output:[[:space:]]*/, "")
    print
    exit
}' "$SOURCE")

if [ -z "$OUTPUT" ]; then
    echo "Error: Output comment not found" >&2
    exit 3
fi

TMPDIR=$(mktemp -d)

if [ ! -d "$TMPDIR" ]; then
    echo "Error: could not create temporary directory" >&2
    exit 4
fi

echo "Source file: $SOURCE"
echo "Output file: $OUTPUT"
echo "Temporary directory: $TMPDIR"
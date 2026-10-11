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

cleanup()
{
    rm -rf "$TMPDIR"
}

trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP
trap 'cleanup' 0

echo "Source file: $SOURCE"
echo "Output file: $OUTPUT"
echo "Temporary directory: $TMPDIR"

g++ "$SOURCE" -o "$TMPDIR/$OUTPUT"

if [ "$?" -ne 0 ]; then
    echo "Error: compilation failed" >&2
    exit 5
fi

SOURCE_DIR=$(dirname "$SOURCE")

mv "$TMPDIR/$OUTPUT" "$SOURCE_DIR/$OUTPUT"

if [ "$?" -ne 0 ]; then
    echo "Error: could not move output file" >&2
    exit 6
fi

echo "Compilation successful"
echo "Created: $SOURCE_DIR/$OUTPUT"
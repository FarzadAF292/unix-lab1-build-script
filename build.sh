#!/bin/sh

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 source_file" >&2
    exit 1
fi

SOURCE=$1
START_DIR=$(pwd)

case "$SOURCE" in
    /*)
        SOURCE_ABS=$SOURCE
        ;;
    *)
        SOURCE_ABS="$START_DIR/$SOURCE"
        ;;
esac

if [ ! -f "$SOURCE_ABS" ]; then
    echo "Error: source file not found: $SOURCE" >&2
    exit 2
fi

OUTPUT=$(awk '
    /^[[:space:]]*\/\/[[:space:]]*Output:/ {
        sub(/^[[:space:]]*\/\/[[:space:]]*Output:[[:space:]]*/, "")
        print
        exit
    }
' "$SOURCE_ABS")

if [ -z "$OUTPUT" ]; then
    echo "Error: Output comment not found" >&2
    exit 3
fi

case "$OUTPUT" in
    */* | .*)
        echo "Error: invalid output filename: $OUTPUT" >&2
        exit 7
        ;;
esac

TMPDIR=$(mktemp -d)

if [ ! -d "$TMPDIR" ]; then
    echo "Error: could not create temporary directory" >&2
    exit 4
fi

cleanup()
{
    cd "$START_DIR" 2>/dev/null
    rm -rf "$TMPDIR"
}

terminate()
{
    code=$1

    trap - 0 HUP INT QUIT TERM
    cleanup
    exit "$code"
}

trap 'terminate 129' HUP
trap 'terminate 130' INT
trap 'terminate 131' QUIT
trap 'terminate 143' TERM
trap 'cleanup' 0

echo "Source file: $SOURCE"
echo "Output file: $OUTPUT"
echo "Temporary directory: $TMPDIR"

cd "$TMPDIR" || {
    echo "Error: could not enter temporary directory" >&2
    exit 8
}

g++ "$SOURCE_ABS" -o "$OUTPUT"

if [ "$?" -ne 0 ]; then
    echo "Error: compilation failed" >&2
    exit 5
fi

mv "$OUTPUT" "$START_DIR/$OUTPUT"

if [ "$?" -ne 0 ]; then
    echo "Error: could not move output file" >&2
    exit 6
fi

echo "Compilation successful"
echo "Created: $START_DIR/$OUTPUT"
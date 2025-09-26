#!/bin/bash

set -e

# Check for version argument
if [ -z "$1" ]; then
    echo "Usage: $0 <version> [folder]"
    exit 1
fi

VERSION="$1"
FOLDER="${2:-$(pwd)}"
TMPDIR=$(mktemp -d)
LARGE_FILES=()

cd "$FOLDER"

# Remove __pycache__ folders
find . -type d -name '__pycache__' -exec rm -rf {} +

# Find files > 100MB and move them to TMPDIR
while IFS= read -r -d '' file; do
    LARGE_FILES+=("$file")
    mv "$file" "$TMPDIR/"
done < <(find . -type f -size +100M -print0)

# Zip the folder contents
zip -yr "krita_vision_tools-linux-x64-$VERSION.zip" *

# Restore large files
for file in "${LARGE_FILES[@]}"; do
    mv "$TMPDIR/$(basename "$file")" "$file"
done

# Move zip to home directory
mv "krita_vision_tools-linux-x64-$VERSION.zip" ~/

# Clean up
rm -rf "$TMPDIR"

echo "Packaging complete. Zip file moved to ~/krita_vision_tools-linux-x64-$VERSION.zip"
#!/usr/bin/env bash

INPUT_DIR="/mnt/f/downloads/Low Poly Wild West"
CONVERTER="$HOME/bin/FBX2glTF-linux-x64"

# Find every .fbx (case-insensitive) and run the converter on it
find "$INPUT_DIR" -type f -iname '*.fbx' | while IFS= read -r file; do
    echo "Converting: $file"
    "$CONVERTER" --binary "$file"
done


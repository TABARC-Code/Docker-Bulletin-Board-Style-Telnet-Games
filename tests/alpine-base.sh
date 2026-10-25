#!/usr/bin/env bash
# Check the base tags before anyone spends an afternoon debugging an old image.
set -euo pipefail
cd "$(dirname "$0")/.."
for folder in worm Robot Pinball "Hunt the Wumpus"; do
    file="$folder/Dockerfile"
    [[ -f "$file" ]] || { echo "Missing $file" >&2; exit 1; }
    grep -Fxq 'FROM alpine:3.24.3' "$file" || { echo "Base image mismatch: $file" >&2; exit 1; }
done
echo "Alpine base image checks passed."

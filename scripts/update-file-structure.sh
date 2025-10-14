#!/usr/bin/env bash
set -euo pipefail

# update-file-structure.sh
# Generates a tree-like listing of the repository into docs/file_structure.txt
# Excludes common build and VCS folders and the generated file itself.

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

OUTFILE="docs/file_structure.txt"
echo "Generating $OUTFILE from $REPO_ROOT"

# Header with timestamp
printf "Project: %s\nGenerated: %s\n\n" "$REPO_ROOT" "$(date -u +'%Y-%m-%d %H:%M:%SZ')" > "$OUTFILE"

# Build a find expression that prunes common directories we don't want in the listing
find . \
  \( -path './build' -o -path './.git' -o -path './.gradle' -o -path './.dart_tool' -o -path './.idea' -o -path './.pub' -o -path './.packages' -o -path './build' \) -prune -o \
  -print | sed 's|^\./||' | sort | awk -F'/' '{
    depth = NF;
    prefix = "";
    for (i=1;i<depth;i++) prefix = prefix "    ";
    if (NF==1) { print $0 }
    else { print prefix "|-- " $NF }
  }' >> "$OUTFILE"

echo "Wrote $(wc -l < "$OUTFILE") lines to $OUTFILE"

exit 0

#!/bin/bash
# Download the 92 sources the LFS 13.0-systemd book needs and verify every md5.
# Staged in $DEST; moved to the target tree's sources dir once root is available (keep
# it on the same filesystem so the move is a rename, not a copy).
#
# The book and the wget list are the same for every machine, so this script is shared
# and takes no --host: the destination is just a download cache. On a second machine
# the faster route is usually rsync from one that already has them -- see
# hosts/<host>/BOOTSTRAP.md.
set -uo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(dirname "$HERE")
BOOK=$ROOT/book
DEST=${1:-$ROOT/sources-staging}
JOBS=${JOBS:-5}

mkdir -p "$DEST"
cd "$DEST"

total=$(wc -l < "$BOOK/wget-list-systemd")
echo "fetching $total sources -> $DEST (jobs=$JOBS)"

# -nc skips files already present, so this is resumable.
xargs -P "$JOBS" -n 1 -a "$BOOK/wget-list-systemd" \
    curl -fsSL --retry 5 --retry-delay 3 --retry-connrefused --retry-all-errors -O 2>&1 |
    grep -v '^$' || true

echo
echo "=== verifying md5 (authoritative list: $BOOK/md5sums, 92 entries) ==="
cp "$BOOK/md5sums" .
if md5sum -c md5sums > md5.report 2>&1; then
    ok=$(grep -c ': OK$' md5.report)
    echo "PASS: $ok/$total checksums match"
    rm -f md5sums
    exit 0
else
    echo "FAIL:"
    grep -v ': OK$' md5.report | head -30
    echo
    echo "failed: $(grep -c ': FAILED\|: No such file' md5.report)"
    rm -f md5sums
    exit 1
fi

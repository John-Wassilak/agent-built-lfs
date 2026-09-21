#!/bin/bash
# SPDX-License-Identifier: MIT
# agent-built-lfs -- download and verify the book's sources
# Copyright (c) 2026 John Wassilak

# Download the sources a host's pinned LFS book needs and verify every md5.
# Staged in $DEST; moved to the target tree's sources dir once root is available (keep
# it on the same filesystem so the move is a rename, not a copy).
#
# Takes --host like every other tool here (resolved from --host, else $LFS_HOST, else
# the hostname): the LFS book version is now a per-host pin (host.toml's [books].lfs,
# onboarded 2026-09-07 alongside SLFS/GLFS), not a single global one, so this can no
# longer assume every host wants the same wget-list/md5sums. On a second machine
# pinned to the same version, the faster route is usually rsync from one that already
# has them -- see hosts/<host>/BOOTSTRAP.md.
set -uo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(dirname "$HERE")

HOST=""
DEST=""
while [ $# -gt 0 ]; do
    case "$1" in
        --host) HOST=$2; shift 2 ;;
        *) DEST=$1; shift ;;
    esac
done
DEST=${DEST:-$ROOT/sources-staging}
JOBS=${JOBS:-5}

BOOK=$(HOST="$HOST" python3 -c "
import os, sys
sys.path.insert(0, '$HERE')
import lfshost, booklib
host = lfshost.resolve(os.environ.get('HOST') or None)
print(booklib.book_root(lfshost.ROOT, host, 'lfs'))
")

mkdir -p "$DEST"
cd "$DEST"

total=$(wc -l < "$BOOK/wget-list-systemd")
echo "fetching $total sources from $BOOK -> $DEST (jobs=$JOBS)"

# -nc skips files already present, so this is resumable.
xargs -P "$JOBS" -n 1 -a "$BOOK/wget-list-systemd" \
    curl -fsSL --retry 5 --retry-delay 3 --retry-connrefused --retry-all-errors -O 2>&1 |
    grep -v '^$' || true

echo
echo "=== verifying md5 (authoritative list: $BOOK/md5sums) ==="
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

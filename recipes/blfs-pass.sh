#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. Checked AUR first per the standing two-tier policy -- not there either; pass is popular enough for Arch's official 'extra' repo. Arch's own PKGBUILD source is a git tag clone (git.zx2c4.com/password-store); fetched here via that same server's own snapshot endpoint (git.zx2c4.com/password-store/snapshot/password-store-1.7.4.tar.xz, verified reachable directly) rather than guessing a GitHub mirror name. Needs bash (have), gnupg, tree (both just built).
set -e

make DESTDIR=/ WITH_ALLCOMP=yes install
install -Dm0755 -t /usr/bin contrib/dmenu/passmenu

echo "### version"
pass version 2>&1 | head -3


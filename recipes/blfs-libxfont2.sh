#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in this BLFS mirror. Required (hard, unconditional) by xwayland's meson.build as 'xfont2', undocumented in the book's dependency list. Arch's official libxfont2 PKGBUILD builds from a git tag and autoreconfs -- used the equivalent upstream release tarball instead (same content, already carries a generated ./configure, no autoreconf needed) since it's simpler and this mirror has no md5/sha to verify a git checkout against anyway. No published checksum found for this tarball on xorg.freedesktop.org (no .sha256sum/.sig companion file); fetched directly over HTTPS and sanity-checked as a valid tar archive.
set -e

./configure --prefix=/usr --sysconfdir=/etc --disable-static &&
make
make install


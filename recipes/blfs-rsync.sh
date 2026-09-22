#!/bin/bash
# HAND-AUTHORED recipe from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/basicnet/rsync.html
# title  : rsync-3.5.0
# rationale: operator-requested. Recommended dependency popt-1.19 was
# already installed; system zlib is used instead of the bundled copy.
#
# No patch on 13.1. Through 13.0 this recipe applied the book's required
# security patch (upstream 797e17f, an invalid access to the files array
# in sender.c, reported by Rapid7). 3.5.0 carries that fix upstream and
# the BLFS 13.1 page lists no patch at all -- re-read 2026-09-21 against
# basicnet/rsync.html, whose only download is rsync-3.5.0.tar.gz. That
# removal is also what keeps this file legitimately shared: with the
# versioned patch filename gone, no command here names a version, so the
# same recipe is correct for any release that needs no patch.
#
# --disable-xxhash: xxhash is not installed (book default).
# --without-included-zlib: link the system zlib so rsync tracks its
# security updates, per the book's Command Explanations.
#
# configure additionally found zstd, lz4 and OpenSSL on this system, so
# the binary gains zstd/lz4 compression and OpenSSL MD4/MD5 -- more than
# the book's baseline, all from already-tracked packages.
#
# Client-only install: the book's optional rsyncd daemon setup (the
# rsyncd user/group, /etc/rsyncd.conf, and the blfs-systemd-units
# rsyncd.service/.socket) is deliberately NOT done -- none of it is
# needed to run the rsync client, and the firewall's INPUT policy is
# DROP with only SSH open, so a listening daemon on 873 would be dead
# weight and extra attack surface.
set -e

./configure --prefix=/usr \
            --disable-xxhash \
            --without-included-zlib
make

# Test suite left disabled here to match this project's BLFS test policy.
# On 13.0 it was run once by hand at install time: 45 passed, 1 skipped
# (crtimes, unsupported by this configuration), 0 failed. The 13.1 page
# dropped the 'sed -i /typedef/d wildtest.c' prerequisite the 13.0 page
# carried -- it is a plain 'make check' now.
# make check

make install

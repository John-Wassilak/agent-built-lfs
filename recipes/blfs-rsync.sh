#!/bin/bash
# HAND-AUTHORED recipe from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/basicnet/rsync.html
# title  : rsync-3.4.1
# rationale: operator-requested. Recommended dependency popt-1.19 was
# already installed; system zlib is used instead of the bundled copy.
#
# The book's required security patch is applied (upstream commit
# 797e17f, an invalid access to the files array in sender.c, reported
# by Rapid7). It is an additional download alongside the tarball, so it
# must be staged next to the source directory like nodejs's patch.
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

patch -Np1 -i ../rsync-3.4.1-security_fix-1.patch

./configure --prefix=/usr \
            --disable-xxhash \
            --without-included-zlib
make

# Test suite (book: 'sed -i /typedef/d wildtest.c && make check') is
# left disabled here to match this project's BLFS test policy. It was
# run once by hand at install time: 45 passed, 1 skipped (crtimes,
# unsupported by this configuration), 0 failed.
# sed -i '/typedef/d' wildtest.c
# make check

make install

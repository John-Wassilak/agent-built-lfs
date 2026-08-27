#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/imagemagick.html
# title  : ImageMagick-7.1.2-13
#
# Built 2026-08-26 -- awesome window manager's build hard-requires
# `convert` at configure time (icon generation), not listed in the book
# page's own dependency section since ImageMagick isn't normally an
# awesome dependency in BLFS's own tree.
#
# Real gap the book's own download URL missed: imagemagick.org
# restructured/broke the /archive/releases/ path this version's URL
# used (404 on both the exact tarball and the whole directory listing).
# Used the book's own documented fallback mirror instead
# (ftp.osuosl.org/pub/blfs/conglomeration/ImageMagick/), same md5.
set -e

./configure --prefix=/usr     \
    --sysconfdir=/etc \
    --enable-hdri     \
    --with-modules    \
    --with-perl       \
    --disable-static
make
make DOCUMENTATION_PATH=/usr/share/doc/imagemagick-7.1.2 install

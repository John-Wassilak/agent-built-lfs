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
#
# 2026-09-15, laptop: second host, same recipe, built as a dependency of zbar
# (seq 335) -- zbarimg is not compiled at all without MagickWand. Declared
# hand(334) there to match server's hand(226), NOT book(): a book() entry makes
# the extractor the owner of this filename and it rewrites the file, which is
# exactly what happened on the first attempt and silently discarded every
# comment above. The /archive/releases/ 404 recorded above is still live nearly
# three weeks later; re-fetched from the same fallback mirror, md5
# a28a5d65a58fce9c24e8cf4b47cb5c5c, matching the book.
set -e

./configure --prefix=/usr     \
    --sysconfdir=/etc \
    --enable-hdri     \
    --with-modules    \
    --with-perl       \
    --disable-static
make
make DOCUMENTATION_PATH=/usr/share/doc/imagemagick-7.1.2 install

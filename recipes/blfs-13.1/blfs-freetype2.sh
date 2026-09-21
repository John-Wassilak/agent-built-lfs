#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/general/freetype2.html
# title  : FreeType-2.14.3
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: reetype/freetype-doc-2.14.3.tar.xz Download MD5 sum: a9a92aa403d7c1b4eed6ee452dc23305
#   ctx: Download size: 2.1 MB FreeType2 Dependencies Recommended harfBuzz-14.3.1 (runtime) and
#   ctx: libpng-1.6.58 Optional Brotli-1.2.0 and librsvg-2.62.3 Optional (for documentation)
#   ctx: docwriter Installation of FreeType2 If you downloaded the additional documentation,
#   ctx: unpack it into the source tree using the following command:
#   REVIEWED [drop]: Extracts the optional supplementary documentation tarball (freetype-doc-2.14.1.tar.xz), which was not fetched -- docs only, not needed. The base docs/ directory still ships in the main source tree, so block 3 (copying docs/ to /usr/share/doc) is kept.
# tar -xf ../freetype-doc-2.14.3.tar.xz --strip-components=2 -C docs

# --- block 1 --------------------------------------------------
#   ctx: Install FreeType2 by running the following commands:
sed -ri "s:.*(AUX_MODULES.*valid):\1:" modules.cfg &&

sed -r "s:.*(#.*SUBPIXEL_RENDERING) .*:\1:" \
    -i include/freetype/config/ftoption.h   &&

./configure --prefix=/usr            \
            --disable-static         \
            --enable-freetype-config \
            --with-harfbuzz=dynamic  &&
make

# --- block 2 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
make install

# --- block 3 --------------------------------------------------
#   ctx: If you downloaded the optional documentation, install it as the root user:
cp -v -R docs -T /usr/share/doc/freetype-2.14.3 &&
rm -v /usr/share/doc/freetype-2.14.3/freetype-config.1


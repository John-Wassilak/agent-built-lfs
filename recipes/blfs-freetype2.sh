#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/freetype2.html
# title  : FreeType-2.14.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ype-doc-2.14.1.tar.xz Download MD5 sum: 6e08cb8bcd30802a4e8e65c2eb5071cc Download size:
#   ctx: 2.1 MB FreeType2 Dependencies Recommended harfBuzz-12.3.2 (runtime), libpng-1.6.55, and
#   ctx: Which-2.23 Optional Brotli-1.2.0 and librsvg-2.61.4 Optional (for documentation)
#   ctx: docwriter Installation of FreeType2 If you downloaded the additional documentation,
#   ctx: unpack it into the source tree using the following command:
#   REVIEWED [drop]: Extracts the optional supplementary documentation tarball (freetype-doc-2.14.1.tar.xz), which was not fetched -- docs only, not needed. The base docs/ directory still ships in the main source tree, so block 3 (copying docs/ to /usr/share/doc) is kept.
# tar -xf ../freetype-doc-2.14.1.tar.xz --strip-components=2 -C docs

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
cp -v -R docs -T /usr/share/doc/freetype-2.14.1 &&
rm -v /usr/share/doc/freetype-2.14.1/freetype-config.1


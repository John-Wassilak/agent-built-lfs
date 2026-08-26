#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in this BLFS mirror. at-spi2-core hard-requires it (XTEST/RECORD extensions, for accessibility input injection) -- not mentioned in the book's dependency list at all, discovered via the same real failure as libxi above. Arch's official libxtst PKGBUILD as reference -- needs libxext, libxi (previous step), libx11, xorgproto.
set -e

./configure $XORG_CONFIG
make
make install


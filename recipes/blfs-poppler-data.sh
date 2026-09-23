#!/bin/bash
# HAND-AUTHORED recipe -- the book covers this package as an Additional Download on
# general/poppler.html (blocks 3-4, BLFS 13.0), not a page of its own. poppler's step
# dropped those blocks, so this installs the data on its own rather than rebuilding
# poppler. The command is the book's own; lfsbuild has already unpacked and cd'd.
# rationale: xsoft/gimp.html lists Poppler "(including poppler-data)" as Required.
# The data is the CJK/Cyrillic encoding files poppler reads at runtime.
# md5 67ee4a40aa830b1f6e2560ce5f6471ba, matching the book.
set -e

make prefix=/usr install

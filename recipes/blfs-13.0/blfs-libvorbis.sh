#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/multimedia/libvorbis.html
# title  : libvorbis-1.3.7
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: .xz Download MD5 sum: 50902641d358135f06a8392e61c9ac77 Download size: 1.1 MB Estimated
#   ctx: disk space required: 15 MB Estimated build time: 0.1 SBU libvorbis Dependencies Required
#   ctx: libogg-1.3.6 Optional Doxygen-1.16.1 and texlive-20250308 (or install-tl-unx)
#   ctx: (specifically, pdflatex and htlatex) to build the PDF documentation Installation of
#   ctx: libvorbis Install libvorbis by running the following commands:
./configure --prefix=/usr --disable-static &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make -j1 check. Now, as the root user:
make install &&
install -v -m644 doc/Vorbis* /usr/share/doc/libvorbis-1.3.7


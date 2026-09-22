#!/bin/bash
# HAND-MAINTAINED recipe, shared (no book release in its path) -- one package carved
# out of a GROUPED BLFS page.
# source : x/x7lib.html (libXt section), read against both 13.0 and 13.1
#
# Why this cannot be book(). x/x7lib.html builds a whole set of packages in one
# `for` loop over an md5 list, with its own wget, `as_root` and `bash -e`. There is no
# per-package command block on that page to extract, so an extractor pointed at it
# returns the bulk loop for every package on the page. Proven on 2026-09-21: these four
# steps were converted hand() -> book() and re-extracted, and the generated
# blfs-libxt.sh came back as the full 32-library x7lib loop -- downloading and building
# all of libX11, libXext, libpciaccess and the rest under a step named for libXt. The
# generated files were discarded and packages.py put back to hand().
#
# Why it lives in shared recipes/ and not a release directory. Nothing here names a
# version: `./configure $XORG_CONFIG && make && make install` is correct for any release
# whose grouped page still builds this package this way, and libXt/libXmu/xauth and the
# libinput driver are all at the same versions in 13.0 and 13.1. It was moved here from
# recipes/blfs-13.0/ on 2026-09-21; db416ba's per-release split had swept it into that
# directory, which is where hand() does NOT look, so the step could not resolve a recipe
# at all and extract-blfs.py refused to write a plan.
#
# Original rationale, preserved:
# Built 2026-08-26 -- libXmu dependency (see blfs-libxmu.sh), itself
# needed for xauth (see blfs-xauth.sh), needed for startx to work at all.
#
set -e

./configure $XORG_CONFIG
make
make install

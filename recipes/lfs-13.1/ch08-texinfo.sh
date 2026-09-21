#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.1-systemd book.
# source : book/13.1/chapter08/texinfo.html
# title  : 8.73 Texinfo-7.3
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Texinfo package contains programs for reading, writing, and converting info pages.
#   ctx: Approximate build time: 0.4 SBU Required disk space: 151 MB 8.73.1 Installation of
#   ctx: Texinfo Prepare Texinfo for compilation:
./configure --prefix=/usr

# --- block 1 --------------------------------------------------
#   ctx: Compile the package:
make

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue:
#   TAGS: testsuite   [DISABLED - review]
# make check

# --- block 3 --------------------------------------------------
#   ctx: Install the package:
make install

# --- block 4 --------------------------------------------------
#   ctx: Optionally, install the components belonging in a TeX installation:
make TEXMF=/usr/share/texmf install-tex

# --- block 5 --------------------------------------------------
#   ctx: fo documentation system uses a plain text file to hold its list of menu entries. The
#   ctx: file is located at /usr/share/info/dir. Unfortunately, due to occasional problems in the
#   ctx: Makefiles of various packages, it can sometimes get out of sync with the info pages
#   ctx: installed on the system. If the /usr/share/info/dir file ever needs to be recreated, the
#   ctx: following optional commands will accomplish the task:
pushd /usr/share/info
  rm -v dir
  for f in *
    do install-info $f dir 2>/dev/null
  done
popd


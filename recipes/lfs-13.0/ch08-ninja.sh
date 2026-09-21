#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/ninja.html
# title  : 8.58. Ninja-1.13.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: will limit ninja to four parallel processes. If desired, make ninja recognize the
#   ctx: environment variable NINJAJOBS by running the stream editor:
sed -i '/int Guess/a \
  int   j = 0;\
  char* jobs = getenv( "NINJAJOBS" );\
  if ( jobs != NULL ) j = atoi( jobs );\
  if ( j > 0 ) return j;\
' src/ninja.cc

# --- block 1 --------------------------------------------------
#   ctx: Build Ninja with:
python3 configure.py --bootstrap --verbose

# --- block 2 --------------------------------------------------
#   ctx: eaning of the build option: --bootstrap This parameter forces Ninja to rebuild itself
#   ctx: for the current system. --verbose This parameter makes configure.py show the progress
#   ctx: building Ninja. The package tests cannot run in the chroot environment. They require
#   ctx: cmake. But the basic function of this package is already tested by rebuilding itself
#   ctx: (with the --bootstrap option) anyway. Install the package:
install -vm755 ninja /usr/bin/
install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
install -vDm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja


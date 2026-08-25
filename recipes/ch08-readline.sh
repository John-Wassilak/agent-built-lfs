#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/readline.html
# title  : 8.12. Readline-8.3
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: raries that offer command-line editing and history capabilities. Approximate build time:
#   ctx: less than 0.1 SBU Required disk space: 17 MB 8.12.1. Installation of Readline
#   ctx: Reinstalling Readline will cause the old libraries to be moved to <libraryname>.old.
#   ctx: While this is normally not a problem, in some cases it can trigger a linking bug in
#   ctx: ldconfig. This can be avoided by issuing the following two seds:
sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install

# --- block 1 --------------------------------------------------
#   ctx: Prevent hard coding library search paths (rpath) into the shared libraries. This package
#   ctx: does not need rpath for an installation into the standard location, and rpath may
#   ctx: sometimes cause unwanted effects or even security issues:
sed -i 's/-Wl,-rpath,[^ ]*//' support/shobj-conf

# --- block 2 --------------------------------------------------
#   ctx: Fix a problem identified upstream specifically for this version of readline:
sed -e '270a\
     else\
       chars_avail = 1;'      \
    -e '288i\   result = -1;' \
    -i.orig input.c

# --- block 3 --------------------------------------------------
#   ctx: Prepare Readline for compilation:
./configure --prefix=/usr    \
            --disable-static \
            --with-curses    \
            --docdir=/usr/share/doc/readline-8.3

# --- block 4 --------------------------------------------------
#   ctx: The meaning of the new configure option: --with-curses This option tells Readline that
#   ctx: it can find the termcap library functions in the curses library, not a separate termcap
#   ctx: library. This will generate the correct readline.pc file. Compile the package:
make SHLIB_LIBS="-lncursesw"

# --- block 5 --------------------------------------------------
#   ctx: The meaning of the make option: SHLIB_LIBS="-lncursesw" This option forces Readline to
#   ctx: link against the libncursesw library. For details see the “Shared Libraries” section in
#   ctx: the package's README file. This package does not come with a test suite. Install the
#   ctx: package:
make install

# --- block 6 --------------------------------------------------
#   ctx: If desired, install the documentation:
install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-8.3


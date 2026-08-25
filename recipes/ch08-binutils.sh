#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/binutils.html
# title  : 8.21. Binutils-2.46.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Binutils package contains a linker, an assembler, and other tools for handling
#   ctx: object files. Approximate build time: 1.7 SBU Required disk space: 835 MB 8.21.1.
#   ctx: Installation of Binutils The Binutils documentation recommends building Binutils in a
#   ctx: dedicated build directory:
mkdir -v build
cd       build

# --- block 1 --------------------------------------------------
#   ctx: Prepare Binutils for compilation:
../configure --prefix=/usr       \
             --sysconfdir=/etc   \
             --enable-ld=default \
             --enable-plugins    \
             --enable-shared     \
             --disable-werror    \
             --enable-64-bit-bfd \
             --enable-new-dtags  \
             --with-system-zlib  \
             --enable-default-hash-style=gnu

# --- block 2 --------------------------------------------------
#   ctx: The meaning of the new configure parameters: --enable-ld=default Build the original bfd
#   ctx: linker and install it as both ld (the default linker) and ld.bfd. --enable-plugins
#   ctx: Enables plugin support for the linker. --with-system-zlib Use the installed zlib library
#   ctx: instead of building the included version. Compile the package:
make tooldir=/usr

# --- block 3 --------------------------------------------------
#   ctx: stem, this target-specific directory in /usr is not required.
#   ctx: $(exec_prefix)/$(target_alias) would be used if the system were used to cross-compile
#   ctx: (for example, compiling a package on an Intel machine that generates code that can be
#   ctx: executed on PowerPC machines). Important The test suite for Binutils in this section is
#   ctx: considered critical. Do not skip it under any circumstances. Test the results:
set +e
make -k check
__rc=$?
set -e
echo "### TESTSUITE ch08-binutils block 3 exit=$__rc (non-fatal, compare against book)"

# --- block 4 --------------------------------------------------
#   ctx: For a list of failed tests, run:
grep -h "^FAIL:" $(find -name "*.log") || echo "### no FAIL lines in binutils test logs"

# --- block 5 --------------------------------------------------
#   ctx: One test related to gprofng is known to fail. Install the package:
make tooldir=/usr install

# --- block 6 --------------------------------------------------
#   ctx: Remove useless static libraries and other files:
rm -rfv /usr/lib/lib{bfd,ctf,ctf-nobfd,gprofng,opcodes,sframe}.a \
        /usr/share/doc/gprofng/


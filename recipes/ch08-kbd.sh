#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/kbd.html
# title  : 8.69. Kbd-2.9.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Kbd package contains key-table files, console fonts, and keyboard utilities.
#   ctx: Approximate build time: 0.1 SBU Required disk space: 37 MB 8.69.1. Installation of Kbd
#   ctx: The behavior of the backspace and delete keys is not consistent across the keymaps in
#   ctx: the Kbd package. The following patch fixes this issue for i386 keymaps:
patch -Np1 -i ../kbd-2.9.0-backspace-1.patch

# --- block 1 --------------------------------------------------
#   ctx: After patching, the backspace key generates the character with code 127, and the delete
#   ctx: key generates a well-known escape sequence. Remove the redundant resizecons program (it
#   ctx: requires the defunct svgalib to provide the video mode files - for normal use setfont
#   ctx: sizes the console appropriately) together with its manpage.
sed -i '/RESIZECONS_PROGS=/s/yes/no/' configure
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in

# --- block 2 --------------------------------------------------
#   ctx: Prepare Kbd for compilation:
./configure --prefix=/usr --disable-vlock

# --- block 3 --------------------------------------------------
#   ctx: The meaning of the configure option: --disable-vlock This option prevents the vlock
#   ctx: utility from being built because it requires the PAM library, which isn't available in
#   ctx: the chroot environment. Compile the package:
make

# --- block 4 --------------------------------------------------
#   ctx: To test the results, issue:
#   TAGS: testsuite   [DISABLED - review]
# make check

# --- block 5 --------------------------------------------------
#   ctx: Install the package:
make install

# --- block 6 --------------------------------------------------
#   ctx: Note For some languages (e.g., Belarusian) the Kbd package doesn't provide a useful
#   ctx: keymap where the stock “by” keymap assumes the ISO-8859-5 encoding, and the CP1251
#   ctx: keymap is normally used. Users of such languages have to download working keymaps
#   ctx: separately. If desired, install the documentation:
cp -R -v docs/doc -T /usr/share/doc/kbd-2.9.0


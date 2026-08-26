#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in this BLFS mirror. Required by libXfont2 below (found the same way -- xwayland's meson.build hard-requires 'xfont2' with no book documentation of the chain). Arch's official libfontenc PKGBUILD as reference. Its own runtime dependency, xorg-fonts-encodings (encoding data tables), skipped: a data-only package needed for actually rendering legacy X11 core fonts at runtime, not for linking against the library, and this system has no legacy Xorg-Server installed to use them -- one-level policy, out of scope.
set -e

./configure --prefix=/usr --sysconfdir=/etc \
      --localstatedir=/var --disable-static \
      --with-encodingsdir=/usr/share/fonts/encodings &&
make
make install


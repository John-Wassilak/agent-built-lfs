#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in this BLFS mirror. Required (hard) alongside libice above by pulseaudio's meson.build as 'sm', same undocumented-chain discovery. Arch's official libsm PKGBUILD as reference -- needs libice (previous step), util-linux (already built in LFS ch8), xorgproto.
set -e

./configure $XORG_CONFIG --sysconfdir=/etc
make
make install


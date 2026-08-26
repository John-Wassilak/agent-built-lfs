#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in this BLFS mirror. Required (hard) by pulseaudio's meson.build as 'ice' -- discovered via a real configure failure, not mentioned in pulseaudio's book page beyond the generic 'Xorg Libraries' Recommended entry. Arch's official libice PKGBUILD as reference -- needs xtrans, xorgproto (both already built).
set -e

./configure $XORG_CONFIG --sysconfdir=/etc
make
make install


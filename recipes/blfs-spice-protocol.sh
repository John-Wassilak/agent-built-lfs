#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS/SLFS/GLFS 13.1 page for spice-protocol.
# source: spice-space.org/download/releases, spice-protocol-0.14.5.tar.xz, sha256
# baf58449f6e89d19f475899ad5fb9196fdc46c03cc53233f4e39cf2978f9cff7 (the release's own
# .sha256sum). Arch carries it in [extra].
#
# rationale: headers only, no library. qemu's meson finds them through pkg-config
# (>= 0.14.3, feature 'spice_protocol', auto) and then builds ui/vdagent.c, the
# qemu-vdagent chardev. That chardev speaks the spice agent protocol to spice-vdagent
# in a guest, so the clipboard of a viewer on qemu's own VNC server reaches the guest
# without the spice server. Added 2026-10-27 for server's Kali guest (packages.py
# seq 272.5, ahead of qemu so a fresh build gets it).
#
# Plain meson, nothing to configure: the only output is /usr/include/spice-1 and
# spice-protocol.pc, which goes to /usr/share/pkgconfig because it is arch-independent.
set -e

mkdir build
cd    build

meson setup --prefix=/usr --buildtype=release ..
ninja

ninja install

#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/multimedia/pulseaudio.html
# title  : PulseAudio-17.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: TC AudioProcessing Installation of PulseAudio Note If you intend to use pipewire-1.6.8
#   ctx: as the sound system instead of PulseAudio, you can pass the -D daemon=false option to
#   ctx: only build the support libraries of this package. If so, those libraries will require
#   ctx: Wireplumber-0.5.15 installed and pipewire-pulse.socket enabled to be really functional.
#   ctx: Install PulseAudio by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr       \
            --buildtype=release \
            -D database=gdbm    \
            -D doxygen=false    \
            -D bluez5=disabled  \
            -D man=false        \
            -D tests=false      \
            ..                  &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. Only the shipped XML files are validated because
#   ctx: other tests need Check that we've removed from LFS. Now, as the root user:
ninja install

# --- block 2 --------------------------------------------------
#   ctx: Running PulseAudio as a system-wide daemon is possible but not recommended. See
#   ctx: https://www.freedesktop.org/wiki/Software/PulseAudio/Documentation/User/SystemWide/ for
#   ctx: more information. While still as the root user, remove the D-Bus configuration file for
#   ctx: the system wide daemon to avoid creating unnecessary system users and groups:
rm /usr/share/dbus-1/system.d/pulseaudio-system.conf


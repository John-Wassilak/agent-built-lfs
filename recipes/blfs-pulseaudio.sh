#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/multimedia/pulseaudio.html
# title  : PulseAudio-17.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: , GLib-2.86.4, Speex-1.2.1 and Xorg Libraries Optional Avahi-0.8, BlueZ-5.86,
#   ctx: Doxygen-1.16.1 (for documentation), fftw-3.3.10, gst-plugins-base-1.28.1, GTK-3.24.51,
#   ctx: libsamplerate-0.2.2, SBC-2.2 (Bluetooth support), Valgrind-3.26.0, check (for testing),
#   ctx: JACK, libasyncns, LIRC, ORC, soxr, TDB, and WebRTC AudioProcessing Installation of
#   ctx: PulseAudio Install PulseAudio by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr       \
            --buildtype=release \
            -D database=gdbm    \
            -D doxygen=false    \
            -D bluez5=disabled  \
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


#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/upower.html
# title  : UPower-1.91.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Installation of UPower Install UPower by running the following commands:
mkdir build               &&
cd    build               &&

meson setup ..            \
      --prefix=/usr       \
      --buildtype=release \
      -D gtk-doc=false    \
      -D man=false        &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: the results, issue: LC_ALL=C ninja test. The test suite should be run from a local GUI
#   ctx: session started with dbus-launch. On 32-bit machines, one test will fail due to rounding
#   ctx: errors: Tests.test_battery_energy_charge_mixed. On some systems, two tests relating to
#   ctx: the headphone hotplug feature are known to fail. Those can be safely ignored since the
#   ctx: functionality still works. Now, as the root user:
ninja install


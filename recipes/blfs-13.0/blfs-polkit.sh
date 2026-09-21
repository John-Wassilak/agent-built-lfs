#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/postlfs/polkit.html
# title  : Polkit-127
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Installation of Polkit There should be a dedicated user and group to take control of the
#   ctx: polkitd daemon after it is started. Issue the following commands as the root user:
groupadd -fg 27 polkitd &&
id polkitd >/dev/null 2>&1 || useradd -c "PolicyKit Daemon Owner" -d /etc/polkit-1 -u 27 \
        -g polkitd -s /bin/false polkitd

# --- block 1 --------------------------------------------------
#   ctx: Install Polkit by running the following commands:
mkdir build &&
cd    build &&

meson setup ..                   \
      --prefix=/usr              \
      --buildtype=release        \
      -D man=false               \
      -D session_tracking=logind \
      -D authfw=shadow           \
      -D introspection=false     \
      -D tests=false

# --- block 2 --------------------------------------------------
#   ctx: Build the package:
ninja

# --- block 3 --------------------------------------------------
#   ctx: To test the results, first ensure that the system D-Bus daemon is running, and both
#   ctx: D-Bus Python-1.4.0 and dbusmock-0.38.1 are installed. Then run ninja test. Now, as the
#   ctx: root user:
ninja install


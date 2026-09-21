#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/gnome/gnome-keyring.html
# title  : gnome-keyring-48.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: d19a99eadeb5d92774b7960c51d1c5dc Download size: 752 KB Estimated disk space required:
#   ctx: 44 MB Estimated build time: 0.2 SBU (Using parallelism=4; add 0.2 SBU for tests) GNOME
#   ctx: Keyring Dependencies Required dbus-1.16.2 and Gcr-3.41.2 Recommended Linux-PAM-1.7.2,
#   ctx: libxslt-1.1.45, and OpenSSH-10.2p1 Optional libcap-ng Installation of GNOME Keyring
#   ctx: Install GNOME Keyring by running the following commands:
sed -i 's:"/desktop:"/org:' schema/*.xml &&

mkdir build-gkr &&
cd    build-gkr &&

meson setup --prefix=/usr --buildtype=release -D pam=false -D manpage=false .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: A session bus address is necessary to run the tests. To test the results, issue: ninja
#   ctx: test. Now, as the root user:
ninja install


#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.1-systemd book.
# source : book/13.1/chapter08/systemd.html
# title  : 8.77 Systemd-261.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The systemd package contains programs for controlling the startup, running, and shutdown
#   ctx: of the system. Approximate build time: 1.2 SBU Required disk space: 396 MB 8.77.1
#   ctx: Installation of systemd Remove two unneeded groups, render and sgx, from the default
#   ctx: udev rules:
sed -e 's/GROUP="render"/GROUP="video"/' \
    -e 's/GROUP="sgx", //'               \
    -i rules.d/50-udev-default.rules.in

# --- block 1 --------------------------------------------------
#   ctx: Prepare systemd for compilation:
mkdir -p build
cd       build

meson setup ..                \
      --prefix=/usr           \
      --buildtype=release     \
      -D default-dnssec=no    \
      -D firstboot=false      \
      -D install-tests=false  \
      -D ldconfig=false       \
      -D sysusers=false       \
      -D rpmmacrosdir=no      \
      -D homed=disabled       \
      -D man=disabled         \
      -D mode=release         \
      -D pamconfdir=no        \
      -D dev-kvm-mode=0660    \
      -D nobody-group=nogroup \
      -D sysupdate=disabled   \
      -D ukify=disabled       \
      -D docdir=/usr/share/doc/systemd-261.2

# --- block 2 --------------------------------------------------
#   ctx: ll the systemd-sysupdate tool. It's designed for automatically upgrading binary distros,
#   ctx: so it's useless for a basic Linux system built from source. And it will report errors on
#   ctx: boot if it's enabled but not properly configured. -D ukify=disabled Do not install the
#   ctx: systemd-ukify script. At runtime this script requires the pefile Python module that
#   ctx: neither LFS nor BLFS provides. Compile the package:
ninja

# --- block 3 --------------------------------------------------
#   ctx: One test creates a mount point in /tmp that we cannot clean up so easily after running
#   ctx: the test suite, and some tests need a basic /etc/os-release file. To test the results,
#   ctx: create this file and run the test suite in a separate mount namespace (so the mount
#   ctx: point is only visible for the test suite and it gets cleaned up automatically after the
#   ctx: test suite finishes):
echo 'NAME="Linux From Scratch"' > /etc/os-release

# --- block 4 --------------------------------------------------
#   ctx: ll installation: core - systemd:test-namespace, test - systemd:test-chase, and tmpfiles
#   ctx: - systemd:test-systemd-tmpfiles. Some additional tests may fail because they depend on
#   ctx: various kernel configuration options. The test named test - systemd:test-copy may time
#   ctx: out due to I/O congestion with a large parallel job number, but will pass if running
#   ctx: alone with meson test test-copy. Install the package:
ninja install

# --- block 5 --------------------------------------------------
#   ctx: Install the man pages:
tar -xf ../../systemd-man-pages-261.2.tar.xz \
    --no-same-owner --strip-components=1     \
    -C /usr/share/man

# --- block 6 --------------------------------------------------
#   ctx: Create the /etc/machine-id file needed by systemd-journald:
systemd-machine-id-setup

# --- block 7 --------------------------------------------------
#   ctx: Set up the basic target structure:
systemctl preset-all


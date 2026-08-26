#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS -- no dedicated wireguard-tools chapter in this
# book mirror. Upstream source (git.zx2c4.com), matching the current
# version Arch's official `wireguard-tools` package ships (1.0.20260223,
# confirmed against archlinux.org rather than assumed). The kernel module
# itself (CONFIG_WIREGUARD) has been in-tree since Linux 5.6 -- this
# package is only the userspace wg/wg-quick CLI. Batched with the other
# pending kernel config additions (CONFIG_DRM_NOUVEAU, cryptsetup's crypto
# options) for one kernel rebuild rather than done piecemeal.
set -e

make -C src PREFIX=/usr
make -C src PREFIX=/usr install

echo "### version"
wg --version 2>&1 || true

#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: USB boot test (2026-09-02, see BUILD-REPORT.md) found 15x 'iwlwifi
# 0000:04:00.0: Direct firmware load for iwlwifi-8000C-*.ucode failed with error -2' then
# 'no suitable firmware found!' on every boot -- the Intel Wireless 8260 (host.toml's
# [hardware] wifi note already flagged this need, but no step was ever added). BLFS's
# 'About Firmware' page (postlfs/firmware.html) points at the LFS Project's own mirror.
# Fetches the one ucode this chip needs (-36, the newest version the driver itself tried
# first) rather than the whole linux-firmware tree, same policy as server's
# hand(172, "linux-firmware-rtl-nic", ...).
set -e

# Same DNS fix as every other live-fetch recipe in this build (blfs-rust, blfs-go,
# blfs-tailscale, blfs-claude-code) -- chroot has no working /etc/resolv.conf otherwise.
_restore_resolv() {
    rm -f /etc/resolv.conf
    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
}
trap _restore_resolv EXIT
rm -f /etc/resolv.conf
printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf

install -vdm755 /usr/lib/firmware
curl -fsSL --retry 5 --retry-delay 3 -o /usr/lib/firmware/iwlwifi-8000C-36.ucode \
    https://anduin.linuxfromscratch.org/BLFS/linux-firmware/intel/iwlwifi/iwlwifi-8000C-36.ucode

echo "### installed:"
ls -l /usr/lib/firmware/iwlwifi-8000C-36.ucode

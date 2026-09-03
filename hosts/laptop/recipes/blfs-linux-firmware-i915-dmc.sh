#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: USB boot test (2026-09-02, see BUILD-REPORT.md) found 'i915 0000:00:02.0:
# Direct firmware load for i915/skl_dmc_ver1_27.bin failed with error -ENOENT' and
# '[drm] Failed to load DMC firmware ... Disabling runtime power management.' Cosmetic
# (display still works without it -- only the low-power DMC states are lost), but cheap
# to fix from the same LFS Project mirror BLFS's postlfs/firmware.html points at. Fetches
# just this one blob, not the whole linux-firmware tree, same policy as server's
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

install -vdm755 /usr/lib/firmware/i915
curl -fsSL --retry 5 --retry-delay 3 -o /usr/lib/firmware/i915/skl_dmc_ver1_27.bin \
    https://anduin.linuxfromscratch.org/BLFS/linux-firmware/i915/skl_dmc_ver1_27.bin

echo "### installed:"
ls -l /usr/lib/firmware/i915/skl_dmc_ver1_27.bin

#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Baseline hardware audit (2026-08-25) found 'r8169 0000:06:00.0: Unable to load firmware rtl_nic/rtl8168e-3.fw (-2)' on every boot -- this is the machine's only network interface. BLFS's 'About Firmware' page confirms the driver works without it but says to install it once dmesg flags it missing. Fetches the one blob this NIC needs from the LFS project's official mirror, not the full linux-firmware tree (multi-GB, and the rest of it fixes hardware this box does not have).
set -e

# DNS fix added 2026-09-09 (fresh chroot build): this chroot has no working
# /etc/resolv.conf by default, same class of issue as blfs-rust/blfs-attrs/blfs-
# claude-code and others.
_restore_resolv() {
    rm -f /etc/resolv.conf
    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
}
trap _restore_resolv EXIT
rm -f /etc/resolv.conf
printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf

install -vdm755 /usr/lib/firmware/rtl_nic
curl -fsSL --retry 5 --retry-delay 3 -o /usr/lib/firmware/rtl_nic/rtl8168e-3.fw \
    https://anduin.linuxfromscratch.org/BLFS/linux-firmware/rtl_nic/rtl8168e-3.fw

echo "### installed:"
ls -l /usr/lib/firmware/rtl_nic/rtl8168e-3.fw


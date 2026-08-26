#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Baseline hardware audit (2026-08-25) found 'r8169 0000:06:00.0: Unable to load firmware rtl_nic/rtl8168e-3.fw (-2)' on every boot -- this is the machine's only network interface. BLFS's 'About Firmware' page confirms the driver works without it but says to install it once dmesg flags it missing. Fetches the one blob this NIC needs from the LFS project's official mirror, not the full linux-firmware tree (multi-GB, and the rest of it fixes hardware this box does not have).
set -e

install -vdm755 /usr/lib/firmware/rtl_nic
curl -fsSL --retry 5 --retry-delay 3 -o /usr/lib/firmware/rtl_nic/rtl8168e-3.fw \
    https://anduin.linuxfromscratch.org/BLFS/linux-firmware/rtl_nic/rtl8168e-3.fw

echo "### installed:"
ls -l /usr/lib/firmware/rtl_nic/rtl8168e-3.fw


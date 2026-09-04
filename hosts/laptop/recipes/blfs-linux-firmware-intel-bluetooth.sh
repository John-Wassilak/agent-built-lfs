#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
#
# rationale: the 2026-09-04 kernel work gave this machine a working Bluetooth
# *driver* and no working Bluetooth *adapter*. After the reboot into the
# CONFIG_BT kernel, btusb bound the device and hci0 appeared in
# /sys/class/bluetooth and in `rfkill list` (soft- and hard-unblocked), and
# bluetooth.service went active -- but `bluetoothctl list` and `bluetoothctl show`
# both returned nothing at all. dmesg says why:
#
#   Bluetooth: hci0: Bootloader revision 0.0 build 2 week 52 2014
#   Bluetooth: hci0: Device revision is 5
#   Bluetooth: hci0: Failed to load Intel firmware file intel/ibt-11-5.sfi (-2)
#   Bluetooth: hci0: Reading supported features failed (-56)
#
# -2 is ENOENT: the blob simply is not on disk. This is the Intel 8260 combo chip
# (8087:0a2b, the Bluetooth half of the same part IWLWIFI covers for WiFi), which
# is a "bootloader" generation device -- btintel reads its bootloader/device
# revision and then loads a matching operational firmware image by name. Nothing
# in the kernel config can substitute for it, so the Bluetooth kernel work was
# necessary but not sufficient.
#
# Two files, both fetched:
#   ibt-11-5.sfi  the operational firmware itself -- this is the one whose absence
#                 produced the error above. The 11-5 stem is not a guess: it is
#                 what the driver asked for by name in dmesg.
#   ibt-11-5.ddc  the matching device configuration. btintel loads it right after
#                 the .sfi and treats its absence as non-fatal (it logs and
#                 continues on defaults), so this is not strictly required -- but
#                 it carries the per-part tuning parameters, it is a few hundred
#                 bytes, and fetching only half a matched pair to save nothing is
#                 a bad trade.
#
# Source is BLFS's own "About Firmware" page (postlfs/firmware.html) pointing at
# the LFS Project's mirror -- the same base URL the two existing firmware steps on
# this host already use, confirmed to serve both files (HTTP 200) before this was
# written. Fetches only what this chip needs rather than the whole linux-firmware
# tree, matching hand(189, "linux-firmware-iwlwifi-8260", ...) and
# hand(190, "linux-firmware-i915-dmc", ...).
#
# Host-specific, not shared: names one exact chip generation on one machine.
#
# NOTE, deliberately different from this host's other two firmware recipes: there
# is no /etc/resolv.conf rewrite here. Those recipes were written to run inside the
# chroot, where /etc/resolv.conf is absent, and their exit trap ends with
#   ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
# On this machine running natively that would *replace a working regular
# /etc/resolv.conf* (nameserver 1.1.1.1 / 8.8.8.8) with a symlink -- an
# unrequested change to the live host's network config as a side effect of
# installing a firmware blob. DNS resolves fine natively, so the whole block is
# simply omitted. If this step is ever run in a chroot instead, the block from
# blfs-linux-firmware-iwlwifi-8260.sh is what to add back.
set -e

BASE=https://anduin.linuxfromscratch.org/BLFS/linux-firmware/intel

install -vdm755 /usr/lib/firmware/intel

for f in ibt-11-5.sfi ibt-11-5.ddc; do
    curl -fsSL --retry 5 --retry-delay 3 -o "/usr/lib/firmware/intel/$f" "$BASE/$f"
done

echo "### installed:"
ls -l /usr/lib/firmware/intel/ibt-11-5.sfi /usr/lib/firmware/intel/ibt-11-5.ddc

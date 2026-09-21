#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter09/symlinks.html
# title  : 9.4. Managing Devices
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: be found in BLFS. For each of your devices that is likely to have this problem (even if
#   ctx: the problem doesn't exist in your current Linux distribution), find the corresponding
#   ctx: directory under /sys/class or /sys/block. For video devices, this may be
#   ctx: /sys/class/video4linux/videoX. Figure out the attributes that identify the device
#   ctx: uniquely (usually, vendor and product IDs and/or serial numbers work):
#   REVIEWED [drop]: Exploratory command the book offers so a human can inspect a video device's udev attributes ('Figure out the attributes that identify the device uniquely'). This machine has no /sys/class/video4linux/video0, so udevadm exits non-zero and aborts the step.
# udevadm info -a -p /sys/class/video4linux/video0

# --- block 1 --------------------------------------------------
#   ctx: Then write rules that create the symlinks, e.g.:
#   REVIEWED [drop]: Book's example udev rules ('Then write rules that create the symlinks, e.g.') hard-coded to a specific webcam (idProduct 1910, idVendor 0d81) and TV tuner. Installing them would create rules for hardware that does not exist. Section 9.4 is optional guidance for systems with duplicate device classes.
# cat > /etc/udev/rules.d/83-duplicate_devs.rules << "EOF"
# 
# # Persistent symlinks for webcam and tuner
# KERNEL=="video*", ATTRS{idProduct}=="1910", ATTRS{idVendor}=="0d81", SYMLINK+="webcam"
# KERNEL=="video*", ATTRS{device}=="0x036f",  ATTRS{vendor}=="0x109e", SYMLINK+="tvtuner"
# 
# EOF


#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# agent-built-lfs -- kernel configuration for `laptop`
# Copyright (C) 2026 John Wassilak
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program.  If not, see <https://www.gnu.org/licenses/>.

# Kernel configuration for `laptop`. NOT COMPLETE -- see the TODOs below.
#
# Runs inside the chroot, from the kernel source directory, via the ch10-kernel recipe.
# Stage this file AND bin/kernel-config-base.sh into the same directory (/sources): the
# source line below is relative to this script, not to the repo.
#
# The base covers everything the book requires plus the generic x86_64 boot path
# (SCSI/SD/ATA/AHCI/NVMe/ext4 and every USB HCD), netfilter, cryptsetup, WireGuard, TUN,
# the schedutil governor, and the gates. Do not copy those here.
#
# What this file must add, from the audit in BOOTSTRAP.md:
#
#   1. The storage controller this machine actually boots from, as =y. The base covers
#      the common cases, but a machine whose root is behind a controller not in that
#      list will build a kernel that cannot find its own root filesystem -- and LFS has
#      no initramfs to paper over it. `lspci -k` on the live distro names the driver;
#      add it as --enable and add it to EXTRA_GATE_BUILTIN so the gate catches a
#      regression rather than a failed boot.
#   2. The GPU's DRM driver (i915/xe for Intel, amdgpu for AMD, nouveau for NVIDIA).
#      Match it to what hosts/laptop/packages.py builds mesa against.
#   3. The audio codec drivers this board has. server needs REALTEK + HDMI; check
#      /proc/asound/cards and `lspci -k` for audio here rather than assuming.
#   4. Laptop hardware server has none of: ACPI battery/AC, lid switch, backlight,
#      thermal, the touchpad's input driver, and the wireless driver (which will also
#      need firmware LFS does not install -- that is a separate BLFS step, not a
#      kernel option).
set -e

# The one guard between this stub and a kernel that cannot find its own root filesystem.
# Delete these two lines once TODOs 1-4 below are done.
echo "hosts/laptop/kernel-config.sh is a stub -- work through TODOs 1-4 first" >&2
exit 1

source "$(dirname "$0")/kernel-config-base.sh"

kernel_config_start
kernel_config_shared

# --- storage boot path (TODO 1) --------------------------------------------
# EXTRA_GATE_BUILTIN names options the gate must see as =y, on top of the base list.
# export EXTRA_GATE_BUILTIN="NVME_CORE BLK_DEV_NVME"

# --- GPU (TODO 2) ----------------------------------------------------------
# $K --module DRM_I915

# --- audio (TODO 3) --------------------------------------------------------
# $K --module SND_HDA_CODEC_REALTEK

# --- laptop hardware (TODO 4) ---------------------------------------------
# $K --enable ACPI_BATTERY
# $K --enable ACPI_AC
# $K --enable ACPI_BUTTON
# $K --enable BACKLIGHT_CLASS_DEVICE
# $K --module MOUSE_PS2_SYNAPTICS

kernel_config_finish

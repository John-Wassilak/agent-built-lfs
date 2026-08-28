#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# agent-built-lfs -- kernel configuration for `server`
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

# Kernel configuration for `server`: i5-2500K / P67-era board / GTX 770 (GK104, Kepler).
#
# Runs inside the chroot, from the kernel source directory, via the ch10-kernel recipe's
# host override (`bash /sources/kernel-config.sh`). Stage this file AND
# bin/kernel-config-base.sh into the same directory -- the source line below is relative
# to this script, not to the repo.
#
# Everything generic lives in the base: the book's required options, the block/SATA/NVMe
# boot path, USB, netfilter, cryptsetup, WireGuard, the schedutil default, and the gates.
# Only this machine's hardware is below.
set -e

source "$(dirname "$0")/kernel-config-base.sh"

kernel_config_start
kernel_config_shared

# --- GPU: nouveau (added 2026-08-26) ---------------------------------------
# This GPU (GK104/GTX 770, Kepler) had no driver bound at all -- `make defconfig`
# doesn't enable it. Needed for the Hyprland stack's
# OpenGL acceleration (Mesa already built with gallium-drivers=nouveau).
$K --module  DRM_NOUVEAU

# --- added 2026-08-26: HDA audio codec drivers ---
# Necessary but NOT sufficient on its own for "no audio hardware at all"
# (both HDA controllers logging "Cannot probe codecs, giving up"): every
# codec driver was unset in the running kernel's own .config (confirmed
# directly), so even a codec the controller *did* detect would have had
# nothing to bind to. REALTEK for the onboard Intel PCH codec, HDMI for
# the GK104's own HDMI/DP audio, GENERIC as a fallback.
#
# The other half of the real fix is NOT here -- it's a boot parameter,
# not a compile option: "Cannot probe codecs, giving up" is printed by
# the *controller's* own bus-level codec-presence scan, before any codec
# driver is even relevant. Root cause (per the kernel's own HD-audio
# docs): the BIOS misreports which codec slots exist. Fixed with
# `snd_hda_intel.probe_mask=0x1FF,0x1FF` on the kernel command line in
# grub.cfg -- force-probes slots 0-7 on both controllers regardless of
# what the BIOS claims. Confirmed working: the GK104's HDMI codec now
# shows up in /proc/asound/cards with a real playback PCM device. The
# onboard codec still doesn't respond on any forced slot -- looks like
# genuinely dead/BIOS-disabled hardware, not a software gap.
#
# Whoever regenerates grub.cfg next needs to re-add the probe_mask
# parameter by hand -- it doesn't come from this script or from
# CONFIG_CMDLINE, so nothing carries it forward automatically.
$K --module  SND_HDA_CODEC_REALTEK
$K --module  SND_HDA_CODEC_HDMI
$K --module  SND_HDA_GENERIC

kernel_config_finish

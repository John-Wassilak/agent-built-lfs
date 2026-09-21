#!/bin/bash
# SPDX-License-Identifier: MIT
# agent-built-lfs -- kernel configuration for `server`
# Copyright (c) 2026 John Wassilak

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

# --- deliberately NOT enabled, recorded 2026-09-21 (/lfs-audit) ------------
# Broadcom BCM4321 802.11b/g/n (Netgear WN311B, PCI 05:00.0, 14e4:4329). The
# only device on this machine's bus with no driver bound -- `lspci -k` shows
# no "Kernel driver in use" and no candidate module, because CONFIG_SSB and
# CONFIG_B43 are both unset (confirmed in /boot/config-7.1.8). Left that way
# on purpose, and written down here because BUILD-REPORT.md has now noticed it
# twice (2026-08-27 and this audit) without either time leaving a decision
# behind:
#   - the onboard Realtek r8169 is this machine's network, wired, and works;
#     nothing here needs wireless.
#   - b43 cannot associate on firmware alone -- it needs a blob cut out of
#     Broadcom's proprietary driver with b43-fwcutter, which is a new package
#     and a non-redistributable download.
#   - enabling it means a kernel rebuild, and a kernel rebuild orphans the
#     out-of-tree NVIDIA 470.xx modules until they are rebuilt against the new
#     /lib/modules/<ver>/ path. That has already caused one silent breakage on
#     this host.
# Three real costs against a card nothing uses. Enable CONFIG_SSB + CONFIG_B43
# here and add a b43-fwcutter hand() entry to packages.py if that ever changes.
#
# vmscape: /sys/devices/system/cpu/vulnerabilities/vmscape reads "Vulnerable"
# on this i5-2500K and there is nothing to set. Kernel 7.1.8 carries no
# CONFIG_MITIGATION_VMSCAPE symbol at all (grepped the whole config), and
# VMSCAPE is a guest-to-host attack: it needs the machine to be running VMs.
# `# CONFIG_KVM is not set` here -- only CONFIG_KVM_GUEST, which is the other
# direction -- so this host cannot host a guest and the attack has no surface.
# Microcode is current (0x2f; `old_microcode: Not affected`), unlike laptop's
# still-open finding. Revisit if KVM is ever enabled on this box.

kernel_config_finish

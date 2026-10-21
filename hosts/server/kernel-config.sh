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
# vmscape: superseded 2026-10-21 by the KVM section below. Before KVM, this note
# recorded /sys/devices/system/cpu/vulnerabilities/vmscape reading "Vulnerable"
# with no CONFIG_MITIGATION_VMSCAPE symbol in the config, and concluded that a
# host running no guests had no attack surface. The missing symbol had a simpler
# cause: arch/x86/Kconfig declares MITIGATION_VMSCAPE `depends on KVM`, so it
# cannot appear while KVM is unset. Microcode was current at the time (0x2f;
# `old_microcode: Not affected`), unlike laptop's still-open finding.

# xt_connmark / CONNMARK: absent, and tailscale asks for it on every start.
# Recorded 2026-09-22 (/lfs-audit). `journalctl -u tailscaled` carries ten lines
# per boot of:
#     router: warning: failed to add connmark rules (rp_filter workaround may
#     not work) ... Extension CONNMARK revision 0 not supported, missing kernel
#     module?  /  iptables v1.8.13 (legacy): unknown option "--nfmask"
# Confirmed against /boot/config-7.1.8: CONFIG_NETFILTER_XT_MATCH_CONNMARK,
# CONFIG_NETFILTER_XT_TARGET_CONNMARK, CONFIG_NETFILTER_XT_CONNMARK and
# CONFIG_NF_CONNTRACK_MARK do not appear at all -- not "is not set", absent,
# meaning the parent option was never turned on. So the warning is accurate and
# the rules genuinely are not installed.
#
# NOT enabled, for the same reason the Broadcom card above is not: it needs a
# kernel rebuild, and a kernel rebuild orphans the out-of-tree NVIDIA 470.xx
# modules until they are rebuilt against the new /lib/modules/<ver>/ path. What
# is actually lost is tailscale's reverse-path-filter workaround, which matters
# on a host that both forwards tailscale traffic and runs strict rp_filter. This
# box does neither: it is a leaf node on the tailnet, and its own firewall sets
# rp_filter=1 with FORWARD policy DROP and no forwarding rules. Tailscale itself
# works -- the interface is up, the peer address is assigned, and traffic flows.
#
# Enable all four here and rebuild the kernel (then nvidia-470xx) if this host
# ever becomes a tailscale exit node or subnet router, which is exactly when the
# workaround stops being cosmetic.

# --- KVM, added 2026-10-21 ---------------------------------------------------
# For a Windows 11 guest under qemu (packages.py seq 268-273), which the operator
# reaches from laptop over RDP on wg0. BLFS 13.1 postlfs/qemu.html asks for
# VIRTUALIZATION (already =y), KVM, and the vendor module. KVM_INTEL sits in this
# file, not the base, because it names a CPU vendor.
#
# CPU, from /proc/cpuinfo: vmx with ept, vpid, unrestricted_guest and flexpriority,
# which covers everything KVM needs for a modern guest. There is no VT-d: the
# 2500K is a K SKU, and /sys/firmware/acpi/tables has no DMAR. VFIO therefore stays
# unset, because with no IOMMU there is nothing it could pass through.
#
# KVM selects core options the running kernel lacks (PREEMPT_NOTIFIERS,
# USER_RETURN_NOTIFIER, X86_FRED via KVM_INTEL). Building it is therefore a
# full kernel rebuild and a reboot, which in turn means a blfs-nvidia-470xx
# rebuild.
#
# MITIGATION_VMSCAPE is `depends on KVM, default y` in arch/x86/Kconfig, so it
# appears once KVM is on. It is pinned here so that turning on KVM can never
# leave VMSCAPE unmitigated.
#
# Deliberately NOT enabled:
#   VHOST_NET -- in-kernel virtio-net backend for tap devices. The guest uses
#     -netdev user (libslirp), which is userspace and never touches vhost; RDP
#     traffic is far below where that matters.
#   BRIDGE / TUN -- already =m from the shared base (docker, tailscale), so the book's
#     bridge setup is available if a host ever wants it.
$K --module  KVM
$K --module  KVM_INTEL
$K --enable  MITIGATION_VMSCAPE

kernel_config_finish

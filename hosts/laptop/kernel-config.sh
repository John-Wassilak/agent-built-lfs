#!/bin/bash
# SPDX-License-Identifier: MIT
# agent-built-lfs -- kernel configuration for `laptop`
# Copyright (c) 2026 John Wassilak

# Kernel configuration for `laptop`. Filled in from the hardware audit in
# BUILD-REPORT.md (2026-08-28) -- see hosts/laptop/host.toml's [hardware] table for the
# facts this was built from.
#
# Runs inside the chroot, from the kernel source directory, via the ch10-kernel recipe.
# Stage this file AND bin/kernel-config-base.sh into the same directory (/sources): the
# source line below is relative to this script, not to the repo.
#
# The base covers everything the book requires plus the generic x86_64 boot path
# (SCSI/SD/ATA/AHCI/NVMe/ext4 and every USB HCD), netfilter, cryptsetup, WireGuard, TUN,
# the schedutil governor, and the gates. Do not copy those here.
set -e

source "$(dirname "$0")/kernel-config-base.sh"

kernel_config_start
kernel_config_shared

# --- storage boot path -------------------------------------------------------------
# This machine boots from NVMe, not SATA. BLK_DEV_NVME is already --enable'd by the
# shared base config, but the base's gate list only asserts EXT4_FS/BLK_DEV_SD/SCSI/
# ATA/SATA_AHCI/USB* as =y -- it never checks NVMe, because server boots from SATA.
# Without this, a regression that silently demoted BLK_DEV_NVME to =m would pass the
# gate clean and produce a kernel that cannot find its own root filesystem.
export EXTRA_GATE_BUILTIN="NVME_CORE BLK_DEV_NVME"

# --- GPU: Intel HD Graphics 520 (Skylake GT2) ---------------------------------------
# Not on the boot path (LFS boots to a console via SYSFB_SIMPLEFB from the base config,
# same as server) -- module is correct, matches server's nouveau precedent.
$K --module DRM_I915

# --- audio: Conexant CX20753/4 + Intel Skylake HDMI, both on snd_hda_intel/PCH -----
# Confirmed against /proc/asound/cards on the live host, not assumed -- this board is
# Conexant, not Realtek (server's stub guessed the more common Realtek by default).
$K --module SND_HDA_INTEL
$K --module SND_HDA_CODEC_CONEXANT
$K --module SND_HDA_CODEC_HDMI
# USB audio (dock passthrough, headset, C920 webcam mic) -- all three seen live.
$K --module SND_USB_AUDIO

# --- wireless: Intel Wireless 8260 --------------------------------------------------
# The driver; the iwlwifi-8260 firmware blobs themselves are a BLFS/linux-firmware
# step, not a kernel option -- without them the module loads but never associates.
$K --module IWLWIFI
$K --module IWLMVM

# --- wired ethernet: Intel I219-LM --------------------------------------------------
$K --module E1000E

# --- laptop hardware: battery, lid, backlight, ThinkPad hotkeys, touchpad ----------
$K --enable  ACPI_BATTERY
$K --enable  ACPI_AC
$K --enable  ACPI_BUTTON
$K --enable  BACKLIGHT_CLASS_DEVICE
$K --module  THINKPAD_ACPI
$K --module  MOUSE_PS2_SYNAPTICS

# --- card reader: Realtek RTS525A (rtsx_pci) ----------------------------------------
# Deferred, per host.toml: not on the boot path and not needed yet. Add
# MFD_RTSX_PCI + MMC_REALTEK_PCI here if it turns out to be wanted -- exact Kconfig
# symbol names not yet verified against this kernel's Kconfig, unlike everything above.

kernel_config_finish

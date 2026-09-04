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

# --- bluetooth: Intel 8260 combo chip, USB HCI half ---------------------------------
# Confirmed live (2026-09-03): lsusb shows 8087:0a2b "Intel Corp. Bluetooth wireless
# interface" on the internal USB bus (the same 8260 chip IWLWIFI/IWLMVM above already
# cover for WiFi), and dmesg shows thinkpad_acpi's own rfkill switch
# (tpacpi_bluetooth_sw) already unblocked at boot -- but nothing in the running kernel
# could bind the HCI device: CONFIG_BT and everything under it were unset. Book's own
# Kernel Configuration section for BLFS's bluez.html, minus the Cryptographic API block
# (only needed to run bluez's test suite, which this project doesn't run) and minus
# BT_HCIBTSDIO/BT_HCIUART (this hardware is USB, not SDIO or UART). Not on the boot
# path -- modules, RFKILL is already =y from the shared base's defconfig default.
$K --module  BT
$K --enable  BT_BREDR
$K --module  BT_RFCOMM
$K --enable  BT_RFCOMM_TTY
$K --module  BT_BNEP
$K --enable  BT_BNEP_MC_FILTER
$K --enable  BT_BNEP_PROTO_FILTER
$K --module  BT_HIDP
$K --module  BT_HCIBTUSB

# --- wired ethernet, dock: Lenovo OneLink+ Giga (USB CDC-ECM, 17ef:3054) -----------
# Confirmed live (2026-09-03): lsusb shows idVendor=17ef idProduct=3054 "Lenovo
# OneLink+ Giga" on the OneLink+ dock's internal USB3 hub; sysfs bInterfaceClass/
# SubClass on interface 0 is 02/06 (CDC-ECM), not a vendor-specific chip -- no
# r8152 needed. Nothing claimed it because USB_USBNET (the framework every USB
# Ethernet class driver, cdc_ether included, depends on) was never turned on --
# E1000E above only covers the onboard Intel I219-LM, a different device. Modules,
# not built-in: not on the boot path (root is the internal NVMe), so no initramfs
# implication.
$K --module USB_USBNET
$K --module USB_NET_CDCETHER

# --- webcam: Logitech HD Pro Webcam C920 (UVC, USB) ---------------------------------
# Confirmed live (2026-09-04): lsusb/dmesg both show 046d:082d "HD Pro Webcam C920"
# enumerating fine at the USB level, but no /dev/video* ever appears -- this kernel's
# whole media/V4L2 subsystem was absent, not just the one driver (checked every
# CONFIG_MEDIA_*/CONFIG_VIDEO_*/CONFIG_USB_VIDEO_CLASS symbol against
# /boot/config-6.18.10 directly: all unset). No BLFS book page for this -- it's
# purely a kernel Kconfig matter, standard/well-known UVC support, not a userspace
# package. Not on the boot path -- modules. MEDIA_CONTROLLER and the VIDEOBUF2_*
# buffer-queue helpers uvcvideo needs are select'd automatically by Kconfig, not
# set explicitly here -- verify their presence the same way BT_HCIBTUSB was verified
# (grep the built /lib/modules tree for uvcvideo.ko), not assumed from this list.
$K --enable  MEDIA_SUPPORT
$K --enable  MEDIA_USB_SUPPORT
$K --enable  MEDIA_CAMERA_SUPPORT
$K --module  VIDEO_DEV
$K --module  USB_VIDEO_CLASS

kernel_config_finish

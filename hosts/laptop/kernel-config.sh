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
# set explicitly here.
#
# Verified against a real build 2026-09-04 (the same way BT_HCIBTUSB was), rather
# than assumed from this list. Built /boot/config-6.18.10 came out with
# MEDIA_SUPPORT=y, MEDIA_USB_SUPPORT=y, MEDIA_CAMERA_SUPPORT=y,
# MEDIA_CONTROLLER=y, USB_VIDEO_CLASS=m and VIDEOBUF2_{CORE,V4L2}=m, and
# /lib/modules/6.18.10 has kernel/drivers/media/usb/uvc/uvcvideo.ko plus the four
# videobuf2-*.ko helpers -- so the select'd symbols do resolve on their own and
# need no explicit lines here. One deviation worth knowing: VIDEO_DEV came out
# **=y, not =m** as asked for below. Kconfig promoted it because MEDIA_SUPPORT=y
# plus the enabled sub-menus select it as builtin. Harmless (it is the V4L2 core,
# not a driver, and nothing here is on the boot path), and left as --module so the
# intent stays readable; just do not expect a videodev.ko to exist.
$K --enable  MEDIA_SUPPORT
$K --enable  MEDIA_USB_SUPPORT
$K --enable  MEDIA_CAMERA_SUPPORT
$K --module  VIDEO_DEV
$K --module  USB_VIDEO_CLASS

# --- thermal management: the sensors and control knobs thermald needs ---------------
# Confirmed live 2026-09-04, after the reboot into the media/USER_NS kernel:
# thermald 2.5.12 is enabled and running, and cannot do its job. Its own log says so
# in three lines --
#
#   thermald[323]: NO RAPL sysfs present
#   thermald[323]: Thermal DTS: No coretemp sysfs found
#   thermald[323]: Thermal DTS or hwmon: No Zones present Need to configure manually
#
# -- after which it falls back to polling mode 4 with nothing to read and nothing to
# actuate. Checked against the running kernel rather than inferred: /sys/class/powercap
# does not exist at all, no hwmon is named coretemp (the five present are AC, acpitz,
# BAT0, thinkpad and iwlwifi_1), and /boot/config-6.18.10 has SENSORS_CORETEMP,
# POWERCAP, INTEL_RAPL and INTEL_POWERCLAMP all unset.
#
# The machine was never at risk and this is not an emergency fix: the package's own
# hardware throttling is unconditional and below the OS, and thermal_zone0 (acpitz)
# drives the four Processor cooling devices through the step_wise governor. What is
# missing is thermald's ability to see per-core temperature and to act on anything
# finer than cpufreq -- i.e. the entire reason the package is installed.
#
# Four symbols, all verified against this kernel's own Kconfig (extracted from
# linux-6.18.10.tar.xz and read, not assumed):
#
#   SENSORS_CORETEMP   tristate, depends on X86. The per-core DTS sensor, and
#                      thermald's primary input -- the "No coretemp sysfs found" line
#                      above is literally this driver's absence. HWMON is already =y.
#   POWERCAP           bool, and the menuconfig gate INTEL_RAPL sits inside. This is
#                      what creates /sys/class/powercap. INTEL_POWERCLAMP select's it
#                      anyway; set explicitly so the dependency is visible here rather
#                      than implied.
#   INTEL_RAPL         tristate, depends on X86 && PCI, select's INTEL_RAPL_CORE
#                      (which needs IOSF_MBI -- already =y). Running Average Power
#                      Limit via MSR: thermald's primary *control* knob, and the
#                      "NO RAPL sysfs present" line. Sandy Bridge and later, so this
#                      Skylake part is covered.
#   INTEL_POWERCLAMP   tristate, depends on X86 && CPU_SUP_INTEL && CPU_IDLE (=y).
#                      Idle-injection cooling device, exposed through the generic
#                      thermal framework -- the knob thermald reaches for when
#                      cpufreq alone is not enough.
#
# Also INTEL_TCC_COOLING, which is not obviously applicable and was checked before
# being included: drivers/thermal/intel/intel_tcc_cooling.c matches on an explicit
# CPU list, and X86_MATCH_VFM(INTEL_SKYLAKE_L) is in it. This CPU reports family 6
# model 78 stepping 3 (0x6:4e:3) -- SKYLAKE_L -- so the driver will bind here rather
# than load and do nothing. It exposes the TCC offset as a cooling device, letting
# thermald move the throttle point instead of only reacting to it.
#
# Host, not shared: every one of these names Intel. server is Intel too, but the test
# in CLAUDE.md is whether the thing is true of *any* machine running this book, and a
# CPU vendor is not.
#
# Modules, not built-in: none of this is on the boot path (root is NVMe, and the
# thermal framework itself is already =y from defconfig). POWERCAP is the exception
# only because it is a bool.
$K --module  SENSORS_CORETEMP
$K --enable  POWERCAP
$K --module  INTEL_RAPL
$K --module  INTEL_POWERCLAMP
$K --module  INTEL_TCC_COOLING

kernel_config_finish

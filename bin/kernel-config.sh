#!/bin/bash
# Scripted replacement for the book's interactive `make menuconfig` (LFS 13.0 s10.3).
#
# Starts from `make defconfig`, which the book itself recommends as "a good starting
# place ... takes your current system architecture into account". Then applies every
# option the book lists as required, plus the boot-path drivers this build needs as
# built-ins: LFS installs no initramfs, so anything required to reach the root
# filesystem must be =y, never =m.
#
# Runs inside the chroot, from the kernel source directory.
set -e

make defconfig

K=./scripts/config

# --- book: General setup ---
$K --disable WERROR
$K --enable  PSI
$K --disable PSI_DEFAULT_DISABLED
$K --disable IKHEADERS
$K --enable  CGROUPS
$K --enable  MEMCG
$K --enable  CGROUP_SCHED
$K --disable RT_GROUP_SCHED
$K --disable EXPERT

# --- book: Processor type and features ---
$K --enable  RELOCATABLE
$K --enable  RANDOMIZE_BASE

# --- book: General architecture-dependent options ---
$K --enable  STACKPROTECTOR
$K --enable  STACKPROTECTOR_STRONG

# --- book: 64-bit extras (book notes the dependency order) ---
$K --enable  PCI
$K --enable  PCI_MSI
$K --enable  IOMMU_SUPPORT
$K --enable  IRQ_REMAP
$K --enable  X86_X2APIC

# --- book: Networking ---
$K --enable  NET
$K --enable  INET
$K --enable  IPV6

# --- added 2026-08-25: netfilter legacy tables, for BLFS's iptables page ---
# `make defconfig` left NF_TABLES and NETFILTER_XTABLES_LEGACY both unset --
# neither the nftables nor the classic iptables backend existed in the running
# kernel, so iptables (built with the book's --disable-nftables) had no `filter`
# or `nat` table to attach to. The book's own iptables.html builds against the
# legacy ABI, so that's the path enabled here rather than switching to nf_tables.
$K --enable  NETFILTER_XTABLES_LEGACY
$K --module  IP_NF_IPTABLES_LEGACY
$K --module  IP_NF_FILTER
$K --module  IP_NF_NAT
$K --module  IP_NF_MANGLE
$K --module  IP_NF_TARGET_REJECT
$K --module  IP6_NF_IPTABLES_LEGACY
$K --module  IP6_NF_FILTER
$K --module  IP6_NF_MANGLE

# --- added 2026-08-26: batched pending items for the next kernel rebuild ---
# nouveau: this GPU (GK104/GTX 770, Kepler) currently has no driver bound at
# all -- `make defconfig` doesn't enable it. Needed for the Hyprland stack's
# OpenGL acceleration (Mesa already built with gallium-drivers=nouveau).
$K --module  DRM_NOUVEAU
# cryptsetup: installed and verified (tier "extended scope", 2026-08-25) but
# can't open/create encrypted volumes yet -- none of these were set either.
$K --module  DM_CRYPT
$K --enable  CRYPTO_XTS
$K --enable  CRYPTO_USER_API_SKCIPHER
# wireguard-tools: userspace CLI only needs the kernel module, in-tree since
# Linux 5.6 but not enabled by defconfig on this kernel either.
$K --module  WIREGUARD

# --- book: Device Drivers, udev/systemd requirements ---
$K --disable UEVENT_HELPER
$K --enable  DEVTMPFS
$K --enable  DEVTMPFS_MOUNT
$K --enable  FW_LOADER
$K --disable FW_LOADER_USER_HELPER
$K --enable  DMIID
$K --enable  SYSFB_SIMPLEFB

# --- book: Graphics support / console ---
$K --enable  DRM
$K --enable  DRM_PANIC
$K --enable  DRM_FBDEV_EMULATION
$K --enable  DRM_SIMPLEDRM
$K --enable  FRAMEBUFFER_CONSOLE

# --- book: File systems ---
$K --enable  INOTIFY_USER
$K --enable  TMPFS
$K --enable  TMPFS_POSIX_ACL

# --- boot path, built in (no initramfs) ---
$K --enable  BLOCK
$K --enable  SCSI
$K --enable  BLK_DEV_SD
$K --enable  ATA
$K --enable  ATA_PIIX
$K --enable  SATA_AHCI
$K --enable  BLK_DEV_NVME
$K --enable  EXT4_FS
$K --enable  EXT4_USE_FOR_EXT2

# --- USB boot path, built in ---
$K --enable  USB_SUPPORT
$K --enable  USB
$K --enable  USB_PCI
$K --enable  USB_XHCI_HCD
$K --enable  USB_XHCI_PCI
$K --enable  USB_EHCI_HCD
$K --enable  USB_EHCI_PCI
$K --enable  USB_OHCI_HCD
$K --enable  USB_OHCI_HCD_PCI
$K --enable  USB_UHCI_HCD
$K --enable  USB_STORAGE
$K --enable  USB_UAS

# Resolve dependencies non-interactively.
make olddefconfig

# --- gate -----------------------------------------------------------------
# Every driver on the boot path must be =y. A module here means the kernel
# cannot reach its own root filesystem, and the failure only shows up at boot.
fail=0
for opt in EXT4_FS BLK_DEV_SD SCSI ATA SATA_AHCI USB USB_XHCI_HCD \
           USB_EHCI_HCD USB_STORAGE USB_UAS DEVTMPFS DEVTMPFS_MOUNT TMPFS; do
    v=$(grep -E "^CONFIG_${opt}=" .config || true)
    if [ "$v" = "CONFIG_${opt}=y" ]; then
        echo "  ok   CONFIG_${opt}=y"
    else
        echo "  FAIL CONFIG_${opt} is '${v:-unset}' -- must be =y"
        fail=1
    fi
done

if [ "$fail" -ne 0 ]; then
    echo "### kernel config gate FAILED: boot path is not fully built in"
    exit 1
fi
echo "### kernel config gate passed: boot path built in, no initramfs needed"

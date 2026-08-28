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

# --- not in the book: default cpufreq governor -----------------------------
# defconfig leaves this as CONFIG_CPU_FREQ_DEFAULT_GOV_USERSPACE=y, which is a
# trap on a machine with no cpufreq daemon: the userspace governor only changes
# frequency when a process writes scaling_setspeed, so with nothing writing it
# every core sits at scaling_min_freq forever. On this i5-2500K that meant
# 1600 MHz instead of the 3400 MHz all-core turbo -- a measured 2.1x loss on
# sustained CPU work, found on 2026-08-27 while diagnosing an x264 encode that
# ran at 0.51x realtime (0.84x after releasing the clock; synthetic x264 1080p
# medium bench: 0.32x -> 0.70x).
#
# schedutil rather than performance: it was measured to hold the same 3403 MHz
# under sustained encode load (0.719x vs 0.735x on performance) without pinning
# max clock at idle. Also keep ONDEMAND available as a fallback governor.
$K --disable CPU_FREQ_DEFAULT_GOV_USERSPACE
$K --enable  CPU_FREQ_DEFAULT_GOV_SCHEDUTIL
$K --enable  CPU_FREQ_GOV_SCHEDUTIL
$K --enable  CPU_FREQ_GOV_PERFORMANCE
$K --enable  CPU_FREQ_GOV_ONDEMAND

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

# --- added 2026-08-27: TUN/TAP device support ---
# Not set by `make defconfig`. Needed for Tailscale: unlike the in-kernel
# WIREGUARD module above (which implements its own dedicated netdevice type),
# Tailscale runs a userspace WireGuard implementation (wireguard-go) that
# pushes packets through a /dev/net/tun character device -- an entirely
# different kernel interface, TUN, not the WireGuard module. Confirmed unset
# in the running kernel's own .config before adding this.
$K --module  TUN

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

# --- gate: default cpufreq governor ---------------------------------------
# A silent regression here costs ~2x on every CPU-bound workload and shows up
# as nothing but "the machine feels slow", so assert it rather than trust
# olddefconfig to have kept the --enable above.
gov=$(grep -E '^CONFIG_CPU_FREQ_DEFAULT_GOV_[A-Z]+=y' .config || true)
if [ "$gov" = "CONFIG_CPU_FREQ_DEFAULT_GOV_SCHEDUTIL=y" ]; then
    echo "  ok   default cpufreq governor is schedutil"
else
    echo "  FAIL default cpufreq governor is '${gov:-unset}' -- want SCHEDUTIL"
    echo "### kernel config gate FAILED: userspace/unset governor pins all cores at min freq"
    exit 1
fi

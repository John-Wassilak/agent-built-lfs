# SPDX-License-Identifier: MIT
# agent-built-lfs -- shared kernel configuration
# Copyright (c) 2026 John Wassilak

# Shared kernel configuration for every machine in this repo. Sourced, not executed:
# hosts/<name>/kernel-config.sh sources this, adds that machine's hardware between
# kernel_config_shared and kernel_config_finish, and is the file the ch10-kernel recipe
# actually runs.
#
# Scripted replacement for the book's interactive `make menuconfig` (LFS chapter 10).
#
# Starts from `make defconfig`, which the book itself recommends as "a good starting
# place ... takes your current system architecture into account". Then applies every
# option the book lists as required, plus the boot-path drivers this build needs as
# built-ins: LFS installs no initramfs, so anything required to reach the root
# filesystem must be =y, never =m.
#
# What belongs here: anything true of any x86_64 LFS box -- the book's required options,
# the generic block/SATA/NVMe/USB boot path, netfilter, the cpufreq governor default.
# What belongs in the host file: a specific GPU's DRM driver, a specific board's audio
# codecs, a controller only that machine has.
#
# Both files must sit in the same directory when staged for the chroot, because the host
# script sources this one by "$(dirname "$0")".

kernel_config_start() {
    make defconfig
    K=./scripts/config
}

kernel_config_shared() {
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

    # --- not in the book: user namespaces -------------------------------------
    # defconfig leaves CONFIG_USER_NS unset, and that breaks systemd's own service
    # sandboxing rather than only affecting containers. Any unit with
    # PrivateUsers=yes fails to spawn at all: systemd logs "Failed to set up user
    # namespacing: Invalid argument" then "Failed at step USER", and the unit dies
    # with status=217/USER before its ExecStart binary is ever reached. Found on
    # laptop 2026-09-04 via upower.service, whose upstream unit (shipped by upower
    # itself, not written here) sets PrivateUsers=yes -- so this is a book-level
    # fact about running BLFS's own packaged units, not a laptop hardware detail,
    # and it applies to every machine here. Cheap: one bool, no driver, no boot-path
    # implication.
    $K --enable  USER_NS

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

    # --- added 2026-08-26: batched pending items -------------------------------
    # The GPU's own DRM driver is NOT here -- it is per-machine, set by the host file.
    # cryptsetup: installed and verified (tier "extended scope", 2026-08-25) but
    # can't open/create encrypted volumes yet -- none of these were set either.
    $K --module  DM_CRYPT
    $K --enable  CRYPTO_XTS
    $K --enable  CRYPTO_USER_API_SKCIPHER
    # wireguard-tools: userspace CLI only needs the kernel module, in-tree since
    # Linux 5.6 but not enabled by defconfig on this kernel either.
    $K --module  WIREGUARD

    # --- added 2026-09-01: sshfs needs FUSE (Filesystem in Userspace) support --
    # generic kernel feature, true of any machine, not per-host. CUSE (Character
    # device in Userspace) is fuse's own book page's second Kernel Configuration
    # block, needed only to run fuse's own test suite (not run here, matching this
    # project's test-suite policy) -- enabled anyway since it's a small, harmless
    # module and a future host may want it without a second kernel rebuild.
    $K --module  FUSE_FS
    $K --module  CUSE

    # --- added 2026-09-23: container runtime (Docker / containerd / runc) ------
    # Not in any book (BLFS/SLFS/GLFS 13.1 carry no container page). A feature, not
    # hardware, so it goes here with FUSE and WireGuard. Measured against moby's own
    # contrib/check-config.sh on server's 7.1.8 config: namespaces, seccomp, memcg,
    # pids, cpuset and conntrack were already set; these were missing.
    #
    # BPF_SYSCALL + CGROUP_BPF: on cgroup v2 (what systemd mounts here) runc enforces
    # the device allowlist with a BPF program attached to the container's cgroup --
    # there is no devices.allow file on v2. Without these runc cannot start a
    # container at all.
    $K --enable  BPF_SYSCALL
    $K --enable  CGROUP_BPF
    # --cpus / cpu quota; dockerd warns and ignores the flag without it.
    $K --enable  CFS_BANDWIDTH
    # Default bridge network: a veth pair per container onto docker0, with bridged
    # traffic visible to iptables. BRIDGE_NETFILTER depends on NETFILTER_ADVANCED.
    $K --enable  NETFILTER_ADVANCED
    $K --module  VETH
    $K --module  BRIDGE
    $K --module  BRIDGE_NETFILTER
    # Outbound NAT for containers and dockerd's port-publishing rules. Legacy
    # xtables, matching the iptables build above. IP_NF_TARGET_MASQUERADE selects
    # NETFILTER_XT_TARGET_MASQUERADE. IP_NF_RAW: dockerd 28+ installs raw-table
    # PREROUTING drops so hosts on the LAN cannot route directly to a container IP.
    $K --module  IP_NF_TARGET_MASQUERADE
    $K --module  NETFILTER_XT_MATCH_ADDRTYPE
    $K --module  NETFILTER_XT_MARK
    $K --module  IP_NF_RAW
    # IPv6 half of the same, listed "Generally Necessary" by check-config.sh:
    # dockerd programs ip6tables by default and fails network setup without the
    # nat table. Enabling these does not open v6 -- the host firewall's ip6tables
    # policy is still what decides.
    $K --module  IP6_NF_NAT
    $K --module  IP6_NF_TARGET_MASQUERADE
    $K --module  IP6_NF_RAW
    # NETFILTER_ADVANCED=y has a side effect: IP6_NF_TARGET_REJECT is
    # `default m if NETFILTER_ADVANCED=n`, so it silently drops out of the config.
    # Found by diffing the result against /boot/config-7.1.8; the only symbol
    # affected. Pinned here so the ip6tables REJECT target stays available.
    $K --module  IP6_NF_TARGET_REJECT
    # NETFILTER_XT_MATCH_IPVS / IP_VS: check-config.sh also lists these, but only
    # Swarm-mode service load balancing uses them. Left out.
    # overlay2 / containerd's overlayfs snapshotter, the default image storage.
    $K --module  OVERLAY_FS

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
}

# Resolve dependencies non-interactively, then assert the things whose failure is silent.
# EXTRA_GATE_BUILTIN may name additional options a host requires as =y.
kernel_config_finish() {
    make olddefconfig

    # --- gate -----------------------------------------------------------------
    # Every driver on the boot path must be =y. A module here means the kernel
    # cannot reach its own root filesystem, and the failure only shows up at boot.
    fail=0
    for opt in EXT4_FS BLK_DEV_SD SCSI ATA SATA_AHCI USB USB_XHCI_HCD \
               USB_EHCI_HCD USB_STORAGE USB_UAS DEVTMPFS DEVTMPFS_MOUNT TMPFS \
               ${EXTRA_GATE_BUILTIN:-}; do
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
}

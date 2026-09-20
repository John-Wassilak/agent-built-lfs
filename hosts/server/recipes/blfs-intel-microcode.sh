#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Baseline hardware audit (2026-08-25): CPU is an i5-2500K (family 6, model 42, stepping 7 -> blob 06-2a-07) running microcode 0x28, applied once by the board's 2012 BIOS and never updated. The kernel's own 'bugs:' line in /proc/cpuinfo lists old_microcode and vmscape as unmitigated. BLFS's firmware.html is explicit that late loading is no longer supported upstream (the kernel taints and warns on it) -- early loading via a dedicated initrd is the only endorsed path. That reverses this system's original no-initramfs design (see BUILD-REPORT.md), a deliberate call made for this one purpose: the initrd carries nothing but this CPU's microcode blob, not a general-purpose early-boot environment.
set -e

# DNS fix added 2026-09-09 (fresh chroot build): this chroot has no working
# /etc/resolv.conf by default, same class of issue as blfs-rust/blfs-attrs/blfs-
# linux-firmware-rtl-nic and others.
_restore_resolv() {
    rm -f /etc/resolv.conf
    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
}
trap _restore_resolv EXIT
rm -f /etc/resolv.conf
printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf

MC_REL=microcode-20260812
curl -fsSL --retry 5 --retry-delay 3 -o microcode.tar.gz \
    "https://api.github.com/repos/intel/Intel-Linux-Processor-Microcode-Data-Files/tarball/$MC_REL"
mkdir -p microcode-src
tar -xf microcode.tar.gz --strip-components=1 -C microcode-src

mkdir -p initrd/kernel/x86/microcode
cp -v microcode-src/intel-ucode/06-2a-07 initrd/kernel/x86/microcode/GenuineIntel.bin
( cd initrd && find * | cpio -o -H newc > /boot/microcode.img )

# /boot is not a separate partition on this system, so grub.cfg uses the
# in-root path form the book gives for that case. Idempotent re-run.
#
# grub.cfg may not exist yet: this project's grub.cfg is fully hand-maintained at
# overlay/boot/grub.cfg (see root CLAUDE.md), applied by hand at deploy time per
# BOOTSTRAP.md -- true on the live system (grub.cfg has existed since the machine's
# first boot) but not on a from-scratch build, where the overlay hasn't been applied
# yet. The overlay file already carries this exact 'initrd /boot/microcode.img' line,
# so there is nothing to append once it lands -- skip gracefully rather than fail.
if [ -f /boot/grub/grub.cfg ]; then
    grep -q '^[[:space:]]*initrd /boot/microcode.img' /boot/grub/grub.cfg || \
        sed -i '/^[[:space:]]*linux \/boot\/vmlinuz/a\        initrd /boot/microcode.img' \
            /boot/grub/grub.cfg
    grub-script-check /boot/grub/grub.cfg
    echo "### grub.cfg:"
    cat /boot/grub/grub.cfg
else
    echo "### /boot/grub/grub.cfg does not exist yet -- overlay not applied (expected on a fresh build); overlay/boot/grub.cfg already carries the initrd line for when it is."
fi

echo "### initrd:"
ls -l /boot/microcode.img


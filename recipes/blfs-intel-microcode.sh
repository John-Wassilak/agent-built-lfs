#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Baseline hardware audit (2026-08-25): CPU is an i5-2500K (family 6, model 42, stepping 7 -> blob 06-2a-07) running microcode 0x28, applied once by the board's 2012 BIOS and never updated. The kernel's own 'bugs:' line in /proc/cpuinfo lists old_microcode and vmscape as unmitigated. BLFS's firmware.html is explicit that late loading is no longer supported upstream (the kernel taints and warns on it) -- early loading via a dedicated initrd is the only endorsed path. That reverses this system's original no-initramfs design (see BUILD-REPORT.md), a deliberate call made for this one purpose: the initrd carries nothing but this CPU's microcode blob, not a general-purpose early-boot environment.
set -e

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
grep -q '^[[:space:]]*initrd /boot/microcode.img' /boot/grub/grub.cfg || \
    sed -i '/^[[:space:]]*linux \/boot\/vmlinuz/a\        initrd /boot/microcode.img' \
        /boot/grub/grub.cfg
grub-script-check /boot/grub/grub.cfg

echo "### grub.cfg:"
cat /boot/grub/grub.cfg
echo "### initrd:"
ls -l /boot/microcode.img


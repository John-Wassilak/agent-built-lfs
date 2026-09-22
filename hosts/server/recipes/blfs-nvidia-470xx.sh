#!/bin/bash
# HAND-AUTHORED recipe -- proprietary NVIDIA driver, not BLFS.
#
# This IS the system's primary GPU driver as of 2026-08-26 (operator
# decision, after Hyprland/Wayland proved a dead end -- see below).
# Originally built and tested as an experiment on a second GRUB entry
# before being promoted to boot/grub.cfg's default; nouveau is kept as
# entry 1, a fallback, not the primary path anymore.
#
# GTX 770 (GK104, Kepler) is only supported by NVIDIA's legacy 470.xx
# branch -- confirmed against NVIDIA's own supported-chips list
# (device 0x1184, VDPAU feature level D). 470.xx predates GBM support
# in NVIDIA's driver (added in 495, years after Kepler was frozen on
# 470.xx) -- it only supports the older EGLStreams mechanism. Hyprland
# (via aquamarine) has no supported EGLStreams path per Hyprland's own
# wiki -- confirmed live (kmsro: driver missing -> CBackend::create()
# failed), not just predicted. That's what actually drove the decision
# to abandon Hyprland/Wayland for X11/awesome (see AWESOME-X11-PLAN.md)
# rather than a driver choice made for its own sake -- the real goal
# was fixing nouveau's confirmed-broken VAAPI H.264 decode (Mesa
# gitlab issue #14058, unfixed upstream), and VDPAU on this driver
# delivers that, confirmed working end-to-end (see BUILD-REPORT.md's
# Phase 4 testing).
#
# Patched for kernel 7.1.8 using the actively-maintained
# github.com/joanbm/nvidia-470xx-linux-mainline patch set (used by
# Arch's own nvidia-470xx-dkms AUR package) -- 470.xx's own kernel
# module source predates modern kernel internal APIs and does not
# build unpatched past roughly kernel 6.10.
set -e

# Updated 2026-09-08 for the LFS 13.1 bump: kernel version throughout this recipe was
# 6.18.10 (13.0's kernel), now 7.1.8. Also: SYSSRC below used to point at a persistent
# /root/kbuild/linux-6.18.10 this recipe assumed already existed -- true only because an
# earlier session had built it separately and never cleaned it up. ch10-kernel's own
# recipe unpacks-then-cleans-up its kernel source tree like every other step, so nothing
# persists there by default. This recipe now builds its own kbuild tree from the staged
# kernel tarball plus the real running kernel's own .config (installed by ch10-kernel to
# /boot/config-7.1.8) -- an external module must build against a tree configured and
# `modules_prepare`d to match the kernel it will load into, not just bare headers.
# DNS fix added 2026-09-09 (fresh chroot build): this chroot has no working
# /etc/resolv.conf by default, same class of issue as blfs-rust/blfs-attrs/blfs-
# linux-firmware-rtl-nic/blfs-intel-microcode and others -- the wget and git clone
# below both need it.
_restore_resolv() {
    rm -f /etc/resolv.conf
    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
}
trap _restore_resolv EXIT
rm -f /etc/resolv.conf
printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf

VERSION=470.256.02
KVER=7.1.8
WORK=/root/build-nvidia-470xx
# rm -rf added 2026-09-09: this hand() step has tarball="" (self-fetching), so the
# generic driver's unpack-then-cleanup logic never applies here -- $WORK persisted
# across a retry and the .run installer's --extract-only refused to overwrite its own
# leftover extracted directory from the previous (failed) attempt. Idempotent re-run.
rm -rf "$WORK" /root/kbuild
mkdir -p "$WORK"
cd "$WORK"

mkdir -p /root/kbuild
tar -xf "/sources/linux-${KVER}.tar.xz" -C /root/kbuild
cp "/boot/config-${KVER}" "/root/kbuild/linux-${KVER}/.config"
make -C "/root/kbuild/linux-${KVER}" olddefconfig
make -C "/root/kbuild/linux-${KVER}" modules_prepare

# Full build added 2026-09-09: modules_prepare alone leaves no real Module.symvers,
# and NVIDIA's own conftest.sh (kernel/conftest.sh's export_symbol_present_conftest)
# ONLY greps that file to decide which kernel API a given source file should call --
# its own comment admits "May be a false negative if Module.symvers is absent". With
# it missing, nv-caps.c's close_fd()/__close_fd()/sys_close() version-detection picked
# the oldest (removed) sys_close() fallback and failed to compile: "implicit
# declaration of function 'sys_close'" -- confirmed via direct kernel source
# inspection that close_fd() really is exported here (fs/file.c's EXPORT_SYMBOL(
# close_fd)) and conftest simply had nothing to grep. A real build (this exact config,
# same as ch10-kernel's own) populates Module.symvers accurately, fixing this and any
# other conftest check the missing file would have gotten wrong, not just this one
# symptom.
make -C "/root/kbuild/linux-${KVER}" -j"$(nproc)"

wget -q "https://us.download.nvidia.com/XFree86/Linux-x86_64/${VERSION}/NVIDIA-Linux-x86_64-${VERSION}.run" \
    -O "NVIDIA-Linux-x86_64-${VERSION}.run"
chmod +x "NVIDIA-Linux-x86_64-${VERSION}.run"
./"NVIDIA-Linux-x86_64-${VERSION}.run" --extract-only

git clone --depth=1 https://github.com/joanbm/nvidia-470xx-linux-mainline.git patches-repo

cd "NVIDIA-Linux-x86_64-${VERSION}/kernel"
PATCHES="$WORK/patches-repo/patches"
apply_patch() { patch -Np1 -i "$PATCHES/$1"; }
apply_patch 0001-Fix-conftest-to-ignore-implicit-function-declaration.patch
apply_patch 0002-Fix-conftest-to-use-a-short-wchar_t.patch
apply_patch 0003-Fix-conftest-to-use-nv_drm_gem_vmap-which-has-the-se.patch
apply_patch kernel-6.10.patch
apply_patch kernel-6.12.patch
apply_patch nvidia-470xx-fix-gcc-15.patch
apply_patch nvidia-470xx-fix-linux-6.13.patch
apply_patch nvidia-470xx-fix-linux-6.14.patch
apply_patch nvidia-470xx-fix-linux-6.15.patch
apply_patch nvidia-470xx-fix-linux-6.17.patch
apply_patch nvidia-470xx-fix-linux-6.19-part1.patch
apply_patch nvidia-470xx-fix-linux-6.19-part2.patch
apply_patch nvidia-470xx-fix-linux-7.0.patch
apply_patch nvidia-470xx-fix-linux-7.2-part1.patch
apply_patch nvidia-470xx-fix-linux-7.2-part2.patch
apply_patch nvidia-470xx-fix-linux-7.2-part3.patch
apply_patch nvidia-470xx-fix-linux-7.3.patch
apply_patch disable-objtool-override.patch
apply_patch enable-drm-modeset-by-default.patch

# IGNORE_MISSING_MODULE_SYMVERS=1 added 2026-09-09 (fresh chroot build): this kbuild
# tree was set up via modules_prepare only (see above), not a full kernel build, so it
# has no real Module.symvers -- ch10-kernel's own tree (which built the actual running
# kernel and would have a real one) is cleaned up after that step, per every other
# package's unpack-then-cleanup convention, so nothing persists to reuse here. The
# .config copied in is the exact real running config, so the mismatch this check exists
# to catch does not apply -- this is NVIDIA's own documented, officially-supported
# escape hatch for exactly this external-module-build-without-a-full-tree scenario.
IGNORE_MISSING_MODULE_SYMVERS=1 make SYSSRC=/root/kbuild/linux-${KVER} -j"$(nproc)"

# Installed additively -- a NEW directory, does not touch nouveau.ko.
# depmod registers a PCI-ID alias matching this exact GPU (confirmed
# directly via `modinfo nvidia-drm` against the device's own modalias --
# a real overlap, not just caution), which is exactly what makes
# per-boot exclusion via GRUB's own modprobe.blacklist=... kernel
# cmdline parameter work symmetrically on both entries (see
# boot/grub.cfg): entry 0 blacklists nouveau so this driver's alias
# wins the udev auto-load race uncontested; entry 1 (nouveau fallback)
# blacklists this driver's modules the same way, so nouveau's own alias
# wins instead. No static /etc/modprobe.d blacklist needed for either
# direction -- an earlier version of this recipe used one exclusively
# for nvidia, back when this was still just an experiment on a single
# always-on test entry; removed once this became the permanent
# default and the exclusion needed to work in both directions.
install -v -d /lib/modules/${KVER}/kernel/drivers/video/nvidia-470xx
install -v -m644 nvidia.ko nvidia-drm.ko nvidia-modeset.ko nvidia-uvm.ko nvidia-peermem.ko \
    /lib/modules/${KVER}/kernel/drivers/video/nvidia-470xx/
depmod -a ${KVER}

# KMS modeset -- required for the X11/awesome desktop to get a working
# DRM device from nvidia-drm at all. Harmless on the nouveau-fallback
# entry: the option only takes effect if/when nvidia-drm actually loads,
# which it won't there (blacklisted on that entry's cmdline).
install -v -d /etc/modprobe.d
cat > /etc/modprobe.d/nvidia-modeset.conf << "EOF"
options nvidia-drm modeset=1
EOF

# Userspace: --no-install-libglvnd is load-bearing -- this system's
# existing glvnd (1.7.0) and Mesa vendor JSONs must not be touched, since
# the default/nouveau boot entry depends on them working exactly as they
# do today. Confirmed post-install: generic libGL.so/libEGL.so/libGLX.so
# untouched (installer logged "Skipping GLVND file" for every one of
# them), only vendor-specific libGLX_nvidia.so/libEGL_nvidia.so/etc and
# their glvnd vendor JSON (10_nvidia.json, alongside the existing
# 50_mesa.json -- glvnd tries all vendors present, this is normal/safe
# multi-vendor coexistence) were added.
cd "$WORK/NVIDIA-Linux-x86_64-${VERSION}"
./nvidia-installer \
    --no-kernel-module \
    --no-nouveau-check \
    --no-x-check \
    --no-distro-scripts \
    --no-libglx-indirect \
    --no-install-libglvnd \
    --no-questions \
    --ui=none \
    --log-file-name="$WORK/nvidia-installer.log"

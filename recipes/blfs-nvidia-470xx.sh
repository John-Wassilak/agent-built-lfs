#!/bin/bash
# HAND-AUTHORED, EXPERIMENTAL recipe -- proprietary NVIDIA driver, not
# BLFS. This is NOT the system's primary GPU driver -- nouveau remains
# default on every normal boot (GRUB entry 0, untouched). This is
# installed purely to test whether VDPAU hardware H.264 decode works
# for a security-camera-viewing workload, given nouveau's own VAAPI
# decode has a confirmed, unfixed upstream crash bug (see BUILD-REPORT.md
# GPU deep-dive, and Mesa gitlab issue #14058).
#
# GTX 770 (GK104, Kepler) is only supported by NVIDIA's legacy 470.xx
# branch -- confirmed against NVIDIA's own supported-chips list
# (device 0x1184, VDPAU feature level D). 470.xx predates GBM support
# in NVIDIA's driver (added in 495, years after Kepler was frozen on
# 470.xx) -- it only supports the older EGLStreams mechanism. Hyprland
# (via aquamarine) has no supported EGLStreams path per Hyprland's own
# wiki, so this is expected to likely break Wayland/Hyprland compositing
# entirely while (hopefully) fixing VDPAU decode -- a real, accepted
# tradeoff, not an oversight. See the GRUB entry this depends on
# (boot/grub.cfg, entry 1) for how this is tested without touching the
# default/working boot path.
#
# Patched for kernel 6.18.10 using the actively-maintained
# github.com/joanbm/nvidia-470xx-linux-mainline patch set (used by
# Arch's own nvidia-470xx-dkms AUR package) -- 470.xx's own kernel
# module source predates modern kernel internal APIs and does not
# build unpatched past roughly kernel 6.10.
set -e

VERSION=470.256.02
WORK=/root/build-nvidia-470xx
mkdir -p "$WORK"
cd "$WORK"

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

make SYSSRC=/root/kbuild/linux-6.18.10 -j"$(nproc)"

# Installed additively -- a NEW directory, does not touch nouveau.ko.
# depmod registers a PCI-ID alias matching this exact GPU, which now
# genuinely races nouveau for the device on every boot (wildcard vendor
# match, confirmed) -- the blacklist file below is not optional.
install -v -d /lib/modules/6.18.10-audio/kernel/drivers/video/nvidia-470xx
install -v -m644 nvidia.ko nvidia-drm.ko nvidia-modeset.ko nvidia-uvm.ko nvidia-peermem.ko \
    /lib/modules/6.18.10-audio/kernel/drivers/video/nvidia-470xx/
depmod -a 6.18.10-audio

cat > /etc/modprobe.d/blacklist-nvidia-470xx.conf << "EOF"
# nvidia-470xx-linux-mainline patched build, additive alongside nouveau
# (see BUILD-REPORT.md GPU deep-dive). Never auto-load via udev modalias
# matching on ANY boot -- only loaded explicitly (modprobe nvidia-drm) on
# the dedicated TEST grub entry that blacklists nouveau via kernel cmdline.
# Without this, nvidia.ko now has a matching PCI-ID alias (same GPU) and
# could race nouveau for the device on the normal/default boot.
blacklist nvidia
blacklist nvidia-drm
blacklist nvidia-modeset
blacklist nvidia-uvm
blacklist nvidia-peermem
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

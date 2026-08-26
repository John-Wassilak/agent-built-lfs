#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/mesa.html
# title  : Mesa-25.3.5
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
#
# Rebuilt 2026-08-26 with -D glvnd=enabled: this option is meson
# type:feature (auto/enabled/disabled) and Mesa was originally built (tier
# 4) before libglvnd existed, so "auto" detected no glvnd present and
# defaulted to disabled -- Mesa installed a standalone libEGL.so.1.0.0
# with no glvnd vendor ABI at all. libglvnd's own libEGL.so.1.1.0 later
# won the /usr/lib/libEGL.so.1 soname (built after Mesa), with no vendor
# JSON in /usr/share/glvnd/egl_vendor.d telling it where to dispatch to --
# real EGL calls (eglQueryString et al.) had nothing behind them. Root
# cause of Hyprland/aquamarine's first real crash: CDRMRenderer::loadEGLAPI
# calling into a dispatcher with zero registered vendors. Can't be fixed
# with a hand-written vendor JSON alone -- the existing standalone
# libEGL.so.1.0.0 doesn't implement glvnd's vendor entry points, only the
# plain direct EGL ABI. A real Mesa rebuild is the only fix.
set -e

# --- block 0 --------------------------------------------------
#   ctx: vers are built. That will almost always work. However, it is not efficient. Depending on
#   ctx: your video hardware, you probably need only specific drivers. The first thing you need
#   ctx: to know is which type of video device you have. In some cases it is built into the CPU.
#   ctx: In others it is a separate PCI card. In either case you can tell what video hardware you
#   ctx: have by installing pciutils-3.14.0 and running:
#   REVIEWED [drop]: lspci to identify installed GPU hardware -- already known (GTX 770/GK104, confirmed against pci-ids during the baseline hardware audit) and pciutils is not installed.
# lspci | grep VGA

# --- block 1 --------------------------------------------------
#   ctx: ptic message Error: couldn't get an RGB, Double-buffered visual. Strictly speaking, it
#   ctx: can be compiled as a module. But the module will not be loaded automatically, so it's
#   ctx: more convenient to build it as a part of the kernel image. Installation of Mesa If you
#   ctx: have downloaded the xdemos patch (needed if testing the Xorg installation per BLFS
#   ctx: instructions), apply it by running the following command:
#   REVIEWED [drop]: Applies the optional xdemos patch ('If you have downloaded...') -- not fetched, only needed for testing an Xorg install with extra demo programs, not needed here.
# patch -Np1 -i ../mesa-add_xdemos-4.patch

# --- block 2 --------------------------------------------------
#   ctx: Install Mesa by running the following commands:
mkdir build &&
cd    build &&

meson setup ..                     \
      --prefix=$XORG_PREFIX        \
      --buildtype=release           \
      -D platforms=x11,wayland      \
      -D gallium-drivers=nouveau \
      -D vulkan-drivers=            \
      -D valgrind=disabled           \
      -D video-codecs=all             \
      -D libunwind=disabled          \
      -D glvnd=enabled               &&

ninja

# --- block 3 --------------------------------------------------
#   ctx: Warning Please ask your lawyer or remove the -D video-codecs=all option if you will
#   ctx: distribute the compiled Mesa libraries and drivers to others. To test the results,
#   ctx: issue:
#   REVIEWED [drop]: Reconfigures with build-tests=true and runs the full test suite -- doubles build time for verification not otherwise done for any package in this build (test suites have been skipped throughout).
# meson configure -D build-tests=true &&
# ninja test

# --- block 4 --------------------------------------------------
#   ctx: Now, as the root user:
ninja install

# --- block 5 --------------------------------------------------
#   ctx: If desired, install the optional documentation by running the following commands as the
#   ctx: root user:
cp -rv ../docs -T /usr/share/doc/mesa-25.3.5

